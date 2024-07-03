echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
echo 'src-git cus_lean_routing https://github.com/coolsnowwolf/routing' >>feeds.conf.default

# 更新 Feeds
echo '当前工作目录'
pwd
chmod +x ./scripts/*

./scripts/feeds update -a

tree -L 3

rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
rm -rf feeds/packages/utils/coremark
rm -rf package/new/default-settings

mkdir package/new
git clone  https://github.com/immortalwrt/immortalwrt immortal_immortalwrt
cp -r ./immortal_immortalwrt/package/emortal/autocore package/new/
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

tree -L 3

echo '-步骤：custom_feed-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt  zhKong_OpenWrt
cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/new/

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init
