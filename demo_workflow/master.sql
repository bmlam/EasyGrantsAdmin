SET ECHO OFF TERMOUT OFF
REM master script for convenience 
REM we switch between connecting users within this script

REM The following way to define connection data and credentials is not recommended 
REM for copying in real life projects!
REM Dropping and recreating objects as done here is only acceptable for demo purpose!

SET ECHO ON VERIFY ON 

DEFINE pi_connection_data=192.168.178.36/orcl

DEFINE pi_dba_credential=system/oracle
DEFINE pi_app_schema_1_credential=crm_app/crm_app
DEFINE pi_app_schema_2_credential=sales_app/sales_app

DEFINE pi_dba_connect_string=&pi_dba_credential@&pi_connection_data
DEFINE pi_app_schema_1_connect_string=&pi_app_schema_1_credential@&pi_connection_data
DEFINE pi_app_schema_2_connect_string=&pi_app_schema_2_credential@&pi_connection_data

COL PRIVILEGE FORMAT A20
COL TABLE_NAME FORMAT A30
COL OWNER FORMAT A20
COL GRANTEE FORMAT A20


SET PAGESize 50 LINESIZE 120
SET VERIFY ON TIME ON TIMING ON 
PROMPT Project X set up 

SET ECHO ON TERMOUT ON FEEDBACK ON

CONNECT &pi_dba_connect_string

DROP SYNONYM app_user2.pkg_crm;
DROP PACKAGE crm_app.pkg_crm;
DROP TABLE   crm_app.customer;

DROP TABLE   crm_app.COMMS_CHANNEL;
DROP TABLE   sales_app.PRODUCT;

CREATE TABLE crm_app.customer AS SELECT * FROM dual;

CREATE OR REPLACE PACKAGE crm_app.pkg_crm AS END;
/
SHOW ERRORS

DELETE object_grant_requests WHERE REGEXP_LIKE( owner, '(CRM|SALES)_APP' ) AND object_name NOT LIKE 'VOL_TEST%'
;
COMMIT;

PROMPT before deployment of project X

start ./verify.sql
PAUSE
start ./view_req.sql
PAUSE

PROMPT Deploying project_x

CONNECT &pi_app_schema_1_connect_string

START ./project_X.sql
PAUSE
START ./view_req.sql

PROMPT Performing grant from schema CRM_APP
START ./deploy_bot-CRM_APP.sql
PAUSE

PROMPT after deployment  of project X

CONNECT &pi_dba_connect_string
START ./verify.sql
PAUSE

PROMPT *******   Project y2 set up  ********
PROMPT Re-create objects, which means object privs that may have existed before will vanish

CONNECT &pi_dba_connect_string


SET ECHO ON 

DROP TABLE crm_app.COMMS_CHANNEL ;
DROP TABLE sales_app.PRODUCT; 
CREATE TABLE crm_app.COMMS_CHANNEL AS SELECT * FROM dual;
CREATE TABLE sales_app.PRODUCT AS SELECT * FROM dual;

PAUSE 

PROMPT Doing  deployment for project y2

CONNECT &pi_app_schema_1_connect_string

START ./project_y2.sql
PAUSE
START ./view_req.sql
PAUSE

PROMPT Performing grant from schema CRM_APP
START ./deploy_bot-CRM_APP.sql
PAUSE

PROMPT Performing grant from schema SALES_APP
CONNECT &pi_app_schema_2_connect_string
START ./deploy_bot-SALES_APP.sql
PAUSE

PROMPT ******** after deployment  of project z2 **********+

CONNECT &pi_dba_connect_string
START ./verify.sql

PROMPT deployment for project_z (No new objects required)
PAUSE

CONNECT &pi_app_schema_1_connect_string

START ./project_z.sql
PAUSE
START ./view_req.sql
PAUSE

PROMPT Performing grant from schema CRM_APP
START ./deploy_bot-CRM_APP.sql
PAUSE

PROMPT Performing grant from schema SALES_APP
CONNECT &pi_app_schema_2_connect_string
START ./deploy_bot-SALES_APP.sql
PAUSE

PROMPT ***********  after deployment  of project z ***********

CONNECT &pi_dba_connect_string
START ./verify.sql
PAUSE

PROMPT end of demo
