#!/bin/bash
# DIY Part 2: Modify default settings

# 1. 设置默认 IP 为 192.168.1.149
sed -i 's/192.168.1.1/192.168.1.149/g' package/base-files/files/bin/config_generate

# 2. 设置默认主机名
sed -i 's/ImmortalWrt/N1-SmartHub/g' package/base-files/files/bin/config_generate

# 3. 预置空 root 密码或默认密码 (首次登录免密)
sed -i 's/root:::0:99999:7:::/root:$1$wOSEP92i$1tqf5R55H0k29gLSmg3k60:18400:0:99999:7:::/g' package/base-files/files/etc/shadow 2>/dev/null || true
