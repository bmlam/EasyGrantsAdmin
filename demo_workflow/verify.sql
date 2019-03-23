SET ECHO Off
REM This query verifies the effect of project_x.sql 

SET ECHO ON

SELECT grantee, privilege, owner, table_name FROM dba_tab_privs
WHERE 1=1
	-- AND REGEXP_LIKE( owner, '{CRM|SALES}_APP' )
	AND REGEXP_LIKE( owner, '_APP' )
	and grantee LIKE 'APP_USER%' 
	and table_name NOT LIKE 'VOL_TEST%'
	and table_name NOT LIKE 'BIN$%'
UNION ALL
SELECT owner,   'SYNONYM',    table_owner, synonym_name FROM dba_synonyms
WHERE 1=1
	AND REGEXP_LIKE( table_owner, '(CRM|SALES)_APP' )
ORDER BY grantee,  privilege, owner, table_name
;

