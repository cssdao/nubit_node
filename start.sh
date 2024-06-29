#!/bin/bash

# 警告：这个脚本包含敏感信息。请确保脚本文件的权限设置正确，并且不要将其分享给未经授权的人。

# 检查是否安装了Docker
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Docker 未安装，正在尝试安装..."
        install_docker
    else
        echo "Docker 已安装，继续执行..."
    fi
}

# 安装Docker
install_docker() {
    # 检测Linux发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo "无法检测到 Linux 发行版，请手动安装 Docker。"
        exit 1
    fi

    echo "检测到的操作系统: $OS $VER"

    case $OS in
    "Ubuntu" | "Debian GNU/Linux")
        install_docker_debian
        ;;
    "CentOS Linux" | "Red Hat Enterprise Linux" | "Fedora")
        install_docker_redhat
        ;;
    "SUSE Linux Enterprise Server" | "openSUSE Leap")
        install_docker_suse
        ;;
    "Alpine Linux")
        install_docker_alpine
        ;;
    *)
        echo "不支持的Linux发行版: $OS"
        echo "请参考Docker官方文档手动安装: https://docs.docker.com/engine/install/"
        exit 1
        ;;
    esac

    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER

    echo "Docker 安装完成。请注销并重新登录以应用组更改，或重启系统。"
    echo "安装完成后，请重新运行此脚本。"
    exit 0
}

# 在Debian/Ubuntu上安装Docker
install_docker_debian() {
    # 更新包索引
    sudo apt-get update
    # 安装必要的包
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    # 添加Docker的官方GPG密钥
    curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    # 设置稳定版仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    # 更新apt包索引
    sudo apt-get update
    # 安装Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# 在CentOS/RHEL/Fedora上安装Docker
install_docker_redhat() {
    # 删除旧版本
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    # 安装必要的包
    sudo yum install -y yum-utils
    # 设置仓库
    sudo yum-config-manager --add-repo https://download.docker.com/linux/${ID}/docker-ce.repo
    # 安装Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    # 启动Docker
    sudo systemctl start docker
    # 设置开机自启
    sudo systemctl enable docker
}

# 在SUSE上安装Docker
install_docker_suse() {
    # 添加Docker仓库
    sudo zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
    # 刷新仓库
    sudo zypper refresh
    # 安装Docker
    sudo zypper install -y docker-ce docker-ce-cli containerd.io
    # 启动Docker
    sudo systemctl start docker
    # 设置开机自启
    sudo systemctl enable docker
}

# 在Alpine上安装Docker
install_docker_alpine() {
    # 更新包索引
    sudo apk update
    # 安装Docker
    sudo apk add docker
    # 启动Docker
    sudo rc-update add docker boot
    sudo service docker start
}

# 检查并安装Docker
check_docker

# Docker 登录信息
DOCKER_USERNAME="zh30"
DOCKER_PASSWORD="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"
DOCKER_REGISTRY="ghcr.io"
IMAGE_NAME="ghcr.io/cssdao/nubit_node:latest"
# 定义最大重试次数
MAX_RETRIES=5

# 检查 nubit_node:latest 镜像是否存在
if ! docker image inspect $IMAGE_NAME &>/dev/null; then
    echo "$IMAGE_NAME 镜像不存在，正在尝试登录并拉取..."

    # 登录到 Docker 仓库
    echo "$DOCKER_PASSWORD" | docker login $DOCKER_REGISTRY -u "$DOCKER_USERNAME" --password-stdin

    if [ $? -ne 0 ]; then
        echo "Docker 登录失败，请检查凭证。"
        exit 1
    fi

    # 拉取镜像
    docker pull $IMAGE_NAME

    if [ $? -ne 0 ]; then
        echo "拉取镜像失败。"
        exit 1
    fi

    echo "镜像已成功拉"
else
    echo "$IMAGE_NAME 镜像已存在，继续执行..."
fi

# 查找当前最大的容器编号
MAX_CONTAINER_NUM=$(docker ps -a --format '{{.Names}}' | grep '^nubit[0-9]*$' | sed 's/nubit//' | sort -n | tail -n 1)

# 如果没有找到容器，从1开始；否则从下一个数字开始
if [ -z "$MAX_CONTAINER_NUM" ]; then
    START_NUM=1
else
    START_NUM=$((MAX_CONTAINER_NUM + 1))
fi

echo "将从容器编号 $START_NUM 开始启动新容器"

# 设置默认容器数量
DEFAULT_COUNT=30

# 检查是否提供了命令行参数
if [ $# -gt 0 ]; then
    CONTAINER_COUNT=$1
else
    CONTAINER_COUNT=$DEFAULT_COUNT
fi

# 验证输入是否为正整数
if ! [[ "$CONTAINER_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "错误: 请提供一个有效的正整数作为容器数量。"
    exit 1
fi

echo "将启动 $CONTAINER_COUNT 个容器"

# 循环启动容器
for i in $(seq $START_NUM $((START_NUM + $CONTAINER_COUNT - 1))); do
    CONTAINER_NAME="nubit$i"
    echo "正在启动容器: $CONTAINER_NAME"
    docker run -d --name $CONTAINER_NAME $IMAGE_NAME

    # 输出删除操作的结果
    if [ $? -eq 0 ]; then
        echo "成功启动 $container_name 容器"
    else
        echo "启动失败：$container_name"
    fi

    # 等待容器完全启动
    sleep 1
done

SLEEPTIME=$((240 + $CONTAINER_COUNT * 3))
echo "所有容器已成功启动。等待 $SLEEPTIME 秒后，执行提取密钥信息"

sleep $SLEEPTIME

echo "开始执行提取密钥信息动作"

# 循环提取密钥信息并保存到 keys.md
for i in $(seq $START_NUM $((START_NUM + $CONTAINER_COUNT - 1))); do
    CONTAINER_NAME="nubit$i"

    # 初始化重试计数器
    retry_count=0

    while [ $retry_count -lt $MAX_RETRIES ]; do
        echo "提取 $CONTAINER_NAME 的信息... (尝试 $((retry_count + 1))/$MAX_RETRIES)"

        # 获取容器日志并保存到变量，同时禁止输出到终端
        container_logs=$(docker logs $CONTAINER_NAME 2>/dev/null)

        # 提取所需信息
        address=$(echo "$container_logs" | grep "ADDRESS:" | sed 's/ADDRESS: //')
        mnemonic=$(echo "$container_logs" | sed -n '/MNEMONIC/,/\*\*/p' | grep -v 'MNEMONIC' | grep -v '\*\*' | tr -d '\n')
        pubkey=$(echo "$container_logs" | grep -A 1 "\*\* PUBKEY \*\*" | tail -n 1)
        authkey=$(echo "$container_logs" | grep -A 1 "\*\* AUTH KEY \*\*" | tail -n 1)

        # 检查是否所有信息都已获取
        if [ -n "$address" ] && [ -n "$mnemonic" ] && [ -n "$pubkey" ] && [ -n "$authkey" ]; then
            # 所有信息都已获取，写入 keys.md
            {
                echo "Container: $CONTAINER_NAME"
                echo "Address: $address"
                echo "Mnemonic: $mnemonic"
                echo "Pubkey: $pubkey"
                echo "Authkey: $authkey"
                echo "---"
            } >>keys.md
            echo "成功提取 $CONTAINER_NAME 的信息并写入 keys.md"
            break # 跳出重试循环
        else
            # 信息不完整，准备重试
            echo "无法获取 $CONTAINER_NAME 的完整信息，准备重试..."
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                sleep 10 # 等待10秒后重试
            fi
        fi
    done

    if [ $retry_count -eq $MAX_RETRIES ]; then
        echo "警告：无法在 $MAX_RETRIES 次尝试后获取 $CONTAINER_NAME 的完整信息"
    fi
    sleep 1
done

echo "所有容器已启动并记录完成!私钥信息已经在 keys.md 文件中，请谨慎保存。"
