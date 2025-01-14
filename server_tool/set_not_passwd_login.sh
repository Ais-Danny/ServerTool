#!/bin/bash
#配置无密码访问

# 自定义变量
PASSWORD="123456"
TIMEOUT_DURATION=2  # 设置连接超时时间为2秒
HOSTS=(
    "127.0.0.1:2221"
    "127.0.0.1:2222"
    "127.0.0.1:2223"
    "127.0.0.1:2224"
    "127.0.0.1:2225"
)


# 生成密钥
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "生成 SSH 密钥..."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" <<< y >/dev/null 2>&1
fi

# 初始化计数器和失败主机列表
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_HOSTS=()

# 遍历所有主机并分发密钥
for HOST in "${HOSTS[@]}"; do
    IP=$(echo $HOST | cut -d: -f1)
    PORT=$(echo $HOST | cut -d: -f2)

    if grep -q "$IP" ~/.ssh/known_hosts; then
        echo "更新主机 $IP:$PORT 的公钥到 known_hosts..."
        # 删除旧的公钥并添加新的公钥
        ssh-keyscan -p $PORT $IP | sed "s|.* $IP|$IP|" > ~/.ssh/known_hosts.tmp
        mv ~/.ssh/known_hosts.tmp ~/.ssh/known_hosts
    else
        echo "添加主机 $IP:$PORT 到 known_hosts..."
        ssh-keyscan -p $PORT $IP >> ~/.ssh/known_hosts
    fi

    # 检查目标主机是否已经接收到公钥（通过查询目标主机的 authorized_keys）
    if sshpass -p "$PASSWORD" ssh -p $PORT root@$IP "grep -q $(cat ~/.ssh/id_rsa.pub) ~/.ssh/authorized_keys"; then
        # 如果已经存在，则删除旧的公钥并重新添加
        echo "目标主机 $IP:$PORT 已经拥有该公钥，更新公钥..."
        sshpass -p "$PASSWORD" ssh -p $PORT root@$IP "sed -i '/$(cat ~/.ssh/id_rsa.pub)/d' ~/.ssh/authorized_keys"
        sshpass -p "$PASSWORD" ssh-copy-id -f -o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/known_hosts -p $PORT root@$IP
    else
        # 如果不存在，则直接添加
        echo "分发公钥到 $IP:$PORT..."
        sshpass -p "$PASSWORD" ssh-copy-id -f -o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/known_hosts -p $PORT root@$IP
    fi
done
# 重新加载 SSH 服务
sudo systemctl reload sshd

# 测试连接是否成功，设置连接超时为 2 秒
for HOST in "${HOSTS[@]}"; do
    IP=$(echo $HOST | cut -d: -f1)
    PORT=$(echo $HOST | cut -d: -f2)

    # 测试连接（设置连接超时为 2 秒）
    timeout $TIMEOUT_DURATION ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/known_hosts -p $PORT root@$IP "echo SSH 连接成功" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        # 成功连接，打印绿色
        echo -e "\033[32m连接到 $IP:$PORT 成功\033[0m"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        # 连接失败，打印红色，并记录失败主机
        echo -e "\033[31m连接到 $IP:$PORT 失败\033[0m"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_HOSTS+=("$IP:$PORT")
    fi
done

# 输出统计结果
echo "脚本执行完毕。"
echo "成功连接的主机数量: $SUCCESS_COUNT"
echo "失败连接的主机数量: $FAIL_COUNT"

# 打印失败主机
if [ $FAIL_COUNT -gt 0 ]; then
    echo "失败的主机列表："
    for FAILED_HOST in "${FAILED_HOSTS[@]}"; do
        echo -e "\033[31m$FAILED_HOST\033[0m"
    done
fi

