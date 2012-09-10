drop table profiler_cfg;
drop sequence profiler_cfg_sq;


create sequence profiler_cfg_sq
start with 1000                  
increment by 1                
nocache                       
nocycle;

create table profiler_cfg
(
	id		NUMBER(10),
	param_name 	varchar2(30),
	param_value	number(2),
	param_subvalue 	varchar2(40),
	trace_ena	number,
	constraint profile_cfg_pk PRIMARY KEY(id)
) tablespace users;


create unique index profiler_cfg_idx0 on profiler_cfg(param_name) tablespace INDX;


--profiler on system  is off
insert into profiler_cfg(id,param_name,param_value) values(0,'profiler on system',0);

--create trigger
create or replace trigger profiler_cfg_insert_tgr before insert on profiler_cfg for each row
declare
        lid number(10);
begin
        select profiler_cfg_sq.nextval into lid from dual;
        :new.id:=lid;
end;
/