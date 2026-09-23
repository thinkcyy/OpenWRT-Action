#echo 补丁config-6.12
#echo  CONFIG_PWM_IPQ=y >> target/linux/qualcommax/config-6.12
#echo config-6.12内容为
#cat target/linux/qualcommax/config-6.12

#cp -vr ../patch/target ./
#echo dts文件内容为
#cat ./target/linux/qualcommax/dts/ipq8072-sax1v1k.dts

source ../$REPO_TYPE/scripts/add-sax1v1k-fan-hw.sh --channel2 
