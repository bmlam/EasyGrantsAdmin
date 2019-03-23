# EasyGrantsAdmin

## Motivation

In a large Oracle installation it is normal that database objecs including stored 
procedures exist in more than one schema.  Consequently schema A requires object 
privilege such as SELECT, INSERT, EXECUTE on objects in schema B. There may be even more schemata: C, D, E etc. 
Managing hundreds, thousands or even more inter-schemata object privieges can become a real headache.

Closely related to granting/revoking of object privileges is managing synonymns. Using synonym 
is usually a better practice than qualifying the object name with the owning schema
name. If PUBLIC SYNONYMs are used, the management is pretty straight forward. But 
at sites where PRIVATE SYNONYMS are preferred for whatever reason, managing the 
synonyms is as painful as grants, from a developers point of view.

Lets be straight: dealing with grants and syonyms are no intellectual changes at all and therefore the task should not cost an undue amount of effort.

I have worked at many sites facing these challenges and have in fact not seen any solution which makes the task painless for deveolpers.

At one site, they use one grant script for each objects, for example 
HR.DEPARTMENTS.GRANTS.sql. In there, developers put stuff like:

```
REM By Jack for project X: we need to query the table  
GRANT SELCT ON HR.departments TO schema_b;

REM By Emily for project Y2: schema_c needs to change data, schema_d needs to query
GRANT SELECT,INSERT,UPDATE ON HR.departments TO schema_c;
GRANT SELECT ON HR.departments TO schema_d;
```

Similar stuff will probably be found in scripts such as

* HR.EMPLOYEES.GRANTS.sql
* HR.LOCATIONS.GRANTS.sql
* SALES.ORDER_ENTRIES.GRANTS.sql 
* SALES.PRODUCTS.GRANTS.sql

and so on and so forth

Of course, all these grant scripts are version controlled in a repository. For a project which needs to 
grant or revoke privilege on 20 objects, 20 scripts need to be updated/created. If the synonyms for 
HR.DEPARTMENTS are managed in a script HR.DEPARTMENS.SYNONYMS.sql, there are 20 more synonym scripts to deal with.

It should be noted some site has a policy to automatically revoke object privileges 
which are not listed explicitly in the grant scripts.


Yet at another site, the objects privileges and synonyms are managed in one single 
script per schema. For example there would be a HR.GRANTS_AND_SYNONYMS.SQL where 
you will find these lines:

```
REM By Jack for project X: we need to query the tables  
GRANT SELCT ON HR.departments TO schema_b;
GRANT SELCT ON HR.emloyees TO schema_b;

REM By Emily for project Y2: schema_c needs to change data, schema_d needs to query

GRANT SELECT,INSERT,UPDATE ON HR.departments TO schema_c;
GRANT SELECT,INSERT,UPDATE ON HR.employees TO schema_c;

GRANT SELECT ON HR.departments TO schema_d;
GRANT SELECT ON HR.employees TO schema_d;
```

This approach avoids the problem of having to update dozens of script per project, but it 
gets troublesome when the schema script contains thousands of lines. During deployment, 
all these lines need to be executed.  Even if Oracle places a lock only for a veryhort 
time, in a busy database, running the script can take a while. Remember that the project 
that needs to be deployed needs only about 20 new grants. Running the grant statements 
for already existing object privileges is a waste of time. The other problem is that 
maintaining such a big script by hand is error-prone. Developer tend to edit only a few 
lines in the big script and actually run those lines separately, without testing the 
complete script.  Another risk is that when multiple projects modify these schema scripts, 
the version which ultimately get installed may destroy the work from the other versions.

Both cumbersome approaches described so far strive to have a complete picture of grants 
and synonyms in the repository and an easy way to locate these scripts for auditing 
purpose. This per se is not a bad thing.

I personally have always thought there must be a better way to implement the good intentions with a more elegant 
method. My definition of being elegant is:

*developers need to spend only minimum effort on managing grants and synonyms per project
*the management of grants and synonyms are easily trackable
*risk of revoking grants or dropping synonyms by mistake are at mininum level.

## Terminology
I will use the term _schema_ to refer to database users which have tables, packages etc on 
which privieges are to be granted to other database users.  The term _user_ refers to 
database user void of these type of database objects. They could be purely connecting 
users, or roles.

The tool presented here only deals with grants on objects owned by the schemata. 
Grantees can be _users_ or _schemata_. The tool can also manage synonyms owned by the 
grantee _users_.

## Solution principles

The idea is to use a dedicated tool to manage the grants. Of course this tool has to be 
designed and implemented. We need a little data model and some PLSQL code. This GIT 
project is indeed the fruit of this designing and implementation process.

The central "repository" for grants and synonyms is the table object_grant_requests. 
To get the relevant object privileges, a developer would put for example these lines:
```
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'DEPARTMENTS', 'SELECT', 'SCHEMA_B', 'G', 'my project need SELECT' );
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'EMPLOYESS', 'SELECT', 'SCHEMA_B', 'G', 'my project need SELECT' );
COMMIT;
```

The package which actually will perform the grant, PCK_GRANTS_ADMIN, is in a schema 
which does _not_ require DBA privileges. But the package is defined with INVOKERS RIGHT. 
After checking the object_grant_requests table and the data dictionary, it will 
generate the appropiate GRANT sttaements. In practice, the deployer will need to 
logon e.g. as HR user and call:
  `EXECUTE pck_grants_admin.p_process_request( i_schema=> USER )`
  
Performing a revoke is done similary, to revoke SELECT on HR.locations from schema_c, 
the line would be:
```
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'LOCATIONS', 'SELECT', 'SCHEMA_C', 'R', 'decommission old code' );
```

Suppose your project also requires grants on objects in the SALES schema, the deployer 
will need to log on as SALES and again run 
```
  EXECUTE pck_grants_admin.p_process_request( i_schema=> USER )
```

Creating (or dropping) synonyms are handled the same way as granting or revoking 
object privilege. To create a synonym in schema_b for HR.employees:

```
INSERT INTO GRANT_ADMIN.object_grant_requests VALUES ( 'HR', 'EMPLOYESS', 'SYNONYM', 'SCHEMA_B', 'G', 'Synonym is a good thing' );
```

Delevopers on a project will simply create one single script, e.g. MY_PROJECT-GRANTS_AND_SYNONYMS.sql 

As mentioned, it is sufficient for each project to use only one single script for 
grants and synonyms. Now you might ask if each projects has itw own script for grant and
synonyms, how would it be possible to track them at a central place? Simple. The package provides a function to export the data in OBJECT_GRANT_REQUESTS into a script in the form of a CLOB. The site just has to include in the deployment workflow a step to extract the script with the following query

```
  SELECT pck_grants_admin.f_export_request_meta FROM DUAL;
```

Once the script is spooled to a file, which can be checked into the source code repository.
Since the grant and revoke requests of all projects end up in the OBJECT_GRANT_REQUEST table 
and the exported script reflects all rows in the table, it can be used to repopulate the very table, should such a need arise.

Of course you the script export and check-in step should be automated and included in the 
deployment workflow. For example a robot can spool it 

directly to a path in your repository and commit it. 
To sum up, each projects just requires one script for grants and synonyms, the automated workflow keeps the central
script, which incorporate the grants and revokes for all projects, up-to-date.

File demo_workflow.md shows how this is done in practice (without the automated export step).

## Advanced Use Cases
The tool also allows the use of regular expression to specifies the grantees, for example it is possible to use **HR|SALES** to specifiy 
* HR 
* SALES 

as grantees within the same row of OBJECT_GRANT_REQUEST. 

By the same token, **USER0[1-3]** specifies in one row that 
* USER01 
* USER02 
* USER03 

are the grantees.

## Installation 
We assume you want to install the required objects in a schema named GRANT_ADMIN. If you choose to use another schema, you just need to edit the installation scripts accordingly. 

There is one view that should be created and owned by SYS user - ALL_GRANTEES. But if you cannot get your DBA to do it, you can create a view or table with the same name in the GRANT_ADMIN schema. The object just needs to include all user or role names which will ever receive privileges managed by EasyGrantAdmin.

* Run the script core_setup-step1-by-dba.sql as SYS or any user with equivalent privileges. 
* Run the script core_setup-step2-by-grant_admin.sql as GRANT_ADMIN

## Optionally, create the database objects for demo or test of EasyGrantAdmin
start the script demo_setup-by-dba.sql as SYS or an user with equivalent privileges. 

To de-install, run de-install.sql. Privileges and synonyms which have been granted/created 
are left untouched.

## Copyright and Disclaimer

This software can be used, modified as desired. Use it at your own risk!. Against fees, I would be happy to provide consultancy for installation, customization.

The scripts have been tested in an Oracle Developer Day virtual machine. Some of the scripts may contain username and password for my convenience during testing. You will NOT copy this for a real environment!

