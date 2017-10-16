-define(Language(Type, Arg),
    case Type of
        1 ->
            {_PlayerId, PlayerName} = Arg,
            <<PlayerName/binary, "占得先机，成功激活了神魔之战。战役马上开始，热血即将燃烧。"/utf8>>;
        2 ->
            PlayerName = Arg,
            {<<"您"/utf8, "已经离开了公会"/utf8>>,
                <<"玩家"/utf8, PlayerName/binary, "离开了公会"/utf8>>};
        3 ->
            PlayerName = Arg,
            {<<"您"/utf8, "被移除公会"/utf8>>,
                <<"玩家"/utf8, PlayerName/binary, "被移除公会"/utf8>>};
        4 ->
            {GuildName, PlayerName} = Arg,
            {<<GuildName/binary, "公会批准了您的入会申请！，您已加入"/utf8, GuildName/binary, "公会!"/utf8>>,
                <<"玩家"/utf8, PlayerName/binary, "加入了公会"/utf8>>};

        5 ->
            {PlayerName, PositionName} = Arg,
            {<<"您的职位已变更，现在是"/utf8, PositionName/binary>>,
                <<"玩家"/utf8, PlayerName/binary, "的职位已变更，现在是"/utf8, PositionName/binary>>};
        6 ->
            <<"系统"/utf8>>;
        7 ->
            {MyPlayerName, ToPlayerName, MsgBin} = Arg,
            <<"玩家："/utf8, MyPlayerName/binary, "赠送鲜花给玩家："/utf8, ToPlayerName/binary, "附加祝福语："/utf8, MsgBin/binary>>;
        _ -> <<>>
    end).