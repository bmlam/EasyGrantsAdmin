REM perform grant of object privileges in schema CRM_APP
REM it may make sense to check that the current user is indeed CRM_APP

SHOW USER

BEGIN
	pck_grants_admin.ep_process_requests( USER );
END;
/
