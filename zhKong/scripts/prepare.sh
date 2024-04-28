cd openwrt

echo "添加软件包"
chmod +x ../zhKong/scripts/*.sh
../zhKong/scripts/custom_feeds.sh

echo "导入编译配置"
cp -v ../zhKong/config/config-$ROUTER_MODEL.config .config
make defconfig
