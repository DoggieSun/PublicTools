#!/bin/bash
# 收集所有与 eth0 相关 IRQ 的 smp_affinity 掩码
masks=()
echo "收集到的 IRQ 和对应的 smp_affinity："
for irq in $(grep -i eth0 /proc/interrupts | awk -F: '{print $1}'); do
    mask=$(cat /proc/irq/$irq/smp_affinity)
    # 去除逗号和所有空白字符，将类似 "00000000,00000000,00080000" 转换为连续字符串
    mask=$(echo "$mask" | tr -d ',[:space:]')
    echo "IRQ $irq: $mask"
    masks+=("$mask")
done

if [ ${#masks[@]} -eq 0 ]; then
    echo "没有找到与 eth0 相关的 IRQ 或 smp_affinity 信息。"
    exit 1
fi

# 使用 python3 读取所有掩码并计算按位 OR 的并集，同时输出二进制形式
result=$(printf "%s\n" "${masks[@]}" | python3 -c '
import sys
union = 0
for line in sys.stdin:
    m = line.strip()
    if m:
        try:
            union |= int(m, 16)
        except Exception as e:
            sys.exit("转换错误: " + str(e))
# 输出并集的十六进制表示
print("Union SMP Affinity (hex): 0x{:x}".format(union))
# 输出并集的二进制表示，不含前缀
binary_str = format(union, "b")
print("Union SMP Affinity (bin):", binary_str)
# 将并集转换为具体的 CPU 列表（从低位开始，每个1对应一个 CPU）
cpus = []
i = 0
u = union
while u:
    if u & 1:
        cpus.append(str(i))
    u >>= 1
    i += 1
print("CPU列表: " + ",".join(cpus))
')

echo "$result"