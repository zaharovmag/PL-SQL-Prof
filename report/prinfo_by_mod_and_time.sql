set linesize 600
select sum(stop_exec_in_ms - START_EXEC_IN_MS)/100 "total time",round(avg(stop_exec_in_ms - START_EXEC_IN_MS)/100,2) "AVG" ,mod_name"Module name",count(*) "total call" from profiler_info
where start_execute > to_date('&start_date','dd/mm/yy')
and start_execute < to_date('&stop_date','dd/mm/yy')
group by mod_name
order by 1 desc
/
