/* Business Solutions Using SQL */

/* Query 1 */


select t1.cpu_number as cpu_number, t2.host_id as host_id, t1.total_mem from host_info as t1 inner join host_usage as t2
on t1.id = t2.host_id order by cpu_number, total_mem desc;



/* Query 2 */

select b.hi as host_id, b.hn as host_name,b.ft as timestamp ,avg(b.pm) as avg_used_mem_percentage from (
select a.hi as hi , a.hn as hn ,a.pm as pm, first_value(a.ts) over (partition by a.bins) as ft, a.bins as bins
from (select t1.host_id as hi, t2.hostname as hn ,100*((t2.total_mem - t1.memory_free)/(t2.total_mem)) as pm ,
t1.timestamp as ts , t1.buckets as bins from (select st.host_id as host_id , st.memory_free as memory_free, st.timestamp as timestamp, (((st.rk-1)/5)+1) as buckets 
from (select host_id , memory_free, timestamp, rank() over (order by timestamp) as rk from host_usage) as st) as t1 
inner join host_info as t2 on t1.host_id = t2.id) as a) as b group by b.ft,b.hi,b.hn order by b.ft;

