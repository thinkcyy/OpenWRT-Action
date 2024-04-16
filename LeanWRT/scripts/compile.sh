cd openwrt
make download -j$(nproc)
#make -j$(nproc) || make -j1 V=s
make -j1 V=s
