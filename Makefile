SRC_DIR = src
BUILD_DIR = build

$(BUILD_DIR)/IOD.flp: $(SRC_DIR)/IOD.asm
	nasm $(SRC_DIR)/IOD.asm -o $(BUILD_DIR)/IOD.bin
	dd status=noxfer conv=notrunc if=$(BUILD_DIR)/IOD.bin of=$(BUILD_DIR)/IOD.flp

.PHONY: clean

clean:
	rm $(BUILD_DIR)/* -rf

