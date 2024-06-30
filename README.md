# Nubit 节点脚本

方便快捷的安装 Nubit 轻节点

## 安装

默认启动 30 个容器节点，请根据机器的磁盘大小判定自己能跑多少个

```bash
curl -sL https://shell.css.show/start.sh | bash
```

在 bash 后面加一个数字，表示增加自定义数量的容器节点

```bash
curl -sL https://shell.css.show/start.sh | bash 120
```

> 脚本会在安装并运行完成后，自动获取每个节点的私钥信息到执行脚本所在目录下的 `keys.md` 文档中，请谨慎保存文档。
> 目前所有启动的容器都会自带 `自动重启`，如果想不定时查看已停止的容器 ID 集合，请运行 `docker ps -aqf status=exited`，重启所有停止的容器请点击 [这里](##重启所有停止的容器)

---

## 扫描私钥

在安装后如果有容器未在特定时间内启动完成，需要手动运行扫描脚本

```bash
curl -sL https://shell.css.show/scan.sh | bash
```

> 此脚本会从节点名称 `nubit1` 开始扫描私钥信息到执行脚本所在目录下的 `keys.md` 文档中，直到所有容器节点全部扫描完毕为止。

---

## 提交验证

建议所有容器启动后跑 15 分钟左右在开始提交验证

```bash
curl -sL https://shell.css.show/verify.sh | bash
```

此脚本会从节点名称 `nubit1` 开始依次检查每个节点的状态，带着节点的信息去请求官方的验证界面，直到所有容器节点全部检查完毕为止。

> 请注意，在提交验证前，确保所有容器已经启动并运行正常，且私钥文件 `keys.md` 已经填充了有效信息。

---

## 重启所有停止的容器

```bash
docker start $(docker ps -aqf status=exited)
```

---

## 更改容器的重启策略

```bash
docker update --restart=always $(docker ps -aq)
```

---

### 获取 Docker 容器 ID 集合

获取所有已退出的容器的集合
```bash
docker ps -aqf status=exited
```

获取所有容器的集合
```bash
docker ps -aq
```