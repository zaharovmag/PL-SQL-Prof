create or replace package rsb_profiler 
as
--CONSTANT DECLARATION
--modules types
	module_type		 CONSTANT NUMBER := 0;
	func_type   		 CONSTANT NUMBER := 1;

	version			 CONSTANT NUMBER := 0.2;
--COMPLITE TRUE/FALSE
	is_notcomplite		 CONSTANT NUMBER := 0;   
	is_complite		 CONSTANT NUMBER := 1;


--DEF VALUE
	is_off			 CONSTANT NUMBER := 0;
	is_on		 	 CONSTANT NUMBER := 1;

--RESERVED CFG ID
	profiler_onwholesystem 	 CONSTANT NUMBER := 0;

--LOCAL VAR
l_audsid number := NULL;
l_sid number :=NULL;
l_operid number :=NULL;
l_last_level NUMBER :=0;
l_trace NUMBER := 0;	
l_trace_mod varchar2(100) := NULL;
--FUNCTION/PROCEDURE DECLARATION
	procedure profiler_start(mod_name in varchar2,mod_type in NUMBER);
	procedure profiler_end;
	function  profiler_ison(mod_name in varchar2) return number;
	function  profiler_onmod(mod_name in varchar2) return number;
	
	procedure setoperid;
	
	procedure AddModule(mod_name in varchar2);
	procedure SetSystemProfilerOn;
	procedure ModSetOn(mod_name in varchar2);
	procedure SetSystemProfilerOff;
	procedure ModSetOff(mod_name in varchar2);
	procedure MoveHistoryData;
	procedure trace_enable(mod_name in varchar2);
	procedure trace_disable(mod_name in varchar2);
	function  get_current_mod return varchar2;
	function  get_current_id return number;	
	procedure  set_audsid;
	procedure  set_sid;

	
	procedure trace_begin;
	procedure trace_end;

end;
/

create or replace package body rsb_profiler
is



procedure MoveHistoryData
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	insert into profiler_history(sid,audsid,operid,
					start_execute,stop_execute,start_exec_in_ms,stop_exec_in_ms,
					mod_type,mod_name,complete,modlv)
					(select sid,audsid,operid,
						start_execute,stop_execute,start_exec_in_ms,stop_exec_in_ms,
						mod_type,mod_name,complete,modlv 
					 from profiler_info);
	commit;
	execute immediate 'truncate table profiler_info';
	execute immediate 'alter index profiler_info_idx0 rebuild';
	execute immediate 'alter index profiler_info_pk rebuild';
	
end;


procedure trace_enable(mod_name in varchar2)
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set trace_ena=is_on where param_name = mod_name;
	commit;
end;

procedure trace_disable(mod_name in varchar2)
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set trace_ena=is_off where param_name = mod_name;
	commit;
end;

procedure AddModule(mod_name in varchar2)
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	insert into profiler_cfg(PARAM_NAME,PARAM_VALUE,trace_ena) values(mod_name,is_off,is_off);
	commit;
end;

procedure SetSystemProfilerOn
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set param_value = is_on 
	where id = profiler_onwholesystem ; 
	commit;
end;

procedure ModSetOn(mod_name in varchar2)
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set param_value = is_on 
	where param_name = mod_name ; 	
	commit;
end;

procedure SetSystemProfilerOff
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set param_value = is_off 
	where id = profiler_onwholesystem ; 
	commit;
end;

procedure ModSetOff(mod_name in varchar2)
as
PRAGMA AUTONOMOUS_TRANSACTION;
begin
	update profiler_cfg set param_value = is_off 
	where param_name = mod_name ; 	
	commit;
end;




function get_current_id return number
as
ll_mod_id number;
begin
	select max(id) into ll_mod_id from profiler_info where audsid = l_audsid 
	      		  and complete = rsb_profiler.is_notcomplite;
	return ll_mod_id;
end;

function  get_current_mod return varchar2
as
ll_mod_name varchar2(100);
ll_id number;
begin
	ll_id := get_current_id;
	select mod_name into ll_mod_name from  profiler_info
	       where id = ll_id;
	return  ll_mod_name;
end;



function profiler_onmod(mod_name in varchar2) return number
as
PRAGMA AUTONOMOUS_TRANSACTION;
profiler_onmodison number;
l_trace_ena number;
begin
		select param_value,trace_ena into profiler_onmodison,l_trace_ena from profiler_cfg
		       where param_name = mod_name;
		if(l_trace_ena = is_on)
		then
			trace_begin;
			l_trace := is_on;
			l_trace_mod := mod_name; 
		end if;

		return profiler_onmodison;
	        exception
			when NO_DATA_FOUND then
			     return is_off;
end;


function profiler_ison(mod_name in varchar2) return number
as
PRAGMA AUTONOMOUS_TRANSACTION;
profiler_onsystemison number;
begin
	if (l_trace = is_on)
	then
		return is_on;
	end if;

	select param_value into profiler_onsystemison
	       from profiler_cfg where id = profiler_onwholesystem;
	if profiler_onsystemison = is_on
	then
		return is_on;
	end if;
	
	return profiler_onmod(mod_name);
end;

procedure setoperid
as
begin
	select t1.t_oper into l_operid from dperson_dbt t1,dsembnk_dbt t2 where t2.t_oper=t1.t_oper and t2.t_audsid=l_audsid;
        exception
		when NO_DATA_FOUND then
		     l_operid := 0;

end;


procedure set_audsid
as
begin
	SELECT sys_context('USERENV', 'SESSIONID') into l_audsid FROM dual;	
end;

procedure set_sid
as 
begin
	select sid into l_sid from sys.v_$session where audsid=l_audsid; 
end;


procedure profiler_start(mod_name in varchar2,mod_type in NUMBER)
as
PRAGMA AUTONOMOUS_TRANSACTION;

begin
	
	if (profiler_ison(mod_name)  = is_on)
	then	
		if (l_audsid is NULL)
		then
			set_audsid;
			set_sid;
			setoperid;
		end if;
		
		l_last_level := l_last_level + 1;

		insert into profiler_info(sid,audsid,operid,start_execute,start_exec_in_ms,mod_type,mod_name,complete) 
		values(l_sid,l_audsid,l_operid,SYSDATE,dbms_utility.get_time,mod_type,mod_name,rsb_profiler.is_notcomplite);

        	commit;
	end if;

end;



procedure trace_begin
as
begin
	execute immediate 'alter session set events ''10046 trace name context forever, level 12''';
end;


procedure trace_end
as
begin
	execute immediate 'alter session set sql_trace=FALSE';
	execute immediate 'alter session set events ''10046 trace name context off''';	
end;

procedure profiler_end
as
PRAGMA AUTONOMOUS_TRANSACTION;
ll_id number;
begin


	if (l_last_level > 0)
	then

		if (l_trace = is_on and l_trace_mod = get_current_mod) 
		then
			trace_end;	
			l_trace := is_off; 
			
		end if;
		

		l_last_level := l_last_level - 1;
		ll_id := get_current_id;
		update profiler_info set complete = rsb_profiler.is_complite, stop_execute=sysdate,
		       		     	 stop_exec_in_ms = dbms_utility.get_time
		where id = ll_id;

		--(select max(id) from profiler_info where audsid = l_audsid 
	      	--	  and complete = rsb_profiler.is_notcomplite);

       		commit;
	end if;
end;


end;
/