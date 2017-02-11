SRC_DIR = src
BUILD_DIR = build

$(BUILD_DIR)/IOD.flp: $(SRC_DIR)/*.asm
	# assemble source
	nasm $(SRC_DIR)/boot.asm -o $(BUILD_DIR)/boot.bin
	nasm $(SRC_DIR)/kernel.asm -o $(BUILD_DIR)/kernel.bin

	# create DOS filesystem for floppy image
	mkdosfs -C $@ 1440
	#mkfs.vfat -C $@ 1440

	# write bootloader to floppy image
	dd status=noxfer conv=notrunc if=$(BUILD_DIR)/boot.bin of=$@

	# copy kernel files onto floppy image
	mkdir $(BUILD_DIR)/tmpmnt
	mount -o loop -t msdos $(BUILD_DIR)/IOD.flp $(BUILD_DIR)/tmpmnt
	cp $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/tmpmnt
	umount $(BUILD_DIR)/tmpmnt
	rm -rf $(BUILD_DIR)/tmpmnt

.PHONY: clean

clean:
	rm $(BUILD_DIR)/* -rf

