echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
echo 'src-git cus_lean_prouting https://github.com/coolsnowwolf/routing' >>feeds.conf.default

# netgear theme
#echo 'src-git cus_netgear https://github.com/ysoyipek/luci-theme-netgear.git' >>feeds.conf.default

# ysx
#echo 'src-git cus_sx88 https://github.com/ysx88/openwrt-packages' >>feeds.conf.default


# 更新 Feeds
./scripts/feeds update -a

rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings

mkdir package/new
git clone  https://github.com/immortalwrt/immortalwrt immortal_immortalwrt
cp -r ./immortal_immortalwrt/package/emortal/autocore package/new/
#svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/new/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/new/autocore/files/luci-mod-status-autocore.json
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/new/

git clone  https://github.com/immortalwrt/luci immortal_luci
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/

git clone  https://github.com/immortalwrt/packages immortal_package
cp -r ./immortal_package/utils/coremark package/new/

git clone https://github.com/coolsnowwolf/lede lede
cp -r ./lede/package/lean feeds/

rm -r feeds/lean/ddns-scripts_aliyun
rm -r feeds/lean/autocore
./scripts/feeds install -a


# Lean LEDE的package (ddns-scripts_aliyun)
# svn export https://github.com/coolsnowwolf/lede/branches/master/package package/lede
# rm -rf package/lede/base-files
# rm -rf package/lede/boot
# rm -rf package/lede/devel
# rm -rf package/lede/firmware
# rm -rf package/lede/kernel
# rm -rf package/lede/libs
# rm -rf package/lede/network
# rm -rf package/lede/qat
# rm -rf package/lede/qca
# rm -rf package/lede/system
# rm -rf package/lede/utils
# rm -rf package/lede/wwan

# git clone https://github.com/sensec/ddns-scripts_aliyun.git  -b main --single-branch package/aliyun --depth 1

# immortalwrt
#svn export https://github.com/immortalwrt/luci/branches/master/modules/luci-base feeds/luci/modules/luci-base
#svn export https://github.com/immortalwrt/luci/branches/master/modules/luci-mod-status feeds/luci/modules/luci-mod-status
#svn export https://github.com/immortalwrt/packages/branches/master/utils/coremark package/new/coremark
#svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/default-settings package/emortal/default-settings

# ddns-scripts_aliyun
cp -r ../package/ddns-scripts_aliyun  package/new/
