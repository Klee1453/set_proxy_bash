#!/bin/bash

# 检查用户是否提供了足够的参数
if [ $# -eq 2 ]; then
    # 用户提供了两个参数，设置代理
    ip_address="$1"
    port="$2"
    http_proxy="http://$ip_address:$port"
    https_proxy="https://$ip_address:$port"
else
    if [ $# -eq 0 ]; then
        # 如果没有参数，关闭代理
        http_proxy=""
        https_proxy=""
    else
        # 其他情况，打印帮助信息
        echo "Usage: $0 <ip_address> <port>"
        echo "This will set the system proxy to <ip_address>:<port> (HTTP & HTTPS) and synchronize the git and apt proxies."
        echo "If no parameters are entered, the proxy will be closed."
        exit 1
    fi
fi

# 配置文件路径
bashrc_file="$HOME/.bashrc"
apt_proxy_conf="/etc/apt/apt.conf.d/proxy.conf"

# 函数：向文件追加代理设置
append_proxy_setting() {
    local file="$1"
    local pattern="$2"
    local setting="$3"

    if [ -f "$file" ]; then
        # 如果文件存在，使用sed删除已有的代理配置行
        sudo sed -i "/^$pattern/d" "$file"
    fi

    # 向文件追加代理配置
    if [ -n "$setting" ]; then
        echo "$pattern$setting" | sudo tee -a "$file"
    fi
}

# 设置系统代理
append_proxy_setting "$bashrc_file" "export http_proxy=" "\"$http_proxy\""
append_proxy_setting "$bashrc_file" "export https_proxy=" "\"$https_proxy\""

# 设置Git代理
git config --global --unset http.proxy
git config --global --unset https.proxy
if [ -n "$http_proxy" ]; then
    git config --global http.proxy "$http_proxy"
    git config --global https.proxy "$https_proxy"
fi

# 设置APT代理
append_proxy_setting "$apt_proxy_conf" "Acquire::http::Proxy " "\"$http_proxy\";"
append_proxy_setting "$apt_proxy_conf" "Acquire::https::Proxy " "\"$https_proxy\";"

# 重新加载bash配置文件
source "$bashrc_file"

if [ -n "$http_proxy" ]; then
    echo "System proxy, Git proxy, and APT proxy set to $http_proxy and $https_proxy."
else
    echo "Proxy closed."
fi