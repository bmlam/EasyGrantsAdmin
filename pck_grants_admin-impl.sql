CREATE OR REPLACE PACKAGE BODY pck_grants_admin AS

	gc_res_type_failed CONSTANT request_process_results.result_type%TYPE := 'Failed';
	gc_res_type_success CONSTANT request_process_results.result_type%type := 'Success';
	gc_res_type_skipped CONSTANT request_process_results.result_type%type := 'Skipped';
	gc_res_type_overruled CONSTANT request_process_results.result_type%type := 'Ovrruled';
	
PROCEDURE ep_denormalize_grants 
( i_schema IN VARCHAR2
)
AS 
BEGIN
	--execute immediate 'truncate table gtmp_grantable_objects';
	pck_grants_admin_private.p_trunc_table( 'gtmp_grantable_objects');
	
	INSERT INTO gtmp_grantable_objects
	( owner,    object_name,     object_type
	)
	SELECT owner,    object_name,     object_type
	FROM dba_objects
	WHERE owner = i_schema
		AND object_type IN
		('aa'
		,'FUNCTION'
		,'PACKAGE'
		,'PROCEDURE'
		,'TABLE'
		,'TYPE'
		,'VIEW'
		)	;
	loginfo ($$plsql_unit||':'||$$plsql_line, 'inserted rows into gtmp_grantable_objects: '||sql%rowcount );

	pck_grants_admin_private.p_trunc_table( 'gtmp_request_denormed');
	INSERT INTO gtmp_request_denormed
	( owner,    object_name,     grantee,    grantable,    priv,   request_type,   request_id
	, based_on_regexp,     request_ts
	)
	SELECT r.owner,  o.object_name,  g.grantee,  r.grantable,  r.privilege,   r.request_type,   r.id
	, 'Y',		request_ts
	FROM v_object_grant_requests r
	JOIN all_grantees g  ON REGEXP_LIKE ( g.grantee, r.grantee_name_pattern )
	JOIN gtmp_grantable_objects o ON o.owner = r.owner AND o.object_name = r.object_name
	WHERE r.grantee_is_regexp = 'Y'
	UNION ALL
	SELECT r.owner,  o.object_name,  g.grantee,  r.grantable,  r.privilege,   r.request_type,   r.id
	, 'N',    request_ts
	FROM v_object_grant_requests r
	JOIN all_grantees g  ON g.grantee = r.grantee_name_pattern 
	JOIN gtmp_grantable_objects o ON o.owner = r.owner AND o.object_name = r.object_name
	WHERE r.grantee_is_regexp = 'N'
	;
	loginfo ($$plsql_unit||':'||$$plsql_line, 'inserted rows into gtmp_request_denormed: '||sql%rowcount );
	
	COMMIT;

END ep_denormalize_grants;

FUNCTION ef_report_conflicts
-- to validate name patterns, i.e. revoke and grants must not exist for the same object
( ip_raise_conflicts_flg IN NUMBER DEFAULT 1
)
RETURN CLOB
AS
BEGIN
NULL;
NULL;
END ef_report_conflicts;


PROCEDURE ep_process_requests
( i_schema VARCHAR2
)
AS 	
	l_result_type request_process_results.result_type%TYPE;
	l_error_msg VARCHAR2(2000);
	l_record_cnt NUMBER := 0;
	l_skip_cnt NUMBER := 0;
	lrec_result  request_process_results%ROWTYPE;
BEGIN 
	ep_denormalize_grants( i_schema=> i_schema );

	pck_grants_admin_private.p_trunc_table( 'gtmp_object_privs');
	
	INSERT INTO gtmp_object_privs
	( owner,    object_name,     grantee,	 privilege,	 	grantable
	)
	SELECT
	owner,    table_name,     grantee,	 privilege,	 	grantable
	FROM dba_tab_privs
	WHERE owner = i_schema
	UNION ALL
	SELECT 
	table_owner, table_name,  owner, 'SYNONYM',     null
	FROM dba_synonyms
	WHERE table_owner = i_schema
	;
	loginfo ($$plsql_unit||':'||$$plsql_line, 'inserted rows into gtmp_object_privs: '||sql%rowcount );

	
	FOR act_rec IN (
		SELECT * FROM V_fact_req_full_outer_join
	) LOOP
		IF act_rec.prio > 1 THEN 
			l_result_type := gc_res_type_overruled;
		ELSE
			IF act_rec.ddl  IS NULL THEN 
				l_result_type := gc_res_type_skipped;
				l_skip_cnt := l_skip_cnt + 1;
			ELSE
				BEGIN 
					IF act_rec.r_priv = 'SYNONYM' THEN -- package owner privs for CREATE/DROP ANY synonym
						pck_grants_admin_private.p_execute_synonym_ddl( act_rec.ddl );
					ELSE
						EXECUTE IMMEDIATE act_rec.ddl ;
					END IF; -- check is synonym
					
					l_result_type := gc_res_type_success;
				EXCEPTION 
					WHEN OTHERS THEN 
						l_result_type := gc_res_type_failed;
						l_error_msg := SQLERRM;
					END;
				COMMIT;
			END IF; -- check DDL 
		END IF;  -- check skipped

		IF l_result_type <> gc_res_type_skipped THEN 
			lrec_result.req_id    :=  act_rec.request_id;
			lrec_result.req_type   :=  act_rec.req_type;
			lrec_result.grantable         :=  act_rec.r_admin;
			lrec_result.result_type       :=  l_result_type;
			lrec_result.processed_ts   :=  SYSTIMESTAMP;
			lrec_result.error_msg :=  CASE l_result_type WHEN gc_res_type_failed THEN l_error_msg END;
			lrec_result.failed_ddl :=  CASE l_result_type WHEN gc_res_type_failed THEN act_rec.ddl END;
			lrec_result.overruled_by_req_id :=  CASE l_result_type WHEN gc_res_type_overruled THEN act_rec.winner_req_id END;

			pck_grants_admin_private.p_log_result( lrec_result );
		END IF; -- CHECK skipped
		
		l_record_cnt := l_record_cnt + 1;
	END LOOP;
	
	loginfo ($$plsql_unit||':'||$$plsql_line, 'l_record_cnt: '||l_record_cnt );
	loginfo ($$plsql_unit||':'||$$plsql_line, 'l_skip_cnt: '||l_skip_cnt );

END ep_process_requests;


FUNCTION ef_export_current_grants
-- create a script for exisint grants so they can be declared as accepted grants.
-- non-accepted grants can be deleted manually from the script
( i_schema IN VARCHAR2
  , i_default_reason VARCHAR2 DEFAULT 'for migration'
)
RETURN CLOB
AS
	lv_return CLOB;
	lc_merge_template CONSTANT VARCHAR2(2000) :=
q'[merge into object_grant_requests tgt
using (
select '<owner>' owner,'<object_name>' object_name, '<grantee_name_pattern>' grantee_name_pattern
, 'N'  grantee_is_regexp, '<privilege>' privilege, '<grantable>' grantable
from dual
) src
ON (src.owner = tgt.owner and src.object_name = tgt.object_name and src.grantee_name_pattern = tgt.grantee_name_pattern
and src.grantee_is_regexp = tgt.grantee_is_regexp and src.privilege = tgt.privilege)
WHEN NOT MATCHED THEN
INSERT ( owner, object_name, grantee_name_pattern, grantee_is_regexp
,privilege, grantable,  grant_reason,last_grant_req_ts
) VALUES
( src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp
,src.privilege, src.grantable , '<grant_reason>',systimestamp
)
WHEN MATCHED THEN UPDATE
SET grantable = src.grantable, last_revoke_req_ts = null, last_grant_req_ts = systimestamp
,grant_reason = '<grant_reason>'
;
]';

	lv_merge VARCHAR2(4000);
BEGIN
	FOR gr_rec IN (
		select rownum rn
		, owner, table_name as object_name, grantee, privilege
		, substr( grantable, 1, 1) grantable
		FROM dba_tab_privs
		WHERE owner = i_schema
	) LOOP
		lv_merge := lc_merge_template;
		lv_merge :=		replace( lv_merge, '<owner>', gr_rec.owner) ;
		lv_merge :=		replace( lv_merge, '<object_name>', gr_rec.object_name ) ;
		lv_merge :=		replace( lv_merge, '<grantee_name_pattern>', gr_rec.grantee ) ;
		lv_merge :=		replace( lv_merge, '<privilege>', gr_rec.privilege ) ;
		lv_merge :=		replace( lv_merge, '<grantable>', gr_rec.grantable ) ;
		lv_merge :=		replace( lv_merge, '<grant_reason>', replace( i_default_reason, '''', '') ) ;

		lv_return := CASE WHEN gr_rec.rn > 1 THEN lv_return||chr(10) END
			||lv_merge;
	END LOOP;
	RETURN  lv_return;
END ef_export_current_grants;

END;
/


SHOW ERRORS
