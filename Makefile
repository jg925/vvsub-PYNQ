DEVICE := xilinx_u250_xdma_201830_2
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
INSTALL_PATH := ../build

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE)
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif

#ADVANCED_XO += $(XO_DIR)/vadd_advanced.xo
#ADVANCED_XO += $(XO_DIR)/mmult.xo
VSUB_XO += $(XO_DIR)/vsub.xo

#INSTALL_TARGETS += $(INSTALL_PATH)/3-advanced-features/advanced.xclbin

all: build install

#build: advanced 
build: vsub

#advanced: check-vitis check-xrt advanced.$(TARGET).$(XSA).xclbin
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

#$(INSTALL_PATH)/3-advanced-features/advanced.xclbin:
$(INSTALL_PATH)/overlays:
#ifneq (,$(wildcard advanced.$(TARGET).$(XSA).xclbin))
ifneq (,$(wildcard vsub.$(TARGET).$(XSA).xclbin))
#ifneq (,$(wildcard $(INSTALL_PATH)/3-advanced-features))
ifneq (,$(wildcard $(INSTALL_PATH)/overlays))
	$(CP) vsub.$(TARGET).$(XSA).xclbin $@
#else ifneq (,$(wildcard $(INSTALL_PATH)/3_advanced_features))
#	$(CP) advanced.$(TARGET).$(XSA).xclbin $(INSTALL_PATH)/3_advanced_features
else ifneq (,$(wildcard $(INSTALL_PATH)/overlays))
	$(CP) vsub.$(TARGET).$(XSA).xclbin $(INSTALL_PATH)/overlays
else
#	$(warning Could not copy to $(INSTALL_PATH)/3-advanced-features as the folder does not exist)
	$(warning Could not copy to $(INSTALL_PATH)/overlays as the folder does not exist)
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

#$(XO_DIR)/vadd_advanced.xo: $(SRC_DIR)/advanced_features.cpp | $(XO_DIR)
#	$(VPP) $(CLFLAGS) --temp_dir $(XO_DIR) -c -k vadd -o'$@' '$<'
#$(XO_DIR)/mmult.xo: $(SRC_DIR)/advanced_features.cpp | $(XO_DIR)
#	$(VPP) $(CLFLAGS) --temp_dir $(XO_DIR) -c -k mmult -o'$@' '$<'
$(XO_DIR)/vsub.xo: $(SRC_DIR/vsub.cpp | $(XO_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(XO_DIR) -c -k vsub -o'$@' '$<'

advanced.$(TARGET).$(XSA).xclbin: $(ADVANCED_XO) | $(XCLBIN_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(XCLBIN_DIR) --kernel_frequency $(FREQUENCY) -l -o'$@' $(+)

clean:
	-$(RMDIR) _xclbin* _xo* .Xil $(MOD_SRC_DIR)
	-$(RM) *.log *.jou  *.info *.ltx *.pb *.link_summary

cleanall: clean
	-$(RM) *.xclbin
