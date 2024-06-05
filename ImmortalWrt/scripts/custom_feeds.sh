# 更新 Feeds
#cd openwrt
#echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci' >>feeds.conf.default
#echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages' >>feeds.conf.default
#echo 'src-git cus_lean_prouting https://github.com/coolsnowwolf/routing' >>feeds.conf.default

# 更新 Feeds
./scripts/feeds update -a

#rm -rf feeds/luci/modules/luci-base
#rm -rf feeds/luci/modules/luci-mod-status
#rm -rf feeds/packages/utils/coremark
#rm -rf package/new/default-settings

#mkdir package/new

#git clone  https://github.com/immortalwrt/packages immortal_package
#cp -r ./immortal_package/utils/coremark package/new/

#git clone https://github.com/coolsnowwolf/lede lede
#cp -r ./lede/package/lean feeds/

# 删除lean的ddns-scripts_aliyun
#rm -r feeds/lean/ddns-scripts_aliyun
#rm -r feeds/lean/autocore
./scripts/feeds install -a

#echo '当前执行步骤：2.1.5-custom_feeds-添加zhKong的ddns-scripts_aliyun包'
#git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt zhKong_OpenWrt
#cp -vr ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/new/

echo '当前执行步骤：2.1.6-custom_feeds-调整为适用于22.03的TurboACC https://github.com/chenmozhijin/turboacc'
rm -rf ./feeds/luci/applications/luci-app-turboacc/
#curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
#git clone --depth=1 --single-branch https://github.com/chenmozhijin/turboacc ~/turboacc
#cp ~/add_turboacc_no_952953.sh ./
#bash ./add_turboacc_no_952953.sh
bash ../ImmortalWrt/scripts/add_turboacc_no_952953.sh

#修改编译文件
#tree -L 2 feeds/nss/
#cp -v nss-makefile-changes/qca-nss-clients-Makefile feeds/nss/qca-nss-clients/Makefile
#cp -v nss-makefile-changes/qca-nss-ecm-Makefile feeds/nss/qca-nss-ecm/Makefile
