# Agent User Rules


## Directory and Navigation
- If you are already in the correct directory you do not need to run cd commands
- Dont change directory or run commands unless you absolutely have too. The idea is to solve each problem in as few steps as possible


## Code Changes and Fixes
- Make minimal changes only. Don't browse unnecessary files. Make sure the changes makes sense coneptually. Don't check target/compiled unless asked for it.
- Don't fix more than you need to. Do not switch directories, build models, query stuff unless I tell you to.
- When fixing models and tests apply minimal changes only
- Ask me to approve code changes


## Model Relationships and Lineage
- If i ask you if models are related to each other I mean to check the lineage using f.e. get_model_children or get_model_parents. You should not run show or sql commands.
- When asked about downstream dependencies use the dbt MCP get_model_children to understand the relations
- When I ask you to check for impact downstream I want you to use get_model_children MCP


## Validation and Testing
- When applying a fix to a model and or tests you should build only the changed model and run MCP show with an aggregation function to validate the problem is solved.
- When I ask you to validate I just want you to check the changed models. Be extremely short and run a single aggregation query to validate
- Always use dbtf instead of dbt to run dbt commands
- You don't need to run dbtf test after you have done dbtf build since build also includes tests.


## Metrics and Queries (For some reason I don’t get groupings to work in MCP
- You are not allowed to use the group_by parameter for query_metrics.
- No need to use mcp list_metrics and get_dimensions unless you need them.
- When I tell you to validate sales for last month you can use this syntax:
```json
{
 "metrics": [
   "total_gross_sales"
 ],
 "where": "{{ TimeDimension('customer_order__order_time', 'MONTH') }} = '<date>'"
}
```
You can point out that the metric is based on column gross_item_sales_amount in fct_orders
- Better to run GROUP BY instead of DISTINCT when validating results with the mcp show command


## Communication Style
- Be extremely short in your responses. Highlight and icon the important things
- Highlight important findings with colors and icons.
- If you fix an error locally thanks to Fusion LSP you can point that out


## Git Workflow
- Before changing code I want you to create a new branch and ask for my approval before doing a git workflow. 
- Always complete git workflow BEFORE creating PRs:
 1. git add → 2. git commit → 3. git push → 4. create PR
 Never attempt PR creation with uncommitted changes. Make sure branch exists remote.
- Always ask for permission before creating PRs, issues, or making external changes.
Only proceed with code fixes after user approval.
- for repository sa-standard-shared-demo always default to PR into branch vignette/fs-vscode rather than main


## Issue Management
- Typically I want you to use get_issue rather than pull request when I ask you to fix things or read issues from Github