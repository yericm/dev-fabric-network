# dev-fabric-network 使用与 chaincode 的 Debug 模式

为了快速开发 chaincode, 同时快速重现 fabric 配置对这个网络的影响, 这里提供了dev-fabric-network.

启动时, 仅一个 Org, 一个 peer, 一个 orderer. 由于这里的 peer 使用了内置的 levelDB, 所以如果需要 CA server, 需要启动在 docker 中.

### 前置条件

你本机已经有 peer、orderer 等 fabric 可执行的二进制文件, 同时有安装并已经启动 docker.

## 启动网络

脚本会提醒你需要修改本机的 `hosts` 文件

```sh
./network.sh up
```
### 快速安装并实例化 chaincode

`code.sh`中关于 `install`, `instantiate` 部分需要自行调整, `install` 时, `-p` 最好给绝对路径.

在 `exit 0` 后面的命令, 永不运行, 作为在命令行中的提示(`cat code.sh`).

这里给`code.sh`一个参数 chaincode-name

```sh
./code.sh <chaincode-name>
```

### 使 peer 进入 dev 模式

这里注意, 需要先**安装并实例化** chaincode, 才可使用 dev 模式来 debug.

```sh
./network.sh dev
```

然后在 IDEA 中按以下格式配置 chaincode 主类的运行参数即可

```
CORE_PEER_ADDRESS=127.0.0.1:7051
CORE_CHAINCODE_ID_NAME=mycc:1.0
CORE_CHAINCODE_LOGGING_LEVEL=debug
CORE_CHAINCODE_LOGGING_SHIM=debug

以上数行, 用英文分号连接为一行, 写入 `environment variables` 即可.
以下一行, 写入 `Program arguments` 即可.
如果有问题, 将本地回环ip改为内网的ip

-peer.address=127.0.0.1:7052
```

### 关闭并清理该网络

这里 chaincode-name 选填, 如果有该参数, 脚本会自行帮助使用者找出之前使用到的docker 镜像和容器, 方便清理

```sh
./network.sh down [chaincode-name]
```
