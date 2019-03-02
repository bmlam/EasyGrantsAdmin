REM master script for convenience 
REM we switch between connecting users within this script

DEFINE pi_dba_connect_string=system/oracle@192.168.178.36/orcl
DEFINE pi_deployer_connect_string=crm_app/crm_app@192.168.178.36/orcl
DEFINE pi_app_schema_1_connect_string=crm_app/crm_app@192.168.178.36/orcl
DEFINE pi_app_schema_2_connect_string=sales_app/sales_app@192.168.178.36/orcl

COL PRIVILEGE FORMAT A20
COL TABLE_NAME FORMAT A30
COL OWNER FORMAT A20
COL GRANTEE FORMAT A20

SET PAGESize 50 LINESIZE 120
SET VERIFY OFF

PROMPT Project X set up 

CONNECT &pi_dba_connect_string

SET ECHO ON 

DROP SYNONYM app_user2.pkg_crm;
DROP PACKAGE crm_app.pkg_crm;
DROP TABLE   crm_app.customer;

CREATE TABLE crm_app.customer AS SELECT * FROM dual;

CREATE OR REPLACE PACKAGE crm_app.pkg_crm AS END;
/
SHOW ERRORS

PAUSE

PROMPT before deployment of project X
@@./verify_proj_x.sql

PAUSE

PROMPT Doing  deployment 

CONNECT &pi_deployer_connect_string

START ./project_X.sql

PROMPT Performing grant from schema CRM_APP
START ./deploy_bot-CRM_APP.sql

PAUSE

PROMPT after deployment  of project X

CONNECT & pi_dba_connect_string
START ./verify_proj_x.sql

