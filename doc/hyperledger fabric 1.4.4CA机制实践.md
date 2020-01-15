[参考](https://blog.csdn.net/mellymengyan/article/details/80765385)

## 命令编译

首先是 fabric-ca-server fabric-ca-client 的编译，golang 编译过程跳过
然后 cd 至一个空的文件夹，本例为 $FABRIC_CA

```
export FABRIC_CA=$PWD
```

## 启动 CA Server
尝试启动 CA server

`nohup fabric-ca-server start -b admin:123456 > server.log 2>&1 &`

这里的 `-b` 是用作指定管理员用户名与密码

这里注意一点，如果有报错

```
dyld: malformed mach-o image: segment __DWARF has vmsize < filesize
```

需要重新编译 fabric-ca-server fabric-ca-client，使用 `go build -ldflags "-w"` 替换 `go build`

## 启动client然后生成管理员的证书和私钥

```
export FABRIC_CA_CLIENT_HOME=$FABRIC_CA/ca
fabric-ca-client enroll -u http://admin:123456@localhost:7054
```

## 用管理员身份签其他用户

以下命令中的参数随后会解释，先执行命令即可

以管理员身份注册一个用户，用户名为 dev，归属于联盟 org1.department1，且附加一些参数

```
# 注册在录 register
fabric-ca-client register --id.name dev --id.type user --id.affiliation org1.department1 --id.attrs 'hf.Revoker=true,foo=bar'

### 如果成功会输出密码
Password: iGKHFFcwdTNc
```

为该用户生成 msp

```

# 使用密码执行 enroll命令，生成该用户的 msp(含证书与私钥)
fabric-ca-client enroll -u http://dev:iGKHFFcwdTNc@localhost:7054 -M $FABRIC_CA_CLIENT_HOME/dev_msp
```

至此，名为 dev 的用户签署完毕，相关文件在 dev_msp 目录下

参数说明

`--id.affiliation`
配置信息在 fabric-ca-server-config.yaml 的 affiliation 下
用于表示这个联盟有哪些 org，每个 org 下有哪些 affiliation
这些信息可以在 server 运行时执行 `fabric-ca-client affiliation list` 来查看

`--id.attrs`
即，生成的 CA 证书中应该包含的一些附属信息（完全可以自定义），其中 `hf` 作为前缀的是 fabric 相关信息
表示的是用户是否拥有相关的权限:

```
      hf.Registrar.Roles该用户可以增加的新用户类型，用户类型都有：client、orderer、peer、user。

      hf.Registrar.DelegateRoles该用户可以设置的新用户的hf.Registrar.Roles属性。

      hf.Registrar.Attributes该用户可以为新用户设置的保留属性和自定义属性。

      hf.GenCRL该用户是否可以获取CRL列表，已经撤销的证书列表。

      hf.Revoker该用户是否能够撤销其它用户。

      hf.AffiliationMgr该用户是否可以管理联盟。

      hf.IntermediateCA该用户是否可以作为中间CA。
```


