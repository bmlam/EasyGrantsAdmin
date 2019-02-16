
--
-- test runs 
-- 
exec pck_grants_admin.ep_denormalize_grants( i_schema =>'HR' );
exec pck_grants_admin.ep_process_requests ( i_schema =>'HR' );

select pck_grants_admin.ef_export_current_grants( 'HR' ) from dual;
select pck_grants_admin.ef_export_request_meta( 'HR' ) from dual;

-- data model 
SELECT * from V_fact_req_full_outer_join;

select regexp_instr( 'creAte synonym ', '^create|drop .*synonym', 1, 1, 0, 'i' ) f from dual;