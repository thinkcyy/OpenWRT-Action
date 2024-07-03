#echo '-添加额外feed源'
echo '-添加lean的luci、package和routing源'
echo 'src-git cus_lean_luci https://github.com/coolsnowwolf/luci.git' >>feeds.conf.default
echo 'src-git cus_lean_packages https://github.com/coolsnowwolf/packages.git' >>feeds.conf.default
echo 'src-git cus_lean_routing https://github.com/coolsnowwolf/routing.git' >>feeds.conf.default
