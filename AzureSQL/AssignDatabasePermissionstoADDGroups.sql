-- Azure SQL query to grant database permissions to ADD (or AD) groups.

-- un on MasterDB
CREATE USER [ACL_GrantLogin_vFrohnSQL] FROM EXTERNAL PROVIDER

-- Run on DB
CREATE USER [ACL_DBOwner_MyDatabase01] FROM EXTERNAL PROVIDER
EXEC sp_addrolemember 'db_owner', 'ACL_DBOwner_MyDatabase01' 

CREATE USER [ACL_DBWriter_MyDatabase01] FROM EXTERNAL PROVIDER
EXEC sp_addrolemember 'db_datawriter', 'ACL_DBWriter_MyDatabase01' 

CREATE USER [ACL_DBReader_MyDatabase01] FROM EXTERNAL PROVIDER
EXEC sp_addrolemember 'db_datareader', 'ACL_DBReader_MyDatabase01' 


-- Check permissions worked
SELECT * FROM SYS.DATABASE_PRINCIPALS
