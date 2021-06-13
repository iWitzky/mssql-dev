sqlcmd=( /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U 'sa' -P "${SA_PASSWORD}" )
initdbtmp_dir=/initdb_tmp

function wait_mssql_port () {
    echo "Waiting for mssql startup"
      while ! echo 2> /dev/null  > /dev/tcp/127.0.0.1/1433 ; do
        waitAndSleep "for open database port" 5
      done
      echo "Database ready!"
}

function wait_dbs_online () {
    echo "Wait ... for Databases come online"
    # using sql file because bash tries to interpret "if e" from "if exists"-sql-statement
    # when using a variable with sql statement
    while ! $("${sqlcmd[@]}" -i /mssql-container/checkDBstate.sql); do
        waitAndSleep "for database maintenance to be completed" 5
    done
    echo "Databases ready!"
}

function kill_pid_and_wait_vanish () {
    
    MSSQL_RUN_PID=$1

    # stop sql server process when pid exists
    if [ ! $(kill -0 "$MSSQL_RUN_PID") ]; then
        
        kill "$MSSQL_RUN_PID"

        waitAndSleep "for database shutdown to be completed" 0
        wait $MSSQL_RUN_PID

    fi
}

function restoreDB() {
    db=$(basename $1 .bak)
    
    data_dir=/var/opt/mssql/data
    sql_query="IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '${db}')
               BEGIN
                    RESTORE DATABASE [${db}]
                    FROM DISK ='$1'
                    WITH MOVE '${db}' TO '${data_dir}/${db}.mdf',
                    MOVE '${db}_Log' TO '${data_dir}/${db}log.ldf';
               END"
    
    echo "Init database restore - [${db}]"
    "${sqlcmd[@]}" -Q "$sql_query"
}

function restoreDB7z() {
    dbfilename=$(basename $1 .7z)
    7z e $1 -o$initdbtmp_dir
    restoreDB "$initdbtmp_dir/$dbfilename"
}

function restoreDBgz() {
    dbfilename=$(basename $1 .gz)
    zcat $1 > "$initdbtmp_dir/$dbfilename"
    restoreDB "$initdbtmp_dir/$dbfilename"
}

function provision_files () {
    echo "Provisioning files:"
    cd $1
    for f in $1/*; do
        case "$f" in
            *.bak)    echo " - $f"; restoreDB "$f";;
            *.bak.7z) echo " - $f"; restoreDB7z "$f";;
            *.bak.gz) echo " - $f"; restoreDBgz "$f";;
            *.sh)     echo " - $f"; . "$f" ;;
            *.sql)    echo " - $f"; "${sqlcmd[@]}" -i "$f";;
            *.sql.gz) echo " - $f"; gunzip -c "$f" | "${sqlcmd[@]}";;
        esac
    done
    cd - > /dev/null
}

function waitAndSleep() {
    echo "Wait ... $1"
    sleep 5
}
