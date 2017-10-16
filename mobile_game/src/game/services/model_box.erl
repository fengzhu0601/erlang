%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 人物模型大小
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(model_box).


-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("model_box.hrl").


load_config_meta() ->
    [
        #config_meta{record = #model_box_cfg{},
            fields = ?record_fields(model_box_cfg),
            file = "generated_model_box.txt",
            keypos = #model_box_cfg.id,
            verify = fun verify/1}
    ].


verify(#model_box_cfg{id = _Id, x = X, y = Y, h = H}) ->
    ?check(?is_pos_integer(X), "model_box [~p] x:~p 无效", [X]),
    ?check(?is_pos_integer(Y), "model_box [~p] y:~p 无效", [Y]),
    ?check(?is_pos_integer(H), "model_box [~p] h:~p 无效", [H]),
    ok;

verify(_R) ->
    ?ERROR_LOG("model_box配置 ~p错误格式", [_R]),
    exit(bad).


