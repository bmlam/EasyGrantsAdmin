-- application user CRM_APP
create user crm_app identified by crm_app
;
alter user crm_app quota 100m on users
;
grant select on dba_objects to CRM_APP
;
grant select on dba_synonyms to CRM_APP
;
grant select on dba_tab_privs to CRM_APP
;
grant create session to CRM_APP
;
grant resource to CRM_APP
;

-- application user SALES_APP
create user sales_app identified by sales_app
;
alter user sales_app quota 100m on users
;
grant select on dba_objects to SALES_APP
;
grant select on dba_synonyms to SALES_APP
;
grant select on dba_tab_privs to SALES_APP
;
grant create session to SALES_APP
;
grant resource to SALES_APP
;


-- crm_app schema objects for demo
CREATE TABLE crm_APP.CUSTOMER AS SELECT * FROM DUAL;
CREATE TABLE crm_APP.COMMS_CHANNEL   AS SELECT * FROM DUAL;

CREATE OR REPLACE PACKAGE crm_APP.PKG_CRM AS BEGIN NULL; END;
/

-- SALES_app schema objects for demo
CREATE TABLE SALES_APP.PRODUCT AS SELECT * FROM DUAL;
CREATE TABLE SALES_APP."ORDER"   AS SELECT * FROM DUAL;

CREATE  OR REPLACE PACKAGE SALES_APP.PKG_ORDER_ENTRY AS BEGIN NULL; END;
/

create user app_user1 identified by app_user1;
create user app_user2 identified by app_user2;
create user app_user3 identified by app_user3;

