echo "--当前执行步骤：添加通用软件包-add_package_common.sh"

echo '---添加thinkcy目录'
[[ -d "package/thinkcy" ]] && mkdir -p package/thinkcy
# git clone https://github.com/izilzty/luci-app-temp-status ./package/thinkcy/luci-app-temp-status
cp -r ../thinkcy ./package/

echo '---添加额外feed源'
# luci-mod-status-nss
echo "src-git thinkcy_qosmio https://github.com/qosmio/packages-extra" | cat - feeds.conf.default                                                     > feeds.conf.add
# zerotier
cp feeds.conf.add feeds.conf.last ; echo "src-git thinkcy_mwarning https://github.com/mwarning/zerotier-openwrt.git" | cat - feeds.conf.last          > feeds.conf.add
cp feeds.conf.add feeds.conf.default
