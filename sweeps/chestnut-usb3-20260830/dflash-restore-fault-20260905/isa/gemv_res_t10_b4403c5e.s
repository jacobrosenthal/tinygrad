
/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad/isa/gemv_res_t10_b4403c5e.elf:	file format elf64-amdgpu

Disassembly of section .text:

0000000000000000 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res>:
	v_lshrrev_b32_e32 v0, 5, v0                                // 000000000000: 32000085
	s_lshl_b32 s3, s15, 3                                      // 000000000004: 8403830F
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000008: BF870091
	v_readfirstlane_b32 s2, v0                                 // 00000000000C: 7E040500
	s_lshl_b32 s2, s2, 1                                       // 000000000010: 84028102
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000014: BF870499
	s_add_i32 s2, s2, s3                                       // 000000000018: 81020302
	s_cmpk_gt_u32 s2, 0x13ff                                   // 00000000001C: B58213FF
	s_cbranch_scc1 3492                                        // 000000000020: BFA20DA4 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x36b4>
	v_mbcnt_lo_u32_b32 v12, -1, 0                              // 000000000024: D71F000C 000100C1
	s_load_b256 s[4:11], s[0:1], null                          // 00000000002C: F40C0100 F8000000
	s_mul_i32 s3, s2, 0x1080                                   // 000000000034: 9603FF02 00001080
	s_load_b128 s[12:15], s[0:1], 0x20                         // 00000000003C: F4080300 F8000020
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000000044: BF870241
	v_dual_mov_b32 v250, 0 :: v_dual_and_b32 v235, 6, v12      // 000000000048: CA240080 FAEA1886
	v_and_b32_e32 v8, 7, v12                                   // 000000000050: 36101887
	v_lshrrev_b32_e32 v10, 3, v12                              // 000000000054: 32141883
	v_dual_mov_b32 v254, 0 :: v_dual_lshlrev_b32 v13, 2, v12   // 000000000058: CA220080 FE0C1882
	v_mov_b32_e32 v233, v235                                   // 000000000060: 7FD203EB
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000000064: BF870244
	v_or_b32_e32 v14, 1, v8                                    // 000000000068: 381C1081
	v_lshlrev_b32_e32 v0, 4, v8                                // 00000000006C: 30001084
	v_mul_u32_u24_e32 v17, 0xb0, v10                           // 000000000070: 162214FF 000000B0
	v_cmp_lt_u32_e32 vcc_lo, 3, v8                             // 000000000078: 7C921083
	v_dual_mov_b32 v234, v235 :: v_dual_mov_b32 v237, v14      // 00000000007C: CA1001EB EAEC010E
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000000084: BF870244
	v_and_b32_e32 v15, 16, v0                                  // 000000000088: 361E0090
	v_and_b32_e32 v16, 0x60, v0                                // 00000000008C: 362000FF 00000060
	v_mov_b32_e32 v248, 0                                      // 000000000094: 7FF00280
	v_dual_mov_b32 v252, 0 :: v_dual_mov_b32 v249, 0           // 000000000098: CA100080 FCF80080
	v_mad_u32_u24 v0, 0xb0, v10, v15                           // 0000000000A0: D60B0000 043E14FF 000000B0
	s_waitcnt lgkmcnt(0)                                       // 0000000000AC: BF89FC07
	s_add_u32 s6, s6, s3                                       // 0000000000B0: 80060306
	s_addc_u32 s7, s7, 0                                       // 0000000000B4: 82078007
	s_add_u32 s16, s6, 0x1080                                  // 0000000000B8: 8010FF06 00001080
	s_addc_u32 s17, s7, 0                                      // 0000000000C0: 82118007
	v_add3_u32 v9, v16, v0, 48                                 // 0000000000C4: D6550009 02C20110
	scratch_store_b32 off, v0, off offset:400                  // 0000000000CC: DC690190 007C0000
	v_dual_mov_b32 v236, v14 :: v_dual_add_nc_u32 v11, 16, v0  // 0000000000D4: CA20010E EC0A0090
	s_clause 0x5                                               // 0000000000DC: BF850005
	global_load_b128 v[0:3], v17, s[6:7]                       // 0000000000E0: DC5E0000 00060011
	global_load_b128 v[4:7], v17, s[16:17]                     // 0000000000E8: DC5E0000 04100011
	global_load_b128 v[104:107], v9, s[6:7]                    // 0000000000F0: DC5E0000 68060009
	global_load_b128 v[96:99], v9, s[16:17]                    // 0000000000F8: DC5E0000 60100009
	global_load_b128 v[112:115], v11, s[6:7]                   // 000000000100: DC5E0000 7006000B
	global_load_b128 v[108:111], v11, s[16:17]                 // 000000000108: DC5E0000 6C10000B
	s_add_u32 s18, s8, 0x1800                                  // 000000000110: 8012FF08 00001800
	s_addc_u32 s19, s9, 0                                      // 000000000118: 82138009
	s_add_u32 s20, s8, 0x3000                                  // 00000000011C: 8014FF08 00003000
	s_addc_u32 s21, s9, 0                                      // 000000000124: 82158009
	s_add_u32 s22, s8, 0x4800                                  // 000000000128: 8016FF08 00004800
	s_addc_u32 s23, s9, 0                                      // 000000000130: 82178009
	v_dual_mov_b32 v238, v14 :: v_dual_lshlrev_b32 v9, 5, v12  // 000000000134: CA22010E EE081885
	v_lshlrev_b32_e32 v11, 3, v8                               // 00000000013C: 30161083
	s_add_u32 s24, s12, 0x1200                                 // 000000000140: 8018FF0C 00001200
	s_addc_u32 s25, s13, 0                                     // 000000000148: 8219800D
	s_add_u32 s26, s8, 0x6000                                  // 00000000014C: 801AFF08 00006000
	s_addc_u32 s27, s9, 0                                      // 000000000154: 821B8009
	s_add_u32 s28, s12, 0x1800                                 // 000000000158: 801CFF0C 00001800
	v_and_or_b32 v9, 0xc0, v9, v15                             // 000000000160: D6570009 043E12FF 000000C0
	v_dual_mov_b32 v239, 0 :: v_dual_and_b32 v8, 24, v11       // 00000000016C: CA240080 EF081698
	s_addc_u32 s29, s13, 0                                     // 000000000174: 821D800D
	s_add_u32 s30, s8, 0x7800                                  // 000000000178: 801EFF08 00007800
	s_addc_u32 s31, s9, 0                                      // 000000000180: 821F8009
	s_add_u32 s34, s12, 0x1e00                                 // 000000000184: 8022FF0C 00001E00
	s_addc_u32 s35, s13, 0                                     // 00000000018C: 8223800D
	s_clause 0x2                                               // 000000000190: BF850002
	scratch_store_b32 off, v9, off offset:84                   // 000000000194: DC690054 007C0900
	scratch_store_b32 off, v17, off offset:404                 // 00000000019C: DC690194 007C1100
	scratch_store_b32 off, v8, off                             // 0000000001A4: DC690000 007C0800
	s_add_u32 s36, s8, 0x9000                                  // 0000000001AC: 8024FF08 00009000
	v_dual_mov_b32 v255, 0 :: v_dual_lshlrev_b32 v8, 5, v10    // 0000000001B4: CA220080 FF081485
	s_addc_u32 s37, s9, 0                                      // 0000000001BC: 82258009
	s_add_u32 s38, s10, 0x1200                                 // 0000000001C0: 8026FF0A 00001200
	s_addc_u32 s39, s11, 0                                     // 0000000001C8: 8227800B
	s_add_u32 s40, s12, 0x2400                                 // 0000000001CC: 8028FF0C 00002400
	s_addc_u32 s41, s13, 0                                     // 0000000001D4: 8229800D
	v_mov_b32_e32 v9, 0                                        // 0000000001D8: 7E120280
	v_lshl_or_b32 v12, v14, 2, v8                              // 0000000001DC: D656000C 0421050E
	v_and_or_b32 v13, v13, 24, v8                              // 0000000001E4: D657000D 0421310D
	v_add3_u32 v8, v17, v16, v15                               // 0000000001EC: D6550008 043E2111
	v_mov_b32_e32 v15, 0                                       // 0000000001F4: 7E1E0280
	s_add_u32 s42, s8, 0xa800                                  // 0000000001F8: 802AFF08 0000A800
	s_addc_u32 s43, s9, 0                                      // 000000000200: 822B8009
	s_add_u32 s44, s10, 0x1500                                 // 000000000204: 802CFF0A 00001500
	s_addc_u32 s45, s11, 0                                     // 00000000020C: 822D800B
	s_add_u32 s46, s12, 0x2a00                                 // 000000000210: 802EFF0C 00002A00
	scratch_store_b32 off, v15, off offset:116                 // 000000000218: DC690074 007C0F00
	v_mov_b32_e32 v15, 0                                       // 000000000220: 7E1E0280
	s_addc_u32 s47, s13, 0                                     // 000000000224: 822F800D
	s_add_u32 s48, s8, 0xc000                                  // 000000000228: 8030FF08 0000C000
	s_addc_u32 s49, s9, 0                                      // 000000000230: 82318009
	s_add_u32 s50, s10, 0x1800                                 // 000000000234: 8032FF0A 00001800
	s_addc_u32 s51, s11, 0                                     // 00000000023C: 8233800B
	scratch_store_b32 off, v15, off offset:112                 // 000000000240: DC690070 007C0F00
	v_mov_b32_e32 v15, 0                                       // 000000000248: 7E1E0280
	s_add_u32 s52, s12, 0x3000                                 // 00000000024C: 8034FF0C 00003000
	s_addc_u32 s53, s13, 0                                     // 000000000254: 8235800D
	s_add_u32 s54, s8, 0xd800                                  // 000000000258: 8036FF08 0000D800
	s_addc_u32 s55, s9, 0                                      // 000000000260: 82378009
	s_add_u32 s56, s10, 0x1b00                                 // 000000000264: 8038FF0A 00001B00
	scratch_store_b32 off, v15, off offset:108                 // 00000000026C: DC69006C 007C0F00
	v_mov_b32_e32 v15, 0                                       // 000000000274: 7E1E0280
	s_addc_u32 s57, s11, 0                                     // 000000000278: 8239800B
	s_add_u32 s58, s12, 0x3600                                 // 00000000027C: 803AFF0C 00003600
	s_addc_u32 s59, s13, 0                                     // 000000000284: 823B800D
	s_add_u32 s3, s8, 32                                       // 000000000288: 8003A008
	s_addc_u32 s33, s9, 0                                      // 00000000028C: 82218009
	scratch_store_b32 off, v15, off offset:104                 // 000000000290: DC690068 007C0F00
	v_mov_b32_e32 v15, 0                                       // 000000000298: 7E1E0280
	s_add_u32 s60, s8, 0x1820                                  // 00000000029C: 803CFF08 00001820
	s_addc_u32 s61, s9, 0                                      // 0000000002A4: 823D8009
	s_add_u32 s62, s8, 0x3020                                  // 0000000002A8: 803EFF08 00003020
	s_addc_u32 s63, s9, 0                                      // 0000000002B0: 823F8009
	s_add_u32 s64, s8, 0x4820                                  // 0000000002B4: 8040FF08 00004820
	scratch_store_b32 off, v15, off offset:100                 // 0000000002BC: DC690064 007C0F00
	v_mov_b32_e32 v15, 0                                       // 0000000002C4: 7E1E0280
	s_addc_u32 s65, s9, 0                                      // 0000000002C8: 82418009
	s_add_u32 s66, s8, 0x6020                                  // 0000000002CC: 8042FF08 00006020
	s_addc_u32 s67, s9, 0                                      // 0000000002D4: 82438009
	s_add_u32 s68, s8, 0x7820                                  // 0000000002D8: 8044FF08 00007820
	s_addc_u32 s69, s9, 0                                      // 0000000002E0: 82458009
	s_clause 0x1                                               // 0000000002E4: BF850001
	scratch_store_b32 off, v8, off offset:416                  // 0000000002E8: DC6901A0 007C0800
	scratch_store_b32 off, v15, off offset:96                  // 0000000002F0: DC690060 007C0F00
	v_mov_b32_e32 v15, 0                                       // 0000000002F8: 7E1E0280
	s_add_u32 s70, s8, 0x9020                                  // 0000000002FC: 8046FF08 00009020
	s_addc_u32 s71, s9, 0                                      // 000000000304: 82478009
	s_add_u32 s72, s8, 0xa820                                  // 000000000308: 8048FF08 0000A820
	s_addc_u32 s73, s9, 0                                      // 000000000310: 82498009
	v_dual_mov_b32 v232, 0 :: v_dual_and_b32 v253, 16, v11     // 000000000314: CA240080 E8FC1690
	s_add_u32 s74, s8, 0xc020                                  // 00000000031C: 804AFF08 0000C020
	v_lshl_or_b32 v11, v10, 6, v11                             // 000000000324: D656000B 042D0D0A
	s_clause 0x1                                               // 00000000032C: BF850001
	scratch_store_b32 off, v14, off offset:412                 // 000000000330: DC69019C 007C0E00
	scratch_store_b32 off, v15, off offset:92                  // 000000000338: DC69005C 007C0F00
	v_dual_mov_b32 v251, 0 :: v_dual_lshlrev_b32 v14, 8, v10   // 000000000340: CA220080 FB0E1488
	v_mov_b32_e32 v10, 0                                       // 000000000348: 7E140280
	v_dual_mov_b32 v8, 0 :: v_dual_mov_b32 v15, 0              // 00000000034C: CA100080 080E0080
	s_addc_u32 s75, s9, 0                                      // 000000000354: 824B8009
	s_add_u32 s76, s8, 0xd820                                  // 000000000358: 804CFF08 0000D820
	s_mov_b32 s1, 0                                            // 000000000360: BE810080
	s_addc_u32 s77, s9, 0                                      // 000000000364: 824D8009
	s_clause 0x1                                               // 000000000368: BF850001
	scratch_store_b32 off, v235, off offset:408                // 00000000036C: DC690198 007CEB00
	scratch_store_b32 off, v15, off offset:88                  // 000000000374: DC690058 007C0F00
	s_clause 0x2                                               // 00000000037C: BF850002
	scratch_load_b32 v15, off, off offset:404                  // 000000000380: DC510194 0F7C0000
	scratch_load_b32 v16, off, off offset:416                  // 000000000388: DC5101A0 107C0000
	scratch_load_b32 v17, off, off offset:400                  // 000000000390: DC510190 117C0000
	s_waitcnt vmcnt(8)                                         // 000000000398: BF8923F7
	v_lshrrev_b32_e32 v1, v253, v1                             // 00000000039C: 320203FD
	s_waitcnt vmcnt(2)                                         // 0000000003A0: BF890BF7
	v_add_nc_u32_e32 v15, s1, v15                              // 0000000003A4: 4A1E1E01
	s_waitcnt vmcnt(1)                                         // 0000000003A8: BF8907F7
	v_add_nc_u32_e32 v16, s1, v16                              // 0000000003AC: 4A202001
	s_waitcnt vmcnt(0)                                         // 0000000003B0: BF8903F7
	v_add_nc_u32_e32 v17, s1, v17                              // 0000000003B4: 4A222201
	v_add_nc_u32_e32 v18, 0x2c0, v15                           // 0000000003B8: 4A241EFF 000002C0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000003C0: BF870193
	v_add_nc_u32_e32 v19, 0x2f0, v16                           // 0000000003C4: 4A2620FF 000002F0
	v_add_nc_u32_e32 v23, 0x2d0, v17                           // 0000000003CC: 4A2E22FF 000002D0
	s_clause 0x1                                               // 0000000003D4: BF850001
	global_load_b128 v[32:35], v18, s[6:7]                     // 0000000003D8: DC5E0000 20060012
	global_load_b128 v[36:39], v18, s[16:17]                   // 0000000003E0: DC5E0000 24100012
	scratch_load_b32 v18, off, off offset:84                   // 0000000003E8: DC510054 127C0000
	s_clause 0x3                                               // 0000000003F0: BF850003
	global_load_b128 v[44:47], v19, s[6:7]                     // 0000000003F4: DC5E0000 2C060013
	global_load_b128 v[40:43], v19, s[16:17]                   // 0000000003FC: DC5E0000 28100013
	global_load_b128 v[52:55], v23, s[6:7]                     // 000000000404: DC5E0000 34060017
	global_load_b128 v[48:51], v23, s[16:17]                   // 00000000040C: DC5E0000 30100017
	v_add_nc_u32_e32 v23, 4, v11                               // 000000000414: 4A2E1684
	s_waitcnt vmcnt(4)                                         // 000000000418: BF8913F7
	v_add_co_u32 v24, s0, v14, v18                             // 00000000041C: D7000018 0002250E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000000424: BF8701A1
	v_add_co_ci_u32_e64 v25, null, 0, 0, s0                    // 000000000428: D5207C19 00010080
	v_add_nc_u32_e32 v18, v18, v14                             // 000000000430: 4A241D12
	v_add_co_u32 v19, s0, s3, v24                              // 000000000434: D7000013 00023003
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000043C: BF8700A1
	v_add_co_ci_u32_e64 v20, s0, s33, v25, s0                  // 000000000440: D5200014 00023221
	v_add_co_u32 v21, s0, s60, v24                             // 000000000448: D7000015 0002303C
	v_add_co_ci_u32_e64 v22, s0, s61, v25, s0                  // 000000000450: D5200016 0002323D
	s_clause 0x1                                               // 000000000458: BF850001
	global_load_b128 v[228:231], v[19:20], off                 // 00000000045C: DC5E0000 E47C0013
	global_load_b128 v[224:227], v[21:22], off                 // 000000000464: DC5E0000 E07C0015
	global_load_b32 v19, v12, s[10:11] offset:768              // 00000000046C: DC520300 130A000C
	s_waitcnt vmcnt(0)                                         // 000000000474: BF8903F7
	scratch_store_b32 off, v19, off offset:200                 // 000000000478: DC6900C8 007C1300
	s_clause 0x1                                               // 000000000480: BF850001
	global_load_b128 v[136:139], v18, s[18:19]                 // 000000000484: DC5E0000 88120012
	global_load_b128 v[132:135], v18, s[20:21]                 // 00000000048C: DC5E0000 84140012
	global_load_b64 v[26:27], v11, s[12:13] offset:1536        // 000000000494: DC560600 1A0C000B
	v_add_co_u32 v19, s0, s62, v24                             // 00000000049C: D7000013 0002303E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000004A4: BF8700A1
	v_add_co_ci_u32_e64 v20, s0, s63, v25, s0                  // 0000000004A8: D5200014 0002323F
	v_add_co_u32 v21, s0, s64, v24                             // 0000000004B0: D7000015 00023040
	v_add_co_ci_u32_e64 v22, s0, s65, v25, s0                  // 0000000004B8: D5200016 00023241
	s_waitcnt vmcnt(0)                                         // 0000000004C0: BF8903F7
	scratch_store_b64 off, v[26:27], off offset:128            // 0000000004C4: DC6D0080 007C1A00
	global_load_b64 v[26:27], v11, s[12:13] offset:3072        // 0000000004CC: DC560C00 1A0C000B
	s_waitcnt vmcnt(0)                                         // 0000000004D4: BF8903F7
	scratch_store_b64 off, v[26:27], off offset:120            // 0000000004D8: DC6D0078 007C1A00
	s_clause 0x1                                               // 0000000004E0: BF850001
	global_load_b128 v[220:223], v[19:20], off                 // 0000000004E4: DC5E0000 DC7C0013
	global_load_b128 v[216:219], v[21:22], off                 // 0000000004EC: DC5E0000 D87C0015
	global_load_b32 v26, v13, s[10:11] offset:768              // 0000000004F4: DC520300 1A0A000D
	v_add_co_u32 v19, s0, s66, v24                             // 0000000004FC: D7000013 00023042
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000504: BF8700A1
	v_add_co_ci_u32_e64 v20, s0, s67, v25, s0                  // 000000000508: D5200014 00023243
	v_add_co_u32 v21, s0, s68, v24                             // 000000000510: D7000015 00023044
	v_add_co_ci_u32_e64 v22, s0, s69, v25, s0                  // 000000000518: D5200016 00023245
	s_waitcnt vmcnt(0)                                         // 000000000520: BF8903F7
	scratch_store_b32 off, v26, off offset:252                 // 000000000524: DC6900FC 007C1A00
	global_load_b32 v26, v13, s[10:11] offset:1536             // 00000000052C: DC520600 1A0A000D
	s_waitcnt vmcnt(0)                                         // 000000000534: BF8903F7
	scratch_store_b32 off, v26, off offset:240                 // 000000000538: DC6900F0 007C1A00
	global_load_b32 v26, v13, s[10:11] offset:2304             // 000000000540: DC520900 1A0A000D
	s_waitcnt vmcnt(0)                                         // 000000000548: BF8903F7
	scratch_store_b32 off, v26, off offset:216                 // 00000000054C: DC6900D8 007C1A00
	s_clause 0x3                                               // 000000000554: BF850003
	global_load_b128 v[148:151], v18, s[22:23]                 // 000000000558: DC5E0000 94160012
	global_load_b128 v[140:143], v18, s[26:27]                 // 000000000560: DC5E0000 8C1A0012
	global_load_b128 v[212:215], v[19:20], off                 // 000000000568: DC5E0000 D47C0013
	global_load_b128 v[208:211], v[21:22], off                 // 000000000570: DC5E0000 D07C0015
	s_clause 0x2                                               // 000000000578: BF850002
	global_load_b32 v240, v12, s[10:11] offset:1536            // 00000000057C: DC520600 F00A000C
	global_load_b32 v30, v12, s[10:11] offset:2304             // 000000000584: DC520900 1E0A000C
	global_load_b32 v26, v12, s[10:11] offset:3072             // 00000000058C: DC520C00 1A0A000C
	v_add_co_u32 v19, s0, s70, v24                             // 000000000594: D7000013 00023046
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000059C: BF8700A1
	v_add_co_ci_u32_e64 v20, s0, s71, v25, s0                  // 0000000005A0: D5200014 00023247
	v_add_co_u32 v21, s0, s72, v24                             // 0000000005A8: D7000015 00023048
	v_add_co_ci_u32_e64 v22, s0, s73, v25, s0                  // 0000000005B0: D5200016 00023249
	s_waitcnt vmcnt(0)                                         // 0000000005B8: BF8903F7
	scratch_store_b32 off, v26, off offset:244                 // 0000000005BC: DC6900F4 007C1A00
	global_load_b32 v26, v12, s[10:11] offset:3840             // 0000000005C4: DC520F00 1A0A000C
	s_waitcnt vmcnt(0)                                         // 0000000005CC: BF8903F7
	scratch_store_b32 off, v26, off offset:228                 // 0000000005D0: DC6900E4 007C1A00
	s_clause 0x5                                               // 0000000005D8: BF850005
	global_load_b128 v[160:163], v18, s[30:31]                 // 0000000005DC: DC5E0000 A01E0012
	global_load_b128 v[156:159], v18, s[36:37]                 // 0000000005E4: DC5E0000 9C240012
	global_load_b128 v[204:207], v[19:20], off                 // 0000000005EC: DC5E0000 CC7C0013
	global_load_b128 v[192:195], v[21:22], off                 // 0000000005F4: DC5E0000 C07C0015
	global_load_b128 v[152:155], v18, s[42:43]                 // 0000000005FC: DC5E0000 982A0012
	global_load_b128 v[144:147], v18, s[48:49]                 // 000000000604: DC5E0000 90300012
	global_load_b32 v21, v13, s[38:39]                         // 00000000060C: DC520000 1526000D
	v_add_co_u32 v19, s0, s74, v24                             // 000000000614: D7000013 0002304A
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000061C: BF870001
	v_add_co_ci_u32_e64 v20, s0, s75, v25, s0                  // 000000000620: D5200014 0002324B
	s_waitcnt vmcnt(0)                                         // 000000000628: BF8903F7
	scratch_store_b32 off, v21, off offset:232                 // 00000000062C: DC6900E8 007C1500
	global_load_b32 v21, v13, s[44:45]                         // 000000000634: DC520000 152C000D
	s_waitcnt vmcnt(0)                                         // 00000000063C: BF8903F7
	scratch_store_b32 off, v21, off offset:208                 // 000000000640: DC6900D0 007C1500
	global_load_b32 v21, v13, s[50:51]                         // 000000000648: DC520000 1532000D
	s_waitcnt vmcnt(0)                                         // 000000000650: BF8903F7
	scratch_store_b32 off, v21, off offset:204                 // 000000000654: DC6900CC 007C1500
	s_clause 0x2                                               // 00000000065C: BF850002
	global_load_b32 v31, v13, s[10:11] offset:3072             // 000000000660: DC520C00 1F0A000D
	global_load_b32 v29, v13, s[10:11] offset:3840             // 000000000668: DC520F00 1D0A000D
	global_load_b32 v21, v12, s[38:39]                         // 000000000670: DC520000 1526000C
	s_waitcnt vmcnt(0)                                         // 000000000678: BF8903F7
	scratch_store_b32 off, v21, off offset:248                 // 00000000067C: DC6900F8 007C1500
	global_load_b32 v21, v12, s[44:45]                         // 000000000684: DC520000 152C000C
	s_waitcnt vmcnt(0)                                         // 00000000068C: BF8903F7
	scratch_store_b32 off, v21, off offset:236                 // 000000000690: DC6900EC 007C1500
	global_load_b32 v21, v12, s[50:51]                         // 000000000698: DC520000 1532000C
	s_waitcnt vmcnt(0)                                         // 0000000006A0: BF8903F7
	scratch_store_b32 off, v21, off offset:212                 // 0000000006A4: DC6900D4 007C1500
	v_add_co_u32 v21, s0, s76, v24                             // 0000000006AC: D7000015 0002304C
	global_load_b32 v24, v11, s[24:25]                         // 0000000006B4: DC520000 1818000B
	v_add_co_ci_u32_e64 v22, s0, s77, v25, s0                  // 0000000006BC: D5200016 0002324D
	s_waitcnt vmcnt(0)                                         // 0000000006C4: BF8903F7
	scratch_store_b32 off, v24, off offset:152                 // 0000000006C8: DC690098 007C1800
	global_load_b32 v24, v11, s[28:29]                         // 0000000006D0: DC520000 181C000B
	s_waitcnt vmcnt(0)                                         // 0000000006D8: BF8903F7
	scratch_store_b32 off, v24, off offset:156                 // 0000000006DC: DC69009C 007C1800
	global_load_b32 v24, v11, s[34:35]                         // 0000000006E4: DC520000 1822000B
	s_waitcnt vmcnt(0)                                         // 0000000006EC: BF8903F7
	scratch_store_b32 off, v24, off offset:148                 // 0000000006F0: DC690094 007C1800
	global_load_b32 v24, v11, s[40:41]                         // 0000000006F8: DC520000 1828000B
	s_waitcnt vmcnt(0)                                         // 000000000700: BF8903F7
	scratch_store_b32 off, v24, off offset:144                 // 000000000704: DC690090 007C1800
	global_load_b32 v24, v11, s[46:47]                         // 00000000070C: DC520000 182E000B
	s_waitcnt vmcnt(0)                                         // 000000000714: BF8903F7
	scratch_store_b32 off, v24, off offset:136                 // 000000000718: DC690088 007C1800
	global_load_b32 v24, v11, s[52:53]                         // 000000000720: DC520000 1834000B
	s_waitcnt vmcnt(0)                                         // 000000000728: BF8903F7
	scratch_store_b32 off, v24, off offset:140                 // 00000000072C: DC69008C 007C1800
	s_clause 0x3                                               // 000000000734: BF850003
	global_load_b128 v[172:175], v18, s[8:9]                   // 000000000738: DC5E0000 AC080012
	global_load_b128 v[164:167], v18, s[54:55]                 // 000000000740: DC5E0000 A4360012
	global_load_b128 v[188:191], v[19:20], off                 // 000000000748: DC5E0000 BC7C0013
	global_load_b128 v[180:183], v[21:22], off                 // 000000000750: DC5E0000 B47C0015
	s_clause 0x1                                               // 000000000758: BF850001
	global_load_b32 v241, v13, s[10:11]                        // 00000000075C: DC520000 F10A000D
	global_load_b32 v19, v13, s[56:57]                         // 000000000764: DC520000 1338000D
	s_waitcnt vmcnt(0)                                         // 00000000076C: BF8903F7
	scratch_store_b32 off, v19, off offset:220                 // 000000000770: DC6900DC 007C1300
	s_clause 0x1                                               // 000000000778: BF850001
	global_load_b32 v242, v12, s[10:11]                        // 00000000077C: DC520000 F20A000C
	global_load_b32 v19, v12, s[56:57]                         // 000000000784: DC520000 1338000C
	s_waitcnt vmcnt(0)                                         // 00000000078C: BF8903F7
	scratch_store_b32 off, v19, off offset:224                 // 000000000790: DC6900E0 007C1300
	global_load_b64 v[19:20], v11, s[12:13]                    // 000000000798: DC560000 130C000B
	s_waitcnt vmcnt(0)                                         // 0000000007A0: BF8903F7
	scratch_store_b64 off, v[19:20], off offset:192            // 0000000007A4: DC6D00C0 007C1300
	global_load_b32 v19, v11, s[58:59]                         // 0000000007AC: DC520000 133A000B
	s_waitcnt vmcnt(0)                                         // 0000000007B4: BF8903F7
	scratch_store_b32 off, v19, off offset:160                 // 0000000007B8: DC6900A0 007C1300
	global_load_b32 v19, v23, s[24:25]                         // 0000000007C0: DC520000 13180017
	s_waitcnt vmcnt(0)                                         // 0000000007C8: BF8903F7
	scratch_store_b32 off, v19, off offset:184                 // 0000000007CC: DC6900B8 007C1300
	global_load_b32 v19, v23, s[28:29]                         // 0000000007D4: DC520000 131C0017
	s_waitcnt vmcnt(0)                                         // 0000000007DC: BF8903F7
	scratch_store_b32 off, v19, off offset:188                 // 0000000007E0: DC6900BC 007C1300
	global_load_b32 v19, v23, s[34:35]                         // 0000000007E8: DC520000 13220017
	s_waitcnt vmcnt(0)                                         // 0000000007F0: BF8903F7
	scratch_store_b32 off, v19, off offset:180                 // 0000000007F4: DC6900B4 007C1300
	global_load_b32 v19, v23, s[40:41]                         // 0000000007FC: DC520000 13280017
	s_waitcnt vmcnt(0)                                         // 000000000804: BF8903F7
	scratch_store_b32 off, v19, off offset:176                 // 000000000808: DC6900B0 007C1300
	global_load_b32 v19, v23, s[46:47]                         // 000000000810: DC520000 132E0017
	s_waitcnt vmcnt(0)                                         // 000000000818: BF8903F7
	scratch_store_b32 off, v19, off offset:168                 // 00000000081C: DC6900A8 007C1300
	global_load_b32 v19, v23, s[52:53]                         // 000000000824: DC520000 13340017
	s_waitcnt vmcnt(0)                                         // 00000000082C: BF8903F7
	scratch_store_b32 off, v19, off offset:172                 // 000000000830: DC6900AC 007C1300
	global_load_b32 v19, v23, s[58:59]                         // 000000000838: DC520000 133A0017
	s_waitcnt vmcnt(0)                                         // 000000000840: BF8903F7
	scratch_store_b32 off, v19, off offset:164                 // 000000000844: DC6900A4 007C1300
	v_lshrrev_b32_e32 v19, v253, v3                            // 00000000084C: 322607FD
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000850: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000854: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000858: 8D00007E
	s_cbranch_execz 7                                          // 00000000085C: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x87c>
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000860: BF8700A1
	v_and_b32_e32 v20, 15, v19                                 // 000000000864: 3628268F
	v_lshrrev_b32_e32 v21, 2, v1                               // 000000000868: 322A0282
	v_and_or_b32 v20, v21, 48, v20                             // 00000000086C: D6570014 04516115
	scratch_store_b32 off, v20, off offset:260                 // 000000000874: DC690104 007C1400
	s_and_not1_saveexec_b32 s0, s0                             // 00000000087C: BE803000
	s_cbranch_execz 3                                          // 000000000880: BFA50003 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x890>
	v_and_b32_e32 v20, 63, v1                                  // 000000000884: 362802BF
	scratch_store_b32 off, v20, off offset:260                 // 000000000888: DC690104 007C1400
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000890: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000894: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000898: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 00000000089C: 8D00007E
	s_cbranch_execz 8                                          // 0000000008A0: BFA50008 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x8c4>
	v_lshrrev_b32_e32 v1, 10, v1                               // 0000000008A4: 3202028A
	v_lshrrev_b32_e32 v19, 8, v19                              // 0000000008A8: 32262688
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008AC: BF870092
	v_and_b32_e32 v1, 48, v1                                   // 0000000008B0: 360202B0
	v_and_or_b32 v1, v19, 15, v1                               // 0000000008B4: D6570001 04051F13
	scratch_store_b32 off, v1, off offset:268                  // 0000000008BC: DC69010C 007C0100
	s_and_not1_saveexec_b32 s0, s0                             // 0000000008C4: BE803000
	s_cbranch_execz 4                                          // 0000000008C8: BFA50004 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x8dc>
	v_bfe_u32 v1, v1, 8, 6                                     // 0000000008CC: D6100001 02191101
	scratch_store_b32 off, v1, off offset:268                  // 0000000008D4: DC69010C 007C0100
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000008DC: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000008E0: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000008E4: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 0000000008E8: 8D00007E
	s_cbranch_execz 14                                         // 0000000008EC: BFA5000E <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x928>
	scratch_load_b32 v19, off, off                             // 0000000008F0: DC510000 137C0000
	s_waitcnt vmcnt(0)                                         // 0000000008F8: BF8903F7
	v_lshrrev_b32_e32 v1, v19, v2                              // 0000000008FC: 32020513
	v_lshrrev_b32_e32 v3, v19, v3                              // 000000000900: 32060713
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000904: BF870112
	v_lshrrev_b32_e32 v1, 2, v1                                // 000000000908: 32020282
	v_lshrrev_b32_e32 v3, 4, v3                                // 00000000090C: 32060684
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000910: BF870092
	v_and_b32_e32 v1, 48, v1                                   // 000000000914: 360202B0
	v_and_or_b32 v1, v3, 15, v1                                // 000000000918: D6570001 04051F03
	scratch_store_b32 off, v1, off offset:256                  // 000000000920: DC690100 007C0100
	s_and_not1_saveexec_b32 s0, s0                             // 000000000928: BE803000
	s_cbranch_execz 7                                          // 00000000092C: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x94c>
	scratch_load_b32 v1, off, off                              // 000000000930: DC510000 017C0000
	s_waitcnt vmcnt(0)                                         // 000000000938: BF8903F7
	v_bfe_u32 v1, v2, v1, 6                                    // 00000000093C: D6100001 021A0302
	scratch_store_b32 off, v1, off offset:256                  // 000000000944: DC690100 007C0100
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000094C: 8C7E007E
	v_lshrrev_b32_e32 v1, v253, v5                             // 000000000950: 32020BFD
	v_lshrrev_b32_e32 v2, v253, v7                             // 000000000954: 32040FFD
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000958: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000095C: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000960: 8D00007E
	s_cbranch_execz 7                                          // 000000000964: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x984>
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000968: BF8700A1
	v_and_b32_e32 v3, 15, v2                                   // 00000000096C: 3606048F
	v_lshrrev_b32_e32 v5, 2, v1                                // 000000000970: 320A0282
	v_and_or_b32 v3, v5, 48, v3                                // 000000000974: D6570003 040D6105
	scratch_store_b32 off, v3, off offset:328                  // 00000000097C: DC690148 007C0300
	s_and_not1_saveexec_b32 s0, s0                             // 000000000984: BE803000
	s_cbranch_execz 3                                          // 000000000988: BFA50003 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x998>
	v_and_b32_e32 v3, 63, v1                                   // 00000000098C: 360602BF
	scratch_store_b32 off, v3, off offset:328                  // 000000000990: DC690148 007C0300
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000998: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 00000000099C: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000009A0: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 0000000009A4: 8D00007E
	s_cbranch_execz 8                                          // 0000000009A8: BFA50008 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x9cc>
	v_lshrrev_b32_e32 v1, 10, v1                               // 0000000009AC: 3202028A
	v_lshrrev_b32_e32 v2, 8, v2                                // 0000000009B0: 32040488
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009B4: BF870092
	v_and_b32_e32 v1, 48, v1                                   // 0000000009B8: 360202B0
	v_and_or_b32 v1, v2, 15, v1                                // 0000000009BC: D6570001 04051F02
	scratch_store_b32 off, v1, off offset:356                  // 0000000009C4: DC690164 007C0100
	s_and_not1_saveexec_b32 s0, s0                             // 0000000009CC: BE803000
	s_cbranch_execz 4                                          // 0000000009D0: BFA50004 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x9e4>
	v_bfe_u32 v1, v1, 8, 6                                     // 0000000009D4: D6100001 02191101
	scratch_store_b32 off, v1, off offset:356                  // 0000000009DC: DC690164 007C0100
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000009E4: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000009E8: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000009EC: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 0000000009F0: 8D00007E
	s_cbranch_execz 14                                         // 0000000009F4: BFA5000E <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xa30>
	scratch_load_b32 v2, off, off                              // 0000000009F8: DC510000 027C0000
	s_waitcnt vmcnt(0)                                         // 000000000A00: BF8903F7
	v_lshrrev_b32_e32 v1, v2, v6                               // 000000000A04: 32020D02
	v_lshrrev_b32_e32 v2, v2, v7                               // 000000000A08: 32040F02
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000A0C: BF870112
	v_lshrrev_b32_e32 v1, 2, v1                                // 000000000A10: 32020282
	v_lshrrev_b32_e32 v2, 4, v2                                // 000000000A14: 32040484
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A18: BF870092
	v_and_b32_e32 v1, 48, v1                                   // 000000000A1C: 360202B0
	v_and_or_b32 v1, v2, 15, v1                                // 000000000A20: D6570001 04051F02
	scratch_store_b32 off, v1, off offset:264                  // 000000000A28: DC690108 007C0100
	s_and_not1_saveexec_b32 s0, s0                             // 000000000A30: BE803000
	s_cbranch_execz 7                                          // 000000000A34: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xa54>
	scratch_load_b32 v1, off, off                              // 000000000A38: DC510000 017C0000
	s_waitcnt vmcnt(0)                                         // 000000000A40: BF8903F7
	v_bfe_u32 v1, v6, v1, 6                                    // 000000000A44: D6100001 021A0306
	scratch_store_b32 off, v1, off offset:264                  // 000000000A4C: DC690108 007C0100
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000A54: 8C7E007E
	v_dual_mov_b32 v19, v48 :: v_dual_mov_b32 v20, v49         // 000000000A58: CA100130 13140131
	v_dual_mov_b32 v21, v50 :: v_dual_mov_b32 v22, v51         // 000000000A60: CA100132 15160133
	s_cmpk_eq_i32 s1, 0xb00                                    // 000000000A68: B1810B00
	s_clause 0x4                                               // 000000000A6C: BF850004
	scratch_store_b128 off, v[40:43], off offset:4             // 000000000A70: DC750004 007C2800
	scratch_store_b128 off, v[36:39], off offset:20            // 000000000A78: DC750014 007C2400
	scratch_store_b128 off, v[52:55], off offset:52            // 000000000A80: DC750034 007C3400
	scratch_store_b128 off, v[44:47], off offset:68            // 000000000A88: DC750044 007C2C00
	scratch_store_b128 off, v[32:35], off offset:36            // 000000000A90: DC750024 007C2000
	s_cbranch_scc1 33                                          // 000000000A98: BFA20021 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xb20>
	v_add_nc_u32_e32 v1, 0x580, v15                            // 000000000A9C: 4A021EFF 00000580
	v_add_nc_u32_e32 v2, 0x5b0, v16                            // 000000000AA4: 4A0420FF 000005B0
	v_add_nc_u32_e32 v3, 0x590, v17                            // 000000000AAC: 4A0622FF 00000590
	global_load_b128 v[19:22], v1, s[6:7]                      // 000000000AB4: DC5E0000 13060001
	s_waitcnt vmcnt(0)                                         // 000000000ABC: BF8903F7
	scratch_store_b128 off, v[19:22], off offset:36            // 000000000AC0: DC750024 007C1300
	global_load_b128 v[19:22], v1, s[16:17]                    // 000000000AC8: DC5E0000 13100001
	s_waitcnt vmcnt(0)                                         // 000000000AD0: BF8903F7
	scratch_store_b128 off, v[19:22], off offset:20            // 000000000AD4: DC750014 007C1300
	global_load_b128 v[19:22], v2, s[6:7]                      // 000000000ADC: DC5E0000 13060002
	s_waitcnt vmcnt(0)                                         // 000000000AE4: BF8903F7
	scratch_store_b128 off, v[19:22], off offset:68            // 000000000AE8: DC750044 007C1300
	global_load_b128 v[19:22], v2, s[16:17]                    // 000000000AF0: DC5E0000 13100002
	s_waitcnt vmcnt(0)                                         // 000000000AF8: BF8903F7
	scratch_store_b128 off, v[19:22], off offset:4             // 000000000AFC: DC750004 007C1300
	global_load_b128 v[19:22], v3, s[6:7]                      // 000000000B04: DC5E0000 13060003
	s_waitcnt vmcnt(0)                                         // 000000000B0C: BF8903F7
	scratch_store_b128 off, v[19:22], off offset:52            // 000000000B10: DC750034 007C1300
	global_load_b128 v[19:22], v3, s[16:17]                    // 000000000B18: DC5E0000 13100003
	scratch_load_b32 v2, off, off offset:84                    // 000000000B20: DC510054 027C0000
	v_add_nc_u32_e32 v1, 0x400, v14                            // 000000000B28: 4A021CFF 00000400
	v_add_nc_u32_e32 v6, 0x80, v13                             // 000000000B30: 4A0C1AFF 00000080
	v_add_nc_u32_e32 v25, 0x104, v11                           // 000000000B38: 4A3216FF 00000104
	s_waitcnt vmcnt(1)                                         // 000000000B40: BF8907F7
	scratch_store_b128 off, v[19:22], off offset:384           // 000000000B44: DC750180 007C1300
	v_add_nc_u32_e32 v247, 0x400, v18                          // 000000000B4C: 4BEE24FF 00000400
	s_clause 0x1                                               // 000000000B54: BF850001
	global_load_b32 v3, v6, s[10:11] offset:1536               // 000000000B58: DC520600 030A0006
	global_load_b32 v7, v6, s[10:11] offset:2304               // 000000000B60: DC520900 070A0006
	s_waitcnt vmcnt(2)                                         // 000000000B68: BF890BF7
	v_add_co_u32 v1, s0, v1, v2                                // 000000000B6C: D7000001 00020501
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000B74: BF870111
	v_add_co_ci_u32_e64 v2, null, 0, 0, s0                     // 000000000B78: D5207C02 00010080
	v_add_co_u32 v27, s0, s3, v1                               // 000000000B80: D700001B 00020203
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000B88: BF8700A1
	v_add_co_ci_u32_e64 v28, s0, s33, v2, s0                   // 000000000B8C: D520001C 00020421
	v_add_co_u32 v56, s0, s60, v1                              // 000000000B94: D7000038 0002023C
	v_add_co_ci_u32_e64 v57, s0, s61, v2, s0                   // 000000000B9C: D5200039 0002043D
	v_add_co_u32 v58, s0, s62, v1                              // 000000000BA4: D700003A 0002023E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000BAC: BF8700A1
	v_add_co_ci_u32_e64 v59, s0, s63, v2, s0                   // 000000000BB0: D520003B 0002043F
	v_add_co_u32 v60, s0, s64, v1                              // 000000000BB8: D700003C 00020240
	v_add_co_ci_u32_e64 v61, s0, s65, v2, s0                   // 000000000BC0: D520003D 00020441
	v_add_co_u32 v62, s0, s66, v1                              // 000000000BC8: D700003E 00020242
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000BD0: BF8700A1
	v_add_co_ci_u32_e64 v63, s0, s67, v2, s0                   // 000000000BD4: D520003F 00020443
	v_add_co_u32 v64, s0, s68, v1                              // 000000000BDC: D7000040 00020244
	v_add_co_ci_u32_e64 v65, s0, s69, v2, s0                   // 000000000BE4: D5200041 00020445
	v_add_co_u32 v66, s0, s70, v1                              // 000000000BEC: D7000042 00020246
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000BF4: BF8700A1
	v_add_co_ci_u32_e64 v67, s0, s71, v2, s0                   // 000000000BF8: D5200043 00020447
	v_add_co_u32 v68, s0, s72, v1                              // 000000000C00: D7000044 00020248
	v_add_co_ci_u32_e64 v69, s0, s73, v2, s0                   // 000000000C08: D5200045 00020449
	v_add_co_u32 v70, s0, s74, v1                              // 000000000C10: D7000046 0002024A
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000C18: BF8700A1
	v_add_co_ci_u32_e64 v71, s0, s75, v2, s0                   // 000000000C1C: D5200047 0002044B
	v_add_co_u32 v72, s0, s76, v1                              // 000000000C24: D7000048 0002024C
	v_add_co_ci_u32_e64 v73, s0, s77, v2, s0                   // 000000000C2C: D5200049 0002044D
	v_add_nc_u32_e32 v2, 0x80, v12                             // 000000000C34: 4A0418FF 00000080
	s_clause 0x11                                              // 000000000C3C: BF850011
	global_load_b32 v243, v6, s[38:39]                         // 000000000C40: DC520000 F3260006
	global_load_b32 v1, v6, s[44:45]                           // 000000000C48: DC520000 012C0006
	global_load_b32 v5, v6, s[50:51]                           // 000000000C50: DC520000 05320006
	global_load_b32 v17, v6, s[10:11] offset:3072              // 000000000C58: DC520C00 110A0006
	global_load_b32 v15, v6, s[10:11] offset:3840              // 000000000C60: DC520F00 0F0A0006
	global_load_b32 v21, v6, s[10:11] offset:768               // 000000000C68: DC520300 150A0006
	global_load_b32 v23, v6, s[10:11]                          // 000000000C70: DC520000 170A0006
	global_load_b32 v6, v6, s[56:57]                           // 000000000C78: DC520000 06380006
	global_load_b32 v20, v2, s[10:11] offset:1536              // 000000000C80: DC520600 140A0002
	global_load_b32 v19, v2, s[10:11] offset:2304              // 000000000C88: DC520900 130A0002
	global_load_b32 v246, v2, s[10:11] offset:3072             // 000000000C90: DC520C00 F60A0002
	global_load_b32 v18, v2, s[10:11] offset:3840              // 000000000C98: DC520F00 120A0002
	global_load_b32 v16, v2, s[38:39]                          // 000000000CA0: DC520000 10260002
	global_load_b32 v245, v2, s[44:45]                         // 000000000CA8: DC520000 F52C0002
	global_load_b32 v244, v2, s[50:51]                         // 000000000CB0: DC520000 F4320002
	global_load_b32 v22, v2, s[10:11] offset:768               // 000000000CB8: DC520300 160A0002
	global_load_b32 v24, v2, s[10:11]                          // 000000000CC0: DC520000 180A0002
	global_load_b32 v2, v2, s[56:57]                           // 000000000CC8: DC520000 02380002
	global_load_b32 v26, v25, s[24:25]                         // 000000000CD0: DC520000 1A180019
	s_waitcnt vmcnt(0)                                         // 000000000CD8: BF8903F7
	scratch_store_b32 off, v26, off offset:288                 // 000000000CDC: DC690120 007C1A00
	global_load_b32 v26, v25, s[28:29]                         // 000000000CE4: DC520000 1A1C0019
	s_waitcnt vmcnt(0)                                         // 000000000CEC: BF8903F7
	scratch_store_b32 off, v26, off offset:292                 // 000000000CF0: DC690124 007C1A00
	global_load_b32 v26, v25, s[34:35]                         // 000000000CF8: DC520000 1A220019
	s_waitcnt vmcnt(0)                                         // 000000000D00: BF8903F7
	scratch_store_b32 off, v26, off offset:296                 // 000000000D04: DC690128 007C1A00
	global_load_b32 v26, v25, s[40:41]                         // 000000000D0C: DC520000 1A280019
	s_waitcnt vmcnt(0)                                         // 000000000D14: BF8903F7
	scratch_store_b32 off, v26, off offset:284                 // 000000000D18: DC69011C 007C1A00
	global_load_b32 v26, v25, s[46:47]                         // 000000000D20: DC520000 1A2E0019
	s_waitcnt vmcnt(0)                                         // 000000000D28: BF8903F7
	scratch_store_b32 off, v26, off offset:276                 // 000000000D2C: DC690114 007C1A00
	s_clause 0x1                                               // 000000000D34: BF850001
	global_load_b32 v26, v25, s[52:53]                         // 000000000D38: DC520000 1A340019
	global_load_b32 v25, v25, s[58:59]                         // 000000000D40: DC520000 193A0019
	s_waitcnt vmcnt(1)                                         // 000000000D48: BF8907F7
	scratch_store_b32 off, v26, off offset:280                 // 000000000D4C: DC690118 007C1A00
	s_waitcnt vmcnt(0)                                         // 000000000D54: BF8903F7
	scratch_store_b32 off, v25, off offset:272                 // 000000000D58: DC690110 007C1900
	v_add_nc_u32_e32 v25, 0x100, v11                           // 000000000D60: 4A3216FF 00000100
	s_clause 0x1                                               // 000000000D68: BF850001
	global_load_b32 v26, v25, s[24:25]                         // 000000000D6C: DC520000 1A180019
	global_load_b64 v[74:75], v25, s[12:13] offset:1536        // 000000000D74: DC560600 4A0C0019
	s_waitcnt vmcnt(1)                                         // 000000000D7C: BF8907F7
	scratch_store_b32 off, v26, off offset:320                 // 000000000D80: DC690140 007C1A00
	s_waitcnt vmcnt(0)                                         // 000000000D88: BF8903F7
	scratch_store_b64 off, v[74:75], off offset:340            // 000000000D8C: DC6D0154 007C4A00
	s_clause 0x1                                               // 000000000D94: BF850001
	global_load_b32 v26, v25, s[28:29]                         // 000000000D98: DC520000 1A1C0019
	global_load_b64 v[74:75], v25, s[12:13] offset:3072        // 000000000DA0: DC560C00 4A0C0019
	s_waitcnt vmcnt(1)                                         // 000000000DA8: BF8907F7
	scratch_store_b32 off, v26, off offset:324                 // 000000000DAC: DC690144 007C1A00
	global_load_b32 v26, v25, s[34:35]                         // 000000000DB4: DC520000 1A220019
	s_waitcnt vmcnt(0)                                         // 000000000DBC: BF8903F7
	scratch_store_b32 off, v26, off offset:316                 // 000000000DC0: DC69013C 007C1A00
	global_load_b32 v26, v25, s[40:41]                         // 000000000DC8: DC520000 1A280019
	s_waitcnt vmcnt(0)                                         // 000000000DD0: BF8903F7
	scratch_store_b32 off, v26, off offset:312                 // 000000000DD4: DC690138 007C1A00
	global_load_b32 v26, v25, s[46:47]                         // 000000000DDC: DC520000 1A2E0019
	s_waitcnt vmcnt(0)                                         // 000000000DE4: BF8903F7
	scratch_store_b32 off, v26, off offset:304                 // 000000000DE8: DC690130 007C1A00
	global_load_b32 v26, v25, s[52:53]                         // 000000000DF0: DC520000 1A340019
	s_waitcnt vmcnt(0)                                         // 000000000DF8: BF8903F7
	scratch_store_b32 off, v26, off offset:308                 // 000000000DFC: DC690134 007C1A00
	global_load_b32 v26, v25, s[58:59]                         // 000000000E04: DC520000 1A3A0019
	s_waitcnt vmcnt(0)                                         // 000000000E0C: BF8903F7
	scratch_store_b32 off, v26, off offset:300                 // 000000000E10: DC69012C 007C1A00
	global_load_b64 v[25:26], v25, s[12:13]                    // 000000000E18: DC560000 190C0019
	scratch_store_b64 off, v[74:75], off offset:332            // 000000000E20: DC6D014C 007C4A00
	s_waitcnt vmcnt(0)                                         // 000000000E28: BF8903F7
	scratch_store_b64 off, v[25:26], off offset:348            // 000000000E2C: DC6D015C 007C1900
	s_clause 0x13                                              // 000000000E34: BF850013
	global_load_b128 v[200:203], v[27:28], off                 // 000000000E38: DC5E0000 C87C001B
	global_load_b128 v[196:199], v[56:57], off                 // 000000000E40: DC5E0000 C47C0038
	global_load_b128 v[184:187], v[58:59], off                 // 000000000E48: DC5E0000 B87C003A
	global_load_b128 v[176:179], v[60:61], off                 // 000000000E50: DC5E0000 B07C003C
	global_load_b128 v[168:171], v[62:63], off                 // 000000000E58: DC5E0000 A87C003E
	global_load_b128 v[128:131], v[64:65], off                 // 000000000E60: DC5E0000 807C0040
	global_load_b128 v[124:127], v[66:67], off                 // 000000000E68: DC5E0000 7C7C0042
	global_load_b128 v[120:123], v[68:69], off                 // 000000000E70: DC5E0000 787C0044
	global_load_b128 v[116:119], v[70:71], off                 // 000000000E78: DC5E0000 747C0046
	global_load_b128 v[100:103], v[72:73], off                 // 000000000E80: DC5E0000 647C0048
	global_load_b128 v[88:91], v247, s[18:19]                  // 000000000E88: DC5E0000 581200F7
	global_load_b128 v[84:87], v247, s[20:21]                  // 000000000E90: DC5E0000 541400F7
	global_load_b128 v[80:83], v247, s[22:23]                  // 000000000E98: DC5E0000 501600F7
	global_load_b128 v[76:79], v247, s[26:27]                  // 000000000EA0: DC5E0000 4C1A00F7
	global_load_b128 v[72:75], v247, s[30:31]                  // 000000000EA8: DC5E0000 481E00F7
	global_load_b128 v[68:71], v247, s[36:37]                  // 000000000EB0: DC5E0000 442400F7
	global_load_b128 v[64:67], v247, s[42:43]                  // 000000000EB8: DC5E0000 402A00F7
	global_load_b128 v[60:63], v247, s[48:49]                  // 000000000EC0: DC5E0000 3C3000F7
	global_load_b128 v[92:95], v247, s[8:9]                    // 000000000EC8: DC5E0000 5C0800F7
	global_load_b128 v[56:59], v247, s[54:55]                  // 000000000ED0: DC5E0000 383600F7
	v_lshrrev_b32_e32 v25, v253, v33                           // 000000000ED8: 323243FD
	v_lshrrev_b32_e32 v26, v253, v35                           // 000000000EDC: 323447FD
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000EE0: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000EE4: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000EE8: 8D00007E
	s_cbranch_execz 7                                          // 000000000EEC: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xf0c>
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000EF0: BF8700A1
	v_and_b32_e32 v27, 15, v26                                 // 000000000EF4: 3636348F
	v_lshrrev_b32_e32 v28, 2, v25                              // 000000000EF8: 32383282
	v_and_or_b32 v27, v28, 48, v27                             // 000000000EFC: D657001B 046D611C
	scratch_store_b32 off, v27, off offset:368                 // 000000000F04: DC690170 007C1B00
	s_and_not1_saveexec_b32 s0, s0                             // 000000000F0C: BE803000
	s_cbranch_execz 3                                          // 000000000F10: BFA50003 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xf20>
	v_and_b32_e32 v27, 63, v25                                 // 000000000F14: 363632BF
	scratch_store_b32 off, v27, off offset:368                 // 000000000F18: DC690170 007C1B00
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000F20: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000F24: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000F28: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000F2C: 8D00007E
	s_cbranch_execz 8                                          // 000000000F30: BFA50008 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xf54>
	v_lshrrev_b32_e32 v25, 10, v25                             // 000000000F34: 3232328A
	v_lshrrev_b32_e32 v26, 8, v26                              // 000000000F38: 32343488
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000F3C: BF870092
	v_and_b32_e32 v25, 48, v25                                 // 000000000F40: 363232B0
	v_and_or_b32 v25, v26, 15, v25                             // 000000000F44: D6570019 04651F1A
	scratch_store_b32 off, v25, off offset:372                 // 000000000F4C: DC690174 007C1900
	s_and_not1_saveexec_b32 s0, s0                             // 000000000F54: BE803000
	s_cbranch_execz 4                                          // 000000000F58: BFA50004 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xf6c>
	v_bfe_u32 v25, v25, 8, 6                                   // 000000000F5C: D6100019 02191119
	scratch_store_b32 off, v25, off offset:372                 // 000000000F64: DC690174 007C1900
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000F6C: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000F70: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000F74: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000F78: 8D00007E
	s_cbranch_execz 14                                         // 000000000F7C: BFA5000E <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xfb8>
	scratch_load_b32 v26, off, off                             // 000000000F80: DC510000 1A7C0000
	s_waitcnt vmcnt(0)                                         // 000000000F88: BF8903F7
	v_lshrrev_b32_e32 v25, v26, v34                            // 000000000F8C: 3232451A
	v_lshrrev_b32_e32 v26, v26, v35                            // 000000000F90: 3234471A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000F94: BF870112
	v_lshrrev_b32_e32 v25, 2, v25                              // 000000000F98: 32323282
	v_lshrrev_b32_e32 v26, 4, v26                              // 000000000F9C: 32343484
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000FA0: BF870092
	v_and_b32_e32 v25, 48, v25                                 // 000000000FA4: 363232B0
	v_and_or_b32 v25, v26, 15, v25                             // 000000000FA8: D6570019 04651F1A
	scratch_store_b32 off, v25, off offset:360                 // 000000000FB0: DC690168 007C1900
	s_and_not1_saveexec_b32 s0, s0                             // 000000000FB8: BE803000
	s_cbranch_execz 7                                          // 000000000FBC: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0xfdc>
	scratch_load_b32 v25, off, off                             // 000000000FC0: DC510000 197C0000
	s_waitcnt vmcnt(0)                                         // 000000000FC8: BF8903F7
	v_bfe_u32 v25, v34, v25, 6                                 // 000000000FCC: D6100019 021A3322
	scratch_store_b32 off, v25, off offset:360                 // 000000000FD4: DC690168 007C1900
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000FDC: 8C7E007E
	v_lshrrev_b32_e32 v25, v253, v37                           // 000000000FE0: 32324BFD
	v_lshrrev_b32_e32 v26, v253, v39                           // 000000000FE4: 32344FFD
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000FE8: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000FEC: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000000FF0: 8D00007E
	s_cbranch_execz 7                                          // 000000000FF4: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x1014>
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000FF8: BF8700A1
	v_and_b32_e32 v27, 15, v26                                 // 000000000FFC: 3636348F
	v_lshrrev_b32_e32 v28, 2, v25                              // 000000001000: 32383282
	v_and_or_b32 v27, v28, 48, v27                             // 000000001004: D657001B 046D611C
	scratch_store_b32 off, v27, off offset:376                 // 00000000100C: DC690178 007C1B00
	s_and_not1_saveexec_b32 s0, s0                             // 000000001014: BE803000
	s_cbranch_execz 3                                          // 000000001018: BFA50003 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x1028>
	v_and_b32_e32 v27, 63, v25                                 // 00000000101C: 363632BF
	scratch_store_b32 off, v27, off offset:376                 // 000000001020: DC690178 007C1B00
	s_or_b32 exec_lo, exec_lo, s0                              // 000000001028: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 00000000102C: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001030: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000001034: 8D00007E
	s_cbranch_execz 8                                          // 000000001038: BFA50008 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x105c>
	v_lshrrev_b32_e32 v25, 10, v25                             // 00000000103C: 3232328A
	v_lshrrev_b32_e32 v26, 8, v26                              // 000000001040: 32343488
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001044: BF870092
	v_and_b32_e32 v25, 48, v25                                 // 000000001048: 363232B0
	v_and_or_b32 v25, v26, 15, v25                             // 00000000104C: D6570019 04651F1A
	scratch_store_b32 off, v25, off offset:380                 // 000000001054: DC69017C 007C1900
	s_and_not1_saveexec_b32 s0, s0                             // 00000000105C: BE803000
	s_cbranch_execz 4                                          // 000000001060: BFA50004 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x1074>
	v_bfe_u32 v25, v25, 8, 6                                   // 000000001064: D6100019 02191119
	scratch_store_b32 off, v25, off offset:380                 // 00000000106C: DC69017C 007C1900
	s_or_b32 exec_lo, exec_lo, s0                              // 000000001074: 8C7E007E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000001078: BE80206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000107C: BF870009
	s_xor_b32 s0, exec_lo, s0                                  // 000000001080: 8D00007E
	s_cbranch_execz 14                                         // 000000001084: BFA5000E <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x10c0>
	scratch_load_b32 v26, off, off                             // 000000001088: DC510000 1A7C0000
	s_waitcnt vmcnt(0)                                         // 000000001090: BF8903F7
	v_lshrrev_b32_e32 v25, v26, v38                            // 000000001094: 32324D1A
	v_lshrrev_b32_e32 v26, v26, v39                            // 000000001098: 32344F1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000109C: BF870112
	v_lshrrev_b32_e32 v25, 2, v25                              // 0000000010A0: 32323282
	v_lshrrev_b32_e32 v26, 4, v26                              // 0000000010A4: 32343484
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000010A8: BF870092
	v_and_b32_e32 v25, 48, v25                                 // 0000000010AC: 363232B0
	v_and_or_b32 v25, v26, 15, v25                             // 0000000010B0: D6570019 04651F1A
	scratch_store_b32 off, v25, off offset:364                 // 0000000010B8: DC69016C 007C1900
	s_and_not1_saveexec_b32 s0, s0                             // 0000000010C0: BE803000
	s_cbranch_execz 7                                          // 0000000010C4: BFA50007 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x10e4>
	scratch_load_b32 v25, off, off                             // 0000000010C8: DC510000 197C0000
	s_waitcnt vmcnt(0)                                         // 0000000010D0: BF8903F7
	v_bfe_u32 v25, v38, v25, 6                                 // 0000000010D4: D6100019 021A3326
	scratch_store_b32 off, v25, off offset:364                 // 0000000010DC: DC69016C 007C1900
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000010E4: 8C7E007E
	scratch_load_b32 v247, off, off offset:412                 // 0000000010E8: DC51019C F77C0000
	v_lshrrev_b32_e32 v25, 4, v107                             // 0000000010F0: 3232D684
	v_lshrrev_b32_e32 v26, v238, v115                          // 0000000010F4: 3234E7EE
	v_add_nc_u32_e32 v11, 0x200, v11                           // 0000000010F8: 4A1616FF 00000200
	v_add_nc_u32_e32 v13, 0x100, v13                           // 000000001100: 4A1A1AFF 00000100
	s_addk_i32 s1, 0x580                                       // 000000001108: B7810580
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 00000000110C: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v26, 4, v26                              // 000000001114: 30343484
	s_cmpk_lg_i32 s1, 0x1080                                   // 000000001118: B2011080
	v_add_nc_u32_e32 v12, 0x100, v12                           // 00000000111C: 4A1818FF 00000100
	v_add_nc_u32_e32 v14, 0x800, v14                           // 000000001124: 4A1C1CFF 00000800
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 00000000112C: BF870133
	v_and_or_b32 v34, 0x10101010, v26, v25                     // 000000001130: D6570022 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v106                             // 00000000113C: 3232D484
	v_lshrrev_b32_e32 v26, v237, v114                          // 000000001140: 3234E5ED
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 000000001144: 363232FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000114C: BF870092
	v_lshlrev_b32_e32 v26, 4, v26                              // 000000001150: 30343484
	v_and_or_b32 v33, 0x10101010, v26, v25                     // 000000001154: D6570021 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v105                             // 000000001160: 3232D284
	v_lshrrev_b32_e32 v26, v236, v113                          // 000000001164: 3234E3EC
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001168: BF870112
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 00000000116C: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v26, 4, v26                              // 000000001174: 30343484
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001178: BF8700A1
	v_and_or_b32 v26, 0x10101010, v26, v25                     // 00000000117C: D657001A 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v104                             // 000000001188: 3232D084
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 00000000118C: 363232FF 0F0F0F0F
	s_waitcnt vmcnt(0)                                         // 000000001194: BF8903F7
	v_lshrrev_b32_e32 v27, v247, v112                          // 000000001198: 3236E1F7
	v_lshrrev_b32_e32 v38, v247, v108                          // 00000000119C: 324CD9F7
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000011A0: BF870112
	v_lshlrev_b32_e32 v27, 4, v27                              // 0000000011A4: 30363684
	v_lshlrev_b32_e32 v38, 4, v38                              // 0000000011A8: 304C4C84
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 0000000011AC: BF8701C2
	v_and_or_b32 v28, 0x10101010, v27, v25                     // 0000000011B0: D657001C 046636FF 10101010
	v_lshrrev_b32_e32 v25, 4, v99                              // 0000000011BC: 3232C684
	v_lshrrev_b32_e32 v27, v238, v111                          // 0000000011C0: 3236DFEE
	v_and_b32_e32 v99, 0xf0f0f0f, v99                          // 0000000011C4: 36C6C6FF 0F0F0F0F
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 0000000011CC: 363232FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000011D4: BF870093
	v_lshlrev_b32_e32 v27, 4, v27                              // 0000000011D8: 30363684
	v_and_or_b32 v35, 0x10101010, v27, v25                     // 0000000011DC: D6570023 046636FF 10101010
	v_lshrrev_b32_e32 v25, 4, v98                              // 0000000011E8: 3232C484
	v_lshrrev_b32_e32 v27, v237, v110                          // 0000000011EC: 3236DDED
	v_and_b32_e32 v98, 0xf0f0f0f, v98                          // 0000000011F0: 36C4C4FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000011F8: BF870193
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 0000000011FC: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v27, 4, v27                              // 000000001204: 30363684
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 000000001208: BF8701C1
	v_and_or_b32 v37, 0x10101010, v27, v25                     // 00000000120C: D6570025 046636FF 10101010
	v_lshrrev_b32_e32 v25, 4, v97                              // 000000001218: 3232C284
	v_lshrrev_b32_e32 v27, v236, v109                          // 00000000121C: 3236DBEC
	v_and_b32_e32 v97, 0xf0f0f0f, v97                          // 000000001220: 36C2C2FF 0F0F0F0F
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 000000001228: 363232FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001230: BF870093
	v_lshlrev_b32_e32 v27, 4, v27                              // 000000001234: 30363684
	v_and_or_b32 v25, 0x10101010, v27, v25                     // 000000001238: D6570019 046636FF 10101010
	v_lshrrev_b32_e32 v27, 4, v96                              // 000000001244: 3236C084
	v_and_b32_e32 v96, 0xf0f0f0f, v96                          // 000000001248: 36C0C0FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001250: BF870092
	v_and_b32_e32 v27, 0xf0f0f0f, v27                          // 000000001254: 363636FF 0F0F0F0F
	v_and_or_b32 v27, 0x10101010, v38, v27                     // 00000000125C: D657001B 046E4CFF 10101010
	v_dot4_i32_iu8 v38, v28, v228, 0 neg_lo:[0,1,0]            // 000000001268: CC164026 5A03C91C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001270: BF870112
	v_dot4_i32_iu8 v39, v27, v228, 0 neg_lo:[0,1,0]            // 000000001274: CC164027 5A03C91B
	v_dot4_i32_iu8 v38, v26, v229, v38 neg_lo:[0,1,0]          // 00000000127C: CC164026 5C9BCB1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001284: BF870112
	v_dot4_i32_iu8 v39, v25, v229, v39 neg_lo:[0,1,0]          // 000000001288: CC164027 5C9FCB19
	v_dot4_i32_iu8 v38, v33, v230, v38 neg_lo:[0,1,0]          // 000000001290: CC164026 5C9BCD21
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001298: BF870112
	v_dot4_i32_iu8 v228, v37, v230, v39 neg_lo:[0,1,0]         // 00000000129C: CC1640E4 5C9FCD25
	v_dot4_i32_iu8 v39, v34, v231, v38 neg_lo:[0,1,0]          // 0000000012A4: CC164027 5C9BCF22
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 0000000012AC: BF870232
	v_dot4_i32_iu8 v38, v35, v231, v228 neg_lo:[0,1,0]         // 0000000012B0: CC164026 5F93CF23
	v_dot4_i32_iu8 v228, v28, v224, 0 neg_lo:[0,1,0]           // 0000000012B8: CC1640E4 5A03C11C
	v_dot4_i32_iu8 v224, v27, v224, 0 neg_lo:[0,1,0]           // 0000000012C0: CC1640E0 5A03C11B
	v_cvt_f32_i32_e32 v39, v39                                 // 0000000012C8: 7E4E0B27
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000012CC: BF870214
	v_cvt_f32_i32_e32 v38, v38                                 // 0000000012D0: 7E4C0B26
	v_dot4_i32_iu8 v228, v26, v225, v228 neg_lo:[0,1,0]        // 0000000012D4: CC1640E4 5F93C31A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000012DC: BF870114
	v_dot4_i32_iu8 v224, v25, v225, v224 neg_lo:[0,1,0]        // 0000000012E0: CC1640E0 5F83C319
	v_dot4_i32_iu8 v225, v33, v226, v228 neg_lo:[0,1,0]        // 0000000012E8: CC1640E1 5F93C521
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 0000000012F0: BF870232
	v_dot4_i32_iu8 v224, v37, v226, v224 neg_lo:[0,1,0]        // 0000000012F4: CC1640E0 5F83C525
	v_dot4_i32_iu8 v226, v28, v220, 0 neg_lo:[0,1,0]           // 0000000012FC: CC1640E2 5A03B91C
	v_dot4_i32_iu8 v220, v27, v220, 0 neg_lo:[0,1,0]           // 000000001304: CC1640DC 5A03B91B
	v_dot4_i32_iu8 v225, v34, v227, v225 neg_lo:[0,1,0]        // 00000000130C: CC1640E1 5F87C722
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001314: BF870214
	v_dot4_i32_iu8 v224, v35, v227, v224 neg_lo:[0,1,0]        // 000000001318: CC1640E0 5F83C723
	v_dot4_i32_iu8 v226, v26, v221, v226 neg_lo:[0,1,0]        // 000000001320: CC1640E2 5F8BBB1A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001328: BF870114
	v_dot4_i32_iu8 v220, v25, v221, v220 neg_lo:[0,1,0]        // 00000000132C: CC1640DC 5F73BB19
	v_dot4_i32_iu8 v221, v33, v222, v226 neg_lo:[0,1,0]        // 000000001334: CC1640DD 5F8BBD21
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 00000000133C: BF870232
	v_dot4_i32_iu8 v220, v37, v222, v220 neg_lo:[0,1,0]        // 000000001340: CC1640DC 5F73BD25
	v_dot4_i32_iu8 v222, v28, v216, 0 neg_lo:[0,1,0]           // 000000001348: CC1640DE 5A03B11C
	v_dot4_i32_iu8 v216, v27, v216, 0 neg_lo:[0,1,0]           // 000000001350: CC1640D8 5A03B11B
	v_dot4_i32_iu8 v221, v34, v223, v221 neg_lo:[0,1,0]        // 000000001358: CC1640DD 5F77BF22
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001360: BF870214
	v_dot4_i32_iu8 v220, v35, v223, v220 neg_lo:[0,1,0]        // 000000001364: CC1640DC 5F73BF23
	v_dot4_i32_iu8 v222, v26, v217, v222 neg_lo:[0,1,0]        // 00000000136C: CC1640DE 5F7BB31A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001374: BF870114
	v_dot4_i32_iu8 v216, v25, v217, v216 neg_lo:[0,1,0]        // 000000001378: CC1640D8 5F63B319
	v_dot4_i32_iu8 v217, v33, v218, v222 neg_lo:[0,1,0]        // 000000001380: CC1640D9 5F7BB521
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 000000001388: BF870232
	v_dot4_i32_iu8 v216, v37, v218, v216 neg_lo:[0,1,0]        // 00000000138C: CC1640D8 5F63B525
	v_dot4_i32_iu8 v218, v28, v212, 0 neg_lo:[0,1,0]           // 000000001394: CC1640DA 5A03A91C
	v_dot4_i32_iu8 v212, v27, v212, 0 neg_lo:[0,1,0]           // 00000000139C: CC1640D4 5A03A91B
	v_dot4_i32_iu8 v217, v34, v219, v217 neg_lo:[0,1,0]        // 0000000013A4: CC1640D9 5F67B722
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000013AC: BF870214
	v_dot4_i32_iu8 v216, v35, v219, v216 neg_lo:[0,1,0]        // 0000000013B0: CC1640D8 5F63B723
	v_dot4_i32_iu8 v218, v26, v213, v218 neg_lo:[0,1,0]        // 0000000013B8: CC1640DA 5F6BAB1A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000013C0: BF870114
	v_dot4_i32_iu8 v212, v25, v213, v212 neg_lo:[0,1,0]        // 0000000013C4: CC1640D4 5F53AB19
	v_dot4_i32_iu8 v213, v33, v214, v218 neg_lo:[0,1,0]        // 0000000013CC: CC1640D5 5F6BAD21
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 0000000013D4: BF870232
	v_dot4_i32_iu8 v212, v37, v214, v212 neg_lo:[0,1,0]        // 0000000013D8: CC1640D4 5F53AD25
	v_dot4_i32_iu8 v214, v28, v208, 0 neg_lo:[0,1,0]           // 0000000013E0: CC1640D6 5A03A11C
	v_dot4_i32_iu8 v208, v27, v208, 0 neg_lo:[0,1,0]           // 0000000013E8: CC1640D0 5A03A11B
	v_dot4_i32_iu8 v213, v34, v215, v213 neg_lo:[0,1,0]        // 0000000013F0: CC1640D5 5F57AF22
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000013F8: BF870214
	v_dot4_i32_iu8 v212, v35, v215, v212 neg_lo:[0,1,0]        // 0000000013FC: CC1640D4 5F53AF23
	v_dot4_i32_iu8 v214, v26, v209, v214 neg_lo:[0,1,0]        // 000000001404: CC1640D6 5F5BA31A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000140C: BF870114
	v_dot4_i32_iu8 v208, v25, v209, v208 neg_lo:[0,1,0]        // 000000001410: CC1640D0 5F43A319
	v_dot4_i32_iu8 v209, v33, v210, v214 neg_lo:[0,1,0]        // 000000001418: CC1640D1 5F5BA521
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 000000001420: BF870232
	v_dot4_i32_iu8 v208, v37, v210, v208 neg_lo:[0,1,0]        // 000000001424: CC1640D0 5F43A525
	v_dot4_i32_iu8 v210, v28, v204, 0 neg_lo:[0,1,0]           // 00000000142C: CC1640D2 5A03991C
	v_dot4_i32_iu8 v204, v27, v204, 0 neg_lo:[0,1,0]           // 000000001434: CC1640CC 5A03991B
	v_dot4_i32_iu8 v209, v34, v211, v209 neg_lo:[0,1,0]        // 00000000143C: CC1640D1 5F47A722
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001444: BF870214
	v_dot4_i32_iu8 v208, v35, v211, v208 neg_lo:[0,1,0]        // 000000001448: CC1640D0 5F43A723
	v_dot4_i32_iu8 v210, v26, v205, v210 neg_lo:[0,1,0]        // 000000001450: CC1640D2 5F4B9B1A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001458: BF870114
	v_dot4_i32_iu8 v204, v25, v205, v204 neg_lo:[0,1,0]        // 00000000145C: CC1640CC 5F339B19
	v_dot4_i32_iu8 v205, v33, v206, v210 neg_lo:[0,1,0]        // 000000001464: CC1640CD 5F4B9D21
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 00000000146C: BF870232
	v_dot4_i32_iu8 v204, v37, v206, v204 neg_lo:[0,1,0]        // 000000001470: CC1640CC 5F339D25
	v_dot4_i32_iu8 v206, v28, v192, 0 neg_lo:[0,1,0]           // 000000001478: CC1640CE 5A03811C
	v_dot4_i32_iu8 v192, v27, v192, 0 neg_lo:[0,1,0]           // 000000001480: CC1640C0 5A03811B
	v_dot4_i32_iu8 v205, v34, v207, v205 neg_lo:[0,1,0]        // 000000001488: CC1640CD 5F379F22
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001490: BF870214
	v_dot4_i32_iu8 v204, v35, v207, v204 neg_lo:[0,1,0]        // 000000001494: CC1640CC 5F339F23
	v_dot4_i32_iu8 v206, v26, v193, v206 neg_lo:[0,1,0]        // 00000000149C: CC1640CE 5F3B831A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000014A4: BF870114
	v_dot4_i32_iu8 v192, v25, v193, v192 neg_lo:[0,1,0]        // 0000000014A8: CC1640C0 5F038319
	v_dot4_i32_iu8 v193, v33, v194, v206 neg_lo:[0,1,0]        // 0000000014B0: CC1640C1 5F3B8521
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000014B8: BF870112
	v_dot4_i32_iu8 v194, v37, v194, v192 neg_lo:[0,1,0]        // 0000000014BC: CC1640C2 5F038525
	v_dot4_i32_iu8 v192, v34, v195, v193 neg_lo:[0,1,0]        // 0000000014C4: CC1640C0 5F078722
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_4)// 0000000014CC: BF870252
	v_dot4_i32_iu8 v193, v35, v195, v194 neg_lo:[0,1,0]        // 0000000014D0: CC1640C1 5F0B8723
	v_dot4_i32_iu8 v194, v28, v188, 0 neg_lo:[0,1,0]           // 0000000014D8: CC1640C2 5A03791C
	v_dot4_i32_iu8 v188, v27, v188, 0 neg_lo:[0,1,0]           // 0000000014E0: CC1640BC 5A03791B
	v_dot4_i32_iu8 v28, v28, v180, 0 neg_lo:[0,1,0]            // 0000000014E8: CC16401C 5A03691C
	v_dot4_i32_iu8 v27, v27, v180, 0 neg_lo:[0,1,0]            // 0000000014F0: CC16401B 5A03691B
	v_dot4_i32_iu8 v194, v26, v189, v194 neg_lo:[0,1,0]        // 0000000014F8: CC1640C2 5F0B7B1A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001500: BF870214
	v_dot4_i32_iu8 v188, v25, v189, v188 neg_lo:[0,1,0]        // 000000001504: CC1640BC 5EF37B19
	v_dot4_i32_iu8 v26, v26, v181, v28 neg_lo:[0,1,0]          // 00000000150C: CC16401A 5C736B1A
	s_delay_alu instid0(VALU_DEP_4)                            // 000000001514: BF870004
	v_dot4_i32_iu8 v25, v25, v181, v27 neg_lo:[0,1,0]          // 000000001518: CC164019 5C6F6B19
	v_lshrrev_b32_e32 v27, v233, v113                          // 000000001520: 3236E3E9
	v_dot4_i32_iu8 v189, v33, v190, v194 neg_lo:[0,1,0]        // 000000001524: CC1640BD 5F0B7D21
	v_dot4_i32_iu8 v188, v37, v190, v188 neg_lo:[0,1,0]        // 00000000152C: CC1640BC 5EF37D25
	v_dot4_i32_iu8 v26, v33, v182, v26 neg_lo:[0,1,0]          // 000000001534: CC16401A 5C6B6D21
	v_dot4_i32_iu8 v25, v37, v182, v25 neg_lo:[0,1,0]          // 00000000153C: CC164019 5C676D25
	scratch_load_b32 v182, off, off offset:408                 // 000000001544: DC510198 B67C0000
	v_and_b32_e32 v33, 0xf0f0f0f, v107                         // 00000000154C: 3642D6FF 0F0F0F0F
	v_and_b32_e32 v37, 0xf0f0f0f, v104                         // 000000001554: 364AD0FF 0F0F0F0F
	v_dot4_i32_iu8 v188, v35, v191, v188 neg_lo:[0,1,0]        // 00000000155C: CC1640BC 5EF37F23
	v_dot4_i32_iu8 v181, v34, v183, v26 neg_lo:[0,1,0]         // 000000001564: CC1640B5 5C6B6F22
	v_dot4_i32_iu8 v180, v35, v183, v25 neg_lo:[0,1,0]         // 00000000156C: CC1640B4 5C676F23
	v_lshrrev_b32_e32 v26, v234, v114                          // 000000001574: 3234E5EA
	v_and_b32_e32 v35, 0xf0f0f0f, v105                         // 000000001578: 3646D2FF 0F0F0F0F
	v_lshlrev_b32_e32 v27, 4, v27                              // 000000001580: 30363684
	v_dot4_i32_iu8 v189, v34, v191, v189 neg_lo:[0,1,0]        // 000000001584: CC1640BD 5EF77F22
	v_lshrrev_b32_e32 v25, v235, v115                          // 00000000158C: 3232E7EB
	v_and_b32_e32 v34, 0xf0f0f0f, v106                         // 000000001590: 3644D4FF 0F0F0F0F
	v_lshrrev_b32_e32 v106, v233, v109                         // 000000001598: 32D4DBE9
	v_lshlrev_b32_e32 v26, 4, v26                              // 00000000159C: 30343484
	v_and_or_b32 v27, 0x10101010, v27, v35                     // 0000000015A0: D657001B 048E36FF 10101010
	v_lshlrev_b32_e32 v25, 4, v25                              // 0000000015AC: 30323284
	v_lshrrev_b32_e32 v105, v234, v110                         // 0000000015B0: 32D2DDEA
	v_lshlrev_b32_e32 v35, 4, v106                             // 0000000015B4: 3046D484
	v_and_or_b32 v26, 0x10101010, v26, v34                     // 0000000015B8: D657001A 048A34FF 10101010
	v_lshrrev_b32_e32 v104, v235, v111                         // 0000000015C4: 32D0DFEB
	v_and_or_b32 v25, 0x10101010, v25, v33                     // 0000000015C8: D6570019 048632FF 10101010
	v_lshlrev_b32_e32 v34, 4, v105                             // 0000000015D4: 3044D284
	v_and_or_b32 v35, 0x10101010, v35, v97                     // 0000000015D8: D6570023 058646FF 10101010
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000015E4: BF870194
	v_lshlrev_b32_e32 v33, 4, v104                             // 0000000015E8: 3042D084
	v_and_or_b32 v34, 0x10101010, v34, v98                     // 0000000015EC: D6570022 058A44FF 10101010
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 0000000015F8: BF870142
	v_and_or_b32 v33, 0x10101010, v33, v99                     // 0000000015FC: D6570021 058E42FF 10101010
	s_waitcnt vmcnt(0)                                         // 000000001608: BF8903F7
	v_lshrrev_b32_e32 v28, v182, v112                          // 00000000160C: 3238E1B6
	v_lshrrev_b32_e32 v107, v182, v108                         // 000000001610: 32D6D9B6
	v_lshlrev_b32_e32 v28, 4, v28                              // 000000001614: 30383884
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001618: BF870191
	v_and_or_b32 v28, 0x10101010, v28, v37                     // 00000000161C: D657001C 049638FF 10101010
	v_lshlrev_b32_e32 v37, 4, v107                             // 000000001628: 304AD684
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000162C: BF870191
	v_and_or_b32 v37, 0x10101010, v37, v96                     // 000000001630: D6570025 05824AFF 10101010
	v_dot4_i32_iu8 v96, v28, v172, 0 neg_lo:[0,1,0]            // 00000000163C: CC164060 5A03591C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001644: BF870112
	v_dot4_i32_iu8 v97, v37, v172, 0 neg_lo:[0,1,0]            // 000000001648: CC164061 5A035925
	v_dot4_i32_iu8 v96, v27, v173, v96 neg_lo:[0,1,0]          // 000000001650: CC164060 5D835B1B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001658: BF870112
	v_dot4_i32_iu8 v97, v35, v173, v97 neg_lo:[0,1,0]          // 00000000165C: CC164061 5D875B23
	v_dot4_i32_iu8 v96, v26, v174, v96 neg_lo:[0,1,0]          // 000000001664: CC164060 5D835D1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000166C: BF870112
	v_dot4_i32_iu8 v97, v34, v174, v97 neg_lo:[0,1,0]          // 000000001670: CC164061 5D875D22
	v_dot4_i32_iu8 v173, v25, v175, v96 neg_lo:[0,1,0]         // 000000001678: CC1640AD 5D835F19
	v_dot4_i32_iu8 v96, v28, v136, 0 neg_lo:[0,1,0]            // 000000001680: CC164060 5A03111C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001688: BF8701A3
	v_dot4_i32_iu8 v172, v33, v175, v97 neg_lo:[0,1,0]         // 00000000168C: CC1640AC 5D875F21
	v_dot4_i32_iu8 v97, v37, v136, 0 neg_lo:[0,1,0]            // 000000001694: CC164061 5A031125
	v_dot4_i32_iu8 v96, v27, v137, v96 neg_lo:[0,1,0]          // 00000000169C: CC164060 5D83131B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000016A4: BF870112
	v_dot4_i32_iu8 v97, v35, v137, v97 neg_lo:[0,1,0]          // 0000000016A8: CC164061 5D871323
	v_dot4_i32_iu8 v96, v26, v138, v96 neg_lo:[0,1,0]          // 0000000016B0: CC164060 5D83151A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000016B8: BF870112
	v_dot4_i32_iu8 v97, v34, v138, v97 neg_lo:[0,1,0]          // 0000000016BC: CC164061 5D871522
	v_dot4_i32_iu8 v136, v25, v139, v96 neg_lo:[0,1,0]         // 0000000016C4: CC164088 5D831719
	v_dot4_i32_iu8 v96, v28, v132, 0 neg_lo:[0,1,0]            // 0000000016CC: CC164060 5A03091C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 0000000016D4: BF8701A3
	v_dot4_i32_iu8 v115, v33, v139, v97 neg_lo:[0,1,0]         // 0000000016D8: CC164073 5D871721
	v_dot4_i32_iu8 v97, v37, v132, 0 neg_lo:[0,1,0]            // 0000000016E0: CC164061 5A030925
	v_dot4_i32_iu8 v96, v27, v133, v96 neg_lo:[0,1,0]          // 0000000016E8: CC164060 5D830B1B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000016F0: BF870112
	v_dot4_i32_iu8 v97, v35, v133, v97 neg_lo:[0,1,0]          // 0000000016F4: CC164061 5D870B23
	v_dot4_i32_iu8 v96, v26, v134, v96 neg_lo:[0,1,0]          // 0000000016FC: CC164060 5D830D1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001704: BF870112
	v_dot4_i32_iu8 v97, v34, v134, v97 neg_lo:[0,1,0]          // 000000001708: CC164061 5D870D22
	v_dot4_i32_iu8 v132, v25, v135, v96 neg_lo:[0,1,0]         // 000000001710: CC164084 5D830F19
	v_dot4_i32_iu8 v96, v28, v148, 0 neg_lo:[0,1,0]            // 000000001718: CC164060 5A03291C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001720: BF8701A3
	v_dot4_i32_iu8 v113, v33, v135, v97 neg_lo:[0,1,0]         // 000000001724: CC164071 5D870F21
	v_dot4_i32_iu8 v97, v37, v148, 0 neg_lo:[0,1,0]            // 00000000172C: CC164061 5A032925
	v_dot4_i32_iu8 v96, v27, v149, v96 neg_lo:[0,1,0]          // 000000001734: CC164060 5D832B1B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000173C: BF870112
	v_dot4_i32_iu8 v97, v35, v149, v97 neg_lo:[0,1,0]          // 000000001740: CC164061 5D872B23
	v_dot4_i32_iu8 v96, v26, v150, v96 neg_lo:[0,1,0]          // 000000001748: CC164060 5D832D1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001750: BF870112
	v_dot4_i32_iu8 v97, v34, v150, v97 neg_lo:[0,1,0]          // 000000001754: CC164061 5D872D22
	v_dot4_i32_iu8 v114, v25, v151, v96 neg_lo:[0,1,0]         // 00000000175C: CC164072 5D832F19
	v_dot4_i32_iu8 v96, v28, v140, 0 neg_lo:[0,1,0]            // 000000001764: CC164060 5A03191C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 00000000176C: BF8701A3
	v_dot4_i32_iu8 v111, v33, v151, v97 neg_lo:[0,1,0]         // 000000001770: CC16406F 5D872F21
	v_dot4_i32_iu8 v97, v37, v140, 0 neg_lo:[0,1,0]            // 000000001778: CC164061 5A031925
	v_dot4_i32_iu8 v96, v27, v141, v96 neg_lo:[0,1,0]          // 000000001780: CC164060 5D831B1B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001788: BF870112
	v_dot4_i32_iu8 v97, v35, v141, v97 neg_lo:[0,1,0]          // 00000000178C: CC164061 5D871B23
	v_dot4_i32_iu8 v96, v26, v142, v96 neg_lo:[0,1,0]          // 000000001794: CC164060 5D831D1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000179C: BF870112
	v_dot4_i32_iu8 v97, v34, v142, v97 neg_lo:[0,1,0]          // 0000000017A0: CC164061 5D871D22
	v_dot4_i32_iu8 v112, v25, v143, v96 neg_lo:[0,1,0]         // 0000000017A8: CC164070 5D831F19
	v_dot4_i32_iu8 v96, v28, v160, 0 neg_lo:[0,1,0]            // 0000000017B0: CC164060 5A03411C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 0000000017B8: BF8701A3
	v_dot4_i32_iu8 v109, v33, v143, v97 neg_lo:[0,1,0]         // 0000000017BC: CC16406D 5D871F21
	v_dot4_i32_iu8 v97, v37, v160, 0 neg_lo:[0,1,0]            // 0000000017C4: CC164061 5A034125
	v_dot4_i32_iu8 v96, v27, v161, v96 neg_lo:[0,1,0]          // 0000000017CC: CC164060 5D83431B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000017D4: BF870112
	v_dot4_i32_iu8 v97, v35, v161, v97 neg_lo:[0,1,0]          // 0000000017D8: CC164061 5D874323
	v_dot4_i32_iu8 v96, v26, v162, v96 neg_lo:[0,1,0]          // 0000000017E0: CC164060 5D83451A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000017E8: BF870112
	v_dot4_i32_iu8 v97, v34, v162, v97 neg_lo:[0,1,0]          // 0000000017EC: CC164061 5D874522
	v_dot4_i32_iu8 v110, v25, v163, v96 neg_lo:[0,1,0]         // 0000000017F4: CC16406E 5D834719
	v_dot4_i32_iu8 v96, v28, v156, 0 neg_lo:[0,1,0]            // 0000000017FC: CC164060 5A03391C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001804: BF8701A3
	v_dot4_i32_iu8 v107, v33, v163, v97 neg_lo:[0,1,0]         // 000000001808: CC16406B 5D874721
	v_dot4_i32_iu8 v97, v37, v156, 0 neg_lo:[0,1,0]            // 000000001810: CC164061 5A033925
	v_dot4_i32_iu8 v96, v27, v157, v96 neg_lo:[0,1,0]          // 000000001818: CC164060 5D833B1B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001820: BF870112
	v_dot4_i32_iu8 v97, v35, v157, v97 neg_lo:[0,1,0]          // 000000001824: CC164061 5D873B23
	v_dot4_i32_iu8 v96, v26, v158, v96 neg_lo:[0,1,0]          // 00000000182C: CC164060 5D833D1A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001834: BF870112
	v_dot4_i32_iu8 v97, v34, v158, v97 neg_lo:[0,1,0]          // 000000001838: CC164061 5D873D22
	v_dot4_i32_iu8 v108, v25, v159, v96 neg_lo:[0,1,0]         // 000000001840: CC16406C 5D833F19
	v_dot4_i32_iu8 v96, v28, v152, 0 neg_lo:[0,1,0]            // 000000001848: CC164060 5A03311C
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001850: BF8701A3
	v_dot4_i32_iu8 v105, v33, v159, v97 neg_lo:[0,1,0]         // 000000001854: CC164069 5D873F21
	v_dot4_i32_iu8 v97, v37, v152, 0 neg_lo:[0,1,0]            // 00000000185C: CC164061 5A033125
	v_dot4_i32_iu8 v96, v27, v153, v96 neg_lo:[0,1,0]          // 000000001864: CC164060 5D83331B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000186C: BF870112
	v_dot4_i32_iu8 v97, v35, v153, v97 neg_lo:[0,1,0]          // 000000001870: CC164061 5D873323
	v_dot4_i32_iu8 v96, v26, v154, v96 neg_lo:[0,1,0]          // 000000001878: CC164060 5D83351A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001880: BF870112
	v_dot4_i32_iu8 v97, v34, v154, v97 neg_lo:[0,1,0]          // 000000001884: CC164061 5D873522
	v_dot4_i32_iu8 v106, v25, v155, v96 neg_lo:[0,1,0]         // 00000000188C: CC16406A 5D833719
	v_dot4_i32_iu8 v96, v28, v144, 0 neg_lo:[0,1,0]            // 000000001894: CC164060 5A03211C
	v_dot4_i32_iu8 v28, v28, v164, 0 neg_lo:[0,1,0]            // 00000000189C: CC16401C 5A03491C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 0000000018A4: BF870224
	v_dot4_i32_iu8 v99, v33, v155, v97 neg_lo:[0,1,0]          // 0000000018A8: CC164063 5D873721
	v_dot4_i32_iu8 v97, v37, v144, 0 neg_lo:[0,1,0]            // 0000000018B0: CC164061 5A032125
	v_dot4_i32_iu8 v96, v27, v145, v96 neg_lo:[0,1,0]          // 0000000018B8: CC164060 5D83231B
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 0000000018C0: BF870224
	v_dot4_i32_iu8 v27, v27, v165, v28 neg_lo:[0,1,0]          // 0000000018C4: CC16401B 5C734B1B
	v_dot4_i32_iu8 v28, v37, v164, 0 neg_lo:[0,1,0]            // 0000000018CC: CC16401C 5A034925
	v_dot4_i32_iu8 v97, v35, v145, v97 neg_lo:[0,1,0]          // 0000000018D4: CC164061 5D872323
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000018DC: BF870214
	v_dot4_i32_iu8 v96, v26, v146, v96 neg_lo:[0,1,0]          // 0000000018E0: CC164060 5D83251A
	v_dot4_i32_iu8 v26, v26, v166, v27 neg_lo:[0,1,0]          // 0000000018E8: CC16401A 5C6F4D1A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000018F0: BF870214
	v_dot4_i32_iu8 v28, v35, v165, v28 neg_lo:[0,1,0]          // 0000000018F4: CC16401C 5C734B23
	v_dot4_i32_iu8 v97, v34, v146, v97 neg_lo:[0,1,0]          // 0000000018FC: CC164061 5D872522
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001904: BF870214
	v_dot4_i32_iu8 v104, v25, v147, v96 neg_lo:[0,1,0]         // 000000001908: CC164068 5D832719
	v_dot4_i32_iu8 v98, v25, v167, v26 neg_lo:[0,1,0]          // 000000001910: CC164062 5C6B4F19
	v_lshrrev_b32_e32 v25, 4, v47                              // 000000001918: 32325E84
	v_lshrrev_b32_e32 v26, v238, v55                           // 00000000191C: 32346FEE
	v_dot4_i32_iu8 v27, v34, v166, v28 neg_lo:[0,1,0]          // 000000001920: CC16401B 5C734D22
	v_lshrrev_b32_e32 v28, v236, v49                           // 000000001928: 323863EC
	v_dot4_i32_iu8 v97, v33, v147, v97 neg_lo:[0,1,0]          // 00000000192C: CC164061 5D872721
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 000000001934: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v26, 4, v26                              // 00000000193C: 30343484
	v_dot4_i32_iu8 v96, v33, v167, v27 neg_lo:[0,1,0]          // 000000001940: CC164060 5C6F4F21
	v_lshrrev_b32_e32 v27, v238, v51                           // 000000001948: 323667EE
	v_lshlrev_b32_e32 v28, 4, v28                              // 00000000194C: 30383884
	v_lshrrev_b32_e32 v33, v237, v50                           // 000000001950: 324265ED
	v_and_or_b32 v142, 0x10101010, v26, v25                    // 000000001954: D657008E 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v46                              // 000000001960: 32325C84
	v_lshrrev_b32_e32 v26, v237, v54                           // 000000001964: 32346DED
	v_lshlrev_b32_e32 v27, 4, v27                              // 000000001968: 30363684
	v_lshlrev_b32_e32 v33, 4, v33                              // 00000000196C: 30424284
	v_lshrrev_b32_e32 v51, v235, v51                           // 000000001970: 326667EB
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 000000001974: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v26, 4, v26                              // 00000000197C: 30343484
	v_lshrrev_b32_e32 v50, v234, v50                           // 000000001980: 326465EA
	v_lshrrev_b32_e32 v49, v233, v49                           // 000000001984: 326263E9
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 000000001988: BF8701C3
	v_and_or_b32 v143, 0x10101010, v26, v25                    // 00000000198C: D657008F 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v45                              // 000000001998: 32325A84
	v_lshrrev_b32_e32 v26, v236, v53                           // 00000000199C: 32346BEC
	v_lshrrev_b32_e32 v53, v233, v53                           // 0000000019A0: 326A6BE9
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 0000000019A4: 363232FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000019AC: BF870093
	v_lshlrev_b32_e32 v26, 4, v26                              // 0000000019B0: 30343484
	v_and_or_b32 v144, 0x10101010, v26, v25                    // 0000000019B4: D6570090 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v44                              // 0000000019C0: 32325884
	v_lshrrev_b32_e32 v26, v247, v52                           // 0000000019C4: 323469F7
	v_lshrrev_b32_e32 v52, v182, v52                           // 0000000019C8: 326869B6
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000019CC: BF870193
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 0000000019D0: 363232FF 0F0F0F0F
	v_lshlrev_b32_e32 v26, 4, v26                              // 0000000019D8: 30343484
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_4)// 0000000019DC: BF870251
	v_and_or_b32 v145, 0x10101010, v26, v25                    // 0000000019E0: D6570091 046634FF 10101010
	v_lshrrev_b32_e32 v25, 4, v40                              // 0000000019EC: 32325084
	v_lshrrev_b32_e32 v26, v247, v48                           // 0000000019F0: 323461F7
	v_lshrrev_b32_e32 v48, v182, v48                           // 0000000019F4: 326061B6
	v_and_b32_e32 v40, 0xf0f0f0f, v40                          // 0000000019F8: 365050FF 0F0F0F0F
	v_and_b32_e32 v25, 0xf0f0f0f, v25                          // 000000001A00: 363232FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001A08: BF870094
	v_lshlrev_b32_e32 v26, 4, v26                              // 000000001A0C: 30343484
	v_and_or_b32 v25, 0x10101010, v26, v25                     // 000000001A10: D6570019 046634FF 10101010
	v_lshrrev_b32_e32 v26, 4, v43                              // 000000001A1C: 32345684
	v_and_b32_e32 v43, 0xf0f0f0f, v43                          // 000000001A20: 365656FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001A28: BF870193
	v_dot4_i32_iu8 v35, v25, v128, 0 neg_lo:[0,1,0]            // 000000001A2C: CC164023 5A030119
	v_and_b32_e32 v26, 0xf0f0f0f, v26                          // 000000001A34: 363434FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000001A3C: BF870131
	v_and_or_b32 v26, 0x10101010, v27, v26                     // 000000001A40: D657001A 046A36FF 10101010
	v_lshrrev_b32_e32 v27, 4, v41                              // 000000001A4C: 32365284
	v_and_b32_e32 v41, 0xf0f0f0f, v41                          // 000000001A50: 365252FF 0F0F0F0F
	v_and_b32_e32 v27, 0xf0f0f0f, v27                          // 000000001A58: 363636FF 0F0F0F0F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000001A60: BF8701B1
	v_and_or_b32 v28, 0x10101010, v28, v27                     // 000000001A64: D657001C 046E38FF 10101010
	v_lshrrev_b32_e32 v27, 4, v42                              // 000000001A70: 32365484
	v_and_b32_e32 v42, 0xf0f0f0f, v42                          // 000000001A74: 365454FF 0F0F0F0F
	v_dot4_i32_iu8 v35, v28, v129, v35 neg_lo:[0,1,0]          // 000000001A7C: CC164023 5C8F031C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001A84: BF870093
	v_and_b32_e32 v27, 0xf0f0f0f, v27                          // 000000001A88: 363636FF 0F0F0F0F
	v_and_or_b32 v37, 0x10101010, v33, v27                     // 000000001A90: D6570025 046E42FF 10101010
	v_dot4_i32_iu8 v27, v145, v200, 0 neg_lo:[0,1,0]           // 000000001A9C: CC16401B 5A039191
	v_dot4_i32_iu8 v33, v25, v200, 0 neg_lo:[0,1,0]            // 000000001AA4: CC164021 5A039119
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001AAC: BF870112
	v_dot4_i32_iu8 v27, v144, v201, v27 neg_lo:[0,1,0]         // 000000001AB0: CC16401B 5C6F9390
	v_dot4_i32_iu8 v33, v28, v201, v33 neg_lo:[0,1,0]          // 000000001AB8: CC164021 5C87931C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001AC0: BF870112
	v_dot4_i32_iu8 v27, v143, v202, v27 neg_lo:[0,1,0]         // 000000001AC4: CC16401B 5C6F958F
	v_dot4_i32_iu8 v33, v37, v202, v33 neg_lo:[0,1,0]          // 000000001ACC: CC164021 5C879525
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001AD4: BF8701A2
	v_dot4_i32_iu8 v134, v142, v203, v27 neg_lo:[0,1,0]        // 000000001AD8: CC164086 5C6F978E
	v_dot4_i32_iu8 v27, v145, v196, 0 neg_lo:[0,1,0]           // 000000001AE0: CC16401B 5A038991
	v_dot4_i32_iu8 v133, v26, v203, v33 neg_lo:[0,1,0]         // 000000001AE8: CC164085 5C87971A
	v_dot4_i32_iu8 v33, v25, v196, 0 neg_lo:[0,1,0]            // 000000001AF0: CC164021 5A038919
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001AF8: BF870113
	v_dot4_i32_iu8 v27, v144, v197, v27 neg_lo:[0,1,0]         // 000000001AFC: CC16401B 5C6F8B90
	v_dot4_i32_iu8 v33, v28, v197, v33 neg_lo:[0,1,0]          // 000000001B04: CC164021 5C878B1C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001B0C: BF870112
	v_dot4_i32_iu8 v27, v143, v198, v27 neg_lo:[0,1,0]         // 000000001B10: CC16401B 5C6F8D8F
	v_dot4_i32_iu8 v33, v37, v198, v33 neg_lo:[0,1,0]          // 000000001B18: CC164021 5C878D25
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001B20: BF8701A2
	v_dot4_i32_iu8 v137, v142, v199, v27 neg_lo:[0,1,0]        // 000000001B24: CC164089 5C6F8F8E
	v_dot4_i32_iu8 v27, v145, v184, 0 neg_lo:[0,1,0]           // 000000001B2C: CC16401B 5A037191
	v_dot4_i32_iu8 v135, v26, v199, v33 neg_lo:[0,1,0]         // 000000001B34: CC164087 5C878F1A
	v_dot4_i32_iu8 v33, v25, v184, 0 neg_lo:[0,1,0]            // 000000001B3C: CC164021 5A037119
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001B44: BF870113
	v_dot4_i32_iu8 v27, v144, v185, v27 neg_lo:[0,1,0]         // 000000001B48: CC16401B 5C6F7390
	v_dot4_i32_iu8 v33, v28, v185, v33 neg_lo:[0,1,0]          // 000000001B50: CC164021 5C87731C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001B58: BF870112
	v_dot4_i32_iu8 v27, v143, v186, v27 neg_lo:[0,1,0]         // 000000001B5C: CC16401B 5C6F758F
	v_dot4_i32_iu8 v33, v37, v186, v33 neg_lo:[0,1,0]          // 000000001B64: CC164021 5C877525
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001B6C: BF8701A2
	v_dot4_i32_iu8 v139, v142, v187, v27 neg_lo:[0,1,0]        // 000000001B70: CC16408B 5C6F778E
	v_dot4_i32_iu8 v27, v145, v176, 0 neg_lo:[0,1,0]           // 000000001B78: CC16401B 5A036191
	v_dot4_i32_iu8 v138, v26, v187, v33 neg_lo:[0,1,0]         // 000000001B80: CC16408A 5C87771A
	v_dot4_i32_iu8 v33, v25, v176, 0 neg_lo:[0,1,0]            // 000000001B88: CC164021 5A036119
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001B90: BF870113
	v_dot4_i32_iu8 v27, v144, v177, v27 neg_lo:[0,1,0]         // 000000001B94: CC16401B 5C6F6390
	v_dot4_i32_iu8 v33, v28, v177, v33 neg_lo:[0,1,0]          // 000000001B9C: CC164021 5C87631C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001BA4: BF870112
	v_dot4_i32_iu8 v27, v143, v178, v27 neg_lo:[0,1,0]         // 000000001BA8: CC16401B 5C6F658F
	v_dot4_i32_iu8 v33, v37, v178, v33 neg_lo:[0,1,0]          // 000000001BB0: CC164021 5C876525
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001BB8: BF8701A2
	v_dot4_i32_iu8 v141, v142, v179, v27 neg_lo:[0,1,0]        // 000000001BBC: CC16408D 5C6F678E
	v_dot4_i32_iu8 v27, v145, v168, 0 neg_lo:[0,1,0]           // 000000001BC4: CC16401B 5A035191
	v_dot4_i32_iu8 v140, v26, v179, v33 neg_lo:[0,1,0]         // 000000001BCC: CC16408C 5C87671A
	v_dot4_i32_iu8 v33, v25, v168, 0 neg_lo:[0,1,0]            // 000000001BD4: CC164021 5A035119
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001BDC: BF870113
	v_dot4_i32_iu8 v27, v144, v169, v27 neg_lo:[0,1,0]         // 000000001BE0: CC16401B 5C6F5390
	v_dot4_i32_iu8 v33, v28, v169, v33 neg_lo:[0,1,0]          // 000000001BE8: CC164021 5C87531C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001BF0: BF870112
	v_dot4_i32_iu8 v27, v143, v170, v27 neg_lo:[0,1,0]         // 000000001BF4: CC16401B 5C6F558F
	v_dot4_i32_iu8 v33, v37, v170, v33 neg_lo:[0,1,0]          // 000000001BFC: CC164021 5C875525
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 000000001C04: BF870232
	v_dot4_i32_iu8 v34, v142, v171, v27 neg_lo:[0,1,0]         // 000000001C08: CC164022 5C6F578E
	v_dot4_i32_iu8 v27, v145, v128, 0 neg_lo:[0,1,0]           // 000000001C10: CC16401B 5A030191
	v_dot4_i32_iu8 v128, v37, v130, v35 neg_lo:[0,1,0]         // 000000001C18: CC164080 5C8F0525
	v_dot4_i32_iu8 v33, v26, v171, v33 neg_lo:[0,1,0]          // 000000001C20: CC164021 5C87571A
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001C28: BF870113
	v_dot4_i32_iu8 v27, v144, v129, v27 neg_lo:[0,1,0]         // 000000001C2C: CC16401B 5C6F0390
	v_cvt_f32_i32_e32 v33, v33                                 // 000000001C34: 7E420B21
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C38: BF870092
	v_dot4_i32_iu8 v27, v143, v130, v27 neg_lo:[0,1,0]         // 000000001C3C: CC16401B 5C6F058F
	v_dot4_i32_iu8 v35, v142, v131, v27 neg_lo:[0,1,0]         // 000000001C44: CC164023 5C6F078E
	v_dot4_i32_iu8 v27, v26, v131, v128 neg_lo:[0,1,0]         // 000000001C4C: CC16401B 5E03071A
	v_dot4_i32_iu8 v128, v145, v124, 0 neg_lo:[0,1,0]          // 000000001C54: CC164080 5A02F991
	v_dot4_i32_iu8 v124, v25, v124, 0 neg_lo:[0,1,0]           // 000000001C5C: CC16407C 5A02F919
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001C64: BF870193
	v_cvt_f32_i32_e32 v27, v27                                 // 000000001C68: 7E360B1B
	v_dot4_i32_iu8 v128, v144, v125, v128 neg_lo:[0,1,0]       // 000000001C6C: CC164080 5E02FB90
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001C74: BF870113
	v_dot4_i32_iu8 v124, v28, v125, v124 neg_lo:[0,1,0]        // 000000001C78: CC16407C 5DF2FB1C
	v_dot4_i32_iu8 v125, v143, v126, v128 neg_lo:[0,1,0]       // 000000001C80: CC16407D 5E02FD8F
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001C88: BF870112
	v_dot4_i32_iu8 v126, v37, v126, v124 neg_lo:[0,1,0]        // 000000001C8C: CC16407E 5DF2FD25
	v_dot4_i32_iu8 v124, v142, v127, v125 neg_lo:[0,1,0]       // 000000001C94: CC16407C 5DF6FF8E
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000001C9C: BF870132
	v_dot4_i32_iu8 v125, v26, v127, v126 neg_lo:[0,1,0]        // 000000001CA0: CC16407D 5DFAFF1A
	v_dot4_i32_iu8 v126, v145, v120, 0 neg_lo:[0,1,0]          // 000000001CA8: CC16407E 5A02F191
	v_dot4_i32_iu8 v120, v25, v120, 0 neg_lo:[0,1,0]           // 000000001CB0: CC164078 5A02F119
	v_dot4_i32_iu8 v126, v144, v121, v126 neg_lo:[0,1,0]       // 000000001CB8: CC16407E 5DFAF390
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001CC0: BF870112
	v_dot4_i32_iu8 v120, v28, v121, v120 neg_lo:[0,1,0]        // 000000001CC4: CC164078 5DE2F31C
	v_dot4_i32_iu8 v121, v143, v122, v126 neg_lo:[0,1,0]       // 000000001CCC: CC164079 5DFAF58F
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001CD4: BF870002
	v_dot4_i32_iu8 v120, v37, v122, v120 neg_lo:[0,1,0]        // 000000001CD8: CC164078 5DE2F525
	v_dot4_i32_iu8 v122, v145, v116, 0 neg_lo:[0,1,0]          // 000000001CE0: CC16407A 5A02E991
	v_dot4_i32_iu8 v116, v25, v116, 0 neg_lo:[0,1,0]           // 000000001CE8: CC164074 5A02E919
	v_dot4_i32_iu8 v25, v25, v100, 0 neg_lo:[0,1,0]            // 000000001CF0: CC164019 5A02C919
	v_dot4_i32_iu8 v121, v142, v123, v121 neg_lo:[0,1,0]       // 000000001CF8: CC164079 5DE6F78E
	v_dot4_i32_iu8 v120, v26, v123, v120 neg_lo:[0,1,0]        // 000000001D00: CC164078 5DE2F71A
	v_dot4_i32_iu8 v122, v144, v117, v122 neg_lo:[0,1,0]       // 000000001D08: CC16407A 5DEAEB90
	v_dot4_i32_iu8 v116, v28, v117, v116 neg_lo:[0,1,0]        // 000000001D10: CC164074 5DD2EB1C
	v_dot4_i32_iu8 v25, v28, v101, v25 neg_lo:[0,1,0]          // 000000001D18: CC164019 5C66CB1C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001D20: BF870193
	v_dot4_i32_iu8 v117, v143, v118, v122 neg_lo:[0,1,0]       // 000000001D24: CC164075 5DEAED8F
	v_dot4_i32_iu8 v116, v37, v118, v116 neg_lo:[0,1,0]        // 000000001D2C: CC164074 5DD2ED25
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001D34: BF870003
	v_dot4_i32_iu8 v25, v37, v102, v25 neg_lo:[0,1,0]          // 000000001D38: CC164019 5C66CD25
	v_and_b32_e32 v37, 0xf0f0f0f, v45                          // 000000001D40: 364A5AFF 0F0F0F0F
	v_and_b32_e32 v45, 0xf0f0f0f, v47                          // 000000001D48: 365A5EFF 0F0F0F0F
	v_lshrrev_b32_e32 v47, v234, v54                           // 000000001D50: 325E6DEA
	v_dot4_i32_iu8 v116, v26, v119, v116 neg_lo:[0,1,0]        // 000000001D54: CC164074 5DD2EF1A
	v_dot4_i32_iu8 v25, v26, v103, v25 neg_lo:[0,1,0]          // 000000001D5C: CC164019 5C66CF1A
	v_and_b32_e32 v26, 0xf0f0f0f, v44                          // 000000001D64: 363458FF 0F0F0F0F
	v_and_b32_e32 v44, 0xf0f0f0f, v46                          // 000000001D6C: 36585CFF 0F0F0F0F
	v_lshrrev_b32_e32 v46, v235, v55                           // 000000001D74: 325C6FEB
	v_dot4_i32_iu8 v117, v142, v119, v117 neg_lo:[0,1,0]       // 000000001D78: CC164075 5DD6EF8E
	v_dot4_i32_iu8 v118, v145, v100, 0 neg_lo:[0,1,0]          // 000000001D80: CC164076 5A02C991
	v_cvt_f32_i32_e32 v25, v25                                 // 000000001D88: 7E320B19
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001D8C: BF870194
	v_lshlrev_b32_e32 v46, 4, v46                              // 000000001D90: 305C5C84
	v_dot4_i32_iu8 v118, v144, v101, v118 neg_lo:[0,1,0]       // 000000001D94: CC164076 5DDACB90
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001D9C: BF8701A2
	v_and_or_b32 v45, 0x10101010, v46, v45                     // 000000001DA0: D657002D 04B65CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v47                              // 000000001DAC: 305C5E84
	v_dot4_i32_iu8 v28, v143, v102, v118 neg_lo:[0,1,0]        // 000000001DB0: CC16401C 5DDACD8F
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001DB8: BF8701A2
	v_and_or_b32 v44, 0x10101010, v46, v44                     // 000000001DBC: D657002C 04B25CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v53                              // 000000001DC8: 305C6A84
	v_dot4_i32_iu8 v28, v142, v103, v28 neg_lo:[0,1,0]         // 000000001DCC: CC16401C 5C72CF8E
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000001DD4: BF8701A2
	v_and_or_b32 v37, 0x10101010, v46, v37                     // 000000001DD8: D6570025 04965CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v52                              // 000000001DE4: 305C6884
	v_cvt_f32_i32_e32 v28, v28                                 // 000000001DE8: 7E380B1C
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001DEC: BF870122
	v_and_or_b32 v26, 0x10101010, v46, v26                     // 000000001DF0: D657001A 046A5CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v51                              // 000000001DFC: 305C6684
	v_dot4_i32_iu8 v54, v26, v76, 0 neg_lo:[0,1,0]             // 000000001E00: CC164036 5A02991A
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_4) | instid1(VALU_DEP_4)// 000000001E08: BF870252
	v_and_or_b32 v43, 0x10101010, v46, v43                     // 000000001E0C: D657002B 04AE5CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v50                              // 000000001E18: 305C6484
	v_dot4_i32_iu8 v50, v26, v84, 0 neg_lo:[0,1,0]             // 000000001E1C: CC164032 5A02A91A
	v_dot4_i32_iu8 v52, v26, v80, 0 neg_lo:[0,1,0]             // 000000001E24: CC164034 5A02A11A
	v_dot4_i32_iu8 v54, v37, v77, v54 neg_lo:[0,1,0]           // 000000001E2C: CC164036 5CDA9B25
	v_and_or_b32 v42, 0x10101010, v46, v42                     // 000000001E34: D657002A 04AA5CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v49                              // 000000001E40: 305C6284
	v_dot4_i32_iu8 v50, v37, v85, v50 neg_lo:[0,1,0]           // 000000001E44: CC164032 5CCAAB25
	v_dot4_i32_iu8 v52, v37, v81, v52 neg_lo:[0,1,0]           // 000000001E4C: CC164034 5CD2A325
	v_dot4_i32_iu8 v54, v44, v78, v54 neg_lo:[0,1,0]           // 000000001E54: CC164036 5CDA9D2C
	s_delay_alu instid0(VALU_DEP_4)                            // 000000001E5C: BF870004
	v_and_or_b32 v41, 0x10101010, v46, v41                     // 000000001E60: D6570029 04A65CFF 10101010
	v_lshlrev_b32_e32 v46, 4, v48                              // 000000001E6C: 305C6084
	v_dot4_i32_iu8 v48, v26, v88, 0 neg_lo:[0,1,0]             // 000000001E70: CC164030 5A02B11A
	v_dot4_i32_iu8 v50, v44, v86, v50 neg_lo:[0,1,0]           // 000000001E78: CC164032 5CCAAD2C
	v_dot4_i32_iu8 v52, v44, v82, v52 neg_lo:[0,1,0]           // 000000001E80: CC164034 5CD2A52C
	v_dot4_i32_iu8 v54, v45, v79, v54 neg_lo:[0,1,0]           // 000000001E88: CC164036 5CDA9F2D
	v_and_or_b32 v40, 0x10101010, v46, v40                     // 000000001E90: D6570028 04A25CFF 10101010
	v_dot4_i32_iu8 v46, v26, v92, 0 neg_lo:[0,1,0]             // 000000001E9C: CC16402E 5A02B91A
	v_dot4_i32_iu8 v48, v37, v89, v48 neg_lo:[0,1,0]           // 000000001EA4: CC164030 5CC2B325
	v_dot4_i32_iu8 v50, v45, v87, v50 neg_lo:[0,1,0]           // 000000001EAC: CC164032 5CCAAF2D
	v_dot4_i32_iu8 v52, v45, v83, v52 neg_lo:[0,1,0]           // 000000001EB4: CC164034 5CD2A72D
	v_dot4_i32_iu8 v55, v40, v76, 0 neg_lo:[0,1,0]             // 000000001EBC: CC164037 5A029928
	v_dot4_i32_iu8 v76, v26, v72, 0 neg_lo:[0,1,0]             // 000000001EC4: CC16404C 5A02911A
	v_dot4_i32_iu8 v72, v40, v72, 0 neg_lo:[0,1,0]             // 000000001ECC: CC164048 5A029128
	v_dot4_i32_iu8 v46, v37, v93, v46 neg_lo:[0,1,0]           // 000000001ED4: CC16402E 5CBABB25
	v_dot4_i32_iu8 v48, v44, v90, v48 neg_lo:[0,1,0]           // 000000001EDC: CC164030 5CC2B52C
	v_dot4_i32_iu8 v47, v40, v92, 0 neg_lo:[0,1,0]             // 000000001EE4: CC16402F 5A02B928
	v_dot4_i32_iu8 v76, v37, v73, v76 neg_lo:[0,1,0]           // 000000001EEC: CC16404C 5D329325
	v_dot4_i32_iu8 v72, v41, v73, v72 neg_lo:[0,1,0]           // 000000001EF4: CC164048 5D229329
	v_dot4_i32_iu8 v46, v44, v94, v46 neg_lo:[0,1,0]           // 000000001EFC: CC16402E 5CBABD2C
	v_dot4_i32_iu8 v48, v45, v91, v48 neg_lo:[0,1,0]           // 000000001F04: CC164030 5CC2B72D
	v_dot4_i32_iu8 v49, v40, v88, 0 neg_lo:[0,1,0]             // 000000001F0C: CC164031 5A02B128
	v_dot4_i32_iu8 v73, v44, v74, v76 neg_lo:[0,1,0]           // 000000001F14: CC164049 5D32952C
	v_dot4_i32_iu8 v72, v42, v74, v72 neg_lo:[0,1,0]           // 000000001F1C: CC164048 5D22952A
	v_dot4_i32_iu8 v74, v26, v68, 0 neg_lo:[0,1,0]             // 000000001F24: CC16404A 5A02891A
	v_dot4_i32_iu8 v68, v40, v68, 0 neg_lo:[0,1,0]             // 000000001F2C: CC164044 5A028928
	v_dot4_i32_iu8 v46, v45, v95, v46 neg_lo:[0,1,0]           // 000000001F34: CC16402E 5CBABF2D
	v_dot4_i32_iu8 v73, v45, v75, v73 neg_lo:[0,1,0]           // 000000001F3C: CC164049 5D26972D
	v_dot4_i32_iu8 v51, v40, v84, 0 neg_lo:[0,1,0]             // 000000001F44: CC164033 5A02A928
	v_dot4_i32_iu8 v74, v37, v69, v74 neg_lo:[0,1,0]           // 000000001F4C: CC16404A 5D2A8B25
	v_dot4_i32_iu8 v68, v41, v69, v68 neg_lo:[0,1,0]           // 000000001F54: CC164044 5D128B29
	v_dot4_i32_iu8 v53, v40, v80, 0 neg_lo:[0,1,0]             // 000000001F5C: CC164035 5A02A128
	v_dot4_i32_iu8 v47, v41, v93, v47 neg_lo:[0,1,0]           // 000000001F64: CC16402F 5CBEBB29
	v_dot4_i32_iu8 v49, v41, v89, v49 neg_lo:[0,1,0]           // 000000001F6C: CC164031 5CC6B329
	v_dot4_i32_iu8 v69, v44, v70, v74 neg_lo:[0,1,0]           // 000000001F74: CC164045 5D2A8D2C
	v_dot4_i32_iu8 v68, v42, v70, v68 neg_lo:[0,1,0]           // 000000001F7C: CC164044 5D128D2A
	v_dot4_i32_iu8 v70, v26, v64, 0 neg_lo:[0,1,0]             // 000000001F84: CC164046 5A02811A
	v_dot4_i32_iu8 v64, v40, v64, 0 neg_lo:[0,1,0]             // 000000001F8C: CC164040 5A028128
	v_dot4_i32_iu8 v51, v41, v85, v51 neg_lo:[0,1,0]           // 000000001F94: CC164033 5CCEAB29
	v_dot4_i32_iu8 v69, v45, v71, v69 neg_lo:[0,1,0]           // 000000001F9C: CC164045 5D168F2D
	v_dot4_i32_iu8 v53, v41, v81, v53 neg_lo:[0,1,0]           // 000000001FA4: CC164035 5CD6A329
	v_dot4_i32_iu8 v70, v37, v65, v70 neg_lo:[0,1,0]           // 000000001FAC: CC164046 5D1A8325
	v_dot4_i32_iu8 v64, v41, v65, v64 neg_lo:[0,1,0]           // 000000001FB4: CC164040 5D028329
	v_dot4_i32_iu8 v55, v41, v77, v55 neg_lo:[0,1,0]           // 000000001FBC: CC164037 5CDE9B29
	v_dot4_i32_iu8 v47, v42, v94, v47 neg_lo:[0,1,0]           // 000000001FC4: CC16402F 5CBEBD2A
	v_dot4_i32_iu8 v49, v42, v90, v49 neg_lo:[0,1,0]           // 000000001FCC: CC164031 5CC6B52A
	v_dot4_i32_iu8 v65, v44, v66, v70 neg_lo:[0,1,0]           // 000000001FD4: CC164041 5D1A852C
	v_dot4_i32_iu8 v64, v42, v66, v64 neg_lo:[0,1,0]           // 000000001FDC: CC164040 5D02852A
	v_dot4_i32_iu8 v66, v26, v60, 0 neg_lo:[0,1,0]             // 000000001FE4: CC164042 5A02791A
	v_dot4_i32_iu8 v26, v26, v56, 0 neg_lo:[0,1,0]             // 000000001FEC: CC16401A 5A02711A
	v_dot4_i32_iu8 v60, v40, v60, 0 neg_lo:[0,1,0]             // 000000001FF4: CC16403C 5A027928
	v_dot4_i32_iu8 v65, v45, v67, v65 neg_lo:[0,1,0]           // 000000001FFC: CC164041 5D06872D
	v_dot4_i32_iu8 v51, v42, v86, v51 neg_lo:[0,1,0]           // 000000002004: CC164033 5CCEAD2A
	v_dot4_i32_iu8 v66, v37, v61, v66 neg_lo:[0,1,0]           // 00000000200C: CC164042 5D0A7B25
	v_dot4_i32_iu8 v26, v37, v57, v26 neg_lo:[0,1,0]           // 000000002014: CC16401A 5C6A7325
	v_dot4_i32_iu8 v60, v41, v61, v60 neg_lo:[0,1,0]           // 00000000201C: CC16403C 5CF27B29
	v_dot4_i32_iu8 v37, v40, v56, 0 neg_lo:[0,1,0]             // 000000002024: CC164025 5A027128
	v_dot4_i32_iu8 v53, v42, v82, v53 neg_lo:[0,1,0]           // 00000000202C: CC164035 5CD6A52A
	v_dot4_i32_iu8 v61, v44, v62, v66 neg_lo:[0,1,0]           // 000000002034: CC16403D 5D0A7D2C
	v_dot4_i32_iu8 v26, v44, v58, v26 neg_lo:[0,1,0]           // 00000000203C: CC16401A 5C6A752C
	scratch_load_b32 v44, off, off offset:268                  // 000000002044: DC51010C 2C7C0000
	v_dot4_i32_iu8 v37, v41, v57, v37 neg_lo:[0,1,0]           // 00000000204C: CC164025 5C967329
	v_dot4_i32_iu8 v55, v42, v78, v55 neg_lo:[0,1,0]           // 000000002054: CC164037 5CDE9D2A
	v_dot4_i32_iu8 v61, v45, v63, v61 neg_lo:[0,1,0]           // 00000000205C: CC16403D 5CF67F2D
	v_dot4_i32_iu8 v26, v45, v59, v26 neg_lo:[0,1,0]           // 000000002064: CC16401A 5C6A772D
	scratch_load_b32 v45, off, off offset:260                  // 00000000206C: DC510104 2D7C0000
	v_dot4_i32_iu8 v60, v42, v62, v60 neg_lo:[0,1,0]           // 000000002074: CC16403C 5CF27D2A
	scratch_load_b32 v62, off, off offset:252                  // 00000000207C: DC5100FC 3E7C0000
	v_dot4_i32_iu8 v37, v42, v58, v37 neg_lo:[0,1,0]           // 000000002084: CC164025 5C96752A
	v_cvt_f32_f16_e32 v42, v0                                  // 00000000208C: 7E541700
	v_dot4_i32_iu8 v64, v43, v67, v64 neg_lo:[0,1,0]           // 000000002090: CC164040 5D02872B
	v_dot4_i32_iu8 v60, v43, v63, v60 neg_lo:[0,1,0]           // 000000002098: CC16403C 5CF27F2B
	s_clause 0x1                                               // 0000000020A0: BF850001
	scratch_load_b32 v63, off, off offset:240                  // 0000000020A4: DC5100F0 3F7C0000
	scratch_load_b32 v70, off, off offset:244                  // 0000000020AC: DC5100F4 467C0000
	v_dot4_i32_iu8 v37, v43, v59, v37 neg_lo:[0,1,0]           // 0000000020B4: CC164025 5C96772B
	s_clause 0x1                                               // 0000000020BC: BF850001
	scratch_load_b32 v59, off, off offset:200                  // 0000000020C0: DC5100C8 3B7C0000
	scratch_load_b32 v67, off, off offset:216                  // 0000000020C8: DC5100D8 437C0000
	v_dot4_i32_iu8 v68, v43, v71, v68 neg_lo:[0,1,0]           // 0000000020D0: CC164044 5D128F2B
	s_clause 0x2                                               // 0000000020D8: BF850002
	scratch_load_b32 v71, off, off offset:228                  // 0000000020DC: DC5100E4 477C0000
	scratch_load_b32 v74, off, off offset:232                  // 0000000020E4: DC5100E8 4A7C0000
	scratch_load_b32 v77, off, off offset:236                  // 0000000020EC: DC5100EC 4D7C0000
	v_dot4_i32_iu8 v72, v43, v75, v72 neg_lo:[0,1,0]           // 0000000020F4: CC164048 5D22972B
	s_clause 0x1                                               // 0000000020FC: BF850001
	scratch_load_b32 v75, off, off offset:248                  // 000000002100: DC5100F8 4B7C0000
	scratch_load_b32 v76, off, off offset:208                  // 000000002108: DC5100D0 4C7C0000
	v_dot4_i32_iu8 v55, v43, v79, v55 neg_lo:[0,1,0]           // 000000002110: CC164037 5CDE9F2B
	s_clause 0x1                                               // 000000002118: BF850001
	scratch_load_b32 v79, off, off offset:212                  // 00000000211C: DC5100D4 4F7C0000
	scratch_load_b32 v78, off, off offset:204                  // 000000002124: DC5100CC 4E7C0000
	v_dot4_i32_iu8 v47, v43, v95, v47 neg_lo:[0,1,0]           // 00000000212C: CC16402F 5CBEBF2B
	v_dot4_i32_iu8 v49, v43, v91, v49 neg_lo:[0,1,0]           // 000000002134: CC164031 5CC6B72B
	v_dot4_i32_iu8 v51, v43, v87, v51 neg_lo:[0,1,0]           // 00000000213C: CC164033 5CCEAF2B
	v_dot4_i32_iu8 v53, v43, v83, v53 neg_lo:[0,1,0]           // 000000002144: CC164035 5CD6A72B
	v_cvt_f32_f16_e32 v43, v4                                  // 00000000214C: 7E561704
	v_cvt_f32_i32_e32 v57, v172                                // 000000002150: 7E720BAC
	v_cvt_f32_f16_e32 v40, v32                                 // 000000002154: 7E501720
	v_cvt_f32_f16_e32 v41, v36                                 // 000000002158: 7E521724
	v_lshrrev_b32_e32 v0, 16, v0                               // 00000000215C: 32000090
	v_cvt_f32_i32_e32 v46, v46                                 // 000000002160: 7E5C0B2E
	v_lshrrev_b32_e32 v4, 16, v4                               // 000000002164: 32080890
	v_cvt_f32_i32_e32 v47, v47                                 // 000000002168: 7E5E0B2F
	v_lshrrev_b32_e32 v32, 16, v32                             // 00000000216C: 32404090
	v_cvt_f32_f16_e32 v0, v0                                   // 000000002170: 7E001700
	v_cvt_f32_i32_e32 v26, v26                                 // 000000002174: 7E340B1A
	v_cvt_f32_f16_e32 v4, v4                                   // 000000002178: 7E081704
	v_lshrrev_b32_e32 v36, 16, v36                             // 00000000217C: 32484890
	s_waitcnt vmcnt(13)                                        // 000000002180: BF8937F7
	v_cvt_f32_u32_e32 v44, v44                                 // 000000002184: 7E580D2C
	s_waitcnt vmcnt(12)                                        // 000000002188: BF8933F7
	v_cvt_f32_u32_e32 v45, v45                                 // 00000000218C: 7E5A0D2D
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002190: BF870112
	v_mul_f32_e32 v44, v42, v44                                // 000000002194: 1058592A
	v_mul_f32_e32 v42, v42, v45                                // 000000002198: 10545B2A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000219C: BF870091
	v_dual_mul_f32 v45, v242, v44 :: v_dual_mul_f32 v56, v241, v42// 0000000021A0: C8C659F2 2D3855F1
	v_mul_f32_e32 v39, v45, v39                                // 0000000021A8: 104E4F2D
	v_cvt_f32_i32_e32 v45, v173                                // 0000000021AC: 7E5A0BAD
	s_waitcnt vmcnt(11)                                        // 0000000021B0: BF892FF7
	v_mul_f32_e32 v58, v62, v42                                // 0000000021B4: 1074553E
	s_waitcnt vmcnt(7)                                         // 0000000021B8: BF891FF7
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000021BC: BF870002
	v_dual_mul_f32 v66, v67, v42 :: v_dual_fmac_f32 v39, v56, v45// 0000000021C0: C8C05543 42265B38
	s_clause 0x1                                               // 0000000021C8: BF850001
	scratch_load_b32 v45, off, off offset:356                  // 0000000021CC: DC510164 2D7C0000
	scratch_load_b32 v56, off, off offset:328                  // 0000000021D4: DC510148 387C0000
	s_waitcnt vmcnt(1)                                         // 0000000021DC: BF8907F7
	v_cvt_f32_u32_e32 v45, v45                                 // 0000000021E0: 7E5A0D2D
	s_waitcnt vmcnt(0)                                         // 0000000021E4: BF8903F7
	v_cvt_f32_u32_e32 v56, v56                                 // 0000000021E8: 7E700D38
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000021EC: BF870092
	v_mul_f32_e32 v45, v43, v45                                // 0000000021F0: 105A5B2B
	v_dual_mul_f32 v43, v43, v56 :: v_dual_mul_f32 v56, v242, v45// 0000000021F4: C8C6712B 2B385BF2
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000021FC: BF870111
	v_mul_f32_e32 v38, v56, v38                                // 000000002200: 104C4D38
	v_mul_f32_e32 v56, v241, v43                               // 000000002204: 107057F1
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002208: BF8700B1
	v_fmac_f32_e32 v38, v56, v57                               // 00000000220C: 564C7338
	v_cvt_f32_i32_e32 v56, v225                                // 000000002210: 7E700BE1
	v_mul_f32_e32 v57, v59, v44                                // 000000002214: 1072593B
	v_mul_f32_e32 v56, v57, v56                                // 000000002218: 10707139
	v_cvt_f32_i32_e32 v57, v136                                // 00000000221C: 7E720B88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000002220: BF870141
	v_fmac_f32_e32 v56, v58, v57                               // 000000002224: 5670733A
	v_mul_f32_e32 v57, v59, v45                                // 000000002228: 10725B3B
	v_cvt_f32_i32_e32 v58, v224                                // 00000000222C: 7E740BE0
	v_cvt_f32_i32_e32 v59, v115                                // 000000002230: 7E760B73
	v_dual_mul_f32 v57, v57, v58 :: v_dual_mul_f32 v58, v62, v43// 000000002234: C8C67539 393A573E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000223C: BF8700B1
	v_dual_mul_f32 v62, v63, v42 :: v_dual_fmac_f32 v57, v58, v59// 000000002240: C8C0553F 3E38773A
	v_cvt_f32_i32_e32 v58, v221                                // 000000002248: 7E740BDD
	v_mul_f32_e32 v59, v240, v44                               // 00000000224C: 107659F0
	v_mul_f32_e32 v58, v59, v58                                // 000000002250: 1074753B
	v_cvt_f32_i32_e32 v59, v132                                // 000000002254: 7E760B84
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002258: BF8700A1
	v_dual_fmac_f32 v58, v62, v59 :: v_dual_mul_f32 v59, v240, v45// 00000000225C: C806773E 3A3A5BF0
	v_cvt_f32_i32_e32 v62, v220                                // 000000002264: 7E7C0BDC
	v_mul_f32_e32 v59, v59, v62                                // 000000002268: 10767D3B
	v_mul_f32_e32 v62, v63, v43                                // 00000000226C: 107C573F
	v_cvt_f32_i32_e32 v63, v113                                // 000000002270: 7E7E0B71
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000002274: BF870141
	v_fmac_f32_e32 v59, v62, v63                               // 000000002278: 56767F3E
	v_cvt_f32_i32_e32 v62, v217                                // 00000000227C: 7E7C0BD9
	v_mul_f32_e32 v63, v30, v44                                // 000000002280: 107E591E
	v_mul_f32_e32 v30, v30, v45                                // 000000002284: 103C5B1E
	v_mul_f32_e32 v62, v63, v62                                // 000000002288: 107C7D3F
	v_cvt_f32_i32_e32 v63, v114                                // 00000000228C: 7E7E0B72
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000002290: BF870131
	v_fmac_f32_e32 v62, v66, v63                               // 000000002294: 567C7F42
	v_cvt_f32_i32_e32 v63, v216                                // 000000002298: 7E7E0BD8
	v_cvt_f32_i32_e32 v66, v111                                // 00000000229C: 7E840B6F
	v_mul_f32_e32 v30, v30, v63                                // 0000000022A0: 103C7F1E
	v_mul_f32_e32 v63, v67, v43                                // 0000000022A4: 107E5743
	v_mul_f32_e32 v67, v31, v42                                // 0000000022A8: 1086551F
	v_mul_f32_e32 v31, v31, v43                                // 0000000022AC: 103E571F
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000022B0: BF8700B3
	v_fmac_f32_e32 v30, v63, v66                               // 0000000022B4: 563C853F
	v_cvt_f32_i32_e32 v63, v213                                // 0000000022B8: 7E7E0BD5
	v_mul_f32_e32 v66, v70, v44                                // 0000000022BC: 10845946
	v_mul_f32_e32 v63, v66, v63                                // 0000000022C0: 107E7F42
	v_cvt_f32_i32_e32 v66, v112                                // 0000000022C4: 7E840B70
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 0000000022C8: BF8701C1
	v_dual_fmac_f32 v63, v67, v66 :: v_dual_mul_f32 v66, v70, v45// 0000000022CC: C8068543 3F425B46
	v_cvt_f32_i32_e32 v67, v212                                // 0000000022D4: 7E860BD4
	v_mul_f32_e32 v70, v29, v42                                // 0000000022D8: 108C551D
	v_mul_f32_e32 v29, v29, v43                                // 0000000022DC: 103A571D
	v_mul_f32_e32 v66, v66, v67                                // 0000000022E0: 10848742
	v_cvt_f32_i32_e32 v67, v109                                // 0000000022E4: 7E860B6D
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000022E8: BF8700B1
	v_fmac_f32_e32 v66, v31, v67                               // 0000000022EC: 5684871F
	v_cvt_f32_i32_e32 v31, v209                                // 0000000022F0: 7E3E0BD1
	v_mul_f32_e32 v67, v71, v44                                // 0000000022F4: 10865947
	v_mul_f32_e32 v31, v67, v31                                // 0000000022F8: 103E3F43
	v_cvt_f32_i32_e32 v67, v110                                // 0000000022FC: 7E860B6E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000002300: BF870141
	v_fmac_f32_e32 v31, v70, v67                               // 000000002304: 563E8746
	v_mul_f32_e32 v67, v71, v45                                // 000000002308: 10865B47
	v_cvt_f32_i32_e32 v70, v208                                // 00000000230C: 7E8C0BD0
	v_mul_f32_e32 v71, v74, v42                                // 000000002310: 108E554A
	v_mul_f32_e32 v67, v67, v70                                // 000000002314: 10868D43
	v_cvt_f32_i32_e32 v70, v107                                // 000000002318: 7E8C0B6B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000231C: BF8700B1
	v_fmac_f32_e32 v67, v29, v70                               // 000000002320: 56868D1D
	v_cvt_f32_i32_e32 v29, v205                                // 000000002324: 7E3A0BCD
	v_mul_f32_e32 v70, v75, v44                                // 000000002328: 108C594B
	v_mul_f32_e32 v29, v70, v29                                // 00000000232C: 103A3B46
	v_cvt_f32_i32_e32 v70, v108                                // 000000002330: 7E8C0B6C
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002334: BF8700B1
	v_fmac_f32_e32 v29, v71, v70                               // 000000002338: 563A8D47
	v_mul_f32_e32 v70, v75, v45                                // 00000000233C: 108C5B4B
	v_cvt_f32_i32_e32 v71, v204                                // 000000002340: 7E8E0BCC
	v_dual_mul_f32 v75, v76, v42 :: v_dual_mul_f32 v70, v70, v71// 000000002344: C8C6554C 4B468F46
	v_mul_f32_e32 v71, v74, v43                                // 00000000234C: 108E574A
	v_cvt_f32_i32_e32 v74, v105                                // 000000002350: 7E940B69
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002354: BF8700B1
	v_fmac_f32_e32 v70, v71, v74                               // 000000002358: 568C9547
	v_cvt_f32_i32_e32 v71, v192                                // 00000000235C: 7E8E0BC0
	v_mul_f32_e32 v74, v77, v44                                // 000000002360: 1094594D
	v_mul_f32_e32 v71, v74, v71                                // 000000002364: 108E8F4A
	v_cvt_f32_i32_e32 v74, v106                                // 000000002368: 7E940B6A
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 00000000236C: BF870131
	v_dual_fmac_f32 v71, v75, v74 :: v_dual_mul_f32 v74, v77, v45// 000000002370: C806954B 474A5B4D
	v_cvt_f32_i32_e32 v75, v193                                // 000000002378: 7E960BC1
	v_mul_f32_e32 v77, v78, v42                                // 00000000237C: 109A554E
	v_mul_f32_e32 v74, v74, v75                                // 000000002380: 1094974A
	v_mul_f32_e32 v75, v76, v43                                // 000000002384: 1096574C
	v_cvt_f32_i32_e32 v76, v99                                 // 000000002388: 7E980B63
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000238C: BF8700B1
	v_fmac_f32_e32 v74, v75, v76                               // 000000002390: 5694994B
	v_cvt_f32_i32_e32 v75, v189                                // 000000002394: 7E960BBD
	v_mul_f32_e32 v76, v79, v44                                // 000000002398: 1098594F
	v_mul_f32_e32 v75, v76, v75                                // 00000000239C: 1096974C
	v_cvt_f32_i32_e32 v76, v104                                // 0000000023A0: 7E980B68
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_1)// 0000000023A4: BF8700D1
	v_dual_fmac_f32 v75, v77, v76 :: v_dual_mul_f32 v76, v79, v45// 0000000023A8: C806994D 4B4C5B4F
	v_cvt_f32_i32_e32 v77, v188                                // 0000000023B0: 7E9A0BBC
	scratch_load_b32 v79, off, off offset:224                  // 0000000023B4: DC5100E0 4F7C0000
	v_dual_mul_f32 v76, v76, v77 :: v_dual_mul_f32 v77, v78, v43// 0000000023BC: C8C69B4C 4C4C574E
	v_cvt_f32_i32_e32 v78, v97                                 // 0000000023C4: 7E9C0B61
	v_fmac_f32_e32 v76, v77, v78                               // 0000000023C8: 56989D4D
	scratch_load_b32 v78, off, off offset:220                  // 0000000023CC: DC5100DC 4E7C0000
	v_cvt_f32_i32_e32 v77, v181                                // 0000000023D4: 7E9A0BB5
	s_waitcnt vmcnt(1)                                         // 0000000023D8: BF8907F7
	v_mul_f32_e32 v44, v79, v44                                // 0000000023DC: 1058594F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_2)// 0000000023E0: BF870151
	v_mul_f32_e32 v44, v44, v77                                // 0000000023E4: 10589B2C
	v_cvt_f32_i32_e32 v77, v98                                 // 0000000023E8: 7E9A0B62
	s_waitcnt vmcnt(0)                                         // 0000000023EC: BF8903F7
	v_mul_f32_e32 v42, v78, v42                                // 0000000023F0: 1054554E
	v_mul_f32_e32 v43, v78, v43                                // 0000000023F4: 1056574E
	v_fmac_f32_e32 v44, v42, v77                               // 0000000023F8: 56589B2A
	v_mul_f32_e32 v42, v79, v45                                // 0000000023FC: 10545B4F
	v_cvt_f32_i32_e32 v45, v180                                // 000000002400: 7E5A0BB4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002404: BF8700A1
	v_mul_f32_e32 v42, v42, v45                                // 000000002408: 10545B2A
	v_cvt_f32_i32_e32 v45, v96                                 // 00000000240C: 7E5A0B60
	v_fmac_f32_e32 v42, v43, v45                               // 000000002410: 56545B2B
	s_clause 0x1                                               // 000000002414: BF850001
	scratch_load_b32 v43, off, off offset:372                  // 000000002418: DC510174 2B7C0000
	scratch_load_b32 v45, off, off offset:368                  // 000000002420: DC510170 2D7C0000
	s_waitcnt vmcnt(1)                                         // 000000002428: BF8907F7
	v_cvt_f32_u32_e32 v43, v43                                 // 00000000242C: 7E560D2B
	s_waitcnt vmcnt(0)                                         // 000000002430: BF8903F7
	v_cvt_f32_u32_e32 v45, v45                                 // 000000002434: 7E5A0D2D
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002438: BF870112
	v_mul_f32_e32 v43, v40, v43                                // 00000000243C: 10565728
	v_mul_f32_e32 v40, v40, v45                                // 000000002440: 10505B28
	v_cvt_f32_i32_e32 v45, v134                                // 000000002444: 7E5A0B86
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002448: BF870093
	v_mul_f32_e32 v77, v24, v43                                // 00000000244C: 109A5718
	v_mul_f32_e32 v45, v77, v45                                // 000000002450: 105A5B4D
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002454: BF870094
	v_mul_f32_e32 v77, v23, v40                                // 000000002458: 109A5117
	v_fmac_f32_e32 v45, v77, v46                               // 00000000245C: 565A5D4D
	s_clause 0x1                                               // 000000002460: BF850001
	scratch_load_b32 v46, off, off offset:380                  // 000000002464: DC51017C 2E7C0000
	scratch_load_b32 v77, off, off offset:376                  // 00000000246C: DC510178 4D7C0000
	s_waitcnt vmcnt(1)                                         // 000000002474: BF8907F7
	v_cvt_f32_u32_e32 v46, v46                                 // 000000002478: 7E5C0D2E
	s_waitcnt vmcnt(0)                                         // 00000000247C: BF8903F7
	v_cvt_f32_u32_e32 v77, v77                                 // 000000002480: 7E9A0D4D
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002484: BF870112
	v_mul_f32_e32 v46, v41, v46                                // 000000002488: 105C5D29
	v_mul_f32_e32 v41, v41, v77                                // 00000000248C: 10529B29
	v_cvt_f32_i32_e32 v77, v133                                // 000000002490: 7E9A0B85
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002494: BF870092
	v_dual_mul_f32 v24, v24, v46 :: v_dual_mul_f32 v23, v23, v41// 000000002498: C8C65D18 18165317
	v_mul_f32_e32 v24, v24, v77                                // 0000000024A0: 10309B18
	scratch_load_b64 v[77:78], off, off offset:192             // 0000000024A4: DC5500C0 4D7C0000
	v_fmac_f32_e32 v24, v23, v47                               // 0000000024AC: 56305F17
	s_clause 0x1                                               // 0000000024B0: BF850001
	scratch_load_b32 v23, off, off offset:256                  // 0000000024B4: DC510100 177C0000
	scratch_load_b32 v47, off, off offset:264                  // 0000000024BC: DC510108 2F7C0000
	s_waitcnt vmcnt(1)                                         // 0000000024C4: BF8907F7
	v_cvt_f32_u32_e32 v23, v23                                 // 0000000024C8: 7E2E0D17
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_4) | instid1(VALU_DEP_2)// 0000000024CC: BF870151
	v_dual_mul_f32 v0, v0, v23 :: v_dual_add_f32 v23, v77, v78 // 0000000024D0: C8C82F00 00169D4D
	scratch_load_b64 v[77:78], off, off offset:128             // 0000000024D8: DC550080 4D7C0000
	s_waitcnt vmcnt(1)                                         // 0000000024E0: BF8907F7
	v_cvt_f32_u32_e32 v47, v47                                 // 0000000024E4: 7E5E0D2F
	v_fma_f32 v39, -v23, v0, v39                               // 0000000024E8: D6130027 249E0117
	v_mul_f32_e32 v4, v4, v47                                  // 0000000024F0: 10085F04
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000024F4: BF870001
	v_fma_f32 v23, -v23, v4, v38                               // 0000000024F8: D6130017 249A0917
	s_waitcnt vmcnt(0)                                         // 000000002500: BF8903F7
	v_add_f32_e32 v47, v77, v78                                // 000000002504: 065E9D4D
	scratch_load_b64 v[77:78], off, off offset:120             // 000000002508: DC550078 4D7C0000
	v_fma_f32 v56, -v47, v0, v56                               // 000000002510: D6130038 24E2012F
	v_fma_f32 v47, -v47, v4, v57                               // 000000002518: D613002F 24E6092F
	s_delay_alu instid0(VALU_DEP_2)                            // 000000002520: BF870002
	v_add_f32_e32 v10, v10, v56                                // 000000002524: 0614710A
	s_waitcnt vmcnt(0)                                         // 000000002528: BF8903F7
	v_add_f32_e32 v38, v77, v78                                // 00000000252C: 064C9D4D
	s_clause 0x1                                               // 000000002530: BF850001
	scratch_load_b32 v57, off, off offset:152                  // 000000002534: DC510098 397C0000
	scratch_load_b32 v77, off, off offset:184                  // 00000000253C: DC5100B8 4D7C0000
	v_fma_f32 v58, -v38, v0, v58                               // 000000002544: D613003A 24EA0126
	v_fma_f32 v38, -v38, v4, v59                               // 00000000254C: D6130026 24EE0926
	s_waitcnt vmcnt(0)                                         // 000000002554: BF8903F7
	s_delay_alu instid0(VALU_DEP_2)                            // 000000002558: BF870002
	v_dual_add_f32 v8, v8, v58 :: v_dual_add_f32 v57, v57, v77 // 00000000255C: C9087508 08389B39
	s_clause 0x1                                               // 000000002564: BF850001
	scratch_load_b32 v77, off, off offset:156                  // 000000002568: DC51009C 4D7C0000
	scratch_load_b32 v78, off, off offset:188                  // 000000002570: DC5100BC 4E7C0000
	v_fma_f32 v62, -v57, v0, v62                               // 000000002578: D613003E 24FA0139
	v_fma_f32 v30, -v57, v4, v30                               // 000000002580: D613001E 247A0939
	s_waitcnt vmcnt(0)                                         // 000000002588: BF8903F7
	v_add_f32_e32 v77, v77, v78                                // 00000000258C: 069A9D4D
	s_clause 0x1                                               // 000000002590: BF850001
	scratch_load_b32 v59, off, off offset:148                  // 000000002594: DC510094 3B7C0000
	scratch_load_b32 v78, off, off offset:180                  // 00000000259C: DC5100B4 4E7C0000
	v_fma_f32 v57, -v77, v0, v63                               // 0000000025A4: D6130039 24FE014D
	v_fma_f32 v63, -v77, v4, v66                               // 0000000025AC: D613003F 250A094D
	s_clause 0x1                                               // 0000000025B4: BF850001
	scratch_load_b32 v66, off, off offset:144                  // 0000000025B8: DC510090 427C0000
	scratch_load_b32 v77, off, off offset:176                  // 0000000025C0: DC5100B0 4D7C0000
	s_waitcnt vmcnt(2)                                         // 0000000025C8: BF890BF7
	v_add_f32_e32 v59, v59, v78                                // 0000000025CC: 06769D3B
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000025D0: BF870001
	v_fma_f32 v31, -v59, v0, v31                               // 0000000025D4: D613001F 247E013B
	s_waitcnt vmcnt(0)                                         // 0000000025DC: BF8903F7
	v_add_f32_e32 v66, v66, v77                                // 0000000025E0: 06849B42
	v_fma_f32 v59, -v59, v4, v67                               // 0000000025E4: D613003B 250E093B
	s_clause 0x1                                               // 0000000025EC: BF850001
	scratch_load_b32 v67, off, off offset:136                  // 0000000025F0: DC510088 437C0000
	scratch_load_b32 v77, off, off offset:168                  // 0000000025F8: DC5100A8 4D7C0000
	v_fma_f32 v29, -v66, v0, v29                               // 000000002600: D613001D 24760142
	v_fma_f32 v66, -v66, v4, v70                               // 000000002608: D6130042 251A0942
	s_waitcnt vmcnt(0)                                         // 000000002610: BF8903F7
	v_add_f32_e32 v67, v67, v77                                // 000000002614: 06869B43
	s_clause 0x1                                               // 000000002618: BF850001
	scratch_load_b32 v77, off, off offset:140                  // 00000000261C: DC51008C 4D7C0000
	scratch_load_b32 v78, off, off offset:172                  // 000000002624: DC5100AC 4E7C0000
	v_fma_f32 v71, -v67, v0, v71                               // 00000000262C: D6130047 251E0143
	v_fma_f32 v67, -v67, v4, v74                               // 000000002634: D6130043 252A0943
	s_waitcnt vmcnt(0)                                         // 00000000263C: BF8903F7
	v_add_f32_e32 v77, v77, v78                                // 000000002640: 069A9D4D
	s_clause 0x1                                               // 000000002644: BF850001
	scratch_load_b32 v70, off, off offset:160                  // 000000002648: DC5100A0 467C0000
	scratch_load_b32 v78, off, off offset:164                  // 000000002650: DC5100A4 4E7C0000
	v_fma_f32 v74, -v77, v0, v75                               // 000000002658: D613004A 252E014D
	v_fma_f32 v75, -v77, v4, v76                               // 000000002660: D613004B 2532094D
	s_waitcnt vmcnt(0)                                         // 000000002668: BF8903F7
	v_add_f32_e32 v70, v70, v78                                // 00000000266C: 068C9D46
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002670: BF870001
	v_fma_f32 v0, -v70, v0, v44                                // 000000002674: D6130000 24B20146
	v_fma_f32 v4, -v70, v4, v42                                // 00000000267C: D6130004 24AA0946
	v_cvt_f32_i32_e32 v42, v137                                // 000000002684: 7E540B89
	v_mul_f32_e32 v44, v22, v43                                // 000000002688: 10585716
	v_mul_f32_e32 v22, v22, v46                                // 00000000268C: 102C5D16
	v_add_f32_e32 v0, v250, v0                                 // 000000002690: 060001FA
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002694: BF8700B3
	v_mul_f32_e32 v42, v44, v42                                // 000000002698: 1054552C
	v_cvt_f32_i32_e32 v44, v48                                 // 00000000269C: 7E580B30
	v_mul_f32_e32 v48, v21, v40                                // 0000000026A0: 10605115
	v_dual_mul_f32 v21, v21, v41 :: v_dual_fmac_f32 v42, v48, v44// 0000000026A4: C8C05315 152A5930
	v_cvt_f32_i32_e32 v44, v135                                // 0000000026AC: 7E580B87
	v_mul_f32_e32 v48, v3, v40                                 // 0000000026B0: 10605103
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000026B4: BF8700A2
	v_dual_mul_f32 v3, v3, v41 :: v_dual_mul_f32 v22, v22, v44 // 0000000026B8: C8C65303 03165916
	v_cvt_f32_i32_e32 v44, v49                                 // 0000000026C0: 7E580B31
	v_fmac_f32_e32 v22, v21, v44                               // 0000000026C4: 562C5915
	v_cvt_f32_i32_e32 v21, v139                                // 0000000026C8: 7E2A0B8B
	v_mul_f32_e32 v44, v20, v43                                // 0000000026CC: 10585714
	v_mul_f32_e32 v20, v20, v46                                // 0000000026D0: 10285D14
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000026D4: BF8700A2
	v_mul_f32_e32 v21, v44, v21                                // 0000000026D8: 102A2B2C
	v_cvt_f32_i32_e32 v44, v50                                 // 0000000026DC: 7E580B32
	v_fmac_f32_e32 v21, v48, v44                               // 0000000026E0: 562A5930
	v_cvt_f32_i32_e32 v44, v138                                // 0000000026E4: 7E580B8A
	v_mul_f32_e32 v48, v7, v40                                 // 0000000026E8: 10605107
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000026EC: BF8700A2
	v_dual_mul_f32 v7, v7, v41 :: v_dual_mul_f32 v20, v20, v44 // 0000000026F0: C8C65307 07145914
	v_cvt_f32_i32_e32 v44, v51                                 // 0000000026F8: 7E580B33
	v_fmac_f32_e32 v20, v3, v44                                // 0000000026FC: 56285903
	v_cvt_f32_i32_e32 v3, v141                                 // 000000002700: 7E060B8D
	v_mul_f32_e32 v44, v19, v43                                // 000000002704: 10585713
	v_mul_f32_e32 v19, v19, v46                                // 000000002708: 10265D13
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000270C: BF8700A2
	v_mul_f32_e32 v3, v44, v3                                  // 000000002710: 1006072C
	v_cvt_f32_i32_e32 v44, v52                                 // 000000002714: 7E580B34
	v_fmac_f32_e32 v3, v48, v44                                // 000000002718: 56065930
	v_cvt_f32_i32_e32 v44, v140                                // 00000000271C: 7E580B8C
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002720: BF8700A1
	v_mul_f32_e32 v19, v19, v44                                // 000000002724: 10265913
	v_cvt_f32_i32_e32 v44, v53                                 // 000000002728: 7E580B35
	v_fmac_f32_e32 v19, v7, v44                                // 00000000272C: 56265907
	v_cvt_f32_i32_e32 v7, v34                                  // 000000002730: 7E0E0B22
	v_mul_f32_e32 v34, v246, v43                               // 000000002734: 104457F6
	v_mul_f32_e32 v44, v17, v40                                // 000000002738: 10585111
	v_mul_f32_e32 v17, v17, v41                                // 00000000273C: 10225311
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002740: BF8700A3
	v_mul_f32_e32 v7, v34, v7                                  // 000000002744: 100E0F22
	v_cvt_f32_i32_e32 v34, v54                                 // 000000002748: 7E440B36
	v_fmac_f32_e32 v7, v44, v34                                // 00000000274C: 560E452C
	v_mul_f32_e32 v34, v246, v46                               // 000000002750: 10445DF6
	v_mul_f32_e32 v44, v5, v40                                 // 000000002754: 10585105
	v_mul_f32_e32 v5, v5, v41                                  // 000000002758: 100A5305
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000275C: BF8700A3
	v_mul_f32_e32 v33, v34, v33                                // 000000002760: 10424322
	v_cvt_f32_i32_e32 v34, v55                                 // 000000002764: 7E440B37
	v_fmac_f32_e32 v33, v17, v34                               // 000000002768: 56424511
	v_cvt_f32_i32_e32 v17, v35                                 // 00000000276C: 7E220B23
	v_dual_mul_f32 v34, v18, v43 :: v_dual_mul_f32 v35, v15, v40// 000000002770: C8C65712 2222510F
	v_dual_mul_f32 v18, v18, v46 :: v_dual_mul_f32 v15, v15, v41// 000000002778: C8C65D12 120E530F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000002780: BF870221
	v_mul_f32_e32 v18, v18, v27                                // 000000002784: 10243712
	v_cvt_f32_i32_e32 v27, v72                                 // 000000002788: 7E360B48
	v_mul_f32_e32 v17, v34, v17                                // 00000000278C: 10222322
	v_cvt_f32_i32_e32 v34, v73                                 // 000000002790: 7E440B49
	s_delay_alu instid0(VALU_DEP_3)                            // 000000002794: BF870003
	v_fmac_f32_e32 v18, v15, v27                               // 000000002798: 5624370F
	v_cvt_f32_i32_e32 v15, v124                                // 00000000279C: 7E1E0B7C
	v_mul_f32_e32 v27, v16, v43                                // 0000000027A0: 10365710
	v_mul_f32_e32 v16, v16, v46                                // 0000000027A4: 10205D10
	v_fmac_f32_e32 v17, v35, v34                               // 0000000027A8: 56224523
	v_mul_f32_e32 v34, v243, v40                               // 0000000027AC: 104451F3
	v_mul_f32_e32 v35, v1, v40                                 // 0000000027B0: 10465101
	v_mul_f32_e32 v15, v27, v15                                // 0000000027B4: 101E1F1B
	v_cvt_f32_i32_e32 v27, v69                                 // 0000000027B8: 7E360B45
	v_mul_f32_e32 v1, v1, v41                                  // 0000000027BC: 10025301
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 0000000027C0: BF870132
	v_fmac_f32_e32 v15, v34, v27                               // 0000000027C4: 561E3722
	v_cvt_f32_i32_e32 v27, v125                                // 0000000027C8: 7E360B7D
	v_cvt_f32_i32_e32 v34, v68                                 // 0000000027CC: 7E440B44
	v_dual_mul_f32 v16, v16, v27 :: v_dual_mul_f32 v27, v243, v41// 0000000027D0: C8C63710 101A53F3
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000027D8: BF8700B1
	v_fmac_f32_e32 v16, v27, v34                               // 0000000027DC: 5620451B
	v_mul_f32_e32 v34, v245, v43                               // 0000000027E0: 104457F5
	v_cvt_f32_i32_e32 v27, v121                                // 0000000027E4: 7E360B79
	v_mul_f32_e32 v27, v34, v27                                // 0000000027E8: 10363722
	v_cvt_f32_i32_e32 v34, v65                                 // 0000000027EC: 7E440B41
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000027F0: BF8700B1
	v_fmac_f32_e32 v27, v35, v34                               // 0000000027F4: 56364523
	v_mul_f32_e32 v34, v245, v46                               // 0000000027F8: 10445DF5
	v_cvt_f32_i32_e32 v35, v120                                // 0000000027FC: 7E460B78
	v_mul_f32_e32 v34, v34, v35                                // 000000002800: 10444722
	v_cvt_f32_i32_e32 v35, v64                                 // 000000002804: 7E460B40
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002808: BF8700B1
	v_fmac_f32_e32 v34, v1, v35                                // 00000000280C: 56444701
	v_cvt_f32_i32_e32 v1, v117                                 // 000000002810: 7E020B75
	v_mul_f32_e32 v35, v244, v43                               // 000000002814: 104657F4
	v_mul_f32_e32 v1, v35, v1                                  // 000000002818: 10020323
	v_cvt_f32_i32_e32 v35, v61                                 // 00000000281C: 7E460B3D
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002820: BF8700B1
	v_fmac_f32_e32 v1, v44, v35                                // 000000002824: 5602472C
	v_mul_f32_e32 v35, v244, v46                               // 000000002828: 10465DF4
	v_cvt_f32_i32_e32 v44, v116                                // 00000000282C: 7E580B74
	v_mul_f32_e32 v35, v35, v44                                // 000000002830: 10465923
	v_cvt_f32_i32_e32 v44, v60                                 // 000000002834: 7E580B3C
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002838: BF8700A1
	v_fmac_f32_e32 v35, v5, v44                                // 00000000283C: 56465905
	v_mul_f32_e32 v5, v2, v43                                  // 000000002840: 100A5702
	v_dual_mul_f32 v2, v2, v46 :: v_dual_mul_f32 v5, v5, v28   // 000000002844: C8C65D02 02043905
	v_mul_f32_e32 v28, v6, v40                                 // 00000000284C: 10385106
	v_mul_f32_e32 v6, v6, v41                                  // 000000002850: 100C5306
	s_delay_alu instid0(VALU_DEP_3)                            // 000000002854: BF870003
	v_mul_f32_e32 v2, v2, v25                                  // 000000002858: 10043302
	v_cvt_f32_i32_e32 v25, v37                                 // 00000000285C: 7E320B25
	v_add_f32_e32 v41, v252, v71                               // 000000002860: 06528FFC
	v_fmac_f32_e32 v5, v28, v26                                // 000000002864: 560A351C
	scratch_load_b32 v28, off, off offset:364                  // 000000002868: DC51016C 1C7C0000
	v_fmac_f32_e32 v2, v6, v25                                 // 000000002870: 56043306
	scratch_load_b32 v25, off, off offset:360                  // 000000002874: DC510168 197C0000
	v_cvt_f32_f16_e32 v6, v32                                  // 00000000287C: 7E0C1720
	s_waitcnt vmcnt(0)                                         // 000000002880: BF8903F7
	v_cvt_f32_u32_e32 v25, v25                                 // 000000002884: 7E320D19
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002888: BF870001
	v_mul_f32_e32 v6, v6, v25                                  // 00000000288C: 100C3306
	scratch_load_b64 v[25:26], off, off offset:348             // 000000002890: DC55015C 197C0000
	s_waitcnt vmcnt(0)                                         // 000000002898: BF8903F7
	v_add_f32_e32 v25, v25, v26                                // 00000000289C: 06323519
	v_cvt_f32_f16_e32 v26, v36                                 // 0000000028A0: 7E341724
	scratch_load_b64 v[36:37], off, off offset:340             // 0000000028A4: DC550154 247C0000
	v_cvt_f32_u32_e32 v28, v28                                 // 0000000028AC: 7E380D1C
	v_fma_f32 v32, -v25, v6, v45                               // 0000000028B0: D6130020 24B60D19
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000028B8: BF870092
	v_mul_f32_e32 v26, v26, v28                                // 0000000028BC: 1034391A
	v_fma_f32 v24, -v25, v26, v24                              // 0000000028C0: D6130018 24623519
	s_waitcnt vmcnt(0)                                         // 0000000028C8: BF8903F7
	v_add_f32_e32 v28, v36, v37                                // 0000000028CC: 06384B24
	scratch_load_b64 v[36:37], off, off offset:332             // 0000000028D0: DC55014C 247C0000
	v_fma_f32 v22, -v28, v26, v22                              // 0000000028D8: D6130016 245A351C
	s_waitcnt vmcnt(0)                                         // 0000000028E0: BF8903F7
	v_add_f32_e32 v25, v36, v37                                // 0000000028E4: 06324B24
	v_fma_f32 v36, -v28, v6, v42                               // 0000000028E8: D6130024 24AA0D1C
	s_clause 0x1                                               // 0000000028F0: BF850001
	scratch_load_b32 v28, off, off offset:288                  // 0000000028F4: DC510120 1C7C0000
	scratch_load_b32 v37, off, off offset:320                  // 0000000028FC: DC510140 257C0000
	v_add_f32_e32 v23, v249, v23                               // 000000002904: 062E2FF9
	v_fma_f32 v21, -v25, v6, v21                               // 000000002908: D6130015 24560D19
	v_add_f32_e32 v10, v10, v36                                // 000000002910: 0614490A
	v_fma_f32 v20, -v25, v26, v20                              // 000000002914: D6130014 24523519
	s_delay_alu instid0(VALU_DEP_3)                            // 00000000291C: BF870003
	v_add_f32_e32 v8, v8, v21                                  // 000000002920: 06102B08
	s_waitcnt vmcnt(0)                                         // 000000002924: BF8903F7
	v_add_f32_e32 v28, v37, v28                                // 000000002928: 06383925
	s_clause 0x1                                               // 00000000292C: BF850001
	scratch_load_b32 v37, off, off offset:292                  // 000000002930: DC510124 257C0000
	scratch_load_b32 v40, off, off offset:324                  // 000000002938: DC510144 287C0000
	v_fma_f32 v3, -v28, v6, v3                                 // 000000002940: D6130003 240E0D1C
	v_fma_f32 v19, -v28, v26, v19                              // 000000002948: D6130013 244E351C
	s_waitcnt vmcnt(0)                                         // 000000002950: BF8903F7
	v_add_f32_e32 v37, v40, v37                                // 000000002954: 064A4B28
	s_clause 0x1                                               // 000000002958: BF850001
	scratch_load_b32 v25, off, off offset:296                  // 00000000295C: DC510128 197C0000
	scratch_load_b32 v40, off, off offset:316                  // 000000002964: DC51013C 287C0000
	v_fma_f32 v7, -v37, v6, v7                                 // 00000000296C: D6130007 241E0D25
	v_fma_f32 v28, -v37, v26, v33                              // 000000002974: D613001C 24863525
	s_clause 0x1                                               // 00000000297C: BF850001
	scratch_load_b32 v33, off, off offset:284                  // 000000002980: DC51011C 217C0000
	scratch_load_b32 v37, off, off offset:312                  // 000000002988: DC510138 257C0000
	s_waitcnt vmcnt(2)                                         // 000000002990: BF890BF7
	v_add_f32_e32 v25, v40, v25                                // 000000002994: 06323328
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002998: BF870001
	v_fma_f32 v17, -v25, v6, v17                               // 00000000299C: D6130011 24460D19
	s_waitcnt vmcnt(0)                                         // 0000000029A4: BF8903F7
	v_add_f32_e32 v33, v37, v33                                // 0000000029A8: 06424325
	v_fma_f32 v18, -v25, v26, v18                              // 0000000029AC: D6130012 244A3519
	s_clause 0x1                                               // 0000000029B4: BF850001
	scratch_load_b32 v25, off, off offset:276                  // 0000000029B8: DC510114 197C0000
	scratch_load_b32 v37, off, off offset:304                  // 0000000029C0: DC510130 257C0000
	v_fma_f32 v15, -v33, v6, v15                               // 0000000029C8: D613000F 243E0D21
	v_fma_f32 v16, -v33, v26, v16                              // 0000000029D0: D6130010 24423521
	s_waitcnt vmcnt(0)                                         // 0000000029D8: BF8903F7
	v_add_f32_e32 v25, v37, v25                                // 0000000029DC: 06323325
	s_clause 0x1                                               // 0000000029E0: BF850001
	scratch_load_b32 v37, off, off offset:280                  // 0000000029E4: DC510118 257C0000
	scratch_load_b32 v40, off, off offset:308                  // 0000000029EC: DC510134 287C0000
	v_fma_f32 v27, -v25, v6, v27                               // 0000000029F4: D613001B 246E0D19
	v_fma_f32 v25, -v25, v26, v34                              // 0000000029FC: D6130019 248A3519
	s_delay_alu instid0(VALU_DEP_2)                            // 000000002A04: BF870002
	v_dual_add_f32 v249, v23, v24 :: v_dual_add_f32 v252, v41, v27// 000000002A08: C9083117 F9FC3729
	s_waitcnt vmcnt(0)                                         // 000000002A10: BF8903F7
	v_add_f32_e32 v37, v40, v37                                // 000000002A14: 064A4B28
	s_clause 0x1                                               // 000000002A18: BF850001
	scratch_load_b32 v33, off, off offset:272                  // 000000002A1C: DC510110 217C0000
	scratch_load_b32 v40, off, off offset:300                  // 000000002A24: DC51012C 287C0000
	v_fma_f32 v1, -v37, v6, v1                                 // 000000002A2C: D6130001 24060D25
	s_waitcnt vmcnt(0)                                         // 000000002A34: BF8903F7
	v_add_f32_e32 v33, v40, v33                                // 000000002A38: 06424328
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002A3C: BF870001
	v_fma_f32 v5, -v33, v6, v5                                 // 000000002A40: D6130005 24160D21
	v_add_f32_e32 v6, v9, v39                                  // 000000002A48: 060C4F09
	scratch_load_b32 v9, off, off offset:116                   // 000000002A4C: DC510074 097C0000
	v_fma_f32 v2, -v33, v26, v2                                // 000000002A54: D6130002 240A3521
	s_waitcnt vmcnt(0)                                         // 000000002A5C: BF8903F7
	v_dual_add_f32 v250, v0, v5 :: v_dual_add_f32 v33, v9, v38 // 000000002A60: C9080B00 FA204D09
	scratch_load_b32 v9, off, off offset:112                   // 000000002A68: DC510070 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002A70: BF8903F7
	v_add_f32_e32 v30, v9, v30                                 // 000000002A74: 063C3D09
	scratch_load_b32 v9, off, off offset:108                   // 000000002A78: DC51006C 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002A80: BF8903F7
	v_dual_add_f32 v43, v251, v74 :: v_dual_add_f32 v38, v9, v63// 000000002A84: C90895FB 2B267F09
	scratch_load_b32 v9, off, off offset:104                   // 000000002A8C: DC510068 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002A94: BF8903F7
	v_add_f32_e32 v39, v9, v59                                 // 000000002A98: 064E7709
	scratch_load_b32 v9, off, off offset:100                   // 000000002A9C: DC510064 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002AA4: BF8903F7
	v_add_f32_e32 v40, v9, v66                                 // 000000002AA8: 06508509
	scratch_load_b32 v9, off, off offset:96                    // 000000002AAC: DC510060 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002AB4: BF8903F7
	v_add_f32_e32 v42, v9, v67                                 // 000000002AB8: 06548709
	scratch_load_b32 v9, off, off offset:92                    // 000000002ABC: DC51005C 097C0000
	v_fma_f32 v34, -v37, v26, v35                              // 000000002AC4: D6130022 248E3525
	v_dual_add_f32 v26, v248, v47 :: v_dual_add_f32 v37, v239, v57// 000000002ACC: C9085FF8 1A2473EF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002AD4: BF870111
	v_dual_add_f32 v31, v255, v31 :: v_dual_add_f32 v248, v26, v22// 000000002AD8: C9083FFF 1FF82D1A
	v_add_f32_e32 v239, v37, v7                                // 000000002AE0: 07DE0F25
	s_waitcnt vmcnt(0)                                         // 000000002AE4: BF8903F7
	v_dual_add_f32 v7, v40, v16 :: v_dual_add_f32 v44, v9, v75 // 000000002AE8: C9082128 072C9709
	scratch_load_b32 v9, off, off offset:88                    // 000000002AF0: DC510058 097C0000
	s_waitcnt vmcnt(0)                                         // 000000002AF8: BF8903F7
	v_dual_add_f32 v35, v232, v62 :: v_dual_add_f32 v4, v9, v4 // 000000002AFC: C9087DE8 23040909
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000002B04: BF8701A1
	v_dual_add_f32 v29, v254, v29 :: v_dual_add_f32 v232, v35, v3// 000000002B08: C9083BFE 1DE80723
	v_add_f32_e32 v9, v6, v32                                  // 000000002B10: 06124106
	v_dual_add_f32 v21, v33, v20 :: v_dual_add_f32 v2, v4, v2  // 000000002B14: C9082921 15020504
	v_add_f32_e32 v20, v30, v19                                // 000000002B1C: 0628271E
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002B20: BF870004
	v_dual_add_f32 v19, v38, v28 :: v_dual_add_f32 v254, v29, v15// 000000002B24: C9083926 13FE1F1D
	v_add_f32_e32 v6, v42, v25                                 // 000000002B2C: 060C332A
	v_add_f32_e32 v255, v31, v17                               // 000000002B30: 07FE231F
	v_add_f32_e32 v17, v39, v18                                // 000000002B34: 06222527
	v_add_f32_e32 v251, v43, v1                                // 000000002B38: 07F6032B
	v_add_f32_e32 v3, v44, v34                                 // 000000002B3C: 0606452C
	s_cbranch_scc0 31                                          // 000000002B40: BFA1001F <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2bc0>
	s_clause 0x7                                               // 000000002B44: BF850007
	scratch_store_b32 off, v21, off offset:116                 // 000000002B48: DC690074 007C1500
	scratch_store_b32 off, v20, off offset:112                 // 000000002B50: DC690070 007C1400
	scratch_store_b32 off, v19, off offset:108                 // 000000002B58: DC69006C 007C1300
	scratch_store_b32 off, v17, off offset:104                 // 000000002B60: DC690068 007C1100
	scratch_store_b32 off, v7, off offset:100                  // 000000002B68: DC690064 007C0700
	scratch_store_b32 off, v6, off offset:96                   // 000000002B70: DC690060 007C0600
	scratch_store_b32 off, v3, off offset:92                   // 000000002B78: DC69005C 007C0300
	scratch_store_b32 off, v2, off offset:88                   // 000000002B80: DC690058 007C0200
	s_clause 0x5                                               // 000000002B88: BF850005
	scratch_load_b128 v[0:3], off, off offset:36               // 000000002B8C: DC5D0024 007C0000
	scratch_load_b128 v[104:107], off, off offset:68           // 000000002B94: DC5D0044 687C0000
	scratch_load_b128 v[112:115], off, off offset:52           // 000000002B9C: DC5D0034 707C0000
	scratch_load_b128 v[4:7], off, off offset:20               // 000000002BA4: DC5D0014 047C0000
	scratch_load_b128 v[96:99], off, off offset:4              // 000000002BAC: DC5D0004 607C0000
	scratch_load_b128 v[108:111], off, off offset:384          // 000000002BB4: DC5D0180 6C7C0000
	s_branch 62959                                             // 000000002BBC: BFA0F5EF <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x37c>
	v_add_f32_dpp v0, v9, v9 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BC0: 060012FA FF091109
	v_mbcnt_lo_u32_b32 v1, -1, 0                               // 000000002BC8: D71F0001 000100C1
	s_mov_b32 s3, 0                                            // 000000002BD0: BE830080
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002BD4: BF870112
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BD8: 060000FA FF091200
	v_cmp_eq_u32_e32 vcc_lo, 0, v1                             // 000000002BE0: 7C940280
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002BE4: BF870092
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BE8: 060000FA FF091400
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BF0: 060000FA FF091800
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002BF8: BF870001
	v_readlane_b32 s1, v0, 15                                  // 000000002BFC: D7600001 00011F00
	v_readlane_b32 s6, v0, 31                                  // 000000002C04: D7600006 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002C0C: BE80206A
	s_cbranch_execz 15                                         // 000000002C10: BFA5000F <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2c50>
	s_lshl_b64 s[8:9], s[2:3], 2                               // 000000002C14: 84888202
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002C18: BF870001
	v_add_f32_e64 v0, s1, s6                                   // 000000002C1C: D5030000 00000C01
	s_add_u32 s10, s4, s8                                      // 000000002C24: 800A0804
	s_addc_u32 s11, s5, s9                                     // 000000002C28: 820B0905
	s_add_u32 s8, s14, s8                                      // 000000002C2C: 8008080E
	s_addc_u32 s9, s15, s9                                     // 000000002C30: 8209090F
	s_load_b32 s3, s[8:9], null                                // 000000002C34: F40000C4 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002C3C: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s3, v0          // 000000002C40: CA080080 01000003
	global_store_b32 v1, v0, s[10:11]                          // 000000002C48: DC6A0000 000A0001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002C50: 8C7E007E
	v_add_f32_dpp v0, v10, v10 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C54: 060014FA FF09110A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002C5C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C60: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C68: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002C70: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C74: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002C7C: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002C84: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002C8C: BE80206A
	s_cbranch_execz 18                                         // 000000002C90: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2cdc>
	s_add_i32 s6, s2, 0x1400                                   // 000000002C94: 8106FF02 00001400
	s_mov_b32 s7, 0                                            // 000000002C9C: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002CA0: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002CA8: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002CAC: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002CB0: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002CB4: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002CB8: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002CBC: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002CC0: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002CC8: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002CCC: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002CD4: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002CDC: 8C7E007E
	v_add_f32_dpp v0, v8, v8 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002CE0: 060010FA FF091108
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CE8: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002CEC: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002CF4: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CFC: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002D00: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002D08: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002D10: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002D18: BE80206A
	s_cbranch_execz 18                                         // 000000002D1C: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2d68>
	s_add_i32 s6, s2, 0x2800                                   // 000000002D20: 8106FF02 00002800
	s_mov_b32 s7, 0                                            // 000000002D28: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002D2C: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002D34: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002D38: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002D3C: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002D40: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002D44: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002D48: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002D4C: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002D54: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002D58: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002D60: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002D68: 8C7E007E
	v_add_f32_dpp v0, v232, v232 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002D6C: 0601D0FA FF0911E8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002D74: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002D78: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002D80: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002D88: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002D8C: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002D94: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002D9C: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002DA4: BE80206A
	s_cbranch_execz 18                                         // 000000002DA8: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2df4>
	s_add_i32 s6, s2, 0x3c00                                   // 000000002DAC: 8106FF02 00003C00
	s_mov_b32 s7, 0                                            // 000000002DB4: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002DB8: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002DC0: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002DC4: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002DC8: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002DCC: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002DD0: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002DD4: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002DD8: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002DE0: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002DE4: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002DEC: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002DF4: 8C7E007E
	v_add_f32_dpp v0, v239, v239 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002DF8: 0601DEFA FF0911EF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002E00: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E04: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E0C: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002E14: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E18: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002E20: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002E28: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002E30: BE80206A
	s_cbranch_execz 18                                         // 000000002E34: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2e80>
	s_add_i32 s6, s2, 0x5000                                   // 000000002E38: 8106FF02 00005000
	s_mov_b32 s7, 0                                            // 000000002E40: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002E44: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002E4C: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002E50: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002E54: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002E58: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002E5C: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002E60: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002E64: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002E6C: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002E70: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002E78: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002E80: 8C7E007E
	v_add_f32_dpp v0, v255, v255 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E84: 0601FEFA FF0911FF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002E8C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E90: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002E98: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EA0: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002EA4: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002EAC: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002EB4: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002EBC: BE80206A
	s_cbranch_execz 18                                         // 000000002EC0: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2f0c>
	s_add_i32 s6, s2, 0x6400                                   // 000000002EC4: 8106FF02 00006400
	s_mov_b32 s7, 0                                            // 000000002ECC: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002ED0: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002ED8: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002EDC: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002EE0: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002EE4: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002EE8: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002EEC: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002EF0: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002EF8: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002EFC: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002F04: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002F0C: 8C7E007E
	v_add_f32_dpp v0, v254, v254 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002F10: 0601FCFA FF0911FE
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002F18: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002F1C: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002F24: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002F2C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002F30: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002F38: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002F40: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002F48: BE80206A
	s_cbranch_execz 18                                         // 000000002F4C: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x2f98>
	s_add_i32 s6, s2, 0x7800                                   // 000000002F50: 8106FF02 00007800
	s_mov_b32 s7, 0                                            // 000000002F58: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002F5C: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002F64: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002F68: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002F6C: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002F70: 82090705
	s_add_u32 s6, s14, s6                                      // 000000002F74: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000002F78: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000002F7C: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000002F84: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000002F88: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000002F90: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002F98: 8C7E007E
	v_add_f32_dpp v0, v252, v252 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002F9C: 0601F8FA FF0911FC
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002FA4: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FA8: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FB0: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002FB8: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FBC: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000002FC4: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000002FCC: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000002FD4: BE80206A
	s_cbranch_execz 18                                         // 000000002FD8: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x3024>
	s_add_i32 s6, s2, 0x8c00                                   // 000000002FDC: 8106FF02 00008C00
	s_mov_b32 s7, 0                                            // 000000002FE4: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000002FE8: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000002FF0: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002FF4: BF870009
	s_add_u32 s8, s4, s6                                       // 000000002FF8: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000002FFC: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003000: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000003004: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003008: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003010: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000003014: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 00000000301C: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000003024: 8C7E007E
	v_add_f32_dpp v0, v251, v251 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003028: 0601F6FA FF0911FB
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003030: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003034: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000303C: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003044: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003048: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003050: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000003058: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000003060: BE80206A
	s_cbranch_execz 18                                         // 000000003064: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x30b0>
	s_or_b32 s6, s2, 0xa000                                    // 000000003068: 8C06FF02 0000A000
	s_mov_b32 s7, 0                                            // 000000003070: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003074: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 00000000307C: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003080: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003084: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000003088: 82090705
	s_add_u32 s6, s14, s6                                      // 00000000308C: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000003090: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003094: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 00000000309C: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 0000000030A0: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 0000000030A8: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000030B0: 8C7E007E
	v_add_f32_dpp v0, v250, v250 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000030B4: 0601F4FA FF0911FA
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030BC: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000030C0: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000030C8: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030D0: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000030D4: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 0000000030DC: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 0000000030E4: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000030EC: BE80206A
	s_cbranch_execz 18                                         // 0000000030F0: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x313c>
	s_add_i32 s6, s2, 0xb400                                   // 0000000030F4: 8106FF02 0000B400
	s_mov_b32 s7, 0                                            // 0000000030FC: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003100: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000003108: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000310C: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003110: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000003114: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003118: 8006060E
	s_addc_u32 s7, s15, s7                                     // 00000000311C: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003120: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003128: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 00000000312C: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000003134: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000313C: 8C7E007E
	v_add_f32_dpp v0, v249, v249 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003140: 0601F2FA FF0911F9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003148: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000314C: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003154: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000315C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003160: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003168: D7600001 00011F00
	v_readlane_b32 s6, v0, 31                                  // 000000003170: D7600006 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000003178: BE80206A
	s_cbranch_execz 16                                         // 00000000317C: BFA50010 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x31c0>
	s_mov_b32 s3, 0                                            // 000000003180: BE830080
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000003184: BF8704A1
	v_add_f32_e64 v0, s1, s6                                   // 000000003188: D5030000 00000C01
	s_lshl_b64 s[8:9], s[2:3], 2                               // 000000003190: 84888202
	s_add_u32 s10, s4, s8                                      // 000000003194: 800A0804
	s_addc_u32 s11, s5, s9                                     // 000000003198: 820B0905
	s_add_u32 s8, s14, s8                                      // 00000000319C: 8008080E
	s_addc_u32 s9, s15, s9                                     // 0000000031A0: 8209090F
	s_load_b32 s3, s[8:9], 0x4                                 // 0000000031A4: F40000C4 F8000004
	s_waitcnt lgkmcnt(0)                                       // 0000000031AC: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s3, v0          // 0000000031B0: CA080080 01000003
	global_store_b32 v1, v0, s[10:11] offset:4                 // 0000000031B8: DC6A0004 000A0001
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000031C0: 8C7E007E
	v_add_f32_dpp v0, v248, v248 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031C4: 0601F0FA FF0911F8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000031CC: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031D0: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031D8: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000031E0: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031E4: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 0000000031EC: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 0000000031F4: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000031FC: BE80206A
	s_cbranch_execz 18                                         // 000000003200: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x324c>
	s_add_i32 s6, s2, 0x1401                                   // 000000003204: 8106FF02 00001401
	s_mov_b32 s7, 0                                            // 00000000320C: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003210: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000003218: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000321C: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003220: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000003224: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003228: 8006060E
	s_addc_u32 s7, s15, s7                                     // 00000000322C: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003230: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003238: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 00000000323C: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000003244: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000324C: 8C7E007E
	v_add_f32_dpp v0, v21, v21 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003250: 06002AFA FF091115
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003258: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000325C: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003264: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000326C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003270: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003278: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000003280: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000003288: BE80206A
	s_cbranch_execz 18                                         // 00000000328C: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x32d8>
	s_add_i32 s6, s2, 0x2801                                   // 000000003290: 8106FF02 00002801
	s_mov_b32 s7, 0                                            // 000000003298: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 00000000329C: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 0000000032A4: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000032A8: BF870009
	s_add_u32 s8, s4, s6                                       // 0000000032AC: 80080604
	s_addc_u32 s9, s5, s7                                      // 0000000032B0: 82090705
	s_add_u32 s6, s14, s6                                      // 0000000032B4: 8006060E
	s_addc_u32 s7, s15, s7                                     // 0000000032B8: 8207070F
	s_load_b32 s6, s[6:7], null                                // 0000000032BC: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 0000000032C4: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 0000000032C8: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 0000000032D0: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000032D8: 8C7E007E
	v_add_f32_dpp v0, v20, v20 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000032DC: 060028FA FF091114
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032E4: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000032E8: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000032F0: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032F8: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000032FC: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003304: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 00000000330C: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000003314: BE80206A
	s_cbranch_execz 18                                         // 000000003318: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x3364>
	s_add_i32 s6, s2, 0x3c01                                   // 00000000331C: 8106FF02 00003C01
	s_mov_b32 s7, 0                                            // 000000003324: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003328: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000003330: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003334: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003338: 80080604
	s_addc_u32 s9, s5, s7                                      // 00000000333C: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003340: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000003344: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003348: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003350: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000003354: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 00000000335C: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000003364: 8C7E007E
	v_add_f32_dpp v0, v19, v19 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003368: 060026FA FF091113
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003370: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003374: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000337C: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003384: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003388: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003390: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000003398: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000033A0: BE80206A
	s_cbranch_execz 18                                         // 0000000033A4: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x33f0>
	s_add_i32 s6, s2, 0x5001                                   // 0000000033A8: 8106FF02 00005001
	s_mov_b32 s7, 0                                            // 0000000033B0: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 0000000033B4: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 0000000033BC: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000033C0: BF870009
	s_add_u32 s8, s4, s6                                       // 0000000033C4: 80080604
	s_addc_u32 s9, s5, s7                                      // 0000000033C8: 82090705
	s_add_u32 s6, s14, s6                                      // 0000000033CC: 8006060E
	s_addc_u32 s7, s15, s7                                     // 0000000033D0: 8207070F
	s_load_b32 s6, s[6:7], null                                // 0000000033D4: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 0000000033DC: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 0000000033E0: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 0000000033E8: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000033F0: 8C7E007E
	v_add_f32_dpp v0, v17, v17 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000033F4: 060022FA FF091111
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000033FC: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003400: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003408: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003410: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003414: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 00000000341C: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 000000003424: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 00000000342C: BE80206A
	s_cbranch_execz 18                                         // 000000003430: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x347c>
	s_add_i32 s6, s2, 0x6401                                   // 000000003434: 8106FF02 00006401
	s_mov_b32 s7, 0                                            // 00000000343C: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003440: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000003448: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000344C: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003450: 80080604
	s_addc_u32 s9, s5, s7                                      // 000000003454: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003458: 8006060E
	s_addc_u32 s7, s15, s7                                     // 00000000345C: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003460: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003468: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 00000000346C: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000003474: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000347C: 8C7E007E
	v_add_f32_dpp v0, v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003480: 06000EFA FF091107
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003488: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000348C: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003494: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000349C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000034A0: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 0000000034A8: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 0000000034B0: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000034B8: BE80206A
	s_cbranch_execz 18                                         // 0000000034BC: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x3508>
	s_add_i32 s6, s2, 0x7801                                   // 0000000034C0: 8106FF02 00007801
	s_mov_b32 s7, 0                                            // 0000000034C8: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 0000000034CC: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 0000000034D4: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000034D8: BF870009
	s_add_u32 s8, s4, s6                                       // 0000000034DC: 80080604
	s_addc_u32 s9, s5, s7                                      // 0000000034E0: 82090705
	s_add_u32 s6, s14, s6                                      // 0000000034E4: 8006060E
	s_addc_u32 s7, s15, s7                                     // 0000000034E8: 8207070F
	s_load_b32 s6, s[6:7], null                                // 0000000034EC: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 0000000034F4: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 0000000034F8: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000003500: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000003508: 8C7E007E
	v_add_f32_dpp v0, v6, v6 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000350C: 06000CFA FF091106
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003514: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003518: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003520: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003528: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000352C: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 000000003534: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 00000000353C: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 000000003544: BE80206A
	s_cbranch_execz 18                                         // 000000003548: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x3594>
	s_add_i32 s6, s2, 0x8c01                                   // 00000000354C: 8106FF02 00008C01
	s_mov_b32 s7, 0                                            // 000000003554: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 000000003558: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000003560: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003564: BF870009
	s_add_u32 s8, s4, s6                                       // 000000003568: 80080604
	s_addc_u32 s9, s5, s7                                      // 00000000356C: 82090705
	s_add_u32 s6, s14, s6                                      // 000000003570: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000003574: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003578: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 000000003580: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000003584: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 00000000358C: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000003594: 8C7E007E
	v_add_f32_dpp v0, v3, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003598: 060006FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000035A0: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035A4: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035AC: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000035B4: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035B8: 060000FA FF091800
	v_readlane_b32 s1, v0, 15                                  // 0000000035C0: D7600001 00011F00
	v_readlane_b32 s3, v0, 31                                  // 0000000035C8: D7600003 00013F00
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000035D0: BE80206A
	s_cbranch_execz 18                                         // 0000000035D4: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x3620>
	s_or_b32 s6, s2, 0xa001                                    // 0000000035D8: 8C06FF02 0000A001
	s_mov_b32 s7, 0                                            // 0000000035E0: BE870080
	v_add_f32_e64 v0, s1, s3                                   // 0000000035E4: D5030000 00000601
	s_lshl_b64 s[6:7], s[6:7], 2                               // 0000000035EC: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000035F0: BF870009
	s_add_u32 s8, s4, s6                                       // 0000000035F4: 80080604
	s_addc_u32 s9, s5, s7                                      // 0000000035F8: 82090705
	s_add_u32 s6, s14, s6                                      // 0000000035FC: 8006060E
	s_addc_u32 s7, s15, s7                                     // 000000003600: 8207070F
	s_load_b32 s6, s[6:7], null                                // 000000003604: F4000183 F8000000
	s_waitcnt lgkmcnt(0)                                       // 00000000360C: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s6, v0          // 000000003610: CA080080 01000006
	global_store_b32 v1, v0, s[8:9]                            // 000000003618: DC6A0000 00080001
	s_or_b32 exec_lo, exec_lo, s0                              // 000000003620: 8C7E007E
	v_add_f32_dpp v0, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003624: 060004FA FF091102
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000362C: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003630: 060000FA FF091200
	v_add_f32_dpp v0, v0, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003638: 060000FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003640: BF870091
	v_add_f32_dpp v0, v0, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003644: 060000FA FF091800
	v_readlane_b32 s0, v0, 15                                  // 00000000364C: D7600000 00011F00
	v_readlane_b32 s1, v0, 31                                  // 000000003654: D7600001 00013F00
	s_and_saveexec_b32 s3, vcc_lo                              // 00000000365C: BE83206A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003660: BF870009
	s_xor_b32 s3, exec_lo, s3                                  // 000000003664: 8D03037E
	s_cbranch_execz 18                                         // 000000003668: BFA50012 <gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res+0x36b4>
	s_add_i32 s2, s2, 0xb401                                   // 00000000366C: 8102FF02 0000B401
	s_mov_b32 s3, 0                                            // 000000003674: BE830080
	v_add_f32_e64 v0, s0, s1                                   // 000000003678: D5030000 00000200
	s_lshl_b64 s[2:3], s[2:3], 2                               // 000000003680: 84828202
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003684: BF870009
	s_add_u32 s4, s4, s2                                       // 000000003688: 80040204
	s_addc_u32 s5, s5, s3                                      // 00000000368C: 82050305
	s_add_u32 s2, s14, s2                                      // 000000003690: 8002020E
	s_addc_u32 s3, s15, s3                                     // 000000003694: 8203030F
	s_load_b32 s2, s[2:3], null                                // 000000003698: F4000081 F8000000
	s_waitcnt lgkmcnt(0)                                       // 0000000036A0: BF89FC07
	v_dual_mov_b32 v1, 0 :: v_dual_add_f32 v0, s2, v0          // 0000000036A4: CA080080 01000002
	global_store_b32 v1, v0, s[4:5]                            // 0000000036AC: DC6A0000 00040001
	s_endpgm                                                   // 0000000036B4: BFB00000
	s_code_end                                                 // 0000000036B8: BF9F0000
	s_code_end                                                 // 0000000036BC: BF9F0000
	s_code_end                                                 // 0000000036C0: BF9F0000
	s_code_end                                                 // 0000000036C4: BF9F0000
	s_code_end                                                 // 0000000036C8: BF9F0000
	s_code_end                                                 // 0000000036CC: BF9F0000
	s_code_end                                                 // 0000000036D0: BF9F0000
	s_code_end                                                 // 0000000036D4: BF9F0000
	s_code_end                                                 // 0000000036D8: BF9F0000
	s_code_end                                                 // 0000000036DC: BF9F0000
	s_code_end                                                 // 0000000036E0: BF9F0000
	s_code_end                                                 // 0000000036E4: BF9F0000
	s_code_end                                                 // 0000000036E8: BF9F0000
	s_code_end                                                 // 0000000036EC: BF9F0000
	s_code_end                                                 // 0000000036F0: BF9F0000
	s_code_end                                                 // 0000000036F4: BF9F0000
	s_code_end                                                 // 0000000036F8: BF9F0000
	s_code_end                                                 // 0000000036FC: BF9F0000
	s_code_end                                                 // 000000003700: BF9F0000
	s_code_end                                                 // 000000003704: BF9F0000
	s_code_end                                                 // 000000003708: BF9F0000
	s_code_end                                                 // 00000000370C: BF9F0000
	s_code_end                                                 // 000000003710: BF9F0000
	s_code_end                                                 // 000000003714: BF9F0000
	s_code_end                                                 // 000000003718: BF9F0000
	s_code_end                                                 // 00000000371C: BF9F0000
	s_code_end                                                 // 000000003720: BF9F0000
	s_code_end                                                 // 000000003724: BF9F0000
	s_code_end                                                 // 000000003728: BF9F0000
	s_code_end                                                 // 00000000372C: BF9F0000
	s_code_end                                                 // 000000003730: BF9F0000
	s_code_end                                                 // 000000003734: BF9F0000
	s_code_end                                                 // 000000003738: BF9F0000
	s_code_end                                                 // 00000000373C: BF9F0000
	s_code_end                                                 // 000000003740: BF9F0000
	s_code_end                                                 // 000000003744: BF9F0000
	s_code_end                                                 // 000000003748: BF9F0000
	s_code_end                                                 // 00000000374C: BF9F0000
	s_code_end                                                 // 000000003750: BF9F0000
	s_code_end                                                 // 000000003754: BF9F0000
	s_code_end                                                 // 000000003758: BF9F0000
	s_code_end                                                 // 00000000375C: BF9F0000
	s_code_end                                                 // 000000003760: BF9F0000
	s_code_end                                                 // 000000003764: BF9F0000
	s_code_end                                                 // 000000003768: BF9F0000
	s_code_end                                                 // 00000000376C: BF9F0000
	s_code_end                                                 // 000000003770: BF9F0000
	s_code_end                                                 // 000000003774: BF9F0000
	s_code_end                                                 // 000000003778: BF9F0000
	s_code_end                                                 // 00000000377C: BF9F0000
	s_code_end                                                 // 000000003780: BF9F0000
	s_code_end                                                 // 000000003784: BF9F0000
	s_code_end                                                 // 000000003788: BF9F0000
	s_code_end                                                 // 00000000378C: BF9F0000
	s_code_end                                                 // 000000003790: BF9F0000
	s_code_end                                                 // 000000003794: BF9F0000
	s_code_end                                                 // 000000003798: BF9F0000
	s_code_end                                                 // 00000000379C: BF9F0000
	s_code_end                                                 // 0000000037A0: BF9F0000
	s_code_end                                                 // 0000000037A4: BF9F0000
	s_code_end                                                 // 0000000037A8: BF9F0000
	s_code_end                                                 // 0000000037AC: BF9F0000
	s_code_end                                                 // 0000000037B0: BF9F0000
	s_code_end                                                 // 0000000037B4: BF9F0000
	s_code_end                                                 // 0000000037B8: BF9F0000
	s_code_end                                                 // 0000000037BC: BF9F0000
	s_code_end                                                 // 0000000037C0: BF9F0000
	s_code_end                                                 // 0000000037C4: BF9F0000
	s_code_end                                                 // 0000000037C8: BF9F0000
	s_code_end                                                 // 0000000037CC: BF9F0000
	s_code_end                                                 // 0000000037D0: BF9F0000
	s_code_end                                                 // 0000000037D4: BF9F0000
	s_code_end                                                 // 0000000037D8: BF9F0000
	s_code_end                                                 // 0000000037DC: BF9F0000
	s_code_end                                                 // 0000000037E0: BF9F0000
	s_code_end                                                 // 0000000037E4: BF9F0000
	s_code_end                                                 // 0000000037E8: BF9F0000
	s_code_end                                                 // 0000000037EC: BF9F0000
	s_code_end                                                 // 0000000037F0: BF9F0000
	s_code_end                                                 // 0000000037F4: BF9F0000
	s_code_end                                                 // 0000000037F8: BF9F0000
	s_code_end                                                 // 0000000037FC: BF9F0000
	s_code_end                                                 // 000000003800: BF9F0000
	s_code_end                                                 // 000000003804: BF9F0000
	s_code_end                                                 // 000000003808: BF9F0000
	s_code_end                                                 // 00000000380C: BF9F0000
	s_code_end                                                 // 000000003810: BF9F0000
	s_code_end                                                 // 000000003814: BF9F0000
	s_code_end                                                 // 000000003818: BF9F0000
	s_code_end                                                 // 00000000381C: BF9F0000
	s_code_end                                                 // 000000003820: BF9F0000
	s_code_end                                                 // 000000003824: BF9F0000
	s_code_end                                                 // 000000003828: BF9F0000
	s_code_end                                                 // 00000000382C: BF9F0000
	s_code_end                                                 // 000000003830: BF9F0000
	s_code_end                                                 // 000000003834: BF9F0000
	s_code_end                                                 // 000000003838: BF9F0000
	s_code_end                                                 // 00000000383C: BF9F0000
	s_code_end                                                 // 000000003840: BF9F0000
	s_code_end                                                 // 000000003844: BF9F0000
	s_code_end                                                 // 000000003848: BF9F0000
	s_code_end                                                 // 00000000384C: BF9F0000
	s_code_end                                                 // 000000003850: BF9F0000
	s_code_end                                                 // 000000003854: BF9F0000
	s_code_end                                                 // 000000003858: BF9F0000
	s_code_end                                                 // 00000000385C: BF9F0000
	s_code_end                                                 // 000000003860: BF9F0000
	s_code_end                                                 // 000000003864: BF9F0000
	s_code_end                                                 // 000000003868: BF9F0000
	s_code_end                                                 // 00000000386C: BF9F0000
	s_code_end                                                 // 000000003870: BF9F0000
	s_code_end                                                 // 000000003874: BF9F0000
	s_code_end                                                 // 000000003878: BF9F0000
	s_code_end                                                 // 00000000387C: BF9F0000
