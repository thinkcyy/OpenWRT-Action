echo '-步骤：custom_feed-更新 Feeds'

./scripts/feeds update -a
./scripts/feeds install -a


echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-Action导入编译配置'
cp -v ../zhKong/config/config-${INPUT_ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
