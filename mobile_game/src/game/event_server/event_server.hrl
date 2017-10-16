%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十一月 2015 下午8:07
%%%-------------------------------------------------------------------
-author("clark").


-define(CHILD(Mod, Type, Args),
    {
        Mod,
        {Mod, start_link, Args},
        transient, 2000, Type, [Mod]
    }
).

-define(SUP_LINK(Mod, Args),
    {
        Mod,
        {Mod, start_link, Args},
        permanent, 2000, supervisor, [Mod]
    }
).

-define(WORKER_LINK(Mod, Args),
    {
        Mod,
        {Mod, start_link, Args},
        permanent, 2000, worker, [Mod]
    }
).


-define(CHILD_WORKER(ProcessMod, Name, Mod, Args),
    {
        Name,
        {ProcessMod,start_link,[{Name, Mod, Args}]},
        permanent, 2000, worker, [Mod]
    }
).



-define(init_ok(Args, Timeout),                     {ok, Args, Timeout}).
-define(init_stop(),                                {stop, crash}).

% --------------------------------------------------------------------
% Function: handle_call/3
% Description: Handling call messages
% Returns: {reply, Reply, State}          |
%          {reply, Reply, State, Timeout} |
%          {noreply, State}               |
%          {noreply, State, Timeout}      |
%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
-define(call_reply(Ret, State),                     {reply, Ret, State}).
-define(call_reply_ex(Ret, State, Timeout),         {reply, Ret, State, Timeout}).
-define(call_stop(Ret, State),                      {stop, normal, Ret, State}).
-define(call_stop_ex(Reason, Ret, State),           {stop, Reason, Ret, State}).


% --------------------------------------------------------------------
% Function: handle_cast/2
% Description: Handling cast messages
% Returns: {noreply, State}          |
%          {noreply, State, Timeout} |
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
-define(cast_noreply(State),                        {noreply, State}).
-define(cast_noreply_ex(State, Timeout),            {noreply, State, Timeout}).
-define(cast_stop(Reason, State),                   {stop, Reason, State}).


% --------------------------------------------------------------------
% Function: handle_info/2
% Description: Handling all non call/cast messages
% Returns: {noreply, State}          |
%          {noreply, State, Timeout} |
%          {stop, Reason, State}            (terminate/2 is called)
% --------------------------------------------------------------------
-define(info_noreply(State),                        {noreply, State}).
-define(info_noreply_ex(State, Timeout),            {noreply, State, Timeout}).
-define(info_stop(Reason, State),                   {stop, Reason, State}).


% --------------------------------------------------------------------
% terminate(Reason, State) -> no_return()
%       Reason = normal | shutdown | Term
% --------------------------------------------------------------------
-define(is_normal(Reason), Reason == normal).
-define(is_shutdown(Reason), Reason == shutdown).
-define(is_term(Reason), Reason == Term).
-define(terminate_ret(), nil).

% --------------------------------------------------------------------
% code_change
% --------------------------------------------------------------------
-define(code_change_ret(Ret,State), {Ret, State}).


% send event
-define(send_event(Eng, Evt, Data), Eng!{Evt, Data}).

