# Incident Report: Storage Media Corruption & Recovery

**Date:** September 30, 2026  
**System:** Raspberry Pi 5  
**Affected Component:** NVMe/SATA External SSD (Root, Boot, and OS Partitions)  

---

## 1. Incident Overview

A sudden, ungraceful power loss across the residential electrical grid caused catastrophic filesystem and I/O corruption on the primary boot SSD of the Raspberry Pi 5. The device failed to complete the boot process and exhibited severe read/write delays.

---

## 2. Diagnostics & Findings

* **Direct Monitor Diagnostics:** Connecting a display to the Raspberry Pi 5 during startup revealed persistent kernel I/O hangs and read/write timeouts during initialization.
* **Secondary Machine Diagnostics:** Attaching the SSD to a secondary Linux workstation confirmed extreme disk degradation. Accessing simple text files on the surviving boot partition triggered severe latency, indicating corrupt block structures and hung I/O queues.
* **GUI Formatting Attempt:** Formatting via standard GUI Disk Utility tools failed due to continuous I/O blocking and excessive processing timeouts.

---

## 3. Remediation & Recovery Procedure

To bypass GUI I/O timeouts, the drive was completely re-partitioned via low-level CLI using `diskpart`, followed by a fresh OS re-flash.

* **Fresh OS Re-flash Software:** Raspberry Pi Imager

### Terminal Commands Executed (`diskpart`)

```cmd
# Open diskpart prompt
diskpart

# Run the following diskpart commands:
list disk
select disk X   # (Replace X with your SSD's disk number from the list)
clean           # (Erases the partition table instantly without reading metadata)
convert gpt
create partition primary
format fs=ntfs quick
```

---

## 4. Root Cause Analysis & Prevention

### Root Cause
Ext4 and FAT32 filesystems maintain cached data and metadata in RAM before writing to physical storage. The unexpected power outage interrupted active disk writes, leaving corrupted metadata, unlinked inodes, and pending I/O requests stuck in an unrecoverable hardware state.

### Prevention via Uninterruptible Power Supply (UPS)
To prevent future corruption, a dedicated mini-DC UPS is being deployed directly between the power supply and the Raspberry Pi 5.

* **Recommended Hardware:** Eaton 3S Mini DC UPS (or an equivalent Geekworm X120X / 5V DC UPS HAT).
* **Function:** Provides continuous 5V/5A power during outages, giving the OS time to trigger an automated, graceful shutdown sequence (`sudo shutdown -h now`) before total battery depletion.