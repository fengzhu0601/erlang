%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 六月 2016 下午5:52
%%%-------------------------------------------------------------------
-module(load_cfg_broadcast).
-author("clark").

%% API
-export
([
    get_calltime/2
    , get_calltime_list/1
    , get_all_broadcast_mes_id/0
    , get_notice_type/1
]).


-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_broadcast.hrl").

load_config_meta() ->
    [
        #config_meta
        {
            record = #broadcast_chat_cfg{},
            fields = ?record_fields(broadcast_chat_cfg),
            file = "broadcast.txt",
            keypos = #broadcast_chat_cfg.id,
            verify = fun verify_chat_cfg/1,
            all = [#broadcast_chat_cfg.id]
        },
        #config_meta
        {
            record = #broadcast_condition_cfg{},
            fields = ?record_fields(broadcast_condition_cfg),
            file = "broadcast_condition.txt",
            keypos = #broadcast_condition_cfg.id,
            verify = fun verify_condition_cfg/1
        },
        #config_meta
        {
            record = #broadcast_des_cfg{},
            fields = ?record_fields(broadcast_des_cfg),
            file = "broadcast_des.txt",
            keypos = #broadcast_des_cfg.id,
            verify = fun verify_des_cfg/1
        }
    ].

verify_chat_cfg(#broadcast_chat_cfg{id = Id, type = TypeList, function_event = _EventList} = _Chat) ->
    ?check(is_list(TypeList), "broadcast.txt Id: ~p type:~p 格式不正确", [Id, TypeList]),
    ?check(erlang:length(TypeList) =:= 2,  "broadcast.txt Id: ~p type:~p 格式不正确", [Id, TypeList]),
    [Type1, Type2] = TypeList,
    ?check(is_integer(Type1),  "broadcast.txt Id: ~p type:~p 格式不正确", [Id, TypeList]),
    ?check(is_integer(Type2),  "broadcast.txt Id: ~p type:~p 格式不正确", [Id, TypeList]),
    ok.

verify_condition_cfg(#broadcast_condition_cfg{}) ->
    ok.

verify_des_cfg(#broadcast_des_cfg{}) ->
    ok.

%% 根据配置选择相应的数据筛选方法(目前只有在发送服务器维护信息时候使用)
get_calltime(Id, Num) ->
    case lookup_broadcast_chat_cfg(Id) of
        #broadcast_chat_cfg{function_event = CallTimeList} ->
            case lists:keyfind(Id, 1, CallTimeList) of
                {_Id, TimeTuple} ->
                    TimeList = tuple_to_list(TimeTuple),
                    Len = erlang:length(TimeList),
                    if
                        Len < Num -> nil;
                        true -> lists:nth(Num, TimeList)
                    end;
                _ ->
                    nil
            end;
        _ ->
            nil
    end.

get_calltime_list(Id) ->
    case lookup_broadcast_chat_cfg(Id) of
        #broadcast_chat_cfg{function_event = FunEvent} ->
            case lists:keyfind(Id, 1, FunEvent) of
                {_Id, TimeTuple} ->
                    tuple_to_list(TimeTuple);
                _ ->
                    {error, unknow_type}
            end;
        _ ->
            {error, unknow_type}
    end.


%% 获取所有的广播id
get_all_broadcast_mes_id() ->
    [Id || Id <- lookup_all_broadcast_chat_cfg(#broadcast_chat_cfg.id), is_integer(Id)].

%% 获取公告播放类型
get_notice_type(Id) ->
    case lookup_broadcast_chat_cfg(Id) of
        #broadcast_chat_cfg{type = [Type1, Type2]} ->
            {Type1, Type2};
        _ ->
            {0, 0}
    end.