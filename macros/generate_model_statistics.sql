{% macro generate_model_statistics(models) %}
    {% set queries = [] %}
    {% set dbt_project_name = var('dbt_project_name') %}
    {% set run_notes = var('run_notes') %}

    {% if not models %}
        {% do log('No models provided to generate_model_statistics macro') %}
    {% endif %}
    
    {% for model in models %}
        {% set query %}
        select
            '{{ model.model_name }}' as model_name,
            {{ model.run_order }} as run_order,
            (select count(*) as row_count from {{ ref(model.model_name) }}) as row_count,
            current_timestamp as model_run_ts,
            '{{ run_notes }}' as run_notes,
            '{{ dbt_project_name }}' as dbt_project_name
        {% endset %}
        
        {% do queries.append(query) %}
    {% endfor %}
    
    {% set final_query = queries | join(' union all ') %}
    
    {{ return(final_query) }}
{% endmacro %}
