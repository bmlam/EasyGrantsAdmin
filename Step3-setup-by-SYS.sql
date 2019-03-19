SET SCAN ON
DEFINE &gran_admin_schema=gran_admin

create or replace public synonym gtmp_object_privs for &gran_admin_schema.gtmp_object_privs;
create or replace public synonym gtmp_request_denormed for &gran_admin_schema.gtmp_request_denormed;
create or replace public synonym pck_grants_admin for &gran_admin_schema.pck_grants_admin;
create or replace public synonym request_process_results for &gran_admin_schema.request_process_results;
create or replace public synonym V_fact_req_full_outer_join for &gran_admin_schema.V_fact_req_full_outer_join;
create or replace public synonym object_grant_requests for &gran_admin_schema.object_grant_requests;
create or replace public synonym REQUEST_PROCESS_RESULTS for &gran_admin_schema.REQUEST_PROCESS_RESULTS;
create or replace public synonym v_object_grant_requests for &gran_admin_schema.v_object_grant_requests;

grant SELECT on &gran_admin_schema.object_grant_requests to PUBLIC;
grant SELECT on &gran_admin_schema.REQUEST_PROCESS_RESULTS to PUBLIC;


grant execute on &gran_admin_schema.pck_grants_admin to CRM_APP;
grant ALL on &gran_admin_schema.object_grant_requests to CRM_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_grantable_objects to CRM_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_request_denormed to CRM_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_object_privs to CRM_APP;
grant SELECT on &gran_admin_schema.v_object_grant_requests to CRM_APP;
grant SELECT on &gran_admin_schema.V_fact_req_full_outer_join to CRM_APP;

grant execute on &gran_admin_schema.pck_grants_admin to SALES_APP;
grant ALL on &gran_admin_schema.object_grant_requests to SALES_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_grantable_objects to SALES_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_request_denormed to SALES_APP;
grant SELECT,INSERT on &gran_admin_schema.gtmp_object_privs to SALES_APP;
grant SELECT on &gran_admin_schema.v_object_grant_requests to SALES_APP;
grant SELECT on &gran_admin_schema.V_fact_req_full_outer_join to SALES_APP;


