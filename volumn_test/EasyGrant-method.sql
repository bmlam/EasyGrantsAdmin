CONNECT crm_app/crm_app@ 192.168.178.36/orcl

set time on timing on 

BEGIN
	pck_grants_admin.ep_process_requests( 'CRM_APP' );
END;
/
