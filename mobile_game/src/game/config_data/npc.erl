-module(npc).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("npc_struct.hrl").

-export([
    get_npc_data_by_sceneid/2,
    get_npc_can_challenge/1
]).


get_npc_data_by_sceneid(SceneId, FlushNum) ->
    %?DEBUG_LOG("SceneId-------------------------------:~p",[SceneId]),
    case lookup_guaiwu_gc_npc_cfg(SceneId) of
        ?none ->
            [];
        #guaiwu_gc_npc_cfg{num={0, _List}} ->
            [];
        #guaiwu_gc_npc_cfg{num={TotalNum, List}, coordinate_m=L1, coordinate_b=L2, npc_list=NpcList, boss_list=BossList} ->
            case lists:keyfind(FlushNum, 1, List) of
                ?false ->
                    %?DEBUG_LOG("1--------------------------------------"),
                    get_small_npc(L1, TotalNum, NpcList);
                {_, BossNum} ->
                    %?DEBUG_LOG("2--------------------------------------"),
                    {NextL1, BossNpcList} = get_boss_npc_p(L1, L2, BossNum, BossList),
                    %?DEBUG_LOG("NextL1------------------------:~p",[NextL1]),
                    %?DEBUG_LOG("BossNpcList---------------------:~p",[BossNpcList]),
                    SmallNpcList = get_small_npc(NextL1, TotalNum-BossNum, NpcList),
                    %?DEBUG_LOG("SmallNpcList------------------------:~p",[SmallNpcList]),
                    BossNpcList ++ SmallNpcList
            end
    end. 

get_small_npc(L1, TotalNum, NpcList) ->
    %?DEBUG_LOG("L1-------------------------:~p",[L1]),
    %?DEBUG_LOG("NpcList--------------------:~p----NpcListSize-----:~p",[NpcList, length(NpcList)]),
    List1 = util:get_val_by_weight(L1, TotalNum),
    % ?DEBUG_LOG("List1------------------------:~p",[List1]),
    Size = length(List1),
    %?DEBUG_LOG("Size---------------------:~p",[Size]),
    List2 = util:get_val_by_weight(NpcList, Size),
    % ?DEBUG_LOG("List2------------------------:~p",[List2]),
    merge_list(List2, List1).

get_boss_npc_p(L1, L2, TotalNum, BossList) ->
    %?DEBUG_LOG("L1----:~p",[L1]),
    %?DEBUG_LOG("L2------------:~p",[L2]),
    BossPList = util:get_val_by_weight(L2, TotalNum),
    %?DEBUG_LOG("BossPList--------------------:~p",[BossPList]),
    BossSize = length(BossPList),
    BossNList = util:get_val_by_weight(BossList, BossSize),
    %?DEBUG_LOG("BossNList------------------------:~p",[BossNList]),
    FinalList = merge_list(BossNList, BossPList),
    %?DEBUG_LOG("FinalList---------------------------------:~p",[FinalList]),
    {un_merge_p(BossPList, L1), FinalList}.

un_merge_p([], List) ->
    List;
un_merge_p([P|T], List) ->
    un_merge_p(T, lists:keydelete(P, 1, List)).


% get_gwgc_samll_npc_all_data(SceneId) ->
%     L1 = get_gwgc_small_npc_list(SceneId),
%     L2 = get_gwgc_small_coordinate_list(SceneId),
%     FinalList = merge_list(L1, L2),
%     ?DEBUG_LOG("FaialList------------------:~p",[FinalList]),
%     FinalList.

% get_gwgc_small_coordinate_list(SceneId) ->
%     case lookup_guaiwu_gc_npc_cfg(SceneId) of
%         ?none ->
%             [];
%         #guaiwu_gc_npc_cfg{coordinate_m=List} ->
%             L = util:get_val_by_weight(List, 2),
%             ?DEBUG_LOG("L-------------------------:~p",[L]),
%             L
%     end.

% get_gwgc_small_npc_list(SceneId) ->
%     case lookup_guaiwu_gc_npc_cfg(SceneId) of
%         ?none ->
%             [];
%         #guaiwu_gc_npc_cfg{npc_list=List} ->
%             L = util:get_val_by_weight(List, 2),
%             ?DEBUG_LOG("L-------------------------:~p",[L]),
%             L
%     end.

merge_list(L1, L2) ->
    merge_list_(L1, L2, []).
merge_list_([],_, List) ->
    List;
merge_list_(_,[],List) ->
    List;
merge_list_([], [], List) ->
    List;
merge_list_([H1|T1], [{X, Y}|T2], List) ->
    merge_list_(T1, T2, [{H1, X, Y, 0}|List]).


get_npc_can_challenge(NpcId) ->
    case lookup_npc_cfg(NpcId) of
        #npc_cfg{can_challenge=Cc} when Cc > 0 ->
            Cc;
        ?none ->
            ?false
    end.




load_config_meta() ->
    [
        #config_meta
        {
            record = #npc_cfg{},
            fields = ?record_fields(npc_cfg),
            file = "npc.txt",
            keypos = #npc_cfg.id,
            verify = fun verify/1
        },

        #config_meta
        {
            record = #guaiwu_gc_npc_cfg{},
            fields = ?record_fields(guaiwu_gc_npc_cfg),
            file = "guaiwu_gc_npc.txt",
            keypos = #guaiwu_gc_npc_cfg.id,
            verify = fun verify_guaiwu_gc_npc/1
        }
    ].

verify(#npc_cfg{id = _Id, scene_id = undefined, x = undefined, y = undefined}) ->
    pass;
verify(#npc_cfg{id = Id, scene_id = SID, x = X, y = Y}) ->
    ?check(erlang:is_integer(Id), "npc [~p] id 不是数字! ", [Id]),
    ?check(load_cfg_scene:is_exist_scene_cfg(SID), "npc [~p] scene_id 没有找到", [SID]),
    MapId = load_cfg_scene:get_map_id(SID),
    ?check(scene_map:map_is_walkable(MapId, X, Y), "npc [~p] x, y 不是可行走点", [{X, Y}]),
    ok;

verify(_R) ->
    ?ERROR_LOG("npc ~p 无效格式", [_R]),
    exit(bad).
    
verify_guaiwu_gc_npc(G) ->
    ok.