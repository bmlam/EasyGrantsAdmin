start revoke-privs.sql
start check_grant_status.sql

PROMPT First run of EasyGrantAdmin method to make sure the grants work
start traditional-method.sql
start check_grant_status.sql

PROMPT traditional method without revoking before since we are quite sure Oracle will take its time for grants
start check_grant_status.sql

PROMPT Second run of EasyGrantAdmin method to see how fast it is
start EasyGrant-method.sql

start check_grant_status.sql
