REM This query verifies the effect of project_x.sql 

SELECT grantee, privilege, owner, table_name FROM dba_tab_privs
WHERE 1=0
  OR privilege = 'SELECT'  AND owner = 'CRM_APP' and grantee = 'APP_USER1' AND table_name = 'CUSTOMER'
  OR privilege = 'EXECUTE' AND owner = 'CRM_APP' and grantee = 'APP_USER2' AND table_name = 'PKG_CRM'
UNION ALL
SELECT owner,   'SYNONYM',    table_owner, synonym_name FROM dba_synonyms
WHERE 1=0
  OR owner = 'APP_USER2' AND synonym_name = 'PKG_CRM' AND TABLE_NAME = 'PKG_CRM'
;