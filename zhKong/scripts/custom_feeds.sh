echo '-步骤：custom_feed-更新 Feeds'

#echo '-步骤：custom_feed-替换自带的feed源'
#cp ../$REPO_TYPE/scripts/feeds.conf.default ./

./scripts/feeds update -a

: <<'COMMENT'
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

echo '-步骤：custom_feed-替换自带luci'
rm -rf feeds/luci
#rm -rf feeds/luci/modules/luci-base
#rm -rf feeds/luci/modules/luci-mod-status
mv immortal_luci  feeds

#rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings
#cp -vr ./immortal_luci/modules/luci-base feeds/luci/modules/
#cp -vr ./immortal_luci/modules/luci-mod-status feeds/luci/modules/
cp -vr ./immortal_package/utils/coremark package/immortal/
cp -vr ./immortal_immortalwrt/package/emortal/default-settings package/immortal/

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


 


#echo '-步骤：custom_feed-调整为适用于22.03的TurboACC https://github.com/chenmozhijin/turboacc'
#rm -rf ./feeds/luci/applications/luci-app-turboacc/
#curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

echo '-步骤：custom_feed-添加coolsnowwolf的软件包'
mkdir package/lean
git clone --depth 1 https://github.com/coolsnowwolf/luci cus_lean_luci
#cp -r cus_lean_luci/applications/luci-app-zerotier package/lean/
cp -r cus_lean_luci/applications/luci-app-turboacc package/lean/
#cp -r cus_lean_luci/applications/luci-app-cpufreq package/lean/
#cp -r cus_lean_luci/applications/luci-app-advanced-reboot package/lean/
#cp -r cus_lean_luci/applications/luci-app-dawn package/lean/
#cp -r cus_lean_luci/applications/luci-app-samba4 package/lean/
#cp -r cus_lean_luci/applications/luci-app-usb-printer package/lean/

git clone --depth 1 https://github.com/coolsnowwolf/lede cus_lean_lede
cp -r cus_lean_lede/package/lean/autosamba package/lean/
cp -r cus_lean_lede/package/lean/automount package/lean/
cp -r cus_lean_lede/package/lean/ddns-scripts_dnspod package/lean/
cp -r cus_lean_lede/package/lean/ipv6-helper package/lean/

echo '-步骤：custom_feed-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt  zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init

COMMENT

./scripts/feeds install -a

echo '-package文件总览：'
tree -L 3 ./package
tree -L 3 ./feeds

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-Action导入编译配置'
cp -v ../zhKong/config/config-${INPUT_ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
