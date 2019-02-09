--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/log_table.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/debug_user.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/long_log.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-def.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-impl.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-shorthands.sql

@/Users/bmlam/Dropbox/EasyGrantsAdmin/pck_grants_admin-def.sql
@/Users/bmlam/Dropbox/EasyGrantsAdmin/pck_grants_admin-impl.sql

--
-- test runs 
-- 
exec pck_grants_admin.ep_denormalize_grants( i_schema =>'HR' );
exec pck_grants_admin.ep_process_requests ( i_schema =>'HR' );

select pck_grants_admin.ef_export_current_grants( 'HR' ) from dual;
--
-- data dict
-- 
select * from dba_tab_privs;
select * from object_grant_requests order by 2;

select * from dba_tab_privs where owner = 'SYSTEM';
select owner,count(1), count(distinct grantee) from dba_tab_privs 
group by owner
order by 1
;

-- log table 
select component loc, 'Y'||to_char(timestamp, 'rr.mmdd hh24:miss')ts, text txt, t.* from log_table t 
order by id desc
;

--
-- Our data model 
--
select * from REQUEST_PROCESS_RESULTS order by processed_ts desc;

select * from sys.all_grantees;

select REQUEST_TYPE rty, t.* from v_object_grant_requests t
--where grantee_is_regexp='Y'
;
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
            ELSE 'GRANT '||r_priv||' ON '||r_obj||'.' ||' TO '||r_gtee||'; '
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
;

select * from gtmp_request_denormed order by grantee, owner, object_name, priv;
select * from gtmp_grantable_objects;
select * from gtmp_object_privs;
select * from user_objects;


-- pattern example
merge into object_grant_requests tgt
using (
select 'HR' owner,'DEPARTMENTS' object_name, 'TESTER[1-3]' grantee_name_pattern
, 'Y'  grantee_is_regexp, 'SELECT' privilege, 'N' grantable
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

-- revoke example 
merge into object_grant_requests tgt
using (
select 'HR' owner,'TEST_REVOKE' object_name, 'TESTER2' grantee_name_pattern
, 'N'  grantee_is_regexp, 'SELECT' privilege, 'N' grantable
from dual
UNION ALL 
select 'HR' owner,'TEST_REVOKE' object_name, 'TESTER2' grantee_name_pattern
, 'N'  grantee_is_regexp, 'SYNONYM' privilege, 'N' grantable
from dual
) src
ON (src.owner = tgt.owner and src.object_name = tgt.object_name and src.grantee_name_pattern = tgt.grantee_name_pattern
and src.grantee_is_regexp = tgt.grantee_is_regexp and src.privilege = tgt.privilege)
WHEN NOT MATCHED THEN
INSERT ( owner, object_name, grantee_name_pattern, grantee_is_regexp
,privilege, grantable,  grant_reason
,last_revoke_req_ts
) VALUES
( src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp
,src.privilege, src.grantable , '<grant_reason>'
,systimestamp
)
WHEN MATCHED THEN UPDATE
SET grantable = src.grantable, last_revoke_req_ts = systimestamp
,grant_reason = '<grant_reason>'
;
