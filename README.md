# R68S OpenWrt 固件编译

FastRhino R68S 路由器自编译 OpenWrt 固件，基于 Lean LEDE + Flippy 打包。

## 使用方法

### 第一次使用

1. **Fork 或 Push 到你的 GitHub**
2. 在 GitHub 仓库页面点击 **Actions** → **编译 R68S OpenWrt 固件** → **Run workflow**
3. 填写参数后点击绿色按钮
4. 等待约 30-60 分钟，编译完成后在 Actions 页面下载 `.img.gz` 固件

### 输入参数

| 参数 | 说明 | 默认值 |
|:--|:--|:--|
| `kernel_version` | 内核版本 | `6.12.y` |
| `openwrt_ip` | 路由器 IP | `192.168.20.1` |
| `custom_packages` | 额外安装的包 | (空) |

### 刷机方法

```bash
# 方法一：远程升级（推荐，保留配置）
# 1. 下载固件到你的电脑
# 2. 解压得到 .img 文件
# 3. SCP 传到路由器
scp openwrt_rk3568_r68s_xxx.img root@192.168.20.1:/tmp/

# 4. SSH 到路由器执行升级
ssh root@192.168.20.1
openwrt-update-rockchip /tmp/openwrt_rk3568_r68s_xxx.img
# 输入 y 保留配置 → 自动重启 ✅
```

## 技术栈

- **OpenWrt 源码**: [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- **打包工具**: [unifreq/openwrt_packit](https://github.com/unifreq/openwrt_packit)
- **GitHub Action**: [ophub/flippy-openwrt-actions](https://github.com/ophub/flippy-openwrt-actions)
