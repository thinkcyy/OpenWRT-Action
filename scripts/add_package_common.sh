echo "-当前执行步骤：添加通用软件包"

[[ -d "package/thinkcy" ]] && mkdir -p package/thinkcy
# git clone https://github.com/izilzty/luci-app-temp-status ./package/thinkcy/luci-app-temp-status
cp -r ../thinkcy ./package/
cp -r ../thinkcy-settings ./package/thinkcy/ 

echo "src-git qosmioextra https://github.com/qosmio/packages-extra" >> feeds.conf
echo "src-git zerotier-openwrt https://github.com/mwarning/zerotier-openwrt.git" >> feeds.conf
