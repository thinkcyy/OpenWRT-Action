cd openwrt

echo "添加包"
chmod +x ../23.05-NSS/scripts/*.sh
../23.05-NSS/scripts/custom_feeds.sh


echo "导入编译配置"
cp -v ../23.05-NSS/config/config-EA8500.config .config
make defconfig