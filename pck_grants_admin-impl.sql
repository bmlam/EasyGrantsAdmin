CREATE OR REPLACE PACKAGE BODY pck_grants_admin AS

PROCEDRE ep_denormalize_grants
--to denormalize grant request from OGR and GRu
( ip_schema VARCHAR2
)
AS BEGIN NULL
END ;

FUNCTION ef_report_conflicts
-- to validate name patterns, i.e. revoke and grants must not exist for the same object
( ip_raise_conflicts_flg NUMBER DEFAULT 1
) RETURN CLOB
AS BEGIN NULL
END ;
;

PROCEDURE ep_process_requests
--to process the requests which also merge into the DUG
( ip_schema VARCHAR2
)
AS BEGIN NULL
END ;


END;
/

SHOW ERRORS
