@echo off

REM - disconnect both server and database docker containers
REM - and remove network to reset
docker network disconnect ewb-rainwater-network ewb-rainwater-server
docker network disconnect ewb-rainwater-network ewb-rainwater-database
docker network rm ewb-rainwater-network

REM - Create new server and database containers
cd database
call docker_commands_database.bat
cd ..\server
call docker_commands_server.bat
cd ..

REM - Create Docker network and add both server and database containers
docker network create ewb-rainwater-network
docker network connect ewb-rainwater-network ewb-rainwater-server
docker network connect ewb-rainwater-network ewb-rainwater-database

REM - Start database container (Do first, since server tries to connect to database)
docker start ewb-rainwater-database

REM - Check the status of the MySQL server, can only connect once the status is "healthy"
REM - Only move on once the server is fully ready to be connected to
REM - Second line is assigning the value of the inspect function to the variable status
echo Waiting for MySQL...
:loop_start
for /f %%i in ('docker inspect --format "{{.State.Health.Status}}" ewb-rainwater-database') do SET state=%%i
IF "%state%"=="healthy" (goto :loop_break)
goto :loop_start
:loop_break

REM - Login in MySQL Client and change authentication settings
REM - Using -i, not -it because of a strange 'winpty' error
REM - Change auth settings because of dispartity between server and client versions
docker exec -i ewb-rainwater-database mysql -uroot -pewb2020 < mysql_auth_changes.sql

REM - Start server container
docker start ewb-rainwater-server
