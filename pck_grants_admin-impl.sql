CREATE OR REPLACE PACKAGE BODY pck_grants_admin AS

PROCEDURE ep_denormalize_grants
--to denormalize grant request from OGR and GRu
( ip_schema IN VARCHAR2
)
AS BEGIN NULL;
END ep_denormalize_grants;

FUNCTION ef_report_conflicts
-- to validate name patterns, i.e. revoke and grants must not exist for the same object
( ip_raise_conflicts_flg IN NUMBER DEFAULT 1
)
RETURN CLOB
AS BEGIN NULL;
END ef_report_conflicts;


PROCEDURE ep_process_requests
--to process the requests which also merge into the DUG
( ip_schema VARCHAR2
)
AS BEGIN NULL;
END ep_process_requests;


FUNCTION ef_export_current_grants
-- create a script for exisint grants so they can be declared as accepted grants.
-- non-accepted grants can be deleted manually from the script
( ip_schema IN VARCHAR2
  , ip_default_reason VARCHAR2 DEFAULT 'for migration'
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
		WHERE owner = ip_schema
	) LOOP
		lv_merge := lc_merge_template;
		lv_merge :=		replace( lv_merge, '<owner>', gr_rec.owner) ;
		lv_merge :=		replace( lv_merge, '<object_name>', gr_rec.object_name ) ;
		lv_merge :=		replace( lv_merge, '<grantee_name_pattern>', gr_rec.grantee ) ;
		lv_merge :=		replace( lv_merge, '<privilege>', gr_rec.privilege ) ;
		lv_merge :=		replace( lv_merge, '<grantable>', gr_rec.grantable ) ;
		lv_merge :=		replace( lv_merge, '<grant_reason>', replace( ip_default_reason, '''', '') ) ;

		lv_return := CASE WHEN gr_rec.rn > 1 THEN lv_return||chr(10) END
			||lv_merge;
	END LOOP;
	RETURN  lv_return;
END ef_export_current_grants;

END;
/

SHOW ERRORS
