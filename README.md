# 🚀 Nubit 节点启动器

一键式解决方案，轻松部署和管理大规模 Nubit 轻节点。

## 🛠 快速开始

部署 30 个节点（默认）：
```bash
curl -sL https://shell.css.show/start.sh | bash
```

自定义节点数量：
```bash
curl -sL https://shell.css.show/start.sh | bash 120
```

## 🔑 密钥管理

自动生成的密钥存储在`keys.md`中。请妥善保管此文件！

## 🔍 节点扫描

错过了某些节点？运行：
```bash
curl -sL https://shell.css.show/scan.sh | bash
```

## ✅ 验证

节点运行 15 分钟后，进行验证：
```bash
curl -sL https://shell.css.show/verify.sh | bash
```

## 🔄 维护

重启已停止的容器：
```bash
docker start $(docker ps -aqf status=exited)
```

为所有容器设置自动重启：
```bash
docker update --restart=always $(docker ps -aq)
```

## 📊 监控

列出已退出的容器：
```bash
docker ps -aqf status=exited
```

列出所有容器：
```bash
docker ps -aq
```

---

⚠️ 处理节点密钥和敏感数据时，请确保采取适当的安全措施。

🌟 加入 Nubit 革命！轻松扩展您的节点部署。