-- Triggering an error causes sqlcmd to exit with an exit status > 0
if exists (select * from sys.databases where state_desc != 'ONLINE') raiserror('Not all databases are ready!', 20, -1);