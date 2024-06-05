{% macro get_column_stats(model, default_max_entities=1000, default_min_count=5, column_exceptions={}) %}
    {% set columns = adapter.get_columns_in_relation(ref(model)) %}
    {% set cte_statements = [] %}
    {% set dbt_project_name = var('dbt_project_name') %}
    {% set run_notes = var('run_notes') %}

    {% for column in columns %}
        {% set column_name = column.name %}
        
        {% set max_entities = column_exceptions.get(column_name, {}).get('max_entities', default_max_entities) %}
        {% set min_count = column_exceptions.get(column_name, {}).get('min_count', default_min_count) %}
        
        {% set cte_statement %}
            entity_counts_{{ loop.index }} as (
                select 
                    '{{ model }}' as model_name,
                    '{{ column_name }}' as column_name,
                    cast({{ column_name }} as varchar) as entity,
                    count(*) as entity_count,
                    current_timestamp as model_run_ts,
                    '{{ run_notes }}' as run_notes,
                    '{{ dbt_project_name }}' as dbt_project_name
                from {{ ref(model) }}
                group by {{ column_name }}
                having count(*) >= {{ min_count }}
                order by entity_count desc
                limit {{ max_entities }}
            )
        {% endset %}
        
        {% do cte_statements.append(cte_statement) %}
    {% endfor %}
    
    with {{ cte_statements | join(', ') }}
    
    {% for column in columns %}
        select * from entity_counts_{{ loop.index }}
        {% if not loop.last %}
        union all
        {% endif %}
    {% endfor %}
{% endmacro %}
