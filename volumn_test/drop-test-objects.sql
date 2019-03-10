PROMPT dropping test objects 
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
END;
/


