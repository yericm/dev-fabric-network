#! /bin/bash

if [[ $1 == '' ]]; then
	chaincode_name=mycc
else
	chaincode_name=$1
fi

if [[ $2 == '' ]]; then
	#chaincode_path=citybrain_cc
	chaincode_path=java
else
	chaincode_path=$2
fi

export CHANNEL_ID=mychannel

export FABRIC_CFG_PATH=$PWD/peer0
export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=../fabricconfig/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

# 安装 chaincode
peer chaincode install -n $chaincode_name -v 1.0 -l java -p $PWD"/chaincode/"$chaincode_path

# 实例化 chaincode
peer chaincode instantiate -o orderer.example.com:7050 \
-C $CHANNEL_ID -n $chaincode_name -v 1.0 -l java -c '{"Args":[]}'

exit 0
###################### 
# 以下命令作为终端调用时的提醒, 并不执行. 
# 同时, 由于是非 tls 模式, 没有包含任何证书相关的参数.
# 仅在开发环境调试使用.

# 查询 / 尝试调用
peer chaincode query -C $CHANNEL_ID -n $chaincode_name -c '{"Args":["func","args"]}'

# 调用
peer chaincode invoke -o orderer.example.com:7050 \
-C $CHANNEL_ID -n $chaincode_name --peerAddresses peer0.org1.example.com:7051 \
-c '{"Args":["func","args"]}'

# 升级链码
peer chaincode install -n $chaincode_name -v 1.0.1 -l java -p $PWD"/chaincode/"$chaincode_path
peer chaincode upgrade -o orderer.example.com:7050 -C $CHANNEL_ID -n $chaincode_name -v 1.0.1 -l java -c '{"Args":[]}'
