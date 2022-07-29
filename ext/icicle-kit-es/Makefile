# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

TOP_DIR := $(abspath ../../)
ICICLE_KIT_ES_DIR := $(TOP_DIR)/ext/icicle-kit-es
SOC_CONF_DIR      := $(TOP_DIR)/ext/icicle-kit-es/fpga_design_config
SOC_CONF_GEN_DIR  := $(TOP_DIR)/ext/pfsc-platform/soc_config_generator
SOC_CONF_XML_DIR  := $(TOP_DIR)/ext/icicle-ref-design/XML

.PHONY: all
all: $(SOC_CONF_DIR)

$(SOC_CONF_DIR):
    # MCHP Bug - mpfs_configuration_generator.py v2021.11: xml file name ignored unless in current folder
	$(info mpfs_configuration_generator.py MPFS_Icicle_MSS_Baremetal.xml ...)
	cd $(SOC_CONF_XML_DIR); \
	python3 $(SOC_CONF_GEN_DIR)/mpfs_configuration_generator.py MPFS_Icicle_MSS_Baremetal.xml $(ICICLE_KIT_ES_DIR) 

.PHONY: clean
clean:
	rm -rf $(SOC_CONF_DIR)
