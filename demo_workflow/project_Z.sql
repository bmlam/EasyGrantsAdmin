PROMPT To revoke EXECUTE  and 
PROMPT To grant UPDATE 

MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' revoke_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'CRM_APP', 'PKG_CRM'    , 'APP_USER2'           , 'N'                  , 'EXECUTE'     , 'User abused the priv'        FROM dual
) src ON (
    src.owner = tgt.owner AND src.object_name = tgt.object_name AND src.grantee_name_pattern = tgt.grantee_name_pattern AND src.grantee_is_regexp = tgt.grantee_is_regexp AND src.privilege = tgt.privilege
)
WHEN NOT MATCHED THEN INSERT (
    owner,     object_name,     grantee_name_pattern,     grantee_is_regexp,     privilege,     revoke_reason,     last_revoke_req_ts
) VALUES (
    src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp, src.privilege, src.revoke_reason, systimestamp
)
WHEN MATCHED THEN UPDATE
    SET last_revoke_req_ts = systimestamp, revoke_reason = src.revoke_reason
; 

MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' grantable, '?' grant_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER2'           , 'N'                  , 'UPDATE'     , 'N'          , 'Project Z'     FROM dual
) src ON (
    src.owner = tgt.owner AND src.object_name = tgt.object_name AND src.grantee_name_pattern = tgt.grantee_name_pattern AND src.grantee_is_regexp = tgt.grantee_is_regexp AND src.privilege = tgt.privilege
)
WHEN NOT MATCHED THEN INSERT (
    owner,     object_name,     grantee_name_pattern,     grantee_is_regexp,     privilege,     grantable,     grant_reason,     last_grant_req_ts
) VALUES (
    src.owner, src.object_name, src.grantee_name_pattern, src.grantee_is_regexp, src.privilege, src.grantable, src.grant_reason, systimestamp
)
WHEN MATCHED THEN UPDATE
    SET grantable = src.grantable, last_grant_req_ts = systimestamp, grant_reason = src.grant_reason
;
COMMIT;
