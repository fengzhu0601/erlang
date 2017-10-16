#!/usr/bin/env bash

cd ~/work/server/mobile_game/release
rm -rf ./share_142@192.168.0.142/Database
scp -r santi_server@192.168.0.142:/home/santi_server/run/tar_version_temp/share_142/Database ./share_142@192.168.0.142
cd ..
make st svr=share_142 ip='192.168.0.142'
