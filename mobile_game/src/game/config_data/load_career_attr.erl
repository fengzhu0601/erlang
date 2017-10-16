%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 七月 2015 上午11:12
%%%-------------------------------------------------------------------
-module(load_career_attr).
-author("clark").

%% API
-export
([
    get_lev_attr_id/2
    , get_lv_totle_exp/2
]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_career_attr.hrl").



load_config_meta() ->
    [
        #config_meta
        {
            record = #role_cfg{},
            fields = ?record_fields(role_cfg),
            file = "hero.txt",
            keypos = [#role_cfg.career, #role_cfg.lev],
            verify = fun verify/1
        }
    ].



verify(#role_cfg{career = C, lev = Lev, level_up_exp = Exp, attr = St}) ->
    ?check(player_def:is_valid_career(C), "hero.txt ~w 的career ~w 无效!", [{C, Lev}, C]),
    ?check(com_util:is_valid_uint8(Lev), "hero.txt ~w 的lev ~w 无效!", [{C, Lev}, Lev]),
    ?check(com_util:is_valid_uint64(Exp), "hero.txt ~w 的level_up_exp ~w 无效!", [{C, Lev}, Exp]),
    ?check(load_spirit_attr:is_exist_attr(St), "hero.txt ~w 的attr ~w 没有找到!", [{C, Lev}, St]),
    ok.




%% 获取职业等级对应的属性id
get_lev_attr_id(Career, Lev) ->
    case lookup_role_cfg({Career, Lev}) of
        #role_cfg{attr = St} ->
            St;
        _ ->
            ?none
    end.


get_lv_totle_exp(Career, Level) ->
    case lookup_role_cfg({Career, Level}) of
        #role_cfg{level_up_exp = Exp} ->
            Exp;
        _ ->
            ?none
    end.