# 工具作用
- 帮助批量操作服务器发送同步文件
- 批量执行命令
# 必备工具
shpass和rsync ，运行前请检查是否存在！！
```cmd
yum install sshpass

apt install sshpass
```
报错
```cmd
rsync error: error in IPC code (code 14) at pipe.c(85) [sender=3.2.3]
```
# 批量认证host key
不认证，第一次连接的设备无法连接。<br>
会报错

解决办法：输入以下命令

```cmd
ssh-keyscan -f ip.txt >> ~/.ssh/known_hosts
``` 
# ip与密码
将批量操作的ip填入ip.txt,密码填入passwd.txt<br>
密码需要与ip一行行对应

# 注意
默认使用root用户登录，如需修改请修改server_tool.sh文件中的root为其他用户
```shell
# 遍历服务器地址和密码文件，逐行处理
while read -u 3 ip && read -u 4 passwd; do
    # 使用rsync命令同步文件夹
    rsync -avz --delete --progress -e "sshpass -p $passwd ssh -o StrictHostKeyChecking=no" "$LOCAL_FOLD/" "root@$ip:$SERVER_FOLD/"
done 3< "$IP_FILE" 4< "$PASSWD_FILE"
```
