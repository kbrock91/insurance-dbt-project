import pandas as pd


def model(dbt, session):
    """
    Calculate risk scores for policyholders based on their claims history.
    
    This Python model demonstrates dbt Python capabilities by computing
    aggregate metrics and a simple risk score for each policyholder.
    """
    dbt.config(
        materialized="table",
        packages=["pandas"],
        meta = {
            "owner": "analytics-team",
            "model_type": "python",
            "contains_pii": True,
            "refresh_frequency": "daily",
            "tier": "silver"
        }
    )

    # Read upstream models
    # Note: Snowflake returns UPPERCASE column names, so we lowercase them
    policyholders = dbt.ref("stg_policyholders").to_pandas()
    policyholders.columns = policyholders.columns.str.lower()
    
    claims = dbt.ref("stg_claims").to_pandas()
    claims.columns = claims.columns.str.lower()
    
    policies = dbt.ref("stg_policies").to_pandas()
    policies.columns = policies.columns.str.lower()

    # Join policyholders to their policies
    policyholder_policies = policyholders.merge(
        policies[["policy_id", "policyholder_id"]],
        on="policyholder_id",
        how="left"
    )

    # Aggregate claims per policyholder
    claims_agg = (
        claims.merge(
            policies[["policy_id", "policyholder_id"]],
            on="policy_id",
            how="inner"
        )
        .groupby("policyholder_id")
        .agg(
            total_claims=("claim_id", "count"),
            total_loss_amount=("loss_amount", "sum"),
            avg_loss_amount=("loss_amount", "mean")
        )
        .reset_index()
    )

    # Merge aggregates back to policyholders
    result = policyholders[["policyholder_id", "first_name", "last_name"]].merge(
        claims_agg,
        on="policyholder_id",
        how="left"
    )

    # Fill NaN for policyholders with no claims
    result["total_claims"] = result["total_claims"].fillna(0).astype(int)
    result["total_loss_amount"] = result["total_loss_amount"].fillna(0.0)
    result["avg_loss_amount"] = result["avg_loss_amount"].fillna(0.0)

    # Calculate a simple risk score (0-100 scale)
    # Higher claims count and loss amounts = higher risk
    max_claims = result["total_claims"].max() if result["total_claims"].max() > 0 else 1
    max_loss = result["total_loss_amount"].max() if result["total_loss_amount"].max() > 0 else 1

    result["risk_score"] = (
        (result["total_claims"] / max_claims) * 50 +
        (result["total_loss_amount"] / max_loss) * 50
    ).round(2)

    # Uppercase column names for Snowflake compatibility
    # (Snowflake expects unquoted identifiers to be uppercase)
    result.columns = result.columns.str.upper()

    return result
