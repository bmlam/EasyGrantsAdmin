-- pattern example
merge into object_grant_requests tgt
using (
select 'HR' owner,'DEPARTMENTS' object_name, 'APP_USER[1-3]' grantee_name_pattern
, 'Y'  grantee_is_regexp, 'SELECT' privilege, 'N' grantable
from dual
UNION ALL
select 'HR' owner,'DEPARTMENTS' object_name, 'APP_USER[2-4]' grantee_name_pattern
, 'Y'  grantee_is_regexp, 'SELECT' privilege, 'Y' grantable
from dual
) src
ON (src.owner = tgt.owner and src.object_name = tgt.object_name and src.grantee_name_pattern = tgt.grantee_name_pattern
and src.grantee_is_regexp = tgt.grantee_is_regexp and src.privilege = tgt.privilege)
WHEN NOT MATCHED THEN
INSERT ( owner, object_name, grantee_name_pattern, grantee_is_regexp
,privilege, grantable,  grant_reason,last_grant_req_ts
) VALUES
( src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp
,src.privilege, src.grantable , 'initial grant',systimestamp
)
WHEN MATCHED THEN UPDATE
SET grantable = src.grantable, last_revoke_req_ts = null, last_grant_req_ts = systimestamp
,grant_reason = 'initial grant'
;

-- revoke example 
merge into object_grant_requests tgt
using (
select 'HR' owner,'TEST_REVOKE' object_name, 'APP_USER2' grantee_name_pattern
, 'N'  grantee_is_regexp, 'SELECT' privilege, 'N' grantable
from dual
UNION ALL -- combined with previous this provokes ambiguity 
select 'HR' owner,'TEST_REVOKE' object_name, 'APP_USER2' grantee_name_pattern
, 'N'  grantee_is_regexp, 'SYNONYM' privilege, 'N' grantable
from dual
) src
ON (src.owner = tgt.owner and src.object_name = tgt.object_name and src.grantee_name_pattern = tgt.grantee_name_pattern
and src.grantee_is_regexp = tgt.grantee_is_regexp and src.privilege = tgt.privilege)
WHEN NOT MATCHED THEN
INSERT ( owner, object_name, grantee_name_pattern, grantee_is_regexp
,privilege, grantable,  grant_reason
,last_revoke_req_ts
) VALUES
( src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp
,src.privilege, src.grantable , 'initial grant'
,systimestamp
)
WHEN MATCHED THEN UPDATE
SET grantable = src.grantable, last_revoke_req_ts = systimestamp
,grant_reason = 'initial grant'
;

COMMIT;

