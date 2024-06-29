# 使用最新的Ubuntu镜像
FROM ubuntu:latest

# 更新APT包索引并安装curl
RUN apt-get update && apt-get install -y curl

# 设置容器启动时执行的命令
CMD ["bash", "-c", "curl -sL1 https://nubit.sh | bash"]
