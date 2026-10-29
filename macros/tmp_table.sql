{% macro snowflake__resolve_incremental_tmp_relation(tmp_relation) %}

{% set suffix = env_var('DBT_PERMISSIONS', none) %}
{% if not suffix %}          {# none, '', and 0 #}
    {{ return(tmp_relation) }}
  {% endif %}

  {% set temp_identifier = tmp_relation.identifier ~ '_' ~ suffix %}
  {% set resolved_tmp_relation = tmp_relation.incorporate(
      path={"identifier": temp_identifier},
  ) %}

  {{ return(resolved_tmp_relation) }}
{% endmacro %}