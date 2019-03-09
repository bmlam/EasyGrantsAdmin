REM run this script with a DBA user!

create or replace view grant_admin.vw_vol_test_objects as
select 'TABLE' as otype
  ,'VOL_TEST_TABLE_'||to_char(level) object_name 
  ,CASE mod(level, 1) WHEN 0 THEN 'CRM_APP' ELSE 'SALES_APP' END as owner
from dual 
connect by level <= 1800
UNION ALL
select 'PACKAGE' as otype
  ,'VOL_TEST_PKG_'||to_char(level)
  ,CASE mod(level, 1) WHEN 0 THEN 'CRM_APP' ELSE 'SALES_APP' END as owner
from dual 
connect by level <= 200
;


set time on timing on 

PROMPT dropping and re-creating test objects 
BEGIN 
	FOR rec IN (
		SELECT dd.object_name
		  , 'DROP '||ot.otype||' '||ot.owner||'.'||ot.object_name as ddl
		FROM dba_objects dd
		JOIN grant_admin.VW_VOL_TEST_OBJECTS ot ON dd.owner = ot.owner AND ot.object_name = dd.object_name AND dd.object_type=ot.otype
		WHERE dd.owner IN ('CRM_APP', 'SALES_APP' ) AND dd.object_name LIKE 'VOL_TEST%' -- being careful
		  AND dd.object_type IN ( 'TABLE' )
		  --and rownum < 3
	) LOOP
		EXECUTE IMMEDIATE rec.ddl;
	END LOOP; -- over test object_name
	--
	-- CREATE 
	--
	FOR rec IN (
		SELECT 'CREATE '
		  ||CASE ot.otype 
		  WHEN 'PACKAGE' THEN ' OR REPLACE '
		  END 
		  ||ot.otype||' '||ot.owner||'.'||ot.object_name 
		  ||' '
		  ||CASE ot.otype 
		  WHEN 'TABLE' THEN ' ( c1 number, c2 varchar2(10) )'
		  WHEN 'PACKAGE' THEN ' AS END;'
		  END 
		  as ddl
		FROM grant_admin.VW_VOL_TEST_OBJECTS ot
        WHERE 1=1
		--  and rownum < 3
	) LOOP
		BEGIN 
			EXECUTE IMMEDIATE rec.ddl;
		EXCEPTION WHEN OTHERS THEN 
			RAISE_APPLICATION_ERROR( -20001, sqlerrm || 'on DDL '||rec.ddl);
		END;
	END LOOP; -- over test object_name
	--
END;
/



PROMPT create GRANT DDL statements, Spool the result to a script
set heading off pagesize 0 linesize 120

WITH grantees_ AS (
    SELECT 'APP_USER'||level grantee
    FROM dual
    CONNECT BY level <= 3
)
		SELECT 'GRANT '
		  ||CASE ot.otype 
		  WHEN 'PACKAGE' THEN ' EXECUTE '
		  WHEN 'TABLE' THEN ' SELECT '
		  END 
          ||' ON '
		  ||ot.owner||'.'||ot.object_name 
		  ||' TO '|| gt.grantee||';'
		  as ddl
		FROM grant_admin.VW_VOL_TEST_OBJECTS ot
        CROSS JOIN grantees_ gt 
        WHERE 1=1
;

set heading on pagesize 120 linesize 120

