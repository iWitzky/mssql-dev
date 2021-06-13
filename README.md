mssql-dev - Docker project for MS SQL Server Container with batteries for lazy developers
=====

* Enhanced _entrypoint.sh_ for individual file provisioning without image rebuild.
* The _Dockerfile_ is based on the official "Microsoft SQL Server on Linux" image:
  https://hub.docker.com/_/microsoft-mssql-server
* Using the _mcr.microsoft.com/mssql/server:2017-CU24-ubuntu-16.04_ image.

Provisioning of the SQL server:
-----

Mount your files to the container directory _/initdb.d_ to initialize the sql server with your data.  
The directory /initdb.d can be included as a whole or each provisioning file individually.  

Supported file formats:  
1. MS SQL Server Database Backup _(.bak)_  
   _Note:_
      * _The name of the database to restore is determined from the file name of the mounted backup without the file extension .bak!_  
      * _Restoring a database with a changed database name is not supported!_
      * _Existing databases will not be restored!_
      * _Keep track of naming conventions for MS SQL Server databases!_
2. MS SQL Server Database Backup as a single file in a 7zip archive _(.bak.7z)_  
   _Note:_
      * _Only one database backup may be packed in a 7zip archive!_  
      * _The 7zip archive must be named like the file of the database backup with the extension .7z_  
      * _The file of the database backup must be located directly in the 7zip archive without subdirectories!_  
      * _The instructions for point 1 still apply!_
3. MS SQL Server Database Backup as gzip archive _(.bak.gz)_  
4. SQL files _(.sql)_
5. SQL files as gzip archive _(.sql.gz)_
6. shell script _(.sh)_


docker-compose.yml - example - individual file mount:
-----
```yaml
services: 
  mssql:
    image: mssql-dev:2017-CU24-ubuntu-16.04
    volumes:
      - ./DevDatabase_1.1.bak.gz:/initdb.d/DevDatabase.bak.gz
      - ./cleanup.sql:/initdb.d/zz_cleanup.sql
```  
**In this example, the backup is restored as _DevDatabase_.**
**The name of the database is determined from the filename of the mounted backup without the file extension _.bak_!**
**The SQL script should be processed at the end of the provisioning, so the filename is preceded by _z\__.**


docker-compose.yml - example - directory mount:
-----
```yaml
services: 
  mssql:
    image: mssql-dev:2017-CU24-ubuntu-16.04
    volumes:
      - ./:/initdb.d/
```  
**This example would try to restore a backup _DevDatabase\_1.1.bak.gz_ as database _DevDatabase\_1.1_**


The processing order of the files in the _/initdb.d_ directory corresponds to the default sorting of the _ls_ command.
Example:
1. 01_createDB.sql
2. devDB.bak
3. my_script.sh
4. zz_cleanup.sql

docker commands:
-----
* Build  
    `docker build -t mssql-dev:2017-CU24-ubuntu-16.04 .`
* Start  
    `docker run -d --name mssql-dev -v $(pwd)/DevDatabase_1.1.bak.gz:/initdb.d/DevDatabase.bak.gz -p 1433:1433 mssql-dev:2017-CU24-ubuntu-16.04`
* SQLcmd:  
    `docker exec -it mssql-dev /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P '<your_password>'`

docker-compose commands:
-----

* Build  
    `docker-compose build mssql-dev`

* Start  
    `docker-compose up -d mssql-dev`

* SQLcmd:  
    `docker-compose exec -it mssql-dev /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P '<your_password>'`
