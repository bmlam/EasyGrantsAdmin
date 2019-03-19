SET SCAN ON
DEFINE &gran_admin_schema=gran_admin

create user &gran_admin_schema identified by &gran_admin_schema quota 100m on users
;
grant resource, create session to &gran_admin_schema
;
grant create view to &gran_admin_schema
;
grant create any synonym to &gran_admin_schema
;
grant drop any synonym to &gran_admin_schema
;
--grant select on dba_objects to &gran_admin_schema;
--grant select on dba_synonyms to &gran_admin_schema;
--grant select on dba_tab_privs to &gran_admin_schema;
--grant select on dba_users to &gran_admin_schema;
--grant select on dba_roles to &gran_admin_schema;

create or replace view all_grantees
as 
select username AS grantee
from dba_users
union 
select role from dba_roles
;

grant select on all_grantees to public;
create or replace public synonym all_grantees for sys.all_grantees;

