
../scripts/add_package_common.sh

./scripts/feeds update -a


echo '-步骤：custom_feed-替换自带feed中的luci-base、luci-mod-status、coremark和自带package中的default-settings'
mkdir package/immortal

git clone https://github.com/immortalwrt/luci immortal_luci
git clone https://github.com/immortalwrt/packages immortal_package
git clone https://github.com/immortalwrt/immortalwrt immortal_immortalwrt
git clone https://github.com/coolsnowwolf/lede lede

: <<'COMMENT'
# 锁定日期
cd immortal_luci
../../scripts/select_dir_commit.sh

cd ../immortal_package
../../scripts/select_dir_commit.sh

cd ../immortal_immortalwrt
../../scripts/select_dir_commit.sh

cd ../lede
../../scripts/select_dir_commit.sh

cd ..
COMMENT


echo '-步骤：custom_feed-替换自带luci-base、luci-mod-status'
rm -rf feeds/luci/modules/luci-base
rm -rf feeds/luci/modules/luci-mod-status
cp -r ./immortal_luci/modules/luci-base feeds/luci/modules/
cp -r ./immortal_luci/modules/luci-mod-status feeds/luci/modules/

echo '-步骤：custom_feed-替换自带default-settings'
cp -r ./immortal_immortalwrt/package/emortal/default-settings package/immortal/

[[ -d "package/thinkcy" ]] && mkdir -p ./package/thinkcy
cp -vr ../thinkcy-settings ./package/thinkcy 

echo '-步骤：custom_feed-添加lean的luci仓库'
git clone https://github.com/coolsnowwolf/luci cus_lean_luci
cp -r ./cus_lean_luci/applications/luci-app-turboacc package/thinkcy/

echo '-步骤：custom_feed-修改默认语言'
sed -i "s|option lang auto|option lang \'zh_cn\'|g" ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option en English' ./feeds/luci/modules/luci-base/root/etc/config/luci
sed -i '/config internal languages/a \ \ \ \ \ \ \ \ option zh_cn chinese' ./feeds/luci/modules/luci-base/root/etc/config/luci

echo '-步骤：custom_feed-添加zhKong的ddns-scripts_aliyun包'
git clone --depth 1 https://github.com/thinkcyy/AX3600-OpenWrt  zhKong_OpenWrt
cp -r ./zhKong_OpenWrt/package/ddns-scripts_aliyun  package/thinkcy/

echo '-步骤：custom_feed-向后调整tinc服务启动次序'             
sed -i 's|START=42|START=99|g' ./feeds/packages/net/tinc/files/tinc.init

echo '-步骤：custom_feed-移除frp日志'      
sed -i '/Starting frp service/d' ./feeds/luci/applications/luci-app-frpc/root/etc/init.d/frp
sed -i '/Shutting down frp service/d' ./feeds/luci/applications/luci-app-frpc/root/etc/init.d/frp

echo '-步骤：custom_feed-修改imagebuilder'    
rm -rf  target/imagebuilder
cp -r ../imagebuilder target/

./scripts/feeds install -a

echo "ROUTER_MODEL为： ${ROUTER_MODEL}"
echo "INPUT_ROUTER_MODEL为： ${INPUT_ROUTER_MODEL}"

echo '-步骤：custom_feed-导入编译配置'
cp -v ../zhKong/config/config-${ROUTER_MODEL}.config .config

echo '-步骤：custom_feed-初始化编译配置defconfig'
make defconfig
