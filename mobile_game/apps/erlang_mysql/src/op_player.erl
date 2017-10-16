-module(op_player).

-include("include/common.hrl").

-export
([
    create_account/0,
    create_player_to_mysql/3,
    get_create_player_count/2,
    get_re_account_count/2,
    save_player_and_account_num/0
    %get_count/2
    %role_money_change/3,
    %role_exp_change/2,
    %role_level_change/2,
    %role_vip_level_change/2,
    %role_family_change/2,
    %role_curmap_change/2,
    %role_combat_power_change/2,
    %role_kill_man_num_change/2,
    %role_kill_monster_num_change/2,
    %role_name_check/1,
    %role_consume_money/4,
    %get_password/0
]).    

-export
([
    %is_player_id/1,
    create_account_to_mysql/3,
    %save_freeze_player/6,
    %delete_freeze_player/3,
    %save_gag_player/6,
    %delete_gag_player/3,
    %save_internal_player/5,
    %delete_internal_player/3,
    %save_system_broadcast/9,
    is_freeze_player/1,
    is_jinyan_player/1,
    is_neibuzhanghao_player/1,
    save_game_server_node/0,
    %save_online_player_count/3,
    %save_online_account_count/3,
    save_online_player_and_account_count/0,
    save_total_pay/3,
    %save_create_player_count/2,
    %save_re_account_count/2,
    save_houtai_goods/0,
    %can_login/2,
    %create_account_more/3,
    %get_player_id_by_account_name/1,
    %create_account/0,
    clear_online_player/2,
    update_player_data/8,
    update_account/2,
    create_new_cd_key_to_mysql/7,
    get_cd_key_prize/2,
    create_new_cd_key_to_mysql/8
]).

-define(RE_COUNT, 1100).

init_online_player(Id) ->
    db_mysql:insert(?DB_POOL, online_player, [id],[Id]).

init_server_data(Id, PlatFormId, ServerId) ->
    db_mysql:insert(?DB_POOL, server_data, [id, platform_id, server_id, create_player_count, re_account_count], 
        [Id,PlatFormId,ServerId, ?RE_COUNT, 0]).


save_houtai_goods() ->
    init_gm_data().

    

save_game_server_node() ->
    %Node = node(),
    %io:format("op_player node ---------------:~p~n",[Node]),
    %#{platform_id := PlatFormId, id := ServerId} =global_data:get_server_info(),
    #{platform_id := PlatFormId, id := ServerId, ip := IP, port := Port, gmport := GmControllerPort} =global_data:get_server_info(),
    io:format("op_player save_game_server_node platform_id, server_id----------------:~p~n",[{PlatFormId, ServerId}]),
    Id = tool:pin_id(PlatFormId, ServerId),
    case db_mysql:select_row(?DB_POOL, game_server_nodes, "id", [{id,Id}]) of
        [] ->
            Fun = fun() ->
                insert_game_server_node_to_mysql(Id, PlatFormId, ServerId, IP, Port, GmControllerPort)
            end,
            case mysql:transaction(?DB_POOL, Fun) of
                {atomic, _} ->
                    %create_account(),
                    init_online_player(Id),
                    %init_server_data(Id, PlatFormId, ServerId), %% todo
                    {true,ok};
                _E ->
                    {false,ok}
            end;
        _PlayerInfor ->
            init_online_player(Id),
            pass
    end.

get_create_player_count(PlatFormId, ServerId) ->
    Id = tool:pin_id(PlatFormId, ServerId),
    case db_mysql:select_row(server_data, "create_player_count", [{id, Id}]) of
        [] ->
            0;
        [Count] ->
            Count
    end.

get_re_account_count(PlatFormId, ServerId) ->
    Id = tool:pin_id(PlatFormId, ServerId),
    case db_mysql:select_row(server_data, "re_account_count", [{id, Id}]) of
        [] ->
            0;
        [Count] ->
            Count
    end.

get_cd_key_prize(CdKey,CdKeyTypeList) ->
    case db_mysql:select_row(?DB_POOL, cd_keys, "cd_key, type, prize_id, use_times", [{cd_key, CdKey}]) of
        [] ->
            {error, no_found};
        [CdKey, Type, PrizeId, UseTimes] ->
            if
                UseTimes =:= -1 ->
                    case lists:member(Type, CdKeyTypeList) of
                        false ->
                            {ok,PrizeId,Type};
                        _ ->
                            {error, already_type}
                    end;
                UseTimes > 0->
                    case lists:member(Type, CdKeyTypeList) of
                        false ->
                            db_mysql:update(?DB_POOL, cd_keys, [use_times], [UseTimes -1 ],[{cd_key, CdKey}]),
                            {ok,PrizeId,Type};
                        _ ->
                            {error, already_type}
                    end;
                true ->
                    {error, no_times}
            end
    end.

% is_player_id(PlayerId) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             ?false;
%         _PlayerInfor ->
%             ?true
%     end.

is_freeze_player(PlayerId) ->
    case db_mysql:select_row(?DB_POOL, player_freeze, "id", [{id, PlayerId}]) of
        [] ->
            ?false;
        _PlayerInfor ->
            ?true
    end.

is_jinyan_player(PlayerId) ->
    %io:format("data---------------------:~p~n",[{PlayerId, PlatFormId, WorldId}]),
    case db_mysql:select_row(?DB_POOL, player_jinyan, "id", [{id, PlayerId}]) of
        [] ->
            %io:format("80 is not jinyan palyer---------------------------~n"),
            ?false;
        _PlayerInfor ->
            %io:format("80 is not jinyan _PlayerInfor---------------------------:~p~n",[_PlayerInfor]),
            ?true
    end.

is_neibuzhanghao_player(PlayerId) ->
    case db_mysql:select_row(?DB_POOL, player_neibuzhanghao, "id", [{id, PlayerId}]) of
        [] ->
            ?false;
        _PlayerInfor ->
            ?true
    end.

create_account_to_mysql(AccountName, PassWolrd, PlatFormId) ->
    CreateTime = tool:get_unix_time(),
    %io:format("create_account_to_mysql-----------------------~n"),
    %PlayerList = [{AccountName, PlayerId}],
    %B = tool:term_to_bitstring(PlayerList),
    %io:format("B------------------------:~p~n",[B]),
    Fun = fun() ->
        create_new_account(AccountName, PassWolrd, CreateTime, PlatFormId)
    end,
    case mysql:transaction(?DB_POOL, Fun) of
        {atomic, _} ->
            {true,ok};
        _E ->
            {false,ok}
    end.


update_account(List, AccountName) ->
    B = tool:term_to_bitstring(List),
    db_mysql:update(?DB_POOL, account, 
    [player_id], 
    [B], account_name, AccountName).




create_player_to_mysql(PlayerId, Name, Job) ->
    CreateTime=tool:get_unix_time(),
    #{platform_id := PlatFormId, id := ServerId} =global_data:get_server_info(),
    io:format("create_player_to_mysql---------------------:~p~n",[PlayerId]),
    % case db_mysql:select_row(?DB_POOL, player, "level", [{player_id, PlayerId},{platform_id, PlatFormId},{server_id, ServerId}]) of
    %     [] ->
            Fun = fun() ->
                create_new_infor(PlayerId,Name, Job, CreateTime, PlatFormId, ServerId)
            end,
            case mysql:transaction(?DB_POOL, Fun) of
                {atomic, _} ->
                    {true,ok};
                _E ->
                    {false,ok}
            end.
    %     PlayerInfor ->
    %         {true,PlayerInfor}
    % end.

% save_freeze_player(PlayerId, HowLong, MiaoShu, MakeName,PlatFormId, WorldId) ->
%     CreateTime=tool:get_unix_time(),
%     case db_mysql:select_row(?DB_POOL, player_freeze, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             Fun = fun() ->
%                 save_freeze_player(PlayerId, HowLong, MiaoShu, MakeName, CreateTime,PlatFormId, WorldId)
%             end,
%             case mysql:transaction(?DB_POOL, Fun) of
%                 {atomic, _} ->
%                     true;
%                 _E ->
%                     false
%             end;
%         _PlayerInfor ->
%             true
%     end.

% delete_freeze_player(PlayerId,PlatFormId, WorldId) ->
%     db_mysql:delete(?DB_POOL, player_freeze, [{player_id, PlayerId},{platform_id, PlatFormId},{server_id, WorldId}]),
%     true.

% save_gag_player(PlayerId, HowLong, MiaoShu, MakeName,PlatFormId, WorldId) ->
%     CreateTime=tool:get_unix_time(),
%     case db_mysql:select_row(?DB_POOL, player_jinyan, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             Fun = fun() ->
%                 insert_gag_player(PlayerId, HowLong, MiaoShu, MakeName, CreateTime,PlatFormId, WorldId)
%             end,
%             case mysql:transaction(?DB_POOL, Fun) of
%                 {atomic, _} ->
%                     true;
%                 _E ->
%                     false
%             end;
%         _PlayerInfor ->
%             true
%     end.

% delete_gag_player(PlayerId,PlatFormId, WorldId) ->
%     db_mysql:delete(?DB_POOL, player_jinyan, [{player_id, PlayerId},{platform_id, PlatFormId},{server_id, WorldId}]),
%     true.    

% save_internal_player(PlayerId, MiaoShu, MakeName, PlatFormId, WorldId) ->
%     CreateTime=tool:get_unix_time(),
%     case db_mysql:select_row(?DB_POOL, player_neibuzhanghao, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             Fun = fun() ->
%                 insert_internal_player(PlayerId, MiaoShu, MakeName, CreateTime, PlatFormId, WorldId)
%             end,
%             case mysql:transaction(?DB_POOL, Fun) of
%                 {atomic, _} ->
%                     true;
%                 _E ->
%                     false
%             end;
%         _PlayerInfor ->
%             true
%     end.

% delete_internal_player(PlayerId, PlatFormId, WorldId) ->
%     db_mysql:delete(?DB_POOL, player_neibuzhanghao, [{player_id, PlayerId},{platform_id, PlatFormId},{server_id, WorldId}]),
%     true.    

% save_system_broadcast(Xuhao, StartTime, EntTime, IntervalTime, Type, Title, Content, PlatFormId, WorldId) ->
%     case db_mysql:select_row(?DB_POOL, system_broadcast, "xuhao", [{xuhao, Xuhao}]) of
%         [] ->
%             Fun = fun() ->
%                 insert_system_broadcast(Xuhao, StartTime, EntTime, IntervalTime, Type, Title, Content,PlatFormId, WorldId)
%             end,
%             case mysql:transaction(?DB_POOL, Fun) of
%                 {atomic, _} ->
%                     true;
%                 _E ->
%                     false
%             end;
%         _PlayerInfor ->
%             db_mysql:update(?DB_POOL, system_broadcast, [xuhao,start_time,end_time,interval_time,type,title,content], 
%                                                         [Xuhao, StartTime, EntTime, IntervalTime, Type, Title, Content], xuhao, Xuhao),
%             true
%     end.

% get_count(IsAdd, Count) ->
%     if
%         IsAdd =:= 1 ->
%             Count + 1;
%         IsAdd =:= 0 ->
%             erlang:max(0, Count -1)
%     end.




% save_online_player_count(PlatFormId, WorldId, IsAdd) ->
%     io:format("online_player count--------------------:~p~n",[db_mysql:select_row(online_player, "player_count", [{platform_id, PlatFormId}, {server_id, WorldId}])]),
%     case db_mysql:select_row(online_player, "player_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             db_mysql:insert(?DB_POOL, online_player, [platform_id, server_id, player_count], [PlatFormId,WorldId, get_count(IsAdd, 0)]);
%         [Count] ->
%             db_mysql:update(?DB_POOL, online_player, [player_count], [get_count(IsAdd, Count)], [{platform_id, PlatFormId}, {server_id, WorldId}])
%     end.
% save_online_account_count(PlatFormId, WorldId, IsAdd) ->
%     case db_mysql:select_row(online_player, "account_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             db_mysql:insert(?DB_POOL, online_player, [platform_id, server_id, account_count], [PlatFormId,WorldId, get_count(IsAdd, 0)]);
%         [Count] ->
%             db_mysql:update(?DB_POOL, online_player, [account_count], [get_count(IsAdd, Count)], [{platform_id, PlatFormId}, {server_id, WorldId}])
%     end.

save_online_player_and_account_count() ->
    #{platform_id := PlatFormId, id := ServerId} =global_data:get_server_info(),
    Id = tool:pin_id(PlatFormId, ServerId),
    %OnlineCount = global_data:get_online_count(),
    OnlineCount = ets:info(world, size),
    if
        OnlineCount >= 0 ->
            db_mysql:update(?DB_POOL, online_player, [player_count, account_count],
                         [OnlineCount,OnlineCount], [{id, Id}]);
        true ->
            pass
    end.


save_total_pay(PlatFormId, WorldId, Num) ->
    Id = tool:pin_id(PlatFormId, WorldId),
    case db_mysql:select_row(pay_player, "chongzhi_count", [{id, Id}]) of
        [] ->
            db_mysql:insert(?DB_POOL, pay_player, [id, platform_id, server_id, chongzhi_count], [Id, PlatFormId,WorldId, Num]);
        [Count] ->
            db_mysql:update(?DB_POOL, pay_player, [chongzhi_count], [Count + 1], [{id, Id}])
    end.

% save_create_player_count(PlatFormId, WorldId) ->
%     Id = tool:pin_id(PlatFormId, WorldId),
    % case db_mysql:select_row(server_data, "create_player_count", [{id, Id}]) of
    %     [] ->
    %         Fun = fun() ->
    %             db_mysql:insert(?DB_POOL, server_data, [id,platform_id, server_id, create_player_count], [Id,PlatFormId,WorldId, 1])
    %         end,
    %         case mysql:transaction(?DB_POOL, Fun) of
    %             {atomic, _} ->
    %                 true;
    %             _E ->
    %                 false
    %         end;
    %     [Count] ->
    %         db_mysql:update(?DB_POOL, server_data, [create_player_count], [Count + 1], [{id, Id}])
    % end.


% save_re_account_count(PlatFormId, WorldId) ->
%     Id = tool:pin_id(PlatFormId, WorldId),
    % case db_mysql:select_row(server_data, "re_account_count", [{id, Id}]) of
    %     [] ->
    %         Fun = fun() ->
    %             db_mysql:insert(?DB_POOL, server_data, [id,platform_id, server_id, re_account_count], [Id,PlatFormId,WorldId, 1])
    %         end,
    %         case mysql:transaction(?DB_POOL, Fun) of
    %             {atomic, _} ->
    %                 true;
    %             _E ->
    %                 false
    %         end;
    %     [Count] ->
    %         db_mysql:update(?DB_POOL, server_data, [re_account_count], [Count + 1], [{id, Id}])
    % end.


save_player_and_account_num() ->
    #{platform_id := PlatFormId, id := ServerId} =global_data:get_server_info(),
    Id = tool:pin_id(PlatFormId, ServerId),
    PlayerCount = global_data:get_player_count(),
    AccountCount = global_data:get_account_count(),
    %io:format("op_player 386----------PlayerCount-:~p~n",[PlayerCount]),
    %io:format("op_player 387----------AccountCount-:~p~n",[AccountCount]),
    if
        PlayerCount > 0, AccountCount > 0 ->
            db_mysql:update(?DB_POOL, server_data, [re_account_count, create_player_count], 
            [AccountCount, PlayerCount], [{id, Id}]);
        true ->
            pass
    end.


create_new_account(AccountName, PassWolrd, CreateTime, PlatFormId) ->
    db_mysql:insert(?DB_POOL, account, [platform_id, password, account_name, real_time], 
                                    [PlatFormId, PassWolrd,AccountName,CreateTime]).


%创建一个新玩家
create_new_infor(PlayerId,Name, Job, CreateTime, PlatFormId, ServerId) ->
    %db_mysql:insert(?DB_POOL, player, [id,server_id,name,job,create_time, platform_id], 
    %                                  [PlayerId,ServerId,Name,Job,CreateTime, PlatFormId]).
    db_mysql:replace(?DB_POOL, player, [id,server_id,name,job,create_time, platform_id], 
                                     [PlayerId,ServerId,Name,Job,CreateTime, PlatFormId]).

% save_freeze_player(PlayerId, FreezeTime, MiaoShu, MakeName, MakeTime,PlatFormId, WorldId) ->
%     db_mysql:insert(?DB_POOL, player_freeze, [player_id,time,info,name,make_time,platform_id,server_id], 
%                                              [PlayerId,FreezeTime,MiaoShu,MakeName, MakeTime,PlatFormId,WorldId]).

% insert_gag_player(PlayerId, FreezeTime, MiaoShu, MakeName, MakeTime, PlatFormId, WorldId) ->
%     db_mysql:insert(?DB_POOL, player_jinyan, [player_id,time,info,name,make_time,platform_id,server_id], 
%                                              [PlayerId,FreezeTime,MiaoShu,MakeName, MakeTime,PlatFormId, WorldId]).

% insert_internal_player(PlayerId, MiaoShu, MakeName, MakeTime, PlatFormId, WorldId) ->
%     db_mysql:insert(?DB_POOL, player_neibuzhanghao, [player_id,info,name,make_time,platform_id,server_id], 
%                                                     [PlayerId,MiaoShu,MakeName, MakeTime,PlatFormId, WorldId]).

% insert_system_broadcast(Xuhao, StartTime, EntTime, IntervalTime, Type, Title, Content, PlatFormId, WorldId) ->
%     db_mysql:insert(?DB_POOL, system_broadcast, [xuhao,start_time,end_time,interval_time,type,title,content,platform_id, server_id], 
%                                                 [Xuhao, StartTime, EntTime, IntervalTime, Type, Title, Content,PlatFormId,WorldId]).

insert_game_server_node_to_mysql(Id, PlatFormId, ServerId, IP, Port, GmControllerPort) ->
    Node = node(),
    StartServerTime = tool:get_unix_time(),
    {Pn, Sn} = load_server_info:get_fs_name_by_id(PlatFormId, ServerId),
    %io:format("StartServerTime-------------------:~p~n",[{StartServerTime, IP, Port}]),
    %io:format("Pn,Sn----------------------:~p~n",[{Pn, Sn}]),
    %io:format("GmControllerPort----------------------:~p~n",[GmControllerPort]),
    db_mysql:insert(?DB_POOL, game_server_nodes, [id, platform_id, platform_name, server_id, server_name, node,ip, game_prot, gm_prot, time],
                                                 [Id, PlatFormId, Pn, ServerId, Sn, Node, IP, Port, GmControllerPort, StartServerTime]).

insert_gm_data() ->
    db_mysql:execute_raw_sql("alter table gm_goods AUTO_INCREMENT=1"),
    List = ets:tab2list(offset_goods_cfg),
    %Size = length(List),
    %io:format("offset_goods_cfg----------------:~p~n",[Size]),
    lists:foreach(fun({_, Pl}) ->
            {ItemID, ItemName, ItemType} = load_offset_goods:get_offset(Pl),
            case ItemName of
                undefined ->
                    pass;
                _ ->
                    db_mysql:insert(?DB_POOL, gm_goods, [bid, name,type],[ItemID, binary_to_list(ItemName), ItemType])
            end
    end,
    List).


init_gm_data() ->
    List = ets:tab2list(offset_goods_cfg),
    %io:format("init gm data List-----------:~p~n",[List]),
    OldSize = 
    case db_mysql:select_count(?DB_POOL, gm_goods, []) of
        [] ->
            0;
        [C] ->
            C
    end,
    %io:format("init gm data OldSize------:~p~n",[OldSize]),
    NewListSize = length(List),
    io:format("init gm data is not ==--------:~p~n",[{NewListSize,OldSize}]),
    if
        OldSize =/= NewListSize ->
            db_mysql:delete(?DB_POOL, gm_goods, []),
            insert_gm_data();
        OldSize =:= 0 ->
            init_gm_data();
        true ->
            %io:format("init_gm_data ---------pass----~n"),
            pass
    end.
    %lists:foreach(fun({_, Pl}) ->
    %        {ItemID, ItemName, ItemType} = load_offset_goods:get_offset(Pl),
    %        db_mysql:replace(?DB_POOL, gm_goods, [bid, name,type],[ItemID, binary_to_list(ItemName), ItemType])
    %end,
    %List).

% role_money_change(PlayerId, NewValue, Type) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false,ok};
%         PlayerInfor ->
%             change_player_money(PlayerId, NewValue, Type),
%             {true, PlayerInfor}
%     end.

% role_exp_change(PlayerId, NewValue) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false,ok};
%         PlayerInfor ->
%             change_player_exp(PlayerId,NewValue),
%             {true,PlayerInfor}
%     end.


% role_level_change(PlayerId, NewValue) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false, ok};
%         PlayerInfor ->
%             change_player_level(PlayerId, NewValue),
%             {true, PlayerInfor}
%     end.

% role_vip_level_change(PlayerId, NewValue) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false, ok};
%         PlayerInfor ->
%             change_player_vip_level(PlayerId, NewValue),
%             {true, PlayerInfor}
%     end.

% role_family_change(PlayerId, NewFamilyId) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false, ok};
%         PlayerInfor ->
%             change_player_familyid(PlayerId, NewFamilyId),
%             {true, PlayerInfor}
%     end.

% role_curmap_change(PlayerId, NewMapId) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false, ok};
%         PlayerInfor ->
%             change_player_curmapid(PlayerId, NewMapId),
%             {true, PlayerInfor}
%     end.

% role_combat_power_change(PlayerId, NewPower) ->
%     case db_mysql:select_row(?DB_POOL, player, "player_id", [{player_id, PlayerId}]) of
%         [] ->
%             {false, ok};
%         PlayerInfor ->
%             change_player_combat_power(PlayerId, NewPower),
%             {true, PlayerInfor}
%     end.

% role_kill_man_num_change(PlayerId, AddNum) ->
%     case get_killman_num_info(PlayerId) of
%         null ->
%             {false, ok};
%         KillManNum ->
%             change_player_killman_num(PlayerId, KillManNum + AddNum)
%     end.

% role_kill_monster_num_change(PlayerId, AddNum) ->
%     case get_killmonster_num_info(PlayerId) of
%         null ->
%             {false,ok};
%         KillMonsterNum ->
%             change_player_killmonster_num(PlayerId, KillMonsterNum + AddNum)
%     end.

% handle(?CHECK_NAME, _, [Name]) ->
% role_name_check(Name) ->
%     is_exist_same_name_player(Name).


update_player_data(PlayerId, Name, Exp, Level, VipLevel, CombPower, JinBi, ZuanShi) ->
    %io:format("update_player_data--------------------------:~p~n",[PlayerId]),
    db_mysql:update(?DB_POOL, player, 
    [name, cur_exp, level, vip_level, comb_power, jinbi_num, zuanshi_num], 
    [Name,
    tool:check_data(Exp, 0),
    tool:check_data(Level, 1),
    tool:check_data(VipLevel, 0),
    tool:check_data(CombPower, 0),
    tool:check_data(JinBi, 0),
    tool:check_data(ZuanShi, 0)], id, PlayerId).


% change_player_money(PlayerId, NewValue, Type) ->
%     case Type of
%         10 -> %% pd_money
%             db_mysql:update(?DB_POOL, player, [jinbi_num], [NewValue], player_id, PlayerId);
%         11 -> %% pd_diamond
%             db_mysql:update(?DB_POOL, player, [zuanshi_num], [NewValue], player_id, PlayerId);
%         _ ->
%             ?ERROR_LOG("~p unknown type money Type=~p",	[?MODULE,Type]),
%             ok
%     end.

% %重设玩家的经验 
% change_player_exp(PlayerId,NewValue) ->
%     db_mysql:update(?DB_POOL, player, [cur_exp], [NewValue], player_id, PlayerId).

% %重设玩家的等级
% change_player_level(PlayerId,NewValue) ->
%     db_mysql:update(?DB_POOL, player, [level], [NewValue], player_id, PlayerId).

% %重设玩家的vip等级
% change_player_vip_level(PlayerId, NewValue) ->
%     db_mysql:update(?DB_POOL, player, [vip_level], [NewValue], player_id, PlayerId).

% %重设玩家的家族id
% change_player_familyid(PlayerId, NewFamilyId) ->
%     db_mysql:update(?DB_POOL, player, [family_id], [NewFamilyId], player_id, PlayerId).

% %重设玩家所在地图id
% change_player_curmapid(PlayerId, NewMapId) ->
%     db_mysql:update(?DB_POOL, player, [curmap_id], [NewMapId], player_id, PlayerId).


% %重设玩家战力
% change_player_combat_power(PlayerId, NewPower) ->
%     db_mysql:update(?DB_POOL, player, [comb_power], [NewPower], player_id, PlayerId).

% %判断是不是存在相同名字
% is_exist_same_name_player(Name) ->
%     case db_mysql:get_all(?DB_POOL, "SELECT name FROM player WHERE name = "  ++ mysql:encode(Name)) of
%         [] ->
%             {true,ok};
%         _ ->
%             {false,ok}
%     end.

% %查询player表某个玩家的kill_man字段
% get_killman_num_info(PlayerId) ->
%     db_mysql:select_one(?DB_POOL, player, "kill_man", [{player_id, PlayerId}]).

% %查询player表某个玩家的kill_monster字段
% get_killmonster_num_info(PlayerId) ->
%     db_mysql:select_one(?DB_POOL, player, "kill_monster", [{player_id, PlayerId}]).

% %改变玩家的杀人数量
% change_player_killman_num(PlayerId, Value) ->
%     db_mysql:update(?DB_POOL, player, [kill_man], [Value], player_id, PlayerId).

% %改变玩家的杀怪数量
% change_player_killmonster_num(PlayerId,Value) ->
%     db_mysql:update(?DB_POOL, player, [kill_monster], [Value], player_id, PlayerId).

% %% todo 
% role_consume_money(PlayerId, Value, Type, _Log) ->
%     case Type of
%         10 ->
%             ok;
%         11 ->
%             ok;
%         12 ->
%             case db_mysql:select_one(?DB_POOL, player, "consume_ingot_count", [{player_id, PlayerId}]) of
%                 null ->
%                     ok;
%                 OldValue ->
%                     db_mysql:update(?DB_POOL, player, [consume_ingot_count], [Value + OldValue], player_id, PlayerId)
%             end;
%         _ ->
%             ?ERROR_LOG("~p unknown type money Type=~p",	[?MODULE,Type]),
%             ok
%     end.

% can_login(AccountName, PassWolrd) ->
%     case db_mysql:select_row(?DB_POOL, account, "password", [{account_name, AccountName}]) of
%         [] ->
%             false;
%         [Ps] ->
%             io:format("Ps----------------------------:~p~n",[Ps]),
%             Ps =:= PassWolrd
%         % Account ->
%         %     io:format("Account----------------------:~p~n",[Account]),
%         %     lists:nth(4, Account) =:= PassWolrd
%     end.

% create_account() ->
%     lists:foreach(fun(Name) ->
%         create_account_more(Name, 1, 100)
%     end,
%     ["mokylin", "santi", "test"]).


% create_account_more(Str, Star, End) ->
%     #{platform_id := PlatformId, id := ServerId} =global_data:get_server_info(),
%     erase(io_file),
%     FileName = Str ++ ".txt",
%     {ok, Io} = chinese_file:open_utf8_file(FileName),
%     put(io_file, Io),
%     do_create_account_more(PlatformId, ServerId, Str, lists:seq(Star, End)).

% do_create_account_more(_, _, _, []) ->
%     pass;
% do_create_account_more(PlatformId, ServerId, Str, [Num|T]) ->
%     %io:format("PlatformId------------------:~p~n",[{PlatformId, ServerId, Str, Num}]),
%     NewStr = lists:concat([Str, integer_to_list(Num)]),
%     Name = list_to_binary(NewStr),
%     put(pd_name, Name),
%     Role = get_role(),
%     put(pd_career, Role),
%     PlatformPlayerName = platfrom:get_user_key(PlatformId, ServerId, NewStr),
%     NewPlayerId = gen_id:next_id(player_tab),
%     PassWolrd = get_password(),
%     create_account_to_mysql(PlatformPlayerName,PassWolrd, PlatformId, NewPlayerId),
%     save_file_account(PlatformPlayerName, PassWolrd),
%     % case platfrom:register_name(NewPlayerId, Name) of
%     %     alreay_exist ->
%     %         pass;
%     %     ok ->
%     %         player_mods_manager:houtai_create_mods(NewPlayerId),
%     %         op_player:create_player_to_mysql(NewPlayerId, Name, Role),
%     %         op_player:save_create_player_count(PlatformId,ServerId)
%     % end,
%     do_create_account_more(PlatformId, ServerId, Str, T).


% get_role() ->
%     case random:uniform(4) of
%         3 ->
%             random:uniform(4);
%         R ->
%             R
%     end.

% get_player_id_by_account_name(AccountName) ->
%     io:format("get_player_id_by_account_name---------------------:~p~n",[AccountName]),
%     case db_mysql:select_row(?DB_POOL, account, "player_id", [{account_name, AccountName}]) of
%         [] ->
%             none;
%         [BitPlayerIdList] = P ->
%             io:format("P----------------------:~p~n",[P]),
%             io:format("BitPlayerIdList----------------:~p~n",[BitPlayerIdList]),
%             {ok, PlayerIdList} = tool:bitstring_to_term(BitPlayerIdList),
%             io:format("PlayerIdList-------------------:~p~n",[PlayerIdList]),
%             case lists:keyfind(AccountName, 1, PlayerIdList) of
%                 false ->
%                     none;
%                 {_, PlayerId} ->
%                     PlayerId
%             end
%     end.

save_file_account(NewStr, P) ->
    Io = get(io_file),
    chinese_file:write_list(Io, [NewStr, P]).

get_password() ->
    <<A4:24,_/binary>> = crypto:strong_rand_bytes(14),
    list_to_atom(integer_to_list(A4)).


clear_online_player(PlatFormId, ServerId) ->
    db_mysql:delete(?DB_POOL, online_player, [{platform_id, PlatFormId},{server_id, ServerId}]).




create_account() ->
    lists:foreach(fun(Name) ->
        create_account_more(Name, 1, ?RE_COUNT)
    end,
    ["t"]).


create_account_more(Str, Star, End) ->
    #{platform_id := PlatformId, id := ServerId} =global_data:get_server_info(),
    %erase(io_file),
    %FileName = Str ++ ".txt",
    %{ok, Io} = chinese_file:open_utf8_file(FileName),
    %put(io_file, Io),
    do_create_account_more(PlatformId, ServerId, Str, lists:seq(Star, End)).

do_create_account_more(_, _, _, []) ->
    pass;
do_create_account_more(PlatformId, ServerId, Str, [Num|T]) ->
    %io:format("PlatformId------------------:~p~n",[{PlatformId, ServerId, Str, Num}]),
    NewStr = lists:concat([Str, integer_to_list(Num)]),
    PlatformPlayerName = platfrom:get_user_key(PlatformId, ServerId, NewStr),
    NewPlayerId = tool:make_player_id(PlatformId, ServerId, gen_id:next_id(player_tab)),
    PassWolrd = get_password(),
    account:insert_account(PlatformPlayerName, NewPlayerId, PlatformId, PassWolrd),
    %save_file_account(PlatformPlayerName, PassWolrd),
    do_create_account_more(PlatformId, ServerId, Str, T).

get_role() ->
    case random:uniform(4) of
        3 ->
            random:uniform(4);
        R ->
            R
    end.

%% @Platfrom        cd-key的使用平台
%% @Server          cd-key的使用服务器
%% @Duration        cd-key的有效时间 单位多少天
%% @Sum             cd-key的数量
%% @PrizeId         cd-key对应的奖励Id
create_new_cd_key_to_mysql(_Platform,_Server,_Duration,_PrizeId,_UseTimes,_Type,Sum) when Sum =:= 0 ->
    ok;
create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes,Type,Sum) ->
    Key = cd_key:generate_cd_key(),
    CreateTime = util:get_now_second(0),
    DeadLine = CreateTime + Duration * 24 * 60 * 60,
    db_mysql:insert(?DB_POOL, cd_keys, [cd_key, platform_id, server_id, type, prize_id, use_times, create_time, deadline],
    [Key,Platform,Server, Type, PrizeId, UseTimes,CreateTime,DeadLine]),
    create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes,Type,Sum - 1).

create_new_cd_key_to_mysql(_Platform, _Server, _Duration, _PrizeId, _UseTimes, _Type,Sum, _X) when Sum =:= 0 ->
    ok;
create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes, Type,Sum, X) ->
    Key = cd_key:generate_cd_key(X),
    CreateTime = util:get_now_second(0),
    DeadLine = CreateTime + Duration * 24 * 60 * 60,
    db_mysql:insert(?DB_POOL, cd_keys, [cd_key, platform_id, server_id, type, prize_id, use_times, create_time, deadline],
        [Key,Platform,Server, Type, PrizeId, UseTimes,CreateTime,DeadLine]),
    create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes,Type,Sum - 1, X).

