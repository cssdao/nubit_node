#!/bin/bash

# 警告：这个脚本包含敏感信息。请确保脚本文件的权限设置正确，并且不要将其分享给未经授权的人。

# Docker 登录信息
DOCKER_USERNAME="zh30"
DOCKER_PASSWORD="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"
DOCKER_REGISTRY="ghcr.io"
IMAGE_NAME="ghcr.io/cssdao/nubit_node:latest"

# 检查 nubit:latest 镜像是否存在
if ! docker image inspect $IMAGE_NAME &> /dev/null; then
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
    
    # 为拉取的镜像添加 nubit:latest 标签
    docker tag $IMAGE_NAME nubit:latest
    
    echo "镜像已成功拉"
else
    echo "$IMAGE_NAME 镜像已存在，继续执行..."
fi

# 设置默认容器数量
DEFAULT_COUNT=50

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
for i in $(seq 1 $CONTAINER_COUNT)
do
    CONTAINER_NAME="nubit$i"
    echo "正在启动容器: $CONTAINER_NAME"
    docker run -d --name $CONTAINER_NAME $IMAGE_NAME

    # 等待容器完全启动
    sleep 1
done

SLEEPTIME=$((240 > $CONTAINER_COUNT ? (340-CONTAINER_COUNT) : 100))
echo "所有容器已成功启动。等待 $SLEEPTIME 秒后，执行提取密钥信息"

sleep $SLEEPTIME

echo "开始执行提取密钥信息动作"

# 循环提取密钥信息并保存到 keys.md
for i in $(seq 1 $CONTAINER_COUNT)
do
    CONTAINER_NAME="nubit$i"

    # 提取信息并追加到 keys.md
    echo "提取 $CONTAINER_NAME 的信息..."
    {
        echo "Container: $CONTAINER_NAME"

        # 获取容器日志并保存到变量
        container_logs=$(docker logs $CONTAINER_NAME)
        echo "Address: $(echo "$container_logs" | grep "ADDRESS:" | sed 's/ADDRESS: //' )"
        echo "Mnemonic: $(echo "$container_logs" | sed -n '/MNEMONIC/,/\*\*/p' | grep -v 'MNEMONIC' | grep -v '\*\*' | tr -d '\n' )"
        echo "Pubkey: $(echo "$container_logs" | grep -A 1 "\*\* PUBKEY \*\*" | tail -n 1 )"
        echo "Authkey: $(echo "$container_logs" | grep -A 1 "\*\* AUTH KEY \*\*" | tail -n 1 )"
        echo "---"
    } >> keys.md
    sleep 1
done

echo "所有容器已启动并记录完成!私钥信息已经在 keys.md 文件中，请谨慎保存。"