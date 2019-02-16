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

create or replace view HR.test_revoke AS SELECT * FROM employees;

grant select on hr.test_revoke to tester2;

create or replace synonym tester2.test_revoke for hr.test_revoke;

alter user hr identified by hr;

