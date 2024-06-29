#!/bin/bash

# 警告：这个脚本包含敏感信息。请确保脚本文件的权限设置正确，并且不要将其分享给未经授权的人。

# 查找当前最大的容器编号
CONTAINER_COUNT=$(docker ps -a --format '{{.Names}}' | grep '^nubit[0-9]*$' | sed 's/nubit//' | sort -n | tail -n 1)

# 如果没有找到容器，从1开始；否则从下一个数字开始
if [ -z "$CONTAINER_COUNT" ]; then
  echo "没有运行任何 nubit 节点容器，请先运行节点脚本"
  exit 0
fi

echo "将扫描 $CONTAINER_COUNT 个容器"

# 定义最大重试次数
MAX_RETRIES=5

# 清空 keys.md 文件
> keys.md
echo "keys.md 文件已清空，准备写入新的数据。"

# 循环提取密钥信息并保存到 keys.md
for i in $(seq 1 $CONTAINER_COUNT); do
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
