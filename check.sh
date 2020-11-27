#!/bin/bash
#
# 检查网速
#
#by pgf@fealive.com
#

CONFIG_IP=
funReload(){
    #备份配置文件
    cp ./config.json ./old_config/"$1".json
    ./v2gen_amd64_linux -u "https://bulink.xyz/api/subscribe/?token=wpcpdd&sub_type=vmess" --best -o ./config.json -template ./json_temp
    NEW_CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
    echo "NNEW ADDRESS:"{$NEW_CONFIG_IP}
    if [ "$1" = "$NEW_CONFIG_IP" ];then
            echo "ADDRESS = NNEW ADDRESS,NO RELOAD"
    else
            echo "RELOAD..."
            /bin/sh -c  'cat ./log/app.pid | xargs kill'
            echo "start:".$NEW_CONFIG_IP > ./log/v2ray.log
            /bin/sh -c 'nohup ./v2ray >> ./log/v2ray.log 2>&1 & echo $! > ./log/app.pid'
            cat ./log/app.pid | xargs echo
            echo "SUCCUSS..."
    fi
}

wgetCheck(){
    echo > ./log/wget.log #清空上次wget
    echo  "开启wget测速,下载文件https://codeload.github.com/v2fly/v2ray-core/tar.gz/v4.31.0"
    /bin/sh -c 'nohup wget -O /dev/null -o ./log/wget.log -e https_proxy=http://127.0.0.1:1081 https://codeload.github.com/v2fly/v2ray-core/tar.gz/v4.31.0 >> /dev/null 2>&1 & echo $! > ./log/wget.pid'
    sleep 10
    /bin/sh -c  'cat ./log/wget.pid | xargs kill'
    wgetRs=`tail -n 2 ./log/wget.log | head -n 1`
    echo $wgetRs
    speedInfo=`echo $wgetRs | grep $(date +%Y-%m-%d) | grep -Eo "[0-9]{1,4}(\.[0-9]+)? [KM]+B/s"`
    if [ -z "$speedInfo" ]; then #10s未下载完,取最后一条网速
        speedInfo=`echo $wgetRs | awk '{print $5 $6 $7 $8}'`
        speedInfo=${speedInfo:-'0K'} #是0 不是o
        speed=`echo $speedInfo | grep -Eo "[0-9]{1,4}(\.[0-9]+)?[KM]+" | grep -Eo "[0-9]{1,4}(\.[0-9]+)?"`
        unit=`echo $speedInfo | grep -Eo "[KM]+"`"B/s"
        speedInfo=$speed" "$unit
    else
        speed=`echo $speedInfo |  awk '{print $2}'`
        unit=`echo $speedInfo |  awk '{print $1}'`
    fi
    echo "speedInfo:"$speedInfo
    echo "speed:"$speed
    echo "unit:"$unit
    if [[ $unit == "KB/s" && `echo "$speed < 500" | bc` -eq 1   ]]; then
        echo "网速慢,更新订阅并重启reload v2tay"
        echo "现在时间是"$(date +%Y年%m月%d日%H:%M:%S )"-------------------------------" >> ./log/v2rayReload.log
        echo "目标地址:${CONFIG_IP} 网速慢,重新加载" >> ./log/v2rayReload.log
        funReload $CONFIG_IP
    else
        echo "网速正常"
    fi
}

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
echo "checking..."
lastfailedOutboundTime=
while [ 1 ]
do
    echo "现在时间是"$(date +%Y年%m月%d日%H:%M:%S )"-------------------------------"
    CONFIG_IP=`cat config.json | grep address | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}'`
    echo "测试目标地址:${CONFIG_IP}--------------------------"
    if (ping -c 1 {$CONFIG_IP} >/dev/null 2>&1);then
            echo "目标地址:${CONFIG_IP}网络故障,重新加载"
            echo "现在时间是"$(date +%Y年%m月%d日%H:%M:%S )"-------------------------------" >> ./log/v2rayReload.log
            echo "目标地址:${CONFIG_IP}网络故障,重新加载" >> ./log/v2rayReload.log
            funReload $CONFIG_IP
    fi
    
    pingRs=`ping -c 5 40.83.72.221 | tail -n 2`
    echo $pingRs
    rtt=`echo $pingRs | awk -F'=' '{print $2}' | awk -F'/' '{print $2}'`
    rtt=${rtt:-'500'}
    #echo "延迟:"$rtt
    packetloss=`echo $pingRs | awk -F',' '{print $3}' | grep -Eo "[0-9]{1,3}"`
    #echo "packet loss:"$packetloss
    if [[ `echo "$rtt >= 50" | bc` -eq 1 && packetloss -gt 40 ]];then
            echo "目标地址:${CONFIG_IP},延迟:${rtt}ms,packet loss:${packetloss}"
            echo "延迟大于30,packet loss大于40,测试网速"
            wgetCheck
    else
        echo "ping 正常"
    fi
    #日志检查
    hasFailedDial=`tail -n 10 log/v2ray.log | grep "failed to dial to (wss://${CONFIG_IP}/v2ray)" | tail -n 1`
    failedOutboundTime=`tail -n 5 log/v2ray.log | grep "failed to process outbound traffic" | tail -n 1 | grep -Eo "[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"`
    if [ -n "$hasFailedDial" ];then
            echo "$hasFailedDial"
            echo "目标地址:${CONFIG_IP} 网络链接错误,重新加载"
            echo "现在时间是"$(date +%Y年%m月%d日%H:%M:%S )"-------------------------------" >> ./log/v2rayReload.log
            echo "目标地址:${CONFIG_IP} 网络链接错误,重新加载" >> ./log/v2rayReload.log
            funReload $CONFIG_IP
    elif [ -n "$failedOutboundTime" ];then
            echo "Has failed to process outbound traffic , Last Time ${lastfailedOutboundTime}"
            echo "New failed to process outbound traffic ${failedOutboundTime}"
            if [ "$lastfailedOutboundTime" != "$failedOutboundTime" ];then
                lastfailedOutboundTime=$failedOutboundTime
                echo "目标地址:${CONFIG_IP} 无法处理出站流量,检查网速"
                wgetCheck
            fi
    else
        echo "链接 正常"
    fi
  
    sleep 30
    echo  ""   
done 

