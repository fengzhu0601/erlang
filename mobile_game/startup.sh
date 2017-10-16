#!/usr/bin/env bash
StartMod=mobile_game_cmd
NodeNameCenter=center_svr@192.168.0.142
NodeNameGame=game_svr1@192.168.0.221
Cookie=dragon_cookie


case $1 in
    'st' | 'start')
        erl +pc unicode +P 50000 -smp enable -pa apps/*/ebin -pa ebin +K true -config priv/etc/sys.config -s $StartMod -setcookie $Cookie -name $NodeNameGame;;

    'st_center_svr' | 'server1')
        erl +pc unicode +P 50000 -smp enable -pa apps/*/ebin -pa ebin +K true -config priv/etc/center_sys.config -s $StartMod start_center_app -setcookie $Cookie -name $NodeNameCenter;;

    *)
        show_info ;;
esac
