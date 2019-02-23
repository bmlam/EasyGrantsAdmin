REM This query verifies the effect of project_x.sql 

SELECT grantee, privilege, owner, table_name FROM dba_tab_privs
WHERE 1=0
  OR privilege = 'SELECT' AND owner = 'CRM_APP' and grantee = 'APP_USER1' AND table_name = 'CUSTOMER'
;