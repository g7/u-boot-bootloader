# Bargain basement dual-boot:
# - If running on SD Card (devnum 0), we can check the status of the
#   volume key and determine if the user would like to trigger 'dual-boot'
# - This is not a proper chainload since the CPU state has been already
#   changed by the current u-boot, so we can't load another u-boot, or
#   whichever bootloader is in the eMMC
# - The 'dual-boot' happens by changing the environment variables and searching
#   for the eMMC OS' u-boot bootscript, then loading and sourcing it
if test ${devnum) = 0 -a "${volume_key}" = "up" -a -e mmc 2:1 boot.scr; then
	# Volume up has been pressed and a bootscript has been found
	echo "Dual boot requested, and eMMC OS' bootscript has been found"
	setenv devtype mmc
	setenv devnum 2
	setenv volume_key ""

	if load ${devtype} ${devnum}:1 ${loadaddr} /boot.scr; then
		echo "Loaded eMMC OS' bootscript"
		source ${loadaddr}
	else
		echo "Unable to load eMMC OS's bootscript"
	fi

	reset
fi

echo "========== Setting up bootargs ==========="
gpio set 98 # Enable vibrator
gpio set 114 # Turn LED green on
part uuid ${devtype} ${devnum}:2 uuid
setenv bootargs console=tty0 console=ttyS0,115200 root=PARTUUID=${uuid} no_console_suspend rootwait quiet earlycon=uart,mmio32,0x01c28000 panic=10 consoleblank=0 loglevel=0

echo "========= Loading DTB and kernel ========="
gpio set 115 # Turn LED red on

if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /${fdtfile}; then
	echo "Loaded hinted fdtfile (${fdtfile})"
else
	echo "Hinted fdtfile not found, fallbacking to /sun50i-a64-pinephone-1.1.dtb"
	load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /sun50i-a64-pinephone-1.1.dtb
fi

load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /Image

echo "============= Booting kernel ============="
gpio set 116 # Turn LED blue on
gpio clear 98 # Disable vibrator
booti ${kernel_addr_r} - ${fdt_addr_r}

