#!/usr/bin/env bash

# configure exit on bash syntax errors
set -e

if [ "$1" = '/opt/mssql/bin/sqlservr' ]; then

    sqlcmd_exe=/opt/mssql-tools/bin/sqlcmd
    mssqlconf_exe=/opt/mssql/bin/mssql-conf
    initdb_dir=/initdb.d
    
    if [ -x ${sqlcmd_exe} ] && [ -x ${mssqlconf_exe} ] && [ -d ${initdb_dir} ] && [ $(ls -1 ${initdb_dir} | wc -l) -gt 0 ]; then

      # sqlcmd, mssql-config, initdb-dir and at least one init file available -> provisioning mssql server
      
      # load functions and variables
      . /mssql-container/functions.sh
      # create directory for temporary files
      mkdir -p $initdbtmp_dir

      echo
      echo 'MS SQL Server start provisioning.'
      echo

      # set listening interface to localhost
      # -> nobody outside the container should talk to server during provisioning
      /opt/mssql/bin/mssql-conf set network.ipaddress 127.0.0.1

      # start mssql server
      /opt/mssql/bin/sqlservr &
      MSSQL_RUN_PID=$!
      echo "Started MS SQL Server with PID $MSSQL_RUN_PID"
      
      # waiting for mssql server port opens
      wait_mssql_port

      # provision the init files from initdb-dir
      provision_files $initdb_dir

      # Don't kill the server when databases are in another than ONLINE state
      wait_dbs_online

      # provisioning finished -> kill server for regular startup
      kill_pid_and_wait_vanish $MSSQL_RUN_PID

      # set listening interface back to default 0.0.0.0
      /opt/mssql/bin/mssql-conf unset network.ipaddress

      # cleanup
      rm -rf $initdbtmp_dir

      echo
      echo 'MS SQL Server provisioning complete.'
      echo
    fi

fi

# start command
exec "$@"
