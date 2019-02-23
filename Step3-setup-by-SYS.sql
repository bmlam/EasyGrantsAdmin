
create or replace public synonym gtmp_object_privs for grant_admin.gtmp_object_privs;
create or replace public synonym gtmp_request_denormed for grant_admin.gtmp_request_denormed;
create or replace public synonym pck_grants_admin for grant_admin.pck_grants_admin;
create or replace public synonym request_process_results for grant_admin.request_process_results;
create or replace public synonym V_fact_req_full_outer_join for grant_admin.V_fact_req_full_outer_join;
create or replace public synonym object_grant_requests for grant_admin.object_grant_requests;
create or replace public synonym REQUEST_PROCESS_RESULTS for grant_admin.REQUEST_PROCESS_RESULTS;
create or replace public synonym v_object_grant_requests for grant_admin.v_object_grant_requests;

grant SELECT on grant_admin.object_grant_requests to PUBLIC;
grant SELECT on grant_admin.REQUEST_PROCESS_RESULTS to PUBLIC;


grant execute on grant_admin.pck_grants_admin to CRM_APP;
grant ALL on grant_admin.object_grant_requests to CRM_APP;
grant SELECT,INSERT on grant_admin.gtmp_grantable_objects to CRM_APP;
grant SELECT,INSERT on grant_admin.gtmp_request_denormed to CRM_APP;
grant SELECT,INSERT on grant_admin.gtmp_object_privs to CRM_APP;
grant SELECT on grant_admin.v_object_grant_requests to CRM_APP;
grant SELECT on grant_admin.V_fact_req_full_outer_join to CRM_APP;

grant execute on grant_admin.pck_grants_admin to SALES_APP;
grant ALL on grant_admin.object_grant_requests to SALES_APP;
grant SELECT,INSERT on grant_admin.gtmp_grantable_objects to SALES_APP;
grant SELECT,INSERT on grant_admin.gtmp_request_denormed to SALES_APP;
grant SELECT,INSERT on grant_admin.gtmp_object_privs to SALES_APP;
grant SELECT on grant_admin.v_object_grant_requests to SALES_APP;
grant SELECT on grant_admin.V_fact_req_full_outer_join to SALES_APP;


