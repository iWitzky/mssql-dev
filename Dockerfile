FROM mcr.microsoft.com/mssql/server:2017-CU24-ubuntu-16.04

# set product id to MS SQL Server Developer edition
ENV MSSQL_PID=Developer

# set this to 'Y' only when you accept the End-User Licensing Agreement
#   mentioned on https://hub.docker.com/_/microsoft-mssql-server
#   2021/13/06 -> https://go.microsoft.com/fwlink/?linkid=857698
ENV ACCEPT_EULA=N

# set default password
ENV SA_PASSWORD=myStrong(!)Password#1234

# add 7zip
RUN apt-get update \
    && apt-get install -y \
        p7zip-full \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# add provisioning scripts
COPY entrypoint.sh /mssql-container/
COPY functions.sh /mssql-container/
COPY checkDBstate.sql /mssql-container/

# set bind directory
VOLUME /initdb.d

ENTRYPOINT ["/mssql-container/entrypoint.sh"]
EXPOSE 1433
CMD ["/opt/mssql/bin/sqlservr"]
