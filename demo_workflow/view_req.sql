SET ECHO OFF 
column id format 9999999
column OBJECT_NAME FORMAT A20
column OWNER FORMAT A12
column GRANTEE_NAME_PATTERN FORMAT A20
column PRIVILEGE FORMAT A12
column PRIVILEGE FORMAT A12
column regex FORMAT A5
column req_reason FORMAT A20

SET PAGES 100 LINES 140

alter session set nls_date_format = 'yyyy.mm.dd hh24:mi:ss';

SET ECHO Off feedback on 

PROMPT current request metadata

SELECT 
	ID
 ,OBJECT_NAME
 ,OWNER
 ,GRANTEE_NAME_PATTERN
 ,GRANTEE_IS_REGEXP regex
 ,PRIVILEGE
 ,REQUEST_TYPE
 ,CAst (REQUEST_TS as date) request_ts
,case request_type when 'G' then grant_reason when 'R' then revoke_reason end req_reason
FROM v_object_grant_requests
WHERE REGEXP_LIKE( owner, '(CRM|SALES)_APP' )
  AND object_name NOT LIKE 'VOL_TEST%'
ORDER BY request_ts
;
SET ECHO On 
