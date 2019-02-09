CREATE OR REPLACE PACKAGE pck_grants_admin 
AUTHID CURRENT_USER
AS

FUNCTION ef_export_current_grants
-- create a script for exisint grants so they can be declared as accepted grants.
-- non-accepted grants can be deleted manually from the script
( i_schema IN VARCHAR2
, i_default_reason VARCHAR2 DEFAULT 'for migration'
)
RETURN CLOB
;

PROCEDURE ep_denormalize_grants
--to denormalize grant request from OGR and GRu
( i_schema IN VARCHAR2
)
;

PROCEDURE ep_process_requests
--to process the requests which also merge into the DUG
( i_schema VARCHAR2
)
;
END;
/

SHOW ERRORS
