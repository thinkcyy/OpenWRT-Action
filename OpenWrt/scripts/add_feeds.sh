echo '-添加额外feed源'
echo "src-git thinkcy_qosmio https://github.com/qosmio/packages-extra" | cat - feeds.conf.default                > feeds.conf.add
echo "src-git thinkcy_mwarning https://github.com/mwarning/zerotier-openwrt.git" | cat - feeds.conf.default      >> feeds.conf.add
cp feeds.conf.add feeds.conf.default
