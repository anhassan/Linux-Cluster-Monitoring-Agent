#!/bin/bash

#su centos

#start the docker daemon if not started

systemctl status docker || systemctl start docker

#checker whether the command line arguments are less than three or not

if [ $# -lt 1 ] || [ $# -gt 2 ]
then
echo "Wrong the number of arguments given ,use ./psql_docker.sh start | stop [password] format"
exit 0
fi


#getting the command line arguments

pos1=$1
pos2=$2

#setting an environment variable for password of psql instance

export PGPASSWORD

#checking whether a custom password choice is provided by the user or not

if [[ $pos2 == "" ]]
then

#putting in default password as user didnot give any preference

PGPASSWORD='password'
else

#setting in the custom password provided by the user

echo "password set = "$pos2
PGPASSWORD=$pos2

fi

#checking the first command line argument(start | stop) and then progressing accordingly

if [ $pos1 = 'start' ]
then

#checking whether this container is already up and running or not

if [ $(sudo docker ps | grep -cE "jrvs-psql") -eq 1 ]
then
echo "container already running......"
exit 0
fi


#checking whether the p-sql image is available or not

if [ $(sudo docker image ls | grep -cE "postgres") -eq 0 ]
then

#pulling postgres image from dockerhub

sudo docker pull postgres
echo "Image Pulled....."
fi

#checking whether a volume has been created or not

if [ $(sudo docker volume ls | grep -cE "pgdata") -eq 0 ]
then

#volume doesnot exist and therefore must be created

sudo docker volume create pgdata
fi

#checking whether a container is present or not

#checking all the stopped containers

if [ $(sudo docker ps -f "status=exited" | grep -cE "jrvs-psql") -eq 0 ]
then

#creating a container as it is not present

sudo docker run --name jrvs-psql -e POSTGRES_PASSWORD=$PGPASSWORD -d -v pgdata:/var/lib/postgresql/data -p 5432:5432 postgres
echo "New container created"
exit 0
else

#starting the stopped container

sudo docker container start jrvs-psql
echo "Stopped container started"
exit 0
fi


elif [ $pos1 = 'stop' ]
then

#checking the number of arguments

if [ $# -gt 1 ]
then
echo "Wrong the number of arguments given ,use ./psql_docker.sh start | stop [password] format"
exit 0
fi

#stopping the container if it is running

if [ $(sudo docker ps | grep -cE "jrvs-psql") -eq 1 ]
then

#stopping a running container

sudo docker container stop jrvs-psql
echo "Container stopped"
exit 0


#checking that whether the container exists or not


elif [ $(sudo docker ps -f "status=exited" | grep -cE "jrvs-psql") -eq 0 ]
then
echo "container doesnot exist......."
exit 0

#checking whether the container is already stopped or not

elif [ $(sudo docker ps -f "status=exited" | grep -cE "jrvs-psql") -eq 1 ]
then
echo "container already stopped......." 
exit 0

fi

else

#wrong input format provided

echo "wrong input format provided, use ./psql_docker.sh start | stop [password] format"
exit 0 
fi
