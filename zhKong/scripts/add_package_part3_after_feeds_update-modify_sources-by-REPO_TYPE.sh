#!/bin/bash
# patch-sax1v1k-pwm.sh
set -e

ROOT="$(pwd)"

echo "OpenWrt source: $ROOT"

# ------------------------------------------------------------
# 1. 找 SAX1V1K DTS
# ------------------------------------------------------------

DTS="$(grep -RIl \
    'compatible.*spectrum,sax1v1k' \
    "$ROOT/target/linux/qualcommax" \
    --include='*.dts' \
    --include='*.dtsi' 2>/dev/null | head -n1 || true)"

if [ -z "$DTS" ]; then
    echo "ERROR: 找不到 SAX1V1K DTS"
    echo
    echo "请执行："
    echo "  grep -RIl 'spectrum,sax1v1k' target/linux/qualcommax --include='*.dts'"
    exit 1
fi

echo "SAX1V1K DTS:"
echo "  $DTS"

# ------------------------------------------------------------
# 2. 检查原 DTS 是否已经存在 PWM
# ------------------------------------------------------------

if grep -q 'qca,ipq4019-pwm' "$DTS"; then
    echo
    echo "PWM controller 已经存在，不重复添加。"
else
    echo
    echo "添加 qca,ipq4019-pwm controller..."

    cp -a "$DTS" "$DTS.bak-pwm"

    cat >> "$DTS" <<'EOT'


	/* PWM 控制器：IPQ807x TCSR 区（stock dts 的 qca,ipq4019-pwm 同硬件块）
	 * reg 基址候选 0x194b000（QSDK ipq4019 系），需按第 5 节验证 */
	pwm: pwm@194b000 {
		compatible = "qcom,ipq8074-pwm";
		reg = <0x194b000 0x20>;		/* 4 通道 × 8 字节 */
		clocks = <&gcc GCC_APSS_PWM_CLK>;
		assigned-clocks = <&gcc GCC_APSS_PWM_CLK>;
		assigned-clock-rates = <100000000>;
		#pwm-cells = <2>;
	};

	/* 风扇：先按 gpio32=pwm3 写；如无效改 <&pwm 2 40000>（gpio27=pwm2） */
	fan: pwm-fan {
		compatible = "pwm-fan";
		pwms = <&pwm 2 40000>;		/* 25kHz 标准 4 线风扇 PWM */
		cooling-min-state = <0>;
		cooling-max-state = <4>;
		#cooling-cells = <2>;
	};
};


EOT

    echo "  PWM controller 已添加。"
fi

# ------------------------------------------------------------
# 3. 检查 pinctrl 是否已经存在
# ------------------------------------------------------------

if grep -q 'pwm_pinmux' "$DTS"; then
    echo
    echo "pwm_pinmux 已经存在，不重复添加。"
else
    echo
    echo "添加 pwm_pinmux..."

    cp -a "$DTS" "$DTS.bak-pwm-pinmux"

    cat >> "$DTS" <<'EOT'

/*
 * Factory PWM pinmux from Askey RT5010W-D187-REV6
 */
&pinctrl {
    pwm_pinmux: pwm-pinmux {
        pwm02 {
            pins = "gpio25";
            function = "pwm02";
            drive-strength = <8>;
        };

        pwm12 {
            pins = "gpio26";
            function = "pwm12";
            drive-strength = <8>;
        };

        pwm22 {
            pins = "gpio27";
            function = "pwm22";
            drive-strength = <8>;
        };

        pwm33 {
            pins = "gpio32";
            function = "pwm33";
            drive-strength = <8>;
        };
    };
};
EOT

    echo "  pwm_pinmux 已添加。"
fi

# ------------------------------------------------------------
# 4. 查找 qualcommax kernel config
# ------------------------------------------------------------

CONFIG=""

for f in \
    "$ROOT/target/linux/qualcommax/ipq807x/config-6.6" \
    "$ROOT/target/linux/qualcommax/config-6.6" \
    "$ROOT/target/linux/qualcommax/ipq807x/config-6.12" \
    "$ROOT/target/linux/qualcommax/config-6.12"
do
    if [ -f "$f" ]; then
        CONFIG="$f"
        break
    fi
done

if [ -z "$CONFIG" ]; then
    echo
    echo "WARNING: 没找到固定版本的 qualcommax kernel config。"
    echo "请执行："
    echo
    echo "  find target/linux/qualcommax -name 'config-*' -type f"
    echo
else
    echo
    echo "Kernel config:"
    echo "  $CONFIG"

    cp -a "$CONFIG" "$CONFIG.bak-pwm"

    # --------------------------------------------------------
    # PWM framework
    # --------------------------------------------------------

    add_config()
    {
        local c="$1"

        if grep -q "^${c}=y$" "$CONFIG"; then
            echo "  already: $c"
        else
            echo "$c=y" >> "$CONFIG"
            echo "  added:   $c"
        fi
    }

    echo
    echo "添加 PWM framework 配置..."

    add_config CONFIG_PWM

    # PWM sysfs interface
    add_config CONFIG_PWM_SYSFS

    # 常见情况下 pwm-fan 后面会需要
    add_config CONFIG_SENSORS_PWM_FAN

    echo
    echo "注意：暂不强制添加 vendor PWM driver 的 CONFIG 名称。"
    echo "先由内核 Kconfig 自动检查实际名称。"
fi

# ------------------------------------------------------------
# 5. 显示结果
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Patch result"
echo "============================================================"

echo
echo "[DTS PWM]"
grep -n -A15 -B3 'qca,ipq4019-pwm' "$DTS" || true

echo
echo "[DTS pinmux]"
grep -n -A30 -B3 'pwm_pinmux' "$DTS" || true

echo
echo "[Kernel PWM config]"
if [ -n "$CONFIG" ]; then
    grep -E 'CONFIG_(PWM|SENSORS_PWM_FAN)' "$CONFIG" || true
fi

echo
echo "============================================================"
echo "Backup files:"
echo "  $DTS.bak-pwm"
echo "  $DTS.bak-pwm-pinmux"
[ -n "$CONFIG" ] && echo "  $CONFIG.bak-pwm"
