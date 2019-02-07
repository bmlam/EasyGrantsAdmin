CREATE OR REPLACE PACKAGE BODY pck_grants_admin AS

PROCEDURE ep_denormalize_grants
( i_schema IN VARCHAR2
)
AS 
BEGIN
	execute immediate 'truncate table gtmp_grantable_objects';
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

	execute immediate 'truncate table gtmp_request_denormed';
	INSERT INTO gtmp_request_denormed
	( owner,    object_name,     grantee,    grantable,    priv,   request_type,   request_id
	)
	SELECT r.owner,  o.object_name,  g.grantee,  r.grantable,  r.privilege,   r.request_type,   r.id
	FROM v_object_grant_requests r
	JOIN sys.all_grantees g  ON REGEXP_LIKE ( g.grantee, r.grantee_name_pattern )
	JOIN gtmp_grantable_objects o ON o.owner = r.owner AND o.object_name = r.object_name
	WHERE r.grantee_is_regexp = 'Y'
	UNION ALL
	SELECT r.owner,  o.object_name,  g.grantee,  r.grantable,  r.privilege,   r.request_type,   r.id
	FROM v_object_grant_requests r
	JOIN sys.all_grantees g  ON g.grantee = r.grantee_name_pattern 
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
BEGIN 
	ep_denormalize_grants( i_schema=> i_schema );

	execute immediate 'truncate table gtmp_object_privs';
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
		WITH foj_ as ( 
			SELECT 
			 f.owner f_own, f.object_name f_obj, f.privilege f_priv, f.grantee f_gtee, f.grantable f_admin
			,r.owner r_own, r.object_name r_obj, r.priv      r_priv, r.grantee r_gtee, r.grantable r_admin
			,r.request_id, r.request_type req_act
			FROM gtmp_object_privs f
			FULL OUTER JOIN gtmp_request_denormed r
			ON r.owner = f.owner AND r.object_name = f.object_name AND r.priv = f.privilege AND r.grantee = f.grantee
		)
		--SELECT * from foj_
		SELECT 
		    CASE req_act 
		    WHEN 'G' THEN
		        CASE 
		        WHEN f_priv IS NULL THEN 
		            CASE r_priv
		            WHEN 'SYNONYM' 
		            THEN 'CREATE OR REPLACE SYNONYM '||r_gtee||'.'||r_obj||' FOR '||r_own||'.'||r_obj
		            ELSE 'GRANT '||r_priv||' ON '||r_obj||'.' ||' TO '||r_gtee||CASE WHEN r_admin = 'Y' THEN ' with grant option' END
		            END
		        END  
		    WHEN 'R' THEN
		        CASE WHEN f_priv IS NOT NULL THEN 
		            CASE r_priv
		            WHEN 'SYNONYM' THEN 'DROP SYNONYM '||r_gtee||'.'||r_obj
		            ELSE 'REVOKE '||r_priv||' ON '||r_obj||'.' ||' FROM '||r_gtee
		            END
		        END
		    END AS action
		    , j.*
		FROM foj_ j
	) LOOP
		null;
	END LOOP;
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
