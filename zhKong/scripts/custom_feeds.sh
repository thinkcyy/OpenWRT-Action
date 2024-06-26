echo '当前执行步骤：2.1.1-custom_feeds-添加lean的LUCI、packages、和routing的feed源'
#echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
#echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
#echo 'src-git cus_lean_routing https://github.com/coolsnowwolf/routing' >>feeds.conf.default

echo '当前执行步骤：2.1.2-custom_feeds-更新 Feeds'
./scripts/feeds update -a

echo '当前执行步骤：2.1.3-custom_feeds-替换自带feed中的luci-base、luci-mod-status、coremark和自带package中的default-settings'
mkdir package/immortal
git clone --depth 1 https://github.com/immortalwrt/luci immortal_luci
git clone --depth 1 https://github.com/immortalwrt/packages immortal_package
git clone --depth 1 https://github.com/immortalwrt/immortalwrt immortal_immortalwrt

rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/
cp -r ./immortal_package/utils/coremark package/immortal/
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/immortal/

#添加autocore
cp -r ./immortal_immortalwrt/package/emortal/autocore package/immortal/
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/immortal/autocore/files/luci-mod-status-autocore.json

#echo '当前执行步骤：2.1.4-custom_feeds-添加lean自带的lean软件目录'
#git clone --depth 1 https://github.com/coolsnowwolf/lede lede
#cp -r ./lede/package/lean feeds/
# 删除lean的ddns-scripts_aliyun、dedefault-settings
#rm -r feeds/lean/ddns-scripts_aliyun
#rm -r feeds/lean/autocore
#rm -r feeds/lean/default-settings


./scripts/feeds install -a

echo '当前执行步骤：2.1.5-custom_feeds-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/immortal/
tree -L 3 ./package
