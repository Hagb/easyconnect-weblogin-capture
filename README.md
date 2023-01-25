# easyconnect weblogin capture

本仓库包含了一些实用程序，用于捕获 EasyConnect 的登录过程以及给出登录时产生的 twfId（用于建立 VPN 隧道的认证凭据）。使用 [EasierConnect](https://github.com/lyc8503/EasierConnect)（一个自由/开源的 EasyConnect 客户端）可以以 twfId 为凭据登录 VPN。

## 用法

原理是对进行服务器进行反向代理，之后：

- 使用 EasyConnect 客户端时用反代地址替代原服务器地址，或者
- 在本地运行 EasyConnect 服务，并用浏览器访问 `https://反代地址/por/login_psw.csp` 进行网页登录。

目前有基于 [socat](http://www.dest-unreach.org/socat/)+shell 以及基于 [mitmproxy](https://github.com/mitmproxy/mitmproxy) 的方式：前者仅依赖 socat 和一些常用的 \*nix 命令；后者依赖较多，但功能较多、使用较为灵活。

### 基于 socat

在某种 \*nix shell 中运行如下命令（其中证书可以使用自签名证书，EasyConnect 客户端似乎并不验证）

```bash
export cert=证书路径
hostname=服务器域名或IP port=服务器HTTPS端口 socat ssl-l:反代的端口,reuseaddr,fork,cert="$cert",verify=0 exec:./socat-filter.sh
```

捕获到 twfId 时会输出

```
TWFID has been captured: xxxxxx
Interrupt the connection!
```

此外，可以给 socat 加上 `-v` 参数来输出请求细节，之后可重定向到某个日志文件 `login.log`：

```bash
export cert=证书路径
hostname=服务器域名或IP port=服务器HTTPS端口 socat -v ssl-l:反代服务的端口,reuseaddr,fork,cert="$cert",verify=0 exec:./socat-filter.sh 2>&1 | tee login.log
```

### 基于 mitmproxy

若未安装 mitmproxy，则请先使用以下命令安装 mitmproxy

```bash
pip install mitmproxy
```

之后运行

```bash
mitmdump -m 'reverse:https://服务器HTTPS地址' --ssl-insecure -p 反代服务的端口 -s mitmproxy-addon.py
```

捕获到 twfId 时输出与上面基于 socat 的方式一样。

此外，可以给 mitmdump 加上 `--flow-detail 4` 参数来输出请求细节，之后可重定向到某个日志文件 `login.log`：

```bash
mitmdump -m 'reverse:https://服务器HTTPS地址' --ssl-insecure -p 反代服务的端口 -s mitmproxy-addon.py --flow-detail 4 | tee login.log
```

## TODO

- [ ] **无需特权的情况下使用 EasyConnect Linux 版相关组件完成 web 登录过程的轻量级方案**
- [ ] 捕获 VPN 隧道

## LICENSE

[MIT](./LICENSE)
