# Rabbit in a Data Build Tool (dbt)

This DBT package recreates some of the key functions of the "rabbit" tools in the OHDSI toolkit, but streamlined and optimized for use in a dbt project.

## Package at the development phase

https://docs.getdbt.com/guides/building-packages?step=1
https://docs.getdbt.com/blog/so-you-want-to-build-a-package

![image](https://github.com/odikia/rabbit_in_a_dbt/assets/20713572/edbc776a-c05b-41c2-9cf0-352c0662f7e8)

### How It Works
- Initialize Query List: Begins by initializing an empty list called queries to store individual SQL queries for each model.
- Loop Over Models: Iterates over each model provided in the models list.
  - Generate Query for Each Model: Constructs a SQL query that selects:
    - The model name.
    - The run order specified for the model.
    - The row count from the model's table.
    - The current timestamp to capture when the model was run.
    - Run notes provided in the macro call.
    - The dbt project name.
    - The phase of development for the model
  - Append to Queries List: Each constructed query is appended to the `queries` list.
- Combine Queries: After all individual model queries are created, they are combined into a single SQL query using 'union all'.
- Return Final Query: Outputs the final combined query, ready for execution.

This macro is useful for logging and auditing model runs within a dbt project, providing a quick overview of each model's state at the time of the run.

# Macros
## generate_model_statistics
### Overview
The `generate_model_statistics` macro compiles statistics for multiple models in a dbt project. It generates SQL queries that compute basic statistics, such as row counts for specified models, and captures execution details like timestamps and specific run notes.
### Parameters
- **`models`**: A list of dictionaries, each specifying a model and its order in the run sequence.
- **`run_notes`**: A string containing notes or comments about the current run, which will be logged with each model's statistics.
- **`dbt_project_name`**: The name of the dbt project to which these models belong.
- **`development_phase`**: The phase of the projects development. Can be version number, or nomenclature, but try to be descriptive but succinct (version number is best, using major, minor, hotfix, x.x.x!).

### Structure for `models` Parameter
The `models` parameter expects a list of dictionaries with the following keys:
```yaml
models:
  - model_name: 'patients'
    run_order: 1
  - model_name: 'drugs'
    run_order: 2
  - model_name: 'procedures'
    run_order: 3

### Example DBT Usage

```jinja
{{ config(
    materialized='table'
) }}

{% set models = [
    {'model_name': 'daily_sales', 'run_order': 1},
    {'model_name': 'customer_demographics', 'run_order': 2}
] %}

{{ rabbit_in_a_dbt.generate_model_statistics(
  models=models,
  run_notes='Initial run for daily updates',
  dbt_project_name='wali_demographics',
  development_phase='Development'
) }}
```

## get_column_stats
The `get_column_stats` macro generates SQL queries to get statistics about columns in a database table. The result of this macro is a SQL query that gets the top entities by count for each column in a table, with the ability to specify column-specific values for max_entities and min_count, and the ability to skip certain columns.
### Parameters
- model: The name of the database table.
- default_max_entities: The default maximum number of entities for each column in the model to be displayed (default is 1000).
- min_count: The default minimum count required per cell per column in the model in order to be displayed (default is 5).
- column_exceptions: A dictionary that can contain column-specific values for max_entities and min_count. The structure must conform to the following:

```jinja
{% set column_exceptions ={
  'column_name1': {'max_entities': 100, 'min_count': 10},
  'column_name2': {'max_entities': 50, 'min_count': 2},
  'column_name3': None
} %}
```

**Note: you can skip a column by setting its value to None.**

### Example DBT usage

```jinja
{{ config(
    materialized='table'
) }}

{% set model_name = 'os_extract_specimen' %}

{% set column_exceptions = {
    'ops_identifier': {'max_entities': 5, 'min_count': 1},
    'ppid': {'max_entities': 5, 'min_count': 10},
    'specimen_id': {'max_entities': 5, 'min_count': 1}
} %}

{{ rabbit_in_a_dbt.get_column_stats(model_name, default_max_entities=10, default_min_count=5, column_exceptions=column_exceptions) }}
```

### How It Works
- Get Columns: The macro begins by getting a list of all columns in the model table.
- Initialize CTE Statements List: A list named cte_statements is initialized. This list will hold the Common Table Expressions (CTEs) that are generated for each column.
- Loop Over Columns: The macro then loops over each column in the columns list.
- Skip Column: If the column is in the column_exceptions dictionary with a value of None, the macro skips this column and moves to the next one.
- Get Max Entities and Min Count: For each column, the macro gets the max_entities and min_count values. If the column is in the column_exceptions dictionary, it uses the values from the dictionary. Otherwise, it uses the default values.
- Generate CTE Statement: For each column, the macro generates a CTE statement. This statement creates a temporary table that contains the model_name, column_name, entity, and entity_count for each entity in the column that has a count greater than or equal to min_count. The entities are ordered by entity_count in descending order, and only the top max_entities entities are included.
- Append CTE Statement: The CTE statement is then appended to the cte_statements list.
- Combine CTE Statements: After the loop, all the CTE statements are combined into a single string with commas in between.
- Generate Final Query: Finally, the macro generates the final query. This query selects all rows from each CTE and combines them using the UNION ALL operator.

# Special Note:
This documentation was created with the assistance of ChatGPT 4o:
- https://chatgpt.com/share/cf63a5d6-57f9-4bdd-a1d3-c17ede214d5a
