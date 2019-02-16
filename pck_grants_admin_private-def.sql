CREATE OR REPLACE PACKAGE pck_grants_admin_private AS

PROCEDURE p_log_result
( i_result_rec request_process_results%ROWTYPE
)
;

PROCEDURE p_trunc_table
( i_table_name VARCHAR2
)
;


PROCEDURE p_execute_synonym_ddl(
	i_ddl VARCHAR2
); 

END;
/

show errors