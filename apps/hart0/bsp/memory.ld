/* Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved */

/* envm_origin = 0x20220100; envm_len = 128K-256; */
/* lim_origin  = 0x08000000; lim_len  = 2M-64K; */

boot_prog = 0x08002000; boot_prog_len = 16K;
boot_data = 0x08040000; boot_data_len = 8K;

zone1_prog = 0x08012000; zone1_prog_len = 184K;
zone1_data = 0x08046000; zone1_data_len = 136K;

zone2_prog = 0x0800E000; zone2_prog_len = 16K;
zone2_data = 0x08044000; zone2_data_len = 8K;

zone3_prog = 0x0800A000; zone3_prog_len = 16K;
zone3_data = 0x08042000; zone3_data_len = 8K;

zone4_prog = 0x08006000; zone4_prog_len = 16K;
zone4_data = 0x08040000; zone4_data_len = 8K;