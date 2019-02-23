REM master script for convenience 
REM we switch between connecting users within this script

CONNECT crm_app/crm_app@192.168.178.36/orcl

PROMPT before deployment 
@@./verify_proj_x.sql

PROMPT Doing  deployment 
@@./project_X.sql

PROMPT Performing grant from schema CRM_APP
@@./deploy_bot-CRM_APP.sql

PROMPT after deployment 
@@./verify_proj_x.sql
