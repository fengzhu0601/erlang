-module(ranking_lib).
-behaviour(gen_server).

-include_lib("pangzi/include/pangzi.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-include("inc.hrl").
-include("rank.hrl").
-include("player.hrl").

-export([start_link/0, init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).


%% API
-export
([
    update/3,
    get_top1_by_name/2,
    get_rank_order/2,
    get_rank_order/3,
    get_rank_order_page/3,
    get_rank_order_page/4,
    get_rank_page_by_role/3,
    reset_rank/3,
    reset_rank/1,
    lookup_data_by_name/1,
    get_top1_by_zhanli_and_role/2,
    flush_rank_by_rankname/1,
    flush_rank_only_by_rankname/1,
    start_send_after_by_rankname/3,
    get_rank_player_list/1,
    get_rank_info/1,
    get_top_n/2,
    get_top_3_info/1,
    get_top_n_info/2
]).


-define(pd_ranking(Name), {pd_ranking, Name}). %% 存的是单个排行榜的数据list
-define(pd_ranking_tree(Name), {pd_ranking_tree, Name}). %% %% 存的是单个排行榜的数据gb_trees
-define(RANKING_INTERVAL_MINUTE, 30).                       %% 5分钟更新排行榜
-define(CHECK_TIME_INTEVAL, 5).


%% create a rank
-define(flush_rank, flush_ets).


-define(reset, reset).

-define(update, update).
-define(ranking_tab, ranking_tab).

-define(rank_new(Name, MaxSize), #rank_info{name=Name, max_size=MaxSize}).
-define(ALL_RANKS,
    [
        ?rank_new(?ranking_level            ,100),
        ?rank_new(?ranking_zhanli           ,200),
        ?rank_new(?ranking_arena            ,100),
        ?rank_new(?ranking_ac               ,100),
        ?rank_new(?ranking_meili            ,100),
        ?rank_new(?ranking_abyss            ,200),
        ?rank_new(?ranking_guild            ,100),
        ?rank_new(?ranking_camp             ,100),
        ?rank_new(?ranking_camp_god         ,100),
        ?rank_new(?ranking_camp_magic       ,100),
        ?rank_new(?ranking_camp_person      ,100),
        ?rank_new(?ranking_daily_1          ,100),
        ?rank_new(?ranking_daily_2          ,100),
        ?rank_new(?ranking_sky_ins_kill_player, 100),
        ?rank_new(?ranking_sky_ins_kill_monster, 100),
        ?rank_new(?ranking_suit             ,100),
        ?rank_new(?ranking_gwgc             ,201),
        ?rank_new(?ranking_bounty           ,100),
        ?rank_new(?ranking_ride             ,200),
        ?rank_new(?ranking_pet              ,200),
        ?rank_new(?ranking_suit_new         ,200),
        ?rank_new(?ranking_daily_4          ,200),
        ?rank_new(?ranking_daily_5          ,200)
    ]).


-define(ALL_RANKS_NAME,
    [
        ?ranking_level,
        ?ranking_zhanli,
        ?ranking_arena,
        ?ranking_ac,
        ?ranking_meili,
        ?ranking_abyss,
        ?ranking_guild,
        ?ranking_camp,
        ?ranking_camp_god,
        ?ranking_camp_magic,
        ?ranking_camp_person,
        ?ranking_daily_1,
        ?ranking_daily_2,
        ?ranking_sky_ins_kill_monster,
        ?ranking_sky_ins_kill_player,
        ?ranking_suit,
        ?ranking_gwgc,
        ?ranking_bounty,
        ?ranking_ride,
        ?ranking_pet,
        ?ranking_suit_new,
        ?ranking_daily_4,
        ?ranking_daily_5
    ]).

-define(WEEK_RESET_RANK,
    [
        ?ranking_daily_4,
        ?ranking_daily_5
    ]).

%% 王者排行榜 1个小时刷新一次
-define(KING_RANKS_NAME,
    [
        ?ranking_zhanli,
        ?ranking_guild,
        ?ranking_abyss,
        ?ranking_pet,
        ?ranking_ride,
        ?ranking_suit_new
    ]
).

-define(GUILD_FUN, fun(A,B) -> A > B end).


-record(ranking_tab, {name,
                      ranking=[]}). %% {playerId, SortValue}

-record(rank_info, {name,
                    max_size,    %% 最大的排行数量
                    size = 0     %% 已经有的排行数量
}).



init_tab() ->
    lists:foreach(fun(RankName) ->
        true = dbcache:insert_new(?ranking_tab, #ranking_tab{name=RankName})
    end,
    all_rank_names()),
    ok.




all_rank_names() ->
    lists:map(fun(#rank_info{name=Name}) ->
        Name end,
    ?ALL_RANKS).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    com_process:init_name(<<"ranking_lib">>),
    %%load_data(),
    lists:foreach(fun init_rank/1, ?ALL_RANKS),
    erlang:send_after(?CHECK_TIME_INTEVAL * 1000, ?MODULE, {'CHECK_IS_RESET'}),
    {ok, <<"ranking_lib">>}.

handle_call(_Request, _From, State) ->
    ?ERROR_LOG("unknown msg~p", [_Request]),
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    ?ERROR_LOG("unknown msg~p", [_Msg]),
    {noreply, State}.

%% TODO 只记录需要排的,而不是所有
%% 只记录，更新请求，在间隔时间到了后统一更新到ets中
handle_info({?update, ?ranking_gwgc, Key, SortValue}, State) ->
    case erlang:get(?pd_ranking(?ranking_gwgc)) of
        ?undefined ->
            pass;
        _ ->
            Pd= ?pd_ranking_tree(?ranking_gwgc),
            Gb = get(Pd),
            CurV = 
            case gb_trees:lookup(Key, Gb) of
                ?none ->
                    0;
                {value, V} ->
                    V
            end,
            %?DEBUG_LOG("CurV-------------------------:~p",[CurV]),
            erlang:put(Pd,
                       gb_trees:enter(Key, SortValue+CurV, Gb))
    end,
    {noreply, State};

handle_info({?update, RankName, Key, SortValue}, State) ->
%%    ?DEBUG_LOG("RankName----:~p-----SortValue----:~p",[RankName, SortValue]),
    case erlang:get(?pd_ranking(RankName)) of
        ?undefined ->
            ?ERROR_LOG("can not find rank name ~p", [RankName]);
        _ ->
            Pd= ?pd_ranking_tree(RankName),
            erlang:put(Pd, gb_trees:enter(Key, SortValue, get(Pd)))
    end,
    {noreply, State};


%% 把所有的更新同步到ets表中
handle_info({?flush_rank, RankName}, State) ->
    %% 刷新前的排名前三
    OldTopN = get_top_n(RankName, 3),
    flush_rank(RankName),
    %% 刷新后的排名前三
    NewTopN = get_top_n(RankName, 3),

    case lists:member(RankName, ?KING_RANKS_NAME) of
        ?true ->
            impact_ranking_list_service:boardcast_ranking_list_change(RankName, OldTopN, NewTopN);
        _ ->
            pass
    end,
    start_flush_rank_timer(RankName),
    {noreply, State};

handle_info({flush_rank_only, RankName}, State) ->
    %% 刷新前的排名前三
    OldTopN = get_top_n(RankName, 3),
    flush_rank(RankName),
    %% 刷新后的排名前三
    NewTopN = get_top_n(RankName, 3),
    impact_ranking_list_service:boardcast_ranking_list_change(RankName, OldTopN, NewTopN),
    {noreply, State};

%% 重置排行榜
handle_info({?reset, RankName}, State) ->
    %?DEBUG_LOG("reset RankName----------------------:~p",[RankName]),
    case erlang:get(?pd_ranking(RankName)) of
        ?undefined ->
            ?ERROR_LOG("can not find rank name ~p", [RankName]);
        _RankInfo ->
            erlang:put(?pd_ranking_tree(RankName), gb_trees:empty()),

            _MapName = get_map_name(RankName),
            ets:delete_all_objects(get_map_name(RankName)),
            ets:delete(?ranking_tab, RankName),
            case erase({ranking_tab, RankName}) of
                ?undefined ->
                    pass;
                RankData -> 
                    dbcache:update(?ranking_tab, RankData#ranking_tab{ranking=[]})
            end
    end,
    {noreply, State};

handle_info({start_send_after_by_rankname, RankName, PidName, Time}, State) ->
    flush_rank(RankName),
    start_flush_rank_timer(RankName, PidName, Time),
    {noreply, State};

handle_info({'CHECK_IS_RESET'}, State) ->
    {{Year, Month, Day}, {H, M, S}} = calendar:local_time(),
    case calendar:day_of_the_week(Year, Month, Day) =:= 1 andalso H =:= 0 andalso M =:= 0 andalso S < ?CHECK_TIME_INTEVAL of
        true -> %% 周重置
            week_reset();
        _ ->
            pass
    end,
    erlang:send_after(?CHECK_TIME_INTEVAL * 1000, ?MODULE, {'CHECK_IS_RESET'}),
    {noreply, State};

handle_info(_Msg, State) ->
    ?ERROR_LOG("~p unkonwn msg ~p", [?pname(), _Msg]),
    {noreply, State}.

%% save to db
terminate(Reason, State) ->
%%     lists:foreach(fun(#rank_info{name=Name}) ->
%%         quickdb:update(?ranking_tab,Name, #ranking_tab{name=Name, ranking=ets:tab2list(Name)})
%%                   end,
%%                   ?ALL_RANKS),
    user_default:every_shut_msg(?FILE,?MODULE,?LINE,Reason,State),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


get_rank_player_list(RankName) ->
    %% 获取玩家ID
    Ranking = lookup_data_by_name(RankName),
    %?INFO_LOG("Ranking:~p", [Ranking]),
    AbyssPlayerList =
        lists:foldr(
            fun({PlayerId,_SortValue}, AccList) ->
                [PlayerId | AccList]
            end,
            [],
            Ranking),
    AbyssPlayerList.

%% 获取排行信息
get_rank_info(RankName) ->
    erlang:get(?pd_ranking(RankName)).

%% save data to db
%% save_data() ->
%%     lists:foreach(fun(#rank_info{name=Name}) ->
%%         quickdb:update(?ranking_tab,Name, #ranking_tab{name=Name, ranking=ets:tab2list(Name)})
%%                   end,
%%                   ?ALL_RANKS),
%%     ok.

%% @doc 更新自己的记录.
%% SortValue 是需要排序的数值    

update(RankName, PlayerId, SortValue) when is_integer(SortValue)->%% todo bug
    case lists:member(RankName, ?ALL_RANKS_NAME) of
        ?true ->
            ?MODULE ! {?update, RankName, PlayerId, SortValue};
        _ ->
            pass
    end;

update(RankName, PlayerId, SortValue) ->%% todo bug
    case lists:member(RankName, ?ALL_RANKS_NAME) of
        ?true ->
            ?MODULE ! {?update, RankName, PlayerId, SortValue};
        _ ->
            pass
    end.


%% @doc 得到一个人在指定排行的排名.
get_rank_order(RankName, PlayerId) ->
%%     ?INFO_LOG("rankname:~p ", [RankName]),
%%     ?INFO_LOG("get_map_name:~p ", [get_map_name(RankName)]),
    case ets:lookup(get_map_name(RankName), PlayerId) of
        [{_PlayerId, Order, Value}] -> 
            {Order, Value};
        [] ->
            {0,0}
    end.

%% @doc 得到一个人在指定排行的排名. 虚空深渊
get_rank_order(RankName, PlayerId, Def) ->
    case ets:lookup(get_map_name(RankName), PlayerId) of
        [{_PlayerId, Order, Value}] -> {Order, Value};
        [] -> Def
    end.



get_rank_order_page(Star, Len, Name) ->
    case lookup_data_by_name(Name) of
        [] ->
            {0, 0, []};
        R ->
            %?DEBUG_LOG("R----------------------:~p",[R]),
            Size = length(R),
            NStar = min(Star, Size),
            {Size, NStar, lists:sublist(R, NStar, Len)}
    end.


get_rank_order_page(Star, Len, Name, MaxLen) ->
%%     ?INFO_LOG("================R:~p ", [lookup_data_by_name(Name)]),
    case lookup_data_by_name(Name) of
        [] ->
            {0, 0, []};
        R ->
            NR = lists:sublist(R, MaxLen),
            Size = length(NR),
            NStar = min(Star, Size),
            {Size, NStar, lists:sublist(NR, NStar, Len)}
    end.



%% 根据职业获取对应的排行榜
get_rank_page_by_role(YeShu, Name, Role) ->
    End = YeShu * 10,
    Begin = End - 9,
    {_Size, _List} = case lookup_data_by_name(Name) of
                       [] ->
                          {1, []};
                       R ->
                           put(rank_role, Role),
                           R2 = lists:filter(fun(T) ->
                               {PlayerId, _} = T,
                               Role = get(rank_role),
                               case player:lookup_info(PlayerId, [?pd_career])of
                                   [] ->
                                        false;
                                   [Job] ->
                                       if
                                           Job =:= Role ->
                                              true;
                                           true ->
                                              false
                                       end
                               end
                           end, R),
                           Size = length(R2),
                           if
                               Size =< 10 andalso Size >= 0 ->
                                  {1, R2};
                               true ->
                                  %?DEBUG_LOG("R2------------:~p----Begin---:~p----End--:~p",[R2, Begin, End]),
                                  List = lists:sublist(R2, Begin, End),
                                  {page(Size), List}
                           end
                     end.

page(Size) ->
    case {Size div 10, Size rem 10} of
        {N,0} ->
            N;
        {N,_} -> N + 1
    end.

get_top1_by_zhanli_and_role(Name, Role) ->
    case lookup_data_by_name(Name) of
        [] ->
            pass;
        R ->
            put(rank_role, Role),
            R2 = 
            lists:filter(fun(T) ->
               {PlayerId, _} = T,
               Role = get(rank_role),
               case player:lookup_info(PlayerId, [?pd_career])of
                    [] ->
                        false;
                    [Job] ->
                        if
                            Job =:= Role ->
                                true;
                            true ->
                                false
                        end
               end
            end, 
            R),
            if
                R2 =:= [] ->
                   pass;
                true ->
                    lists:nth(1, R2)
            end
    end.



%% 获取单个排行榜的第一名
get_top1_by_name(RankName, Rank) ->
    case lookup_data_by_name(RankName) of
        [] ->
             0;
        R ->
            Size = length(R),
            if
                Rank > Size ->
                    0;
                true ->
                    {PlayerId, _} =
                        if
                            RankName =:= ?ranking_arena ->
                                lists:nth(Rank, lists:keysort(2, R));
                            true ->
                                lists:nth(Rank, lists:reverse(lists:keysort(2, R)))
                        end,
                    PlayerId
            end
    end.

%% 获取前N名
get_top_n(_RankName, N) when N =< 0  ->
    [];
get_top_n(RankName, N) ->
    case lookup_data_by_name(RankName) of
        [] ->
            [];
        R ->
            lists:sublist(R, N)
    end.

%% 获取排行榜前三名Id及名次
get_top_3_info(RankName) ->
    RankList = get_top_n(RankName, 3),
    {_, Top3IdList} =
        lists:foldl(
            fun({Id, _RankValue}, {Rank,Acc}) ->
                {Rank+1,[{Id, Rank+1} | Acc]}
            end,
            {0,[]},
            RankList
        ),
    Top3IdList.

get_top_n_info(RankName, N) ->
    RankList = get_top_n(RankName, N),
    {_, Top3IdList} =
        lists:foldl(
            fun({Id, _RankValue}, {Rank,Acc}) ->
                {Rank+1,[{Id, Rank+1} | Acc]}
            end,
            {0,[]},
            RankList
        ),
    Top3IdList.

%% 查询对应的排名数据
lookup_data_by_name(Name) ->
    case dbcache:lookup(?ranking_tab, Name) of
        [] ->
            [];
        [R] ->
            R#ranking_tab.ranking
    end.

start_flush_rank_timer(RankName, PidName, Time) ->
    case whereis(PidName) of
        ?undefined ->
            %?DEBUG_LOG("1-----------------------------------"),
            pass;
        _ ->
            %?DEBUG_LOG("2-----------------------------------"),
            ?send_after_self(1000* Time,{start_send_after_by_rankname, RankName, PidName, Time})
    end.
start_flush_rank_timer(Name) ->
    ?send_after_self(1000* (?SECONDS_PER_MINUTE * ?RANKING_INTERVAL_MINUTE + ?random(30)),{?flush_rank, Name}).

flush_rank(RankName) ->
    % 前提: ets中所有的obj在进程字典中都存在
    #rank_info{max_size=MaxSize} = erlang:get(?pd_ranking(RankName)),
    %% 
    Tree = erlang:get(?pd_ranking_tree(RankName)),
    Size = gb_trees:size(Tree),
    SortTupleList =
        if
            RankName =:= ?ranking_arena ->
                List111 = lists:reverse(lists:keysort(2, gb_trees:to_list(Tree))),
                List111;
            true ->
                lists:reverse(lists:keysort(2, gb_trees:to_list(Tree)))
        end,
    {NewRank, Rest} =
        if Size > MaxSize ->
            lists:split(MaxSize, SortTupleList);
            true ->
                {SortTupleList, []}
        end,


    flush_ets(RankName, NewRank),

    %% delete Reset from Tree
    NewTree =
        lists:foldl(
            fun({Key, _}, Acc) ->
                gb_trees:delete(Key, Acc)
            end,
            Tree,
            Rest
        ),
    erlang:put(?pd_ranking_tree(RankName), NewTree),
    %start_flush_rank_tiemr(RankName),
    ok.


%% rankRow {playerId, SortValue}
flush_ets(RankName, Rank) ->
    %?DEBUG_LOG("RankName------:~p------Rank-----:~p",[RankName, Rank]),
    if
        Rank =:= [] ->
            pass;
        true ->
            case dbcache:lookup(?ranking_tab, RankName) of
                [] ->
                    NewR = #ranking_tab{name=RankName, ranking=Rank},
                    put({ranking_tab, RankName}, NewR), 
                    dbcache:update(?ranking_tab, NewR);
                [R] ->
                    LastRankData = get({ranking_tab, RankName}),
                    NewR = R#ranking_tab{ranking=Rank},
                    if
                        LastRankData =:= NewR ->
                            pass;
                        true ->
                            put({ranking_tab, RankName}, NewR),
                            dbcache:update(?ranking_tab, NewR)
                    end
            end,
            MapName = get_map_name(RankName),
            {_, MapRank} = 
            lists:foldl(
                fun({PlayerId, Value}, {Order, Acc}) ->
                    {Order+1, [{PlayerId, Order, Value} | Acc]}
                end,
                {1, []},
                Rank
            ),
            ets:delete_all_objects(MapName),
            ?true = ets:insert_new(MapName, MapRank)  %% 這個表中的數據格式{PlayerId, Rank}
    end,
    ok.


get_map_name(Name) -> %%return rankmap_17
    erlang:list_to_atom(lists:append(atom_to_list('rankmap_'),integer_to_list(Name))).

init_rank(#rank_info{name=Name}=Info) ->
    MapName = get_map_name(Name),
    MapName = ets:new(MapName,
                      [named_table,
                       ?protected,
                       {?read_concurrency, true}]),      %% 反向映射排行

    ?pd_new(?pd_ranking(Name), Info),
    case dbcache:lookup(?ranking_tab, Name) of
        [] ->
            ?pd_new(?pd_ranking_tree(Name), gb_trees:empty());
        [#ranking_tab{ranking=Ranking}] ->
            %?DEBUG_LOG("Ranking------------------~p-Name----:~p",[Ranking, Name]),
            ?pd_new(?pd_ranking_tree(Name), gb_trees:from_orddict(orddict:from_list(Ranking))),
            flush_ets(Name, Ranking)
    end,

    start_flush_rank_timer(Name),
    ok.

week_reset() ->
    lists:foreach(
        fun(RankName) ->
                flush_rank(RankName),
                RankList = lookup_data_by_name(RankName),
                case RankName of
                    ?ranking_daily_4 ->
                        daily_activity_mng:send_rank_prize(1, RankList);
                    ?ranking_daily_5 ->
                        daily_activity_mng:send_rank_prize(2, RankList);
                    _ ->
                        pass
                end,
                reset_rank(RankName),
                ok
        end,
        ?WEEK_RESET_RANK
    ).

reset_rank(_RankName, _MaxSize, _Ranking) ->
    %erlang:put(?pd_ranking(RankName), #rank_info{name = RankName, max_size = MaxSize, size = 0}),
    %erlang:put(?pd_ranking_tree(RankName), gb_trees:from_orddict(orddict:from_list(Ranking))),
    %flush_ets(RankName, Ranking).
    ok.

start_send_after_by_rankname(RankName, PidName, Time) ->
    ?MODULE ! {start_send_after_by_rankname, RankName, PidName, Time},
    ok.


reset_rank(RankName) ->
    ?MODULE ! {?reset, RankName},
    ok.


flush_rank_by_rankname(RankName) ->
    ?MODULE ! {?flush_rank, RankName}.

flush_rank_only_by_rankname(RankName) ->
    ?MODULE ! {flush_rank_only, RankName}.

load_db_table_meta() ->
    [
        #?db_table_meta{
            name = ?ranking_tab,
            fields = ?record_fields(?ranking_tab),
            flush_interval = 5,
            shrink_size = 5,
            load_all = true,
            init = fun init_tab/0
        }
    ].



% %%%-------------------------------------------------------------------
% %%% @author zl
% %%% @doc 实现一个排行功能模块.
% %%%       只能排整形数字，从大到小.
% %%%       排序大小为1000 级别
% %%%
% %%%       排名的类型，1只增排名： 就是一个玩家的排名数据是只增的，不会减少.
% %%%                                 这样的排名有，最佳历史排名.
% %%%                   2. 增减排名： 就是一个玩家的排名数据可增可减，
% %%%
% %%%              II 间隔排名，实时排名
% %%%
% %%%      对于数据的拉取有两种方式
% %%%      1. 一起拉去所有数据，在实时更新
% %%%      2. 每次拉去，每次请求,
% %%%
% %%%      TODO 全部排名，就是对所有玩家排名, 可以考虑排名服务器
% %%%
% %%%
% %%%      架构，1. 一个process，处理所有排行的写入更新,
% %%%            2. 排行在一个ets 表中存储所有的排行中的信息，
% %%%            3. 对数据的更新先暂存，由process统一间隔的刷新排行到ets中
% %%%            4. 其他玩家从ets中读取
% %%%
% %%%
% %%%
% %%% @end
% %%%-------------------------------------------------------------------

% -module(ranking_lib).
% -behaviour(gen_server).

% -include_lib("stdlib/include/ms_transform.hrl").
% -include_lib("pangzi/include/pangzi.hrl").

% -include("inc.hrl").
% -include("rank.hrl").
% -include("load_db_misc.hrl").
% -include("player.hrl").

% -export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


% %% API
% -export([
%     update/3,
%     get_top1_by_name/1,
%     get_len_by_name/1,
%     lookup_data_by_name/1,
%     flush_ets/2,
%     get_player_by_order/2,
%     get_rank_order/2, get_rank_order/3, get_rank_page/2, get_rank_page/3, get_rank_page/4
%     ,get_rank_order_page/3, get_rank_order_page/4
%     ,reset_rank/1, flush_rank_/1, get_order_by_player/2
%     ,show/1, reset_rank/3
% ]).


% %% pd



% %% create a rank
% -define(flush_rank, flush_ets).


% -define(update, update).
% -define(arena_ret, arena_ret).
% -define(reset, reset).
% -define(ranking_tab, ranking_tab).

% -define(rank_new(Name, MaxSize), #rank_info{name = Name, max_size = MaxSize}).
% -define(ALL_RANKS,
%     [
%         ?rank_new(?ranking_arena, 500),
%         ?rank_new(?ranking_guild, 1000),
%         ?rank_new(?ranking_lev, 100),
%         ?rank_new(?ranking_power, 100),
%         ?rank_new(?ranking_friend_score, 100),
%         ?rank_new(?ranking_camp, 100),
%         ?rank_new(?ranking_camp_god, 100),
%         ?rank_new(?ranking_camp_magic, 100),
%         ?rank_new(?ranking_camp_person, 100),
%         ?rank_new(?ranking_daily_1, 100),
%         ?rank_new(?ranking_daily_2, 100),
%         ?rank_new(?ranking_abyss, 100),
%         ?rank_new(?ranking_sky_ins_kill_player, 100),
%         ?rank_new(?ranking_sky_ins_kill_monster, 100),


%         %% @doc 特殊称号
%         ?rank_new(?ranking_career_1_power, 10),
%         ?rank_new(?ranking_career_2_power, 10),
%         ?rank_new(?ranking_career_3_power, 10),
%         ?rank_new(?ranking_career_4_power, 10)

%         %%?rank_new(ranking_zhanli   ,100),
%         %%?rank_new(ranking_equip    ,100),
%         %%?rank_new(ranking_jade     ,100),
%         %%?rank_new(ranking_zhanhun  ,100),
%         %%?rank_new(ranking_mount    ,100),
%         %%?rank_new(ranking_jungong  ,100),
%         %%?rank_new(ranking_chengjiu ,100)
%     ]).

% -record(ranking_tab, {name,
%     ranking = []}). %% {playerId, SortValue}

% -record(rank_info, {name,
%     max_size,  %% 最大的排行数量
%     size = 0     %% 已经有的排行数量
% }).


% load_db_table_meta() ->
%     [
%         #?db_table_meta{
%             name = ?ranking_tab,
%             fields = ?record_fields(?ranking_tab),
%             flush_interval = 0,
%             shrink_size = 5,
%             load_all = true,
%             init = fun init_tab/0
%         }
%     ].


% reset_rank(RankName) ->
%     ?MODULE ! {?reset, RankName}.

% flush_rank_(RankName) ->
%     ?MODULE ! {?flush_rank, RankName}.

% %%
% init_tab() ->
%     lists:foreach(
%         fun(RankName) ->
%             true = dbcache:insert_new(?ranking_tab, #ranking_tab{name = RankName})
%         end,
%         all_rank_names()),
%     ok.




% all_rank_names() ->
%     lists:map(fun(#rank_info{name = Name}) ->
%         Name end,
%         ?ALL_RANKS).



% start_link() ->
%     gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


% init([]) ->
%     com_process:init_name(<<"ranking_lib">>),

%     %%load_data(),
%     lists:foreach(fun init_rank/1, ?ALL_RANKS),

%     %% 还没理清这代码的进程创建关系，先借这贵宝地实现初始化了
%     load_db_misc:load(),
%     load_db_misc:set(?misc_server_start_time, erlang:now()),

%     {ok, <<"ranking_lib">>}.




% handle_call({get_player_arena_order, PlayerID}, _From, State) ->
%     Order = ranking_arena:on_call_get_order(PlayerID),
%     {reply, {ok, Order}, State};

% handle_call(_Request, _From, State) ->
%     ?ERROR_LOG("unknown msg~p", [_Request]),
%     {reply, ok, State}.

% handle_cast(_Msg, State) ->
%     ?ERROR_LOG("unknown msg~p", [_Msg]),
%     {noreply, State}.

% %% 重置排行榜
% handle_info({?reset, RankName}, State) ->
%     case erlang:get(?pd_ranking(RankName)) of
%         ?undefined ->
%             ?ERROR_LOG("can not find rank name ~p", [RankName]);
%         RankInfo ->
%             erlang:put(?pd_ranking(RankName), RankInfo#rank_info{size = 0}),
%             erlang:put(?pd_ranking_tree(RankName), gb_trees:empty()),
%             ets:delete_all_objects(get_map_name(RankName)),
%             ets:delete(?ranking_tab, RankName)
%     end,
%     {noreply, State};

% %% TODO 只记录需要排的,而不是所有
% %% 只记录，更新请求，在间隔时间到了后统一更新到ets中
% handle_info({?update, RankName, Key, SortValue}, State) ->
%     case erlang:get(?pd_ranking(RankName)) of
%         ?undefined ->
%             ?ERROR_LOG("can not find rank name ~p", [RankName]);
%         _ ->
%             Pd = ?pd_ranking_tree(RankName),
%             erlang:put(Pd, gb_trees:enter(Key, SortValue, erlang:get(Pd)))
%     end,
%     {noreply, State};

% handle_info({?arena_ret, IsWin, PlayerID, OpsOrder}, State) ->
%     ?INFO_LOG("ranking change error!!!"),
%     ranking_arena:on_msg_p2erank_attack_ret(IsWin, PlayerID, OpsOrder),
%     {noreply, State};


% %% 把所有的更新同步到ets表中
% handle_info({?flush_rank, RankName}, State) ->
%     flush_rank(RankName),
%     {noreply, State};



% handle_info(_Msg, State) ->
%     ?ERROR_LOG("~p unkonwn msg ~p", [?pname(), _Msg]),
%     {noreply, State}.

% %% save to db
% terminate(_Reason, _State) ->
% %%     lists:foreach(fun(#rank_info{name=Name}) ->
% %%         dbcache:update(?ranking_tab, #ranking_tab{name=Name, ranking=ets:tab2list(Name)})
% %%                   end,
% %%                   ?ALL_RANKS),
%     ok.

% code_change(_OldVsn, State, _Extra) ->
%     {ok, State}.



% %% save data to db
% %% save_data() ->
% %%     lists:foreach(fun(#rank_info{name=Name}) ->
% %%         dbcache:update(?ranking_tab, #ranking_tab{name=Name, ranking=ets:tab2list(Name)})
% %%                   end,
% %%                   ?ALL_RANKS),
% %%     ok.



% %% @doc 更新自己的记录.
% %% SortValue 是需要排序的数值
% update(RankName, PlayerId, SortValue) ->
%     ?MODULE ! {?update, RankName, PlayerId, SortValue}.


% %% @doc 得到一个人在指定排行的排名.
% get_rank_order(RankName, PlayerId) ->
%     get_rank_order(RankName, PlayerId, out_rank).


% %% 或者自己直接使用ets:match
% %% XXX '$end_of_table'
% %% @doc 得到一个排行的分页
% get_rank_page(YeShu, Name) ->
%     End = YeShu * 10,
%     Begin = End - 9,
%     {_Size, _List} = case lookup_data_by_name(Name) of
%                          [] ->
%                              {1, []};
%                          R ->
%                              Size = length(R),
%                              if
%                                  Size < 10 ->
%                                      {1, R};
%                                  true ->
%                                      List = lists:sublist(R, Begin, End),
%                                      {page(Size), List}
%                              end
%                      end.


% get_rank_page(Star, Len, Name) ->
%     {_Size, _List} = case lookup_data_by_name(Name) of
%                          [] ->
%                              {0, []};
%                          R ->
%                              Size = length(R),
%                              {Size, lists:sublist(R, Star, Len)}
%                      end.
% get_rank_page(Star, Len, Name, MaxLen) ->
%     {_Size, _List} = case lookup_data_by_name(Name) of
%                          [] ->
%                              {0, []};
%                          R ->
%                              NR = lists:sublist(R, MaxLen),
%                              Size = length(NR),
%                              {Size, lists:sublist(NR, Star, Len)}
%                      end.


% get_rank_order_page(Star, Len, Name) ->
%     {_Size, _NStar, _List} = case lookup_data_by_name(Name) of
%                                  [] ->
%                                      {0, 0, []};
%                                  R ->
%                                      Size = length(R),
%                                      NStar = min(Star, Size),
%                                      {Size, NStar, lists:sublist(R, NStar, Len)}
%                              end.
% get_rank_order_page(Star, Len, Name, MaxLen) ->
%     {_Size, _NStar, _List} = case lookup_data_by_name(Name) of
%                                  [] ->
%                                      {0, 0, []};
%                                  R ->
%                                      NR = lists:sublist(R, MaxLen),
%                                      Size = length(NR),
%                                      NStar = min(Star, Size),
%                                      {Size, NStar, lists:sublist(NR, NStar, Len)}
%                              end.

% page(Size) ->
%     case {Size div 10, Size rem 10} of
%         {N, 0} -> N;
%         {N, _} -> N + 1
%     end.

% %% 获取单个排行榜的第一名
% get_top1_by_name(RankName) ->
%     case lookup_data_by_name(RankName) of
%         [] ->
%             0;
%         R ->
%             {PlayerId, _} = lists:last(R),
%             PlayerId
%     end.

% get_len_by_name(RankName) ->
%     case lookup_data_by_name(RankName) of
%         [] -> 0;
%         R -> erlang:length(R)
%     end.




% show(RankName) ->
%     case lookup_data_by_name(RankName) of
%         [] ->
%             0;
%         R ->
%             lists:foreach(
%                 fun
%                     ({PlayerID,_}) ->
%                         [Name] = player:lookup_info(PlayerID, [?pd_name]),
%                         ?INFO_LOG("rank ~ts ~p",[Name, PlayerID])
%                 end,
%                 R)
%     end.



% get_nth(_PlayeID, [], _Order) -> 0;
% get_nth(PlayerID, [{ID, _}|TailList], Order) ->
%     case ID of
%         PlayerID -> Order;
%         _ -> get_nth(PlayerID, TailList, Order+1)
%     end.
% get_order_by_player(RankName, PlayerID) ->
%     case lookup_data_by_name(RankName) of
%         [] -> 0;
%         R -> get_nth(PlayerID, R, 1)
%     end.
% get_player_by_order(RankName, Rank) ->
%     case lookup_data_by_name(RankName) of
%         [] -> 0;
%         R ->
% %%             ?INFO_LOG("get_player_by_order ~p",[R]),
%             case util:nth(Rank, R) of
%                 none -> 0;
%                 {PlayerId, _} -> PlayerId
%             end
%     end.

% %% 查询对应的排名数据
% lookup_data_by_name(Name) ->
%     case dbcache:lookup(?ranking_tab, Name) of
%         [] ->
%             [];
%         [R] ->
%             R#ranking_tab.ranking
%     end.


% start_flush_rank_tiemr(Name) ->
%     ?send_after_self(1000 * (?SECONDS_PER_MINUTE * ?RANKING_INTERVAL_MINUTE + ?random(30)),
%         {?flush_rank, Name}).


% %%=======================================================================
% %% Internal functions
% %%=======================================================================



% flush_rank(RankName) ->
%     % 前提: ets中所有的obj在进程字典中都存在
%     #rank_info{max_size = MaxSize} = erlang:get(?pd_ranking(RankName)),
%     Tree = erlang:get(?pd_ranking_tree(RankName)),
%     Size = gb_trees:size(Tree),
%     SortTupleList =
%         lists:sort
%         (
%             fun
%                 ({_A1, A1}, {_A2, A2}) -> A1 >= A2
%             end,
%             gb_trees:to_list(Tree)
%         ),
%     {NewRank, Rest} =
%         if Size > MaxSize ->
%             lists:split(MaxSize, SortTupleList);
%             true -> {SortTupleList, []}
%         end,
%     flush_ets(RankName, NewRank),
%     NewTree =
%         lists:foldl(fun({Key, _}, Acc) -> gb_trees:delete(Key, Acc) end,
%             Tree,
%             Rest),
%     erlang:put(?pd_ranking_tree(RankName), NewTree),
% %%     ?INFO_LOG("flush_rank ~p",[{RankName, NewTree}]),
%     start_flush_rank_tiemr(RankName),
%     ok.

% %% RankList [{playerId, SortValue}]
% flush_ets(RankName, RankList) ->
%     if
%         RankList =:= [] ->
%             pass;
%         true ->
%             case dbcache:lookup(?ranking_tab, RankName) of
%                 [] ->
%                     NewR = #ranking_tab{name = RankName, ranking = RankList},
%                     dbcache:update(?ranking_tab, NewR);
%                 [R] ->
%                     NewR = R#ranking_tab{ranking = RankList},
%                     dbcache:update(?ranking_tab, NewR)
%             end,
%             MapName = get_map_name(RankName),
%             {_, MapRank} = lists:foldl
%             (
%                 fun
%                     ({PlayerId, Value}, {Order, Acc}) ->
%                         {
%                             Order + 1,
%                             [{PlayerId, Order, Value} | Acc]
%                         }
%                 end,
%                 {1, []},
%                 RankList
%             ),
%             ets:delete_all_objects(MapName),
%             ?true = ets:insert_new(MapName, MapRank)  %% 這個表中的數據格式{PlayerId, Rank}
%     end,
%     ok.


% get_map_name(Name) ->
%     com_util:atom_concat([Name, '_map']).

% %%
% %% -define(pd_ranking(Name), {pd_ranking, Name}).
% %% -define(pd_ranking_tree(Name), {pd_ranking_tree, Name}).
% init_rank(#rank_info{name = Name} = Info) ->
%     %% row {PlayerId, SortValue }
% %%     Name= ets:new(Name, [named_table,
% %%                          bag,
% %%                          ?protected,
% %%                          {?keypos, 2}, %% sort with value
% %%                          {?read_concurrency, true}]),      %%等级排行
%     MapName = get_map_name(Name),
%     %% row {PlayerId, SortValue }
%     MapName = ets:new(MapName,
%         [named_table,
%             ?protected,
%             {?read_concurrency, true}]),      %% 反向映射排行

%     %% insert rank data
%     ?pd_new(?pd_ranking(Name), Info),
%     case dbcache:lookup(?ranking_tab, Name) of
%         [] ->
%             ?pd_new(?pd_ranking_tree(Name), gb_trees:empty());
%         [#ranking_tab{ranking = Ranking}] ->
% %%             ?INFO_LOG("Ranking------------------~p",[{Name, Ranking}]),
%             ?pd_new(?pd_ranking_tree(Name), gb_trees:from_orddict(orddict:from_list(Ranking))),
%             flush_ets(Name, Ranking)
%     end,

%     start_flush_rank_tiemr(Name),
%     ok.

% reset_rank(RankName, MaxSize, Ranking) ->
%     erlang:put(?pd_ranking(RankName), #rank_info{name = RankName, max_size = MaxSize, size = 0}),
%     erlang:put(?pd_ranking_tree(RankName), gb_trees:from_orddict(orddict:from_list(Ranking))),
%     flush_ets(RankName, Ranking).

