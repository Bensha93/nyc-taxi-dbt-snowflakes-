{% test unique_id_in_range(model, column_name, lookup_model, lookup_field) %}

with fact as (
    select {{ column_name }} as id
    from {{ model }}
    where {{ column_name }} is not null
),

bounds as (
    select min({{ lookup_field }}) as min_id, max({{ lookup_field }}) as max_id
    from {{ lookup_model }}
)

select f.id
from fact f
cross join bounds b
where f.id < b.min_id
   or f.id > b.max_id

{% endtest %}