--drop 	     table object_grant_requests ;
create 	     table object_grant_requests --OGR
(	        id NUMBER generated always as identity
            , object_name               varchar2(30) NOT NULL
             ,owner               varchar2(30) NOT NULL
	         ,grantee_name_pattern	 varchar2(100)  NOT NULL
	         ,grantee_is_regexp char(1) CHECK( grantee_is_regexp in ('Y', 'N' ) )
	         ,privilege	 varchar2(30) NOT NULL
	         ,grantable	 char(1) CHECK( grantable in ('Y', 'N' ) )
	         ,last_grant_req_ts timestamp
	         ,last_revoke_req_ts  timestamp
	         ,grant_reason   varchar2(200)
	         ,revoke_reason	 varchar2(200)
		,request_last_executed timestamp
);

create or replace view v_object_grant_requests 
as
SELECT id, object_name, owner
  ,grantee_name_pattern, grantee_is_regexp
  , privilege
  , CASE WHEN last_grant_req_ts > last_revoke_req_ts OR last_revoke_req_ts IS NULL THEN 'G'
    ELSE 'R'
    END  AS REQUEST_TYPE
  , grantable
  , last_grant_req_ts
  , last_revoke_req_ts
  , grant_reason, revoke_reason
FROM object_grant_requests
;
--drop 	 table detected_unrequested_grants ;
create 	 table detected_unrequested_grants -- DUG
(	        id NUMBER generated always as identity
            ,object_name	 varchar2(30) NOT NULL
	         ,owner               varchar2(30) NOT NULL
	         ,grantee	 varchar2(30) NOT NULL
	         ,priv	 varchar2(30) NOT NULL
	         ,last_detected 	timestamp
);

-- phase 2	     table grant_rules: GRu 
--	         function_name    returs type of OGR
--	         active_flg
--	         actived_dt
	
create global temporary table gtmp_grantable_objects
on commit preserve rows
as select owner, object_name, object_type from all_objects where 1=0
--for dba_objects of relevant types
;
drop table gtmp_request_denormed ;
create global temporary table gtmp_object_privs
on commit preserve rows
--for dba_tab_privs for relevant grantees and 	relevant object types
as select table_schema as owner, table_name as object_name, grantee, privilege, grantable
from all_tab_privs where 1=0
;

create global temporary table gtmp_request_denormed
-- to stored denormalized requests
(	         object_name	 varchar2(30) NOT NULL
	         ,owner               varchar2(30) NOT NULL
	         ,grantee	 varchar2(30) NOT NULL
	         ,grantable	 char(1) 
	         ,priv	 varchar2(30) NOT NULL
	         ,request_type 	char(1) CHECK( request_type in ('G', 'R' ) )
             ,request_id    NUMBER NOT NULL 
)
on commit preserve rows
;
	
create table request_process_events
(REQUEST_ID  NUMBER          NOT NULL 
,REQUEST_TYPE  VARCHAR2(1)     NOT NULL 
,PROCESS_TS   TIMESTAMP(6)    NOT NULL 
,GRANTABLE             VARCHAR2(1)    
,SUCCEEDED             VARCHAR2(1)    
,FAILED_DDL            VARCHAR2(2000) 
,ERROR_MSG             VARCHAR2(2000)
);
--	     package with procedures
--	         to denormalize grant request from OGR and GRu
--	         to validate name patterns, i.e. revoke and grants must not
--	exist for the same object and same grantee. throw errors check
--	validation fails
--	         to process the requests which also merge into the DUG
