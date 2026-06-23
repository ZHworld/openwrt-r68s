# 本地快速编译脚本（需要 Lima 或 Linux 环境）
# 用法: bash build.sh

set -e

# 配置
KERNEL_VER="${1:-6.12.y}"
OPENWRT_IP="${2:-192.168.20.1}"
WORK_DIR="$HOME/openwrt-build"
ROOTFS_DIR="$WORK_DIR/openwrt"
PACKIT_DIR="$WORK_DIR/openwrt_packit"

echo "=== 开始编译 R68S 固件 ==="
echo "内核版本: $KERNEL_VER"
echo "路由器 IP: $OPENWRT_IP"
echo "工作目录: $WORK_DIR"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 1. 克隆 LEDE
if [ ! -d "$ROOTFS_DIR" ]; then
    echo ">>> 克隆 LEDE 源码..."
    git clone --depth=1 https://github.com/coolsnowwolf/lede "$ROOTFS_DIR"
fi

# 2. 更新 feeds
cd "$ROOTFS_DIR"
./scripts/feeds update -a
./scripts/feeds install -a

# 3. 配置
cat > .config <<'EOF'
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_Default=y
CONFIG_TARGET_ROOTFS_TARGZ=y
CONFIG_BINARY_FOLDER="bin"
CONFIG_DOWNLOAD_FOLDER="dl"
CONFIG_CCACHE=y
CONFIG_LUCI_LANG_zh_Hans=y
EOF
make defconfig

# 4. 编译
echo ">>> 开始编译（这可能需要 2-4 小时）..."
make download -j$(nproc)
make -j$(nproc)

# 5. 查找 rootfs
ROOTFS=$(find bin/targets -name "*rootfs.tar.gz" | head -1)
echo ">>> Rootfs: $ROOTFS"

# 6. 克隆打包脚本
cd "$WORK_DIR"
if [ ! -d "$PACKIT_DIR" ]; then
    git clone --depth=1 https://github.com/unifreq/openwrt_packit.git "$PACKIT_DIR"
fi

# 7. 复制 rootfs
cp "$ROOTFS_DIR/$ROOTFS" "$PACKIT_DIR/"
cd "$PACKIT_DIR"

# 8. 下载内核（如果本地没有）
KERNEL_URL="https://github.com/breakingbadboy/OpenWrt/releases/download/kernel_stable"
for f in boot modules dtb-rockchip; do
    [ -f "${f}-${KERNEL_VER}.tar.gz" ] || \
        wget -q "$KERNEL_URL/${f}-${KERNEL_VER}.tar.gz" || true
done

# 9. 打包
export OPENWRT_IP="$OPENWRT_IP"
echo ">>> 执行 Flippy 打包..."
sudo bash mk_rk3568_r68s.sh

echo ">>> 固件生成在: $PACKIT_DIR/output/"
ls -lh output/
