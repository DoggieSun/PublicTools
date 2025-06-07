# PublicTools

This repository hosts small utility scripts for system administration.

## irq.sh

`irq.sh` gathers the `smp_affinity` masks of all IRQs related to a network
interface and prints their bitwise union. This can help check which CPUs can
handle interrupts from a specific device.

### Requirements
- Linux system with `/proc/interrupts` and `/proc/irq/`
- `bash` and `python3`

### Usage
```bash
./irq.sh              # use default interface eth0
./irq.sh -i eth1      # specify interface name
```
The script outputs the union mask in hexadecimal, binary and as a list of CPU
indexes.

