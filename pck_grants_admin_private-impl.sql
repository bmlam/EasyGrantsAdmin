CREATE OR REPLACE PACKAGE BODY pck_grants_admin_private AS

PROCEDURE p_log_result
( i_result_rec request_process_results%ROWTYPE)
AS
BEGIN
	INSERT INTO request_process_results values i_result_rec;
	COMMIT;
END p_log_result;

PROCEDURE p_trunc_table
( i_table_name VARCHAR2)
AS
	l_my_schema VARCHAR2(30);
BEGIN
	SELECT username
	INTO l_my_schema
	FROM user_users
	;
	loginfo ($$plsql_unit||':'||$$plsql_line, 'i_table_name: '||i_table_name );
	EXECUTE IMMEDIATE 'truncate table '||l_my_schema||'.'||i_table_name;
END p_trunc_table;

PROCEDURE p_execute_synonym_ddl(
	i_ddl VARCHAR2
) AS
BEGIN 
	debug ($$plsql_unit||':'||$$plsql_line, 'i_ddl: '||i_ddl );
	IF regexp_instr( i_ddl, '^create|drop .*synonym', 1, 1, 0, 'i' ) > 0 
		--AND instr( i_ddl, ';' ) = 0
	THEN 
		EXECUTE IMMEDIATE i_ddl;
	ELSE
		RAISE_APPLICATION_ERROR( -20001, 'DDL does not appear to be for a synonym' );
	END IF;
EXCEPTION 
	WHEN OTHERS THEN 
		logerror( $$plsql_unit||':'||$$plsql_line, sqlcode, dbms_utility.format_error_backtrace );
		RAISE;
END p_execute_synonym_ddl;
END;
/

SHOW errors