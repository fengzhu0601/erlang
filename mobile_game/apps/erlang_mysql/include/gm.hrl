-define(binary_to_int(BinId), list_to_integer(binary_to_list(BinId))).
-define(mail_mod_msg(Mod, Msg), {mod, Mod, ?MODULE, Msg}).


-define(WORLD_ID, 1).
-define(PLATFORM_ID, 1).
