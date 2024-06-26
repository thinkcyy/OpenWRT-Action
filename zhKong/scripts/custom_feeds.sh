#echo '当前执行步骤：2.1.1-custom_feeds-添加feeds.conf.default'
#echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
#echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
#echo 'src-git cus_lean_prouting https://github.com/coolsnowwolf/routing' >>feeds.conf.default

echo '当前执行步骤：2.1.2-custom_feeds-更新 Feeds'
./scripts/feeds update -a

echo '当前执行步骤：2.1.3-custom_feeds-删除luci-base、luci-mod-status、coremark、default-settings'
rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings

echo '当前执行步骤：2.1.4-custom_feeds-添加immortalwrt软件包'
mkdir package/new
git clone --depth 1 https://github.com/immortalwrt/immortalwrt immortal_immortalwrt
cp -r ./immortal_immortalwrt/package/emortal/autocore package/new/
#svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/luci-mod-status-autocore.json
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/new/

git clone --depth 1 https://github.com/immortalwrt/luci immortal_luci
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/

git clone --depth 1 https://github.com/immortalwrt/packages immortal_package
cp -r ./immortal_package/utils/coremark package/new/

#git clone --depth 1 https://github.com/coolsnowwolf/lede lede
#cp -r ./lede/package/lean feeds/

# 删除lean的ddns-scripts_aliyun、dedefault-settings
rm -r feeds/lean/ddns-scripts_aliyun
rm -r feeds/lean/autocore
rm -r feeds/lean/default-settings
./scripts/feeds install -a

echo '当前执行步骤：2.1.5-custom_feeds-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/new/
tree -L 3 ./package
