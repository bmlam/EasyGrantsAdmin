create user grant_admin identified by grant_admin quota 100m on users;

grant resource, create session to grant_admin
;
grant create view to grant_admin
;
grant create any synonym to grant_admin
;
grant drop any synonym to grant_admin
;
grant select on dba_objects to grant_admin
;
grant select on dba_synonyms to grant_admin
;
grant select on dba_tab_privs to grant_admin
;
grant select on dba_users to grant_admin
;
grant select on dba_roles to grant_admin
;

-- application user
grant select on dba_objects to HR
;
grant select on dba_synonyms to HR
;
grant select on dba_tab_privs to HR
;

create or replace view all_grantees
as 
select username AS grantee
from dba_users
union 
select role from dba_roles
;

grant select on all_grantees to public;
create or replace public synonym all_grantees for sys.all_grantees;

create user tester1 identified by tester1;
create user tester2 identified by tester2;

grant select on hr.departments to tester1;
grant select on hr.employees to tester1;

grant select on hr.departments to tester2;

create table hr.test_revoke as select * from dual;
grant select on hr.test_revoke to tester2;

create or replace synonym tester2.test_revoke for hr.test_revoke;

alter user hr identified by hr;

grant execute on grant_admin.pck_grants_admin to hr;

create or replace public synonym gtmp_object_privs for grant_admin.gtmp_object_privs;
create or replace public synonym gtmp_request_denormed for grant_admin.gtmp_request_denormed;
create or replace public synonym pck_grants_admin for grant_admin.pck_grants_admin;
create or replace public synonym request_process_results for grant_admin.request_process_results;
create or replace public synonym V_fact_req_full_outer_join for grant_admin.V_fact_req_full_outer_join;
create or replace public synonym v_object_grant_requests for grant_admin.v_object_grant_requests;


create or replace public synonym xxx for grant_admin.xxx;



grant SELECT,INSERT on grant_admin.gtmp_grantable_objects to HR;
grant SELECT,INSERT on grant_admin.gtmp_request_denormed to HR;
grant SELECT,INSERT on grant_admin.gtmp_object_privs to HR;

grant SELECT on grant_admin.v_object_grant_requests to HR;
grant SELECT on grant_admin.V_fact_req_full_outer_join to HR;


--drop procedure grant_admin.p_trunc_table;

CREATE SYNONYM TESTER2.TEST_REVOKE FOR hr.test_revoke;

