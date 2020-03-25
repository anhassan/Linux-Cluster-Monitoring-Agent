# Linux Cluster Monitoring Agent
## Introduction
Linux Cluster Monitoring Agent is a cluster management solution to record hardware specifications and periodically monitor resource usages of individual nodes in a cluster of servers. The data acquired is persisted in a Docker instantiated RDBMS PostgreSQL database which is hosted on a randomly selected server from the entire cluster. The bash agent present on every node is triggered periodically to gather and register real time data in the database instance using crontab jobs. The custom minimum viable product (MVP) also provides meaningful insights by addressing essential business queries to not only manage the cluster efficiently but also plan for future resources.

## Architecture and Design
![](https://github.com/anhassan/Linux-Cluster-Monitoring-Agent/blob/master/linux_sql/assets/Linux_agent_architecture.png)

In line with the above displayed architectural blueprint, the main design consists of two types of nodes: data persistence node and data provision nodes. The data persistence node contains the PostgreSQL(*psql*) instance along with the bash agent while the data provision nodes only contains the bash agents. In a cluster of N nodes there is only one data persistence node and N-1 data provision nodes. Bash agents from all the nodes periodically gather and deposit the updated diagnostics to the *psql* instance which persists the data for further analysis.
### Bash Agent
The bash agent consists of two scripts: `host_info.sh` & `host_usage.sh` to find out hardware specifications and updated tally of consumed resources of each node.

`host_info.sh`: Responsible for recording and pushing hardware specification data to the PostgreSQL instance. Due to the invariant nature of the hardware specifications this script is executed only one at each node.

`host_usage.sh` : Responsible for recording and pushing refreshed resource usage data to the PostgreSQL using automated *crontab* job. In order to collect updated data this script gets executed periodically depending upon the desired update interval specified in the *crontab* job.

### PostgreSQL Instance Creation

`psql_docker.sh`: Responsible for setting up a PostgreSQL instance with *Docker*. Creates a docker container mounted with a volume for data persistence and a user defined password. After creating, the script also provides provision to stop a running container and boot a stopped container using respective command line arguments.

### Database Creation and Table Initialization

`ddl.sql` : Sets up a host_agent database which is responsible for hosting two tables : `host_info` & `host_usage`. The former table being fed by `host_info.sh` contains hardware specification entries of all the nodes in the clusters with id of each cluster being the *primary key*. The host_usage table on the other hand contains historical data of all the updates of the resource usage information and is populated by `host_usage.sh`. The two tables are linked through id of the nodes such that the `host_info` attribute in `host_usage` table acts as a *foreign key* referencing to the id attribute (primary key) of the `host_info table`.

### Business Solutions

`queries.sql` : Responsible for grouping hosts by CPU number and sorting them by their memory sizes in decreasing order and evaluating average used memory in percentage over 5 mins interval for each host by using *windowing*.
### Database Tables

The `host_agent` database contains two tables: `host_info` & `host_usage`. Both the tables have completely different attributes as the later holds information related to the use of resources while the former contains time invariant hardware specifications.

Categorically the attributes of the `host_info` table are mentioned below. A key point to remember is that the number of entries in the `host_info` table are N(number of the nodes in the cluster) as the hardware specifications are constant therefore each node has one corresponding entry with id being the *primary key*.


 * `id` : *Unique identifier of each node & also the primary key*
* `hostname` :   *Fully qualified host name of the node/machine*
* `cpu_number` : *Number of CPU cores of a particular node*   
* `cpu_architecture` :*CPU's architecture/features*
* `cpu_model` : *CPU's manufacturer and model specifications*
* `cpu_mhz` :  *Speed of CPU*
* `L2-cache` : *Memory size of L2-cache in KB*
* `total_mem` : *Total memory of the node in KB*
* `timestamp` : *Time at which the data was recorded in UTC format*

Following is the listing of all the attributes of `host_usage` table. Unlike `host_info`, each node in this table has multiple entries as resources used changes with time. A key point to remember here is that the `host_id` field in this table references to the field of id in the `host_info` and is therefore a *foreign key* in this table.

* `host_id` : *Unique identifier of a node/server & foreign key to* `host_info` *table*
* `memory_free` : *Idle memory present in the node*
 * `cpu_idle` :  *Percentage of time spent by CPU running the kernel*
* `cpu_kernel` : *Percentage of total CPU time spent idle*
* `disk_io` : *Number of disk input/output operations*
* `disk_available` : *Available disk space in MB*
* `timestamp` : *Time at which the data was recorded in UTC format*

## Usage

### 1.Instantiating PostgreSQL

A PostgreSQL instance must be created using Docker and a container has to be provisioned with a dedicated volume to persist the data by executing the `psql_docker.sh`
```bash
   # Create a docker container hosting PostgreSQL server
  ./linux_sql/scripts/psql_docker.sh start custom db_password
```

### 2.Creating database and Initializing Tables

Create `host_agent` database and initialize `host_info` and `host_usage` to store node hardware specifications and resource usage data by executing the following command
```bash
# Create database along with tables
  psql -h localhost -U postgres -W -f ./linux_sql/sql/ddl.sql
```

### 3.Recording Hardware Specifications of Individual Nodes

Execute the `host_info.sh` script only once to push the invariant hardware specifications to `host_info` table in the `host_agent database`.
```bash
# Push hardware specification data of each node to the database
./linux_sql/scripts/host_info.sh psql_host psql_port db_name psql_user psql_password

# Example
./linux_sql/scripts/host_info.sh "localhost" 5432 "host_agent" "postgres" "mypassword"
```


### 4.Collecting Resource Usage Information Across Nodes

Execute the `host_usage.sh` to get current status about resource usage across nodes. This script would be automatically executed using the *crontab* job (setup explained below) to populate the data in host_usage table in order to monitor, analyze and plan for the resource in an optimized way.
```bash
# Push resource usage data across nodes to the database
./linux_sql/scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password

# Example
./linux_sql/scripts/host_usage.sh "localhost" 5432 "host_agent" "postgres" "mypassword"
```

### 5. Crontab Setup

The *crontab* is a command or list of commands that we want to run on a regular schedule. As we want regular updates regarding the resource utilization along all the nodes in our cluster therefore, we must set up a *crontab* job that executes host_usage.sh script periodically after a desired time interval. In my case (default) the time interval for scheduling is set to one minute by using `* * * * *` where the distribution of `* `is as follows `<minute,hour,day(month),month,day(week)>` . For example, setting the first field to 5 would set the scheduling time for *crontab* job to be 5 `(*/5****)`.
```bash
# Edit crontab jobs by executing the following command on shell
crontab -e

# Set the crontab job schedule to every single minutes and dump the ouput to a log file
* * * * * bash ./linux_sql/host_agent/scripts/host_usage.sh sh psql_host psql_port db_name psql_user psql_password  > /tmp/host_usage.log

# List crontab jobs to validate your entry
crontab -l

# View the log file to validate the automation through crontab
cat /tmp/host_usage.log
```
## Improvements

**Replication:** One of the few problems with the solution proposed is that the data persistence node is a single point of failure. In cases, when this node gets down or compromised there is no backup of the data it contains. A plausible solution to this problem would be to have a backup PostgreSQL instance in any one of the remaining nodes as well. This however must remain in sync with the primary database and should only be used in persistent absence of the primary data persistence node.

**Hardware Update Incorporation:** For now, the above solution assumes that the hardware specifications of all the nodes are time invariant. However, this might not be the case as hardware up-gradation of the nodes might be done in order to improve their performance. In order to incorporate this, the previous hardware specifications should be replaced with the new ones. A script can be designed to monitor changes in the hardware and automated by adding it as a *crontab* job.

**Optimizing Queries for Data Analysis:** The table schemas can be normalized in order to make the CRUD more efficient. In addition, both primary and clustered indexing can be done to make queries highly optimized with respect to time.

**Notifications:** Generate notifications in the case when there is no update received from a node for a long amount of time. If this is the case, then it is highly probable that this node has expired therefore this event should be notified. In addition, the usage profile of each node should be available temporally so that if one node is using more resources for short bursts and any other node is under utilizing resources in that burst then resources could be interchanged among nodes for optimal utilization of resources among the cluster.

**Database Optimization:** A large database is not feasible both in terms of space utilization and time complexity. In order to reduce the size of the database, a script should be written to remove duplicate entries. In addition, this script should make the *crontab* job scheduled time for nodes dynamic. For instance, if there is no change in the usage pattern of a particular node then its scheduled job repetition time should be reduced so that it does not populate the database for no good.
