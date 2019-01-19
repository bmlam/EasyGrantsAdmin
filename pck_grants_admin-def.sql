CREATE OR REPLACE PACKAGE pck_grants_admin AS

FUNCTION ef_export_current_grants
-- create a script for exisint grants so they can be declared as accepted grants.
-- non-accepted grants can be deleted manually from the script
( ip_schema IN VARCHAR2
, ip_default_reason VARCHAR2 DEFAULT 'for migration'
)
RETURN CLOB
;

END;
/

SHOW ERRORS
