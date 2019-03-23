BEGIN
	IF user <> 'CRM_APP' THEN 
		RAISE_APPLICATION_ERROR( -20001, 'Wrong connecting user!' );
	END IF;

	pck_std_log.switch_debug( true );
	pck_grants_admin.ep_process_requests( USER );
	
END;
/
