# Rabbit in a Data Build Tool (dbt)

This DBT package recreates some of the key functions of the "rabbit" tools in the OHDSI toolkit, but streamlined and optimized for use in a dbt project.

## Package at the development phase

https://docs.getdbt.com/guides/building-packages?step=1
https://docs.getdbt.com/blog/so-you-want-to-build-a-package

![image](https://github.com/odikia/rabbit_in_a_dbt/assets/20713572/edbc776a-c05b-41c2-9cf0-352c0662f7e8)


# Macros
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

```sql
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
