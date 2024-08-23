# for coolsnowwolf/openwrt



./scripts/feeds update -a

../scripts/add_package_common.sh

mkdir -p ./package/thinkcy
cp -r ../thinkcy-settings ./package/thinkcy 

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init

echo '-步骤：custom_feed-移除frp日志'      
sed -i '/Starting frp service/d' ./feeds/luci/applications/luci-app-frpc/root/etc/init.d/frp
sed -i '/Shutting down frp service/d' ./feeds/luci/applications/luci-app-frpc/root/etc/init.d/frp

./scripts/feeds install -a



echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
#echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../${REPO_TYPE}/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
