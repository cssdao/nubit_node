#!/bin/bash

# 确认步骤
echo "这个脚本将会删除 Nubit 节点容器，请谨慎操作"
echo -n "你确定想删除 Nubit 节点容器吗？输入 'yes' 表示继续："
read -r confirmation

# 检查用户输入
if [ "$confirmation" != "yes" ]; then
    echo "操作已取消"
    exit 1
fi

# 继续执行删除操作
echo "删除 Nubit 节点容器开始..."

# 查找当前最大的容器编号
CONTAINER_COUNT=$(docker ps -a --format '{{.Names}}' | grep '^nubit[0-9]*$' | sed 's/nubit//' | sort -n | tail -n 1)

# 循环开始
for i in {1..CONTAINER_COUNT}
do
    # 构造容器名
    container_name="nubit$i"
    
    # 使用 docker rm -f 命令强制删除容器
    docker rm -f "$container_name"
    
    # 输出删除操作的结果
    if [ $? -eq 0 ]; then
        echo "成功删除 $container_name 容器"
    else
        echo "删除失败： $container_name （它好像不存在）"
    fi
done

echo "操作完成。"