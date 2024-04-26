echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
echo 'src-git cus_lean_prouting https://github.com/coolsnowwolf/routing' >>feeds.conf.default

# 更新 Feeds
./scripts/feeds update -a

rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings

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

git clone --depth 1 https://github.com/coolsnowwolf/lede lede
cp -r ./lede/package/lean feeds/

# 删除lean的ddns-scripts_aliyun
rm -r feeds/lean/ddns-scripts_aliyun
rm -r feeds/lean/autocore
./scripts/feeds install -a

# 使用zhKong的ddns-scripts_aliyun
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt zhKong_OpenWrt
cp -r ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/new/
