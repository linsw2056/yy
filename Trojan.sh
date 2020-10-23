#!/bin/bash
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
clear
green "=========================================================="
 red "本脚本由木子教授改写,所有权归原作者所有" 
 blue "本脚本为Trojan for debian9 一键安装脚本" 
 blue "在阿里云Debian9.11 测试通过"
green "=========================================================="
 red "因本脚本要占用443、80端口,请勿在生产环境安装,请在独立vps安装"
green "=========================================================="
read -s -n1 -p "若同意上述协议，请按任意键继续 ... "

apt-get install wget                          ##Debian Ubuntu 安装 wget
apt-get update -y && apt-get install curl -y    ##Ubuntu/Debian 系统安装 Curl 方法
apt-get install xz-utils   #Debian/Ubuntu 安装 XZ 压缩工具命令
apt-get update    ##更新
apt-get -y install  nginx wget unzip zip curl tar   #Debian安装
systemctl enable nginx.service    #设置Nginx开机启动

green "======================="
blue  "请输入绑定到本VPS的域名"
green "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
green " "
green " "
green "==================================="
 blue "检测到域名解析地址为 $real_addr"
 blue "本VPS的IP为 $local_addr"
green "==================================="
sleep 3s


#开始安装Nginx并配置
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF

green " "
green " "
green "=========================================="
blue "      生成伪装站点"
green "=========================================="
sleep 3s

rm -rf /usr/share/nginx/html/*
cd /usr/share/nginx/html/
#wget https://github.com/V2RaySSR/Trojan/raw/master/web.zip
#unzip web.zip
cat > /usr/share/nginx/html/index.html <<-EOF
<!DOCTYPE html>
<html lang="en">
<head>
<title>HomePage</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta charset="utf-8">
<meta name="keywords" content="" />
</head>
<body>
	<div>这是一个测试网站
	</div>
</body>	
</html>
EOF

systemctl restart nginx.service   #重启nginx

green "=========================================================="
 red "请测试,访问http://你的域名 ，应该可以打开网站了。（不是https://）"
green "=========================================================="
read -s -n1 -p "请按任意键继续 ... "



green "=========================================="
blue "      开始下载安装官方Trojan最新版本"
green "=========================================="
sleep 3s

mkdir -p /root/trojan               #创建目录
mkdir -p /root/trojan/trojan-cert   #创建证书目录
cd /root/trojan   #进入该目录
#cd /usr/src  
wget https://github.com/trojan-gfw/trojan/releases/download/v1.14.0/trojan-1.14.0-linux-amd64.tar.xz    #下载官方Trojan服务器
tar xf trojan-1.*   #解压该文件



#写入配置文件
cat > /root/trojan/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "00000000"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/root/trojan/trojan-cert/cert.cer",
        "key": "/root/trojan/trojan-cert/private.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
green "=========================================="
blue "      正在设置Trojan开机启动"
green "=========================================="
sleep 3s

cat > /lib/systemd/system/trojan.service <<-EOF     
[Unit]  
Description=trojan  
After=network.target  
   
[Service]  
Type=simple  
PIDFile=/root/trojan/trojan/trojan/trojan.pid
ExecStart=/root/trojan/trojan/trojan -c "/root/trojan/trojan/server.conf"  
ExecReload=  
ExecStop=/root/trojan/trojan/trojan  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target

EOF



systemctl start trojan.service  #启动Trojan
systemctl enable trojan.service  #设置Trojan服务开机自启

systemctl restart trojan

cat > /root/trojan/配置.txt <<-EOF

==========================================================

支持：debian9+
作者:木子教授 

==========================================================

你的Trojan配置信息为：

	域名：$your_domain
	密码：00000000
	端口：443
	请将
	xxx.xxx.xxx_chain.crt改名为cert.cer
    xxx.xxx.xxx_key.key改名为private.key 
	上传至/root/trojan/trojan-cert 

==========================================================

EOF

green "=========================================="
blue "      Trojan配置完毕"
blue "	域名：$your_domain"
blue "	密码：00000000"
blue "	端口：443"
blue "	请将"
blue "	xxx.xxx.xxx_chain.crt改名为cert.cer"
blue "  xxx.xxx.xxx_key.key改名为private.key"
blue "	上传至/root/trojan/trojan-cert "
red "	 执行 systemctl restart trojan "
green "=========================================="
sleep 3s