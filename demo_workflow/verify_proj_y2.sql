REM This query verifies the effect of project_x.sql 

SELECT grantee, privilege, owner, table_name FROM dba_tab_privs
WHERE 1=0
  OR privilege = 'SELECT'  AND owner = 'SALES_APP' and grantee = 'APP_USER2' AND table_name = 'PRODUCT'
  OR privilege = 'SELECT'  AND owner = 'CRM_APP'   and grantee = 'APP_USER1' AND table_name = 'COMMS_CHANNEL'
  OR privilege = 'INSERT'  AND owner = 'CRM_APP'   and grantee = 'APP_USER1' AND table_name = 'COMMS_CHANNEL'
  OR privilege = 'UPDATE'  AND owner = 'CRM_APP'   and grantee = 'APP_USER1' AND table_name = 'COMMS_CHANNEL'
;