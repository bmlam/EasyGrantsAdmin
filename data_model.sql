create 	     table object_grant_requests --OGR
(	         object_type               varchar2(30) NOT NULL
(	         ,owner               varchar2(30) NOT NULL
	         ,grantee_name_pattern	 varchar2(100)  NOT NULL
	         grantee_is_regexp_pattern char(1) CHECK( grantee_is_regexp_pattern in 'Y', 'N' ) )
	         ,priv	 varchar2(30) 
	         ,grantable	 char(1) CHECK( grantee_is_regexp_pattern in 'Y', 'N' ) )
	         ,last_grant_req_ts timestamp
	         ,last_revoke_req_ts  timestamp
	         ,request_reason   varchar2(200)
	         ,revoke_reason	 varchar2(200)
		,request_last_executed ts timestamp
);
	    
create 	 table detected_unrequested_grants -- DUG
(	         object_name	 varchar2(30) NOT NULL
(	         ,owner               varchar2(30) NOT NULL
	         ,grantee	 varchar2(30) NOT NULL
	         ,priv	 varchar2(30) NOT NULL
	         ,last_detect_ts 	timestamp
);

-- phase 2	     table grant_rules: GRu 
	         function_name    returs type of OGR
	         active_flg
	         actived_dt
	
create global temporary table gtmp_granted_objects
as select owner, object_name, object_type from dba_objects where 1=0
--for dba_objects of relevant types
;

create global temporary table gtmp_object_privs
--for dba_tab_privs for relevant grantees and 	relevant object types
as select table_owner, table_name, grantee, privilege, grantable
from dba_tab_privs where 1=0
;

create global temporary table gtmp_request_denormed
-- to stored denormalized requests
(	         object_name	 varchar2(30) NOT NULL
(	         ,owner               varchar2(30) NOT NULL
	         ,grantee	 varchar2(30) NOT NULL
	         ,priv	 varchar2(30) NOT NULL
	         ,last_detect_ts 	timestamp
);
	
create or replace view v_request_consolidated
-- to consolidate one request row as grant or revoke
;
	
	     package with procedures
	         to denormalize grant request from OGR and GRu
	         to validate name patterns, i.e. revoke and grants must not
	exist for the same object and same grantee. throw errors check
	validation fails
	         to process the requests which also merge into the DUG
