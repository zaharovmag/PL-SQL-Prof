begin
	rsb_profiler.addmodule('testmod');
	rsb_profiler.MODSETON('testmod');
end;
/


exec rsb_profiler.TRACE_ENABLE('testmod');
exec rsb_profiler.PROFILER_START('testmod',0);
exec rsb_profiler.PROFILER_START('testmod1',1);
exec rsb_profiler.profiler_end;

exec rsb_profiler.profiler_end;


select rsb_profiler.get_current_mod from dual;