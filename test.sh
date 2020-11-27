#!/bin/bash
CONFIG_IP="120.232.163.125"
hasFailed=`tail -n 50 log/v2ray.log | grep "failed to dial to (wss://${CONFIG_IP}/v2ray)" | tail -n 1`
#不为空错误
if [ -n "$hasFailed" ]; then
        echo $hasFailed
        echo "目标IP($CONFIG_IP)链接错误,重新加载"
        #funReload $CONFIG_IP
fi
