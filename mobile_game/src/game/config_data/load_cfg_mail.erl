%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 邮件系统
%%%
%%% @end
%%% Created : 04. 一月 2016 下午4:09
%%%-------------------------------------------------------------------
-module(load_cfg_mail).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_mail.hrl").

load_config_meta() ->
    [
        #config_meta{record = #mail_sys_cfg{},
        fields = ?record_fields(mail_sys_cfg),
        file = "mail_sys.txt",
        keypos = #mail_sys_cfg.id,
        verify = fun verify/1}
    ].


verify(#mail_sys_cfg{id = Id, expirt_day = ExpirtDay, title = Title, content = Content}) ->
    ?check(com_util:is_valid_uint8(ExpirtDay), "mail_sys.txt id(~w) expirt_day (~w) is error!", [Id, ExpirtDay]),
    ?check(erlang:is_binary(Title), "mail_sys.txt id(~w) title(~s) is error!", [Id, Title]),
    ?check(erlang:is_binary(Content), "mail_sys.txt id(~w) content(~s) is error!", [Id, Content]),
    ok;
verify(_R) ->
    ?ERROR_LOG("item ~p 无效格式", [_R]),
    exit(bad).