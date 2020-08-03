DEVICE := xilinx_u280_xdma_201920_1
TARGET := hw
FREQUENCY := 300
VPP := v++

CP = cp -rf
RM = rm -f
RMDIR = rm -rf

# device2xsa - create a filesystem friendly name from device name
# $(1) - full name of device
device2xsa = $(strip $(patsubst %.xpfm, % , $(shell basename $(DEVICE))))
XSA := $(call device2xsa, $(DEVICE))

XO_DIR := ./_xo.$(TARGET).$(XSA)
XCLBIN_DIR := ./_xclbin.$(TARGET).$(XSA)
MOD_SRC_DIR := .src
SRC_DIR := src
INSTALL_PATH := overlays

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE)
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif

VSUB_XO += $(XO_DIR)/vsub.xo

INSTALL_TARGETS += $(INSTALL_PATH)/vsub.xclbin

all: build install

build: vsub

vsub: check-vitis check-xrt vsub.$(TARGET).$(XSA).xclbin

# install targets assume both xclbin and dst folder exist
install: $(INSTALL_TARGETS)

check-vitis:
ifndef XILINX_VITIS
	$(error XILINX_VITIS is not set. Please make sure you have sourced the Vitis settings64.{csh,sh})
endif

check-xrt:
ifndef XILINX_XRT
	$(error XILINX_XRT variable is not set. Please make sure you have sourced the XRT setup.{csh,sh})
endif

$(INSTALL_PATH)/vsub.xclbin:
ifneq (,$(wildcard vsub.$(TARGET).$(XSA).xclbin))
ifneq (,$(wildcard $(INSTALL_PATH)))
	$(CP) vsub.$(TARGET).$(XSA).xclbin $@
else ifneq (,$(wildcard $(INSTALL_PATH)))
	$(CP) vsub.$(TARGET).$(XSA).xclbin $(INSTALL_PATH)
else
	$(warning Could not copy to $(INSTALL_PATH) as the folder does not exist)
endif
else
	$(warning Could not find file vsub.$(TARGET).$(XSA).xclbin)
endif

$(MOD_SRC_DIR): 
	mkdir -p $@
$(XCLBIN_DIR): 
	mkdir -p $@
$(XO_DIR): 
	mkdir -p $@

$(XO_DIR)/vsub.xo: $(SRC_DIR/vsub.cpp | $(XO_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(XO_DIR) -c -k vsub -o'$@' ./src/vsub.cpp

vsub.$(TARGET).$(XSA).xclbin: $(VSUB_XO) | $(XCLBIN_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(XCLBIN_DIR) --kernel_frequency $(FREQUENCY) -l -o'$@' $(+)

clean:
	-$(RMDIR) _xclbin* _xo* .Xil $(MOD_SRC_DIR)
	-$(RM) *.log *.jou  *.info *.ltx *.pb *.link_summary

cleanall: clean
	-$(RM) *.xclbin
