cd openwrt

echo '当前执行步骤：添加软件包'
chmod +x ../zhKong/scripts/*.sh
../zhKong/scripts/custom_feeds.sh

echo '当前执行步骤：导入编译配置'
cp -v ../zhKong/config/config-$ROUTER_MODEL.config .config
make defconfig
