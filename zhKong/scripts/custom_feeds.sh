echo '-步骤：custom_feed-更新 Feeds'
./scripts/feeds update -a

echo '-步骤：custom_feed-替换自带feed中的luci-base、luci-mod-status、coremark和自带package中的default-settings'
mkdir package/immortal

git clone https://github.com/immortalwrt/luci immortal_luci
git clone https://github.com/immortalwrt/packages immortal_package
git clone https://github.com/immortalwrt/immortalwrt immortal_immortalwrt

# 锁定日期
REV_DATE=$(git log -1 --format=%cd --date=iso8601-strict)

cd immortal_luci
REV_HASH=$(git rev-list -n 1 --all --before=${REV_DATE})
git checkout $REV_HASH

cd ../immortal_package
REV_HASH=$(git rev-list -n 1 --all --before=${REV_DATE})
git checkout $REV_HASH

cd ../immortal_immortalwrt
REV_HASH=$(git rev-list -n 1 --all --before=${REV_DATE})
git checkout $REV_HASH

cd ..

rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/
cp -r ./immortal_package/utils/coremark package/immortal/
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/immortal/

echo '-步骤：custom_feed-添加autocore'
cp -r ./immortal_immortalwrt/package/emortal/autocore package/immortal/
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/immortal/autocore/files/luci-mod-status-autocore.json

#echo '-步骤：custom_feed-添加lean自带的lean软件目录'
#git clone --depth 1 https://github.com/coolsnowwolf/lede lede
#cp -r ./lede/package/lean feeds/
# 删除lean的ddns-scripts_aliyun、dedefault-settings
#rm -r feeds/lean/ddns-scripts_aliyun
#rm -r feeds/lean/autocore
#rm -r feeds/lean/default-settings

./scripts/feeds install -a

echo '-步骤：custom_feed-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/immortal/
#tree -L 3 ./package

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-Action导入编译配置'
cp -v ../zhKong/config/config-${INPUT_ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
