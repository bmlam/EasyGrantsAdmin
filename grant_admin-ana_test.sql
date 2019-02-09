--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/log_table.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/debug_user.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/long_log.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-def.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-impl.sql
--@/Users/bmlam/Dropbox/logging/loggingInOracleDB/pck_std_log-shorthands.sql

@/Users/bmlam/Dropbox/EasyGrantsAdmin/p_trunc_table.sql
@/Users/bmlam/Dropbox/EasyGrantsAdmin/p_log_result.sql
@/Users/bmlam/Dropbox/EasyGrantsAdmin/pck_grants_admin_private-def.sql
@/Users/bmlam/Dropbox/EasyGrantsAdmin/pck_grants_admin_private-impl.sql
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
select systimestamp from dual;
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
select * from REQUEST_PROCESS_RESULTS order by processed_ts desc;

--
-- Our data model 
--

select * from sys.all_grantees;

select REQUEST_TYPE rty, t.* from v_object_grant_requests t
--where grantee_is_regexp='Y'
order by id desc
;

select * from gtmp_request_denormed order by grantee, owner, object_name, priv;
select * from gtmp_grantable_objects;
select * from gtmp_object_privs;


-- pattern example
merge into object_grant_requests tgt
using (
select 'HR' owner,'DEPARTMENTS' object_name, 'TESTER[1-3]' grantee_name_pattern
, 'Y'  grantee_is_regexp, 'SELECT' privilege, 'N' grantable
from dual
UNION ALL
select 'HR' owner,'DEPARTMENTS' object_name, 'TESTER[2-4]' grantee_name_pattern
, 'Y'  grantee_is_regexp, 'SELECT' privilege, 'Y' grantable
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
UNION ALL -- combined with previous this provokes ambiguity 
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

