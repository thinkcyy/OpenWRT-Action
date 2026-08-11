echo "--当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-$(basename "$0")"

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.1替换自带feed中的luci-base、luci-mod-status'
mkdir package/immortal

git clone https://github.com/immortalwrt/luci immortal_luci
git clone https://github.com/immortalwrt/packages immortal_package
git clone https://github.com/immortalwrt/immortalwrt immortal_immortalwrt
git clone https://github.com/coolsnowwolf/lede lede

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.2-替换自带luci-base、luci-mod-status'
rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.3-打补丁'
# 来自https://github.com/tingalvin/r7800
echo '-步骤：enable VHT mode on 2.4g and show NSS load in status'
cp -r ../thinkcy/patch/feeds/ ./

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.4-替换自带default-settings'
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/immortal/

#echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.5-添加lean的luci仓库'
#git clone https://github.com/coolsnowwolf/luci cus_lean_luci
#cp -r ./cus_lean_luci/applications/luci-app-turboacc package/thinkcy/

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.5-添加自带源码thinkcy_package'
cp -r ../thinkcy/thinkcy_package ./package/
git clone  https://github.com/superzjg/luci-app-frpc_frps superzjg
cp -r superzjg/luci-app-frpc ./package/thinkcy_package/

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.6-修改默认语言'
sed -i "s|option lang auto|option lang \'zh_cn\'|g" ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option en English' ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option zh_cn chinese' ./feeds/luci/modules/luci-base/root/etc/config/luci

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.7-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt  zhKong_OpenWrt
cp -r ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/thinkcy_package/

echo '---当前执行步骤：custom_feeds自定义软件包-2-调整源码-2.1-通用源码-2.1.8-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init
