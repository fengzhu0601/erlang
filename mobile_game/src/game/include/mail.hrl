-define(player_mail_tab, player_mail_tab).
-define(offline_mail_tab, offline_mail_tab).
-record(?player_mail_tab,{
    id,
    mng
}).

-define(OFFLINE_MAIL, 1).
-record(?offline_mail_tab, {
	id,
	mail_list=[]
}).
