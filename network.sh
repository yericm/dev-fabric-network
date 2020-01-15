#! /bin/bash

function ok() {
	echo -e "\033[32m[OK] $1\033[0m"
}

function err() {
	echo -e "\033[31m[ERROR] $1\033[0m"
}

function checkCmd() {
    type $1 >/dev/null 2>&1 || { echo -e >&2 "\033[31m[Missing] $1. Please install $1 first, Aborting.\033[0m"; exit 1; }
    ok "$1"
    sleep 0.1
}



##### main #####

# TODO: 可优化为 -c
export CHANNEL_ID=mychannel

cmd=$1

if [[ $cmd == '' || $cmd == '-h' || $cmd == '--help' ]]; then
	echo "network.sh <cmd>"
	echo "    cmd:"
	echo "        up ------- to start this fabric network"
	echo "        down ----- to stop this fabric network"
	echo "        dev ------ peer dev mode"
	echo "        ca up ---- start CA server"
	echo "        ca down -- start CA server"
fi

if [[ $cmd == 'up' ]]; then
	# 环境检查
	echo ""
	echo -e "\033[35mPlease add the following domain name to the <hosts> file of this machine.\033[0m"
	echo "127.0.0.1 orderer.example.com"
	echo "<YourIP> peer0.org1.example.com"
	echo ""
	read -p "I have configured them (y/N):" ans
	if [[ $ans != 'y' && $ans != 'Y' ]]; then
		echo "Aborting."
		exit 0
	fi

	echo "Checking your environment..."

	checkCmd docker
	checkCmd docker-compose
	checkCmd cryptogen
	checkCmd configtxgen
	checkCmd orderer
	checkCmd peer
	echo ""

	# 清空旧证书 (基础网络, 组织, 用户), 并生成新证书
	rm -rf ./fabricconfig/crypto-config/*
	cryptogen generate --config=./fabricconfig/crypto-config.yaml --output=./fabricconfig/crypto-config
	ok "generated files in <crypto-config>."
	sleep 0.3
	# 清空旧 channel 相关创世文件 (创世块 genesis.block, 通道初始块 channel.tx, 锚点)
	rm -rf ./channel-artifacts/*
	export FABRIC_CFG_PATH=$PWD/fabricconfig
	export SYS_CHANNEL=sys-channel
	configtxgen -profile OneOrgOrderer -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block >/dev/null 2>&1
	configtxgen -profile OneOrgChannel -outputCreateChannelTx ./channel-artifacts/$CHANNEL_ID.tx -channelID $CHANNEL_ID >/dev/null 2>&1
	configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_ID -asOrg Org1MSP >/dev/null 2>&1
	ok "generated files in <channel-artifacts>."
	sleep 0.3
	# 清空旧 orderer 文件与进程, 启动 orderer
	ordererPid=`ps aux | grep -v grep | grep "orderer start" | awk '{print $2}'`
	if [[ $ordererPid != '' ]]; then
		kill -9 $ordererPid
		sleep 0.2
	fi
	rm -rf ./orderer/production/*
	export FABRIC_CFG_PATH=$PWD/orderer
	nohup orderer start > ./orderer/orderer.log 2>&1 &
	sleep 0.3
	ordererPid=`ps aux | grep -v grep | grep "orderer start" | awk '{print $2}'`
	if [[ $ordererPid != '' ]]; then
		ok "$ordererPid - orderer is started."
	else
		err "failed to start orderer."
		exit 1
	fi
	# 启动 peer, 且使用 couchdb
	my_couchdb_id=`docker ps -a | grep my-couchdb-for-peer0 | awk '{print $1}'`
	if [[ $my_couchdb_id != '' ]]; then
		{
			docker kill $my_couchdb_id
		}
		{
			docker rm $my_couchdb_id
		}
	fi
	nohup docker-compose -f ./peer0/couchdb.yaml up > /dev/null 2>&1 &
	sleep 2
	my_couchdb_id=`docker ps -a | grep my-couchdb-for-peer0 | awk '{print $1}'`
	if [[ $my_couchdb_id != '' ]]; then
		ok "$my_couchdb_id - couchdb is started."
	else
		err "failed to start couchdb."
		exit 1
	fi
	peerPid=`ps aux | grep -v grep | grep "peer node start" | awk '{print $2}'`
	if [[ $peerPid != '' ]]; then
		kill -9 $peerPid
		sleep 0.2
	fi
	export FABRIC_CFG_PATH=$PWD/peer0
	nohup peer node start >> ./peer0/peer.log 2>&1 &
	sleep 0.3
	peerPid=`ps aux | grep -v grep | grep "peer node start" | awk '{print $2}'`
	if [[ $peerPid != '' ]]; then
		ok "$peerPid - peer is started."
	else
		err "failed to start peer."
		exit 1
	fi
	# 创建 channel, 并让 peer0 加入 channel, 且成为锚节点
	sleep 2
	export FABRIC_CFG_PATH=$PWD/peer0
	export CORE_PEER_LOCALMSPID=Org1MSP
	export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
	cd ./peer0
	peer channel create -o orderer.example.com:7050 -c $CHANNEL_ID -f ../channel-artifacts/$CHANNEL_ID.tx
	#peer channel create -o orderer.example.com:7050 -c $CHANNEL_ID -f ../channel-artifacts/$CHANNEL_ID.tx \
	#--tls --cafile ../fabricconfig/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
	if [[ $? == 0 ]]; then
		ok "channel<$CHANNEL_ID> is created."
		cd ..
	else
		exit 1
	fi
	#----
	export FABRIC_CFG_PATH=$PWD/peer0
	export CORE_PEER_LOCALMSPID=Org1MSP
	export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
	export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
	cd ./peer0
	peer channel join -b $CHANNEL_ID.block
	#peer channel join -b $CHANNEL_ID.block \
	#--tls --cafile ../fabricconfig/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
	if [[ $? == 0 ]]; then
		ok "peer0 has joined channel<$CHANNEL_ID>."
		cd ..
	else
		exit 1
	fi
	#----
	export FABRIC_CFG_PATH=$PWD/peer0
	export CORE_PEER_LOCALMSPID=Org1MSP
	export CORE_PEER_MSPCONFIGPATH=../fabricconfig/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
	export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
	peer channel update -o orderer.example.com:7050 -c $CHANNEL_ID -f ./channel-artifacts/Org1MSPanchors.tx
	#peer channel update -o orderer.example.com:7050 -c $CHANNEL_ID -f ./channel-artifacts/Org1MSPanchors.tx \
	#--tls --cafile ../fabricconfig/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
	if [[ $? == 0 ]]; then
		ok "anchor peer is updated."
	fi

	ok "Now, you can install your chaincode and call it."
fi

if [[ $cmd == 'down' ]]; then

	echo "Checking your environment..."

	checkCmd docker
	echo ""

	if [[ $2 == '' ]]; then
		chaincode_name=mycc
	else
		chaincode_name=$2	
	fi
	
	read -p "I am sure to stop this network (y/N):" ans
	if [[ $ans != 'y' && $ans != 'Y' ]]; then
		echo "Aborting."
		exit 0
	fi

	peerPid=`ps aux | grep -v grep | grep "peer node start" | awk '{print $2}'`
	if [[ $peerPid != '' ]]; then
		kill -9 $peerPid
		sleep 0.1
		rm -rf ./peer0/peer.log ./peer0/mychannel.block
	fi
	ok "peer is killed."

	my_couchdb_id=`docker ps -a | grep my-couchdb-for-peer0 | awk '{print $1}'`
	if [[ $my_couchdb_id != '' ]]; then
		{
			docker kill $my_couchdb_id
		}
		{
			docker rm $my_couchdb_id
		}
	fi
	ok "couchdb is killed."

	ordererPid=`ps aux | grep -v grep | grep "orderer start" | awk '{print $2}'`
	if [[ $ordererPid != '' ]]; then
		kill -9 $ordererPid
		sleep 0.1
		rm -rf ./orderer/production/* ./orderer/orderer.log
	fi
	ok "orderer is killed."
	rm -rf ./channel-artifacts/*
	ok "<channel-artifacts> is clear."
	rm -rf ./fabricconfig/crypto-config/*
	ok "<crypto-config> is clear."

	if [[ $chaincode_name != '' ]]; then
		echo "################################################"
		echo ""
		echo "You may need to clean these manually."
		echo "------------------------------------------------"
		echo "docker containers:"
		echo "ID           Image"
		docker ps -a --format "{{.ID}} {{.Image}}" | grep peer0.networkid | grep $chaincode_name
		echo "------------------------------------------------"
		echo "docker images:"
		echo "ID           Repository"
		docker images --format "{{.ID}} {{.Repository}}" | grep peer0.networkid | grep $chaincode_name
		if [[ $chaincode_name == "mycc" ]]; then
			echo "auto kill containers..."
			{
				docker ps -a --format "{{.ID}} {{.Image}}" | grep peer0.networkid | grep $chaincode_name | awk '{print $1}' | xargs docker kill
			}
			echo "auto remove containers..."
			{
				docker ps -a --format "{{.ID}} {{.Image}}" | grep peer0.networkid | grep $chaincode_name | awk '{print $1}' | xargs docker rm
			}
			echo "auto remove images..."
			{
				docker images --format "{{.ID}} {{.Repository}}" | grep peer0.networkid | grep $chaincode_name | awk '{print $1}' | xargs docker rmi
			}
			ok "docker environment has been cleaned up."
		fi
	fi
fi

if [[ $cmd == 'dev' ]]; then

	echo "Checking your environment..."

	checkCmd docker
	checkCmd peer
	echo ""

	chaincode_name=$2
	chaincode_version=$3
	# 关闭 chaincode 容器, 以便本地 IDE 可以启动 chaincode.
	container_id=`docker ps --format "{{.ID}} {{.Image}}" | grep peer0.networkid | grep ${chaincode_name}-${chaincode_version} | awk '{print $1}'`
	if [[ $container_id != '' ]]; then
		docker kill $container_id
		ok "${container_id} - docker container is killed."
	fi
	# 重启 peer 到 dev 模式
	peerPid=`ps aux | grep -v grep | grep "peer node start" | awk '{print $2}'`
	if [[ $peerPid == '' ]]; then
		echo "peer is not running."
		exit 0
	else
		kill $peerPid
		sleep 0.2
		export FABRIC_CFG_PATH=$PWD/peer0
		nohup peer node start --peer-chaincodedev >> ./peer0/peer.log 2>&1 &
		sleep 0.3
		peerPid=`ps aux | grep -v grep | grep "peer node start" | awk '{print $2}'`
		if [[ $peerPid != '' ]]; then
			ok "$peerPid - peer is started by 'dev' mode."
			echo ""
			echo "Now, you can run your chaincode in IDE with 'debug' mode."
		else
			err "failed to start peer."
			exit 1
		fi
	fi
fi
#############################################################################
################################## CA Server ################################
#############################################################################
#############################################################################
if [[ $cmd == 'ca' ]]; then
	# 环境检查
	echo "Checking your environment..."
	
	checkCmd docker
	checkCmd docker-compose

	ca_cmd=$2
	if [[ $ca_cmd == 'down' ]]; then
		# 尝试清除旧容器
		my_ca_id=`docker ps -a | grep my-ca | awk '{print $1}'`
		if [[ $my_ca_id != '' ]]; then
			{
				docker kill $my_ca_id
			}
			{
				docker rm $my_ca_id
			}
		fi
		# 清除旧文件
		rm -rf ./fabric-ca/server.log
		rm -rf ./fabric-ca/fabric-ca-server/*
		exit 0
	elif [[ $ca_cmd == 'up' ]]; then
		cp ./fabricconfig/crypto-config/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem ./fabric-ca/fabric-ca-server/peer.rootCA.pem
		cp ./fabricconfig/crypto-config/peerOrganizations/org1.example.com/ca/`ls ./fabricconfig/crypto-config/peerOrganizations/org1.example.com/ca | grep _sk` ./fabric-ca/fabric-ca-server/priKey
		cd ./fabric-ca
		nohup docker-compose -f docker-compose.yaml up > ./server.log 2>&1 &
		sleep 2
		# enroll admin
		FABRIC_CA_CLIENT_HOME=$PWD/fabric-ca-server/ca/admin fabric-ca-client enroll -u http://admin:adminpw@localhost:7054 > /dev/null 2>&1 
		sleep 0.2
		# register for dev
		user_name=dev
		dev_info=`FABRIC_CA_CLIENT_HOME=$PWD/fabric-ca-server/ca/admin fabric-ca-client register --id.name $user_name --id.type user --id.affiliation org1.department1 --id.attrs 'hf.Revoker=true,gavin=666'`
		echo "user: $user_name, "$dev_info
		dev_priKey=`echo $dev_info | awk '{print $2}'`
		# enroll dev, 参数 '-M' 的当前路径是参考 FABRIC_CA_CLIENT_HOME 的
		FABRIC_CA_CLIENT_HOME=$PWD/fabric-ca-server/ca/dev fabric-ca-client enroll -u "http://dev:${dev_priKey}@localhost:7054" -M ./ > /dev/null 2>&1 
		if [[ $? == 0 ]]; then
			ok "$user_name is registed."
		else
			err "Something is wrong."
		fi
		exit 0
	fi
	echo "$0 ca up/down"
fi
