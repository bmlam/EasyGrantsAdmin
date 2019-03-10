BEGIN 

	FOR rec IN ( 
		SELECT 'REVOKE' ||pr.privilege||' ON '||table_owner||'.'||table_name||' FROM '||  grantee 
			AS ddl
		FROM dba_tab_privs dd
		JOIN grant_admin.VW_VOL_TEST_OBJECTS ot ON dd.table_owner = ot.owner AND ot.object_name = dd.table_name 
		WHERE dd.owner IN ('CRM_APP', 'SALES_APP' ) AND dd.object_name LIKE 'VOL_TEST%' -- being careful
	) LOOP

		EXECUTE IMMEDIATE rec.ddl;
		
	END LOOP;
END;
/