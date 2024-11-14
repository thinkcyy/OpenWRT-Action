echo '-步骤：custom_feed-更新 Feeds'

./scripts/feeds update -a

mkdir -p package/thinkcy
echo '-步骤：custom_feed-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt  zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/thinkcy/

echo '-步骤：custom_feed-添加lean的luci仓库'
git clone https://github.com/coolsnowwolf/luci cus_lean_luci
cp -r ./cus_lean_luci/applications/luci-app-turboacc package/thinkcy/

./scripts/feeds install -a

sed -i "s|option lang auto|option lang \'zh_cn\'|g" ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option zh_cn chinese' ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option en English' ./feeds/luci/modules/luci-base/root/etc/config/luci

sed -i "/config internal languages/a\\        option zh_cn \'chinese\'" ./feeds/luci/modules/luci-base/root/etc/config/luci

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-Action导入编译配置'
cp -v ../zhKong/config/config-${INPUT_ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
