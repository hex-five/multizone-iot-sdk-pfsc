/* Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved */

/* envm_origin = 0x20220100; envm_len = 128K-256; */
/* lim_origin  = 0x08000000; lim_len  = 512K;     */
/* ddr_origin  = 0x80000000; ddr_len  = 768M;     */

boot_prog  = 0x08002000; boot_prog_len  = 52K;
boot_data  = 0x0804C000; boot_data_len  = 28K;

zone1_prog = 0x0800F000; zone1_prog_len = 196K;
zone1_data = 0x0804C000; zone1_data_len = 160K; 

zone2_prog = 0x08040000; zone2_prog_len = 16K;
zone2_data = 0x08074000; zone2_data_len = 16K;

zone3_prog = 0x08044000; zone3_prog_len = 16K;
zone3_data = 0x08078000; zone3_data_len = 16K;

zone4_prog = 0x08048000; zone4_prog_len = 16K;
zone4_data = 0x0807C000; zone4_data_len = 16K;

hart1_prog = 0x80000000; hart1_prog_len = 64M;
hart1_data = 0x90000000; hart1_data_len = 32M;

hart2_prog = 0x84000000; hart2_prog_len = 64M;
hart2_data = 0x92000000; hart2_data_len = 32M;

hart3_prog = 0x88000000; hart3_prog_len = 64M;
hart3_data = 0x94000000; hart3_data_len = 32M;

hart4_prog = 0x8C000000; hart4_prog_len = 64M;
hart4_data = 0x96000000; hart4_data_len = 32M;
