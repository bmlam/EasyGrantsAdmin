In the following we describe how the workflow regarding privileges and synonyms may look like at 
a site which uses Easy Grant Admin tool. It is assumed that the site has two schemata.

SALES_APP which has these objects:
* Table PRODUCT
* Table ORDER
* Package PKG_ORDER_ENTRY

CRM_APP which has these objects:
* Table CUSTOMER
* Table HOUSE_ADDRESS
* Table COMMS_CHANNEL
* Package PKG_CRM
* Package PKG_SHIPPING

At our examplary site, the deployment workflow contains a step to run the following PLSQL block
for every application schema which needs to perform a grant or revoke privilege on its schema
objects:

```
BEGIN
	pck_grants_admin.ep_process_requests( USER );
END;
/
```

## Project X
Jack works during january on project X and needs to grant 
* SELECT on CRMP_APP.CUSTOMER to APP_USER1 
* EXECUTE on CRM_APP.PKG_CRM to APP_USER2 
* Create private synonym for APP_USER2 poiting to CRM_APP.PKG_CRM

For working with the tool, the company has provided a MERGE statement templates anyone can 
use. There is one template for GRANT and one for REVOKE.

Here is the template for **GRANT**:

```
MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' grantable, '?' grant_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'schema_xyz', 'table_xyz'    , 'grantee_xyz'           , 'N'                  , 'SELECT'     , 'N'          , 'Some grant reason'     FROM dual
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
```

Using the template, Jack will put these DML statements into his deployment script:

```
MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' grantable, '?' grant_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER1'           , 'N'                  , 'SELECT'     , 'N'          , 'Project X'     FROM dual
    UNION ALL 
    SELECT 'CRM_APP', 'PKG_CRM'     , 'APP_USER2'           , 'N'                  , 'EXECUTE'    , 'N'          , 'Project X'     FROM dual
    UNION ALL
    SELECT 'CRM_APP', 'PKG_CRM'     , 'APP_USER2'           , 'N'                  , 'SYNONYM'    , NULL         , 'Project X'     FROM dual 
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
```

## Project Y2
Emily works in april on her project and needs to grant 
* SELECT on SALES_APP.PRODUCT to APP_USER2 
* SELECT,INSERT,UPDATE on CRM_APP.COMMS_CHANNEL to APP_USER3

We mentioned there are 2 templates, one for GRANT and one for REVOKE. Below is the 
**REVOKE** template

```
MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' revoke_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'SCHEMA_XYZ', 'TABLE_XYZ'    , 'SOME_USER'           , 'N'                  , 'SOME_PRIV'     , 'Giva a reason'        FROM dual
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

```


Using the templates, she puts these DML statements into her deployment script:

```
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
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER2'           , 'N'                  , 'UPDATE'     , 'N'          , 'Project Y2'     FROM dual
    UNION ALL
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER2'           , 'N'                  , 'SYNONYM'     , 'N'          , 'Project Y2'     FROM dual
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
```

## Project Z
Let's assume it turns out that EXECUTE privilege on CRM_APP.PKG_CRM and the synonym need to be revoked, at 
the same time, APP_USER1 now should receive SELECT and INSERT privilege on SALES_APP.PRODUCT.
Louis has the job to take care of that in _october_. 


Thus Louis puts the following DML statements into his deployment script:

```
MERGE INTO object_grant_requests tgt USING (
    SELECT '?' owner   , '?' object_name, '?' grantee_name_pattern, '?' grantee_is_regexp, '?' privilege, '?' revoke_reason        FROM dual WHERE 1=0 /*layout inline view*/
    UNION ALL
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER2'           , 'N'                  , 'UPDATE'     , 'project Z: User abused the priv'        FROM dual
    UNION ALL
    SELECT 'CRM_APP', 'CUSTOMER'    , 'APP_USER2'           , 'N'                  , 'SYNONYM'     , 'project Z: User no longer needs this'        FROM dual
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
    SELECT 'SALES_APP', 'PRODUCT'    , 'APP_USER1'           , 'N'                  , 'SELECT'     , 'N'          , 'Project Z'     FROM dual
    UNION ALL
    SELECT 'SALES_APP', 'PRODUCT'    , 'APP_USER1'           , 'N'                  , 'INSERT'     , 'N'          , 'Project Z'     FROM dual
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
```

Note that with EasyGrantAdmin Louis does **not** need to touch neither the grant script from preject X nor any central script which might exist! If the site has a policy to maintain a central script, the task can be automated, saving programmer effort for other more valuable duties.


