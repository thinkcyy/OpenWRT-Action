#!/usr/bin/env bash
#
# sax1v1k-pwm-fan.sh
#
# Adds PWM fan control for the Spectrum SAX1V1K (Askey RT5010W-D187 REV6)
# to the AgustinLorenzo/openwrt tree: gpio27 -> PWM channel 2 -> pwm-fan,
# hooked into the cluster thermal zone.
#
# Run it from the repository root BEFORE building:
#
#     bash sax1v1k-pwm-fan.sh                 # repo root = current directory
#     bash sax1v1k-pwm-fan.sh /path/to/openwrt
#
# Changes made (the script is idempotent):
#   1. new kernel patch  target/linux/qualcommax/patches-6.12/NNNN-clk-qcom-gcc-ipq8074-add-ADSS-PWM-clock.patch
#      Generated from the kernel tarball in dl/ (with the repo's earlier patches
#      for the same two files applied first) so the context always matches.
#   2. target/linux/qualcommax/ipq807x/config-default   PWM options
#   3. target/linux/qualcommax/image/ipq807x.mk         kmod-hwmon-pwmfan for spectrum_sax1v1k
#   4. target/linux/qualcommax/files/.../ipq8072-sax1v1k.dts  pwm, pinctrl, pwm-fan, thermal
#   5. only if required: "FEATURES += pwm" in target/linux/qualcommax/Makefile
#
# NOT verified on hardware: the ADSS PWM clock offsets (0x1c008 / 0x1c020) are
# taken from IPQ6018. Test an initramfs build first; do not flash eMMC until
# dmesg shows no "stuck at 'off'" and clk_rate is 100000000.

set -euo pipefail

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

ROOT="${1:-$PWD}"
cd "$ROOT" || die "cannot cd to $ROOT"

QC=target/linux/qualcommax
PDIR=$QC/patches-6.12
DTS=$QC/files/arch/arm64/boot/dts/qcom/ipq8072-sax1v1k.dts
MK=$QC/image/ipq807x.mk
CFG=$QC/ipq807x/config-default
PATCH_SUFFIX=clk-qcom-gcc-ipq8074-add-ADSS-PWM-clock.patch

# ---------------------------------------------------------------- sanity ----
[ -d "$PDIR" ] || die "$PDIR not found - run from the openwrt repo root"
[ -f "$DTS" ]  || die "$DTS not found"
[ -f "$MK" ]   || die "$MK not found"
command -v python3 >/dev/null || die "python3 is required"
command -v patch   >/dev/null || die "patch is required"
command -v tar     >/dev/null || die "tar is required"

DRV_PATCH=$(grep -l '^+++ b/drivers/pwm/pwm-ipq.c' "$PDIR"/*.patch 2>/dev/null | head -n1 || true)
[ -n "$DRV_PATCH" ] || die "no patch in $PDIR adds drivers/pwm/pwm-ipq.c (expected 0141-*.patch)"
COMPAT=$(grep -o 'compatible = "qcom,[a-z0-9]*-pwm"' "$DRV_PATCH" | head -n1 | sed 's/.*"\(.*\)"/\1/' || true)
COMPAT=${COMPAT:-qcom,ipq6018-pwm}
say "PWM driver patch: $(basename "$DRV_PATCH") (compatible $COMPAT)"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------- 1. GCC clock patch --------
existing=$(ls "$PDIR"/*-"$PATCH_SUFFIX" 2>/dev/null | head -n1 || true)
if [ -n "$existing" ]; then
	say "kernel clock patch already present: $(basename "$existing") - skipping"
else
	TAR=$(ls dl/linux-6.12*.tar.xz 2>/dev/null | sort -V | tail -n1 || true)
	[ -n "$TAR" ] || die "kernel tarball dl/linux-6.12*.tar.xz not found (run: make target/linux/download V=s)"
	say "generating clock patch from $TAR"

	prior=()
	for d in target/linux/generic/backport-6.12 target/linux/generic/pending-6.12 \
	         target/linux/generic/hack-6.12 "$PDIR"; do
		[ -d "$d" ] || continue
		while IFS= read -r f; do prior+=("$f"); done < <(ls "$d"/*.patch 2>/dev/null | sort)
	done

	cat > "$WORK/gen.py" <<'PYEOF'
import difflib, os, re, shutil, subprocess, sys

tarball, work, out, pdir = sys.argv[1:5]
priors = sys.argv[5:]

GCC_C = "drivers/clk/qcom/gcc-ipq8074.c"
GCC_H = "include/dt-bindings/clock/qcom,gcc-ipq8074.h"
FILES = (GCC_C, GCC_H)
pdir = os.path.abspath(pdir)
a = os.path.abspath(os.path.join(work, "a"))
b = os.path.abspath(os.path.join(work, "b"))


def die(msg, code=2):
    sys.stderr.write("gen: " + msg + "\n")
    sys.exit(code)


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


os.makedirs(a, exist_ok=True)
r = run(["tar", "-xJf", tarball, "-C", a, "--strip-components=1",
         "--wildcards"] + ["*/" + f for f in FILES])
if r.returncode:
    die("cannot extract from %s: %s" % (tarball, r.stderr.strip()))
for f in FILES:
    if not os.path.isfile(os.path.join(a, f)):
        die("%s not found in tarball" % f)


def sections(text):
    parts = re.split(r'(?m)^(?=diff --git )', text)
    if len(parts) == 1:
        parts = re.split(r'(?m)^(?=--- )', text)
    return parts


def touches(chunk):
    m = re.search(r'(?m)^\+\+\+ (?:b/)?(\S+)', chunk)
    return bool(m) and m.group(1) in FILES


# Bring the two files to the state they have when our patch is applied.
maxtouch = 0
touching = []
tmp = os.path.join(work, "prior.diff")
for p in priors:
    with open(p, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    chunks = [c for c in sections(text) if touches(c)]
    if not chunks:
        continue
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write("".join(chunks))
    r = run(["patch", "-p1", "-d", a, "--no-backup-if-mismatch", "-s", "-i", tmp])
    if r.returncode:
        die("prior patch %s does not apply to the pristine files:\n%s%s"
            % (p, r.stdout, r.stderr))
    touching.append(os.path.basename(p))
    if os.path.dirname(os.path.abspath(p)) == pdir:
        m = re.match(r'(\d+)-', os.path.basename(p))
        if m:
            maxtouch = max(maxtouch, int(m.group(1)))

shutil.copytree(a, b)

# ---- header: two new clock ids after the highest existing id ----------------
hp = os.path.join(b, GCC_H)
with open(hp, encoding="utf-8") as fh:
    h = fh.read()
if "GCC_ADSS_PWM_CLK" in h:
    sys.stderr.write("gen: GCC_ADSS_PWM_CLK already defined in the kernel header\n")
    sys.exit(3)
nums = [int(n) for n in re.findall(r'(?m)^#define\s+\w+\s+(\d+)\b', h)]
if not nums:
    die("no numeric #define found in " + GCC_H)
mx = max(nums)
m = re.search(r'(?m)^#define(\s+)(\S+)(\s+)%d\b[^\n]*\n' % mx, h)
if not m:
    die("cannot locate the define with the highest id (%d)" % mx)
width = len(m.group(2)) + len(m.group(3))


def define(name, val):
    return "#define %s%s\n" % (name.ljust(max(width, len(name) + 1)), val)


new_defs = define("GCC_ADSS_PWM_CLK_SRC", mx + 1) + define("GCC_ADSS_PWM_CLK", mx + 2)
h = h[:m.end()] + new_defs + h[m.end():]
with open(hp, "w", encoding="utf-8") as fh:
    fh.write(h)

# ---- driver -----------------------------------------------------------------
cp = os.path.join(b, GCC_C)
with open(cp, encoding="utf-8") as fh:
    c = fh.read()
if "adss_pwm_clk_src" in c:
    sys.stderr.write("gen: adss_pwm_clk_src already present in gcc-ipq8074.c\n")
    sys.exit(3)

BLOCK = '''
static const struct freq_tbl ftbl_adss_pwm_clk_src[] = {
	F(24000000, P_XO, 1, 0, 0),
	F(100000000, P_GPLL0, 8, 0, 0),
	{ }
};

static struct clk_rcg2 adss_pwm_clk_src = {
	.cmd_rcgr = 0x1c008,
	.freq_tbl = ftbl_adss_pwm_clk_src,
	.hid_width = 5,
	.parent_map = gcc_xo_gpll0_map,
	.clkr.hw.init = &(struct clk_init_data){
		.name = "adss_pwm_clk_src",
		.parent_data = gcc_xo_gpll0,
		.num_parents = ARRAY_SIZE(gcc_xo_gpll0),
		.ops = &clk_rcg2_ops,
	},
};

static struct clk_branch gcc_adss_pwm_clk = {
	.halt_reg = 0x1c020,
	.clkr = {
		.enable_reg = 0x1c020,
		.enable_mask = BIT(0),
		.hw.init = &(struct clk_init_data){
			.name = "gcc_adss_pwm_clk",
			.parent_hws = (const struct clk_hw *[]){
				&adss_pwm_clk_src.clkr.hw },
			.num_parents = 1,
			.flags = CLK_SET_RATE_PARENT,
			.ops = &clk_branch2_ops,
		},
	},
};
'''

m1 = re.search(r'static const struct parent_map gcc_xo_gpll0_map\[\] = \{.*?\n\};\n', c, re.S)
if not m1:
    die("anchor 'gcc_xo_gpll0_map' not found in gcc-ipq8074.c")
c = c[:m1.end()] + BLOCK + c[m1.end():]

m2 = re.search(r'(static struct clk_regmap \*gcc_ipq8074_clks\[\] = \{.*?)(\n\};\n)', c, re.S)
if not m2:
    die("anchor 'gcc_ipq8074_clks[]' not found in gcc-ipq8074.c")
entries = ("\n\t[GCC_ADSS_PWM_CLK_SRC] = &adss_pwm_clk_src.clkr,"
           "\n\t[GCC_ADSS_PWM_CLK] = &gcc_adss_pwm_clk.clkr,")
c = c[:m2.end(1)] + entries + c[m2.end(1):]
with open(cp, "w", encoding="utf-8") as fh:
    fh.write(c)


def mkdiff(path):
    with open(os.path.join(a, path), encoding="utf-8") as fa, \
         open(os.path.join(b, path), encoding="utf-8") as fb:
        A, B = fa.readlines(), fb.readlines()
    d = "".join(difflib.unified_diff(A, B, "a/" + path, "b/" + path))
    return "diff --git a/%s b/%s\n%s" % (path, path, d)


HEADER = """From: sax1v1k-pwm-fan.sh <noreply@invalid>
Subject: [PATCH] clk: qcom: gcc-ipq8074: add ADSS PWM clock

Add the ADSS PWM clock source and branch clock to the IPQ8074 GCC.
Register layout and frequency table follow gcc-ipq6018.c; the PWM block
of the SAX1V1K needs a 100 MHz clock (GPLL0 / 8) on this SoC.
---
"""
with open(out, "w", encoding="utf-8") as fh:
    fh.write(HEADER + mkdiff(GCC_H) + mkdiff(GCC_C))

r = run(["patch", "-p1", "--dry-run", "-d", a, "-i", os.path.abspath(out)])
if r.returncode:
    die("generated patch does not apply to its own base:\n%s%s" % (r.stdout, r.stderr))

print("MAXTOUCH=%d" % maxtouch)
print("TOUCHING=%s" % ",".join(touching))
print("IDS=%d,%d" % (mx + 1, mx + 2))
PYEOF

	rc=0
	python3 "$WORK/gen.py" "$TAR" "$WORK/t" "$WORK/gen.patch" "$PDIR" "${prior[@]}" \
		> "$WORK/gen.out" || rc=$?
	if [ "$rc" -eq 3 ]; then
		warn "the kernel already defines the ADSS PWM clock - no clock patch needed"
	elif [ "$rc" -ne 0 ]; then
		die "clock patch generation failed (see message above)"
	else
		MAXTOUCH=$(sed -n 's/^MAXTOUCH=//p' "$WORK/gen.out")
		TOUCHING=$(sed -n 's/^TOUCHING=//p' "$WORK/gen.out")
		IDS=$(sed -n 's/^IDS=//p' "$WORK/gen.out")
		[ -z "$TOUCHING" ] || say "other patches touching the same files (applied first): $TOUCHING"

		n=$(( 10#${MAXTOUCH:-0} ))
		[ "$n" -lt 141 ] && n=141
		n=$((n + 1))
		while ls "$PDIR"/"$(printf '%04d' "$n")"-* >/dev/null 2>&1; do n=$((n + 1)); done
		OUT="$PDIR/$(printf '%04d' "$n")-$PATCH_SUFFIX"
		cp "$WORK/gen.patch" "$OUT"
		say "wrote $OUT (clock ids $IDS)"
	fi
fi

# --------------------------------------------------- 2. kernel config --------
mkdir -p "$(dirname "$CFG")"
touch "$CFG"
[ -z "$(tail -c1 "$CFG")" ] || echo >> "$CFG"
for opt in CONFIG_PWM=y CONFIG_PWM_IPQ=y CONFIG_PWM_SYSFS=y; do
	key=${opt%%=*}
	if grep -q "^${key}=" "$CFG"; then
		say "$CFG already sets $key"
	else
		echo "$opt" >> "$CFG"
		say "$CFG: added $opt"
	fi
done

# ------------------------------------------------ 3. device packages ---------
if sed -n '/^define Device\/spectrum_sax1v1k/,/^endef/p' "$MK" | grep -q 'kmod-hwmon-pwmfan'; then
	say "$MK already lists kmod-hwmon-pwmfan"
else
	sed -i '/^define Device\/spectrum_sax1v1k/,/^endef/ s/^\(\s*DEVICE_PACKAGES := \)/\1kmod-hwmon-pwmfan /' "$MK"
	sed -n '/^define Device\/spectrum_sax1v1k/,/^endef/p' "$MK" | grep -q 'kmod-hwmon-pwmfan' \
		|| die "could not add kmod-hwmon-pwmfan to spectrum_sax1v1k in $MK (edit DEVICE_PACKAGES by hand)"
	say "$MK: added kmod-hwmon-pwmfan"
fi

# ----------------------------------------- 4. target feature (if needed) -----
HWMON_MK=package/kernel/linux/modules/hwmon.mk
if [ -f "$HWMON_MK" ] \
   && awk '/define KernelPackage\/hwmon-pwmfan/,/^endef/' "$HWMON_MK" | grep -q 'PWM_SUPPORT' \
   && ! grep -Eq '(^|[[:space:]])pwm([[:space:]]|$)' "$QC/Makefile"; then
	if grep -q '^include \$(INCLUDE_DIR)/target.mk' "$QC/Makefile"; then
		sed -i '0,/^include \$(INCLUDE_DIR)\/target.mk/ s//FEATURES += pwm\n\n&/' "$QC/Makefile"
		say "$QC/Makefile: added FEATURES += pwm (kmod-hwmon-pwmfan depends on PWM_SUPPORT)"
	else
		warn "kmod-hwmon-pwmfan needs the 'pwm' target feature; add 'FEATURES += pwm' to $QC/Makefile by hand"
	fi
fi

# ------------------------------------------------------- 5. device tree ------
if grep -q 'pwm_pins:' "$DTS"; then
	say "$DTS already contains the PWM fan nodes - skipping"
else
	[ -z "$(tail -c1 "$DTS")" ] || echo >> "$DTS"
	cat >> "$DTS" <<EOF

/*
 * PWM fan (added by sax1v1k-pwm-fan.sh)
 * The fan is switched by gpio27: high = on. gpio27 muxes to PWM channel 2.
 * Trip temperatures are starting values, tune them after measuring.
 */
&tcsr {
	compatible = "qcom,tcsr-ipq8074", "syscon", "simple-mfd";
	ranges = <0x0 0x01937000 0x21000>;
	#address-cells = <1>;
	#size-cells = <1>;

	pwm: pwm@a010 {
		compatible = "$COMPAT";
		reg = <0xa010 0x20>;
		clocks = <&gcc GCC_ADSS_PWM_CLK>;
		assigned-clocks = <&gcc GCC_ADSS_PWM_CLK>;
		assigned-clock-rates = <100000000>;
		#pwm-cells = <2>;
		pinctrl-0 = <&pwm_pins>;
		pinctrl-names = "default";
		status = "okay";
	};
};

&tlmm {
	pwm_pins: pwm-state {
		fan-pwm {
			pins = "gpio27";
			function = "pwm2";
			drive-strength = <2>;
			bias-pull-down;
		};
	};
};

/ {
	fan: pwm-fan {
		compatible = "pwm-fan";
		pwms = <&pwm 2 40000>;
		cooling-levels = <0 90 150 210 255>;
		#cooling-cells = <2>;
	};
};

&cluster_thermal {
	trips {
		fan_low: fan-low {
			temperature = <60000>;
			hysteresis = <3000>;
			type = "active";
		};

		fan_mid: fan-mid {
			temperature = <70000>;
			hysteresis = <3000>;
			type = "active";
		};

		fan_high: fan-high {
			temperature = <80000>;
			hysteresis = <3000>;
			type = "active";
		};
	};

	cooling-maps {
		map-fan-low {
			trip = <&fan_low>;
			cooling-device = <&fan 1 1>;
		};

		map-fan-mid {
			trip = <&fan_mid>;
			cooling-device = <&fan 2 2>;
		};

		map-fan-high {
			trip = <&fan_high>;
			cooling-device = <&fan 3 4>;
		};
	};
};
EOF
	say "$DTS: appended PWM fan nodes"
fi

# ----------------------------------------------------------------- done ------
echo
say "done. Review the changes:"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	git status --short
else
	echo "(not a git checkout - no status available)"
fi
cat <<'EOT'

Next steps:
  1. make target/linux/{clean,prepare} V=s      # every patch must apply
  2. build an initramfs image, boot it over serial - do NOT flash eMMC yet
  3. on the device:
       dmesg | grep -iE 'adss|pwm|stuck|gcc'
       cat /sys/kernel/debug/clk/gcc_adss_pwm_clk/clk_rate     # 100000000
       ls /sys/class/pwm/ /sys/class/hwmon/*/pwm1
     then lower the duty by hand and check the fan really follows it.
EOT
