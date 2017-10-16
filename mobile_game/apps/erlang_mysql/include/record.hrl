-ifndef(RECORD).
-define(RECORD,	true).

-record(client, {
				 login  = 0,
				 user_name = undefined,
				 timeout = 0
				}).


-endif.

