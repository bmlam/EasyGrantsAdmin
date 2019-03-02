MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' grantable, '?' grant_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'SALES_APP', 'PRODUCT'          , 'APP_USER2'           , 'N'                  , 'SELECT'    , 'N'          , 'Project Y2'     FROM dual
    UNION ALL
    SELECT 'CRM_APP',   'COMMS_CHANNEL'    , 'APP_USER1'           , 'N'                  , 'SELECT'     , 'N'          , 'Project Y2'     FROM dual
    UNION ALL
    SELECT 'CRM_APP',   'COMMS_CHANNEL'    , 'APP_USER1'           , 'N'                  , 'INSERT'     , 'N'          , 'Project Y2'     FROM dual
    UNION ALL
    SELECT 'CRM_APP',   'COMMS_CHANNEL'    , 'APP_USER1'           , 'N'                  , 'UPDATE'     , 'N'          , 'Project Y2'     FROM dual
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