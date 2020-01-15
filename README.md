# dev-fabric-network

dev-fabric-network 是一个开发工具, 让 fabric 开发者可以快速的获得一个可用的开发环境.

你可能会问, 为什么不使用官网教程的 "build your first network" 呢?
因为不够轻, 且不够好用.

## 环境要求

1. 本地有 fabric 的二进制执行文件, peer, orderer 等, 版本为 1.4.4
2. 本地有 docker, docker-compose
3. 本地有以下镜像
	- hyperledger/fabric-baseos   <0.4.18>
	- hyperledger/fabric-javaenv  <1.4.4>
	- hyperledger/fabric-tools    <1.4.4>
	- hyperledger/fabric-ccenv    <1.4.4>
	- hyperledger/fabric-ca       <1.4.4>
	- hyperledger/fabric-couchdb  <0.4.18>

使用中仅 fabric-ca, fabric-couchdb 会长期运行在 docker 容器, 其他镜像被需要的原因是配合 fabric 网络最基础的功能.

## 快速上手

cd 到 dev-fabric-network 目录下.

1. 快速启动一个 fabric 网络.

```sh
./network.sh up
```

2. 快速启动一个 CA server. 并获取一个可用的用户.

默认会自动注册用户 `dev`, 且输出 ta 的私钥.

```sh
# 该命令应该在 fabric 网络启动后再使用, 应为 CA server 需要获取 peer 的根 ca 作为自己的根 ca 使用.
./network.sh ca up
```

3. 快速安装并实例化你的 chaincode

```sh
# 复制你的 chaincode 项目至 chaincode 目录下
cp -r <YourChainCodePath> ./chaincode

# 初始化并安装 chaincode.
./code.sh <chaincodeName> <YourChainCodePathSimpleName>
# chaincodeName 你为 chaincode 起的名字, 默认值为 mycc
# YourChainCodePathSimpleName 是你的 chaincode 项目在 chaincode 目录下的相对路径, 默认值为 citybrain_cc
```

4. 使本地的 peer 进入 dev 模式

当 peer 进入 dev 模式, 你可以在本地启动 chaincode 项目, 以便调试.

在 dev 模式下, 你对 chaincode 修改后不需要 upgrade chaincode, 仅需重启本地的 chaincode 项目即可.

```sh
./network.sh dev
```

5. 收场

```sh
# 关闭 CA server
./network.sh ca down
# 关闭 fabric 网络, 清理资源
./network.sh down
```

## tips

1. `./code.sh` 在没有任何参数传入的情况下, 默认会安装 `./chaincode/citybrain` 路径下的 chaincode, 并命名为 `mycc`.
2. `./network.sh down` 默认会在关闭网络后自动清理 `mycc` 相关的 docker 镜像与容器, 如需手动清理, 可追加指定 chaincode 名在最后, 例: `./network.sh down mycc1`, 如此, 脚本会帮助你找出需要手动清理的 docker 镜像与容器.


