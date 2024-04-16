cd openwrt

# 添加包
chmod +x ../zhKong/scripts/*.sh
../zhKong/scripts/custom_feeds.sh

# config file
cp -v ../zhKong/config/config-AX6.config .config
make defconfig
