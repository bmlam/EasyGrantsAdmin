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
	
--drop table gtmp_grantable_objects;
create /*permanent during testingglobal temporary  */ 
table gtmp_grantable_objects
--on commit preserve rows
as select owner, object_name, object_type from all_objects where 1=0
--for dba_objects of relevant types
;
--drop table gtmp_request_denormed ;
create /*permanent during testingglobal temporary  */ 
table gtmp_object_privs
on commit preserve rows
--for dba_tab_privs for relevant grantees and 	relevant object types
as select table_schema as owner, table_name as object_name, grantee, privilege, grantable
from all_tab_privs where 1=0
;

--DROP TABLE gtmp_request_denormed;
create /*permanent during testingglobal temporary  */ 
table gtmp_request_denormed
-- to stored denormalized requests
(	         object_name	 varchar2(30) NOT NULL
	         ,owner               varchar2(30) NOT NULL
	         ,grantee	 varchar2(30) NOT NULL
	         ,grantable	 char(1) 
	         ,priv	 varchar2(30) NOT NULL
	         ,request_type 	char(1) CHECK( request_type in ('G', 'R' ) )
             ,request_id    NUMBER NOT NULL 
             ,based_on_regexp CHAR(1) NOT NULL 
             ,request_ts timestamp
)
--on commit preserve rows
;
	
create table request_process_results
-- consider auto partition by timestamp 
(REQ_ID  NUMBER             NOT NULL 
,REQ_TYPE  VARCHAR2(1)      NOT NULL 
,GRANTABLE             VARCHAR2(1)    
,PROCESSed_TS   TIMESTAMP         NOT NULL 
,result_type           VARCHAR2(8)    NOT NULL 
,overruled_by_req_id    NUMBER 
,FAILED_DDL            VARCHAR2(2000) 
,ERROR_MSG             VARCHAR2(2000)
);
--	     package with procedures
--	         to denormalize grant request from OGR and GRu
--	         to validate name patterns, i.e. revoke and grants must not
--	exist for the same object and same grantee. throw errors check
--	validation fails
--	         to process the requests which also merge into the DUG

create or replace view v_object_grant_requests  as
WITH add_flag_ AS (
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
)
SELECT a.*
  ,CASE request_type WHEN 'G' THEN last_grant_req_ts WHEN 'R' THEN last_revoke_req_ts END as request_ts
FROM add_flag_ a
;

--DROP VIEW F_fact_req_full_outer_join;
create or replace view V_fact_req_full_outer_join as 
		WITH foj_ as ( 
			SELECT r.request_id
            ,r.based_on_regexp regex
			,r.request_type req_type
            ,r.request_ts
            ,row_number() 
                OVER (PARTITION BY r.owner, r.object_name, r.priv, r.grantee
                    ORDER BY CASE r.based_on_regexp WHEN 'N' THEN 1 ELSE 2 END, r.request_ts DESC ) 
             AS prio
           ,first_value( r.request_id) 
                OVER (PARTITION BY r.owner, r.object_name, r.priv, r.grantee
                    ORDER BY CASE r.based_on_regexp WHEN 'N' THEN 1 ELSE 2 END, r.request_ts DESC ) 
            AS winner_req_id
			,f.owner f_own, f.object_name f_obj, f.privilege f_priv, f.grantee f_gtee, f.grantable f_admin
			,r.owner r_own, r.object_name r_obj, r.priv      r_priv, r.grantee r_gtee, r.grantable r_admin
			FROM gtmp_object_privs f
			FULL OUTER JOIN gtmp_request_denormed r
			ON r.owner = f.owner AND r.object_name = f.object_name AND r.priv = f.privilege AND r.grantee = f.grantee
		)
		--SELECT * from foj_
		SELECT 
		    j.*
		    ,CASE req_type 
		    WHEN 'G' THEN
		        CASE 
		        WHEN f_priv IS NULL THEN 
		            CASE r_priv
		            WHEN 'SYNONYM' 
		            THEN 'CREATE OR REPLACE SYNONYM '||r_gtee||'.'||r_obj||' FOR '||r_own||'.'||r_obj
		            ELSE 'GRANT '||r_priv||' ON '||r_own||'.'||r_obj ||' TO '||r_gtee||CASE WHEN r_admin = 'Y' THEN ' with grant option' END
		            END
		        END  
		    WHEN 'R' THEN
		        CASE WHEN f_priv IS NOT NULL THEN 
		            CASE r_priv
		            WHEN 'SYNONYM' THEN 'DROP SYNONYM '||r_gtee||'.'||r_obj
		            ELSE 'REVOKE '||r_priv||' ON '||r_own||'.'||r_obj ||' FROM '||r_gtee
		            END
		        END
		    END AS ddl
		FROM foj_ j
order by coalesce(r_own, f_own), coalesce(r_obj, f_obj), coalesce(r_priv, f_priv), coalesce( r_gtee, f_gtee)        
;