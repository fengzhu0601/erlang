%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2015 下午5:02
%%%-------------------------------------------------------------------
-module(load_cfg_emits).
-author("clark").

%% API
-export
([
    get_skill/1
    , get_skill_id/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_cfg_emits.hrl").

-define(item_id_assets_max, 1000).

load_config_meta() ->
    [
        #config_meta
        {
            record = #emits_cfg{},
            fields = ?record_fields(emits_cfg),
            file = "emits.txt",
            keypos = #emits_cfg.id,
            verify = fun verify/1
        }
    ].


verify(#emits_cfg{}) ->
    ok.

get_skill(BulletId) ->
    case lookup_emits_cfg(BulletId) of
        #emits_cfg{} = SkillCfg ->
            SkillCfg;
        _ ->
            ?none
    end.

get_skill_id(BulletId) ->
    case lookup_emits_cfg(BulletId) of
        #emits_cfg{attack_skill = SkillId} ->
            SkillId;
        _ ->
            0
    end.
