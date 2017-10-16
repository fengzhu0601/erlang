-module(mall_server).
-include("inc.hrl").
% -include_lib("pangzi/include/pangzi.hrl").

-include("player.hrl").
-include("load_cfg_mall.hrl").


-behaviour(gen_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([get_mall_count/1]).


-record(state, {}).

init_mall() ->
    Size = ets:info(system_mall, size),
    if
        Size =:= 0 ->
            lists:foreach(fun({_, Pac}) ->
                Id = Pac#mall_cfg.id,
                Num = Pac#mall_cfg.number,
                dbcache:insert_new(?system_mall, #system_mall{id=Id, number = Num})
            end,
            ets:tab2list(mall_cfg));
        true ->
            pass
    end.


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    init_mall(),
    {ok, #state{}}.


handle_call({is_can_buy, MallId, Count}, _From, State) ->
    ?DEBUG_LOG("is_can_buy--------------------:~p",[dbcache:lookup(?system_mall, MallId)]),
    IsCan = 
    case dbcache:lookup(?system_mall, MallId) of
        [#system_mall{number = -1}] ->
            ?true;
        [#system_mall{number = 0}] ->
            ?false;
        [#system_mall{number = Num}] when Num - Count >= 0 ->
            dbcache:update(?system_mall, #system_mall{id=MallId, number = erlang:max(0, Num - Count)}),
            ?true;
        _ ->
            ?false
    end,
    {reply, IsCan, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {reply, ok, State}.

handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

% load_db_table_meta() ->
%     [
%         #db_table_meta{name = ?system_mall,
%             fields = ?record_fields(system_mall),
%             load_all = ?true,
%             shrink_size = 1,
%             flush_interval = 5}
%     ].

get_mall_count(MallId) ->
    case dbcache:lookup(?system_mall, MallId) of
        [#system_mall{number = Count}] ->
            Count;
        _ ->
            -1
    end.