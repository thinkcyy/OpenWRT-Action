#!/bin/bash
# ============================================================================
# add-sax1v1k-fan-hw.sh — 方案C: SAX1V1K 硬件 PWM 风扇控制完整补丁
#
# 目标仓库: AgustinLorenzo/openwrt (main_nss)
#
# 本脚本自动完成:
#   [1] target/linux/qualcommax/config-6.12 末尾写入 CONFIG_PWM_IPQ=y
#       (驱动本体已由 patches-6.12/0141 提供, 但仓库未注册 kmod 包,
#        必须内建, 否则驱动不会被编译)
#   [2] (可选 --proper) 生成 patches-6.12/0307-*.patch, 给 pwm-ipq 驱动
#       的 of_match 表添加 "qcom,ipq8074-pwm" (正规做法; 默认不生成,
#       因为 DTS 节点写双 compatible 回退匹配即可, 零内核补丁)
#   [3] ipq8072-sax1v1k.dts 插入:
#         - pwm@<基址> 控制器节点 (时钟自动探测, 可回退 xo_board_clk)
#         - pwm-fan 节点 (默认 通道3/gpio32/25kHz, 可参数改)
#         - &tlmm 内 fan_pwm_pins pinctrl
#         - (可选 -t) &cpu_thermal 自动温控片段
#
# 用法:  ./add-sax1v1k-fan-hw.sh [选项]     (在 openwrt 源码根目录运行)
#   -r DIR         源码根目录            (默认: .)
#   -c N           PWM 通道 0-3          (默认: 3)
#   -p N           GPIO 引脚             (默认: 32)
#   -a ADDR        PWM 寄存器基址        (默认: 0x194b000, 见下方验证)
#   -f HZ          PWM 频率              (默认: 25000)
#   -t|--thermal   追加 cpu_thermal 温控片段
#   --channel2     快捷: 等效 -c 2 -p 27
#   --proper       生成 0307 驱动 compatible patch (DTS 用单 compatible)
#   -h|--help      帮助
#
# 幂等: 任意参数重复运行安全; 原文件备份为 .bak-fan / config-6.12.bak-fan。
#
# 剩余三关 (脚本无法替你验证, 上板后按序排查):
#   关1: dtb 编译报 function 'pwm3' not found
#         -> 上游 pinctrl-ipq8074.c 无 pwm 复用组, 仿照仓库
#            patches-6.12/0305 (ipq5018) 给 pinctrl-ipq8074.c 补组
#   关2: dmesg 无 pwm 输出
#         -> 换 clocks = <&xo_board_clk> 重跑; 再不行换基址:
#            -a 0x1945010 / -a 0x1946010
#   关3: /sys/class/pwm/pwmchip0 出现但风扇不动
#         -> 通道号不对, 脚本末尾有逐个通道试的验收命令
# ============================================================================
set -euo pipefail

ROOT="."; CHANNEL=3; PIN=32; PWM_BASE="0x194b000"; FREQ=25000
THERMAL=0; PROPER=0

die()  { echo "[ERROR] $*" >&2; exit 1; }
info() { echo "[INFO]  $*"; }

while [[ $# -gt 0 ]]; do
	case "$1" in
		-r) ROOT="$2"; shift 2 ;;
		-c) CHANNEL="$2"; shift 2 ;;
		-p) PIN="$2"; shift 2 ;;
		-a) PWM_BASE="$2"; shift 2 ;;
		-f) FREQ="$2"; shift 2 ;;
		-t|--thermal) THERMAL=1; shift ;;
		--channel2) CHANNEL=2; PIN=27; shift ;;
		--proper) PROPER=1; shift ;;
		-h|--help) sed -n '2,44p' "$0"; exit 0 ;;
		*) die "未知参数: $1 (用 -h 查看帮助)" ;;
	esac
done

DTS="$ROOT/target/linux/qualcommax/dts/ipq8072-sax1v1k.dts"
CFG="$ROOT/target/linux/qualcommax/config-6.12"
[[ -f "$DTS" ]] || die "找不到 $DTS —— 请用 -r 指定 openwrt 源码根目录"
[[ -f "$CFG" ]] || die "找不到 $CFG (内核版本不是 6.12?)"
PERIOD_NS=$(( 1000000000 / FREQ ))
info "目标: 通道=$CHANNEL gpio$PIN 基址=$PWM_BASE 周期=${PERIOD_NS}ns"

cp -a "$DTS" "$DTS.bak-fan"
cp -a "$CFG" "$CFG.bak-fan"
info "已备份: ipq8072-sax1v1k.dts.bak-fan / config-6.12.bak-fan"

# ---------------------------------------------------------------------------
# [1] config-6.12: 内建 pwm-ipq 驱动
# ---------------------------------------------------------------------------
if grep -q "^CONFIG_PWM_IPQ=" "$CFG"; then
	sed -i 's/^CONFIG_PWM_IPQ=.*/CONFIG_PWM_IPQ=y/' "$CFG"
else
	printf '\n# SAX1V1K 硬件 PWM 风扇 (patches-6.12/0141 提供的 pwm-ipq 驱动)\nCONFIG_PWM_IPQ=y\n' >> "$CFG"
fi
grep -q "^CONFIG_PWM_IPQ=y" "$CFG" || die "config-6.12 写入失败"
info "config-6.12: CONFIG_PWM_IPQ=y"

# ---------------------------------------------------------------------------
# [2] (可选) 0307 驱动 compatible patch
# ---------------------------------------------------------------------------
if [[ "$PROPER" -eq 1 ]]; then
	PATCH_DIR="$ROOT/target/linux/qualcommax/patches-6.12"
	PATCH_FILE="$PATCH_DIR/0307-pwm-ipq-add-ipq8074-compatible.patch"
	cat > "$PATCH_FILE" << 'EOF'
--- a/drivers/pwm/pwm-ipq.c
+++ b/drivers/pwm/pwm-ipq.c
@@ -1,3 +1,4 @@
+	{ .compatible = "qcom,ipq8074-pwm" },
 	{ .compatible = "qcom,ipq6018-pwm" },
EOF
	info "已生成 $PATCH_FILE (若应用失败可删除该文件, 双 compatible 方案不受影响)"
fi

# ---------------------------------------------------------------------------
# [3] DTS: 时钟探测 + 节点插入
# ---------------------------------------------------------------------------
GCC_CLK_FILE="$ROOT/drivers/clk/qcom/gcc-ipq8074.c"
if [[ -f "$GCC_CLK_FILE" ]] && grep -q "GCC_APSS_PWM_CLK" "$GCC_CLK_FILE"; then
	info "时钟: GCC_APSS_PWM_CLK @100MHz"
	CLOCK_BLK="		clocks = <&gcc GCC_APSS_PWM_CLK>;\\n		assigned-clocks = <&gcc GCC_APSS_PWM_CLK>;\\n		assigned-clock-rates = <100000000>;"
else
	info "时钟: gcc-ipq8074 无 GCC_APSS_PWM_CLK, 回退 xo_board_clk (19.2MHz)"
	CLOCK_BLK="		clocks = <&xo_board_clk>;"
fi

COMPAT="\"qcom,ipq8074-pwm\", \"qcom,ipq6018-pwm\""
[[ "$PROPER" -eq 1 ]] && COMPAT="\"qcom,ipq8074-pwm\""

TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
BLK_ROOT="$TMPD/root.block"

printf '%s\n' \
"	pwm: pwm@$PWM_BASE {" \
"		compatible = $COMPAT;" \
"		reg = <$PWM_BASE 0x20>;		/* 4 通道 x 8 字节 */" \
"$CLOCK_BLK" \
"		#pwm-cells = <2>;" \
"	};" \
"" \
"	fan: pwm-fan {" \
"		compatible = \"pwm-fan\";" \
"		pwms = <&pwm $CHANNEL $PERIOD_NS>;	/* $FREQ Hz */" \
"		cooling-min-state = <0>;" \
"		cooling-max-state = <4>;" \
"		#cooling-cells = <2>;" \
"	};" \
> "$BLK_ROOT"

PINBLK="$TMPD/pin.block"
printf '%s\n' \
"	fan_pwm_pins: fan-pwm-pins {" \
"		pins = \"gpio$PIN\";" \
"		function = \"pwm$CHANNEL\";" \
"		drive-strength = <8>;" \
"	};" \
> "$PINBLK"

# 幂等清理旧节点
awk '
	/^[ \t]*pwm: pwm@/     { skip=1; depth=0 }
	/^[ \t]*fan: pwm-fan/  { skip=1; depth=0 }
	/^[ \t]*fan_pwm_pins:/ { skip=1; depth=0 }
	skip {
		n = gsub(/{/, "{"); depth += n
		depth -= gsub(/}/, "}")
		if (depth <= 0) { skip=0; next }
		next
	}
	{ print }
' "$DTS" > "$TMPD/dts.tmp" && cat "$TMPD/dts.tmp" > "$DTS"

# root: "/ {" 之后插入
sed -i "/^\/ {/r $BLK_ROOT" "$DTS"
grep -q "pwm: pwm@$PWM_BASE" "$DTS" || die "root 节点插入失败"
info "已插入 pwm 控制器 + pwm-fan 节点"

# &tlmm 末尾插入 pinctrl
awk -v blk="$PINBLK" '
	/^&tlmm[ \t]*\{/          { in_tlmm=1 }
	in_tlmm && /^\};/ && !done {
		print ""
		while ((getline line < blk) > 0) print line
		close(blk); done=1; in_tlmm=0
	}
	{ print }
' "$DTS" > "$TMPD/dts.tmp" && cat "$TMPD/dts.tmp" > "$DTS"
grep -q "fan-pwm-pins" "$DTS" || die "&tlmm 插入失败"
info "已插入 pinctrl fan_pwm_pins (gpio$PIN -> pwm$CHANNEL)"

# 可选温控
if [[ "$THERMAL" -eq 1 ]]; then
	if grep -q "^&cpu_thermal" "$DTS"; then
		info "已存在 &cpu_thermal 片段, 跳过"
	elif ! grep -q "cpu_thermal" \
	     "$ROOT/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074.dtsi" 2>/dev/null; then
		info "ipq8074.dtsi 无 cpu_thermal, 跳过温控片段"
	else
		cat >> "$DTS" << 'THERMAL_EOF'

&cpu_thermal {
	trips {
		fan_trip: fan-trip {
			temperature = <65000>;
			hysteresis = <5000>;
			type = "active";
		};
	};

	cooling-maps {
		map0 {
			trip = <&fan_trip>;
			cooling-device = <&fan THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
		};
	};
};
THERMAL_EOF
		info "已追加 &cpu_thermal 温控片段 (65°C 启动风扇)"
	fi
fi

# ---------------------------------------------------------------------------
# 汇总
# ---------------------------------------------------------------------------
echo
echo "===== 生成的节点 ====="
grep -n -A6 "pwm: pwm@\|fan: pwm-fan\|fan-pwm-pins" "$DTS" || true
echo
cat << EOF
===== 剩余手动步骤 =====
1. .config 确认 (=m 只出 .ipk 不装进固件!):
     CONFIG_PACKAGE_kmod-hwmon-core=y
     CONFIG_PACKAGE_kmod-hwmon-pwmfan=y
   然后 make oldconfig

2. 编译, 按顺序过三关:
   关1  dtb 编译报 function 'pwm$CHANNEL' not found
        -> 仿 patches-6.12/0305 给 drivers/pinctrl/qcom/pinctrl-ipq8074.c
           补 gpio$PIN 的 pwm 复用组
   关2  烧录后 dmesg | grep -i pwm 无输出
        -> ./add-sax1v1k-fan-hw.sh -r $ROOT        (重跑, 自动换 xo 时钟)
           仍无输出 -> -a 0x1945010 重跑, 再试 -a 0x1946010
   关3  ls /sys/class/pwm/ 有 pwmchip0 但风扇不动 -> 通道不对:
        cd /sys/class/pwm/pwmchip0
        for i in 0 1 2 3; do
          echo \$i > export 2>/dev/null
          echo $PERIOD_NS > pwm\$i/period
          echo $PERIOD_NS > pwm\$i/duty_cycle
          echo 1 > pwm\$i/enable     # 听风扇, 记住通道号
          echo 0 > pwm\$i/enable; echo \$i > unexport
        done
        确认通道 N 后: ./add-sax1v1k-fan-hw.sh -c N -p XX -r $ROOT 定稿

3. 定稿后验收: cat /sys/class/hwmon/hwmon*/pwm1   (内核温控调速)

4. 回滚:
     cp -a "$DTS.bak-fan" "$DTS"
     cp -a "$CFG.bak-fan" "$CFG"
EOF
