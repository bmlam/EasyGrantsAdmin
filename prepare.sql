--select * from v$database;
--select * from gv$option;
--select * from v$instance;
--select * from gv$version;

create user service identified by service;
grant connect to service;
alter user service quota 1 g on  users;
grant select on dba_tab_privs to service;
grant select on dba_objects to service;
grant create any synonym to service;
grant drop any synonym to service;

create user tester1 identified by tester1;
create user tester2 identified by tester2;
create user appl1 identified by appl2;
