-behaviour(player_mod).
-export([create_mod_data/1,
    load_mod_data/1,
    init_client/0,
    view_data/1,
    handle_frame/1,
    handle_msg/2,
    online/0,
    offline/1,
    save_data/1
]).

