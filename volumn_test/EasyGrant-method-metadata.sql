PROMPT insert grant metadata with EasyGrant method

MERGE INTO object_grant_requests tgt USING (
		SELECT ot.owner, ot.object_name
			,'APP_USER[1-3]' grantee_name_pattern
			,'Y' grantee_is_regexp
			,CASE ot.otype 
			WHEN 'TABLE' THEN 'SELECT'
			WHEN 'PACKAGE' THEN 'EXECUTE'
			END AS privilege
			,'VOLUMN test' grant_reason
			,'N' grantable 
		FROM grant_admin.VW_VOL_TEST_OBJECTS ot
        WHERE 1=1
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
