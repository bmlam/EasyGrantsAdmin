## Purpose
We want to demonstrate the superior run time of EasyGrantAdmin over the traditional method of simple re-execute accumulated GRANT statements.

## Preparation
We will created thousends of test objects on which we will grant privilege to several users.

Run prepare.sql as a DBA user to create a few thousend test objects 

One of the SQL statement produces the traditional grant statement which nneds to be spooled into a SQL script. I then edited it to make it a PLSQL block to get only one feedback messages . This prevents the SQLPLUS screen from being garbled with one message per DDL.

## Run the tests

Best practice for comparing runtime of two different methods mandates that both methods are started simultanously. Unfortunately we can not do that in this case since the DDL executed by both would interfere with each other.

Open one single SQLPLUS session.

```
start test_drive.sql
```

After this, the "desired" privileges have been granted. Now when we run the traditional and EasyGrantAdmin method again. the latter will complete in much shorter time because it does an intelligent scan of the data dictionar and see that there is really no GRANT statements need to be performed, whereas in the traditional method Oracle is forced to process the huge number DDL statements again.
