# for coolsnowwolf/openwrt

../scripts/add_package_common.sh

./scripts/feeds update -a

mkdir -p ./package/thinkcy
cp -r ../thinkcy-settings ./package/thinkcy 

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init

./scripts/feeds install -a

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
#echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../${REPO_TYPE}/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
