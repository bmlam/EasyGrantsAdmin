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


