/* creating a database if doesnot exists */

 SELECT 'CREATE DATABASE host_agent' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_database WHERE datname='host_agent');

/* switch to the database */

\connect host_agent

/* making table to store host information */

CREATE TABLE IF NOT EXISTS host_info(

id SERIAL PRIMARY KEY,
hostname TEXT NOT NULL,
cpu_number NUMERIC NOT NULL,
cpu_architecture TEXT NOT NULL,
cpu_model TEXT NOT NULL,
cpu_mhz NUMERIC NOT NULL,
L2_cache NUMERIC NOT NULL,
total_mem NUMERIC NOT NULL,
timestamp TIMESTAMP NOT NULL

);

/* making table to store usage information */

CREATE TABLE IF NOT EXISTS host_usage(

host_id INTEGER REFERENCES host_info(id),
memory_free NUMERIC NOT NULL,
cpu_idle NUMERIC NOT NULL,
cpu_kernel NUMERIC NOT NULL,
disk_io NUMERIC NOT NULL,
disk_available NUMERIC NOT NULL,
timestamp TIMESTAMP NOT NULL


);
