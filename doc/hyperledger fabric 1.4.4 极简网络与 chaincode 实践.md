# hyperledger fabric 1.4.4 极简网络与 chaincode 实践

## 目标

本地启动 fabric 的服务 (orderer, peer), 尽可能少地占用本机资源, 避免 docker 的使用

因为 chaincode 有两种运行模式 (dev, net), 前者不支持本地启动的 peer, 
所以配置中选择了 net 模式, 仅 chaincode instantiate 依旧需要 docker


## Crypto Generator (秘密文件生成器)

#### 即 完成 网络证书, 组织, 用户等相关文件的生成

```
target_hyperledger=/Users/gavinguan/Desktop/YQ_doc/hyperledger

cd $target_hyperledger

mkdir fabricconfig

cryptogen showtemplate > ./fabricconfig/crypto-config.yaml

#【action】编辑 crypto-config.yaml

# 网络证书, 组织, 用户等相关文件的生成
cryptogen generate --config=./fabricconfig/crypto-config.yaml --output=./fabricconfig/crypto-config
```


## Configuration Transaction Generator (配置事务生成器)

#### 即 完成 
#### - orderer 的 genesis block (创世纪块) 的生成
#### - channel 的 configuration transaction (初始块: 仅含有配置信息)
#### - peer 的 anchor peer transactions
#### configtx.yaml 的完整示例在 github.com/hyperledger/fabric/sampleconfig/configtx.yaml
#### 当前目录依旧是 $target_hyperledger, configtx.yaml 在当前目录

```
#【action】编辑 configtx.yaml

# 创世块的生成
mkdir channel-artifacts
export FABRIC_CFG_PATH=$PWD
export SYS_CHANNEL=sys-channel
configtxgen -profile TwoOrgOrderer -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block

# channel 初始块的生成
export CHANNEL_ID=channel0
configtxgen -profile TwoOrgChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_ID

# 机构锚点文件的生成
configtxgen -profile TwoOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_ID -asOrg Org1MSP
configtxgen -profile TwoOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_ID -asOrg Org2MSP
```


## hosts 域名映射的修改

虽然我在生成网络文件时定义了两个 Org, 各两个 peer, 
但在实践中发现, 只要 channel (可理解为私有网 或 私有账本) 中有一个 peer 正常运行, 
便可实践 chaincode 的整个生命周期

随后 orderer, peer 会启动在本地(宿主机), chaincode 运行在 docker
为了 chaincode 实例可以访问 peer, peer 的域名配置为本机 ip, 
例如这里的 192.168.1.8


```
127.0.0.1 orderer.gavin.com
192.168.1.8 peer0.org1.gavin.com

# 其实仅上面两个域名映射有用到
192.168.1.8 peer1.org1.gavin.com
192.168.1.8 peer0.org2.gavin.com
192.168.1.8 peer1.org2.gavin.com
```



## Orderer 的启动

#### orderer.yaml 的完整示例在 github.com/hyperledger/fabric/sampleconfig/orderer.yaml
#### 当前目录依旧是 $target_hyperledger, orderer.yaml 在当前目录

```
#【action】编辑 orderer.yaml

# 启动 orderer
export FABRIC_CFG_PATH=$PWD
nohup orderer start >> ./orderer.log 2>&1 &
```


## Peer 的启动
#### core.yaml 的完整示例在 github.com/hyperledger/fabric/sampleconfig/core.yaml
#### peer 默认使用内置的 levelDB, 一台机器仅可启动一个 peer, 除非使用 docker

```
mkdir org1peer0 && cd org1peer0
export FABRIC_CFG_PATH=$PWD
nohup peer node start >> peer.log 2>&1 &
```


## 创建 channel
#### 当前目录是 $target_hyperledger/org1peer0

```
export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.gavin.com/users/Admin@org1.gavin.com/msp

# 创建 channel
export CHANNEL_ID=channel0
peer channel create -o orderer.gavin.com:7050 -c $CHANNEL_ID -f ../channel-artifacts/channel.tx
```


## 让运行的 peer 加入 channel
#### 当前目录是 $target_hyperledger/org1peer0

```
export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.gavin.com/users/Admin@org1.gavin.com/msp
export CORE_PEER_ADDRESS=peer0.org1.gavin.com:7051

# 加入 channel
peer channel join -b channel0.block
```


## 更新锚点
#### 当前目录是 $target_hyperledger/org1peer0

```
export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.gavin.com/users/Admin@org1.gavin.com/msp
export CORE_PEER_ADDRESS=peer0.org1.gavin.com:7051

# 更新锚点 
export CHANNEL_ID=channel0
# 这里本来要用 tls, 即下方命令追加两个参数: --tls --cafile ../fabricconfig/crypto-config/ordererOrganizations/gavin.com/orderers/orderer.gavin.com/msp/tlscacerts/tlsca.gavin.com-cert.pem
# 我暂时不知道为什么用了证书选项会报错
peer channel update -o orderer.gavin.com:7050 -c $CHANNEL_ID -f ../channel-artifacts/Org1MSPanchors.tx
```


## 使用 chaincode
#### 在另一个终端中, 切换当前目录为 $GOPATH/sacc, 如不存在自行创建

在 $GOPATH/sacc 下创建 sacc.go, 内容如下
这是官方文档提供的示例, 流程就是设一个值的初始值为 10, 然后修改为 20, 最后查询一下, 确认该值修改为 20


```golang
package main

import (
    "fmt"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    "github.com/hyperledger/fabric/protos/peer"
)

// SimpleAsset implements a simple chaincode to manage an asset
type SimpleAsset struct {
}

// Init is called during chaincode instantiation to initialize any
// data. Note that chaincode upgrade also calls this function to reset
// or to migrate data.
func (t *SimpleAsset) Init(stub shim.ChaincodeStubInterface) peer.Response {
    // Get the args from the transaction proposal
    args := stub.GetStringArgs()
    if len(args) != 2 {
            return shim.Error("Incorrect arguments. Expecting a key and a value")
    }

    // Set up any variables or assets here by calling stub.PutState()

    // We store the key and the value on the ledger
    err := stub.PutState(args[0], []byte(args[1]))
    if err != nil {
            return shim.Error(fmt.Sprintf("Failed to create asset: %s", args[0]))
    }
    return shim.Success(nil)
}

// Invoke is called per transaction on the chaincode. Each transaction is
// either a 'get' or a 'set' on the asset created by Init function. The Set
// method may create a new asset by specifying a new key-value pair.
func (t *SimpleAsset) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
    // Extract the function and args from the transaction proposal
    fn, args := stub.GetFunctionAndParameters()

    var result string
    var err error
    if fn == "set" {
            result, err = set(stub, args)
    } else { // assume 'get' even if fn is nil
            result, err = get(stub, args)
    }
    if err != nil {
            return shim.Error(err.Error())
    }

    // Return the result as success payload
    return shim.Success([]byte(result))
}

// Set stores the asset (both key and value) on the ledger. If the key exists,
// it will override the value with the new one
func set(stub shim.ChaincodeStubInterface, args []string) (string, error) {
    if len(args) != 2 {
            return "", fmt.Errorf("Incorrect arguments. Expecting a key and a value")
    }

    err := stub.PutState(args[0], []byte(args[1]))
    if err != nil {
            return "", fmt.Errorf("Failed to set asset: %s", args[0])
    }
    return args[1], nil
}

// Get returns the value of the specified asset key
func get(stub shim.ChaincodeStubInterface, args []string) (string, error) {
    if len(args) != 1 {
            return "", fmt.Errorf("Incorrect arguments. Expecting a key")
    }

    value, err := stub.GetState(args[0])
    if err != nil {
            return "", fmt.Errorf("Failed to get asset: %s with error: %s", args[0], err)
    }
    if value == nil {
            return "", fmt.Errorf("Asset not found: %s", args[0])
    }
    return string(value), nil
}

// main function starts up the chaincode in the container during instantiate
func main() {
    if err := shim.Start(new(SimpleAsset)); err != nil {
            fmt.Printf("Error starting SimpleAsset chaincode: %s", err)
    }
}
```

然后回到之前的终端, 逐行执行验证 chaincode 的前几个生命周期中的状态即可.

```
export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.gavin.com/users/Admin@org1.gavin.com/msp
export CORE_PEER_ADDRESS=peer0.org1.gavin.com:7051

# sacc 是 $GOPATH/src/sacc, 这里默认语言是 golang, 所以按照 golang 的 import 习惯就是 sacc
peer chaincode install -n mycc -v 0 -p sacc
# channel0 就是上文中的 channelID
peer chaincode instantiate -n mycc -v 0 -c '{"Args":["a","10"]}' -C channel0
peer chaincode invoke -n mycc -c '{"Args":["set", "a", "20"]}' -C channel0
peer chaincode query -n mycc -c '{"Args":["query","a"]}' -C channel0
```









