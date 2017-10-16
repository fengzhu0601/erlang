%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 十二月 2015 上午10:07
%%%-------------------------------------------------------------------
-module(equip_buf).
-author("clark").

%% API
-export
([
    take_on_buf/1
    , take_off_buf/1
    , take_on_buf2/2
    , take_off_buf2/1
    , add_skill_modify_attr/1
    , remove_skill_modify_attr/1
    , add_task_bless_buff/1
]).

-include("player.hrl").
-include("inc.hrl").
-include("load_cfg_skill.hrl").
-include("load_cfg_buff.hrl").


take_on_buf(BufID) ->
%%    ?INFO_LOG("take_on_buf ~p", [BufID]),
    case load_cfg_skill:lookup_skill_modify_cfg(BufID) of
        ?none ->
            ?ERROR_LOG("take_on_buf ~p", [BufID]),
            ok;
        #skill_modify_cfg{svr_prop = SvrProp, svr_coef_prop = CoefSvrProp} ->
            %% 固定属性
            case SvrProp of
                0 ->
                    ok;
                undefined ->
                    ok;
                KeyValList ->
                    attr_new:player_add_attr(attr_new:list_2_attr(KeyValList)),
                    ok
            end,

            %% 千分比属性
            case CoefSvrProp of
                0 ->
                    ok;
                undefined ->
                    ok;
                KeyValList1 ->
                    attr_new:player_add_attr_pre(KeyValList1),
                    ok
            end,

            attr_new:update_player_attr(),
            ok
    end,
    ok.


take_off_buf(BufID) ->
    ?INFO_LOG("take_off_buf ~p", [BufID]),
    case load_cfg_skill:lookup_skill_modify_cfg(BufID) of
        ?none ->
            ?ERROR_LOG("take_on_buf ~p", [BufID]),
            ok;
        #skill_modify_cfg{svr_prop = SvrProp, svr_coef_prop = CoefSvrProp} ->
            case SvrProp of
                0 ->
                    ok;
                undefined ->
                    ok;
                KeyValList ->
                    attr_new:player_sub_attr(attr_new:list_2_attr(KeyValList)),
                    ok
            end,

            case CoefSvrProp of
                0 ->
                    ok;
                undefined ->
                    ok;
                KeyValList1 ->
                    attr_new:player_sub_attr_pre(KeyValList1),
                    ok
            end,

%%             attr_new:update_player_attr(),
            ok
    end,
    ok.

% 人物变身 根据buff表添加属性
take_on_buf2(BufID, EndTime) ->
    ?INFO_LOG("take_on_buf ~p", [BufID]),

    case load_cfg_buff:lookup_buff_cfg(BufID) of
        none ->
            ?ERROR_LOG("take_on_buf ~p", [BufID]),
            ok;
        #buff_cfg{attr_type = AttrType, attrs = Attrs} ->
            attr_new:begin_sync_attr(),
            case AttrType of
                2 ->
                    attr_new:player_add_attr(attr_new:list_2_attr(Attrs));
                1 ->
                    attr_new:player_add_attr_pre(Attrs);
                _ ->
%%                     attr_new:player_add_attr(attr_new:list_2_attr(KeyValList)),
                    ok
            end,
            ?DEBUG_LOG("add buff attr:~p,type:~p", [Attrs, AttrType]),
            attr_new:end_sync_attr(true),
            case get(?pd_idx) of
                undefined ->
                    ok;
                Pidx ->
                    % ?INFO_LOG("add clients buffId:~p,~p", [Pidx, BufID]),
                    %% 永久buff,策划已经没有配
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_BUFF, {Pidx, BufID, EndTime}))
            end

    end,
    ok.


take_off_buf2(BufID) ->
    ?INFO_LOG("take_off_buf ~p", [BufID]),
    case load_cfg_buff:lookup_buff_cfg(BufID) of
        none ->
            ?ERROR_LOG("take_off_buf ~p", [BufID]),
            ok;
        #buff_cfg{attr_type = AttrType, attrs = Attrs} ->
            attr_new:begin_sync_attr(),
            case AttrType of
                2 ->
                    attr_new:player_sub_attr(attr_new:list_2_attr(Attrs));
                1 ->
                    attr_new:player_sub_attr_pre(Attrs);
                _ ->
%%                     attr_new:player_add_attr(attr_new:list_2_attr(KeyValList)),
                    ok
            end,
            attr_new:end_sync_attr(),
            case get(?pd_idx) of
                undefined ->
                    ok;
                Pidx ->
%%                    ?INFO_LOG("canel clients buffId:~p,~p", [Pidx, BufID]),
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_DEL_BUFF, {Pidx, BufID}))
            end
    end,
    ok.

add_skill_modify_attr(Skill_modify_id) ->
    case load_cfg_skill:lookup_skill_modify_cfg(Skill_modify_id) of
        ?none ->
            ?ERROR_LOG("take_on_buf ~p", [Skill_modify_id]),
            ok;
        #skill_modify_cfg{type = Type
            , prop_target_type = Target, svr_coef_prop = CoefSvrProp} ->
            if
                Target =:= 1 ->
                    if
                    % 类型(9是永久)
                        Type =:= 9 ->
                            attr_new:begin_sync_attr(),
                            attr_new:player_add_attr_pre(CoefSvrProp),
                            attr_new:end_sync_attr();
                        true ->
                            ok
                    end;

                true ->
                    ok
            end
    end.

remove_skill_modify_attr(Skill_modify_id) ->
    case load_cfg_skill:lookup_skill_modify_cfg(Skill_modify_id) of
        ?none ->
            ?ERROR_LOG("take_on_buf ~p", [Skill_modify_id]),
            ok;
        #skill_modify_cfg{type = Type
            , prop_target_type = Target, svr_coef_prop = CoefSvrProp} ->
            if
                Target =:= 1 ->
                    if
                    % 类型(9是永久)
                        Type =:= 9 ->
                            attr_new:begin_sync_attr(),
                            attr_new:player_sub_attr_pre(CoefSvrProp),
                            attr_new:end_sync_attr();
                        true ->
                            ok
                    end;

                true ->
                    ok
            end
    end.


 
add_task_bless_buff(BufId) ->
    case load_cfg_buff:lookup_buff_cfg(BufId) of
        none ->
            ok;
        #buff_cfg{attr_type = AttrType, attrs = Attrs, time=Time} ->
            NewTime = erlang:trunc(Time / 1000),
            attr_new:begin_sync_attr(),
            case AttrType of
                2 ->
                    attr_new:player_add_attr(attr_new:list_2_attr(Attrs));
                1 ->
                    attr_new:player_add_attr_pre(Attrs);
                _ ->
                    ok
            end,
            attr_new:end_sync_attr(true),
            case get(?pd_idx) of
                undefined ->
                    ok;
                Pidx ->
                    %?DEBUG_LOG("add_task_bless_buff---------:~p---NewTime---:~p",[BufId, NewTime]),
                    player_mng:bless_add_buff_after(Time, BufId),
                    ?player_send(scene_sproto:pkg_msg(?MSG_SCENE_ADD_BUFF, {Pidx, BufId, NewTime+com_time:now()}))
            end

    end.
