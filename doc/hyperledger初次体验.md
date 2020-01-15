# yperledger 快速上手 (*nix 环境)

为了节约你的时间, 请直接跟随本文的步骤走即可.

## 下载与搭建环境

键入以下命名至终端.

```
mkdir -p $GOPATH/src/github.com/hyperledger
cd $GOPATH/src/github.com/hyperledger
git clone https://github.com/hyperledger/fabric.git

# 官方提供的快速搭建环境的脚本
bash fabric/scripts/bootstrap.sh
```

这里 docker 镜像较大, 如果没有私服, 可能需要下载 2 个小时左右.
建议先阅读[官网 1.4 版本入门指导][3]

镜像拉取完成之后, 可见拉取的镜像列表

```
===> List out hyperledger docker images
hyperledger/fabric-javaenv     1.4.4               4648059d209e        13 days ago         1.7GB
hyperledger/fabric-javaenv     latest              4648059d209e        13 days ago         1.7GB
hyperledger/fabric-ca          1.4.4               62a60c5459ae        13 days ago         150MB
hyperledger/fabric-ca          latest              62a60c5459ae        13 days ago         150MB
hyperledger/fabric-tools       1.4.4               7552e1968c0b        2 weeks ago         1.49GB
hyperledger/fabric-tools       latest              7552e1968c0b        2 weeks ago         1.49GB
hyperledger/fabric-ccenv       1.4.4               ca4780293e4c        2 weeks ago         1.37GB
hyperledger/fabric-ccenv       latest              ca4780293e4c        2 weeks ago         1.37GB
hyperledger/fabric-orderer     1.4.4               dbc9f65443aa        2 weeks ago         120MB
hyperledger/fabric-orderer     latest              dbc9f65443aa        2 weeks ago         120MB
hyperledger/fabric-peer        1.4.4               9756aed98c6b        2 weeks ago         128MB
hyperledger/fabric-peer        latest              9756aed98c6b        2 weeks ago         128MB
hyperledger/fabric-zookeeper   0.4.18              ede9389347db        3 weeks ago         276MB
hyperledger/fabric-zookeeper   latest              ede9389347db        3 weeks ago         276MB
hyperledger/fabric-kafka       0.4.18              caaae0474ef2        3 weeks ago         270MB
hyperledger/fabric-kafka       latest              caaae0474ef2        3 weeks ago         270MB
hyperledger/fabric-couchdb     0.4.18              d369d4eaa0fd        3 weeks ago         261MB
hyperledger/fabric-couchdb     latest              d369d4eaa0fd        3 weeks ago         261MB
```

## 按照[官网 1.4 版本入门指导][3]试用

```
# 生成网络文件
./byfn.sh generate
# 启动 (golang 是默认选项)
./byfn.sh up [-l golang/node/java]
# 停止
./byfn.sh down
```


# 参考资料

[官方项目地址][1]
[概念与架构详解][2]
[官网 1.4 版本入门指导][3]

[1]: https://github.com/hyperledger/fabric
[2]: https://blog.csdn.net/russell_tao/article/details/80459698
[3]: https://hyperledger-fabric.readthedocs.io/en/release-1.4/build_network.html