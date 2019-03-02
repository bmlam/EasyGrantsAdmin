REM This query verifies the effect of project_x.sql 

SELECT grantee, privilege, owner, table_name FROM dba_tab_privs
WHERE 1=0
  OR privilege = 'EXECUTE'  AND owner = 'CRM_APP' and grantee = 'APP_USER2' AND table_name = 'PKG_CRM'
  OR privilege = 'UPDATE'   AND owner = 'CRM_APP' and grantee = 'APP_USER2' AND table_name = 'CUSTOMER'
;