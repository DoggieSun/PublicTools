#!/bin/bash

# 默认网卡接口
iface="eth0"

usage() {
    echo "Usage: $0 [-i interface]" >&2
    exit 1
}

while getopts "i:h" opt; do
    case $opt in
        i)
            iface="$OPTARG"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

masks=()
echo "收集到的 IRQ 和对应的 smp_affinity："
for irq in $(grep -i "$iface" /proc/interrupts | awk -F: '{print $1}'); do
    mask=$(cat /proc/irq/$irq/smp_affinity 2>/dev/null)
    if [ -z "$mask" ]; then
        continue
    fi
    mask=$(echo "$mask" | tr -d ',[:space:]')
    echo "IRQ $irq: $mask"
    masks+=("$mask")
done

if [ ${#masks[@]} -eq 0 ]; then
    echo "没有找到与 $iface 相关的 IRQ 或 smp_affinity 信息。" >&2
    exit 1
fi

result=$(printf "%s\n" "${masks[@]}" | python3 - "$iface" <<'PY'
import sys
union = 0
for line in sys.stdin:
    m = line.strip()
    if m:
        try:
            union |= int(m, 16)
        except Exception as e:
            sys.exit("转换错误: " + str(e))
print("Union SMP Affinity (hex): 0x{:x}".format(union))
binary_str = format(union, "b")
print("Union SMP Affinity (bin):", binary_str)
cpus = []
i = 0
u = union
while u:
    if u & 1:
        cpus.append(str(i))
    u >>= 1
    i += 1
print("CPU列表: " + ",".join(cpus))
PY
)

echo "$result"

