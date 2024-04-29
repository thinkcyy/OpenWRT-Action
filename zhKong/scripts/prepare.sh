cd openwrt

echo '当前执行步骤：执行custom_feeds'
chmod +x ../zhKong/scripts/*.sh
../zhKong/scripts/custom_feeds.sh

echo '当前执行步骤：导入编译配置'
cp -v ../zhKong/config/config-$ROUTER_MODEL.config .config

#Action使用
cp -v ../zhKong/config/config-$INPUT_ROUTER_MODEL.config .config

make defconfig
