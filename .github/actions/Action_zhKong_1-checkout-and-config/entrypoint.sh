#!/bin/sh -l

echo -e "Total CPU cores\t: $(nproc)"
cat /proc/cpuinfo | grep 'model name'
ulimit -a 

sudo swapoff -a
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo -E apt-get -qq update
sudo -E apt-get -qq install aria2 rename xz-utils
sudo -E wget -P /usr/local/sbin/ https://github.com/HiGarfield/lede-17.01.4-Mod/raw/master/.github/backup/apt-fast
sudo -E chmod -R 755 /usr/local/sbin/apt-fast
sudo -E apt-fast -y -qq install zstd dwarves llvm clang lldb lld build-essential rsync asciidoc binutils bzip2 gawk gettext git libncurses5-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc-s1 libc6-dev-i386 subversion flex uglifyjs gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libreadline-dev libglib2.0-dev xmlto qemu-utils upx-ucl libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget ccache curl swig coreutils vim nano python3 python3-pip python3-ply haveged lrzsz scons libpython3-dev
sudo -E pip3 install pyelftools pylibfdt
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
sudo -E git config --global user.name 'GitHub Actions' && git config --global user.email 'noreply@github.com'
sudo -E git config --global core.abbrev auto
sudo timedatectl set-timezone "Asia/Shanghai"
df -h

cd /github/workspace/
git clone --depth 1  https://github.com/thinkcyy/OpenWRT-Action OpenWRT-Action 
git clone --depth 1  https://github.com/AgustinLorenzo/openwrt -b main --single-branch ./OpenWRT-Action/openwrt
echo "当前工作目录"
pwd
tree -L 3
 

chmod +x ./OpenWRT-Action/zhKong/scripts/*.sh
cp -v ./OpenWRT-Action/zhKong/config/$COMPILE_CONFIG.config ./OpenWRT-Action/zhKong/config/config-$ROUTER_MODEL.config
./OpenWRT-Action/zhKong/scripts/prepare.sh
