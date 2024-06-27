cd openwrt

echo '当前执行步骤：2.1-执行custom_feeds'
chmod +x ../zhKong/scripts/*.sh
echo "custom_feeds内容"
cat ../zhKong/scripts/custom_feeds.sh
../zhKong/scripts/custom_feeds.sh

echo '当前执行步骤：2.2-导入编译配置'
echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

#Action使用
cp -v ../zhKong/config/config-${INPUT_ROUTER_MODEL}.config .config

echo '当前执行步骤：2.3-初始化编译配置defconfig'
make defconfig
