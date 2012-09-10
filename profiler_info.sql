drop table profiler_info;
drop sequence profiler_info_sq;




create sequence profiler_info_sq
start with 1                  
increment by 1                
nocache                       
nocycle;

create table profiler_info
(
	id		number(10),
	sid		number,
	audsid 		number,
	operid 		number,
	start_execute	DATE,
	stop_execute 	DATE,
	start_exec_in_ms number,
	stop_exec_in_ms number,
	mod_type 	number,
	modlv		number,
	mod_name  	varchar2(100),
	complete	number,
	constraint profile_info_pk PRIMARY KEY(id))
        TABLESPACE USERS8K00;

create index profiler_info_idx0 on profiler_info(audsid,complete) tablespace INDEX8K00;



create or replace trigger profiler_info_insert_tgr before insert on profiler_info for each row
declare
        lid number(10);
begin
        select profiler_info_sq.nextval into lid from dual;
        :new.id:=lid;
end;
/

drop table profiler_history;
drop sequence profiler_history_sq;

create sequence profiler_history_sq
start with 1                  
increment by 1                
nocache                       
nocycle;

create table profiler_history
(
	id		number(10),
	sid		number,
	audsid 		number,
	operid 		number,
	start_execute	DATE,
	stop_execute 	DATE,
	start_exec_in_ms number,
	stop_exec_in_ms number,
	mod_type 	number,
	modlv		number,
	mod_name  	varchar2(100),
	complete	number,
	constraint profile_history_pk PRIMARY KEY(id))
        TABLESPACE USERS8K00;

create index profiler_history_idx0 on profiler_info(mod_name) tablespace INDEX8K00;
create index profiler_history_idx1 on profiler_info(start_execute,stop_execute) tablespace INDEX8K00;



create or replace trigger profiler_history_insert_tgr before insert on profiler_history for each row
declare
        lid number(10);
begin
        select profiler_history_sq.nextval into lid from dual;
        :new.id:=lid;
end;
/