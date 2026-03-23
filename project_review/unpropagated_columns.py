#!/usr/bin/env python3
"""
Unpropagated Columns Analysis Script (MCP-based)

This script uses the dbt MCP API to analyze column lineage and identify source
columns that are not propagated to downstream models.

Usage:
    # Set environment variables first:
    export DBT_HOST_URL="https://cloud.getdbt.com"  # or your dbt Cloud host
    export DBT_TOKEN="your-service-token"
    export DBT_ENVIRONMENT_ID="your-prod-environment-id"

    # Run the analysis:
    python unpropagated_columns.py

    # With custom output:
    python unpropagated_columns.py --output /path/to/report.csv

Requirements:
    - Python 3.8+
    - requests library (pip install requests)
    - dbt Cloud account with Remote MCP enabled (Starter/Enterprise plan)
    - Service token with Semantic Layer and Developer permissions

Environment Variables:
    DBT_HOST_URL        - dbt Cloud host (default: https://cloud.getdbt.com)
    DBT_TOKEN           - Service token or personal access token
    DBT_ENVIRONMENT_ID  - Production environment ID from dbt Cloud
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Optional
from dataclasses import dataclass, field

try:
    import requests
except ImportError:
    print("Error: requests library required. Install with: pip install requests")
    sys.exit(1)

# Optional: load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv
    # Look for .env in the script's directory
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
except ImportError:
    pass  # python-dotenv not installed, rely on environment variables


# =============================================================================
# Configuration
# =============================================================================

@dataclass
class MCPConfig:
    """Configuration for dbt MCP connection."""
    host_url: str = "https://cloud.getdbt.com"
    token: str = ""
    environment_id: str = ""
    
    @classmethod
    def from_env(cls) -> "MCPConfig":
        """Load configuration from environment variables."""
        return cls(
            host_url=os.environ.get("DBT_HOST_URL", "https://cloud.getdbt.com"),
            token=os.environ.get("DBT_TOKEN", ""),
            environment_id=os.environ.get("DBT_ENVIRONMENT_ID", ""),
        )
    
    def validate(self) -> list[str]:
        """Return list of missing required config."""
        missing = []
        if not self.token:
            missing.append("DBT_TOKEN")
        if not self.environment_id:
            missing.append("DBT_ENVIRONMENT_ID")
        return missing


# =============================================================================
# MCP Client
# =============================================================================

class MCPClient:
    """Client for dbt Remote MCP API using SSE transport."""
    
    def __init__(self, config: MCPConfig):
        self.config = config
        self.base_url = f"{config.host_url.rstrip('/')}/api/ai/v1/mcp/"
        self.headers = {
            "Authorization": f"Token {config.token}",
            "x-dbt-prod-environment-id": config.environment_id,
        }
        self._session = None
        self._client = None
    
    async def _get_client(self):
        """Get or create MCP client session."""
        if self._client is None:
            try:
                from mcp import ClientSession
                from mcp.client.streamable_http import streamablehttp_client
            except ImportError:
                raise ImportError(
                    "MCP library required. Install with: pip install mcp"
                )
            
            # Create Streamable HTTP transport (correct for dbt Remote MCP)
            self._http_context = streamablehttp_client(
                url=self.base_url,
                headers=self.headers
            )
            # streamablehttp_client returns 3 values: read, write, session_id
            self._read, self._write, _ = await self._http_context.__aenter__()
            
            # Create client session
            self._session_context = ClientSession(self._read, self._write)
            self._client = await self._session_context.__aenter__()
            
            # Initialize
            await self._client.initialize()
        
        return self._client
    
    async def close(self):
        """Close the MCP client session."""
        if self._client:
            await self._session_context.__aexit__(None, None, None)
            await self._http_context.__aexit__(None, None, None)
            self._client = None
    
    async def call_tool_async(self, tool_name: str, arguments: dict | None = None) -> dict | list:
        """Call an MCP tool asynchronously."""
        client = await self._get_client()
        result = await client.call_tool(tool_name, arguments or {})
        
        # Parse the result content - each TextContent may be a separate JSON object
        from mcp.types import TextContent
        
        if hasattr(result, 'content') and result.content:
            text_contents = [c for c in result.content if isinstance(c, TextContent)]
            
            if len(text_contents) == 1:
                # Single result
                try:
                    return json.loads(text_contents[0].text)
                except json.JSONDecodeError:
                    return {"text": text_contents[0].text}
            elif len(text_contents) > 1:
                # Multiple results - return as list
                items = []
                for tc in text_contents:
                    try:
                        items.append(json.loads(tc.text))
                    except json.JSONDecodeError:
                        items.append({"text": tc.text})
                return items
        return {}
    
    async def get_all_sources(self) -> list[dict]:
        """Get all sources from the dbt project."""
        result = await self.call_tool_async("get_all_sources")
        if isinstance(result, list):
            return result
        elif isinstance(result, dict) and result:
            return [result]  # Single source
        return []
    
    async def get_source_details(self, unique_id: str) -> dict:
        """Get detailed info about a source including columns."""
        return await self.call_tool_async("get_source_details", {"unique_id": unique_id})
    
    async def get_all_models(self) -> list[dict]:
        """Get all models from the dbt project."""
        result = await self.call_tool_async("get_all_models")
        if isinstance(result, list):
            return result
        elif isinstance(result, dict) and result:
            return [result]  # Single model
        return []
    
    async def get_model_details(self, unique_id: str) -> dict:
        """Get detailed info about a model including columns."""
        return await self.call_tool_async("get_model_details", {"unique_id": unique_id})
    
    async def get_column_lineage(self, model_id: str, column_name: str) -> dict:
        """Get column-level lineage for a specific column."""
        return await self.call_tool_async("get_column_lineage", {
            "model_id": model_id,
            "column_name": column_name
        })
    
    async def get_model_parents(self, unique_id: str) -> list[dict]:
        """Get parent nodes of a model."""
        result = await self.call_tool_async("get_model_parents", {"unique_id": unique_id})
        if isinstance(result, list):
            return result
        elif isinstance(result, dict) and result:
            return [result]  # Single parent
        return []


# =============================================================================
# Analysis Functions
# =============================================================================

def classify_model_layer(model: dict) -> str:
    """Determine if a model is staging, marts, or other."""
    name = model.get("name", "")
    fqn = model.get("fqn", [])
    modeling_layer = model.get("modelingLayer", "")
    
    if modeling_layer:
        return modeling_layer.lower()
    if "staging" in fqn or name.startswith("stg_"):
        return "staging"
    elif "marts" in fqn or name.startswith(("dim_", "fct_", "fact_")):
        return "marts"
    return "other"


def normalize_column_name(name: str) -> str:
    """Normalize column name for comparison."""
    return name.upper().strip()


import re

def parse_column_mappings_from_sql(sql_code: str) -> dict[str, str]:
    """
    Parse SQL to extract column mappings (source_col -> output_col).
    
    Handles patterns like:
    - source_col as output_col
    - cast(source_col as type) as output_col
    - trim(source_col) as output_col
    - function(source_col, ...) as output_col
    
    Returns a dict mapping source column names to output column names.
    """
    mappings = {}
    
    # Normalize SQL for parsing
    sql = sql_code.lower().replace('\n', ' ').replace('\r', ' ')
    
    # Pattern: anything AS output_col (capture both source expression and output name)
    # Match: expression AS column_name (with optional comma after)
    as_pattern = r'([a-z_][a-z0-9_]*(?:\s*\([^)]+\))?)\s+as\s+([a-z_][a-z0-9_]*)'
    
    # Find all AS clauses
    for match in re.finditer(as_pattern, sql):
        expression = match.group(1).strip()
        output_col = match.group(2).strip().upper()
        
        # Extract the base column name from the expression
        # Handle: cast(col as type), trim(col), upper(col), etc.
        col_in_expr = re.search(r'\(?\s*([a-z_][a-z0-9_]*)', expression)
        if col_in_expr:
            source_col = col_in_expr.group(1).strip().upper()
            # Skip SQL keywords
            if source_col not in ('SELECT', 'FROM', 'WHERE', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'AND', 'OR', 'AS', 'CAST', 'VARCHAR', 'TEXT', 'INT', 'DATE', 'TIMESTAMP'):
                mappings[source_col] = output_col
    
    # Also handle direct column references (col without AS)
    # Pattern: find columns in SELECT that don't have AS
    select_match = re.search(r'select\s+(.*?)\s+from', sql, re.DOTALL)
    if select_match:
        select_clause = select_match.group(1)
        # Simple column pattern (not already in mappings as output)
        for col_match in re.finditer(r'(?:^|,)\s*([a-z_][a-z0-9_]*)\s*(?:,|$)', select_clause):
            col = col_match.group(1).strip().upper()
            if col not in mappings.values() and col not in ('SELECT', 'FROM', 'WHERE', 'AS'):
                mappings[col] = col  # Same name in and out
    
    return mappings


async def analyze_with_mcp(client: MCPClient, source_filter: str | None = None) -> list[dict]:
    """
    Analyze column propagation using MCP tools.
    
    Returns a list of records showing propagation status for each source column.
    """
    results = []
    checked_at = datetime.now().isoformat()
    
    print("Fetching sources...")
    sources = await client.get_all_sources()
    
    if source_filter:
        sources = [s for s in sources if s.get("sourceName") == source_filter]
    
    print(f"Found {len(sources)} sources")
    
    print("Fetching models...")
    models = await client.get_all_models()
    print(f"Found {len(models)} models")
    
    # Build model lookup and classify
    model_lookup = {}
    staging_models = []
    mart_models = []
    
    for model in models:
        unique_id = model.get("uniqueId", "")
        model_lookup[unique_id] = model
        layer = classify_model_layer(model)
        if layer == "staging":
            staging_models.append(model)
        elif layer == "marts":
            mart_models.append(model)
    
    # Get detailed info for each model (includes columns)
    print("Fetching model details...")
    model_details = {}
    for model in staging_models + mart_models:
        unique_id = model.get("uniqueId", "")
        try:
            details = await client.get_model_details(unique_id)
            model_details[unique_id] = details
        except Exception as e:
            print(f"  Warning: Could not get details for {unique_id}: {e}")
    
    # Analyze each source
    for source in sources:
        source_unique_id = source.get("uniqueId", "")
        source_name = source.get("name", "")
        
        print(f"Analyzing source: {source_name}")
        
        # Get source columns
        try:
            source_detail = await client.get_source_details(source_unique_id)
            catalog = source_detail.get("catalog", {})
            source_columns = [
                normalize_column_name(col.get("name", ""))
                for col in catalog.get("columns", [])
            ]
        except Exception as e:
            print(f"  Warning: Could not get source details: {e}")
            continue
        
        if not source_columns:
            print(f"  No columns found for {source_name}")
            continue
        
        # Find staging models that use this source
        downstream_staging = []
        for stg in staging_models:
            stg_id = stg.get("uniqueId", "")
            try:
                parents = await client.get_model_parents(stg_id)
                parent_ids = [p.get("uniqueId", "") for p in parents]
                if source_unique_id in parent_ids:
                    downstream_staging.append(stg)
            except Exception:
                pass
        
        # For each source column, trace its propagation
        for source_col in source_columns:
            record = {
                "source_name": source_name,
                "source_column": source_col,
                "staging_model": "",
                "staging_column": "",
                "mart_model": "",
                "mart_column": "",
                "status": "not_used",
                "checked_at": checked_at
            }
            
            # Check staging layer
            for stg_model in downstream_staging:
                stg_id = stg_model.get("uniqueId", "")
                stg_detail = model_details.get(stg_id, {})
                stg_catalog = stg_detail.get("catalog", {})
                stg_columns = [
                    normalize_column_name(col.get("name", ""))
                    for col in stg_catalog.get("columns", [])
                ]
                
                # Try to find matching column in staging
                matched_stg_col = None
                
                # Direct match
                if source_col in stg_columns:
                    matched_stg_col = source_col
                
                # If no direct match, try MCP column lineage first
                if not matched_stg_col:
                    for stg_col in stg_columns:
                        try:
                            lineage = await client.get_column_lineage(stg_id, stg_col)
                            # Check if lineage contains upstream info (not an error)
                            if isinstance(lineage, dict) and "error" not in lineage:
                                upstream = lineage.get("upstream", lineage.get("sources", []))
                                if not upstream and "lineage" in lineage:
                                    upstream = lineage["lineage"].get("upstream", [])
                                
                                for up in upstream:
                                    if isinstance(up, dict):
                                        up_col = normalize_column_name(up.get("column", up.get("columnName", "")))
                                        up_node = up.get("uniqueId", up.get("nodeId", ""))
                                        if up_col == source_col and (up_node == source_unique_id or source_unique_id in up_node):
                                            matched_stg_col = stg_col
                                            break
                        except Exception:
                            pass
                        if matched_stg_col:
                            break
                
                # If MCP lineage didn't work, parse the SQL code
                if not matched_stg_col:
                    raw_code = stg_detail.get("rawCode", "") or stg_detail.get("compiledCode", "")
                    if raw_code:
                        sql_mappings = parse_column_mappings_from_sql(raw_code)
                        # sql_mappings: {SOURCE_COL: OUTPUT_COL}
                        if source_col in sql_mappings:
                            output_col = sql_mappings[source_col]
                            if output_col in stg_columns:
                                matched_stg_col = output_col
                
                # Legacy fallback: try column lineage for each staging column
                if not matched_stg_col:
                    for stg_col in stg_columns:
                        try:
                            lineage = await client.get_column_lineage(stg_id, stg_col)
                            upstream = []
                            if isinstance(lineage, dict) and "error" not in lineage:
                                upstream = lineage.get("upstream", lineage.get("sources", []))
                            
                            for up in upstream:
                                if isinstance(up, dict):
                                    up_col = normalize_column_name(up.get("column", up.get("columnName", "")))
                                    up_node = up.get("uniqueId", up.get("nodeId", ""))
                                    if up_col == source_col and (up_node == source_unique_id or source_unique_id in up_node):
                                        matched_stg_col = stg_col
                                        break
                        except Exception as e:
                            pass  # Column lineage might not be available for all columns
                        if matched_stg_col:
                            break
                
                if matched_stg_col:
                    record["staging_model"] = stg_model.get("name", "")
                    record["staging_column"] = matched_stg_col
                    record["status"] = "propagated_to_staging"
                    
                    # Now check marts layer
                    for mart_model in mart_models:
                        mart_id = mart_model.get("uniqueId", "")
                        
                        # Check if this mart depends on the staging model
                        try:
                            mart_parents = await client.get_model_parents(mart_id)
                            mart_parent_ids = [p.get("uniqueId", "") for p in mart_parents]
                            if stg_id not in mart_parent_ids:
                                continue
                        except Exception:
                            continue
                        
                        mart_detail = model_details.get(mart_id, {})
                        mart_catalog = mart_detail.get("catalog", {})
                        mart_columns = [
                            normalize_column_name(col.get("name", ""))
                            for col in mart_catalog.get("columns", [])
                        ]
                        
                        # Direct match
                        if matched_stg_col in mart_columns:
                            record["mart_model"] = mart_model.get("name", "")
                            record["mart_column"] = matched_stg_col
                            record["status"] = "propagated"
                            break
                        
                        # Try common rename patterns (heuristic)
                        matched_stg_base = matched_stg_col.replace("_KEY", "").replace("_ID", "")
                        for mart_col in mart_columns:
                            mart_col_base = mart_col.replace("_KEY", "").replace("_ID", "")
                            if matched_stg_base == mart_col_base:
                                record["mart_model"] = mart_model.get("name", "")
                                record["mart_column"] = mart_col
                                record["status"] = "propagated"
                                break
                        
                        if record["status"] != "propagated":
                            # Try column lineage as fallback
                            for mart_col in mart_columns:
                                try:
                                    lineage = await client.get_column_lineage(mart_id, mart_col)
                                    upstream = []
                                    if isinstance(lineage, dict):
                                        upstream = lineage.get("upstream", lineage.get("sources", []))
                                    for up in upstream:
                                        if isinstance(up, dict):
                                            up_col = normalize_column_name(up.get("column", up.get("columnName", "")))
                                            if up_col == matched_stg_col:
                                                record["mart_model"] = mart_model.get("name", "")
                                                record["mart_column"] = mart_col
                                                record["status"] = "propagated"
                                                break
                                except Exception:
                                    pass
                                if record["status"] == "propagated":
                                    break
                        
                        if record["status"] == "propagated":
                            break
                    
                    if not record["mart_model"] and mart_models:
                        # Check if any mart depends on this staging
                        has_downstream_mart = False
                        for mart_model in mart_models:
                            mart_id = mart_model.get("uniqueId", "")
                            try:
                                mart_parents = await client.get_model_parents(mart_id)
                                if stg_id in [p.get("uniqueId", "") for p in mart_parents]:
                                    has_downstream_mart = True
                                    break
                            except Exception:
                                pass
                        if has_downstream_mart:
                            record["status"] = "dropped_at_marts"
                    
                    break  # Found in staging
            
            if not record["staging_model"] and downstream_staging:
                record["staging_model"] = downstream_staging[0].get("name", "")
                record["status"] = "dropped_at_staging"
            
            results.append(record)
    
    return results


# =============================================================================
# Export Functions
# =============================================================================

def export_to_csv(results: list[dict], output_path: Path) -> None:
    """Export analysis results to CSV file."""
    if not results:
        print("No results to export.")
        return
    
    fieldnames = [
        "source_name",
        "source_column",
        "staging_model",
        "staging_column",
        "mart_model",
        "mart_column",
        "status",
        "checked_at"
    ]
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"Report written to: {output_path}")


def print_summary(results: list[dict]) -> None:
    """Print a summary of the analysis."""
    total = len(results)
    propagated = len([r for r in results if r["status"] == "propagated"])
    dropped_staging = len([r for r in results if r["status"] == "dropped_at_staging"])
    dropped_marts = len([r for r in results if r["status"] == "dropped_at_marts"])
    not_used = len([r for r in results if r["status"] == "not_used"])
    staging_only = len([r for r in results if r["status"] == "propagated_to_staging"])
    
    print("\n" + "=" * 60)
    print("UNPROPAGATED COLUMNS ANALYSIS SUMMARY")
    print("=" * 60)
    print(f"Total source columns analyzed: {total}")
    print(f"  - Fully propagated to marts: {propagated}")
    print(f"  - Propagated to staging only: {staging_only}")
    print(f"  - Dropped at staging layer:  {dropped_staging}")
    print(f"  - Dropped at marts layer:    {dropped_marts}")
    print(f"  - Not used in any model:     {not_used}")
    print("=" * 60)
    
    # List dropped columns
    dropped = [r for r in results if r["status"] in ("dropped_at_staging", "dropped_at_marts")]
    if dropped:
        print("\nDROPPED COLUMNS:")
        print("-" * 60)
        for r in dropped:
            layer = "staging" if r["status"] == "dropped_at_staging" else "marts"
            print(f"  {r['source_name']}.{r['source_column']} -> dropped at {layer}")
    print()


# =============================================================================
# Main Entry Point
# =============================================================================

async def run_analysis(args, config: MCPConfig) -> list[dict]:
    """Run the analysis with proper async context management."""
    client = MCPClient(config)
    try:
        results = await analyze_with_mcp(client, args.source)
        return results
    finally:
        await client.close()


def main():
    parser = argparse.ArgumentParser(
        description="Analyze unpropagated columns using dbt MCP API"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("project_review/unpropagated_columns_report.csv"),
        help="Output CSV file path"
    )
    parser.add_argument(
        "--source", "-s",
        type=str,
        help="Filter to specific source name"
    )
    
    args = parser.parse_args()
    
    # Load config
    config = MCPConfig.from_env()
    missing = config.validate()
    
    if missing:
        print("Error: Missing required environment variables:")
        for var in missing:
            print(f"  - {var}")
        print("\nSet these variables before running:")
        print("  export DBT_TOKEN='your-service-token'")
        print("  export DBT_ENVIRONMENT_ID='your-environment-id'")
        sys.exit(1)
    
    print(f"Connecting to dbt MCP at: {config.host_url}")
    
    # Run async analysis
    import asyncio
    
    try:
        results = asyncio.run(run_analysis(args, config))
    except PermissionError as e:
        print(f"Authentication error: {e}")
        sys.exit(1)
    except ImportError as e:
        print(f"Missing dependency: {e}")
        print("\nInstall required packages:")
        print("  pip install mcp httpx-sse")
        sys.exit(1)
    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Output
    export_to_csv(results, args.output)
    print_summary(results)
    
    # Exit with error code if unpropagated columns found
    dropped_count = len([r for r in results if r["status"].startswith("dropped")])
    if dropped_count > 0:
        print(f"\n⚠️  Found {dropped_count} unpropagated columns")
        # Optionally exit with error for CI
        # sys.exit(1)


if __name__ == "__main__":
    main()
