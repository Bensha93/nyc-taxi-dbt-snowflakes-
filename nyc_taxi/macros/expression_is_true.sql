{% test expression_is_true(model, column_name, expression) %}

select *
from {{ model }}
where not ({{ expression }})

{% endtest %}
{% macro expression_is_true(model, column_name, expression) %}
{{ return(adapter.dispatch('expression_is_true', 'macros')(model, column_name, expression)) }}
{% endmacro %}