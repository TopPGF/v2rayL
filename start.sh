#!/bin/sh
# 启动脚本
#
#by pgf@fealive.com
#

#获取脚本路径
READLINK=`which readlink`
SCRIPT_LOCATION=$0
if [ -x "$READLINK" ]; then
  while [ -L "$SCRIPT_LOCATION" ]; do
    SCRIPT_LOCATION=`"$READLINK" -e "$SCRIPT_LOCATION"`
  done
fi

cd "`dirname "$SCRIPT_LOCATION"`"
IDE_BIN_HOME=`pwd`
IDE_HOME=`dirname "$IDE_BIN_HOME"`
cd "$OLDPWD"

CMD=$1

if [ "$CMD"x = "stop"x ]
then
        # grep -Eo 正则匹配提取
        CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
        echo $CONFIG_IP
       /bin/sh -c  'cat ./log/app.pid | xargs kill'
       /bin/sh -c  'cat ./log/check.pid | xargs kill'
elif [ "$CMD"x = "reload"x ]
then
        CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
        echo $CONFIG_IP 
        /bin/sh -c  'cat ./log/app.pid | xargs kill'
        echo "start:".$CONFIG_IP > ./log/v2ray.log
         # nohup 保存pid
        /bin/sh -c 'nohup ./v2ray >> ./log/v2ray.log 2>&1 & echo $! > ./log/app.pid' 
        cat ./log/app.pid | xargs echo
elif [ "$CMD"x = "start"x ]
then
        CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
        echo $CONFIG_IP
        echo "start:".$CONFIG_IP > ./log/v2ray.log
        /bin/sh -c 'nohup ./v2ray >> ./log/v2ray.log 2>&1 & echo $! > ./log/app.pid' 
        cat ./log/app.pid | xargs echo
        /bin/sh -c 'nohup ./check.sh > ./log/check.log 2>&1 & echo $! > ./log/check.pid' 
elif [ "$CMD"x = "update"x ]
then
        CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
        cp ./config.json ./old_config/"$CONFIG_IP".json
        echo "ADDRESS:"${CONFIG_IP}
        ./v2gen_amd64_linux -u "https://bulink.xyz/api/subscribe/?token=wpcpdd&sub_type=vmess" --best -o ./config.json -template ./json_temp
        NEW_CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
        echo "NNEW ADDRESS:"${NEW_CONFIG_IP}
        if [ "$CONFIG_IP" = "$NEW_CONFIG_IP" ];then
                echo "ADDRESS = NNEW ADDRESS,NO RELOAD"
        else
                echo "RELOAD..."
                /bin/sh -c  'cat ./log/app.pid | xargs kill'
                /bin/sh -c 'nohup ./v2ray > ./log/v2ray.log 2>&1 & echo $! > ./log/app.pid'
                cat ./log/app.pid | xargs echo
                echo "SUCCUSS..."
        fi
elif [ "$CMD"x = "startCheck"x ]
then
        /bin/sh -c 'nohup ./check.sh > ./log/check.log 2>&1 & echo $! > ./log/check.pid'
elif [ "$CMD"x = "reloadCheck"x ]
then
        /bin/sh -c  'cat ./log/check.pid | xargs kill'
        /bin/sh -c 'nohup ./check.sh > ./log/check.log 2>&1 & echo $! > ./log/check.pid'
elif [ "$CMD"x = "stopCheck"x ]
then
        /bin/sh -c  'cat ./log/check.pid | xargs kill'
else
        echo "./start.sh update | start | reload | stop | startCheck | reloadCheck | stopCheck"
fi
