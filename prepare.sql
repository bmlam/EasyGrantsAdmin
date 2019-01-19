--select * from v$database;
--select * from gv$option;
--select * from v$instance;
--select * from gv$version;

create user service identified by service;
grant connect to service;

create user tester1 identified by tester1;
create user tester2 identified by tester2;
create user appl1 identified by appl2;
