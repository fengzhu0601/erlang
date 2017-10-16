%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 一月 2016 下午4:09
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(mail_sys_cfg,
{
  id = 0,
  expirt_day = 1,
  title = <<>>,
  content = <<>>
}).
