SET TIME ON TIMING ON 

BEGIN 
	FOR rec IN ( 
		SELECT 'REVOKE ' ||dd.privilege||' ON '||dd.owner||'.'||dd.table_name||' FROM '||  dd.grantee 
			AS ddl
		FROM dba_tab_privs dd
		JOIN grant_admin.VW_VOL_TEST_OBJECTS ot ON dd.owner = ot.owner AND ot.object_name = dd.table_name 
		WHERE dd.owner IN ('CRM_APP', 'SALES_APP' ) AND dd.table_name LIKE 'VOL_TEST%' -- being careful
	) LOOP
		BEGIN 
			EXECUTE IMMEDIATE rec.ddl;
		EXCEPTION 
		WHEN OTHERS THEN 
			RAISE_APPLICATION_ERROR( -20001, rec.ddl||chr(10)||sqlerrm );
		END;
	END LOOP;
END;
/
