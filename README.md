# 天门

借鉴 apisix 实现的轻量级网关服务


## 简介。

项目中参考和引用了[ws-cloud-gateway](https://github.com/tech-microworld/ws-cloud-gateway)和[apisix](https://github.com/apache/apisix)的源码。
对codo所使用的api网关进行优化

## 目录

- [特性](#特性)
- [文档](#文档)
- [立刻开始](#立刻开始)
- [性能测试](#性能测试)
- [社区](#社区)
- [视频和文章](#视频和文章)
- [全景图](#全景图)
- [贡献](#贡献)
- [致谢](#致谢)
- [协议](#协议)
-

## 特性

你可以当做流量入口，来处理所有的业务数据，包括动态路由、动态上游、动态证书、
A/B 测试、金丝雀发布(灰度发布)、蓝绿部署、限流限速、抵御恶意攻击、监控报警、服务可观测性、服务治理等。


<font size="3" color="#dd0000">插件文档待完善</font>

- **全平台**

  - 云原生: 平台无关，没有供应商锁定，无论裸机还是 Kubernetes，APISIX 都可以运行。
  - 运行环境: OpenResty
  -
- **多协议**
  - [gRPC 代理](doc/zh-cn/grpc-proxy.md)：通过 APISIX 代理 gRPC 连接，并使用 APISIX 的大部分特性管理你的 gRPC 服务。
  - [gRPC 协议转换](doc/zh-cn/plugins/grpc-transcode.md)：支持协议的转换，这样客户端可以通过 HTTP/JSON 来访问你的 gRPC API。
  - Websocket 代理
  - Proxy Protocol
  - HTTP(S) 反向代理
  - [SSL](doc/zh-cn/https.md)：动态加载 SSL 证书
  -
- **全动态能力**
- **精细化路由**
- **安全防护**
- **运维友好**
- **高度可扩展**

## 性能测试

## 文档
[文档索引](doc/README.md)

## 更新日志
[更新日志](doc/README.md)

## 立刻开始
### 编译和安装

准备在以下操作系统中可顺利安装并做过测试：

CentOS 7, Ubuntu 16.04, Ubuntu 18.04, Debian 9, Debian 10, macOS

有以下几种方式来安装Release 版本:

1. 源码编译（适用所有系统）
   - 安装运行时依赖：OpenResty 和 etcd，以及编译的依赖：luarocks。参考[依赖安装文档](https://github.com/apache/apisix/blob/master/doc/zh-cn/install-dependencies.md)

   - 下载最新的源码发布包：

     ```shell
     git clone  xxx.git
     ```



   - 编译部署

     ```shell
      $ cd  api-gateway
      # 安装运行时依赖的 Lua 库：
      $ make deps
      $ \cp -arp .
     /usr/local/openresty/nginx/
     ```



   - 启动 :
     ```shell
     $ /bin/systemctl start openresty.service
     ```
2. Docker 镜像（适用所有系统）

   默认会拉取最新的发布包：

   ```shell
   $ docker build . -t gateway_image
   $ docker-compose  up -d
   ```

### 针对开发者
> 开发者去看apisix的文档，写的比较完整

#### 检查
```
#安装
$ luarocks install luacheck
$ luacheck -q gateway
```

## 性能测试

### wrk 测试

```bash
# 安装wrk
$ git clone https://github.com/wg/wrk.git
$ cd wrk && make
$ cp wrk /bin/
$ sh benchmark/run-wrk.sh

```

### AB 测试

AB测试 1核心 RPS 14000  4核心24000 ，token和rbac验证RPS分别为 10000  24000

![1核心 无token](docs/images/abtest_1core.png)

![4核心 无token](./docs/images/abtest_4core.png)

![1核心 token鉴权](./docs/images/abtest_all_plugins_1core.png)

![4核心 token鉴权](./docs/images/abtest_all_plugins_4core.png)



## 整体架构


## 服务发现
服务启动时，将自己的节点信息注册到etcd，包括：服务名称、ip、端口

网关服务从 etcd 监听服务节点信息，保存到缓存中，从客户端请求的url中提取服务名称，通过服务名称查找节点信息，将请求转发到后端服务


## 插件功能列表

- [x] 服务发现，动态路由
- [x] 自动生成 requestId，方便链路跟踪
- [x] 控制面板
- [x] gRPC 代理
- [x] jwt  用户登录认证
- [x] rbac   用户登录认证鉴权
- [ ] 动态ip防火墙
- [x] 限流器
- [x] referer限制
- [x] IP黑白名单
- [x] cors跨域
- [ ] 接口协议加解密
- [ ] 统一配置管理
- [ ] 外部日志记录


##### 限流器
**属性**

 | 名称          | 类型    | 必选项 | 默认值 | 有效值                                                                   | 描述                                                                                                                                              |
 | ------------- | ------- | ------ | ------ | ------------------------------------------------------------------------ | ------------------------------------------------------------------- |
 | limit_req_rate | integer | 必须   |        | limit_req_rate > 0      | 指定的请求速率（以秒为单位），请求速率超过 `rate` 但没有超过 （`rate` + `brust`）的请求会被加上延时。                                             |
 | limit_req_burst| integer | 必须   |        | limit_req_burst >= 0    | 请求速率超过 （`rate` + `brust`）的请求会被直接拒绝。|

##### referer限制
**属性**

| 参数名    | 类型          | 可选项 | 默认值 | 有效值 | 描述                             |
| --------- | ------------- | ------ | ------ | ------ | -------------------------------- |
| referer_whitelist | array[string] | 必须    |         |       | 域名列表。域名开头可以用'*'作为通配符 |
| referer_bypass_missing  | boolean       | 可选    | false   |       | 当 Referer 不存在或格式有误时，是否绕过检查 |

##### IP黑白名单
`ip-restriction` 可以通过以下方式限制对服务或路线的访问，将 IP 地址列入白名单或黑名单。 单个 IP 地址，多个 IP 地址 或 CIDR 范围，可以使用类似 10.10.10.0/24 的 CIDR 表示法。

**属性**

| 参数名    | 类型          | 可选项 | 默认值 | 有效值 | 描述                             |
| --------- | ------------- | ------ | ------ | ------ | -------------------------------- |
| ip_whitelist | array[string] | 可选   |        |        | 加入白名单的 IP 地址或 CIDR 范围 |
| ip_blacklist | array[string] | 可选   |        |        | 加入黑名单的 IP 地址或 CIDR 范围 |

只能单独启用白名单或黑名单，两个不能一起使用。
详细参考文档和代码 `https://github.com/apache/apisix/edit/master/docs/zh/latest/plugins/ip-restriction.md`

##### cors跨域处理
**属性**

| 名称             | 类型    | 可选项 | 默认值 | 有效值 | 描述                                                         |
| ---------------- | ------- | ------ | ------ | ------ | ------------------------------------------------------------ |
| allow_origins    | string  | 可选   | "*"    |        | 允许跨域访问的 Origin，格式如：`scheme`://`host`:`port`，比如: https://somehost.com:8081 。多个值使用 `,` 分割，`allow_credential` 为 `false` 时可以使用 `*` 来表示所有 Origin 均允许通过。你也可以在启用了 `allow_credential` 后使用 `**` 强制允许所有 Origin 都通过，但请注意这样存在安全隐患。 |
| allow_methods    | string  | 可选   | "*"    |        | 允许跨域访问的 Method，比如: `GET`，`POST`等。多个值使用 `,` 分割，`allow_credential` 为 `false` 时可以使用 `*` 来表示所有 Origin 均允许通过。你也可以在启用了 `allow_credential` 后使用 `**` 强制允许所有 Method 都通过，但请注意这样存在安全隐患。 |
| allow_headers    | string  | 可选   | "*"    |        | 允许跨域访问时请求方携带哪些非 `CORS规范` 以外的 Header， 多个值使用 `,` 分割，`allow_credential` 为 `false` 时可以使用 `*` 来表示所 有 Header 均允许通过。你也可以在启用了 `allow_credential` 后使用 `**` 强制允许所有 Method 都通过，但请注意这样存在安全隐患。 |
| expose_headers   | string  | 可选   | "*"    |        | 允许跨域访问时响应方携带哪些非 `CORS规范` 以外的 Header， 多个值使用 `,` 分割。 |
| max_age          | integer | 可选   | 600    |        | 浏览器缓存 CORS 结果的最大时间，单位为秒，在这个时间范围内浏览器会复用上一次的检查结果，`-1` 表示不缓存。请注意各个浏览器允许的的最大时间不同，详情请参考 [MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age#Directives)。 |
| allow_credential | boolean | 可选   | false  |        | 是否允许跨域访问的请求方携带凭据（如 Cookie 等）。根据 CORS 规范，如果设置该选项为 `true`，那么将不能在其他选项中使用 `*`。 |

> **提示**
>
> 请注意 `allow_credential` 是一个很敏感的选项，谨慎选择开启。开启之后，其他参数默认的 `*` 将失效，你必须显式指定它们的值。
> 使用 `**` 时要充分理解它引入了一些安全隐患，比如 CSRF，所以确保这样的安全等级符合自己预期再使用。
参考文档和代码 `https://github.com/apache/apisix/blob/master/docs/zh/latest/plugins/cors.md`

## 鸣谢

- [ws-cloud-gateway](https://github.com/tech-microworld/ws-cloud-gateway)
- [apisix](https://github.com/apache/apisix)

## 协议

[GPL v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
