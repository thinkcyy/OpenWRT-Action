#!/bin/bash
# ============================================================================
# add-sax1v1k-fan-hw.sh
#
# SAX1V1K / IPQ8074 硬件 PWM 风扇控制
#
# 当前方案：
#   GPIO32 -> PWM3
#   PWM 基址默认：0x1941010
#   PWM 时钟默认：GCC_ADSS_PWM_CLK
#   PWM 频率默认：25kHz
#
# 重要：
#   0x1941010 是目前根据 IPQ6018/IPQ9574 同类 PWM block 得出的
#   最佳候选地址，但尚无公开 IPQ8074 DTS 明确确认。
#
#   IPQ8074 pinctrl 已原生支持：
#       GPIO32 -> PWM3
#
#   不再修改 pinctrl-ipq8074.c。
#
# 功能：
#   1. CONFIG_PWM_IPQ=y
#   2. 自动确保 kmod-hwmon-pwmfan
#   3. 在 SAX1V1K DTS 添加 PWM controller
#   4. 添加 pwm-fan
#   5. GPIO32 -> PWM3 pinctrl
#   6. 正确绑定 pinctrl-0
#   7. 如果当前 pwm-ipq 驱动仍存在 25kHz period bug，
#      自动生成修复 patch
#   8. 可选添加 cpu_thermal -> pwm-fan cooling map
#
# 用法：
#
#   ./add-sax1v1k-fan-hw.sh
#
#   自定义通道：
#   ./add-sax1v1k-fan-hw.sh -c 2 -p 27
#
#   指定源码目录：
#   ./add-sax1v1k-fan-hw.sh -r ~/openwrt
#
#   指定 PWM 基址：
#   ./add-sax1v1k-fan-hw.sh -a 0x1941010
#
#   使用 XO 时钟：
#   ./add-sax1v1k-fan-hw.sh --xo-clock
#
#   加入 CPU thermal 控制：
#   ./add-sax1v1k-fan-hw.sh --thermal
#
# ============================================================================

set -euo pipefail

ROOT="."
CHANNEL=3
PIN=32
PWM_BASE="0x1941010"
FREQ=25000
THERMAL=0
XO_CLOCK=0

die()
{
	echo "[ERROR] $*" >&2
	exit 1
}

info()
{
	echo "[INFO]  $*"
}

warn()
{
	echo "[WARN]  $*" >&2
}

usage()
{
	sed -n '2,75p' "$0"
	exit 0
}

# ---------------------------------------------------------------------------
# 参数
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
	case "$1" in
		-r)
			[[ $# -ge 2 ]] || die "-r 缺少参数"
			ROOT="$2"
			shift 2
			;;

		-c)
			[[ $# -ge 2 ]] || die "-c 缺少参数"
			CHANNEL="$2"
			shift 2
			;;

		-p)
			[[ $# -ge 2 ]] || die "-p 缺少参数"
			PIN="$2"
			shift 2
			;;

		-a)
			[[ $# -ge 2 ]] || die "-a 缺少参数"
			PWM_BASE="$2"
			shift 2
			;;

		-f)
			[[ $# -ge 2 ]] || die "-f 缺少参数"
			FREQ="$2"
			shift 2
			;;

		-t|--thermal)
			THERMAL=1
			shift
			;;

		--xo-clock)
			XO_CLOCK=1
			shift
			;;

		-h|--help)
			usage
			;;

		*)
			die "未知参数: $1"
			;;
	esac
done

# ---------------------------------------------------------------------------
# 参数检查
# ---------------------------------------------------------------------------

[[ "$CHANNEL" =~ ^[0-3]$ ]] ||
	die "PWM channel 必须为 0~3"

[[ "$PIN" =~ ^[0-9]+$ ]] ||
	die "GPIO 必须为数字"

[[ "$FREQ" =~ ^[0-9]+$ ]] ||
	die "频率必须为数字"

(( FREQ > 0 )) ||
	die "频率必须 > 0"

PERIOD_NS=$((1000000000 / FREQ))

(( PERIOD_NS > 0 )) ||
	die "PWM 频率过高"

# ---------------------------------------------------------------------------
# 路径
# ---------------------------------------------------------------------------

DTS="$ROOT/target/linux/qualcommax/dts/ipq8072-sax1v1k.dts"

CFG="$ROOT/target/linux/qualcommax/config-6.12"

PATCH_DIR="$ROOT/target/linux/qualcommax/patches-6.12"

PWM_DRIVER_PATCH="$PATCH_DIR/0141-pwm-driver-for-qualcomm-ipq6018-pwm-block.patch"

PERIOD_FIX_PATCH="$PATCH_DIR/0307-pwm-ipq-fix-period-calculation.patch"

[[ -f "$DTS" ]] ||
	die "找不到 SAX1V1K DTS:
$DTS"

[[ -f "$CFG" ]] ||
	die "找不到:
$CFG"

[[ -d "$PATCH_DIR" ]] ||
	die "找不到:
$PATCH_DIR"

[[ -f "$PWM_DRIVER_PATCH" ]] ||
	die "找不到 pwm-ipq 驱动 patch:
$PWM_DRIVER_PATCH"

info "源码目录：$ROOT"
info "DTS：$DTS"
info "PWM：channel=$CHANNEL GPIO=$PIN"
info "PWM base：$PWM_BASE"
info "PWM frequency：${FREQ}Hz"
info "PWM period：${PERIOD_NS}ns"

if [[ "$PWM_BASE" == "0x1941010" ]]; then
	warn "0x1941010 是目前基于同系列 Qualcomm PWM block 得出的最佳候选地址"
	warn "目前没有公开 IPQ8074 DTS 明确确认该地址，上板前仍应通过原厂 DTB/寄存器进一步验证"
fi

# ---------------------------------------------------------------------------
# GPIO / PWM 对照提示
# ---------------------------------------------------------------------------

case "$CHANNEL:$PIN" in
	3:32)
		info "确认使用 IPQ8074 原生 GPIO32 -> PWM3"
		;;

	2:27)
		info "使用 IPQ8074 原生 GPIO27 -> PWM2"
		;;

	0:18|0:21|0:25|0:29|0:63)
		info "GPIO$PIN 属于 IPQ8074 PWM0 复用组"
		;;

	1:19|1:22|1:26|1:30|1:64)
		info "GPIO$PIN 属于 IPQ8074 PWM1 复用组"
		;;

	2:20|2:23|2:27|2:31|2:66)
		info "GPIO$PIN 属于 IPQ8074 PWM2 复用组"
		;;

	3:24|3:28|3:32|3:67)
		info "GPIO$PIN 属于 IPQ8074 PWM3 复用组"
		;;

	*)
		warn "没有对 GPIO$PIN / PWM$CHANNEL 做内置复用检查"
		;;
esac

# ---------------------------------------------------------------------------
# 备份
#
# 不重复覆盖最初备份，避免第二次执行脚本以后无法回滚到原始文件。
# ---------------------------------------------------------------------------

if [[ ! -f "$DTS.bak-fan" ]]; then
	cp -a "$DTS" "$DTS.bak-fan"
	info "已备份 DTS：$DTS.bak-fan"
else
	info "保留已有 DTS 备份：$DTS.bak-fan"
fi

if [[ ! -f "$CFG.bak-fan" ]]; then
	cp -a "$CFG" "$CFG.bak-fan"
	info "已备份 config：$CFG.bak-fan"
else
	info "保留已有 config 备份：$CFG.bak-fan"
fi

# ---------------------------------------------------------------------------
# 工具函数：删除本脚本之前生成的标记块
# ---------------------------------------------------------------------------

remove_marker_block()
{
	local file="$1"
	local begin="$2"
	local end="$3"

	[[ -f "$file" ]] || return 0

	awk -v begin="$begin" -v end="$end" '
		index($0, begin) {
			skip=1
			next
		}

		index($0, end) {
			skip=0
			next
		}

		!skip {
			print
		}
	' "$file" > "$file.tmp"

	mv "$file.tmp" "$file"
}

# ---------------------------------------------------------------------------
# [1] CONFIG_PWM_IPQ=y
# ---------------------------------------------------------------------------

if grep -q '^CONFIG_PWM_IPQ=' "$CFG"; then

	sed -i \
		's/^CONFIG_PWM_IPQ=.*/CONFIG_PWM_IPQ=y/' \
		"$CFG"

else

	cat >> "$CFG" <<'EOF'

#
# SAX1V1K hardware PWM fan
#
CONFIG_PWM_IPQ=y
EOF

fi

grep -q '^CONFIG_PWM_IPQ=y$' "$CFG" ||
	die "CONFIG_PWM_IPQ=y 写入失败"

info "CONFIG_PWM_IPQ=y"

# ---------------------------------------------------------------------------
# [2] OpenWrt package
#
# pwm-fan 是 hwmon 下的 pwmfan 驱动。
# ---------------------------------------------------------------------------

if [[ -f "$ROOT/.config" ]]; then

	if grep -q '^CONFIG_PACKAGE_kmod-hwmon-pwmfan=' "$ROOT/.config"; then
		sed -i \
			's/^CONFIG_PACKAGE_kmod-hwmon-pwmfan=.*/CONFIG_PACKAGE_kmod-hwmon-pwmfan=y/' \
			"$ROOT/.config"
	else
		echo 'CONFIG_PACKAGE_kmod-hwmon-pwmfan=y' >> "$ROOT/.config"
	fi

	if grep -q '^CONFIG_PACKAGE_kmod-hwmon-core=' "$ROOT/.config"; then
		sed -i \
			's/^CONFIG_PACKAGE_kmod-hwmon-core=.*/CONFIG_PACKAGE_kmod-hwmon-core=y/' \
			"$ROOT/.config"
	else
		echo 'CONFIG_PACKAGE_kmod-hwmon-core=y' >> "$ROOT/.config"
	fi

	info ".config: kmod-hwmon-pwmfan=y"

else

	warn "没有找到 .config，跳过 kmod-hwmon-pwmfan 配置"
	warn "编译前请确认：CONFIG_PACKAGE_kmod-hwmon-pwmfan=y"

fi

# ---------------------------------------------------------------------------
# [3] 修复 pwm-ipq 的 25kHz period calculation
#
# 原版驱动把 pwm_div 固定在最大值附近：
#
#     pwm_div = 65534
#
# 100MHz / 25kHz = 4000 clocks
#
# 因此原算法会计算出 pre_div=0，并返回 -ERANGE。
#
# Linux 2026-08 已经有对应修复：
# 根据 period 搜索合适的 pre_div / pwm_div。
#
# 如果当前 0141 已经包含 best_pre_div，则认为已经修复。
# ---------------------------------------------------------------------------

if grep -q 'best_pre_div' "$PWM_DRIVER_PATCH"; then

	info "0141 pwm-ipq 已包含 period calculation 修复"
	rm -f "$PERIOD_FIX_PATCH"

else

	info "0141 pwm-ipq 仍是旧 period calculation"
	info "生成 0307-pwm-ipq-fix-period-calculation.patch"

	cat > "$PERIOD_FIX_PATCH" <<'EOF'
From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001
From: SAX1V1K fan patch <local>
Subject: [PATCH] pwm: ipq: fix short period calculation for 25kHz fans

The original IPQ PWM driver fixes pwm_div close to its maximum.
This makes short periods such as 25kHz unusable.

Search for a representable (pre_div, pwm_div) pair instead.

---
 drivers/pwm/pwm-ipq.c | 91 ++++++++++++++++++++++++++++++-------------
 1 file changed, 65 insertions(+), 26 deletions(-)

diff --git a/drivers/pwm/pwm-ipq.c b/drivers/pwm/pwm-ipq.c
--- a/drivers/pwm/pwm-ipq.c
+++ b/drivers/pwm/pwm-ipq.c
@@ -89,10 +89,10 @@ static int ipq_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 	struct ipq_pwm_chip *ipq_chip = ipq_pwm_from_chip(chip);
-	unsigned int pre_div, pwm_div;
-	u64 period_ns, duty_ns;
+	unsigned int pre_div, pwm_div, best_pre_div, best_pwm_div;
+	u64 period_ns, duty_ns, period_rate, min_diff;
 	unsigned long val = 0;
-	unsigned long hi_dur;
+	u64 hi_dur;

@@ -112,35 +112,74 @@ static int ipq_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 	period_ns = min(state->period, IPQ_PWM_MAX_PERIOD_NS);
 	duty_ns = min(state->duty_cycle, period_ns);

-	/*
-	 * Pick the maximal value for PWM_DIV that still allows a
-	 * 100% relative duty cycle. This allows a fine grained
-	 * selection of duty cycles.
-	 */
-	pwm_div = IPQ_PWM_MAX_DIV - 1;
+	period_rate = period_ns * ipq_chip->clk_rate;
+
+	best_pre_div = IPQ_PWM_MAX_DIV;
+	best_pwm_div = IPQ_PWM_MAX_DIV;
+	min_diff = period_rate;
 
 	/*
-	 * although mul_u64_u64_div_u64 returns a u64, in practice it
-	 * won't overflow due to above constraints. Take the max period
-	 * of 10^9 (NSEC_PER_SEC) and the pwm_div + 1 (IPQ_PWM_MAX_DIV)
-	 * 10^9 * 10^8
-	 * ------------- => which fits well into a 32-bit unsigned int.
-	 * 10^9 * 65,535
+	 * Smaller pre_div than this cannot represent the period (pwm_div would
+	 * have to exceed its field), so start the search there.
 	 */
-	pre_div = mul_u64_u64_div_u64(period_ns, ipq_chip->clk_rate,
-				      (u64)NSEC_PER_SEC * (pwm_div + 1));
-
-	if (!pre_div)
-		return -ERANGE;
+	pre_div = div64_u64(period_rate,
+			    (u64)NSEC_PER_SEC * (IPQ_PWM_MAX_DIV + 1));
+
+	for (; pre_div <= IPQ_PWM_MAX_DIV; pre_div++) {
+		u64 remainder;
+
+		pwm_div = div64_u64_rem(period_rate,
+					(u64)NSEC_PER_SEC * (pre_div + 1),
+					&remainder);
+		pwm_div--;
+
+		if (pre_div > pwm_div)
+			break;
+
+		if (pwm_div > IPQ_PWM_MAX_DIV - 1)
+			continue;
+
+		if (remainder < min_diff) {
+			best_pre_div = pre_div;
+			best_pwm_div = pwm_div;
+			min_diff = remainder;
+
+			if (min_diff == 0)
+				break;
+		}
+	}
+
+	pre_div = best_pre_div;
+	pwm_div = best_pwm_div;
+
+	if (pwm_div > IPQ_PWM_MAX_DIV - 1)
+		pwm_div = IPQ_PWM_MAX_DIV - 1;
 
-	pre_div -= 1;
-	if (pre_div > IPQ_PWM_MAX_DIV)
-		pre_div = IPQ_PWM_MAX_DIV;
-
-	/* pwm duty = HI_DUR * (PRE_DIV + 1) / clk_rate */
-	hi_dur = mul_u64_u64_div_u64(duty_ns, ipq_chip->clk_rate,
-				     (u64)NSEC_PER_SEC * (pre_div + 1));
+	hi_dur = DIV64_U64_ROUND_CLOSEST(duty_ns * ipq_chip->clk_rate,
+					 (u64)(pre_div + 1) * NSEC_PER_SEC);
+	if (hi_dur > (u64)pwm_div + 1)
+		hi_dur = (u64)pwm_div + 1;

 	val = FIELD_PREP(IPQ_PWM_REG0_HI_DURATION, hi_dur) |
 		FIELD_PREP(IPQ_PWM_REG0_PWM_DIV, pwm_div);
--
2.39.5
EOF

fi

# ---------------------------------------------------------------------------
# [4] 删除旧的 DTS 片段
# ---------------------------------------------------------------------------

remove_marker_block \
	"$DTS" \
	"/* BEGIN SAX1V1K FAN PWM */" \
	"/* END SAX1V1K FAN PWM */"

remove_marker_block \
	"$DTS" \
	"/* BEGIN SAX1V1K FAN PINCTRL */" \
	"/* END SAX1V1K FAN PINCTRL */"

remove_marker_block \
	"$DTS" \
	"/* BEGIN SAX1V1K FAN THERMAL */" \
	"/* END SAX1V1K FAN THERMAL */"

# ---------------------------------------------------------------------------
# [5] 时钟
#
# 默认使用 GCC_ADSS_PWM_CLK。
#
# 这是 IPQ PWM block 使用的标准 ADSS PWM clock 名称。
#
# --xo-clock 可用于硬件验证阶段：
#
#     clocks = <&xo_board_clk>;
#
# 这样可以绕过 GCC ADSS PWM clock 定义，方便排查时钟问题。
# ---------------------------------------------------------------------------

if [[ "$XO_CLOCK" -eq 1 ]]; then

	CLOCK_BLOCK=$(cat <<'EOF'
		clocks = <&xo_board_clk>;
EOF
)

	info "PWM clock: xo_board_clk"

else

	CLOCK_BLOCK=$(cat <<'EOF'
		clocks = <&gcc GCC_ADSS_PWM_CLK>;
		assigned-clocks = <&gcc GCC_ADSS_PWM_CLK>;
		assigned-clock-rates = <100000000>;
EOF
)

	info "PWM clock: GCC_ADSS_PWM_CLK @ 100MHz"

fi

# ---------------------------------------------------------------------------
# [6] 生成 root 节点内容
#
# #pwm-cells 使用 3：
#
#   <channel period polarity>
#
# pwm-fan：
#
#   <&sax1v1k_pwm channel period 0>
# ---------------------------------------------------------------------------

ROOT_BLOCK="$(mktemp)"

cat > "$ROOT_BLOCK" <<EOF
	/* BEGIN SAX1V1K FAN PWM */

	sax1v1k_pwm: pwm@$PWM_BASE {
		/*
		 * IPQ8074 本身已有 gpio32 -> pwm3。
		 *
		 * driver 当前只匹配 ipq6018-pwm，
		 * 因此这里采用双 compatible：
		 *
		 *   第一优先：IPQ8074
		 *   fallback ：IPQ6018
		 *
		 * 不需要修改 pwm-ipq driver 的 of_match。
		 */
		compatible = "qcom,ipq8074-pwm", "qcom,ipq6018-pwm";

		reg = <$PWM_BASE 0x20>;

$CLOCK_BLOCK

		#pwm-cells = <3>;

		pinctrl-names = "default";
		pinctrl-0 = <&fan_pwm_pins>;

		status = "okay";
	};

	sax1v1k_fan: pwm-fan {
		compatible = "pwm-fan";

		/*
		 * 25kHz = 40000ns
		 *
		 * channel = $CHANNEL
		 * polarity = normal
		 */
		pwms = <&sax1v1k_pwm $CHANNEL $PERIOD_NS 0>;

		/*
		 * 最低档不要设为 0%，避免四线风扇频繁停转/重启。
		 *
		 * 25% / 38% / 50% / 63% / 78% / 100%
		 */
		cooling-levels = <64 96 128 160 200 255>;

		cooling-min-state = <0>;
		cooling-max-state = <5>;

		#cooling-cells = <2>;
	};

	/* END SAX1V1K FAN PWM */
EOF

# ---------------------------------------------------------------------------
# 将 root block 插入 / { ... } 的最后
# ---------------------------------------------------------------------------

TMP_DTS="$(mktemp)"

awk -v block="$ROOT_BLOCK" '
BEGIN {
	n = 0;
	while ((getline line < block) > 0)
		buf[++n] = line;
	close(block);
}

/^\/[[:space:]]*\{/ {
	in_root = 1;
	depth = 0;
}

{
	line = $0;

	if (in_root) {
		tmp = line;

		open_count = gsub(/\{/, "{", tmp);
		close_count = gsub(/\}/, "}", tmp);

		depth += open_count - close_count;

		if (depth == 0) {
			for (i = 1; i <= n; i++)
				print buf[i];

			print line;

			in_root = 0;
			next;
		}
	}

	print line;
}
' "$DTS" > "$TMP_DTS"

mv "$TMP_DTS" "$DTS"

rm -f "$ROOT_BLOCK"

grep -q "sax1v1k_pwm: pwm@$PWM_BASE" "$DTS" ||
	die "PWM controller 插入失败"

grep -q "sax1v1k_fan: pwm-fan" "$DTS" ||
	die "pwm-fan 插入失败"

info "PWM controller + pwm-fan 已加入 DTS"

# ---------------------------------------------------------------------------
# [7] GPIO pinctrl
#
# IPQ8074 已经原生定义：
#
#   pwm3_groups = gpio24 gpio28 gpio32 gpio67
#
# 因此这里只添加 DTS，不修改 pinctrl-ipq8074.c。
#
# 采用单独的 &tlmm fragment，避免破坏原有 &tlmm 节点。
# ---------------------------------------------------------------------------

cat >> "$DTS" <<EOF

	/* BEGIN SAX1V1K FAN PINCTRL */

&tlmm {
	fan_pwm_pins: fan-pwm-pins {
		pins = "gpio$PIN";
		function = "pwm$CHANNEL";
		drive-strength = <8>;
		bias-disable;
	};
};

	/* END SAX1V1K FAN PINCTRL */
EOF

grep -q "fan_pwm_pins: fan-pwm-pins" "$DTS" ||
	die "pinctrl 插入失败"

info "GPIO$PIN -> PWM$CHANNEL pinctrl 已加入"

# ---------------------------------------------------------------------------
# [8] 可选 thermal
#
# 不直接假定 cpu_thermal 一定存在。
#
# 必须能在现有源码中找到：
#
#     cpu_thermal:
#
# 才自动加入。
# ---------------------------------------------------------------------------

if [[ "$THERMAL" -eq 1 ]]; then

	CPU_THERMAL_FOUND=0

	if grep -Rqs \
		'cpu_thermal:[[:space:]]*cpu-thermal' \
		"$ROOT/target/linux/qualcommax" \
		"$ROOT/build_dir" 2>/dev/null; then

		CPU_THERMAL_FOUND=1

	fi

	if [[ "$CPU_THERMAL_FOUND" -eq 0 ]]; then

		warn "没有找到带 label 的 cpu_thermal:"
		warn "跳过 thermal cooling-map"
		warn "PWM 风扇本身仍会正常注册"

	else

		cat >> "$DTS" <<'EOF'

	/* BEGIN SAX1V1K FAN THERMAL */

&cpu_thermal {
	trips {
		sax1v1k_fan_trip: sax1v1k-fan-trip {
			temperature = <65000>;
			hysteresis = <5000>;
			type = "active";
		};
	};

	cooling-maps {
		sax1v1k_fan_map {
			trip = <&sax1v1k_fan_trip>;
			cooling-device = <&sax1v1k_fan 0 5>;
		};
	};
};

	/* END SAX1V1K FAN THERMAL */
EOF

		info "已加入 CPU 65°C -> PWM fan thermal cooling-map"

	fi
fi

# ---------------------------------------------------------------------------
# [9] 最终检查
# ---------------------------------------------------------------------------

echo
echo "============================================================"
echo " SAX1V1K PWM FAN PATCH SUMMARY"
echo "============================================================"
echo
echo "DTS:"
echo "  $DTS"
echo
echo "PWM:"
echo "  base      = $PWM_BASE"
echo "  channel   = $CHANNEL"
echo "  GPIO      = $PIN"
echo "  frequency = ${FREQ} Hz"
echo "  period    = ${PERIOD_NS} ns"
echo

grep -n \
	-E 'sax1v1k_pwm:|sax1v1k_fan:|fan_pwm_pins:' \
	"$DTS" || true

echo
echo "Kernel config:"
grep -E '^CONFIG_PWM_IPQ=' "$CFG" || true

if [[ -f "$ROOT/.config" ]]; then
	echo
	echo "Package config:"
	grep -E '^CONFIG_PACKAGE_kmod-hwmon-(core|pwmfan)=' \
		"$ROOT/.config" || true
fi

echo
echo "PWM driver patch:"
echo "  $PWM_DRIVER_PATCH"

if [[ -f "$PERIOD_FIX_PATCH" ]]; then
	echo
	echo "25kHz period fix:"
	echo "  $PERIOD_FIX_PATCH"
fi

echo
echo "============================================================"
echo " 编译前建议执行："
echo
echo "  make defconfig"
echo
echo "然后检查："
echo
echo "  grep -E 'CONFIG_PWM_IPQ|CONFIG_PACKAGE_kmod-hwmon-pwmfan' .config"
echo
echo "============================================================"
echo
echo "烧录后第一阶段检查："
echo
echo "  dmesg | grep -iE 'pwm|fan'"
echo
echo "  ls -l /sys/class/pwm/"
echo
echo "  ls -l /sys/class/hwmon/"
echo
echo "============================================================"
echo
echo "回滚："
echo
echo "  cp -a \"$DTS.bak-fan\" \"$DTS\""
echo "  cp -a \"$CFG.bak-fan\" \"$CFG\""
echo
echo "============================================================"
