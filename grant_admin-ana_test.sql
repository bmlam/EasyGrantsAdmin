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

exec pck_grants_admin.ep_denormalize_grants( i_schema => user );
exec pck_grants_admin.ep_process_requests ( i_schema =>user );

select * from object_grant_requests order by grantee_name_pattern, owner, object_name, privilege;

select * from all_tables where table_name like 'GT%';
select * from gtmp_request_denormed order by grantee, owner, object_name, priv;
select * from gtmp_grantable_objects;
select * from gtmp_object_privs;
-- data model 
SELECT * from V_fact_req_full_outer_join;


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
select * from v_object_grant_requests;
select * from all_grantees;
select * from gtmp_grantable_objects;

