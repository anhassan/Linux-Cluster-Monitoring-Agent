#!/bin/bash

#assigning CLI arguments to variables

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

#getting hardware information of the host


hostname=$(hostname -f)
memory_free=$(vmstat --unit M | awk 'NR==3{print $4}')
cpu_idle=$(vmstat --unit M | tail -n1 | awk '{print $(NF-2)}')
cpu_kernel=$(vmstat --unit M | awk 'NR==3{print $(NF-3)}')
disk_io=$(vmstat -d | tail -n1 | awk '{print $NF}')
disk_available=$(df -BM | grep -E "\/{1}$" | awk '{print $4}' | sed 's/M//')
timestamp=$(vmstat -t | awk 'NR==3{print $(NF-1), $NF}')

#installing psql CLI client

sudo yum install -y postgresql

#finding the id corresponding to the hostname

id_statement=$(echo "SELECT id FROM host_info WHERE hostname='$hostname';")
host_id=$(sudo PGPASSWORD=$psql_password psql -h $psql_host -p $psql_port -U $psql_user -d $db_name -w -t -c "$id_statement")


#creating an insert statement

insert_statement=$(echo "INSERT INTO host_usage ( host_id,memory_free,cpu_idle,cpu_kernel,disk_io,disk_available,timestamp ) VALUES ($host_id,$memory_free,$cpu_idle,$cpu_kernel,$disk_io,$disk_available,'$timestamp');") 


#inserting the data into the table using psql CLI client
sudo PGPASSWORD=$psql_password psql -h $psql_host -p $psql_port -U $psql_user -d $db_name -w -c "$insert_statement"

