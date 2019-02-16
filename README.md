# EasyGrantsAdmin

## Motivation

In a large Oracle installation it is normal that database objecs including stored procedures exist in more than one schema.  Consequently schema A requires object privilege such as SELECT, INSERT, EXECUTE on objects in schema B. More common is the case where there are also schema C, D, E etc. Managing hundreds, thousands or even more inter-schemata object privieges can become a real headache.

Closely related to grant of object privileges is managing synonymns. Using synonym is usually a better practice than qualifying the object name with the owning schema name. If PUBLIC SYNONYMs are used, the management is pretty straight forward. But at sites where PRIVATE SYNONYMS are preferred for whatever reason, managing the synonyms is as painful as grants.

I have worked at many sites facing these challenges and have in fact rarely seen any elegant solution. 

At one site, they use one grant script for each objects, for example HR.DEPARTMENTS.GRANTS.sql. In there, developers put stuff like:

REM For project X, one developer put this line

`GRANT SELCT ON HR.departments TO schema_b;`

REM For project Y, the other developer put this:

GRANT SELECT,INSERT,UPDATE ON HR.departments TO schema_c;
GRANT SELECT ON HR.locations TO schema_c;

Of course, the script HR.DEPARTMENTS.GRANTS.sql is version controlled in a repository. For a project which need to granmt or revoke privilege on 20 objects, 20 scripts need to be updated/created. If the synonyms for HR.DEPARTMENTS are managed in a script HR.DEPARTMENS.SYNONYMS.sql, there are 20 more synonym scripts to deal with.

It should be noted some site has a policy to automatically revoke object privileges which are not listed explicitly in the grant scripts.


Yet at another site, the objects privileges and synonyms are managed in one single script per schema. For example there would be a HR.GRANTS_AND_SYNONYMS.SQL where you will find these lines:

GRANT SELCT ON HR.DEPARTMENS TO schema_b;
CREATE OR REPLACE PRIVATE SYNONYM schema´_b.departments FOR HR.deparments;
GRANT SELECT,INSERT,UPDATE ON HR.departments TO schema_c;
GRANT SELECT ON HR.locations TO schema_c;

This approach avoids the problem of having to update dozens of script per project, but it gets troublesome when the schema script contains thousands of lines. During deployment, all these lines need to be executed. Even if Oracle places a lock only for a veryhort time, in a busy database, running the script can take a while. Remember that the project that needs to be deployed needs only about 20 new grants. Running the grant statements for already existing object privileges is a waste of time. The other problem is that maintaining such a big script by hand is error-prone. Developer tend to edit only a few lines in the big script and actually run those lines separately, without testing the complete script. Another risk is that when multiple projects modify these schema scripts, the version which ultimately get installed may destroy the work from the other versions.

Both cumbersome approaches described so far strive to have a complete picture of grants and synonyms in the repository and an easy way to locate these scripts for auditing purpose. This per se is not a bad thing.

I personally am convinced that there is a better way to achieve that with a more elegant method. My definition of being elegant is:

*developers need to spend only minimum effort to manage grants and synonyms per project
*the management of grants and synonyms are easily trackable
*risk of revoking grants or dropping synonyms by mistake are at mininum level.

## Terminology
We use the term _schema_ to refer to database users which have tables, packages etc on which privieges are to be granted to other database users.
The term _user_ refers to database user void of these type of database objects. They could be purely connecting users, or roles.

The tool presented here only deals with grants on objects owned by the schemata. Grantees can be _users_ or _schemata_. The tool can also manage synonyms owned by the grantee _users_.

## Solution principles

The idea is to use a dedicated tool to manage the grants. Of course this tool has to be designed and implemented. We need a little data model and some PLSQL code. This GIT project is indeed the fruit of this designing and implementation process.

The central "repository" for grants and synonyms is the table object_grant_requests. To get the relevant object privileges, a developer would put for example these lines:

INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'DEPARTMENTS', 'SELECT', 'SCHEMA_B', 'G', 'my project need SELECT' );
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'EMPLOYESS', 'SELECT', 'SCHEMA_B', 'G', 'my project need SELECT' );
COMMIT;

The package which actually will perform the grant, PCK_GRANTS_ADMIN, is in a schema which does not have DBA privileges. But the package is defined with INVOKERS RIGHT. After checking the object_grant_requests table and the data dictionary, it will generate the appropiate GRANT sttaements. In practice, the deployer will need to logon e.g. as HR user and call:
  EXECUTE pck_grants_admin.p_process_request( i_schema=> USER )
  
Performing a revoke is done similary, to revoke SELECT on HR.locations from schema_c, the line would be:

INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'LOCATIONS', 'SELECT', 'SCHEMA_C', 'R', 'decommission old code' );

Suppose your project also requires grants on objects in the SALES schema, the deployer will need to log on as SALES and again run 
  EXECUTE pck_grants_admin.p_process_request( i_schema=> USER )

Creating (or dropping) synonyms are handled the same way as granting or revoking object privilege. To create a synonym in schema_b for HR.employees:
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'EMPLOYESS', 'SYNONYM', 'SCHEMA_B', 'G', 'Synonym is a good thing' );

Delevopers on a project will simply create one single script, e.g. MY_PROJECT-GRANTS_AND_SYNONYMS.sql 

As mentioned, it is sufficient for each project to use only one single script for grants and synonyms. Now you might notice that it would be difficult to audit who has requested the grants and revokes. Fear not! This information is in OBJECT_GRANT_REQUESTS table, and if want to have the information versioned controlled in one single file AUTOMATICALLY, run 

  SELECT pck_grants_admin.f_export_request_meta FROM DUAL;
  
The result will be a CLOB containing the MERGE statements into OBJEct_GRANTS_RQUESTS. Spool the CLOB and commit it to your repository - of course you should automate this in your deployment workflow. For example a robot can spool it directly to a path in your repository and commit it. Tracking of grants in repository done. Easy!

## Advanced Use Cases

## Installation 

Run the script install.sql as SYS or user with equivalent privileges. This script has 2 parts:
* Creates the schema GRANT_ADMIN, grants to it the required system privilege and SELECT on a few DBA views.
* Creates the data model and stored procedures in GRANT_ADMIN

To de-install, run de_install.sql. Privileges and synonyms which have been granted/created are left untouched.

## Copyright and Disclaimer

This software can be used, modified as desired. Use at your own risk. Against fees, I would be happy to provide consultancy for installation, customization.

