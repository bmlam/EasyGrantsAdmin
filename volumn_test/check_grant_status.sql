SET LINES 120 PAGES 100 

COL GRANTEE FORMAT A20
COL PRIVILEGE FORMAT A20
COL OWNER     FORMAT A20

SELECT tp.grantee, tp.owner, tp.privilege
	, COUNT(1)
FROM dba_tab_privs  tp
JOIN grant_admin.VW_VOL_TEST_OBJECTS ot 
ON ot.owner = tp.owner AND ot.object_name=tp.table_name 
group by tp.grantee, tp.owner, tp.privilege
order by tp.grantee, tp.owner, tp.privilege
;

