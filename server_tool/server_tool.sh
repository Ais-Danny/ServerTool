#!/bin/bash

# 读取服务器地址和密码文件
IP_FILE="ip.txt"
PASSWD_FILE="passwd.txt"
SERVER_FOLD="$2"
LOCAL_FOLD="$1"

# 遍历服务器地址和密码文件，逐行处理
while read -u 3 ip && read -u 4 passwd; do
    # 使用rsync命令同步文件夹
    rsync -avz --delete --progress -e "sshpass -p $passwd ssh -o StrictHostKeyChecking=no" "$LOCAL_FOLD" "root@$ip:$SERVER_FOLD"
done 3< "$IP_FILE" 4< "$PASSWD_FILE"
