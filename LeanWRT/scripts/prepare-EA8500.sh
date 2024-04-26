cd openwrt

echo "添加包"
chmod +x ../LeanWRT/scripts/*.sh
../LeanWRT/scripts/custom_feeds.sh


echo "导入编译配置"
#cp -v ../LeanWRT/config/config-EA8500.config .config
make defconfig
