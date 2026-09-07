
/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad/isa/attn_prep_24_4_256_64_8204_11_k4jv4�_50cd42ad.elf:	file format elf64-amdgpu

Disassembly of section .text:

0000000000000000 <attn_prep_24_4_256_64_8204_11_k4jv4>:
	s_load_b64 s[28:29], s[0:1], 0x58                          // 000000000000: F4040700 F8000058
	s_lshr_b32 s12, s15, 2                                     // 000000000008: 850C820F
	s_waitcnt lgkmcnt(0)                                       // 00000000000C: BF89FC07
	s_load_b32 s2, s[28:29], 0x4                               // 000000000010: F400008E F8000004
	s_waitcnt lgkmcnt(0)                                       // 000000000018: BF89FC07
	s_cmp_ge_u32 s12, s2                                       // 00000000001C: BF09020C
	s_cbranch_scc1 2381                                        // 000000000020: BFA2094D <attn_prep_24_4_256_64_8204_11_k4jv4+0x2558>
	v_mov_b32_e32 v1, 0                                        // 000000000024: 7E020280
	global_load_b32 v2, v1, s[28:29] glc                       // 000000000028: DC524000 021C0001
	s_waitcnt vmcnt(0)                                         // 000000000030: BF8903F7
	buffer_gl1_inv                                             // 000000000034: E0B00000 00000000
	buffer_gl0_inv                                             // 00000000003C: E0AC0000 00000000
	s_clause 0x3                                               // 000000000044: BF850003
	s_load_b64 s[2:3], s[0:1], 0x50                            // 000000000048: F4040080 F8000050
	s_load_b128 s[24:27], s[0:1], 0x40                         // 000000000050: F4080600 F8000040
	s_load_b256 s[16:23], s[0:1], null                         // 000000000058: F40C0400 F8000000
	s_load_b256 s[4:11], s[0:1], 0x20                          // 000000000060: F40C0100 F8000020
	v_readfirstlane_b32 s0, v2                                 // 000000000068: 7E000502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 00000000006C: BF870491
	s_add_i32 s14, s0, s12                                     // 000000000070: 810E0C00
	s_cmpk_lt_u32 s14, 0x200c                                  // 000000000074: B68E200C
	s_cbranch_scc1 22                                          // 000000000078: BFA20016 <attn_prep_24_4_256_64_8204_11_k4jv4+0xd4>
	s_mov_b32 s0, 0                                            // 00000000007C: BE800080
	global_load_b32 v2, v1, s[28:29] glc                       // 000000000080: DC524000 021C0001
	s_waitcnt vmcnt(0)                                         // 000000000088: BF8903F7
	buffer_gl1_inv                                             // 00000000008C: E0B00000 00000000
	buffer_gl0_inv                                             // 000000000094: E0AC0000 00000000
	s_add_i32 s1, s0, 1                                        // 00000000009C: 81018100
	s_cmp_lt_u32 s0, 0xf423f                                   // 0000000000A0: BF0AFF00 000F423F
	s_cselect_b32 s0, -1, 0                                    // 0000000000A8: 980080C1
	v_readfirstlane_b32 s13, v2                                // 0000000000AC: 7E1A0502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 0000000000B0: BF870491
	s_add_i32 s14, s13, s12                                    // 0000000000B4: 810E0C0D
	s_cmpk_gt_u32 s14, 0x200b                                  // 0000000000B8: B58E200B
	s_cselect_b32 s13, -1, 0                                   // 0000000000BC: 980D80C1
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 0000000000C0: BF870499
	s_and_b32 s0, s0, s13                                      // 0000000000C4: 8B000D00
	s_and_not1_b32 vcc_lo, exec_lo, s0                         // 0000000000C8: 916A007E
	s_mov_b32 s0, s1                                           // 0000000000CC: BE800001
	s_cbranch_vccz 65515                                       // 0000000000D0: BFA3FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0x80>
	s_mov_b32 s0, exec_lo                                      // 0000000000D4: BE80007E
	v_cmpx_gt_u32_e32 16, v0                                   // 0000000000D8: 7D980090
	s_cbranch_execz 299                                        // 0000000000DC: BFA5012B <attn_prep_24_4_256_64_8204_11_k4jv4+0x58c>
	s_mov_b32 s1, 0                                            // 0000000000E0: BE810080
	s_mov_b32 s28, 0                                           // 0000000000E4: BE9C0080
	s_mov_b32 s13, exec_lo                                     // 0000000000E8: BE8D007E
	v_cmpx_lt_i32_e32 6, v0                                    // 0000000000EC: 7D820086
	s_xor_b32 s13, exec_lo, s13                                // 0000000000F0: 8D0D0D7E
	s_cbranch_execz 77                                         // 0000000000F4: BFA5004D <attn_prep_24_4_256_64_8204_11_k4jv4+0x22c>
	s_mov_b32 s28, exec_lo                                     // 0000000000F8: BE9C007E
	v_cmpx_lt_i32_e32 10, v0                                   // 0000000000FC: 7D82008A
	s_xor_b32 s28, exec_lo, s28                                // 000000000100: 8D1C1C7E
	s_cbranch_execz 38                                         // 000000000104: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1a0>
	s_mov_b32 s29, exec_lo                                     // 000000000108: BE9D007E
	v_cmpx_lt_i32_e32 12, v0                                   // 00000000010C: 7D82008C
	s_xor_b32 s29, exec_lo, s29                                // 000000000110: 8D1D1D7E
	s_cbranch_execz 19                                         // 000000000114: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x164>
	s_mov_b32 s30, exec_lo                                     // 000000000118: BE9E007E
	v_cmpx_lt_i32_e32 13, v0                                   // 00000000011C: 7D82008D
	s_xor_b32 s30, exec_lo, s30                                // 000000000120: 8D1E1E7E
	s_cbranch_execz 11                                         // 000000000124: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x154>
	s_mov_b32 s33, exec_lo                                     // 000000000128: BEA1007E
	v_cmpx_ne_u32_e32 14, v0                                   // 00000000012C: 7D9A008E
	s_xor_b32 s33, exec_lo, s33                                // 000000000130: 8D21217E
	s_mov_b32 s31, 0x402ee2bf                                  // 000000000134: BE9F00FF 402EE2BF
	s_or_saveexec_b32 s33, s33                                 // 00000000013C: BEA12221
	v_mov_b32_e32 v1, s31                                      // 000000000140: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s33                            // 000000000144: 8D7E217E
	v_mov_b32_e32 v1, 0x40046ac7                               // 000000000148: 7E0202FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s33                             // 000000000150: 8C7E217E
	s_and_not1_saveexec_b32 s30, s30                           // 000000000154: BE9E301E
	v_mov_b32_e32 v1, 0x3fcf1c25                               // 000000000158: 7E0202FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000160: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 000000000164: BE9D301D
	s_cbranch_execz 11                                         // 000000000168: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x198>
	s_mov_b32 s30, exec_lo                                     // 00000000016C: BE9E007E
	v_cmpx_lt_i32_e32 11, v0                                   // 000000000170: 7D82008B
	s_xor_b32 s30, exec_lo, s30                                // 000000000174: 8D1E1E7E
	s_mov_b32 s31, 0x3fa0cc2f                                  // 000000000178: BE9F00FF 3FA0CC2F
	s_or_saveexec_b32 s30, s30                                 // 000000000180: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000184: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000188: 8D7E1E7E
	v_mov_b32_e32 v1, 0x3f713d3a                               // 00000000018C: 7E0202FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000194: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000198: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000019C: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 0000000001A0: BE9C301C
	s_cbranch_execz 30                                         // 0000000001A4: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x220>
	s_mov_b32 s29, exec_lo                                     // 0000000001A8: BE9D007E
	v_cmpx_lt_i32_e32 8, v0                                    // 0000000001AC: 7D820088
	s_xor_b32 s29, exec_lo, s29                                // 0000000001B0: 8D1D1D7E
	s_cbranch_execz 11                                         // 0000000001B4: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x1e4>
	s_mov_b32 s30, exec_lo                                     // 0000000001B8: BE9E007E
	v_cmpx_lt_i32_e32 9, v0                                    // 0000000001BC: 7D820089
	s_xor_b32 s30, exec_lo, s30                                // 0000000001C0: 8D1E1E7E
	s_mov_b32 s31, 0x3f28215d                                  // 0000000001C4: BE9F00FF 3F28215D
	s_or_saveexec_b32 s30, s30                                 // 0000000001CC: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 0000000001D0: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000001D4: 8D7E1E7E
	v_mov_b32_e32 v1, 0x3ec6ae44                               // 0000000001D8: 7E0202FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000001E0: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 0000000001E4: BE9D301D
	s_cbranch_execz 11                                         // 0000000001E8: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x218>
	s_mov_b32 s30, exec_lo                                     // 0000000001EC: BE9E007E
	v_cmpx_lt_i32_e32 7, v0                                    // 0000000001F0: 7D820087
	s_xor_b32 s30, exec_lo, s30                                // 0000000001F4: 8D1E1E7E
	s_mov_b32 s31, 0x3e0379fb                                  // 0000000001F8: BE9F00FF 3E0379FB
	s_or_saveexec_b32 s30, s30                                 // 000000000200: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000204: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000208: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbe0379fb                               // 00000000020C: 7E0202FF BE0379FB
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000214: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000218: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000021C: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000220: BF870499
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000224: 8C7E1C7E
	s_mov_b32 s28, exec_lo                                     // 000000000228: BE9C007E
	s_and_not1_saveexec_b32 s13, s13                           // 00000000022C: BE8D300D
	s_cbranch_execz 67                                         // 000000000230: BFA50043 <attn_prep_24_4_256_64_8204_11_k4jv4+0x340>
	s_mov_b32 s29, s28                                         // 000000000234: BE9D001C
	s_mov_b32 s1, exec_lo                                      // 000000000238: BE81007E
	v_cmpx_lt_i32_e32 2, v0                                    // 00000000023C: 7D820082
	s_xor_b32 s1, exec_lo, s1                                  // 000000000240: 8D01017E
	s_cbranch_execz 31                                         // 000000000244: BFA5001F <attn_prep_24_4_256_64_8204_11_k4jv4+0x2c4>
	s_mov_b32 s29, exec_lo                                     // 000000000248: BE9D007E
	v_cmpx_lt_i32_e32 4, v0                                    // 00000000024C: 7D820084
	s_xor_b32 s29, exec_lo, s29                                // 000000000250: 8D1D1D7E
	s_cbranch_execz 11                                         // 000000000254: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x284>
	s_mov_b32 s30, exec_lo                                     // 000000000258: BE9E007E
	v_cmpx_lt_i32_e32 5, v0                                    // 00000000025C: 7D820085
	s_xor_b32 s30, exec_lo, s30                                // 000000000260: 8D1E1E7E
	s_mov_b32 s31, 0xbec6ae44                                  // 000000000264: BE9F00FF BEC6AE44
	s_or_saveexec_b32 s30, s30                                 // 00000000026C: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000270: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000274: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbf28215d                               // 000000000278: 7E0202FF BF28215D
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000280: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 000000000284: BE9D301D
	s_cbranch_execz 11                                         // 000000000288: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x2b8>
	s_mov_b32 s30, exec_lo                                     // 00000000028C: BE9E007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000290: 7D820083
	s_xor_b32 s30, exec_lo, s30                                // 000000000294: 8D1E1E7E
	s_mov_b32 s31, 0xbf713d3a                                  // 000000000298: BE9F00FF BF713D3A
	s_or_saveexec_b32 s30, s30                                 // 0000000002A0: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 0000000002A4: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000002A8: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbfa0cc2f                               // 0000000002AC: 7E0202FF BFA0CC2F
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000002B4: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 0000000002B8: BF870499
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000002BC: 8C7E1D7E
	s_or_b32 s29, s28, exec_lo                                 // 0000000002C0: 8C1D7E1C
	s_or_saveexec_b32 s1, s1                                   // 0000000002C4: BE812201
	s_mov_b32 s30, 0                                           // 0000000002C8: BE9E0080
	s_xor_b32 exec_lo, exec_lo, s1                             // 0000000002CC: 8D7E017E
	s_cbranch_execz 21                                         // 0000000002D0: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0x328>
	s_mov_b32 s31, -1                                          // 0000000002D4: BE9F00C1
	s_mov_b32 s33, s29                                         // 0000000002D8: BEA1001D
	s_mov_b32 s30, exec_lo                                     // 0000000002DC: BE9E007E
	v_cmpx_lt_i32_e32 0, v0                                    // 0000000002E0: 7D820080
	s_cbranch_execz 10                                         // 0000000002E4: BFA5000A <attn_prep_24_4_256_64_8204_11_k4jv4+0x310>
	v_mov_b32_e32 v1, 0xc0046ac7                               // 0000000002E8: 7E0202FF C0046AC7
	s_mov_b32 s31, exec_lo                                     // 0000000002F0: BE9F007E
	v_cmpx_lt_i32_e32 1, v0                                    // 0000000002F4: 7D820081
	v_mov_b32_e32 v1, 0xbfcf1c25                               // 0000000002F8: 7E0202FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000300: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000304: BF870009
	s_xor_b32 s31, exec_lo, -1                                 // 000000000308: 8D1FC17E
	s_or_b32 s33, s29, exec_lo                                 // 00000000030C: 8C217E1D
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000310: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000314: BF870009
	s_and_not1_b32 s29, s29, exec_lo                           // 000000000318: 911D7E1D
	s_and_b32 s33, s33, exec_lo                                // 00000000031C: 8B217E21
	s_and_b32 s30, s31, exec_lo                                // 000000000320: 8B1E7E1F
	s_or_b32 s29, s29, s33                                     // 000000000324: 8C1D211D
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000328: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000032C: BF870009
	s_and_not1_b32 s28, s28, exec_lo                           // 000000000330: 911C7E1C
	s_and_b32 s29, s29, exec_lo                                // 000000000334: 8B1D7E1D
	s_and_b32 s1, s30, exec_lo                                 // 000000000338: 8B017E1E
	s_or_b32 s28, s28, s29                                     // 00000000033C: 8C1C1D1C
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000340: 8C7E0D7E
	s_and_saveexec_b32 s13, s28                                // 000000000344: BE8D201C
	s_cbranch_execz 132                                        // 000000000348: BFA50084 <attn_prep_24_4_256_64_8204_11_k4jv4+0x55c>
	v_lshlrev_b32_e32 v2, 2, v0                                // 00000000034C: 30040082
	s_mov_b32 s28, exec_lo                                     // 000000000350: BE9C007E
	ds_store_b32 v2, v1 offset:17920                           // 000000000354: D8344600 00000102
	v_cmpx_lt_i32_e32 7, v0                                    // 00000000035C: 7D820087
	s_xor_b32 s28, exec_lo, s28                                // 000000000360: 8D1C1C7E
	s_cbranch_execz 65                                         // 000000000364: BFA50041 <attn_prep_24_4_256_64_8204_11_k4jv4+0x46c>
	s_mov_b32 s29, exec_lo                                     // 000000000368: BE9D007E
	v_cmpx_lt_i32_e32 10, v0                                   // 00000000036C: 7D82008A
	s_xor_b32 s29, exec_lo, s29                                // 000000000370: 8D1D1D7E
	s_cbranch_execz 38                                         // 000000000374: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x410>
	s_mov_b32 s30, exec_lo                                     // 000000000378: BE9E007E
	v_cmpx_lt_i32_e32 12, v0                                   // 00000000037C: 7D82008C
	s_xor_b32 s30, exec_lo, s30                                // 000000000380: 8D1E1E7E
	s_cbranch_execz 19                                         // 000000000384: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x3d4>
	s_mov_b32 s31, exec_lo                                     // 000000000388: BE9F007E
	v_cmpx_lt_i32_e32 13, v0                                   // 00000000038C: 7D82008D
	s_xor_b32 s31, exec_lo, s31                                // 000000000390: 8D1F1F7E
	s_cbranch_execz 11                                         // 000000000394: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x3c4>
	s_mov_b32 s33, exec_lo                                     // 000000000398: BEA1007E
	v_cmpx_ne_u32_e32 14, v0                                   // 00000000039C: 7D9A008E
	s_xor_b32 s33, exec_lo, s33                                // 0000000003A0: 8D21217E
	s_mov_b32 s34, 0x402ee2bf                                  // 0000000003A4: BEA200FF 402EE2BF
	s_or_saveexec_b32 s33, s33                                 // 0000000003AC: BEA12221
	v_mov_b32_e32 v2, s34                                      // 0000000003B0: 7E040222
	s_xor_b32 exec_lo, exec_lo, s33                            // 0000000003B4: 8D7E217E
	v_mov_b32_e32 v2, 0x40046ac7                               // 0000000003B8: 7E0402FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s33                             // 0000000003C0: 8C7E217E
	s_and_not1_saveexec_b32 s31, s31                           // 0000000003C4: BE9F301F
	v_mov_b32_e32 v2, 0x3fcf1c25                               // 0000000003C8: 7E0402FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000003D0: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 0000000003D4: BE9E301E
	s_cbranch_execz 11                                         // 0000000003D8: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x408>
	s_mov_b32 s31, exec_lo                                     // 0000000003DC: BE9F007E
	v_cmpx_lt_i32_e32 11, v0                                   // 0000000003E0: 7D82008B
	s_xor_b32 s31, exec_lo, s31                                // 0000000003E4: 8D1F1F7E
	s_mov_b32 s33, 0x3fa0cc2f                                  // 0000000003E8: BEA100FF 3FA0CC2F
	s_or_saveexec_b32 s31, s31                                 // 0000000003F0: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 0000000003F4: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000003F8: 8D7E1F7E
	v_mov_b32_e32 v2, 0x3f713d3a                               // 0000000003FC: 7E0402FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000404: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000408: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 00000000040C: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 000000000410: BE9D301D
	s_cbranch_execz 19                                         // 000000000414: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x464>
	s_mov_b32 s30, exec_lo                                     // 000000000418: BE9E007E
	v_cmpx_lt_i32_e32 8, v0                                    // 00000000041C: 7D820088
	s_xor_b32 s30, exec_lo, s30                                // 000000000420: 8D1E1E7E
	s_cbranch_execz 11                                         // 000000000424: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x454>
	s_mov_b32 s31, exec_lo                                     // 000000000428: BE9F007E
	v_cmpx_lt_i32_e32 9, v0                                    // 00000000042C: 7D820089
	s_xor_b32 s31, exec_lo, s31                                // 000000000430: 8D1F1F7E
	s_mov_b32 s33, 0x3f28215d                                  // 000000000434: BEA100FF 3F28215D
	s_or_saveexec_b32 s31, s31                                 // 00000000043C: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 000000000440: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 000000000444: 8D7E1F7E
	v_mov_b32_e32 v2, 0x3ec6ae44                               // 000000000448: 7E0402FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000450: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 000000000454: BE9E301E
	v_mov_b32_e32 v2, 0x3e0379fb                               // 000000000458: 7E0402FF 3E0379FB
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000460: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000464: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000468: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 00000000046C: BE9C301C
	s_cbranch_execz 56                                         // 000000000470: BFA50038 <attn_prep_24_4_256_64_8204_11_k4jv4+0x554>
	s_mov_b32 s29, exec_lo                                     // 000000000474: BE9D007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000478: 7D820083
	s_xor_b32 s29, exec_lo, s29                                // 00000000047C: 8D1D1D7E
	s_cbranch_execz 30                                         // 000000000480: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x4fc>
	s_mov_b32 s30, exec_lo                                     // 000000000484: BE9E007E
	v_cmpx_lt_i32_e32 5, v0                                    // 000000000488: 7D820085
	s_xor_b32 s30, exec_lo, s30                                // 00000000048C: 8D1E1E7E
	s_cbranch_execz 11                                         // 000000000490: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x4c0>
	s_mov_b32 s31, exec_lo                                     // 000000000494: BE9F007E
	v_cmpx_lt_i32_e32 6, v0                                    // 000000000498: 7D820086
	s_xor_b32 s31, exec_lo, s31                                // 00000000049C: 8D1F1F7E
	s_mov_b32 s33, 0xbe0379fb                                  // 0000000004A0: BEA100FF BE0379FB
	s_or_saveexec_b32 s31, s31                                 // 0000000004A8: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 0000000004AC: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000004B0: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbec6ae44                               // 0000000004B4: 7E0402FF BEC6AE44
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000004BC: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 0000000004C0: BE9E301E
	s_cbranch_execz 11                                         // 0000000004C4: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x4f4>
	s_mov_b32 s31, exec_lo                                     // 0000000004C8: BE9F007E
	v_cmpx_lt_i32_e32 4, v0                                    // 0000000004CC: 7D820084
	s_xor_b32 s31, exec_lo, s31                                // 0000000004D0: 8D1F1F7E
	s_mov_b32 s33, 0xbf28215d                                  // 0000000004D4: BEA100FF BF28215D
	s_or_saveexec_b32 s31, s31                                 // 0000000004DC: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 0000000004E0: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000004E4: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbf713d3a                               // 0000000004E8: 7E0402FF BF713D3A
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000004F0: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004F4: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000004F8: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 0000000004FC: BE9D301D
	s_cbranch_execz 18                                         // 000000000500: BFA50012 <attn_prep_24_4_256_64_8204_11_k4jv4+0x54c>
	v_mov_b32_e32 v2, 0xc0046ac7                               // 000000000504: 7E0402FF C0046AC7
	s_mov_b32 s30, exec_lo                                     // 00000000050C: BE9E007E
	v_cmpx_lt_i32_e32 1, v0                                    // 000000000510: 7D820081
	s_cbranch_execz 11                                         // 000000000514: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x544>
	s_mov_b32 s31, exec_lo                                     // 000000000518: BE9F007E
	v_cmpx_lt_i32_e32 2, v0                                    // 00000000051C: 7D820082
	s_xor_b32 s31, exec_lo, s31                                // 000000000520: 8D1F1F7E
	s_mov_b32 s33, 0xbfa0cc2f                                  // 000000000524: BEA100FF BFA0CC2F
	s_or_saveexec_b32 s31, s31                                 // 00000000052C: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 000000000530: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 000000000534: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbfcf1c25                               // 000000000538: 7E0402FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000540: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000544: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000548: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000054C: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000550: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000554: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000558: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000055C: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000560: 8C7E0D7E
	s_and_saveexec_b32 s13, s1                                 // 000000000564: BE8D2001
	v_dual_mov_b32 v2, 0xc02ee2bf :: v_dual_mov_b32 v1, 0      // 000000000568: CA1000FF 02000080 C02EE2BF
	ds_store_b32 v1, v2 offset:17920                           // 000000000574: D8344600 00000201
	s_or_b32 exec_lo, exec_lo, s13                             // 00000000057C: 8C7E0D7E
	v_lshlrev_b32_e32 v1, 2, v0                                // 000000000580: 30020082
	ds_store_b32 v1, v2 offset:17984                           // 000000000584: D8344640 00000201
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000058C: 8C7E007E
	v_mbcnt_lo_u32_b32 v4, -1, 0                               // 000000000590: D71F0004 000100C1
	v_lshrrev_b32_e32 v1, 5, v0                                // 000000000598: 32020085
	v_cmp_gt_u32_e64 s0, 0xc0, v0                              // 00000000059C: D44C0000 000200FF 000000C0
	s_and_b32 s30, s15, 3                                      // 0000000005A8: 8B1E830F
	s_mov_b32 s13, 0                                           // 0000000005AC: BE8D0080
	s_mov_b32 s1, exec_lo                                      // 0000000005B0: BE81007E
	v_cmpx_lt_u32_e32 0xbf, v0                                 // 0000000005B4: 7D9200FF 000000BF
	s_xor_b32 s15, exec_lo, s1                                 // 0000000005BC: 8D0F017E
	s_cbranch_execz 171                                        // 0000000005C0: BFA500AB <attn_prep_24_4_256_64_8204_11_k4jv4+0x870>
	s_lshl_b64 s[28:29], s[12:13], 10                          // 0000000005C4: 849C8A0C
	s_mov_b32 s1, exec_lo                                      // 0000000005C8: BE81007E
	v_cmpx_lt_i32_e32 6, v1                                    // 0000000005CC: 7D820286
	s_xor_b32 s1, exec_lo, s1                                  // 0000000005D0: 8D01017E
	s_cbranch_execz 24                                         // 0000000005D4: BFA50018 <attn_prep_24_4_256_64_8204_11_k4jv4+0x638>
	s_mov_b32 s13, exec_lo                                     // 0000000005D8: BE8D007E
	v_cmpx_eq_u32_e32 7, v1                                    // 0000000005DC: 7D940287
	s_cbranch_execz 20                                         // 0000000005E0: BFA50014 <attn_prep_24_4_256_64_8204_11_k4jv4+0x634>
	s_lshl_b64 s[34:35], s[28:29], 2                           // 0000000005E4: 84A2821C
	v_lshlrev_b32_e32 v2, 5, v4                                // 0000000005E8: 30040885
	s_waitcnt lgkmcnt(0)                                       // 0000000005EC: BF89FC07
	s_add_u32 s10, s10, s34                                    // 0000000005F0: 800A220A
	s_addc_u32 s11, s11, s35                                   // 0000000005F4: 820B230B
	s_lshl_b32 s31, s30, 10                                    // 0000000005F8: 841F8A1E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000005FC: BF870009
	s_add_u32 s10, s10, s31                                    // 000000000600: 800A1F0A
	s_addc_u32 s11, s11, 0                                     // 000000000604: 820B800B
	s_clause 0x1                                               // 000000000608: BF850001
	global_load_b128 v[5:8], v2, s[10:11]                      // 00000000060C: DC5E0000 050A0002
	global_load_b128 v[9:12], v2, s[10:11] offset:16           // 000000000614: DC5E0010 090A0002
	s_waitcnt vmcnt(1)                                         // 00000000061C: BF8907F7
	ds_store_b128 v2, v[5:8] offset:13312                      // 000000000620: DB7C3400 00000502
	s_waitcnt vmcnt(0)                                         // 000000000628: BF8903F7
	ds_store_b128 v2, v[9:12] offset:13328                     // 00000000062C: DB7C3410 00000902
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000634: 8C7E0D7E
	s_waitcnt lgkmcnt(0)                                       // 000000000638: BF89FC07
	s_and_not1_saveexec_b32 s10, s1                            // 00000000063C: BE8A3001
	s_cbranch_execz 137                                        // 000000000640: BFA50089 <attn_prep_24_4_256_64_8204_11_k4jv4+0x868>
	s_mov_b32 s11, exec_lo                                     // 000000000644: BE8B007E
	v_cmpx_eq_u32_e32 6, v1                                    // 000000000648: 7D940286
	s_cbranch_execz 133                                        // 00000000064C: BFA50085 <attn_prep_24_4_256_64_8204_11_k4jv4+0x864>
	s_lshl_b64 s[28:29], s[28:29], 2                           // 000000000650: 849C821C
	v_lshlrev_b32_e32 v2, 5, v4                                // 000000000654: 30040885
	s_add_u32 s1, s8, s28                                      // 000000000658: 80011C08
	s_addc_u32 s9, s9, s29                                     // 00000000065C: 82091D09
	s_lshl_b32 s8, s30, 10                                     // 000000000660: 84088A1E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000664: BF870009
	s_add_u32 s8, s1, s8                                       // 000000000668: 80080801
	s_addc_u32 s9, s9, 0                                       // 00000000066C: 82098009
	s_clause 0x3                                               // 000000000670: BF850003
	global_load_b128 v[5:8], v2, s[8:9]                        // 000000000674: DC5E0000 05080002
	global_load_b128 v[9:12], v2, s[8:9] offset:16             // 00000000067C: DC5E0010 09080002
	global_load_b128 v[13:16], v2, s[26:27]                    // 000000000684: DC5E0000 0D1A0002
	global_load_b128 v[17:20], v2, s[26:27] offset:16          // 00000000068C: DC5E0010 111A0002
	s_waitcnt vmcnt(3)                                         // 000000000694: BF890FF7
	v_mul_f32_e32 v3, v6, v6                                   // 000000000698: 10060D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000069C: BF870091
	v_fmac_f32_e32 v3, v5, v5                                  // 0000000006A0: 56060B05
	v_fmac_f32_e32 v3, v7, v7                                  // 0000000006A4: 56060F07
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000006A8: BF8700A1
	v_fmac_f32_e32 v3, v8, v8                                  // 0000000006AC: 56061108
	s_waitcnt vmcnt(2)                                         // 0000000006B0: BF890BF7
	v_fmac_f32_e32 v3, v9, v9                                  // 0000000006B4: 56061309
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006B8: BF870091
	v_fmac_f32_e32 v3, v10, v10                                // 0000000006BC: 5606150A
	v_fmac_f32_e32 v3, v11, v11                                // 0000000006C0: 5606170B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006C4: BF870091
	v_fmac_f32_e32 v3, v12, v12                                // 0000000006C8: 5606190C
	v_add_f32_dpp v3, v3, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006CC: 060606FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006D4: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006D8: 060606FA FF091203
	v_add_f32_dpp v3, v3, v3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006E0: 060606FA FF091403
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006E8: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006EC: 060606FA FF091803
	v_readlane_b32 s1, v3, 15                                  // 0000000006F4: D7600001 00011F03
	v_readlane_b32 s8, v3, 31                                  // 0000000006FC: D7600008 00013F03
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000704: BF870001
	v_add_f32_e64 v3, s1, s8                                   // 000000000708: D5030003 00001001
	s_mov_b32 s1, 0x3b800000                                   // 000000000710: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 000000000718: BF870481
	v_fmaak_f32 v3, s1, v3, 0x358637bd                         // 00000000071C: 5A060601 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000724: BF870121
	v_mul_f32_e32 v21, 0x4f800000, v3                          // 000000000728: 102A06FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v3                     // 000000000730: 7C2806FF 0F800000
	v_cndmask_b32_e32 v3, v3, v21, vcc_lo                      // 000000000738: 02062B03
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 00000000073C: BF870141
	v_sqrt_f32_e32 v21, v3                                     // 000000000740: 7E2A6703
	s_waitcnt_depctr 0xfff                                     // 000000000744: BF880FFF
	v_add_nc_u32_e32 v22, -1, v21                              // 000000000748: 4A2C2AC1
	v_add_nc_u32_e32 v23, 1, v21                               // 00000000074C: 4A2E2A81
	v_fma_f32 v24, -v22, v21, v3                               // 000000000750: D6130018 240E2B16
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000758: BF870112
	v_fma_f32 v25, -v23, v21, v3                               // 00000000075C: D6130019 240E2B17
	v_cmp_ge_f32_e64 s1, 0, v24                                // 000000000764: D4160001 00023080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000076C: BF870191
	v_cndmask_b32_e64 v21, v21, v22, s1                        // 000000000770: D5010015 00062D15
	v_cmp_lt_f32_e64 s1, 0, v25                                // 000000000778: D4110001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000780: BF870091
	v_cndmask_b32_e64 v21, v21, v23, s1                        // 000000000784: D5010015 00062F15
	v_mul_f32_e32 v22, 0x37800000, v21                         // 00000000078C: 102C2AFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000794: BF870121
	v_cndmask_b32_e32 v21, v21, v22, vcc_lo                    // 000000000798: 022A2D15
	v_cmp_class_f32_e64 vcc_lo, v3, 0x260                      // 00000000079C: D47E006A 0001FF03 00000260
	v_cndmask_b32_e32 v3, v21, v3, vcc_lo                      // 0000000007A8: 02060715
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000007AC: BF870121
	v_div_scale_f32 v21, null, v3, v3, 1.0                     // 0000000007B0: D6FC7C15 03CA0703
	v_div_scale_f32 v24, vcc_lo, 1.0, v3, 1.0                  // 0000000007B8: D6FC6A18 03CA06F2
	v_rcp_f32_e32 v22, v21                                     // 0000000007C0: 7E2C5515
	s_waitcnt_depctr 0xfff                                     // 0000000007C4: BF880FFF
	v_fma_f32 v23, -v21, v22, 1.0                              // 0000000007C8: D6130017 23CA2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007D0: BF870091
	v_fmac_f32_e32 v22, v23, v22                               // 0000000007D4: 562C2D17
	v_mul_f32_e32 v23, v24, v22                                // 0000000007D8: 102E2D18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007DC: BF870091
	v_fma_f32 v25, -v21, v23, v24                              // 0000000007E0: D6130019 24622F15
	v_fmac_f32_e32 v23, v25, v22                               // 0000000007E8: 562E2D19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007EC: BF870091
	v_fma_f32 v21, -v21, v23, v24                              // 0000000007F0: D6130015 24622F15
	v_div_fmas_f32 v21, v21, v22, v23                          // 0000000007F8: D6370015 045E2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000800: BF870091
	v_div_fixup_f32 v3, v21, v3, 1.0                           // 000000000804: D6270003 03CA0715
	v_mul_f32_e32 v10, v10, v3                                 // 00000000080C: 1014070A
	v_mul_f32_e32 v5, v5, v3                                   // 000000000810: 100A0705
	v_mul_f32_e32 v6, v6, v3                                   // 000000000814: 100C0706
	v_mul_f32_e32 v7, v7, v3                                   // 000000000818: 100E0707
	v_mul_f32_e32 v8, v8, v3                                   // 00000000081C: 10100708
	v_mul_f32_e32 v9, v9, v3                                   // 000000000820: 10120709
	v_mul_f32_e32 v11, v11, v3                                 // 000000000824: 1016070B
	v_mul_f32_e32 v3, v12, v3                                  // 000000000828: 1006070C
	s_waitcnt vmcnt(1)                                         // 00000000082C: BF8907F7
	v_dual_mul_f32 v5, v13, v5 :: v_dual_mul_f32 v6, v14, v6   // 000000000830: C8C60B0D 05060D0E
	v_dual_mul_f32 v7, v15, v7 :: v_dual_mul_f32 v8, v8, v16   // 000000000838: C8C60F0F 07082108
	s_waitcnt vmcnt(0)                                         // 000000000840: BF8903F7
	v_dual_mul_f32 v9, v9, v17 :: v_dual_mul_f32 v10, v10, v18 // 000000000844: C8C62309 090A250A
	v_mul_f32_e32 v11, v11, v19                                // 00000000084C: 1016270B
	v_mul_f32_e32 v12, v3, v20                                 // 000000000850: 10182903
	ds_store_b128 v2, v[5:8] offset:12288                      // 000000000854: DB7C3000 00000502
	ds_store_b128 v2, v[9:12] offset:12304                     // 00000000085C: DB7C3010 00000902
	s_or_b32 exec_lo, exec_lo, s11                             // 000000000864: 8C7E0B7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000868: BF870009
	s_or_b32 exec_lo, exec_lo, s10                             // 00000000086C: 8C7E0A7E
	s_waitcnt lgkmcnt(0)                                       // 000000000870: BF89FC07
	s_or_saveexec_b32 s8, s15                                  // 000000000874: BE88220F
	v_lshlrev_b32_e32 v2, 5, v4                                // 000000000878: 30040885
	s_xor_b32 exec_lo, exec_lo, s8                             // 00000000087C: 8D7E087E
	s_cbranch_execz 159                                        // 000000000880: BFA5009F <attn_prep_24_4_256_64_8204_11_k4jv4+0xb00>
	s_mul_i32 s1, s30, 6                                       // 000000000884: 9601861E
	s_mul_i32 s9, s12, 0xc000                                  // 000000000888: 9609FF0C 0000C000
	v_add_lshl_u32 v3, s1, v1, 11                              // 000000000890: D6470003 022E0201
	s_mul_hi_u32 s1, s12, 0xc000                               // 000000000898: 9681FF0C 0000C000
	s_add_u32 s6, s6, s9                                       // 0000000008A0: 80060906
	s_addc_u32 s1, s7, s1                                      // 0000000008A4: 82010107
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008A8: BF870091
	v_add_co_u32 v3, s6, s6, v3                                // 0000000008AC: D7000603 00020606
	v_add_co_ci_u32_e64 v5, null, s1, 0, s6                    // 0000000008B4: D5207C05 00190001
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000008BC: BF870112
	v_add_co_u32 v9, vcc_lo, v3, v2                            // 0000000008C0: D7006A09 00020503
	v_add_co_ci_u32_e32 v10, vcc_lo, 0, v5, vcc_lo             // 0000000008C8: 40140A80
	s_clause 0x1                                               // 0000000008CC: BF850001
	global_load_b128 v[5:8], v[9:10], off                      // 0000000008D0: DC5E0000 057C0009
	global_load_b128 v[9:12], v[9:10], off offset:16           // 0000000008D8: DC5E0010 097C0009
	s_clause 0x1                                               // 0000000008E0: BF850001
	global_load_b128 v[13:16], v2, s[24:25]                    // 0000000008E4: DC5E0000 0D180002
	global_load_b128 v[17:20], v2, s[24:25] offset:16          // 0000000008EC: DC5E0010 11180002
	s_waitcnt vmcnt(3)                                         // 0000000008F4: BF890FF7
	v_mul_f32_e32 v3, v6, v6                                   // 0000000008F8: 10060D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008FC: BF870091
	v_fmac_f32_e32 v3, v5, v5                                  // 000000000900: 56060B05
	v_fmac_f32_e32 v3, v7, v7                                  // 000000000904: 56060F07
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000908: BF8700A1
	v_fmac_f32_e32 v3, v8, v8                                  // 00000000090C: 56061108
	s_waitcnt vmcnt(2)                                         // 000000000910: BF890BF7
	v_fmac_f32_e32 v3, v9, v9                                  // 000000000914: 56061309
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000918: BF870091
	v_fmac_f32_e32 v3, v10, v10                                // 00000000091C: 5606150A
	v_fmac_f32_e32 v3, v11, v11                                // 000000000920: 5606170B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000924: BF870091
	v_fmac_f32_e32 v3, v12, v12                                // 000000000928: 5606190C
	v_add_f32_dpp v3, v3, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000092C: 060606FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000934: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000938: 060606FA FF091203
	v_add_f32_dpp v3, v3, v3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000940: 060606FA FF091403
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000948: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000094C: 060606FA FF091803
	v_readlane_b32 s1, v3, 15                                  // 000000000954: D7600001 00011F03
	v_readlane_b32 s6, v3, 31                                  // 00000000095C: D7600006 00013F03
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000964: BF870001
	v_add_f32_e64 v3, s1, s6                                   // 000000000968: D5030003 00000C01
	s_mov_b32 s1, 0x3b800000                                   // 000000000970: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 000000000978: BF870481
	v_fmaak_f32 v3, s1, v3, 0x358637bd                         // 00000000097C: 5A060601 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000984: BF870121
	v_mul_f32_e32 v21, 0x4f800000, v3                          // 000000000988: 102A06FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v3                     // 000000000990: 7C2806FF 0F800000
	v_cndmask_b32_e32 v3, v3, v21, vcc_lo                      // 000000000998: 02062B03
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 00000000099C: BF870141
	v_sqrt_f32_e32 v21, v3                                     // 0000000009A0: 7E2A6703
	s_waitcnt_depctr 0xfff                                     // 0000000009A4: BF880FFF
	v_add_nc_u32_e32 v22, -1, v21                              // 0000000009A8: 4A2C2AC1
	v_add_nc_u32_e32 v23, 1, v21                               // 0000000009AC: 4A2E2A81
	v_fma_f32 v24, -v22, v21, v3                               // 0000000009B0: D6130018 240E2B16
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000009B8: BF870112
	v_fma_f32 v25, -v23, v21, v3                               // 0000000009BC: D6130019 240E2B17
	v_cmp_ge_f32_e64 s1, 0, v24                                // 0000000009C4: D4160001 00023080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000009CC: BF870191
	v_cndmask_b32_e64 v21, v21, v22, s1                        // 0000000009D0: D5010015 00062D15
	v_cmp_lt_f32_e64 s1, 0, v25                                // 0000000009D8: D4110001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009E0: BF870091
	v_cndmask_b32_e64 v21, v21, v23, s1                        // 0000000009E4: D5010015 00062F15
	v_mul_f32_e32 v22, 0x37800000, v21                         // 0000000009EC: 102C2AFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000009F4: BF870121
	v_cndmask_b32_e32 v21, v21, v22, vcc_lo                    // 0000000009F8: 022A2D15
	v_cmp_class_f32_e64 vcc_lo, v3, 0x260                      // 0000000009FC: D47E006A 0001FF03 00000260
	v_cndmask_b32_e32 v3, v21, v3, vcc_lo                      // 000000000A08: 02060715
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000A0C: BF870121
	v_div_scale_f32 v21, null, v3, v3, 1.0                     // 000000000A10: D6FC7C15 03CA0703
	v_div_scale_f32 v24, vcc_lo, 1.0, v3, 1.0                  // 000000000A18: D6FC6A18 03CA06F2
	v_rcp_f32_e32 v22, v21                                     // 000000000A20: 7E2C5515
	s_waitcnt_depctr 0xfff                                     // 000000000A24: BF880FFF
	v_fma_f32 v23, -v21, v22, 1.0                              // 000000000A28: D6130017 23CA2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A30: BF870091
	v_fmac_f32_e32 v22, v23, v22                               // 000000000A34: 562C2D17
	v_mul_f32_e32 v23, v24, v22                                // 000000000A38: 102E2D18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A3C: BF870091
	v_fma_f32 v25, -v21, v23, v24                              // 000000000A40: D6130019 24622F15
	v_fmac_f32_e32 v23, v25, v22                               // 000000000A48: 562E2D19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A4C: BF870091
	v_fma_f32 v21, -v21, v23, v24                              // 000000000A50: D6130015 24622F15
	v_div_fmas_f32 v21, v21, v22, v23                          // 000000000A58: D6370015 045E2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000A60: BF870121
	v_div_fixup_f32 v3, v21, v3, 1.0                           // 000000000A64: D6270003 03CA0715
	v_lshl_or_b32 v21, v1, 10, v2                              // 000000000A6C: D6560015 04091501
	v_mul_f32_e32 v5, v5, v3                                   // 000000000A74: 100A0705
	v_mul_f32_e32 v6, v6, v3                                   // 000000000A78: 100C0706
	v_mul_f32_e32 v7, v7, v3                                   // 000000000A7C: 100E0707
	v_mul_f32_e32 v8, v8, v3                                   // 000000000A80: 10100708
	v_mul_f32_e32 v9, v9, v3                                   // 000000000A84: 10120709
	v_mul_f32_e32 v10, v10, v3                                 // 000000000A88: 1014070A
	v_mul_f32_e32 v11, v11, v3                                 // 000000000A8C: 1016070B
	v_mul_f32_e32 v3, v12, v3                                  // 000000000A90: 1006070C
	s_waitcnt vmcnt(1)                                         // 000000000A94: BF8907F7
	v_dual_mul_f32 v5, v13, v5 :: v_dual_mul_f32 v6, v14, v6   // 000000000A98: C8C60B0D 05060D0E
	v_dual_mul_f32 v7, v15, v7 :: v_dual_mul_f32 v8, v8, v16   // 000000000AA0: C8C60F0F 07082108
	s_waitcnt vmcnt(0)                                         // 000000000AA8: BF8903F7
	v_dual_mul_f32 v9, v9, v17 :: v_dual_mul_f32 v10, v10, v18 // 000000000AAC: C8C62309 090A250A
	v_mul_f32_e32 v11, v11, v19                                // 000000000AB4: 1016270B
	v_mul_f32_e32 v3, v3, v20                                  // 000000000AB8: 10062903
	v_dual_mul_f32 v5, 0x3d800000, v5 :: v_dual_mul_f32 v6, 0x3d800000, v6// 000000000ABC: C8C60AFF 05060CFF 3D800000
	v_dual_mul_f32 v7, 0x3d800000, v7 :: v_dual_mul_f32 v8, 0x3d800000, v8// 000000000AC8: C8C60EFF 070810FF 3D800000
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000AD4: BF870003
	v_dual_mul_f32 v12, 0x3d800000, v3 :: v_dual_mul_f32 v9, 0x3d800000, v9// 000000000AD8: C8C606FF 0C0812FF 3D800000
	v_dual_mul_f32 v10, 0x3d800000, v10 :: v_dual_mul_f32 v11, 0x3d800000, v11// 000000000AE4: C8C614FF 0A0A16FF 3D800000
	ds_store_b128 v21, v[5:8]                                  // 000000000AF0: DB7C0000 00000515
	ds_store_b128 v21, v[9:12] offset:16                       // 000000000AF8: DB7C0010 00000915
	s_or_b32 exec_lo, exec_lo, s8                              // 000000000B00: 8C7E087E
	s_ashr_i32 s15, s14, 31                                    // 000000000B04: 860F9F0E
	v_and_b32_e32 v6, 31, v0                                   // 000000000B08: 360C009F
	s_lshl_b64 s[6:7], s[14:15], 8                             // 000000000B0C: 8486880E
	s_waitcnt lgkmcnt(0)                                       // 000000000B10: BF89FC07
	s_add_u32 s6, s2, s6                                       // 000000000B14: 80060602
	s_addc_u32 s7, s3, s7                                      // 000000000B18: 82070703
	s_barrier                                                  // 000000000B1C: BFBD0000
	buffer_gl0_inv                                             // 000000000B20: E0AC0000 00000000
	s_and_saveexec_b32 s1, s0                                  // 000000000B28: BE812000
	s_cbranch_execz 25                                         // 000000000B2C: BFA50019 <attn_prep_24_4_256_64_8204_11_k4jv4+0xb94>
	v_lshlrev_b32_e32 v3, 2, v6                                // 000000000B30: 30060C82
	s_clause 0x1                                               // 000000000B34: BF850001
	global_load_b32 v5, v3, s[6:7] offset:128                  // 000000000B38: DC520080 05060003
	global_load_b32 v9, v3, s[6:7]                             // 000000000B40: DC520000 09060003
	v_lshl_or_b32 v7, v1, 10, v3                               // 000000000B48: D6560007 040D1501
	ds_load_2addr_b32 v[7:8], v7 offset1:32                    // 000000000B50: D8DC2000 07000007
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000B58: BF890407
	v_mul_f32_e32 v10, v5, v8                                  // 000000000B5C: 10141105
	v_mul_f32_e32 v5, v5, v7                                   // 000000000B60: 100A0F05
	v_lshl_or_b32 v3, v1, 8, v3                                // 000000000B64: D6560003 040D1101
	s_waitcnt vmcnt(0)                                         // 000000000B6C: BF8903F7
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000B70: BF870193
	v_fma_f32 v7, v9, v7, -v10                                 // 000000000B74: D6130007 842A0F09
	v_fmac_f32_e32 v5, v9, v8                                  // 000000000B7C: 560A1109
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000B80: BF870003
	v_add_nc_u32_e32 v3, 0x3800, v3                            // 000000000B84: 4A0606FF 00003800
	ds_store_2addr_b32 v3, v7, v5 offset1:32                   // 000000000B8C: D8382000 00050703
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000B94: 8C7E017E
	v_cmp_gt_u32_e64 s2, 32, v0                                // 000000000B98: D44C0002 000200A0
	v_dual_mov_b32 v5, 0 :: v_dual_mov_b32 v8, 0               // 000000000BA0: CA100080 05080080
	v_lshlrev_b32_e32 v3, 2, v0                                // 000000000BA8: 30060082
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000BAC: BF870003
	s_and_saveexec_b32 s1, s2                                  // 000000000BB0: BE812002
	s_cbranch_execz 17                                         // 000000000BB4: BFA50011 <attn_prep_24_4_256_64_8204_11_k4jv4+0xbfc>
	s_clause 0x1                                               // 000000000BB8: BF850001
	global_load_b32 v9, v3, s[6:7] offset:128                  // 000000000BBC: DC520080 09060003
	global_load_b32 v10, v3, s[6:7]                            // 000000000BC4: DC520000 0A060003
	v_add_nc_u32_e32 v5, 0x3000, v3                            // 000000000BCC: 4A0A06FF 00003000
	ds_load_2addr_b32 v[7:8], v5 offset1:32                    // 000000000BD4: D8DC2000 07000005
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000BDC: BF890407
	v_mul_f32_e32 v11, v9, v8                                  // 000000000BE0: 10161109
	s_waitcnt vmcnt(0)                                         // 000000000BE4: BF8903F7
	v_mul_f32_e32 v5, v10, v8                                  // 000000000BE8: 100A110A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000BEC: BF870112
	v_fma_f32 v8, v10, v7, -v11                                // 000000000BF0: D6130008 842E0F0A
	v_fmac_f32_e32 v5, v9, v7                                  // 000000000BF8: 560A0F09
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000BFC: 8C7E017E
	v_and_b32_e32 v7, 63, v0                                   // 000000000C00: 360E00BF
	v_or_b32_e32 v13, 0xffffff00, v0                           // 000000000C04: 381A00FF FFFFFF00
	s_mov_b32 s1, exec_lo                                      // 000000000C0C: BE81007E
	s_waitcnt lgkmcnt(0)                                       // 000000000C10: BF89FC07
	s_barrier                                                  // 000000000C14: BFBD0000
	buffer_gl0_inv                                             // 000000000C18: E0AC0000 00000000
	v_cmpx_gt_u32_e32 0x180, v0                                // 000000000C20: 7D9800FF 00000180
	s_cbranch_execz 30                                         // 000000000C28: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0xca4>
	v_lshrrev_b32_e32 v10, 6, v0                               // 000000000C2C: 32140086
	v_lshlrev_b32_e32 v11, 2, v7                               // 000000000C30: 30160E82
	v_or_b32_e32 v9, 0xffffff00, v0                            // 000000000C34: 381200FF FFFFFF00
	s_mov_b32 s3, 0                                            // 000000000C3C: BE830080
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000C40: BF870193
	v_lshlrev_b32_e32 v12, 8, v10                              // 000000000C44: 30181488
	v_lshl_or_b32 v10, v10, 10, v11                            // 000000000C48: D656000A 042D150A
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000C50: BF870002
	v_or3_b32 v11, v12, v11, 0x3800                            // 000000000C54: D658000B 03FE170C 00003800
	ds_load_b32 v12, v11                                       // 000000000C60: D8D80000 0C00000B
	v_add_nc_u32_e32 v9, 0x100, v9                             // 000000000C68: 4A1212FF 00000100
	v_add_nc_u32_e32 v11, 0x400, v11                           // 000000000C70: 4A1616FF 00000400
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000C78: BF870002
	v_cmp_lt_u32_e32 vcc_lo, 0x7f, v9                          // 000000000C7C: 7C9212FF 0000007F
	s_or_b32 s3, vcc_lo, s3                                    // 000000000C84: 8C03036A
	s_waitcnt lgkmcnt(0)                                       // 000000000C88: BF89FC07
	ds_store_b32 v10, v12                                      // 000000000C8C: D8340000 00000C0A
	v_add_nc_u32_e32 v10, 0x1000, v10                          // 000000000C94: 4A1414FF 00001000
	s_and_not1_b32 exec_lo, exec_lo, s3                        // 000000000C9C: 917E037E
	s_cbranch_execnz 65519                                     // 000000000CA0: BFA6FFEF <attn_prep_24_4_256_64_8204_11_k4jv4+0xc60>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000CA4: 8C7E017E
	s_and_saveexec_b32 s1, s2                                  // 000000000CA8: BE812002
	v_add_nc_u32_e32 v9, 0x3000, v3                            // 000000000CAC: 4A1206FF 00003000
	ds_store_2addr_b32 v9, v8, v5 offset1:32                   // 000000000CB4: D8382000 00050809
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000CBC: 8C7E017E
	v_xor_b32_e32 v5, 0x1234567, v0                            // 000000000CC0: 3A0A00FF 01234567
	v_xor_b32_e32 v8, 0x7654321, v0                            // 000000000CC8: 3A1000FF 07654321
	s_mov_b32 s6, 0                                            // 000000000CD0: BE860080
	s_waitcnt lgkmcnt(0)                                       // 000000000CD4: BF89FC07
	s_barrier                                                  // 000000000CD8: BFBD0000
	v_mul_lo_u32 v5, 0x9e3779b1, v5                            // 000000000CDC: D72C0005 00020AFF 9E3779B1
	v_mul_lo_u32 v8, 0x9e3779b1, v8                            // 000000000CE8: D72C0008 000210FF 9E3779B1
	buffer_gl0_inv                                             // 000000000CF4: E0AC0000 00000000
	v_bcnt_u32_b32 v5, v5, 0                                   // 000000000CFC: D71E0005 00010105
	v_bcnt_u32_b32 v8, v8, 0                                   // 000000000D04: D71E0008 00010108
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000D0C: BF870112
	v_and_b32_e32 v9, 1, v5                                    // 000000000D10: 36120A81
	v_and_b32_e32 v8, 1, v8                                    // 000000000D14: 36101081
	v_or_b32_e32 v5, 0xffffe800, v3                            // 000000000D18: 380A06FF FFFFE800
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000000D20: BF870223
	v_cmp_eq_u32_e32 vcc_lo, 0, v9                             // 000000000D24: 7C941280
	v_mov_b32_e32 v9, v13                                      // 000000000D28: 7E12030D
	v_cmp_eq_u32_e64 s1, 0, v8                                 // 000000000D2C: D44A0001 00021080
	s_set_inst_prefetch_distance 0x1                           // 000000000D34: BF840001
	s_branch 15                                                // 000000000D38: BFA0000F <attn_prep_24_4_256_64_8204_11_k4jv4+0xd78>
	s_nop 0                                                    // 000000000D3C: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000D40: 8C7E037E
	v_add_nc_u32_e32 v9, 0x100, v9                             // 000000000D44: 4A1212FF 00000100
	ds_store_b32 v5, v10 offset:6144                           // 000000000D4C: D8341800 00000A05
	v_add_nc_u32_e32 v5, 0x400, v5                             // 000000000D54: 4A0A0AFF 00000400
	v_cmp_lt_u32_e64 s3, 0xcff, v9                             // 000000000D5C: D4490003 000212FF 00000CFF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000D68: BF870491
	s_or_b32 s6, s3, s6                                        // 000000000D6C: 8C060603
	s_and_not1_b32 exec_lo, exec_lo, s6                        // 000000000D70: 917E067E
	s_cbranch_execz 23                                         // 000000000D74: BFA50017 <attn_prep_24_4_256_64_8204_11_k4jv4+0xdd4>
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000D78: BF870092
	v_add_nc_u32_e32 v10, 0xfffffb00, v9                       // 000000000D7C: 4A1412FF FFFFFB00
	v_cmp_lt_u32_e64 s3, 0x5ff, v10                            // 000000000D84: D4490003 000214FF 000005FF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000D90: BF870491
	s_and_saveexec_b32 s7, s3                                  // 000000000D94: BE872003
	s_xor_b32 s3, exec_lo, s7                                  // 000000000D98: 8D03077E
	s_cbranch_execz 5                                          // 000000000D9C: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0xdb4>
	ds_load_b32 v10, v5 offset:6144                            // 000000000DA0: D8D81800 0A000005
	s_waitcnt lgkmcnt(0)                                       // 000000000DA8: BF89FC07
	v_cndmask_b32_e64 v10, -v10, v10, vcc_lo                   // 000000000DAC: D501000A 21AA150A
	s_and_not1_saveexec_b32 s3, s3                             // 000000000DB4: BE833003
	s_cbranch_execz 65505                                      // 000000000DB8: BFA5FFE1 <attn_prep_24_4_256_64_8204_11_k4jv4+0xd40>
	ds_load_b32 v10, v5                                        // 000000000DBC: D8D80000 0A000005
	s_waitcnt lgkmcnt(0)                                       // 000000000DC4: BF89FC07
	v_cndmask_b32_e64 v10, -v10, v10, s1                       // 000000000DC8: D501000A 2006150A
	s_branch 65499                                             // 000000000DD0: BFA0FFDB <attn_prep_24_4_256_64_8204_11_k4jv4+0xd40>
	s_set_inst_prefetch_distance 0x2                           // 000000000DD4: BF840002
	s_or_b32 exec_lo, exec_lo, s6                              // 000000000DD8: 8C7E067E
	v_dual_mov_b32 v10, v13 :: v_dual_lshlrev_b32 v5, 1, v0    // 000000000DDC: CA22010D 0A040081
	s_mov_b32 s1, 0                                            // 000000000DE4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000DE8: BF89FC07
	s_barrier                                                  // 000000000DEC: BFBD0000
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000DF0: BF870001
	v_mov_b32_e32 v9, v5                                       // 000000000DF4: 7E120305
	buffer_gl0_inv                                             // 000000000DF8: E0AC0000 00000000
	v_lshlrev_b32_e32 v11, 2, v9                               // 000000000E00: 30161282
	v_add_nc_u32_e32 v10, 0x100, v10                           // 000000000E04: 4A1414FF 00000100
	v_add_nc_u32_e32 v9, 0x200, v9                             // 000000000E0C: 4A1212FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000E14: BF870193
	v_and_b32_e32 v16, 0x3ff8, v11                             // 000000000E18: 362016FF 00003FF8
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v10                        // 000000000E20: 7C9214FF 000005FF
	ds_load_b64 v[11:12], v16                                  // 000000000E28: D9D80000 0B000010
	s_or_b32 s1, vcc_lo, s1                                    // 000000000E30: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000E34: BF89FC07
	v_sub_f32_e32 v15, v11, v12                                // 000000000E38: 081E190B
	v_add_f32_e32 v14, v11, v12                                // 000000000E3C: 061C190B
	ds_store_b64 v16, v[14:15]                                 // 000000000E40: D9340000 00000E10
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000E48: 917E017E
	s_cbranch_execnz 65516                                     // 000000000E4C: BFA6FFEC <attn_prep_24_4_256_64_8204_11_k4jv4+0xe00>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000E50: 8C7E017E
	v_dual_mov_b32 v10, v5 :: v_dual_and_b32 v9, 1, v0         // 000000000E54: CA240105 0A080081
	v_mov_b32_e32 v11, v13                                     // 000000000E5C: 7E16030D
	s_mov_b32 s1, 0                                            // 000000000E60: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000E64: BF89FC07
	s_barrier                                                  // 000000000E68: BFBD0000
	buffer_gl0_inv                                             // 000000000E6C: E0AC0000 00000000
	s_nop 0                                                    // 000000000E74: BF800000
	s_nop 0                                                    // 000000000E78: BF800000
	s_nop 0                                                    // 000000000E7C: BF800000
	v_and_or_b32 v12, 0xffc, v10, v9                           // 000000000E80: D657000C 042614FF 00000FFC
	v_add_nc_u32_e32 v11, 0x100, v11                           // 000000000E8C: 4A1616FF 00000100
	v_add_nc_u32_e32 v10, 0x200, v10                           // 000000000E94: 4A1414FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000E9C: BF870193
	v_lshlrev_b32_e32 v12, 2, v12                              // 000000000EA0: 30181882
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v11                        // 000000000EA4: 7C9216FF 000005FF
	ds_load_2addr_b32 v[14:15], v12 offset1:2                  // 000000000EAC: D8DC0200 0E00000C
	s_or_b32 s1, vcc_lo, s1                                    // 000000000EB4: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000EB8: BF89FC07
	v_add_f32_e32 v16, v14, v15                                // 000000000EBC: 06201F0E
	v_sub_f32_e32 v14, v14, v15                                // 000000000EC0: 081C1F0E
	ds_store_2addr_b32 v12, v16, v14 offset1:2                 // 000000000EC4: D8380200 000E100C
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000ECC: 917E017E
	s_cbranch_execnz 65515                                     // 000000000ED0: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xe80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000ED4: 8C7E017E
	v_dual_mov_b32 v11, v5 :: v_dual_and_b32 v10, 3, v0        // 000000000ED8: CA240105 0B0A0083
	v_mov_b32_e32 v12, v13                                     // 000000000EE0: 7E18030D
	s_mov_b32 s1, 0                                            // 000000000EE4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000EE8: BF89FC07
	s_barrier                                                  // 000000000EEC: BFBD0000
	buffer_gl0_inv                                             // 000000000EF0: E0AC0000 00000000
	s_nop 0                                                    // 000000000EF8: BF800000
	s_nop 0                                                    // 000000000EFC: BF800000
	v_and_or_b32 v14, 0xff8, v11, v10                          // 000000000F00: D657000E 042A16FF 00000FF8
	v_add_nc_u32_e32 v12, 0x100, v12                           // 000000000F0C: 4A1818FF 00000100
	v_add_nc_u32_e32 v11, 0x200, v11                           // 000000000F14: 4A1616FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000F1C: BF870193
	v_lshlrev_b32_e32 v16, 2, v14                              // 000000000F20: 30201C82
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v12                        // 000000000F24: 7C9218FF 000005FF
	ds_load_2addr_b32 v[14:15], v16 offset1:4                  // 000000000F2C: D8DC0400 0E000010
	s_or_b32 s1, vcc_lo, s1                                    // 000000000F34: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000F38: BF89FC07
	v_add_f32_e32 v17, v14, v15                                // 000000000F3C: 06221F0E
	v_sub_f32_e32 v14, v14, v15                                // 000000000F40: 081C1F0E
	ds_store_2addr_b32 v16, v17, v14 offset1:4                 // 000000000F44: D8380400 000E1110
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000F4C: 917E017E
	s_cbranch_execnz 65515                                     // 000000000F50: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xf00>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000F54: 8C7E017E
	v_dual_mov_b32 v12, v5 :: v_dual_and_b32 v11, 7, v0        // 000000000F58: CA240105 0C0A0087
	v_mov_b32_e32 v14, v13                                     // 000000000F60: 7E1C030D
	s_mov_b32 s1, 0                                            // 000000000F64: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000F68: BF89FC07
	s_barrier                                                  // 000000000F6C: BFBD0000
	buffer_gl0_inv                                             // 000000000F70: E0AC0000 00000000
	s_nop 0                                                    // 000000000F78: BF800000
	s_nop 0                                                    // 000000000F7C: BF800000
	v_and_or_b32 v15, 0xff0, v12, v11                          // 000000000F80: D657000F 042E18FF 00000FF0
	v_add_nc_u32_e32 v12, 0x200, v12                           // 000000000F8C: 4A1818FF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000F94: BF870002
	v_lshlrev_b32_e32 v17, 2, v15                              // 000000000F98: 30221E82
	ds_load_2addr_b32 v[15:16], v17 offset1:8                  // 000000000F9C: D8DC0800 0F000011
	v_add_nc_u32_e32 v14, 0x100, v14                           // 000000000FA4: 4A1C1CFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 000000000FAC: BF89FC07
	v_add_f32_e32 v18, v15, v16                                // 000000000FB0: 0624210F
	v_sub_f32_e32 v15, v15, v16                                // 000000000FB4: 081E210F
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000000FB8: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v14                        // 000000000FBC: 7C921CFF 000005FF
	ds_store_2addr_b32 v17, v18, v15 offset1:8                 // 000000000FC4: D8380800 000F1211
	s_or_b32 s1, vcc_lo, s1                                    // 000000000FCC: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000FD0: 917E017E
	s_cbranch_execnz 65514                                     // 000000000FD4: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0xf80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000FD8: 8C7E017E
	v_dual_mov_b32 v15, v13 :: v_dual_and_b32 v12, 15, v0      // 000000000FDC: CA24010D 0F0C008F
	v_mov_b32_e32 v14, v5                                      // 000000000FE4: 7E1C0305
	s_mov_b32 s1, 0                                            // 000000000FE8: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000FEC: BF89FC07
	s_barrier                                                  // 000000000FF0: BFBD0000
	buffer_gl0_inv                                             // 000000000FF4: E0AC0000 00000000
	s_nop 0                                                    // 000000000FFC: BF800000
	v_and_or_b32 v16, 0xfe0, v14, v12                          // 000000001000: D6570010 04321CFF 00000FE0
	v_add_nc_u32_e32 v14, 0x200, v14                           // 00000000100C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001014: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000001018: 30242082
	ds_load_2addr_b32 v[16:17], v18 offset1:16                 // 00000000101C: D8DC1000 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 000000001024: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 00000000102C: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 000000001030: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 000000001034: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000001038: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 00000000103C: 7C921EFF 000005FF
	ds_store_2addr_b32 v18, v19, v16 offset1:16                // 000000001044: D8381000 00101312
	s_or_b32 s1, vcc_lo, s1                                    // 00000000104C: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000001050: 917E017E
	s_cbranch_execnz 65514                                     // 000000001054: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1000>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001058: 8C7E017E
	v_mov_b32_e32 v14, v5                                      // 00000000105C: 7E1C0305
	v_mov_b32_e32 v15, v13                                     // 000000001060: 7E1E030D
	s_mov_b32 s1, 0                                            // 000000001064: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001068: BF89FC07
	s_barrier                                                  // 00000000106C: BFBD0000
	buffer_gl0_inv                                             // 000000001070: E0AC0000 00000000
	s_nop 0                                                    // 000000001078: BF800000
	s_nop 0                                                    // 00000000107C: BF800000
	v_and_or_b32 v16, 0xfc0, v14, v6                           // 000000001080: D6570010 041A1CFF 00000FC0
	v_add_nc_u32_e32 v14, 0x200, v14                           // 00000000108C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001094: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000001098: 30242082
	ds_load_2addr_b32 v[16:17], v18 offset1:32                 // 00000000109C: D8DC2000 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 0000000010A4: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 0000000010AC: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 0000000010B0: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 0000000010B4: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 0000000010B8: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 0000000010BC: 7C921EFF 000005FF
	ds_store_2addr_b32 v18, v19, v16 offset1:32                // 0000000010C4: D8382000 00101312
	s_or_b32 s1, vcc_lo, s1                                    // 0000000010CC: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 0000000010D0: 917E017E
	s_cbranch_execnz 65514                                     // 0000000010D4: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1080>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000010D8: 8C7E017E
	v_mov_b32_e32 v14, v5                                      // 0000000010DC: 7E1C0305
	v_mov_b32_e32 v15, v13                                     // 0000000010E0: 7E1E030D
	s_mov_b32 s1, 0                                            // 0000000010E4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 0000000010E8: BF89FC07
	s_barrier                                                  // 0000000010EC: BFBD0000
	buffer_gl0_inv                                             // 0000000010F0: E0AC0000 00000000
	s_nop 0                                                    // 0000000010F8: BF800000
	s_nop 0                                                    // 0000000010FC: BF800000
	v_and_or_b32 v16, 0xf80, v14, v7                           // 000000001100: D6570010 041E1CFF 00000F80
	v_add_nc_u32_e32 v14, 0x200, v14                           // 00000000110C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001114: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000001118: 30242082
	ds_load_2addr_stride64_b32 v[16:17], v18 offset1:1         // 00000000111C: D8E00100 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 000000001124: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 00000000112C: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 000000001130: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 000000001134: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000001138: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 00000000113C: 7C921EFF 000005FF
	ds_store_2addr_stride64_b32 v18, v19, v16 offset1:1        // 000000001144: D83C0100 00101312
	s_or_b32 s1, vcc_lo, s1                                    // 00000000114C: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000001150: 917E017E
	s_cbranch_execnz 65514                                     // 000000001154: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1100>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001158: 8C7E017E
	v_dual_mov_b32 v15, v5 :: v_dual_and_b32 v14, 0x7f, v0     // 00000000115C: CA240105 0F0E00FF 0000007F
	v_mov_b32_e32 v16, v13                                     // 000000001168: 7E20030D
	s_mov_b32 s1, 0                                            // 00000000116C: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001170: BF89FC07
	s_barrier                                                  // 000000001174: BFBD0000
	buffer_gl0_inv                                             // 000000001178: E0AC0000 00000000
	v_and_or_b32 v17, 0xf00, v15, v14                          // 000000001180: D6570011 043A1EFF 00000F00
	v_add_nc_u32_e32 v15, 0x200, v15                           // 00000000118C: 4A1E1EFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001194: BF870002
	v_lshlrev_b32_e32 v19, 2, v17                              // 000000001198: 30262282
	ds_load_2addr_stride64_b32 v[17:18], v19 offset1:2         // 00000000119C: D8E00200 11000013
	v_add_nc_u32_e32 v16, 0x100, v16                           // 0000000011A4: 4A2020FF 00000100
	s_waitcnt lgkmcnt(0)                                       // 0000000011AC: BF89FC07
	v_add_f32_e32 v20, v17, v18                                // 0000000011B0: 06282511
	v_sub_f32_e32 v17, v17, v18                                // 0000000011B4: 08222511
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 0000000011B8: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v16                        // 0000000011BC: 7C9220FF 000005FF
	ds_store_2addr_stride64_b32 v19, v20, v17 offset1:2        // 0000000011C4: D83C0200 00111413
	s_or_b32 s1, vcc_lo, s1                                    // 0000000011CC: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 0000000011D0: 917E017E
	s_cbranch_execnz 65514                                     // 0000000011D4: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1180>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000011D8: 8C7E017E
	v_mov_b32_e32 v14, v3                                      // 0000000011DC: 7E1C0303
	s_mov_b32 s1, 0                                            // 0000000011E0: BE810080
	s_waitcnt lgkmcnt(0)                                       // 0000000011E4: BF89FC07
	s_barrier                                                  // 0000000011E8: BFBD0000
	buffer_gl0_inv                                             // 0000000011EC: E0AC0000 00000000
	s_branch 13                                                // 0000000011F4: BFA0000D <attn_prep_24_4_256_64_8204_11_k4jv4+0x122c>
	s_nop 0                                                    // 0000000011F8: BF800000
	s_nop 0                                                    // 0000000011FC: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000001200: 8C7E037E
	v_add_nc_u32_e32 v13, 0x100, v13                           // 000000001204: 4A1A1AFF 00000100
	v_add_nc_u32_e32 v14, 0x400, v14                           // 00000000120C: 4A1C1CFF 00000400
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001214: BF8704A2
	v_cmp_lt_u32_e32 vcc_lo, 0xcff, v13                        // 000000001218: 7C921AFF 00000CFF
	s_or_b32 s1, vcc_lo, s1                                    // 000000001220: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000001224: 917E017E
	s_cbranch_execz 15                                         // 000000001228: BFA5000F <attn_prep_24_4_256_64_8204_11_k4jv4+0x1268>
	v_add_nc_u32_e32 v15, 0xfffff500, v13                      // 00000000122C: 4A1E1AFF FFFFF500
	s_mov_b32 s3, exec_lo                                      // 000000001234: BE83007E
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001238: BF870001
	v_cmpx_gt_u32_e32 0xfffffa00, v15                          // 00000000123C: 7D981EFF FFFFFA00
	s_cbranch_execz 65518                                      // 000000001244: BFA5FFEE <attn_prep_24_4_256_64_8204_11_k4jv4+0x1200>
	ds_load_b32 v15, v14                                       // 000000001248: D8D80000 0F00000E
	s_waitcnt lgkmcnt(0)                                       // 000000001250: BF89FC07
	v_mul_f32_e32 v15, 0x3d800000, v15                         // 000000001254: 101E1EFF 3D800000
	ds_store_b32 v14, v15                                      // 00000000125C: D8340000 00000F0E
	s_branch 65510                                             // 000000001264: BFA0FFE6 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1200>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001268: 8C7E017E
	s_waitcnt lgkmcnt(0)                                       // 00000000126C: BF89FC07
	s_barrier                                                  // 000000001270: BFBD0000
	buffer_gl0_inv                                             // 000000001274: E0AC0000 00000000
	ds_load_b32 v13, v3 offset:12288                           // 00000000127C: D8D83000 0D000003
	v_cmp_eq_u32_e64 s1, 0, v4                                 // 000000001284: D44A0001 00020880
	s_waitcnt lgkmcnt(0)                                       // 00000000128C: BF89FC07
	v_mul_f32_e32 v14, v13, v13                                // 000000001290: 101C1B0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001294: BF870091
	v_mov_b32_dpp v14, v14 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001298: 7E1C02FA FF09110E
	v_fmac_f32_e32 v14, v13, v13                               // 0000000012A0: 561C1B0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012A4: BF870091
	v_add_f32_dpp v13, v14, v14 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012A8: 061A1CFA FF09120E
	v_add_f32_dpp v13, v13, v13 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012B0: 061A1AFA FF09140D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012B8: BF870091
	v_add_f32_dpp v13, v13, v13 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012BC: 061A1AFA FF09180D
	v_readlane_b32 s3, v13, 15                                 // 0000000012C4: D7600003 00011F0D
	v_readlane_b32 s7, v13, 31                                 // 0000000012CC: D7600007 00013F0D
	v_lshlrev_b32_e32 v13, 2, v1                               // 0000000012D4: 301A0282
	s_and_saveexec_b32 s6, s1                                  // 0000000012D8: BE862001
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000012DC: BF870002
	v_add_f32_e64 v14, s3, s7                                  // 0000000012E0: D503000E 00000E03
	ds_store_b32 v13, v14 offset:18048                         // 0000000012E8: D8344680 00000E0D
	s_or_b32 exec_lo, exec_lo, s6                              // 0000000012F0: 8C7E067E
	v_mov_b32_e32 v30, 0                                       // 0000000012F4: 7E3C0280
	s_waitcnt lgkmcnt(0)                                       // 0000000012F8: BF89FC07
	s_barrier                                                  // 0000000012FC: BFBD0000
	buffer_gl0_inv                                             // 000000001300: E0AC0000 00000000
	s_mul_i32 s6, s30, 0x258e10                                // 000000001308: 9606FF1E 00258E10
	ds_load_b128 v[14:17], v30 offset:18048                    // 000000001310: DBFC4680 0E00001E
	ds_load_b128 v[18:21], v30 offset:18064                    // 000000001318: DBFC4690 1200001E
	ds_load_b128 v[22:25], v30 offset:17968                    // 000000001320: DBFC4630 1600001E
	s_add_u32 s8, s4, s6                                       // 000000001328: 80080604
	s_addc_u32 s9, s5, 0                                       // 00000000132C: 82098005
	s_waitcnt lgkmcnt(2)                                       // 000000001330: BF89FC27
	v_add_f32_e32 v14, v14, v15                                // 000000001334: 061C1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001338: BF870091
	v_add_f32_e32 v14, v16, v14                                // 00000000133C: 061C1D10
	v_add_f32_e32 v14, v17, v14                                // 000000001340: 061C1D11
	s_waitcnt lgkmcnt(1)                                       // 000000001344: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001348: BF870091
	v_add_f32_e32 v14, v18, v14                                // 00000000134C: 061C1D12
	v_add_f32_e32 v14, v19, v14                                // 000000001350: 061C1D13
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001354: BF870091
	v_add_f32_e32 v14, v20, v14                                // 000000001358: 061C1D14
	v_add_f32_e32 v14, v21, v14                                // 00000000135C: 061C1D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001360: BF870121
	v_mul_f32_e32 v15, 0x4f800000, v14                         // 000000001364: 101E1CFF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v14                    // 00000000136C: 7C281CFF 0F800000
	v_cndmask_b32_e32 v15, v14, v15, vcc_lo                    // 000000001374: 021E1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000001378: BF870141
	v_sqrt_f32_e32 v16, v15                                    // 00000000137C: 7E20670F
	s_waitcnt_depctr 0xfff                                     // 000000001380: BF880FFF
	v_add_nc_u32_e32 v18, 1, v16                               // 000000001384: 4A242081
	v_add_nc_u32_e32 v17, -1, v16                              // 000000001388: 4A2220C1
	v_fma_f32 v20, -v18, v16, v15                              // 00000000138C: D6130014 243E2112
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001394: BF870092
	v_fma_f32 v19, -v17, v16, v15                              // 000000001398: D6130013 243E2111
	v_cmp_ge_f32_e64 s3, 0, v19                                // 0000000013A0: D4160003 00022680
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000013A8: BF870211
	v_cndmask_b32_e64 v16, v16, v17, s3                        // 0000000013AC: D5010010 000E2310
	v_cmp_lt_f32_e64 s3, 0, v20                                // 0000000013B4: D4110003 00022880
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000013BC: BF870121
	v_cndmask_b32_e64 v16, v16, v18, s3                        // 0000000013C0: D5010010 000E2510
	v_cmp_eq_u32_e64 s3, 0, v0                                 // 0000000013C8: D44A0003 00020080
	v_mul_f32_e32 v17, 0x37800000, v16                         // 0000000013D0: 102220FF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000013D8: BF870121
	v_cndmask_b32_e32 v16, v16, v17, vcc_lo                    // 0000000013DC: 02202310
	v_cmp_class_f32_e64 vcc_lo, v15, 0x260                     // 0000000013E0: D47E006A 0001FF0F 00000260
	v_cndmask_b32_e32 v15, v16, v15, vcc_lo                    // 0000000013EC: 021E1F10
	ds_load_b128 v[16:19], v30 offset:17920                    // 0000000013F0: DBFC4600 1000001E
	ds_load_b128 v[26:29], v30 offset:17936                    // 0000000013F8: DBFC4610 1A00001E
	ds_load_b128 v[30:33], v30 offset:17952                    // 000000001400: DBFC4620 1E00001E
	ds_load_b32 v36, v3 offset:12288                           // 000000001408: D8D83000 24000003
	v_div_scale_f32 v20, null, v15, v15, 0x41800000            // 000000001410: D6FC7C14 03FE1F0F 41800000
	v_div_scale_f32 v35, vcc_lo, 0x41800000, v15, 0x41800000   // 00000000141C: D6FC6A23 03FE1EFF 41800000
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001428: BF870002
	v_rcp_f32_e32 v21, v20                                     // 00000000142C: 7E2A5514
	s_waitcnt lgkmcnt(3)                                       // 000000001430: BF89FC37
	v_add_f32_e32 v16, v17, v16                                // 000000001434: 06202111
	s_waitcnt_depctr 0xfff                                     // 000000001438: BF880FFF
	v_fma_f32 v34, -v20, v21, 1.0                              // 00000000143C: D6130022 23CA2B14
	v_add_f32_e32 v17, v17, v18                                // 000000001444: 06222511
	v_add_f32_e32 v18, v19, v18                                // 000000001448: 06242513
	s_waitcnt lgkmcnt(2)                                       // 00000000144C: BF89FC27
	v_add_f32_e32 v19, v19, v26                                // 000000001450: 06263513
	v_dual_add_f32 v26, v27, v26 :: v_dual_fmac_f32 v21, v34, v21// 000000001454: C900351B 1A142B22
	v_mul_f32_e32 v17, 0.5, v17                                // 00000000145C: 102222F0
	v_add_f32_e32 v27, v27, v28                                // 000000001460: 0636391B
	s_delay_alu instid0(VALU_DEP_4)                            // 000000001464: BF870004
	v_dual_add_f32 v28, v29, v28 :: v_dual_mul_f32 v19, 0.5, v19// 000000001468: C906391D 1C1226F0
	s_waitcnt lgkmcnt(1)                                       // 000000001470: BF89FC17
	v_dual_mul_f32 v34, v35, v21 :: v_dual_add_f32 v29, v29, v30// 000000001474: C8C82B23 221C3D1D
	v_add_f32_e32 v30, v31, v30                                // 00000000147C: 063C3D1F
	v_add_f32_e32 v31, v31, v32                                // 000000001480: 063E411F
	v_add_f32_e32 v32, v33, v32                                // 000000001484: 06404121
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000001488: BF8701B4
	v_fma_f32 v37, -v20, v34, v35                              // 00000000148C: D6130025 248E4514
	v_dual_add_f32 v33, v33, v22 :: v_dual_mul_f32 v16, 0.5, v16// 000000001494: C9062D21 211020F0
	v_add_f32_e32 v22, v23, v22                                // 00000000149C: 062C2D17
	v_fmac_f32_e32 v34, v37, v21                               // 0000000014A0: 56442B25
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000014A4: BF870091
	v_fma_f32 v20, -v20, v34, v35                              // 0000000014A8: D6130014 248E4514
	v_div_fmas_f32 v20, v20, v21, v34                          // 0000000014B0: D6370014 048A2B14
	v_add_f32_e32 v21, v23, v24                                // 0000000014B8: 062A3117
	v_cmp_lt_f32_e32 vcc_lo, 0, v14                            // 0000000014BC: 7C221C80
	v_add_f32_e32 v23, v25, v24                                // 0000000014C0: 062E3119
	v_mul_f32_e32 v25, 0.5, v28                                // 0000000014C4: 103238F0
	v_div_fixup_f32 v20, v20, v15, 0x41800000                  // 0000000014C8: D6270014 03FE1F14 41800000
	v_mul_f32_e32 v18, 0.5, v18                                // 0000000014D4: 102424F0
	v_mul_f32_e32 v24, 0.5, v26                                // 0000000014D8: 103034F0
	v_dual_mul_f32 v26, 0.5, v29 :: v_dual_mul_f32 v29, 0.5, v31// 0000000014DC: C8C63AF0 1A1C3EF0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 0000000014E4: BF8701C4
	v_cndmask_b32_e32 v14, 0, v20, vcc_lo                      // 0000000014E8: 021C2880
	v_dual_mul_f32 v20, 0.5, v27 :: v_dual_mul_f32 v27, 0.5, v30// 0000000014EC: C8C636F0 141A3CF0
	v_dual_mul_f32 v31, 0.5, v33 :: v_dual_mul_f32 v30, 0.5, v32// 0000000014F4: C8C642F0 1F1E40F0
	s_waitcnt lgkmcnt(0)                                       // 0000000014FC: BF89FC07
	v_mul_f32_e32 v28, v36, v14                                // 000000001500: 10381D24
	v_mul_f32_e32 v22, 0.5, v22                                // 000000001504: 102C2CF0
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001508: BF870002
	v_cmp_gt_f32_e32 vcc_lo, v28, v16                          // 00000000150C: 7C28211C
	v_cndmask_b32_e64 v16, 0, 1, vcc_lo                        // 000000001510: D5010010 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v17                          // 000000001518: 7C28231C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 00000000151C: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v19                          // 000000001524: 7C28271C
	v_cndmask_b32_e64 v19, 0, 1, vcc_lo                        // 000000001528: D5010013 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v18                          // 000000001530: 7C28251C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001534: BF870244
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 000000001538: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v20                          // 00000000153C: 7C28291C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 000000001540: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v24                          // 000000001548: 7C28311C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v19, vcc_lo          // 00000000154C: 40202710
	v_cmp_gt_f32_e32 vcc_lo, v28, v26                          // 000000001550: 7C28351C
	v_mul_f32_e32 v19, 0.5, v23                                // 000000001554: 10262EF0
	v_cndmask_b32_e64 v18, 0, 1, vcc_lo                        // 000000001558: D5010012 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v25                          // 000000001560: 7C28331C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 000000001564: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v29                          // 000000001568: 7C283B1C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 00000000156C: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v27                          // 000000001574: 7C28371C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001578: BF870244
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v18, vcc_lo          // 00000000157C: 40202510
	v_cmp_gt_f32_e32 vcc_lo, v28, v31                          // 000000001580: 7C283F1C
	v_cndmask_b32_e64 v18, 0, 1, vcc_lo                        // 000000001584: D5010012 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v30                          // 00000000158C: 7C283D1C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 000000001590: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v22                          // 000000001594: 7C282D1C
	v_mul_f32_e32 v17, 0.5, v21                                // 000000001598: 10222AF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000159C: BF870113
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v18, vcc_lo          // 0000000015A0: 40202510
	v_cmp_gt_f32_e32 vcc_lo, v28, v17                          // 0000000015A4: 7C28231C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 0000000015A8: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v19                          // 0000000015B0: 7C28271C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000015B4: BF870092
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 0000000015B8: 40202310
	v_lshlrev_b32_e32 v17, 2, v16                              // 0000000015BC: 30222082
	ds_load_b32 v17, v17 offset:17920                          // 0000000015C0: D8D84600 11000011
	s_waitcnt lgkmcnt(0)                                       // 0000000015C8: BF89FC07
	v_fma_f32 v14, v36, v14, -v17                              // 0000000015CC: D613000E 84461D24
	ds_store_2addr_stride64_b32 v3, v14, v16 offset0:62 offset1:66// 0000000015D4: D83C423E 00100E03
	s_and_saveexec_b32 s4, s3                                  // 0000000015DC: BE842003
	s_cbranch_execz 12                                         // 0000000015E0: BFA5000C <attn_prep_24_4_256_64_8204_11_k4jv4+0x1614>
	s_lshl_b32 s6, s14, 1                                      // 0000000015E4: 8406810E
	v_mul_f32_e32 v14, 0x3d800000, v15                         // 0000000015E8: 101C1EFF 3D800000
	s_ashr_i32 s7, s6, 31                                      // 0000000015F0: 86079F06
	v_mov_b32_e32 v16, 0x140000                                // 0000000015F4: 7E2002FF 00140000
	s_lshl_b64 s[6:7], s[6:7], 2                               // 0000000015FC: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001600: BF870009
	s_add_u32 s6, s8, s6                                       // 000000001604: 80060608
	s_addc_u32 s7, s9, s7                                      // 000000001608: 82070709
	global_store_b32 v16, v14, s[6:7] offset:1920              // 00000000160C: DC6A0780 00060E10
	s_or_b32 exec_lo, exec_lo, s4                              // 000000001614: 8C7E047E
	v_add_nc_u32_e32 v16, 0x3e00, v3                           // 000000001618: 4A2006FF 00003E00
	v_add_nc_u32_e32 v14, 0x4200, v3                           // 000000001620: 4A1C06FF 00004200
	v_cmp_gt_u32_e64 s4, 0x80, v0                              // 000000001628: D44C0004 000200FF 00000080
	s_waitcnt lgkmcnt(0)                                       // 000000001634: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001638: BC7C0000
	s_barrier                                                  // 00000000163C: BFBD0000
	buffer_gl0_inv                                             // 000000001640: E0AC0000 00000000
	s_and_saveexec_b32 s5, s4                                  // 000000001648: BE852004
	s_cbranch_execz 16                                         // 00000000164C: BFA50010 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1690>
	v_lshl_add_u32 v17, v0, 2, v14                             // 000000001650: D6460011 04390500
	s_lshl_b64 s[6:7], s[14:15], 7                             // 000000001658: 8486870E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000165C: BF870009
	v_or_b32_e32 v19, s6, v0                                   // 000000001660: 38260006
	v_mov_b32_e32 v20, s7                                      // 000000001664: 7E280207
	ds_load_b64 v[17:18], v17                                  // 000000001668: D9D80000 11000011
	s_waitcnt lgkmcnt(0)                                       // 000000001670: BF89FC07
	v_lshl_or_b32 v21, v18, 4, v17                             // 000000001674: D6560015 04450912
	v_add_co_u32 v17, vcc_lo, s8, v19                          // 00000000167C: D7006A11 00022608
	v_add_co_ci_u32_e32 v18, vcc_lo, s9, v20, vcc_lo           // 000000001684: 40242809
	global_store_b8 v[17:18], v21, off                         // 000000001688: DC620000 007C1511
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001690: 8C7E057E
	ds_load_b32 v17, v16                                       // 000000001694: D8D80000 11000010
	s_waitcnt lgkmcnt(0)                                       // 00000000169C: BF89FC07
	v_mul_f32_e32 v18, v17, v17                                // 0000000016A0: 10242311
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000016A4: BF870091
	v_mov_b32_dpp v18, v18 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000016A8: 7E2402FA FF091112
	v_fmac_f32_e32 v18, v17, v17                               // 0000000016B0: 56242311
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000016B4: BF870091
	v_add_f32_dpp v17, v18, v18 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000016B8: 062224FA FF091212
	v_add_f32_dpp v17, v17, v17 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000016C0: 062222FA FF091411
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000016C8: BF870091
	v_add_f32_dpp v17, v17, v17 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000016CC: 062222FA FF091811
	v_readlane_b32 s6, v17, 15                                 // 0000000016D4: D7600006 00011F11
	v_readlane_b32 s7, v17, 31                                 // 0000000016DC: D7600007 00013F11
	s_and_saveexec_b32 s5, s1                                  // 0000000016E4: BE852001
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000016E8: BF870001
	v_add_f32_e64 v17, s6, s7                                  // 0000000016EC: D5030011 00000E06
	ds_store_b32 v13, v17 offset:18048                         // 0000000016F4: D8344680 0000110D
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000016FC: 8C7E057E
	v_mov_b32_e32 v21, 0                                       // 000000001700: 7E2A0280
	s_waitcnt lgkmcnt(0)                                       // 000000001704: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001708: BC7C0000
	s_barrier                                                  // 00000000170C: BFBD0000
	buffer_gl0_inv                                             // 000000001710: E0AC0000 00000000
	v_cmp_eq_u32_e64 s5, 0, v8                                 // 000000001718: D44A0005 00021080
	ds_load_b128 v[17:20], v21 offset:18048                    // 000000001720: DBFC4680 11000015
	ds_load_b128 v[21:24], v21 offset:18064                    // 000000001728: DBFC4690 15000015
	ds_load_b32 v25, v16                                       // 000000001730: D8D80000 19000010
	s_waitcnt lgkmcnt(2)                                       // 000000001738: BF89FC27
	v_add_f32_e32 v17, v17, v18                                // 00000000173C: 06222511
	s_waitcnt lgkmcnt(0)                                       // 000000001740: BF89FC07
	v_cndmask_b32_e64 v8, -v25, v25, s5                        // 000000001744: D5010008 20163319
	s_delay_alu instid0(VALU_DEP_2)                            // 00000000174C: BF870002
	v_add_f32_e32 v17, v17, v19                                // 000000001750: 06222711
	ds_store_b32 v16, v8                                       // 000000001754: D8340000 00000810
	s_waitcnt lgkmcnt(0)                                       // 00000000175C: BF89FC07
	s_barrier                                                  // 000000001760: BFBD0000
	v_add_f32_e32 v17, v17, v20                                // 000000001764: 06222911
	buffer_gl0_inv                                             // 000000001768: E0AC0000 00000000
	v_add_f32_e32 v17, v17, v21                                // 000000001770: 06222B11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001774: BF870091
	v_add_f32_e32 v17, v17, v22                                // 000000001778: 06222D11
	v_add_f32_e32 v17, v17, v23                                // 00000000177C: 06222F11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001780: BF870091
	v_add_f32_e32 v17, v17, v24                                // 000000001784: 06223111
	v_mul_f32_e32 v18, 0x4f800000, v17                         // 000000001788: 102422FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v17                    // 000000001790: 7C2822FF 0F800000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001798: BF870092
	v_cndmask_b32_e32 v17, v17, v18, vcc_lo                    // 00000000179C: 02222511
	v_sqrt_f32_e32 v18, v17                                    // 0000000017A0: 7E246711
	s_waitcnt_depctr 0xfff                                     // 0000000017A4: BF880FFF
	v_add_nc_u32_e32 v20, -1, v18                              // 0000000017A8: 4A2824C1
	v_add_nc_u32_e32 v19, 1, v18                               // 0000000017AC: 4A262481
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000017B0: BF870112
	v_fma_f32 v21, -v20, v18, v17                              // 0000000017B4: D6130015 24462514
	v_fma_f32 v22, -v19, v18, v17                              // 0000000017BC: D6130016 24462513
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000017C4: BF870112
	v_cmp_ge_f32_e64 s5, 0, v21                                // 0000000017C8: D4160005 00022A80
	v_cmp_lt_f32_e64 s6, 0, v22                                // 0000000017D0: D4110006 00022C80
	s_and_saveexec_b32 s7, s4                                  // 0000000017D8: BE872004
	s_cbranch_execz 9                                          // 0000000017DC: BFA50009 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1804>
	v_lshl_add_u32 v8, v0, 2, v16                              // 0000000017E0: D6460008 04410500
	ds_load_b64 v[21:22], v8                                   // 0000000017E8: D9D80000 15000008
	s_waitcnt lgkmcnt(0)                                       // 0000000017F0: BF89FC07
	v_add_f32_e32 v23, v21, v22                                // 0000000017F4: 062E2D15
	v_sub_f32_e32 v24, v21, v22                                // 0000000017F8: 08302D15
	ds_store_b64 v8, v[23:24]                                  // 0000000017FC: D9340000 00001708
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001804: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001808: BF89FC07
	s_barrier                                                  // 00000000180C: BFBD0000
	buffer_gl0_inv                                             // 000000001810: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001818: BE872004
	s_cbranch_execz 14                                         // 00000000181C: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1858>
	v_and_or_b32 v8, 0xfc, v5, v9                              // 000000001820: D6570008 04260AFF 000000FC
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000182C: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 000000001830: 30101082
	v_add_nc_u32_e32 v21, 0x3c00, v8                           // 000000001834: 4A2A10FF 00003C00
	ds_load_2addr_b32 v[8:9], v21 offset0:128 offset1:130      // 00000000183C: D8DC8280 08000015
	s_waitcnt lgkmcnt(0)                                       // 000000001844: BF89FC07
	v_add_f32_e32 v22, v8, v9                                  // 000000001848: 062C1308
	v_sub_f32_e32 v8, v8, v9                                   // 00000000184C: 08101308
	ds_store_2addr_b32 v21, v22, v8 offset0:128 offset1:130    // 000000001850: D8388280 00081615
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001858: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 00000000185C: BF89FC07
	s_barrier                                                  // 000000001860: BFBD0000
	buffer_gl0_inv                                             // 000000001864: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 00000000186C: BE872004
	s_cbranch_execz 14                                         // 000000001870: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x18ac>
	v_and_or_b32 v8, 0xf8, v5, v10                             // 000000001874: D6570008 042A0AFF 000000F8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001880: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 000000001884: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 000000001888: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:132      // 000000001890: D8DC8480 0800000A
	s_waitcnt lgkmcnt(0)                                       // 000000001898: BF89FC07
	v_add_f32_e32 v21, v8, v9                                  // 00000000189C: 062A1308
	v_sub_f32_e32 v8, v8, v9                                   // 0000000018A0: 08101308
	ds_store_2addr_b32 v10, v21, v8 offset0:128 offset1:132    // 0000000018A4: D8388480 0008150A
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000018AC: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000018B0: BF89FC07
	s_barrier                                                  // 0000000018B4: BFBD0000
	buffer_gl0_inv                                             // 0000000018B8: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000018C0: BE872004
	s_cbranch_execz 14                                         // 0000000018C4: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1900>
	v_and_or_b32 v8, 0xf0, v5, v11                             // 0000000018C8: D6570008 042E0AFF 000000F0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000018D4: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 0000000018D8: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 0000000018DC: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:136      // 0000000018E4: D8DC8880 0800000A
	s_waitcnt lgkmcnt(0)                                       // 0000000018EC: BF89FC07
	v_add_f32_e32 v11, v8, v9                                  // 0000000018F0: 06161308
	v_sub_f32_e32 v8, v8, v9                                   // 0000000018F4: 08101308
	ds_store_2addr_b32 v10, v11, v8 offset0:128 offset1:136    // 0000000018F8: D8388880 00080B0A
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001900: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001904: BF89FC07
	s_barrier                                                  // 000000001908: BFBD0000
	buffer_gl0_inv                                             // 00000000190C: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001914: BE872004
	s_cbranch_execz 14                                         // 000000001918: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1954>
	v_and_or_b32 v8, 0xe0, v5, v12                             // 00000000191C: D6570008 04320AFF 000000E0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001928: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 00000000192C: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 000000001930: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:144      // 000000001938: D8DC9080 0800000A
	s_waitcnt lgkmcnt(0)                                       // 000000001940: BF89FC07
	v_add_f32_e32 v11, v8, v9                                  // 000000001944: 06161308
	v_sub_f32_e32 v8, v8, v9                                   // 000000001948: 08101308
	ds_store_2addr_b32 v10, v11, v8 offset0:128 offset1:144    // 00000000194C: D8389080 00080B0A
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001954: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001958: BF89FC07
	s_barrier                                                  // 00000000195C: BFBD0000
	buffer_gl0_inv                                             // 000000001960: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001968: BE872004
	s_cbranch_execz 14                                         // 00000000196C: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x19a8>
	v_and_or_b32 v6, 0xc0, v5, v6                              // 000000001970: D6570006 041A0AFF 000000C0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000197C: BF870091
	v_lshlrev_b32_e32 v6, 2, v6                                // 000000001980: 300C0C82
	v_add_nc_u32_e32 v6, 0x3c00, v6                            // 000000001984: 4A0C0CFF 00003C00
	ds_load_2addr_b32 v[8:9], v6 offset0:128 offset1:160       // 00000000198C: D8DCA080 08000006
	s_waitcnt lgkmcnt(0)                                       // 000000001994: BF89FC07
	v_add_f32_e32 v10, v8, v9                                  // 000000001998: 06141308
	v_sub_f32_e32 v8, v8, v9                                   // 00000000199C: 08101308
	ds_store_2addr_b32 v6, v10, v8 offset0:128 offset1:160     // 0000000019A0: D838A080 00080A06
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000019A8: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000019AC: BF89FC07
	s_barrier                                                  // 0000000019B0: BFBD0000
	buffer_gl0_inv                                             // 0000000019B4: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000019BC: BE872004
	s_cbranch_execz 12                                         // 0000000019C0: BFA5000C <attn_prep_24_4_256_64_8204_11_k4jv4+0x19f4>
	v_and_or_b32 v6, 0x80, v5, v7                              // 0000000019C4: D6570006 041E0AFF 00000080
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000019D0: BF870001
	v_lshlrev_b32_e32 v8, 2, v6                                // 0000000019D4: 30100C82
	ds_load_2addr_stride64_b32 v[6:7], v8 offset0:62 offset1:63// 0000000019D8: D8E03F3E 06000008
	s_waitcnt lgkmcnt(0)                                       // 0000000019E0: BF89FC07
	v_add_f32_e32 v9, v6, v7                                   // 0000000019E4: 06120F06
	v_sub_f32_e32 v6, v6, v7                                   // 0000000019E8: 080C0F06
	ds_store_2addr_stride64_b32 v8, v9, v6 offset0:62 offset1:63// 0000000019EC: D83C3F3E 00060908
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000019F4: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000019F8: BF89FC07
	s_barrier                                                  // 0000000019FC: BFBD0000
	buffer_gl0_inv                                             // 000000001A00: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001A08: BE872004
	s_cbranch_execz 7                                          // 000000001A0C: BFA50007 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1a2c>
	ds_load_2addr_stride64_b32 v[6:7], v16 offset1:2           // 000000001A10: D8E00200 06000010
	s_waitcnt lgkmcnt(0)                                       // 000000001A18: BF89FC07
	v_add_f32_e32 v8, v6, v7                                   // 000000001A1C: 06100F06
	v_sub_f32_e32 v6, v6, v7                                   // 000000001A20: 080C0F06
	ds_store_2addr_stride64_b32 v16, v8, v6 offset1:2          // 000000001A24: D83C0200 00060810
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001A2C: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001A30: BF89FC07
	s_barrier                                                  // 000000001A34: BFBD0000
	buffer_gl0_inv                                             // 000000001A38: E0AC0000 00000000
	ds_load_b32 v6, v16                                        // 000000001A40: D8D80000 06000010
	s_waitcnt lgkmcnt(0)                                       // 000000001A48: BF89FC07
	v_cmp_le_f32_e64 s7, 0, v6                                 // 000000001A4C: D4130007 00020C80
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001A54: BF870001
	v_cndmask_b32_e64 v6, 0, 1, s7                             // 000000001A58: D5010006 001D0280
	ds_store_b32 v14, v6                                       // 000000001A60: D8340000 0000060E
	s_waitcnt lgkmcnt(0)                                       // 000000001A68: BF89FC07
	s_barrier                                                  // 000000001A6C: BFBD0000
	buffer_gl0_inv                                             // 000000001A70: E0AC0000 00000000
	s_and_saveexec_b32 s7, s2                                  // 000000001A78: BE872002
	s_cbranch_execz 51                                         // 000000001A7C: BFA50033 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1b4c>
	v_lshlrev_b32_e32 v10, 5, v0                               // 000000001A80: 30140085
	s_lshl_b64 s[10:11], s[14:15], 5                           // 000000001A84: 848A850E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001A88: BF8700A9
	s_add_u32 s2, s10, 0x100600                                // 000000001A8C: 8002FF0A 00100600
	s_addc_u32 s10, s11, 0                                     // 000000001A94: 820A800B
	v_add_nc_u32_e32 v6, 0x420c, v10                           // 000000001A98: 4A0C14FF 0000420C
	v_add_nc_u32_e32 v8, 0x4204, v10                           // 000000001AA0: 4A1014FF 00004204
	v_add_nc_u32_e32 v11, 0x4214, v10                          // 000000001AA8: 4A1614FF 00004214
	v_add_nc_u32_e32 v12, 0x4000, v10                          // 000000001AB0: 4A1814FF 00004000
	ds_load_2addr_b32 v[6:7], v6 offset1:1                     // 000000001AB8: D8DC0100 06000006
	ds_load_2addr_b32 v[8:9], v8 offset1:1                     // 000000001AC0: D8DC0100 08000008
	ds_load_2addr_b32 v[10:11], v11 offset1:1                  // 000000001AC8: D8DC0100 0A00000B
	ds_load_2addr_b32 v[21:22], v12 offset0:128 offset1:135    // 000000001AD0: D8DC8780 1500000C
	s_waitcnt lgkmcnt(3)                                       // 000000001AD8: BF89FC37
	v_lshlrev_b32_e32 v7, 4, v7                                // 000000001ADC: 300E0E84
	v_lshlrev_b32_e32 v6, 3, v6                                // 000000001AE0: 300C0C83
	s_waitcnt lgkmcnt(2)                                       // 000000001AE4: BF89FC27
	v_lshlrev_b32_e32 v8, 1, v8                                // 000000001AE8: 30101081
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000001AEC: BF870133
	v_lshl_or_b32 v7, v9, 2, v7                                // 000000001AF0: D6560007 041D0509
	s_waitcnt lgkmcnt(1)                                       // 000000001AF8: BF89FC17
	v_dual_mov_b32 v10, s10 :: v_dual_lshlrev_b32 v9, 5, v10   // 000000001AFC: CA22000A 0A081485
	v_or3_b32 v6, v8, v6, v7                                   // 000000001B04: D6580006 041E0D08
	v_lshlrev_b32_e32 v7, 6, v11                               // 000000001B0C: 300E1686
	s_waitcnt lgkmcnt(0)                                       // 000000001B10: BF89FC07
	v_lshlrev_b32_e32 v8, 7, v22                               // 000000001B14: 30102C87
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001B18: BF870123
	v_or3_b32 v6, v9, v21, v6                                  // 000000001B1C: D6580006 041A2B09
	v_or_b32_e32 v9, s2, v0                                    // 000000001B24: 38120002
	v_or3_b32 v8, v6, v7, v8                                   // 000000001B28: D6580008 04220F06
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B30: BF870092
	v_add_co_u32 v6, s2, s8, v9                                // 000000001B34: D7000206 00021208
	v_add_co_ci_u32_e64 v7, s2, s9, v10, s2                    // 000000001B3C: D5200207 000A1409
	global_store_b8 v[6:7], v8, off                            // 000000001B44: DC620000 007C0806
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001B4C: 8C7E077E
	s_and_saveexec_b32 s2, s3                                  // 000000001B50: BE822003
	s_cbranch_execz 30                                         // 000000001B54: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1bd0>
	v_cndmask_b32_e64 v6, v18, v20, s5                         // 000000001B58: D5010006 00162912
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001B60: BF8704A1
	v_cndmask_b32_e64 v6, v6, v19, s6                          // 000000001B64: D5010006 001A2706
	s_lshl_b32 s6, s14, 1                                      // 000000001B6C: 8406810E
	s_ashr_i32 s7, s6, 31                                      // 000000001B70: 86079F06
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B74: BF870099
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000001B78: 84868206
	v_mul_f32_e32 v7, 0x37800000, v6                           // 000000001B7C: 100E0CFF 37800000
	s_add_u32 s6, s8, s6                                       // 000000001B84: 80060608
	s_addc_u32 s7, s9, s7                                      // 000000001B88: 82070709
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001B8C: BF870121
	v_dual_cndmask_b32 v6, v6, v7 :: v_dual_mov_b32 v7, 0x140000// 000000001B90: CA500F06 060600FF 00140000
	v_cmp_class_f32_e64 vcc_lo, v17, 0x260                     // 000000001B9C: D47E006A 0001FF11 00000260
	v_cndmask_b32_e32 v6, v6, v17, vcc_lo                      // 000000001BA8: 020C2306
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001BAC: BF870091
	v_mul_f32_e32 v6, 0x3d800000, v6                           // 000000001BB0: 100C0CFF 3D800000
	v_mul_f32_e32 v6, v15, v6                                  // 000000001BB8: 100C0D0F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001BBC: BF870001
	v_mul_f32_e32 v6, 0x3ba06c99, v6                           // 000000001BC0: 100C0CFF 3BA06C99
	global_store_b32 v7, v6, s[6:7] offset:1924                // 000000001BC8: DC6A0784 00060607
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001BD0: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 000000001BD4: BC7C0000
	s_barrier                                                  // 000000001BD8: BFBD0000
	buffer_gl0_inv                                             // 000000001BDC: E0AC0000 00000000
	ds_load_b32 v6, v3 offset:13312                            // 000000001BE4: D8D83400 06000003
	s_waitcnt lgkmcnt(0)                                       // 000000001BEC: BF89FC07
	v_mul_f32_e32 v7, v6, v6                                   // 000000001BF0: 100E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001BF4: BF870091
	v_mov_b32_dpp v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001BF8: 7E0E02FA FF091107
	v_fmac_f32_e32 v7, v6, v6                                  // 000000001C00: 560E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C04: BF870091
	v_add_f32_dpp v6, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C08: 060C0EFA FF091207
	v_add_f32_dpp v6, v6, v6 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C10: 060C0CFA FF091406
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C18: BF870091
	v_add_f32_dpp v6, v6, v6 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C1C: 060C0CFA FF091806
	v_readlane_b32 s5, v6, 15                                  // 000000001C24: D7600005 00011F06
	v_readlane_b32 s6, v6, 31                                  // 000000001C2C: D7600006 00013F06
	s_and_saveexec_b32 s2, s1                                  // 000000001C34: BE822001
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001C38: BF870001
	v_add_f32_e64 v6, s5, s6                                   // 000000001C3C: D5030006 00000C05
	ds_store_b32 v13, v6 offset:18048                          // 000000001C44: D8344680 0000060D
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001C4C: 8C7E027E
	v_mov_b32_e32 v23, 0                                       // 000000001C50: 7E2E0280
	s_waitcnt lgkmcnt(0)                                       // 000000001C54: BF89FC07
	s_barrier                                                  // 000000001C58: BFBD0000
	buffer_gl0_inv                                             // 000000001C5C: E0AC0000 00000000
	ds_load_b128 v[6:9], v23 offset:18048                      // 000000001C64: DBFC4680 06000017
	ds_load_b128 v[10:13], v23 offset:18064                    // 000000001C6C: DBFC4690 0A000017
	ds_load_b128 v[15:18], v23 offset:18032                    // 000000001C74: DBFC4670 0F000017
	s_waitcnt lgkmcnt(2)                                       // 000000001C7C: BF89FC27
	v_add_f32_e32 v6, v6, v7                                   // 000000001C80: 060C0F06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C84: BF870091
	v_add_f32_e32 v6, v8, v6                                   // 000000001C88: 060C0D08
	v_add_f32_e32 v6, v9, v6                                   // 000000001C8C: 060C0D09
	s_waitcnt lgkmcnt(1)                                       // 000000001C90: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C94: BF870091
	v_add_f32_e32 v6, v10, v6                                  // 000000001C98: 060C0D0A
	v_add_f32_e32 v6, v11, v6                                  // 000000001C9C: 060C0D0B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001CA0: BF870091
	v_add_f32_e32 v6, v12, v6                                  // 000000001CA4: 060C0D0C
	v_add_f32_e32 v11, v13, v6                                 // 000000001CA8: 06160D0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001CAC: BF870121
	v_mul_f32_e32 v6, 0x4f800000, v11                          // 000000001CB0: 100C16FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v11                    // 000000001CB8: 7C2816FF 0F800000
	v_cndmask_b32_e32 v6, v11, v6, vcc_lo                      // 000000001CC0: 020C0D0B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000001CC4: BF870141
	v_sqrt_f32_e32 v7, v6                                      // 000000001CC8: 7E0E6706
	s_waitcnt_depctr 0xfff                                     // 000000001CCC: BF880FFF
	v_add_nc_u32_e32 v8, -1, v7                                // 000000001CD0: 4A100EC1
	v_add_nc_u32_e32 v9, 1, v7                                 // 000000001CD4: 4A120E81
	v_fma_f32 v10, -v8, v7, v6                                 // 000000001CD8: D613000A 241A0F08
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001CE0: BF870112
	v_fma_f32 v12, -v9, v7, v6                                 // 000000001CE4: D613000C 241A0F09
	v_cmp_ge_f32_e64 s2, 0, v10                                // 000000001CEC: D4160002 00021480
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001CF4: BF870191
	v_cndmask_b32_e64 v7, v7, v8, s2                           // 000000001CF8: D5010007 000A1107
	v_cmp_lt_f32_e64 s2, 0, v12                                // 000000001D00: D4110002 00021880
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D08: BF870091
	v_cndmask_b32_e64 v7, v7, v9, s2                           // 000000001D0C: D5010007 000A1307
	v_mul_f32_e32 v8, 0x37800000, v7                           // 000000001D14: 10100EFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001D1C: BF870121
	v_cndmask_b32_e32 v7, v7, v8, vcc_lo                       // 000000001D20: 020E1107
	v_cmp_class_f32_e64 vcc_lo, v6, 0x260                      // 000000001D24: D47E006A 0001FF06 00000260
	v_cndmask_b32_e32 v6, v7, v6, vcc_lo                       // 000000001D30: 020C0D07
	ds_load_b128 v[7:10], v23 offset:17984                     // 000000001D34: DBFC4640 07000017
	ds_load_b128 v[19:22], v23 offset:18000                    // 000000001D3C: DBFC4650 13000017
	ds_load_b128 v[23:26], v23 offset:18016                    // 000000001D44: DBFC4660 17000017
	ds_load_b32 v3, v3 offset:13312                            // 000000001D4C: D8D83400 03000003
	s_waitcnt lgkmcnt(3)                                       // 000000001D54: BF89FC37
	v_add_f32_e32 v7, v8, v7                                   // 000000001D58: 060E0F08
	v_add_f32_e32 v8, v8, v9                                   // 000000001D5C: 06101308
	v_add_f32_e32 v9, v10, v9                                  // 000000001D60: 0612130A
	s_waitcnt lgkmcnt(2)                                       // 000000001D64: BF89FC27
	v_add_f32_e32 v10, v10, v19                                // 000000001D68: 0614270A
	v_add_f32_e32 v19, v20, v19                                // 000000001D6C: 06262714
	v_div_scale_f32 v12, null, v6, v6, 0x41800000              // 000000001D70: D6FC7C0C 03FE0D06 41800000
	v_div_scale_f32 v28, vcc_lo, 0x41800000, v6, 0x41800000    // 000000001D7C: D6FC6A1C 03FE0CFF 41800000
	v_add_f32_e32 v20, v20, v21                                // 000000001D88: 06282B14
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001D8C: BF870003
	v_rcp_f32_e32 v13, v12                                     // 000000001D90: 7E1A550C
	v_add_f32_e32 v21, v22, v21                                // 000000001D94: 062A2B16
	s_waitcnt lgkmcnt(1)                                       // 000000001D98: BF89FC17
	v_dual_add_f32 v22, v22, v23 :: v_dual_mul_f32 v9, 0.5, v9 // 000000001D9C: C9062F16 160812F0
	v_add_f32_e32 v23, v24, v23                                // 000000001DA4: 062E2F18
	v_dual_mul_f32 v7, 0.5, v7 :: v_dual_mul_f32 v8, 0.5, v8   // 000000001DA8: C8C60EF0 070810F0
	s_waitcnt_depctr 0xfff                                     // 000000001DB0: BF880FFF
	v_fma_f32 v27, -v12, v13, 1.0                              // 000000001DB4: D613001B 23CA1B0C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001DBC: BF870091
	v_fmac_f32_e32 v13, v27, v13                               // 000000001DC0: 561A1B1B
	v_mul_f32_e32 v27, v28, v13                                // 000000001DC4: 10361B1C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001DC8: BF870091
	v_fma_f32 v29, -v12, v27, v28                              // 000000001DCC: D613001D 2472370C
	v_fmac_f32_e32 v27, v29, v13                               // 000000001DD4: 56361B1D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001DD8: BF870091
	v_fma_f32 v12, -v12, v27, v28                              // 000000001DDC: D613000C 2472370C
	v_div_fmas_f32 v12, v12, v13, v27                          // 000000001DE4: D637000C 046E1B0C
	v_cmp_lt_f32_e32 vcc_lo, 0, v11                            // 000000001DEC: 7C221680
	v_dual_add_f32 v13, v16, v17 :: v_dual_mul_f32 v10, 0.5, v10// 000000001DF0: C9062310 0D0A14F0
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001DF8: BF870003
	v_div_fixup_f32 v12, v12, v6, 0x41800000                   // 000000001DFC: D627000C 03FE0D0C 41800000
	v_add_f32_e32 v24, v24, v25                                // 000000001E08: 06303318
	v_add_f32_e32 v25, v26, v25                                // 000000001E0C: 0632331A
	v_add_f32_e32 v26, v26, v15                                // 000000001E10: 06341F1A
	v_add_f32_e32 v15, v16, v15                                // 000000001E14: 061E1F10
	v_dual_cndmask_b32 v11, 0, v12 :: v_dual_add_f32 v16, v18, v17// 000000001E18: CA481880 0B102312
	v_dual_mul_f32 v17, 0.5, v19 :: v_dual_mul_f32 v12, 0.5, v20// 000000001E20: C8C626F0 110C28F0
	v_mul_f32_e32 v19, 0.5, v22                                // 000000001E28: 10262CF0
	s_waitcnt lgkmcnt(0)                                       // 000000001E2C: BF89FC07
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000001E30: BF8701B3
	v_dual_mul_f32 v3, v3, v11 :: v_dual_mul_f32 v18, 0.5, v21 // 000000001E34: C8C61703 03122AF0
	v_dual_mul_f32 v11, 0.5, v24 :: v_dual_mul_f32 v20, 0.5, v23// 000000001E3C: C8C630F0 0B142EF0
	v_mul_f32_e32 v21, 0.5, v25                                // 000000001E44: 102A32F0
	v_cmp_gt_f32_e32 vcc_lo, v3, v7                            // 000000001E48: 7C280F03
	v_dual_mul_f32 v22, 0.5, v26 :: v_dual_mul_f32 v15, 0.5, v15// 000000001E4C: C8C634F0 160E1EF0
	v_cndmask_b32_e64 v7, 0, 1, vcc_lo                         // 000000001E54: D5010007 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v8                            // 000000001E5C: 7C281103
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001E60: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v10                           // 000000001E68: 7C281503
	v_cndmask_b32_e64 v10, 0, 1, vcc_lo                        // 000000001E6C: D501000A 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v9                            // 000000001E74: 7C281303
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001E78: BF870244
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001E7C: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v12                           // 000000001E80: 7C281903
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001E84: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v17                           // 000000001E8C: 7C282303
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v10, vcc_lo            // 000000001E90: 400E1507
	v_cmp_gt_f32_e32 vcc_lo, v3, v19                           // 000000001E94: 7C282703
	v_mul_f32_e32 v10, 0.5, v16                                // 000000001E98: 101420F0
	v_cndmask_b32_e64 v9, 0, 1, vcc_lo                         // 000000001E9C: D5010009 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v18                           // 000000001EA4: 7C282503
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001EA8: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v11                           // 000000001EAC: 7C281703
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001EB0: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v20                           // 000000001EB8: 7C282903
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001EBC: BF870244
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v9, vcc_lo             // 000000001EC0: 400E1307
	v_cmp_gt_f32_e32 vcc_lo, v3, v22                           // 000000001EC4: 7C282D03
	v_cndmask_b32_e64 v9, 0, 1, vcc_lo                         // 000000001EC8: D5010009 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v21                           // 000000001ED0: 7C282B03
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001ED4: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v15                           // 000000001ED8: 7C281F03
	v_mul_f32_e32 v8, 0.5, v13                                 // 000000001EDC: 10101AF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001EE0: BF870113
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v9, vcc_lo             // 000000001EE4: 400E1307
	v_cmp_gt_f32_e32 vcc_lo, v3, v8                            // 000000001EE8: 7C281103
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001EEC: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v10                           // 000000001EF4: 7C281503
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001EF8: BF870002
	v_add_co_ci_u32_e32 v3, vcc_lo, v7, v8, vcc_lo             // 000000001EFC: 40061107
	ds_store_b32 v14, v3                                       // 000000001F00: D8340000 0000030E
	s_and_saveexec_b32 s2, s3                                  // 000000001F08: BE822003
	s_cbranch_execz 9                                          // 000000001F0C: BFA50009 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1f34>
	v_mul_f32_e32 v3, 0x3d800000, v6                           // 000000001F10: 10060CFF 3D800000
	s_lshl_b64 s[6:7], s[14:15], 2                             // 000000001F18: 8486820E
	v_mov_b32_e32 v6, 0x250000                                 // 000000001F1C: 7E0C02FF 00250000
	s_add_u32 s6, s8, s6                                       // 000000001F24: 80060608
	s_addc_u32 s7, s9, s7                                      // 000000001F28: 82070709
	global_store_b32 v6, v3, s[6:7] offset:3552                // 000000001F2C: DC6A0DE0 00060306
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001F34: 8C7E027E
	s_waitcnt lgkmcnt(0)                                       // 000000001F38: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001F3C: BC7C0000
	s_barrier                                                  // 000000001F40: BFBD0000
	buffer_gl0_inv                                             // 000000001F44: E0AC0000 00000000
	s_and_saveexec_b32 s2, s4                                  // 000000001F4C: BE822004
	s_cbranch_execz 21                                         // 000000001F50: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1fa8>
	v_lshlrev_b32_e32 v3, 2, v5                                // 000000001F54: 30060A82
	s_lshl_b64 s[4:5], s[14:15], 7                             // 000000001F58: 8484870E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 000000001F5C: BF8700C9
	s_add_u32 s3, s8, s4                                       // 000000001F60: 80030408
	s_addc_u32 s4, s9, s5                                      // 000000001F64: 82040509
	ds_load_b64 v[5:6], v3 offset:16896                        // 000000001F68: D9D84200 05000003
	v_add_co_u32 v0, s3, s3, v0                                // 000000001F70: D7000300 00020003
	v_add_co_ci_u32_e64 v3, null, s4, 0, s3                    // 000000001F78: D5207C03 000D0004
	s_waitcnt lgkmcnt(0)                                       // 000000001F80: BF89FC07
	v_lshl_or_b32 v7, v6, 4, v5                                // 000000001F84: D6560007 04150906
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001F8C: BF870193
	v_add_co_u32 v5, vcc_lo, 0x150000, v0                      // 000000001F90: D7006A05 000200FF 00150000
	v_add_co_ci_u32_e32 v6, vcc_lo, 0, v3, vcc_lo              // 000000001F9C: 400C0680
	global_store_b8 v[5:6], v7, off offset:2016                // 000000001FA0: DC6207E0 007C0705
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001FA8: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 000000001FAC: BC7C0000
	s_barrier                                                  // 000000001FB0: BFBD0000
	buffer_gl0_inv                                             // 000000001FB4: E0AC0000 00000000
	s_and_saveexec_b32 s2, s0                                  // 000000001FBC: BE822000
	s_cbranch_execz 357                                        // 000000001FC0: BFA50165 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2558>
	v_lshl_or_b32 v6, v1, 10, v2                               // 000000001FC4: D6560006 04091501
	ds_load_b128 v[8:11], v6                                   // 000000001FCC: DBFC0000 08000006
	ds_load_b128 v[12:15], v6 offset:16                        // 000000001FD4: DBFC0010 0C000006
	s_waitcnt lgkmcnt(1)                                       // 000000001FDC: BF89FC17
	v_max3_f32 v0, |v8|, 0, |v9|                               // 000000001FE0: D61C0500 04250108
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001FE8: BF8700A1
	v_max3_f32 v0, v0, |v10|, |v11|                            // 000000001FEC: D61C0600 042E1500
	s_waitcnt lgkmcnt(0)                                       // 000000001FF4: BF89FC07
	v_max3_f32 v0, v0, |v12|, |v13|                            // 000000001FF8: D61C0600 04361900
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002000: BF870091
	v_max3_f32 v0, v0, |v14|, |v15|                            // 000000002004: D61C0600 043E1D00
	v_mov_b32_dpp v2, v0 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000200C: 7E0402FA FF091100
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002014: BF870091
	v_max_f32_e32 v2, v2, v2                                   // 000000002018: 20040502
	v_max_f32_e32 v0, v0, v2                                   // 00000000201C: 20000500
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002020: BF870091
	v_mov_b32_dpp v2, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002024: 7E0402FA FF091200
	v_max_f32_e32 v2, v2, v2                                   // 00000000202C: 20040502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002030: BF870091
	v_max_f32_e32 v0, v0, v2                                   // 000000002034: 20000500
	v_mov_b32_dpp v2, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002038: 7E0402FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002040: BF870091
	v_max_f32_e32 v2, v2, v2                                   // 000000002044: 20040502
	v_max_f32_e32 v0, v0, v2                                   // 000000002048: 20000500
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000204C: BF870091
	v_mov_b32_dpp v2, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002050: 7E0402FA FF091800
	v_max_f32_e32 v2, v2, v2                                   // 000000002058: 20040502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000205C: BF870091
	v_max_f32_e32 v0, v0, v2                                   // 000000002060: 20000500
	v_readlane_b32 s0, v0, 31                                  // 000000002064: D7600000 00013F00
	v_readlane_b32 s2, v0, 15                                  // 00000000206C: D7600002 00011F00
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002074: BF870112
	v_max_f32_e64 v0, s0, s0                                   // 000000002078: D5100000 00000000
	v_max_f32_e64 v2, s2, s2                                   // 000000002080: D5100002 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002088: BF870091
	v_max_f32_e32 v0, v2, v0                                   // 00000000208C: 20000102
	v_div_scale_f32 v2, null, 0x42fe0000, 0x42fe0000, v0       // 000000002090: D6FC7C02 0401FEFF 42FE0000
	v_div_scale_f32 v7, vcc_lo, v0, 0x42fe0000, v0             // 00000000209C: D6FC6A07 0401FF00 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000020A8: BF8700B2
	v_rcp_f32_e32 v3, v2                                       // 0000000020AC: 7E065502
	s_waitcnt_depctr 0xfff                                     // 0000000020B0: BF880FFF
	v_fma_f32 v5, -v2, v3, 1.0                                 // 0000000020B4: D6130005 23CA0702
	v_fmac_f32_e32 v3, v5, v3                                  // 0000000020BC: 56060705
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020C0: BF870091
	v_mul_f32_e32 v5, v7, v3                                   // 0000000020C4: 100A0707
	v_fma_f32 v16, -v2, v5, v7                                 // 0000000020C8: D6130010 241E0B02
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020D0: BF870091
	v_fmac_f32_e32 v5, v16, v3                                 // 0000000020D4: 560A0710
	v_fma_f32 v2, -v2, v5, v7                                  // 0000000020D8: D6130002 241E0B02
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020E0: BF870091
	v_div_fmas_f32 v2, v2, v3, v5                              // 0000000020E4: D6370002 04160702
	v_div_fixup_f32 v7, v2, 0x42fe0000, v0                     // 0000000020EC: D6270007 0401FF02 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000020F8: BF870121
	v_div_scale_f32 v0, null, v7, v7, 1.0                      // 0000000020FC: D6FC7C00 03CA0F07
	v_div_scale_f32 v16, vcc_lo, 1.0, v7, 1.0                  // 000000002104: D6FC6A10 03CA0EF2
	v_rcp_f32_e32 v5, v0                                       // 00000000210C: 7E0A5500
	s_waitcnt_depctr 0xfff                                     // 000000002110: BF880FFF
	v_fma_f32 v2, -v0, v5, 1.0                                 // 000000002114: D6130002 23CA0B00
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000211C: BF870121
	v_fmac_f32_e32 v5, v2, v5                                  // 000000002120: 560A0B02
	v_mad_u64_u32 v[2:3], null, s30, 6, v[1:2]                 // 000000002124: D6FE7C02 04050C1E
	v_dual_mov_b32 v3, 0 :: v_dual_mul_f32 v18, v16, v5        // 00000000212C: CA060080 03120B10
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002134: BF870091
	v_fma_f32 v17, -v0, v18, v16                               // 000000002138: D6130011 24422500
	v_fmac_f32_e32 v18, v17, v5                                // 000000002140: 56240B11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002144: BF870211
	v_fma_f32 v0, -v0, v18, v16                                // 000000002148: D6130000 24422500
	v_mad_u64_u32 v[16:17], null, s12, 24, v[2:3]              // 000000002150: D6FE7C10 0409300C
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000002158: BF8701A2
	v_div_fmas_f32 v0, v0, v5, v18                             // 00000000215C: D6370000 044A0B00
	v_cmp_neq_f32_e32 vcc_lo, 0, v7                            // 000000002164: 7C3A0E80
	v_lshlrev_b64 v[2:3], 8, v[16:17]                          // 000000002168: D73C0002 00022088
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002170: BF870123
	v_div_fixup_f32 v5, v0, v7, 1.0                            // 000000002174: D6270005 03CA0F00
	v_lshlrev_b32_e32 v0, 3, v4                                // 00000000217C: 30000883
	v_cndmask_b32_e32 v4, 0, v5, vcc_lo                        // 000000002180: 02080A80
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000002184: BF8701A4
	v_add_co_u32 v5, vcc_lo, s16, v2                           // 000000002188: D7006A05 00020410
	v_add_co_ci_u32_e32 v18, vcc_lo, s17, v3, vcc_lo           // 000000002190: 40240611
	v_mul_f32_e32 v13, v13, v4                                 // 000000002194: 101A090D
	v_mul_f32_e32 v9, v9, v4                                   // 000000002198: 10120909
	v_mul_f32_e32 v10, v10, v4                                 // 00000000219C: 1014090A
	v_mul_f32_e32 v14, v14, v4                                 // 0000000021A0: 101C090E
	v_mul_f32_e32 v11, v11, v4                                 // 0000000021A4: 1016090B
	v_rndne_f32_e32 v13, v13                                   // 0000000021A8: 7E1A470D
	v_rndne_f32_e32 v9, v9                                     // 0000000021AC: 7E124709
	v_rndne_f32_e32 v10, v10                                   // 0000000021B0: 7E14470A
	v_rndne_f32_e32 v14, v14                                   // 0000000021B4: 7E1C470E
	v_rndne_f32_e32 v11, v11                                   // 0000000021B8: 7E16470B
	v_cvt_i32_f32_e32 v13, v13                                 // 0000000021BC: 7E1A110D
	v_mul_f32_e32 v8, v8, v4                                   // 0000000021C0: 10100908
	v_cvt_i32_f32_e32 v9, v9                                   // 0000000021C4: 7E121109
	v_cvt_i32_f32_e32 v10, v10                                 // 0000000021C8: 7E14110A
	v_cvt_i32_f32_e32 v14, v14                                 // 0000000021CC: 7E1C110E
	v_dual_mul_f32 v12, v12, v4 :: v_dual_lshlrev_b32 v13, 8, v13// 0000000021D0: C8E2090C 0C0C1A88
	v_mul_f32_e32 v4, v15, v4                                  // 0000000021D8: 1008090F
	v_rndne_f32_e32 v8, v8                                     // 0000000021DC: 7E104708
	v_cvt_i32_f32_e32 v11, v11                                 // 0000000021E0: 7E16110B
	s_delay_alu instid0(VALU_DEP_4)                            // 0000000021E4: BF870004
	v_and_b32_e32 v13, 0xff00, v13                             // 0000000021E8: 361A1AFF 0000FF00
	v_rndne_f32_e32 v12, v12                                   // 0000000021F0: 7E18470C
	v_rndne_f32_e32 v4, v4                                     // 0000000021F4: 7E084704
	v_cvt_i32_f32_e32 v8, v8                                   // 0000000021F8: 7E101108
	v_lshlrev_b32_e32 v9, 8, v9                                // 0000000021FC: 30121288
	v_lshlrev_b32_e32 v10, 16, v10                             // 000000002200: 30141490
	v_cvt_i32_f32_e32 v12, v12                                 // 000000002204: 7E18110C
	v_cvt_i32_f32_e32 v4, v4                                   // 000000002208: 7E081104
	v_lshlrev_b32_e32 v14, 16, v14                             // 00000000220C: 301C1C90
	v_perm_b32 v11, v11, v8, 0x40c0c00                         // 000000002210: D644000B 03FE110B 040C0C00
	v_and_b32_e32 v10, 0xff0000, v10                           // 00000000221C: 361414FF 00FF0000
	v_add_co_u32 v8, vcc_lo, v5, v0                            // 000000002224: D7006A08 00020105
	v_perm_b32 v4, v4, v12, 0x40c0c00                          // 00000000222C: D6440004 03FE1904 040C0C00
	v_and_b32_e32 v12, 0xff00, v9                              // 000000002238: 361812FF 0000FF00
	v_and_b32_e32 v14, 0xff0000, v14                           // 000000002240: 361C1CFF 00FF0000
	v_add_co_ci_u32_e32 v9, vcc_lo, 0, v18, vcc_lo             // 000000002248: 40122480
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000224C: BF870193
	v_or3_b32 v10, v11, v12, v10                               // 000000002250: D658000A 042A190B
	v_or3_b32 v11, v4, v13, v14                                // 000000002258: D658000B 043A1B04
	v_lshlrev_b64 v[4:5], 2, v[16:17]                          // 000000002260: D73C0004 00022082
	global_store_b64 v[8:9], v[10:11], off                     // 000000002268: DC6E0000 007C0A08
	s_and_saveexec_b32 s0, s1                                  // 000000002270: BE802001
	s_cbranch_execz 5                                          // 000000002274: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x228c>
	v_add_co_u32 v8, vcc_lo, s18, v4                           // 000000002278: D7006A08 00020812
	v_add_co_ci_u32_e32 v9, vcc_lo, s19, v5, vcc_lo            // 000000002280: 40120A13
	global_store_b32 v[8:9], v7, off                           // 000000002284: DC6A0000 007C0708
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000228C: 8C7E007E
	v_lshlrev_b32_e32 v10, 2, v0                               // 000000002290: 30140082
	ds_load_b128 v[6:9], v6 offset:6144                        // 000000002294: DBFC1800 06000006
	v_lshl_or_b32 v1, v1, 10, v10                              // 00000000229C: D6560001 04291501
	ds_load_b128 v[10:13], v1 offset:6160                      // 0000000022A4: DBFC1810 0A000001
	s_waitcnt lgkmcnt(1)                                       // 0000000022AC: BF89FC17
	v_max3_f32 v1, |v6|, 0, |v7|                               // 0000000022B0: D61C0501 041D0106
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000022B8: BF8700A1
	v_max3_f32 v1, v1, |v8|, |v9|                              // 0000000022BC: D61C0601 04261101
	s_waitcnt lgkmcnt(0)                                       // 0000000022C4: BF89FC07
	v_max3_f32 v1, v1, |v10|, |v11|                            // 0000000022C8: D61C0601 042E1501
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000022D0: BF870091
	v_max3_f32 v1, v1, |v12|, |v13|                            // 0000000022D4: D61C0601 04361901
	v_mov_b32_dpp v14, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000022DC: 7E1C02FA FF091101
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000022E4: BF870091
	v_max_f32_e32 v14, v14, v14                                // 0000000022E8: 201C1D0E
	v_max_f32_e32 v1, v1, v14                                  // 0000000022EC: 20021D01
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000022F0: BF870091
	v_mov_b32_dpp v14, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000022F4: 7E1C02FA FF091201
	v_max_f32_e32 v14, v14, v14                                // 0000000022FC: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002300: BF870091
	v_max_f32_e32 v1, v1, v14                                  // 000000002304: 20021D01
	v_mov_b32_dpp v14, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002308: 7E1C02FA FF091401
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002310: BF870091
	v_max_f32_e32 v14, v14, v14                                // 000000002314: 201C1D0E
	v_max_f32_e32 v1, v1, v14                                  // 000000002318: 20021D01
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000231C: BF870091
	v_mov_b32_dpp v14, v1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002320: 7E1C02FA FF091801
	v_max_f32_e32 v14, v14, v14                                // 000000002328: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000232C: BF870091
	v_max_f32_e32 v1, v1, v14                                  // 000000002330: 20021D01
	v_readlane_b32 s0, v1, 31                                  // 000000002334: D7600000 00013F01
	v_readlane_b32 s2, v1, 15                                  // 00000000233C: D7600002 00011F01
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000002344: BF870112
	v_max_f32_e64 v1, s0, s0                                   // 000000002348: D5100001 00000000
	v_max_f32_e64 v14, s2, s2                                  // 000000002350: D510000E 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002358: BF870091
	v_max_f32_e32 v1, v14, v1                                  // 00000000235C: 2002030E
	v_div_scale_f32 v14, null, 0x42fe0000, 0x42fe0000, v1      // 000000002360: D6FC7C0E 0405FEFF 42FE0000
	v_div_scale_f32 v17, vcc_lo, v1, 0x42fe0000, v1            // 00000000236C: D6FC6A11 0405FF01 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002378: BF8700B2
	v_rcp_f32_e32 v15, v14                                     // 00000000237C: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 000000002380: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 000000002384: D6130010 23CA1F0E
	v_fmac_f32_e32 v15, v16, v15                               // 00000000238C: 561E1F10
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002390: BF870091
	v_mul_f32_e32 v16, v17, v15                                // 000000002394: 10201F11
	v_fma_f32 v18, -v14, v16, v17                              // 000000002398: D6130012 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023A0: BF870091
	v_fmac_f32_e32 v16, v18, v15                               // 0000000023A4: 56201F12
	v_fma_f32 v14, -v14, v16, v17                              // 0000000023A8: D613000E 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023B0: BF870091
	v_div_fmas_f32 v14, v14, v15, v16                          // 0000000023B4: D637000E 04421F0E
	v_div_fixup_f32 v1, v14, 0x42fe0000, v1                    // 0000000023BC: D6270001 0405FF0E 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000023C8: BF870121
	v_div_scale_f32 v14, null, v1, v1, 1.0                     // 0000000023CC: D6FC7C0E 03CA0301
	v_div_scale_f32 v17, vcc_lo, 1.0, v1, 1.0                  // 0000000023D4: D6FC6A11 03CA02F2
	v_rcp_f32_e32 v15, v14                                     // 0000000023DC: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 0000000023E0: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 0000000023E4: D6130010 23CA1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023EC: BF870091
	v_fmac_f32_e32 v15, v16, v15                               // 0000000023F0: 561E1F10
	v_mul_f32_e32 v16, v17, v15                                // 0000000023F4: 10201F11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023F8: BF870091
	v_fma_f32 v18, -v14, v16, v17                              // 0000000023FC: D6130012 2446210E
	v_fmac_f32_e32 v16, v18, v15                               // 000000002404: 56201F12
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002408: BF870091
	v_fma_f32 v14, -v14, v16, v17                              // 00000000240C: D613000E 2446210E
	v_div_fmas_f32 v14, v14, v15, v16                          // 000000002414: D637000E 04421F0E
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 00000000241C: 7C3A0280
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002420: BF870092
	v_div_fixup_f32 v14, v14, v1, 1.0                          // 000000002424: D627000E 03CA030E
	v_cndmask_b32_e32 v14, 0, v14, vcc_lo                      // 00000000242C: 021C1C80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002430: BF870091
	v_mul_f32_e32 v7, v7, v14                                  // 000000002434: 100E1D07
	v_rndne_f32_e32 v7, v7                                     // 000000002438: 7E0E4707
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000243C: BF870091
	v_cvt_i32_f32_e32 v7, v7                                   // 000000002440: 7E0E1107
	v_lshlrev_b32_e32 v7, 8, v7                                // 000000002444: 300E0E88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000002448: BF8701B1
	v_dual_mul_f32 v12, v12, v14 :: v_dual_and_b32 v7, 0xff00, v7// 00000000244C: C8E41D0C 0C060EFF 0000FF00
	v_mul_f32_e32 v8, v8, v14                                  // 000000002458: 10101D08
	v_mul_f32_e32 v10, v10, v14                                // 00000000245C: 10141D0A
	v_rndne_f32_e32 v12, v12                                   // 000000002460: 7E18470C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002464: BF870193
	v_rndne_f32_e32 v8, v8                                     // 000000002468: 7E104708
	v_rndne_f32_e32 v10, v10                                   // 00000000246C: 7E14470A
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000002470: BF870223
	v_cvt_i32_f32_e32 v12, v12                                 // 000000002474: 7E18110C
	v_mul_f32_e32 v11, v11, v14                                // 000000002478: 10161D0B
	v_cvt_i32_f32_e32 v8, v8                                   // 00000000247C: 7E101108
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002480: BF870214
	v_cvt_i32_f32_e32 v10, v10                                 // 000000002484: 7E14110A
	v_lshlrev_b32_e32 v12, 16, v12                             // 000000002488: 30181890
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 00000000248C: BF8701B4
	v_rndne_f32_e32 v11, v11                                   // 000000002490: 7E16470B
	v_mul_f32_e32 v6, v6, v14                                  // 000000002494: 100C1D06
	v_dual_mul_f32 v13, v13, v14 :: v_dual_lshlrev_b32 v8, 16, v8// 000000002498: C8E21D0D 0D081090
	v_cvt_i32_f32_e32 v11, v11                                 // 0000000024A0: 7E16110B
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000024A4: BF870193
	v_rndne_f32_e32 v6, v6                                     // 0000000024A8: 7E0C4706
	v_and_b32_e32 v8, 0xff0000, v8                             // 0000000024AC: 361010FF 00FF0000
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000024B4: BF870214
	v_rndne_f32_e32 v13, v13                                   // 0000000024B8: 7E1A470D
	v_lshlrev_b32_e32 v11, 8, v11                              // 0000000024BC: 30161688
	v_mul_f32_e32 v9, v9, v14                                  // 0000000024C0: 10121D09
	v_cvt_i32_f32_e32 v6, v6                                   // 0000000024C4: 7E0C1106
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000024C8: BF870194
	v_cvt_i32_f32_e32 v13, v13                                 // 0000000024CC: 7E1A110D
	v_rndne_f32_e32 v9, v9                                     // 0000000024D0: 7E124709
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000024D4: BF870091
	v_cvt_i32_f32_e32 v9, v9                                   // 0000000024D8: 7E121109
	v_perm_b32 v6, v9, v6, 0x40c0c00                           // 0000000024DC: D6440006 03FE0D09 040C0C00
	s_delay_alu instid0(VALU_DEP_4)                            // 0000000024E8: BF870004
	v_perm_b32 v9, v13, v10, 0x40c0c00                         // 0000000024EC: D6440009 03FE150D 040C0C00
	v_and_b32_e32 v10, 0xff00, v11                             // 0000000024F8: 361416FF 0000FF00
	v_and_b32_e32 v11, 0xff0000, v12                           // 000000002500: 361618FF 00FF0000
	v_add_co_u32 v12, vcc_lo, s20, v2                          // 000000002508: D7006A0C 00020414
	v_add_co_ci_u32_e32 v13, vcc_lo, s21, v3, vcc_lo           // 000000002510: 401A0615
	v_or3_b32 v2, v6, v7, v8                                   // 000000002514: D6580002 04220F06
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 00000000251C: BF870223
	v_add_co_u32 v6, vcc_lo, v12, v0                           // 000000002520: D7006A06 0002010C
	v_or3_b32 v3, v9, v10, v11                                 // 000000002528: D6580003 042E1509
	v_add_co_ci_u32_e32 v7, vcc_lo, 0, v13, vcc_lo             // 000000002530: 400E1A80
	global_store_b64 v[6:7], v[2:3], off                       // 000000002534: DC6E0000 007C0206
	s_and_b32 exec_lo, exec_lo, s1                             // 00000000253C: 8B7E017E
	s_cbranch_execz 5                                          // 000000002540: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2558>
	v_add_co_u32 v2, vcc_lo, s22, v4                           // 000000002544: D7006A02 00020816
	v_add_co_ci_u32_e32 v3, vcc_lo, s23, v5, vcc_lo            // 00000000254C: 40060A17
	global_store_b32 v[2:3], v1, off                           // 000000002550: DC6A0000 007C0102
	s_endpgm                                                   // 000000002558: BFB00000
	s_code_end                                                 // 00000000255C: BF9F0000
	s_code_end                                                 // 000000002560: BF9F0000
	s_code_end                                                 // 000000002564: BF9F0000
	s_code_end                                                 // 000000002568: BF9F0000
	s_code_end                                                 // 00000000256C: BF9F0000
	s_code_end                                                 // 000000002570: BF9F0000
	s_code_end                                                 // 000000002574: BF9F0000
	s_code_end                                                 // 000000002578: BF9F0000
	s_code_end                                                 // 00000000257C: BF9F0000
	s_code_end                                                 // 000000002580: BF9F0000
	s_code_end                                                 // 000000002584: BF9F0000
	s_code_end                                                 // 000000002588: BF9F0000
	s_code_end                                                 // 00000000258C: BF9F0000
	s_code_end                                                 // 000000002590: BF9F0000
	s_code_end                                                 // 000000002594: BF9F0000
	s_code_end                                                 // 000000002598: BF9F0000
	s_code_end                                                 // 00000000259C: BF9F0000
	s_code_end                                                 // 0000000025A0: BF9F0000
	s_code_end                                                 // 0000000025A4: BF9F0000
	s_code_end                                                 // 0000000025A8: BF9F0000
	s_code_end                                                 // 0000000025AC: BF9F0000
	s_code_end                                                 // 0000000025B0: BF9F0000
	s_code_end                                                 // 0000000025B4: BF9F0000
	s_code_end                                                 // 0000000025B8: BF9F0000
	s_code_end                                                 // 0000000025BC: BF9F0000
	s_code_end                                                 // 0000000025C0: BF9F0000
	s_code_end                                                 // 0000000025C4: BF9F0000
	s_code_end                                                 // 0000000025C8: BF9F0000
	s_code_end                                                 // 0000000025CC: BF9F0000
	s_code_end                                                 // 0000000025D0: BF9F0000
	s_code_end                                                 // 0000000025D4: BF9F0000
	s_code_end                                                 // 0000000025D8: BF9F0000
	s_code_end                                                 // 0000000025DC: BF9F0000
	s_code_end                                                 // 0000000025E0: BF9F0000
	s_code_end                                                 // 0000000025E4: BF9F0000
	s_code_end                                                 // 0000000025E8: BF9F0000
	s_code_end                                                 // 0000000025EC: BF9F0000
	s_code_end                                                 // 0000000025F0: BF9F0000
	s_code_end                                                 // 0000000025F4: BF9F0000
	s_code_end                                                 // 0000000025F8: BF9F0000
	s_code_end                                                 // 0000000025FC: BF9F0000
	s_code_end                                                 // 000000002600: BF9F0000
	s_code_end                                                 // 000000002604: BF9F0000
	s_code_end                                                 // 000000002608: BF9F0000
	s_code_end                                                 // 00000000260C: BF9F0000
	s_code_end                                                 // 000000002610: BF9F0000
	s_code_end                                                 // 000000002614: BF9F0000
	s_code_end                                                 // 000000002618: BF9F0000
	s_code_end                                                 // 00000000261C: BF9F0000
	s_code_end                                                 // 000000002620: BF9F0000
	s_code_end                                                 // 000000002624: BF9F0000
	s_code_end                                                 // 000000002628: BF9F0000
	s_code_end                                                 // 00000000262C: BF9F0000
	s_code_end                                                 // 000000002630: BF9F0000
	s_code_end                                                 // 000000002634: BF9F0000
	s_code_end                                                 // 000000002638: BF9F0000
	s_code_end                                                 // 00000000263C: BF9F0000
	s_code_end                                                 // 000000002640: BF9F0000
	s_code_end                                                 // 000000002644: BF9F0000
	s_code_end                                                 // 000000002648: BF9F0000
	s_code_end                                                 // 00000000264C: BF9F0000
	s_code_end                                                 // 000000002650: BF9F0000
	s_code_end                                                 // 000000002654: BF9F0000
	s_code_end                                                 // 000000002658: BF9F0000
	s_code_end                                                 // 00000000265C: BF9F0000
	s_code_end                                                 // 000000002660: BF9F0000
	s_code_end                                                 // 000000002664: BF9F0000
	s_code_end                                                 // 000000002668: BF9F0000
	s_code_end                                                 // 00000000266C: BF9F0000
	s_code_end                                                 // 000000002670: BF9F0000
	s_code_end                                                 // 000000002674: BF9F0000
	s_code_end                                                 // 000000002678: BF9F0000
	s_code_end                                                 // 00000000267C: BF9F0000
	s_code_end                                                 // 000000002680: BF9F0000
	s_code_end                                                 // 000000002684: BF9F0000
	s_code_end                                                 // 000000002688: BF9F0000
	s_code_end                                                 // 00000000268C: BF9F0000
	s_code_end                                                 // 000000002690: BF9F0000
	s_code_end                                                 // 000000002694: BF9F0000
	s_code_end                                                 // 000000002698: BF9F0000
	s_code_end                                                 // 00000000269C: BF9F0000
	s_code_end                                                 // 0000000026A0: BF9F0000
	s_code_end                                                 // 0000000026A4: BF9F0000
	s_code_end                                                 // 0000000026A8: BF9F0000
	s_code_end                                                 // 0000000026AC: BF9F0000
	s_code_end                                                 // 0000000026B0: BF9F0000
	s_code_end                                                 // 0000000026B4: BF9F0000
	s_code_end                                                 // 0000000026B8: BF9F0000
	s_code_end                                                 // 0000000026BC: BF9F0000
	s_code_end                                                 // 0000000026C0: BF9F0000
	s_code_end                                                 // 0000000026C4: BF9F0000
	s_code_end                                                 // 0000000026C8: BF9F0000
	s_code_end                                                 // 0000000026CC: BF9F0000
	s_code_end                                                 // 0000000026D0: BF9F0000
	s_code_end                                                 // 0000000026D4: BF9F0000
	s_code_end                                                 // 0000000026D8: BF9F0000
	s_code_end                                                 // 0000000026DC: BF9F0000
	s_code_end                                                 // 0000000026E0: BF9F0000
	s_code_end                                                 // 0000000026E4: BF9F0000
	s_code_end                                                 // 0000000026E8: BF9F0000
	s_code_end                                                 // 0000000026EC: BF9F0000
	s_code_end                                                 // 0000000026F0: BF9F0000
	s_code_end                                                 // 0000000026F4: BF9F0000
	s_code_end                                                 // 0000000026F8: BF9F0000
	s_code_end                                                 // 0000000026FC: BF9F0000
