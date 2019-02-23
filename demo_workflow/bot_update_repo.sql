SET ECHO OFF
REM this script extracts the grant metadata into a MERGE script for table OBJECT_GRANT_REQUESTS
REM at sites which wish to have a central script as backup for the existing grants and synonyms
REM 
REM this script can be run as a final step of the deployment workflow or scheduled periodically
REM at a convenient time
REM It can be modified to spool the generated script into a repository file which then can be 
REM checked in automatically

set LONG 1000000000
set LONGCHUNK 1000000000
set LINESIZE 1000 PAGES 0 HEADING OFF 

rem set verify off 
rem set echo off
rem set feedback off

spool /c/temp/export.sql 

PROMPT exporting requests on objects in schema CRM_APP
SELECT  pck_grants_admin.ef_export_request_meta(i_schema=> 'CRM_APP' )
FROM dual
;

PROMPT exporting requests on objects in schema SALES_APP
SELECT  pck_grants_admin.ef_export_request_meta(i_schema=> 'SALES_APP' )
FROM dual
;
set feedback on echo on

spool off
