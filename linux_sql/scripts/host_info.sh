#!/bin/bash

#assigning CLI arguments to variables

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

#getting hardware information of the host

id=1
hostname=$(hostname -f)
cpu_number=$(lscpu | grep -E "^CPU\(s\):" | awk '{print $2}')
cpu_architecture=$(lscpu | grep "Architecture" | awk '{print $2}')
cpu_model=$(lscpu | grep "Model:" | awk '{print $2}')
cpu_mhz=$(lscpu | grep "CPU MHz:" | awk '{print $3}')
l2_cache=$(lscpu | grep "L2 cache:" | awk '{print $3}' | sed 's/K//')
total_mem=$(cat /proc/meminfo | grep "MemAvailable:" | awk '{print $2}')
timestamp=$(vmstat -t | awk 'NR==3{print $(NF-1), $NF}')

#installing psql CLI client

sudo yum install -y postgresql


#creating an insert statement

#insert_statement='insert into' $db_name

insert_statement=$(echo "INSERT INTO host_info ( id,hostname,cpu_number,cpu_architecture,cpu_model,cpu_mhz,L2_cache,total_mem,timestamp ) VALUES ($id,'$hostname',$cpu_number,'$cpu_architecture',$cpu_model,$cpu_mhz,$l2_cache,$total_mem,'$timestamp');") 


#inserting the data into the table using psql CLI client

sudo PGPASSWORD=$psql_password psql -h $psql_host -p $psql_port -U $psql_user -d $db_name -w -c "$insert_statement"


