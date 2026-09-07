
/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad/isa/attn_prep_24_4_256_64_8204_11_k4jv4�_c9769d79.elf:	file format elf64-amdgpu

Disassembly of section .text:

0000000000000000 <attn_prep_24_4_256_64_8204_11_k4jv4>:
	s_load_b64 s[28:29], s[0:1], 0x58                          // 000000000000: F4040700 F8000058
	s_lshr_b32 s12, s15, 2                                     // 000000000008: 850C820F
	s_waitcnt lgkmcnt(0)                                       // 00000000000C: BF89FC07
	s_load_b32 s2, s[28:29], 0x4                               // 000000000010: F400008E F8000004
	s_waitcnt lgkmcnt(0)                                       // 000000000018: BF89FC07
	s_cmp_ge_u32 s12, s2                                       // 00000000001C: BF09020C
	s_cbranch_scc1 2418                                        // 000000000020: BFA20972 <attn_prep_24_4_256_64_8204_11_k4jv4+0x25ec>
	s_load_b32 s13, s[28:29], null                             // 000000000024: F400034E F8000000
	s_clause 0x3                                               // 00000000002C: BF850003
	s_load_b64 s[2:3], s[0:1], 0x50                            // 000000000030: F4040080 F8000050
	s_load_b128 s[24:27], s[0:1], 0x40                         // 000000000038: F4080600 F8000040
	s_load_b256 s[16:23], s[0:1], null                         // 000000000040: F40C0400 F8000000
	s_load_b256 s[4:11], s[0:1], 0x20                          // 000000000048: F40C0100 F8000020
	s_waitcnt lgkmcnt(0)                                       // 000000000050: BF89FC07
	s_add_i32 s13, s13, s12                                    // 000000000054: 810D0C0D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000058: BF870009
	v_mov_b32_e32 v1, s13                                      // 00000000005C: 7E02020D
	s_cmpk_lt_u32 s13, 0x200c                                  // 000000000060: B68D200C
	s_cbranch_scc1 24                                          // 000000000064: BFA20018 <attn_prep_24_4_256_64_8204_11_k4jv4+0xc8>
	v_dual_mov_b32 v2, s28 :: v_dual_mov_b32 v3, s29           // 000000000068: CA10001C 0202001D
	s_mov_b32 s0, 0                                            // 000000000070: BE800080
	s_mov_b32 s1, 0                                            // 000000000074: BE810080
	flat_load_b32 v1, v[2:3] glc dlc                           // 000000000078: DC506000 017C0002
	s_waitcnt vmcnt(0)                                         // 000000000080: BF8903F7
	s_add_i32 s13, s1, 1                                       // 000000000084: 810D8101
	s_cmp_gt_u32 s1, 0xf423e                                   // 000000000088: BF08FF01 000F423E
	s_cselect_b32 s1, -1, 0                                    // 000000000090: 980180C1
	s_waitcnt lgkmcnt(0)                                       // 000000000094: BF89FC07
	v_add_nc_u32_e32 v1, s12, v1                               // 000000000098: 4A02020C
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 00000000009C: BF8704A1
	v_cmp_gt_u32_e32 vcc_lo, 0x200c, v1                        // 0000000000A0: 7C9802FF 0000200C
	s_or_b32 s1, s1, vcc_lo                                    // 0000000000A8: 8C016A01
	s_and_b32 s1, exec_lo, s1                                  // 0000000000AC: 8B01017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000000B0: BF870009
	s_or_b32 s0, s1, s0                                        // 0000000000B4: 8C000001
	s_mov_b32 s1, s13                                          // 0000000000B8: BE81000D
	s_and_not1_b32 exec_lo, exec_lo, s0                        // 0000000000BC: 917E007E
	s_cbranch_execnz 65517                                     // 0000000000C0: BFA6FFED <attn_prep_24_4_256_64_8204_11_k4jv4+0x78>
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000000C4: 8C7E007E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000000C8: BF870009
	s_mov_b32 s0, exec_lo                                      // 0000000000CC: BE80007E
	v_cmpx_gt_u32_e32 16, v0                                   // 0000000000D0: 7D980090
	s_cbranch_execz 299                                        // 0000000000D4: BFA5012B <attn_prep_24_4_256_64_8204_11_k4jv4+0x584>
	s_mov_b32 s1, 0                                            // 0000000000D8: BE810080
	s_mov_b32 s14, 0                                           // 0000000000DC: BE8E0080
	s_mov_b32 s13, exec_lo                                     // 0000000000E0: BE8D007E
	v_cmpx_lt_i32_e32 6, v0                                    // 0000000000E4: 7D820086
	s_xor_b32 s13, exec_lo, s13                                // 0000000000E8: 8D0D0D7E
	s_cbranch_execz 77                                         // 0000000000EC: BFA5004D <attn_prep_24_4_256_64_8204_11_k4jv4+0x224>
	s_mov_b32 s14, exec_lo                                     // 0000000000F0: BE8E007E
	v_cmpx_lt_i32_e32 10, v0                                   // 0000000000F4: 7D82008A
	s_xor_b32 s14, exec_lo, s14                                // 0000000000F8: 8D0E0E7E
	s_cbranch_execz 38                                         // 0000000000FC: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x198>
	s_mov_b32 s28, exec_lo                                     // 000000000100: BE9C007E
	v_cmpx_lt_i32_e32 12, v0                                   // 000000000104: 7D82008C
	s_xor_b32 s28, exec_lo, s28                                // 000000000108: 8D1C1C7E
	s_cbranch_execz 19                                         // 00000000010C: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x15c>
	s_mov_b32 s29, exec_lo                                     // 000000000110: BE9D007E
	v_cmpx_lt_i32_e32 13, v0                                   // 000000000114: 7D82008D
	s_xor_b32 s29, exec_lo, s29                                // 000000000118: 8D1D1D7E
	s_cbranch_execz 11                                         // 00000000011C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x14c>
	s_mov_b32 s31, exec_lo                                     // 000000000120: BE9F007E
	v_cmpx_ne_u32_e32 14, v0                                   // 000000000124: 7D9A008E
	s_xor_b32 s31, exec_lo, s31                                // 000000000128: 8D1F1F7E
	s_mov_b32 s30, 0x402ee2bf                                  // 00000000012C: BE9E00FF 402EE2BF
	s_or_saveexec_b32 s31, s31                                 // 000000000134: BE9F221F
	v_mov_b32_e32 v2, s30                                      // 000000000138: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s31                            // 00000000013C: 8D7E1F7E
	v_mov_b32_e32 v2, 0x40046ac7                               // 000000000140: 7E0402FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000148: 8C7E1F7E
	s_and_not1_saveexec_b32 s29, s29                           // 00000000014C: BE9D301D
	v_mov_b32_e32 v2, 0x3fcf1c25                               // 000000000150: 7E0402FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000158: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 00000000015C: BE9C301C
	s_cbranch_execz 11                                         // 000000000160: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x190>
	s_mov_b32 s29, exec_lo                                     // 000000000164: BE9D007E
	v_cmpx_lt_i32_e32 11, v0                                   // 000000000168: 7D82008B
	s_xor_b32 s29, exec_lo, s29                                // 00000000016C: 8D1D1D7E
	s_mov_b32 s30, 0x3fa0cc2f                                  // 000000000170: BE9E00FF 3FA0CC2F
	s_or_saveexec_b32 s29, s29                                 // 000000000178: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 00000000017C: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 000000000180: 8D7E1D7E
	v_mov_b32_e32 v2, 0x3f713d3a                               // 000000000184: 7E0402FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000018C: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000190: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000194: 8C7E1C7E
	s_and_not1_saveexec_b32 s14, s14                           // 000000000198: BE8E300E
	s_cbranch_execz 30                                         // 00000000019C: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x218>
	s_mov_b32 s28, exec_lo                                     // 0000000001A0: BE9C007E
	v_cmpx_lt_i32_e32 8, v0                                    // 0000000001A4: 7D820088
	s_xor_b32 s28, exec_lo, s28                                // 0000000001A8: 8D1C1C7E
	s_cbranch_execz 11                                         // 0000000001AC: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x1dc>
	s_mov_b32 s29, exec_lo                                     // 0000000001B0: BE9D007E
	v_cmpx_lt_i32_e32 9, v0                                    // 0000000001B4: 7D820089
	s_xor_b32 s29, exec_lo, s29                                // 0000000001B8: 8D1D1D7E
	s_mov_b32 s30, 0x3f28215d                                  // 0000000001BC: BE9E00FF 3F28215D
	s_or_saveexec_b32 s29, s29                                 // 0000000001C4: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 0000000001C8: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 0000000001CC: 8D7E1D7E
	v_mov_b32_e32 v2, 0x3ec6ae44                               // 0000000001D0: 7E0402FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000001D8: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 0000000001DC: BE9C301C
	s_cbranch_execz 11                                         // 0000000001E0: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x210>
	s_mov_b32 s29, exec_lo                                     // 0000000001E4: BE9D007E
	v_cmpx_lt_i32_e32 7, v0                                    // 0000000001E8: 7D820087
	s_xor_b32 s29, exec_lo, s29                                // 0000000001EC: 8D1D1D7E
	s_mov_b32 s30, 0x3e0379fb                                  // 0000000001F0: BE9E00FF 3E0379FB
	s_or_saveexec_b32 s29, s29                                 // 0000000001F8: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 0000000001FC: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 000000000200: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbe0379fb                               // 000000000204: 7E0402FF BE0379FB
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000020C: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000210: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000214: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000218: BF870499
	s_or_b32 exec_lo, exec_lo, s14                             // 00000000021C: 8C7E0E7E
	s_mov_b32 s14, exec_lo                                     // 000000000220: BE8E007E
	s_and_not1_saveexec_b32 s13, s13                           // 000000000224: BE8D300D
	s_cbranch_execz 67                                         // 000000000228: BFA50043 <attn_prep_24_4_256_64_8204_11_k4jv4+0x338>
	s_mov_b32 s28, s14                                         // 00000000022C: BE9C000E
	s_mov_b32 s1, exec_lo                                      // 000000000230: BE81007E
	v_cmpx_lt_i32_e32 2, v0                                    // 000000000234: 7D820082
	s_xor_b32 s1, exec_lo, s1                                  // 000000000238: 8D01017E
	s_cbranch_execz 31                                         // 00000000023C: BFA5001F <attn_prep_24_4_256_64_8204_11_k4jv4+0x2bc>
	s_mov_b32 s28, exec_lo                                     // 000000000240: BE9C007E
	v_cmpx_lt_i32_e32 4, v0                                    // 000000000244: 7D820084
	s_xor_b32 s28, exec_lo, s28                                // 000000000248: 8D1C1C7E
	s_cbranch_execz 11                                         // 00000000024C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x27c>
	s_mov_b32 s29, exec_lo                                     // 000000000250: BE9D007E
	v_cmpx_lt_i32_e32 5, v0                                    // 000000000254: 7D820085
	s_xor_b32 s29, exec_lo, s29                                // 000000000258: 8D1D1D7E
	s_mov_b32 s30, 0xbec6ae44                                  // 00000000025C: BE9E00FF BEC6AE44
	s_or_saveexec_b32 s29, s29                                 // 000000000264: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 000000000268: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 00000000026C: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbf28215d                               // 000000000270: 7E0402FF BF28215D
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000278: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 00000000027C: BE9C301C
	s_cbranch_execz 11                                         // 000000000280: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x2b0>
	s_mov_b32 s29, exec_lo                                     // 000000000284: BE9D007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000288: 7D820083
	s_xor_b32 s29, exec_lo, s29                                // 00000000028C: 8D1D1D7E
	s_mov_b32 s30, 0xbf713d3a                                  // 000000000290: BE9E00FF BF713D3A
	s_or_saveexec_b32 s29, s29                                 // 000000000298: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 00000000029C: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 0000000002A0: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbfa0cc2f                               // 0000000002A4: 7E0402FF BFA0CC2F
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000002AC: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 0000000002B0: BF870499
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000002B4: 8C7E1C7E
	s_or_b32 s28, s14, exec_lo                                 // 0000000002B8: 8C1C7E0E
	s_or_saveexec_b32 s1, s1                                   // 0000000002BC: BE812201
	s_mov_b32 s29, 0                                           // 0000000002C0: BE9D0080
	s_xor_b32 exec_lo, exec_lo, s1                             // 0000000002C4: 8D7E017E
	s_cbranch_execz 21                                         // 0000000002C8: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0x320>
	s_mov_b32 s30, -1                                          // 0000000002CC: BE9E00C1
	s_mov_b32 s31, s28                                         // 0000000002D0: BE9F001C
	s_mov_b32 s29, exec_lo                                     // 0000000002D4: BE9D007E
	v_cmpx_lt_i32_e32 0, v0                                    // 0000000002D8: 7D820080
	s_cbranch_execz 10                                         // 0000000002DC: BFA5000A <attn_prep_24_4_256_64_8204_11_k4jv4+0x308>
	v_mov_b32_e32 v2, 0xc0046ac7                               // 0000000002E0: 7E0402FF C0046AC7
	s_mov_b32 s30, exec_lo                                     // 0000000002E8: BE9E007E
	v_cmpx_lt_i32_e32 1, v0                                    // 0000000002EC: 7D820081
	v_mov_b32_e32 v2, 0xbfcf1c25                               // 0000000002F0: 7E0402FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000002F8: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000002FC: BF870009
	s_xor_b32 s30, exec_lo, -1                                 // 000000000300: 8D1EC17E
	s_or_b32 s31, s28, exec_lo                                 // 000000000304: 8C1F7E1C
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000308: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000030C: BF870009
	s_and_not1_b32 s28, s28, exec_lo                           // 000000000310: 911C7E1C
	s_and_b32 s31, s31, exec_lo                                // 000000000314: 8B1F7E1F
	s_and_b32 s29, s30, exec_lo                                // 000000000318: 8B1D7E1E
	s_or_b32 s28, s28, s31                                     // 00000000031C: 8C1C1F1C
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000320: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000324: BF870009
	s_and_not1_b32 s14, s14, exec_lo                           // 000000000328: 910E7E0E
	s_and_b32 s28, s28, exec_lo                                // 00000000032C: 8B1C7E1C
	s_and_b32 s1, s29, exec_lo                                 // 000000000330: 8B017E1D
	s_or_b32 s14, s14, s28                                     // 000000000334: 8C0E1C0E
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000338: 8C7E0D7E
	s_and_saveexec_b32 s13, s14                                // 00000000033C: BE8D200E
	s_cbranch_execz 132                                        // 000000000340: BFA50084 <attn_prep_24_4_256_64_8204_11_k4jv4+0x554>
	v_lshlrev_b32_e32 v3, 2, v0                                // 000000000344: 30060082
	s_mov_b32 s14, exec_lo                                     // 000000000348: BE8E007E
	ds_store_b32 v3, v2 offset:17920                           // 00000000034C: D8344600 00000203
	v_cmpx_lt_i32_e32 7, v0                                    // 000000000354: 7D820087
	s_xor_b32 s14, exec_lo, s14                                // 000000000358: 8D0E0E7E
	s_cbranch_execz 65                                         // 00000000035C: BFA50041 <attn_prep_24_4_256_64_8204_11_k4jv4+0x464>
	s_mov_b32 s28, exec_lo                                     // 000000000360: BE9C007E
	v_cmpx_lt_i32_e32 10, v0                                   // 000000000364: 7D82008A
	s_xor_b32 s28, exec_lo, s28                                // 000000000368: 8D1C1C7E
	s_cbranch_execz 38                                         // 00000000036C: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x408>
	s_mov_b32 s29, exec_lo                                     // 000000000370: BE9D007E
	v_cmpx_lt_i32_e32 12, v0                                   // 000000000374: 7D82008C
	s_xor_b32 s29, exec_lo, s29                                // 000000000378: 8D1D1D7E
	s_cbranch_execz 19                                         // 00000000037C: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x3cc>
	s_mov_b32 s30, exec_lo                                     // 000000000380: BE9E007E
	v_cmpx_lt_i32_e32 13, v0                                   // 000000000384: 7D82008D
	s_xor_b32 s30, exec_lo, s30                                // 000000000388: 8D1E1E7E
	s_cbranch_execz 11                                         // 00000000038C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x3bc>
	s_mov_b32 s31, exec_lo                                     // 000000000390: BE9F007E
	v_cmpx_ne_u32_e32 14, v0                                   // 000000000394: 7D9A008E
	s_xor_b32 s31, exec_lo, s31                                // 000000000398: 8D1F1F7E
	s_mov_b32 s33, 0x402ee2bf                                  // 00000000039C: BEA100FF 402EE2BF
	s_or_saveexec_b32 s31, s31                                 // 0000000003A4: BE9F221F
	v_mov_b32_e32 v3, s33                                      // 0000000003A8: 7E060221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000003AC: 8D7E1F7E
	v_mov_b32_e32 v3, 0x40046ac7                               // 0000000003B0: 7E0602FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000003B8: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 0000000003BC: BE9E301E
	v_mov_b32_e32 v3, 0x3fcf1c25                               // 0000000003C0: 7E0602FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000003C8: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 0000000003CC: BE9D301D
	s_cbranch_execz 11                                         // 0000000003D0: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x400>
	s_mov_b32 s30, exec_lo                                     // 0000000003D4: BE9E007E
	v_cmpx_lt_i32_e32 11, v0                                   // 0000000003D8: 7D82008B
	s_xor_b32 s30, exec_lo, s30                                // 0000000003DC: 8D1E1E7E
	s_mov_b32 s31, 0x3fa0cc2f                                  // 0000000003E0: BE9F00FF 3FA0CC2F
	s_or_saveexec_b32 s30, s30                                 // 0000000003E8: BE9E221E
	v_mov_b32_e32 v3, s31                                      // 0000000003EC: 7E06021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000003F0: 8D7E1E7E
	v_mov_b32_e32 v3, 0x3f713d3a                               // 0000000003F4: 7E0602FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000003FC: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000400: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000404: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000408: BE9C301C
	s_cbranch_execz 19                                         // 00000000040C: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x45c>
	s_mov_b32 s29, exec_lo                                     // 000000000410: BE9D007E
	v_cmpx_lt_i32_e32 8, v0                                    // 000000000414: 7D820088
	s_xor_b32 s29, exec_lo, s29                                // 000000000418: 8D1D1D7E
	s_cbranch_execz 11                                         // 00000000041C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x44c>
	s_mov_b32 s30, exec_lo                                     // 000000000420: BE9E007E
	v_cmpx_lt_i32_e32 9, v0                                    // 000000000424: 7D820089
	s_xor_b32 s30, exec_lo, s30                                // 000000000428: 8D1E1E7E
	s_mov_b32 s31, 0x3f28215d                                  // 00000000042C: BE9F00FF 3F28215D
	s_or_saveexec_b32 s30, s30                                 // 000000000434: BE9E221E
	v_mov_b32_e32 v3, s31                                      // 000000000438: 7E06021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 00000000043C: 8D7E1E7E
	v_mov_b32_e32 v3, 0x3ec6ae44                               // 000000000440: 7E0602FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000448: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 00000000044C: BE9D301D
	v_mov_b32_e32 v3, 0x3e0379fb                               // 000000000450: 7E0602FF 3E0379FB
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000458: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000045C: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000460: 8C7E1C7E
	s_and_not1_saveexec_b32 s14, s14                           // 000000000464: BE8E300E
	s_cbranch_execz 56                                         // 000000000468: BFA50038 <attn_prep_24_4_256_64_8204_11_k4jv4+0x54c>
	s_mov_b32 s28, exec_lo                                     // 00000000046C: BE9C007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000470: 7D820083
	s_xor_b32 s28, exec_lo, s28                                // 000000000474: 8D1C1C7E
	s_cbranch_execz 30                                         // 000000000478: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x4f4>
	s_mov_b32 s29, exec_lo                                     // 00000000047C: BE9D007E
	v_cmpx_lt_i32_e32 5, v0                                    // 000000000480: 7D820085
	s_xor_b32 s29, exec_lo, s29                                // 000000000484: 8D1D1D7E
	s_cbranch_execz 11                                         // 000000000488: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x4b8>
	s_mov_b32 s30, exec_lo                                     // 00000000048C: BE9E007E
	v_cmpx_lt_i32_e32 6, v0                                    // 000000000490: 7D820086
	s_xor_b32 s30, exec_lo, s30                                // 000000000494: 8D1E1E7E
	s_mov_b32 s31, 0xbe0379fb                                  // 000000000498: BE9F00FF BE0379FB
	s_or_saveexec_b32 s30, s30                                 // 0000000004A0: BE9E221E
	v_mov_b32_e32 v3, s31                                      // 0000000004A4: 7E06021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000004A8: 8D7E1E7E
	v_mov_b32_e32 v3, 0xbec6ae44                               // 0000000004AC: 7E0602FF BEC6AE44
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000004B4: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 0000000004B8: BE9D301D
	s_cbranch_execz 11                                         // 0000000004BC: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x4ec>
	s_mov_b32 s30, exec_lo                                     // 0000000004C0: BE9E007E
	v_cmpx_lt_i32_e32 4, v0                                    // 0000000004C4: 7D820084
	s_xor_b32 s30, exec_lo, s30                                // 0000000004C8: 8D1E1E7E
	s_mov_b32 s31, 0xbf28215d                                  // 0000000004CC: BE9F00FF BF28215D
	s_or_saveexec_b32 s30, s30                                 // 0000000004D4: BE9E221E
	v_mov_b32_e32 v3, s31                                      // 0000000004D8: 7E06021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000004DC: 8D7E1E7E
	v_mov_b32_e32 v3, 0xbf713d3a                               // 0000000004E0: 7E0602FF BF713D3A
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000004E8: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004EC: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000004F0: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 0000000004F4: BE9C301C
	s_cbranch_execz 18                                         // 0000000004F8: BFA50012 <attn_prep_24_4_256_64_8204_11_k4jv4+0x544>
	v_mov_b32_e32 v3, 0xc0046ac7                               // 0000000004FC: 7E0602FF C0046AC7
	s_mov_b32 s29, exec_lo                                     // 000000000504: BE9D007E
	v_cmpx_lt_i32_e32 1, v0                                    // 000000000508: 7D820081
	s_cbranch_execz 11                                         // 00000000050C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x53c>
	s_mov_b32 s30, exec_lo                                     // 000000000510: BE9E007E
	v_cmpx_lt_i32_e32 2, v0                                    // 000000000514: 7D820082
	s_xor_b32 s30, exec_lo, s30                                // 000000000518: 8D1E1E7E
	s_mov_b32 s31, 0xbfa0cc2f                                  // 00000000051C: BE9F00FF BFA0CC2F
	s_or_saveexec_b32 s30, s30                                 // 000000000524: BE9E221E
	v_mov_b32_e32 v3, s31                                      // 000000000528: 7E06021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 00000000052C: 8D7E1E7E
	v_mov_b32_e32 v3, 0xbfcf1c25                               // 000000000530: 7E0602FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000538: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000053C: BF870009
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000540: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000544: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000548: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000054C: BF870009
	s_or_b32 exec_lo, exec_lo, s14                             // 000000000550: 8C7E0E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000554: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000558: 8C7E0D7E
	s_and_saveexec_b32 s13, s1                                 // 00000000055C: BE8D2001
	v_dual_mov_b32 v3, 0xc02ee2bf :: v_dual_mov_b32 v2, 0      // 000000000560: CA1000FF 03020080 C02EE2BF
	ds_store_b32 v2, v3 offset:17920                           // 00000000056C: D8344600 00000302
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000574: 8C7E0D7E
	v_lshlrev_b32_e32 v2, 2, v0                                // 000000000578: 30040082
	ds_store_b32 v2, v3 offset:17984                           // 00000000057C: D8344640 00000302
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000584: 8C7E007E
	v_mbcnt_lo_u32_b32 v8, -1, 0                               // 000000000588: D71F0008 000100C1
	v_lshrrev_b32_e32 v3, 5, v0                                // 000000000590: 32060085
	v_cmp_gt_u32_e64 s0, 0xc0, v0                              // 000000000594: D44C0000 000200FF 000000C0
	s_and_b32 s28, s15, 3                                      // 0000000005A0: 8B1C830F
	s_mov_b32 s13, 0                                           // 0000000005A4: BE8D0080
	s_mov_b32 s1, exec_lo                                      // 0000000005A8: BE81007E
	v_cmpx_lt_u32_e32 0xbf, v0                                 // 0000000005AC: 7D9200FF 000000BF
	s_xor_b32 s29, exec_lo, s1                                 // 0000000005B4: 8D1D017E
	s_cbranch_execz 169                                        // 0000000005B8: BFA500A9 <attn_prep_24_4_256_64_8204_11_k4jv4+0x860>
	s_lshl_b64 s[14:15], s[12:13], 10                          // 0000000005BC: 848E8A0C
	s_mov_b32 s1, exec_lo                                      // 0000000005C0: BE81007E
	v_cmpx_lt_i32_e32 6, v3                                    // 0000000005C4: 7D820686
	s_xor_b32 s1, exec_lo, s1                                  // 0000000005C8: 8D01017E
	s_cbranch_execz 23                                         // 0000000005CC: BFA50017 <attn_prep_24_4_256_64_8204_11_k4jv4+0x62c>
	s_mov_b32 s13, exec_lo                                     // 0000000005D0: BE8D007E
	v_cmpx_eq_u32_e32 7, v3                                    // 0000000005D4: 7D940687
	s_cbranch_execz 19                                         // 0000000005D8: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x628>
	s_lshl_b64 s[30:31], s[14:15], 2                           // 0000000005DC: 849E820E
	v_lshlrev_b32_e32 v2, 5, v8                                // 0000000005E0: 30041085
	s_add_u32 s10, s10, s30                                    // 0000000005E4: 800A1E0A
	s_addc_u32 s11, s11, s31                                   // 0000000005E8: 820B1F0B
	s_lshl_b32 s30, s28, 10                                    // 0000000005EC: 841E8A1C
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000005F0: BF870009
	s_add_u32 s10, s10, s30                                    // 0000000005F4: 800A1E0A
	s_addc_u32 s11, s11, 0                                     // 0000000005F8: 820B800B
	s_clause 0x1                                               // 0000000005FC: BF850001
	global_load_b128 v[4:7], v2, s[10:11]                      // 000000000600: DC5E0000 040A0002
	global_load_b128 v[9:12], v2, s[10:11] offset:16           // 000000000608: DC5E0010 090A0002
	s_waitcnt vmcnt(1)                                         // 000000000610: BF8907F7
	ds_store_b128 v2, v[4:7] offset:13312                      // 000000000614: DB7C3400 00000402
	s_waitcnt vmcnt(0)                                         // 00000000061C: BF8903F7
	ds_store_b128 v2, v[9:12] offset:13328                     // 000000000620: DB7C3410 00000902
	s_or_b32 exec_lo, exec_lo, s13                             // 000000000628: 8C7E0D7E
	s_and_not1_saveexec_b32 s10, s1                            // 00000000062C: BE8A3001
	s_cbranch_execz 137                                        // 000000000630: BFA50089 <attn_prep_24_4_256_64_8204_11_k4jv4+0x858>
	s_mov_b32 s11, exec_lo                                     // 000000000634: BE8B007E
	v_cmpx_eq_u32_e32 6, v3                                    // 000000000638: 7D940686
	s_cbranch_execz 133                                        // 00000000063C: BFA50085 <attn_prep_24_4_256_64_8204_11_k4jv4+0x854>
	s_lshl_b64 s[14:15], s[14:15], 2                           // 000000000640: 848E820E
	v_lshlrev_b32_e32 v2, 5, v8                                // 000000000644: 30041085
	s_add_u32 s1, s8, s14                                      // 000000000648: 80010E08
	s_addc_u32 s9, s9, s15                                     // 00000000064C: 82090F09
	s_lshl_b32 s8, s28, 10                                     // 000000000650: 84088A1C
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000654: BF870009
	s_add_u32 s8, s1, s8                                       // 000000000658: 80080801
	s_addc_u32 s9, s9, 0                                       // 00000000065C: 82098009
	s_clause 0x3                                               // 000000000660: BF850003
	global_load_b128 v[4:7], v2, s[8:9]                        // 000000000664: DC5E0000 04080002
	global_load_b128 v[9:12], v2, s[8:9] offset:16             // 00000000066C: DC5E0010 09080002
	global_load_b128 v[13:16], v2, s[26:27]                    // 000000000674: DC5E0000 0D1A0002
	global_load_b128 v[17:20], v2, s[26:27] offset:16          // 00000000067C: DC5E0010 111A0002
	s_waitcnt vmcnt(3)                                         // 000000000684: BF890FF7
	v_mul_f32_e32 v21, v5, v5                                  // 000000000688: 102A0B05
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000068C: BF870091
	v_fmac_f32_e32 v21, v4, v4                                 // 000000000690: 562A0904
	v_fmac_f32_e32 v21, v6, v6                                 // 000000000694: 562A0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000698: BF8700A1
	v_fmac_f32_e32 v21, v7, v7                                 // 00000000069C: 562A0F07
	s_waitcnt vmcnt(2)                                         // 0000000006A0: BF890BF7
	v_fmac_f32_e32 v21, v9, v9                                 // 0000000006A4: 562A1309
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006A8: BF870091
	v_fmac_f32_e32 v21, v10, v10                               // 0000000006AC: 562A150A
	v_fmac_f32_e32 v21, v11, v11                               // 0000000006B0: 562A170B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006B4: BF870091
	v_fmac_f32_e32 v21, v12, v12                               // 0000000006B8: 562A190C
	v_add_f32_dpp v21, v21, v21 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006BC: 062A2AFA FF091115
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006C4: BF870091
	v_add_f32_dpp v21, v21, v21 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006C8: 062A2AFA FF091215
	v_add_f32_dpp v21, v21, v21 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006D0: 062A2AFA FF091415
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006D8: BF870091
	v_add_f32_dpp v21, v21, v21 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000006DC: 062A2AFA FF091815
	v_readlane_b32 s1, v21, 15                                 // 0000000006E4: D7600001 00011F15
	v_readlane_b32 s8, v21, 31                                 // 0000000006EC: D7600008 00013F15
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000006F4: BF870001
	v_add_f32_e64 v21, s1, s8                                  // 0000000006F8: D5030015 00001001
	s_mov_b32 s1, 0x3b800000                                   // 000000000700: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 000000000708: BF870481
	v_fmaak_f32 v21, s1, v21, 0x358637bd                       // 00000000070C: 5A2A2A01 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000714: BF870121
	v_mul_f32_e32 v22, 0x4f800000, v21                         // 000000000718: 102C2AFF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v21                    // 000000000720: 7C282AFF 0F800000
	v_cndmask_b32_e32 v21, v21, v22, vcc_lo                    // 000000000728: 022A2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 00000000072C: BF870141
	v_sqrt_f32_e32 v22, v21                                    // 000000000730: 7E2C6715
	s_waitcnt_depctr 0xfff                                     // 000000000734: BF880FFF
	v_add_nc_u32_e32 v23, -1, v22                              // 000000000738: 4A2E2CC1
	v_add_nc_u32_e32 v24, 1, v22                               // 00000000073C: 4A302C81
	v_fma_f32 v25, -v23, v22, v21                              // 000000000740: D6130019 24562D17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000748: BF870112
	v_fma_f32 v26, -v24, v22, v21                              // 00000000074C: D613001A 24562D18
	v_cmp_ge_f32_e64 s1, 0, v25                                // 000000000754: D4160001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000075C: BF870191
	v_cndmask_b32_e64 v22, v22, v23, s1                        // 000000000760: D5010016 00062F16
	v_cmp_lt_f32_e64 s1, 0, v26                                // 000000000768: D4110001 00023480
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000770: BF870091
	v_cndmask_b32_e64 v22, v22, v24, s1                        // 000000000774: D5010016 00063116
	v_mul_f32_e32 v23, 0x37800000, v22                         // 00000000077C: 102E2CFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000784: BF870121
	v_cndmask_b32_e32 v22, v22, v23, vcc_lo                    // 000000000788: 022C2F16
	v_cmp_class_f32_e64 vcc_lo, v21, 0x260                     // 00000000078C: D47E006A 0001FF15 00000260
	v_cndmask_b32_e32 v21, v22, v21, vcc_lo                    // 000000000798: 022A2B16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000079C: BF870121
	v_div_scale_f32 v22, null, v21, v21, 1.0                   // 0000000007A0: D6FC7C16 03CA2B15
	v_div_scale_f32 v25, vcc_lo, 1.0, v21, 1.0                 // 0000000007A8: D6FC6A19 03CA2AF2
	v_rcp_f32_e32 v23, v22                                     // 0000000007B0: 7E2E5516
	s_waitcnt_depctr 0xfff                                     // 0000000007B4: BF880FFF
	v_fma_f32 v24, -v22, v23, 1.0                              // 0000000007B8: D6130018 23CA2F16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007C0: BF870091
	v_fmac_f32_e32 v23, v24, v23                               // 0000000007C4: 562E2F18
	v_mul_f32_e32 v24, v25, v23                                // 0000000007C8: 10302F19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007CC: BF870091
	v_fma_f32 v26, -v22, v24, v25                              // 0000000007D0: D613001A 24663116
	v_fmac_f32_e32 v24, v26, v23                               // 0000000007D8: 56302F1A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007DC: BF870091
	v_fma_f32 v22, -v22, v24, v25                              // 0000000007E0: D6130016 24663116
	v_div_fmas_f32 v22, v22, v23, v24                          // 0000000007E8: D6370016 04622F16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007F0: BF870091
	v_div_fixup_f32 v21, v22, v21, 1.0                         // 0000000007F4: D6270015 03CA2B16
	v_mul_f32_e32 v6, v6, v21                                  // 0000000007FC: 100C2B06
	v_mul_f32_e32 v4, v4, v21                                  // 000000000800: 10082B04
	v_mul_f32_e32 v5, v5, v21                                  // 000000000804: 100A2B05
	v_mul_f32_e32 v7, v7, v21                                  // 000000000808: 100E2B07
	v_mul_f32_e32 v9, v9, v21                                  // 00000000080C: 10122B09
	v_mul_f32_e32 v10, v10, v21                                // 000000000810: 10142B0A
	v_mul_f32_e32 v11, v11, v21                                // 000000000814: 10162B0B
	v_mul_f32_e32 v12, v12, v21                                // 000000000818: 10182B0C
	s_waitcnt vmcnt(1)                                         // 00000000081C: BF8907F7
	v_dual_mul_f32 v4, v13, v4 :: v_dual_mul_f32 v5, v14, v5   // 000000000820: C8C6090D 04040B0E
	v_mul_f32_e32 v6, v15, v6                                  // 000000000828: 100C0D0F
	s_waitcnt vmcnt(0)                                         // 00000000082C: BF8903F7
	v_mul_f32_e32 v11, v11, v19                                // 000000000830: 1016270B
	v_mul_f32_e32 v7, v7, v16                                  // 000000000834: 100E2107
	v_dual_mul_f32 v9, v9, v17 :: v_dual_mul_f32 v10, v10, v18 // 000000000838: C8C62309 090A250A
	v_mul_f32_e32 v12, v12, v20                                // 000000000840: 1018290C
	ds_store_b128 v2, v[4:7] offset:12288                      // 000000000844: DB7C3000 00000402
	ds_store_b128 v2, v[9:12] offset:12304                     // 00000000084C: DB7C3010 00000902
	s_or_b32 exec_lo, exec_lo, s11                             // 000000000854: 8C7E0B7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000858: BF870009
	s_or_b32 exec_lo, exec_lo, s10                             // 00000000085C: 8C7E0A7E
	s_or_saveexec_b32 s8, s29                                  // 000000000860: BE88221D
	v_lshlrev_b32_e32 v9, 5, v8                                // 000000000864: 30121085
	s_xor_b32 exec_lo, exec_lo, s8                             // 000000000868: 8D7E087E
	s_cbranch_execz 161                                        // 00000000086C: BFA500A1 <attn_prep_24_4_256_64_8204_11_k4jv4+0xaf4>
	s_mul_i32 s1, s28, 6                                       // 000000000870: 9601861C
	s_mul_i32 s9, s12, 0xc000                                  // 000000000874: 9609FF0C 0000C000
	v_add_lshl_u32 v2, s1, v3, 11                              // 00000000087C: D6470002 022E0601
	s_mul_hi_u32 s1, s12, 0xc000                               // 000000000884: 9681FF0C 0000C000
	s_add_u32 s6, s6, s9                                       // 00000000088C: 80060906
	s_addc_u32 s1, s7, s1                                      // 000000000890: 82010107
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000894: BF870091
	v_add_co_u32 v2, s6, s6, v2                                // 000000000898: D7000602 00020406
	v_add_co_ci_u32_e64 v4, null, s1, 0, s6                    // 0000000008A0: D5207C04 00190001
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000008A8: BF870112
	v_add_co_u32 v10, vcc_lo, v2, v9                           // 0000000008AC: D7006A0A 00021302
	v_add_co_ci_u32_e32 v11, vcc_lo, 0, v4, vcc_lo             // 0000000008B4: 40160880
	s_clause 0x1                                               // 0000000008B8: BF850001
	global_load_b128 v[4:7], v[10:11], off                     // 0000000008BC: DC5E0000 047C000A
	global_load_b128 v[10:13], v[10:11], off offset:16         // 0000000008C4: DC5E0010 0A7C000A
	s_clause 0x1                                               // 0000000008CC: BF850001
	global_load_b128 v[14:17], v9, s[24:25]                    // 0000000008D0: DC5E0000 0E180009
	global_load_b128 v[18:21], v9, s[24:25] offset:16          // 0000000008D8: DC5E0010 12180009
	s_waitcnt vmcnt(3)                                         // 0000000008E0: BF890FF7
	v_mul_f32_e32 v2, v5, v5                                   // 0000000008E4: 10040B05
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008E8: BF870091
	v_fmac_f32_e32 v2, v4, v4                                  // 0000000008EC: 56040904
	v_fmac_f32_e32 v2, v6, v6                                  // 0000000008F0: 56040D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000008F4: BF8700A1
	v_fmac_f32_e32 v2, v7, v7                                  // 0000000008F8: 56040F07
	s_waitcnt vmcnt(2)                                         // 0000000008FC: BF890BF7
	v_fmac_f32_e32 v2, v10, v10                                // 000000000900: 5604150A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000904: BF870091
	v_fmac_f32_e32 v2, v11, v11                                // 000000000908: 5604170B
	v_fmac_f32_e32 v2, v12, v12                                // 00000000090C: 5604190C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000910: BF870091
	v_fmac_f32_e32 v2, v13, v13                                // 000000000914: 56041B0D
	v_add_f32_dpp v2, v2, v2 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000918: 060404FA FF091102
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000920: BF870091
	v_add_f32_dpp v2, v2, v2 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000924: 060404FA FF091202
	v_add_f32_dpp v2, v2, v2 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000092C: 060404FA FF091402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000934: BF870091
	v_add_f32_dpp v2, v2, v2 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000938: 060404FA FF091802
	v_readlane_b32 s1, v2, 15                                  // 000000000940: D7600001 00011F02
	v_readlane_b32 s6, v2, 31                                  // 000000000948: D7600006 00013F02
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000950: BF870001
	v_add_f32_e64 v2, s1, s6                                   // 000000000954: D5030002 00000C01
	s_mov_b32 s1, 0x3b800000                                   // 00000000095C: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 000000000964: BF870481
	v_fmaak_f32 v2, s1, v2, 0x358637bd                         // 000000000968: 5A040401 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000970: BF870121
	v_mul_f32_e32 v22, 0x4f800000, v2                          // 000000000974: 102C04FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v2                     // 00000000097C: 7C2804FF 0F800000
	v_cndmask_b32_e32 v2, v2, v22, vcc_lo                      // 000000000984: 02042D02
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000000988: BF870141
	v_sqrt_f32_e32 v22, v2                                     // 00000000098C: 7E2C6702
	s_waitcnt_depctr 0xfff                                     // 000000000990: BF880FFF
	v_add_nc_u32_e32 v23, -1, v22                              // 000000000994: 4A2E2CC1
	v_add_nc_u32_e32 v24, 1, v22                               // 000000000998: 4A302C81
	v_fma_f32 v25, -v23, v22, v2                               // 00000000099C: D6130019 240A2D17
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000009A4: BF870112
	v_fma_f32 v26, -v24, v22, v2                               // 0000000009A8: D613001A 240A2D18
	v_cmp_ge_f32_e64 s1, 0, v25                                // 0000000009B0: D4160001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000009B8: BF870191
	v_cndmask_b32_e64 v22, v22, v23, s1                        // 0000000009BC: D5010016 00062F16
	v_cmp_lt_f32_e64 s1, 0, v26                                // 0000000009C4: D4110001 00023480
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009CC: BF870091
	v_cndmask_b32_e64 v22, v22, v24, s1                        // 0000000009D0: D5010016 00063116
	v_mul_f32_e32 v23, 0x37800000, v22                         // 0000000009D8: 102E2CFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000009E0: BF870121
	v_cndmask_b32_e32 v22, v22, v23, vcc_lo                    // 0000000009E4: 022C2F16
	v_cmp_class_f32_e64 vcc_lo, v2, 0x260                      // 0000000009E8: D47E006A 0001FF02 00000260
	v_cndmask_b32_e32 v2, v22, v2, vcc_lo                      // 0000000009F4: 02040516
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000009F8: BF870121
	v_div_scale_f32 v22, null, v2, v2, 1.0                     // 0000000009FC: D6FC7C16 03CA0502
	v_div_scale_f32 v25, vcc_lo, 1.0, v2, 1.0                  // 000000000A04: D6FC6A19 03CA04F2
	v_rcp_f32_e32 v23, v22                                     // 000000000A0C: 7E2E5516
	s_waitcnt_depctr 0xfff                                     // 000000000A10: BF880FFF
	v_fma_f32 v24, -v22, v23, 1.0                              // 000000000A14: D6130018 23CA2F16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A1C: BF870091
	v_fmac_f32_e32 v23, v24, v23                               // 000000000A20: 562E2F18
	v_mul_f32_e32 v24, v25, v23                                // 000000000A24: 10302F19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A28: BF870091
	v_fma_f32 v26, -v22, v24, v25                              // 000000000A2C: D613001A 24663116
	v_fmac_f32_e32 v24, v26, v23                               // 000000000A34: 56302F1A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A38: BF870091
	v_fma_f32 v22, -v22, v24, v25                              // 000000000A3C: D6130016 24663116
	v_div_fmas_f32 v22, v22, v23, v24                          // 000000000A44: D6370016 04622F16
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000A4C: BF870121
	v_div_fixup_f32 v2, v22, v2, 1.0                           // 000000000A50: D6270002 03CA0516
	v_lshl_or_b32 v22, v3, 10, v9                              // 000000000A58: D6560016 04251503
	v_mul_f32_e32 v11, v11, v2                                 // 000000000A60: 1016050B
	v_mul_f32_e32 v4, v4, v2                                   // 000000000A64: 10080504
	v_mul_f32_e32 v5, v5, v2                                   // 000000000A68: 100A0505
	v_mul_f32_e32 v6, v6, v2                                   // 000000000A6C: 100C0506
	v_mul_f32_e32 v7, v7, v2                                   // 000000000A70: 100E0507
	v_mul_f32_e32 v10, v10, v2                                 // 000000000A74: 1014050A
	v_mul_f32_e32 v12, v12, v2                                 // 000000000A78: 1018050C
	s_waitcnt vmcnt(1)                                         // 000000000A7C: BF8907F7
	v_dual_mul_f32 v2, v13, v2 :: v_dual_mul_f32 v5, v15, v5   // 000000000A80: C8C6050D 02040B0F
	v_dual_mul_f32 v6, v16, v6 :: v_dual_mul_f32 v7, v7, v17   // 000000000A88: C8C60D10 06062307
	s_waitcnt vmcnt(0)                                         // 000000000A90: BF8903F7
	v_mul_f32_e32 v10, v10, v18                                // 000000000A94: 1014250A
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000000A98: BF870133
	v_mul_f32_e32 v2, v2, v21                                  // 000000000A9C: 10042B02
	v_dual_mul_f32 v4, v14, v4 :: v_dual_mul_f32 v11, v11, v19 // 000000000AA0: C8C6090E 040A270B
	v_dual_mul_f32 v12, v12, v20 :: v_dual_mul_f32 v5, 0x3d800000, v5// 000000000AA8: C8C6290C 0C040AFF 3D800000
	v_dual_mul_f32 v13, 0x3d800000, v2 :: v_dual_mul_f32 v4, 0x3d800000, v4// 000000000AB4: C8C604FF 0D0408FF 3D800000
	v_dual_mul_f32 v6, 0x3d800000, v6 :: v_dual_mul_f32 v7, 0x3d800000, v7// 000000000AC0: C8C60CFF 06060EFF 3D800000
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000000ACC: BF870214
	v_dual_mul_f32 v10, 0x3d800000, v10 :: v_dual_mul_f32 v11, 0x3d800000, v11// 000000000AD0: C8C614FF 0A0A16FF 3D800000
	v_mul_f32_e32 v12, 0x3d800000, v12                         // 000000000ADC: 101818FF 3D800000
	ds_store_b128 v22, v[4:7]                                  // 000000000AE4: DB7C0000 00000416
	ds_store_b128 v22, v[10:13] offset:16                      // 000000000AEC: DB7C0010 00000A16
	s_or_b32 exec_lo, exec_lo, s8                              // 000000000AF4: 8C7E087E
	v_ashrrev_i32_e32 v2, 31, v1                               // 000000000AF8: 3404029F
	v_and_b32_e32 v12, 31, v0                                  // 000000000AFC: 3618009F
	s_waitcnt lgkmcnt(0)                                       // 000000000B00: BF89FC07
	s_barrier                                                  // 000000000B04: BFBD0000
	buffer_gl0_inv                                             // 000000000B08: E0AC0000 00000000
	v_lshlrev_b64 v[4:5], 8, v[1:2]                            // 000000000B10: D73C0004 00020288
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000B18: BF870111
	v_add_co_u32 v4, vcc_lo, s2, v4                            // 000000000B1C: D7006A04 00020802
	v_add_co_ci_u32_e32 v7, vcc_lo, s3, v5, vcc_lo             // 000000000B24: 400E0A03
	s_and_saveexec_b32 s1, s0                                  // 000000000B28: BE812000
	s_cbranch_execz 29                                         // 000000000B2C: BFA5001D <attn_prep_24_4_256_64_8204_11_k4jv4+0xba4>
	v_lshlrev_b32_e32 v10, 2, v12                              // 000000000B30: 30141882
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000B34: BF870001
	v_add_co_u32 v5, vcc_lo, v4, v10                           // 000000000B38: D7006A05 00021504
	v_add_co_ci_u32_e32 v6, vcc_lo, 0, v7, vcc_lo              // 000000000B40: 400C0E80
	s_clause 0x1                                               // 000000000B44: BF850001
	global_load_b32 v11, v[5:6], off offset:128                // 000000000B48: DC520080 0B7C0005
	global_load_b32 v13, v[5:6], off                           // 000000000B50: DC520000 0D7C0005
	v_lshl_or_b32 v5, v3, 10, v10                              // 000000000B58: D6560005 04291503
	ds_load_2addr_b32 v[5:6], v5 offset1:32                    // 000000000B60: D8DC2000 05000005
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000B68: BF890407
	v_mul_f32_e32 v14, v11, v6                                 // 000000000B6C: 101C0D0B
	v_mul_f32_e32 v11, v11, v5                                 // 000000000B70: 10160B0B
	v_lshl_or_b32 v10, v3, 8, v10                              // 000000000B74: D656000A 04291103
	s_waitcnt vmcnt(0)                                         // 000000000B7C: BF8903F7
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000B80: BF870193
	v_fma_f32 v5, v13, v5, -v14                                // 000000000B84: D6130005 843A0B0D
	v_fmac_f32_e32 v11, v13, v6                                // 000000000B8C: 56160D0D
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000B90: BF870003
	v_add_nc_u32_e32 v6, 0x3800, v10                           // 000000000B94: 4A0C14FF 00003800
	ds_store_2addr_b32 v6, v5, v11 offset1:32                  // 000000000B9C: D8382000 000B0506
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000BA4: 8C7E017E
	v_cmp_gt_u32_e64 s2, 32, v0                                // 000000000BA8: D44C0002 000200A0
	v_dual_mov_b32 v5, 0 :: v_dual_lshlrev_b32 v10, 2, v0      // 000000000BB0: CA220080 050A0082
	v_mov_b32_e32 v6, 0                                        // 000000000BB8: 7E0C0280
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000BBC: BF870003
	s_and_saveexec_b32 s1, s2                                  // 000000000BC0: BE812002
	s_cbranch_execz 21                                         // 000000000BC4: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0xc1c>
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000BC8: BF870002
	v_add_co_u32 v4, vcc_lo, v4, v10                           // 000000000BCC: D7006A04 00021504
	v_add_co_ci_u32_e32 v5, vcc_lo, 0, v7, vcc_lo              // 000000000BD4: 400A0E80
	s_clause 0x1                                               // 000000000BD8: BF850001
	global_load_b32 v7, v[4:5], off offset:128                 // 000000000BDC: DC520080 077C0004
	global_load_b32 v6, v[4:5], off                            // 000000000BE4: DC520000 067C0004
	v_add_nc_u32_e32 v4, 0x3000, v10                           // 000000000BEC: 4A0814FF 00003000
	ds_load_2addr_b32 v[4:5], v4 offset1:32                    // 000000000BF4: D8DC2000 04000004
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000BFC: BF890407
	v_mul_f32_e32 v11, v7, v5                                  // 000000000C00: 10160B07
	s_waitcnt vmcnt(0)                                         // 000000000C04: BF8903F7
	v_mul_f32_e32 v5, v6, v5                                   // 000000000C08: 100A0B06
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000C0C: BF870112
	v_fma_f32 v6, v6, v4, -v11                                 // 000000000C10: D6130006 842E0906
	v_fmac_f32_e32 v5, v7, v4                                  // 000000000C18: 560A0907
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000C1C: 8C7E017E
	v_and_b32_e32 v13, 63, v0                                  // 000000000C20: 361A00BF
	v_or_b32_e32 v4, 0xffffff00, v0                            // 000000000C24: 380800FF FFFFFF00
	s_mov_b32 s1, exec_lo                                      // 000000000C2C: BE81007E
	s_waitcnt lgkmcnt(0)                                       // 000000000C30: BF89FC07
	s_barrier                                                  // 000000000C34: BFBD0000
	buffer_gl0_inv                                             // 000000000C38: E0AC0000 00000000
	v_cmpx_gt_u32_e32 0x180, v0                                // 000000000C40: 7D9800FF 00000180
	s_cbranch_execz 30                                         // 000000000C48: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0xcc4>
	v_lshrrev_b32_e32 v11, 6, v0                               // 000000000C4C: 32160086
	v_lshlrev_b32_e32 v14, 2, v13                              // 000000000C50: 301C1A82
	v_or_b32_e32 v7, 0xffffff00, v0                            // 000000000C54: 380E00FF FFFFFF00
	s_mov_b32 s3, 0                                            // 000000000C5C: BE830080
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000C60: BF870193
	v_lshlrev_b32_e32 v15, 8, v11                              // 000000000C64: 301E1688
	v_lshl_or_b32 v11, v11, 10, v14                            // 000000000C68: D656000B 0439150B
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000C70: BF870002
	v_or3_b32 v14, v15, v14, 0x3800                            // 000000000C74: D658000E 03FE1D0F 00003800
	ds_load_b32 v15, v14                                       // 000000000C80: D8D80000 0F00000E
	v_add_nc_u32_e32 v7, 0x100, v7                             // 000000000C88: 4A0E0EFF 00000100
	v_add_nc_u32_e32 v14, 0x400, v14                           // 000000000C90: 4A1C1CFF 00000400
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000C98: BF870002
	v_cmp_lt_u32_e32 vcc_lo, 0x7f, v7                          // 000000000C9C: 7C920EFF 0000007F
	s_or_b32 s3, vcc_lo, s3                                    // 000000000CA4: 8C03036A
	s_waitcnt lgkmcnt(0)                                       // 000000000CA8: BF89FC07
	ds_store_b32 v11, v15                                      // 000000000CAC: D8340000 00000F0B
	v_add_nc_u32_e32 v11, 0x1000, v11                          // 000000000CB4: 4A1616FF 00001000
	s_and_not1_b32 exec_lo, exec_lo, s3                        // 000000000CBC: 917E037E
	s_cbranch_execnz 65519                                     // 000000000CC0: BFA6FFEF <attn_prep_24_4_256_64_8204_11_k4jv4+0xc80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000CC4: 8C7E017E
	s_and_saveexec_b32 s1, s2                                  // 000000000CC8: BE812002
	v_add_nc_u32_e32 v7, 0x3000, v10                           // 000000000CCC: 4A0E14FF 00003000
	ds_store_2addr_b32 v7, v6, v5 offset1:32                   // 000000000CD4: D8382000 00050607
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000CDC: 8C7E017E
	v_xor_b32_e32 v6, 0x7654321, v0                            // 000000000CE0: 3A0C00FF 07654321
	v_xor_b32_e32 v5, 0x1234567, v0                            // 000000000CE8: 3A0A00FF 01234567
	s_mov_b32 s6, 0                                            // 000000000CF0: BE860080
	s_waitcnt lgkmcnt(0)                                       // 000000000CF4: BF89FC07
	s_barrier                                                  // 000000000CF8: BFBD0000
	v_mul_lo_u32 v6, 0x9e3779b1, v6                            // 000000000CFC: D72C0006 00020CFF 9E3779B1
	v_mul_lo_u32 v5, 0x9e3779b1, v5                            // 000000000D08: D72C0005 00020AFF 9E3779B1
	buffer_gl0_inv                                             // 000000000D14: E0AC0000 00000000
	v_bcnt_u32_b32 v6, v6, 0                                   // 000000000D1C: D71E0006 00010106
	v_bcnt_u32_b32 v5, v5, 0                                   // 000000000D24: D71E0005 00010105
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000D2C: BF870112
	v_and_b32_e32 v14, 1, v6                                   // 000000000D30: 361C0C81
	v_dual_mov_b32 v6, v4 :: v_dual_and_b32 v7, 1, v5          // 000000000D34: CA240104 06060A81
	v_or_b32_e32 v5, 0xffffe800, v10                           // 000000000D3C: 380A14FF FFFFE800
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000D44: BF870193
	v_cmp_eq_u32_e64 s1, 0, v14                                // 000000000D48: D44A0001 00021C80
	v_cmp_eq_u32_e32 vcc_lo, 0, v7                             // 000000000D50: 7C940E80
	s_set_inst_prefetch_distance 0x1                           // 000000000D54: BF840001
	s_branch 23                                                // 000000000D58: BFA00017 <attn_prep_24_4_256_64_8204_11_k4jv4+0xdb8>
	s_nop 0                                                    // 000000000D5C: BF800000
	s_nop 0                                                    // 000000000D60: BF800000
	s_nop 0                                                    // 000000000D64: BF800000
	s_nop 0                                                    // 000000000D68: BF800000
	s_nop 0                                                    // 000000000D6C: BF800000
	s_nop 0                                                    // 000000000D70: BF800000
	s_nop 0                                                    // 000000000D74: BF800000
	s_nop 0                                                    // 000000000D78: BF800000
	s_nop 0                                                    // 000000000D7C: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000D80: 8C7E037E
	v_add_nc_u32_e32 v6, 0x100, v6                             // 000000000D84: 4A0C0CFF 00000100
	ds_store_b32 v5, v7 offset:6144                            // 000000000D8C: D8341800 00000705
	v_add_nc_u32_e32 v5, 0x400, v5                             // 000000000D94: 4A0A0AFF 00000400
	v_cmp_lt_u32_e64 s3, 0xcff, v6                             // 000000000D9C: D4490003 00020CFF 00000CFF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000DA8: BF870491
	s_or_b32 s6, s3, s6                                        // 000000000DAC: 8C060603
	s_and_not1_b32 exec_lo, exec_lo, s6                        // 000000000DB0: 917E067E
	s_cbranch_execz 23                                         // 000000000DB4: BFA50017 <attn_prep_24_4_256_64_8204_11_k4jv4+0xe14>
	v_add_nc_u32_e32 v7, 0xfffffb00, v6                        // 000000000DB8: 4A0E0CFF FFFFFB00
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000DC0: BF870091
	v_cmp_lt_u32_e64 s3, 0x5ff, v7                             // 000000000DC4: D4490003 00020EFF 000005FF
	s_and_saveexec_b32 s7, s3                                  // 000000000DD0: BE872003
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000DD4: BF870009
	s_xor_b32 s3, exec_lo, s7                                  // 000000000DD8: 8D03077E
	s_cbranch_execz 5                                          // 000000000DDC: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0xdf4>
	ds_load_b32 v7, v5 offset:6144                             // 000000000DE0: D8D81800 07000005
	s_waitcnt lgkmcnt(0)                                       // 000000000DE8: BF89FC07
	v_cndmask_b32_e64 v7, -v7, v7, vcc_lo                      // 000000000DEC: D5010007 21AA0F07
	s_and_not1_saveexec_b32 s3, s3                             // 000000000DF4: BE833003
	s_cbranch_execz 65505                                      // 000000000DF8: BFA5FFE1 <attn_prep_24_4_256_64_8204_11_k4jv4+0xd80>
	ds_load_b32 v7, v5                                         // 000000000DFC: D8D80000 07000005
	s_waitcnt lgkmcnt(0)                                       // 000000000E04: BF89FC07
	v_cndmask_b32_e64 v7, -v7, v7, s1                          // 000000000E08: D5010007 20060F07
	s_branch 65499                                             // 000000000E10: BFA0FFDB <attn_prep_24_4_256_64_8204_11_k4jv4+0xd80>
	s_set_inst_prefetch_distance 0x2                           // 000000000E14: BF840002
	s_or_b32 exec_lo, exec_lo, s6                              // 000000000E18: 8C7E067E
	v_dual_mov_b32 v6, v4 :: v_dual_lshlrev_b32 v11, 1, v0     // 000000000E1C: CA220104 060A0081
	s_mov_b32 s1, 0                                            // 000000000E24: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000E28: BF89FC07
	s_barrier                                                  // 000000000E2C: BFBD0000
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000E30: BF870001
	v_mov_b32_e32 v5, v11                                      // 000000000E34: 7E0A030B
	buffer_gl0_inv                                             // 000000000E38: E0AC0000 00000000
	v_lshlrev_b32_e32 v7, 2, v5                                // 000000000E40: 300E0A82
	v_add_nc_u32_e32 v5, 0x200, v5                             // 000000000E44: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 000000000E4C: BF8700C2
	v_and_b32_e32 v7, 0x3ff8, v7                               // 000000000E50: 360E0EFF 00003FF8
	ds_load_b64 v[15:16], v7                                   // 000000000E58: D9D80000 0F000007
	s_waitcnt lgkmcnt(0)                                       // 000000000E60: BF89FC07
	v_dual_add_f32 v17, v15, v16 :: v_dual_add_nc_u32 v6, 0x100, v6// 000000000E64: C920210F 11060CFF 00000100
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000000E70: 7C920CFF 000005FF
	v_sub_f32_e32 v18, v15, v16                                // 000000000E78: 0824210F
	s_or_b32 s1, vcc_lo, s1                                    // 000000000E7C: 8C01016A
	ds_store_b64 v7, v[17:18]                                  // 000000000E80: D9340000 00001107
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000E88: 917E017E
	s_cbranch_execnz 65516                                     // 000000000E8C: BFA6FFEC <attn_prep_24_4_256_64_8204_11_k4jv4+0xe40>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000E90: 8C7E017E
	v_dual_mov_b32 v6, v4 :: v_dual_and_b32 v15, 1, v0         // 000000000E94: CA240104 060E0081
	v_mov_b32_e32 v5, v11                                      // 000000000E9C: 7E0A030B
	s_mov_b32 s1, 0                                            // 000000000EA0: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000EA4: BF89FC07
	s_barrier                                                  // 000000000EA8: BFBD0000
	buffer_gl0_inv                                             // 000000000EAC: E0AC0000 00000000
	s_nop 0                                                    // 000000000EB4: BF800000
	s_nop 0                                                    // 000000000EB8: BF800000
	s_nop 0                                                    // 000000000EBC: BF800000
	v_and_or_b32 v7, 0xffc, v5, v15                            // 000000000EC0: D6570007 043E0AFF 00000FFC
	v_add_nc_u32_e32 v6, 0x100, v6                             // 000000000ECC: 4A0C0CFF 00000100
	v_add_nc_u32_e32 v5, 0x200, v5                             // 000000000ED4: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000EDC: BF870193
	v_lshlrev_b32_e32 v7, 2, v7                                // 000000000EE0: 300E0E82
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000000EE4: 7C920CFF 000005FF
	ds_load_2addr_b32 v[16:17], v7 offset1:2                   // 000000000EEC: D8DC0200 10000007
	s_or_b32 s1, vcc_lo, s1                                    // 000000000EF4: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000EF8: BF89FC07
	v_add_f32_e32 v18, v16, v17                                // 000000000EFC: 06242310
	v_sub_f32_e32 v16, v16, v17                                // 000000000F00: 08202310
	ds_store_2addr_b32 v7, v18, v16 offset1:2                  // 000000000F04: D8380200 00101207
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000F0C: 917E017E
	s_cbranch_execnz 65515                                     // 000000000F10: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xec0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000F14: 8C7E017E
	v_dual_mov_b32 v5, v11 :: v_dual_and_b32 v16, 3, v0        // 000000000F18: CA24010B 05100083
	v_mov_b32_e32 v6, v4                                       // 000000000F20: 7E0C0304
	s_mov_b32 s1, 0                                            // 000000000F24: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000F28: BF89FC07
	s_barrier                                                  // 000000000F2C: BFBD0000
	buffer_gl0_inv                                             // 000000000F30: E0AC0000 00000000
	s_nop 0                                                    // 000000000F38: BF800000
	s_nop 0                                                    // 000000000F3C: BF800000
	v_and_or_b32 v7, 0xff8, v5, v16                            // 000000000F40: D6570007 04420AFF 00000FF8
	v_add_nc_u32_e32 v6, 0x100, v6                             // 000000000F4C: 4A0C0CFF 00000100
	v_add_nc_u32_e32 v5, 0x200, v5                             // 000000000F54: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000F5C: BF870193
	v_lshlrev_b32_e32 v7, 2, v7                                // 000000000F60: 300E0E82
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000000F64: 7C920CFF 000005FF
	ds_load_2addr_b32 v[17:18], v7 offset1:4                   // 000000000F6C: D8DC0400 11000007
	s_or_b32 s1, vcc_lo, s1                                    // 000000000F74: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000F78: BF89FC07
	v_add_f32_e32 v19, v17, v18                                // 000000000F7C: 06262511
	v_sub_f32_e32 v17, v17, v18                                // 000000000F80: 08222511
	ds_store_2addr_b32 v7, v19, v17 offset1:4                  // 000000000F84: D8380400 00111307
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000F8C: 917E017E
	s_cbranch_execnz 65515                                     // 000000000F90: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xf40>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000F94: 8C7E017E
	v_dual_mov_b32 v6, v4 :: v_dual_and_b32 v17, 7, v0         // 000000000F98: CA240104 06100087
	v_mov_b32_e32 v5, v11                                      // 000000000FA0: 7E0A030B
	s_mov_b32 s1, 0                                            // 000000000FA4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000FA8: BF89FC07
	s_barrier                                                  // 000000000FAC: BFBD0000
	buffer_gl0_inv                                             // 000000000FB0: E0AC0000 00000000
	s_nop 0                                                    // 000000000FB8: BF800000
	s_nop 0                                                    // 000000000FBC: BF800000
	v_and_or_b32 v7, 0xff0, v5, v17                            // 000000000FC0: D6570007 04460AFF 00000FF0
	v_add_nc_u32_e32 v6, 0x100, v6                             // 000000000FCC: 4A0C0CFF 00000100
	v_add_nc_u32_e32 v5, 0x200, v5                             // 000000000FD4: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000FDC: BF870193
	v_lshlrev_b32_e32 v7, 2, v7                                // 000000000FE0: 300E0E82
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000000FE4: 7C920CFF 000005FF
	ds_load_2addr_b32 v[18:19], v7 offset1:8                   // 000000000FEC: D8DC0800 12000007
	s_or_b32 s1, vcc_lo, s1                                    // 000000000FF4: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000FF8: BF89FC07
	v_add_f32_e32 v20, v18, v19                                // 000000000FFC: 06282712
	v_sub_f32_e32 v18, v18, v19                                // 000000001000: 08242712
	ds_store_2addr_b32 v7, v20, v18 offset1:8                  // 000000001004: D8380800 00121407
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 00000000100C: 917E017E
	s_cbranch_execnz 65515                                     // 000000001010: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xfc0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001014: 8C7E017E
	v_dual_mov_b32 v5, v11 :: v_dual_and_b32 v18, 15, v0       // 000000001018: CA24010B 0512008F
	v_mov_b32_e32 v6, v4                                       // 000000001020: 7E0C0304
	s_mov_b32 s1, 0                                            // 000000001024: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001028: BF89FC07
	s_barrier                                                  // 00000000102C: BFBD0000
	buffer_gl0_inv                                             // 000000001030: E0AC0000 00000000
	s_nop 0                                                    // 000000001038: BF800000
	s_nop 0                                                    // 00000000103C: BF800000
	v_and_or_b32 v7, 0xfe0, v5, v18                            // 000000001040: D6570007 044A0AFF 00000FE0
	v_add_nc_u32_e32 v5, 0x200, v5                             // 00000000104C: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 000000001054: BF8700C2
	v_lshlrev_b32_e32 v7, 2, v7                                // 000000001058: 300E0E82
	ds_load_2addr_b32 v[19:20], v7 offset1:16                  // 00000000105C: D8DC1000 13000007
	s_waitcnt lgkmcnt(0)                                       // 000000001064: BF89FC07
	v_dual_add_f32 v21, v19, v20 :: v_dual_add_nc_u32 v6, 0x100, v6// 000000001068: C9202913 15060CFF 00000100
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000001074: 7C920CFF 000005FF
	v_sub_f32_e32 v19, v19, v20                                // 00000000107C: 08262913
	s_or_b32 s1, vcc_lo, s1                                    // 000000001080: 8C01016A
	ds_store_2addr_b32 v7, v21, v19 offset1:16                 // 000000001084: D8381000 00131507
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 00000000108C: 917E017E
	s_cbranch_execnz 65515                                     // 000000001090: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0x1040>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001094: 8C7E017E
	v_dual_mov_b32 v5, v11 :: v_dual_mov_b32 v6, v4            // 000000001098: CA10010B 05060104
	s_mov_b32 s1, 0                                            // 0000000010A0: BE810080
	s_waitcnt lgkmcnt(0)                                       // 0000000010A4: BF89FC07
	s_barrier                                                  // 0000000010A8: BFBD0000
	buffer_gl0_inv                                             // 0000000010AC: E0AC0000 00000000
	s_nop 0                                                    // 0000000010B4: BF800000
	s_nop 0                                                    // 0000000010B8: BF800000
	s_nop 0                                                    // 0000000010BC: BF800000
	v_and_or_b32 v7, 0xfc0, v5, v12                            // 0000000010C0: D6570007 04320AFF 00000FC0
	v_add_nc_u32_e32 v5, 0x200, v5                             // 0000000010CC: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 0000000010D4: BF8700C2
	v_lshlrev_b32_e32 v7, 2, v7                                // 0000000010D8: 300E0E82
	ds_load_2addr_b32 v[19:20], v7 offset1:32                  // 0000000010DC: D8DC2000 13000007
	s_waitcnt lgkmcnt(0)                                       // 0000000010E4: BF89FC07
	v_dual_add_f32 v21, v19, v20 :: v_dual_add_nc_u32 v6, 0x100, v6// 0000000010E8: C9202913 15060CFF 00000100
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 0000000010F4: 7C920CFF 000005FF
	v_sub_f32_e32 v19, v19, v20                                // 0000000010FC: 08262913
	s_or_b32 s1, vcc_lo, s1                                    // 000000001100: 8C01016A
	ds_store_2addr_b32 v7, v21, v19 offset1:32                 // 000000001104: D8382000 00131507
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 00000000110C: 917E017E
	s_cbranch_execnz 65515                                     // 000000001110: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0x10c0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001114: 8C7E017E
	v_dual_mov_b32 v5, v11 :: v_dual_mov_b32 v6, v4            // 000000001118: CA10010B 05060104
	s_mov_b32 s1, 0                                            // 000000001120: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001124: BF89FC07
	s_barrier                                                  // 000000001128: BFBD0000
	buffer_gl0_inv                                             // 00000000112C: E0AC0000 00000000
	s_nop 0                                                    // 000000001134: BF800000
	s_nop 0                                                    // 000000001138: BF800000
	s_nop 0                                                    // 00000000113C: BF800000
	v_and_or_b32 v7, 0xf80, v5, v13                            // 000000001140: D6570007 04360AFF 00000F80
	v_add_nc_u32_e32 v5, 0x200, v5                             // 00000000114C: 4A0A0AFF 00000200
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 000000001154: BF8700C2
	v_lshlrev_b32_e32 v7, 2, v7                                // 000000001158: 300E0E82
	ds_load_2addr_stride64_b32 v[19:20], v7 offset1:1          // 00000000115C: D8E00100 13000007
	s_waitcnt lgkmcnt(0)                                       // 000000001164: BF89FC07
	v_dual_add_f32 v21, v19, v20 :: v_dual_add_nc_u32 v6, 0x100, v6// 000000001168: C9202913 15060CFF 00000100
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v6                         // 000000001174: 7C920CFF 000005FF
	v_sub_f32_e32 v19, v19, v20                                // 00000000117C: 08262913
	s_or_b32 s1, vcc_lo, s1                                    // 000000001180: 8C01016A
	ds_store_2addr_stride64_b32 v7, v21, v19 offset1:1         // 000000001184: D83C0100 00131507
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 00000000118C: 917E017E
	s_cbranch_execnz 65515                                     // 000000001190: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0x1140>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001194: 8C7E017E
	v_dual_mov_b32 v6, v11 :: v_dual_and_b32 v5, 0x7f, v0      // 000000001198: CA24010B 060400FF 0000007F
	v_mov_b32_e32 v7, v4                                       // 0000000011A4: 7E0E0304
	s_mov_b32 s1, 0                                            // 0000000011A8: BE810080
	s_waitcnt lgkmcnt(0)                                       // 0000000011AC: BF89FC07
	s_barrier                                                  // 0000000011B0: BFBD0000
	buffer_gl0_inv                                             // 0000000011B4: E0AC0000 00000000
	s_nop 0                                                    // 0000000011BC: BF800000
	v_and_or_b32 v19, 0xf00, v6, v5                            // 0000000011C0: D6570013 04160CFF 00000F00
	v_add_nc_u32_e32 v7, 0x100, v7                             // 0000000011CC: 4A0E0EFF 00000100
	v_add_nc_u32_e32 v6, 0x200, v6                             // 0000000011D4: 4A0C0CFF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000011DC: BF870193
	v_lshlrev_b32_e32 v21, 2, v19                              // 0000000011E0: 302A2682
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v7                         // 0000000011E4: 7C920EFF 000005FF
	ds_load_2addr_stride64_b32 v[19:20], v21 offset1:2         // 0000000011EC: D8E00200 13000015
	s_or_b32 s1, vcc_lo, s1                                    // 0000000011F4: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 0000000011F8: BF89FC07
	v_add_f32_e32 v22, v19, v20                                // 0000000011FC: 062C2913
	v_sub_f32_e32 v19, v19, v20                                // 000000001200: 08262913
	ds_store_2addr_stride64_b32 v21, v22, v19 offset1:2        // 000000001204: D83C0200 00131615
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 00000000120C: 917E017E
	s_cbranch_execnz 65515                                     // 000000001210: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0x11c0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001214: 8C7E017E
	v_mov_b32_e32 v5, v10                                      // 000000001218: 7E0A030A
	s_mov_b32 s1, 0                                            // 00000000121C: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001220: BF89FC07
	s_barrier                                                  // 000000001224: BFBD0000
	buffer_gl0_inv                                             // 000000001228: E0AC0000 00000000
	s_branch 14                                                // 000000001230: BFA0000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x126c>
	s_nop 0                                                    // 000000001234: BF800000
	s_nop 0                                                    // 000000001238: BF800000
	s_nop 0                                                    // 00000000123C: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000001240: 8C7E037E
	v_add_nc_u32_e32 v4, 0x100, v4                             // 000000001244: 4A0808FF 00000100
	v_add_nc_u32_e32 v5, 0x400, v5                             // 00000000124C: 4A0A0AFF 00000400
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001254: BF8704A2
	v_cmp_lt_u32_e32 vcc_lo, 0xcff, v4                         // 000000001258: 7C9208FF 00000CFF
	s_or_b32 s1, vcc_lo, s1                                    // 000000001260: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000001264: 917E017E
	s_cbranch_execz 15                                         // 000000001268: BFA5000F <attn_prep_24_4_256_64_8204_11_k4jv4+0x12a8>
	v_add_nc_u32_e32 v6, 0xfffff500, v4                        // 00000000126C: 4A0C08FF FFFFF500
	s_mov_b32 s3, exec_lo                                      // 000000001274: BE83007E
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001278: BF870001
	v_cmpx_gt_u32_e32 0xfffffa00, v6                           // 00000000127C: 7D980CFF FFFFFA00
	s_cbranch_execz 65518                                      // 000000001284: BFA5FFEE <attn_prep_24_4_256_64_8204_11_k4jv4+0x1240>
	ds_load_b32 v6, v5                                         // 000000001288: D8D80000 06000005
	s_waitcnt lgkmcnt(0)                                       // 000000001290: BF89FC07
	v_mul_f32_e32 v6, 0x3d800000, v6                           // 000000001294: 100C0CFF 3D800000
	ds_store_b32 v5, v6                                        // 00000000129C: D8340000 00000605
	s_branch 65510                                             // 0000000012A4: BFA0FFE6 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1240>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000012A8: 8C7E017E
	s_waitcnt lgkmcnt(0)                                       // 0000000012AC: BF89FC07
	s_barrier                                                  // 0000000012B0: BFBD0000
	buffer_gl0_inv                                             // 0000000012B4: E0AC0000 00000000
	ds_load_b32 v4, v10 offset:12288                           // 0000000012BC: D8D83000 0400000A
	v_cmp_eq_u32_e64 s1, 0, v8                                 // 0000000012C4: D44A0001 00021080
	v_lshlrev_b32_e32 v19, 2, v3                               // 0000000012CC: 30260682
	s_waitcnt lgkmcnt(0)                                       // 0000000012D0: BF89FC07
	v_mul_f32_e32 v5, v4, v4                                   // 0000000012D4: 100A0904
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012D8: BF870091
	v_mov_b32_dpp v5, v5 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012DC: 7E0A02FA FF091105
	v_fmac_f32_e32 v5, v4, v4                                  // 0000000012E4: 560A0904
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012E8: BF870091
	v_add_f32_dpp v4, v5, v5 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012EC: 06080AFA FF091205
	v_add_f32_dpp v4, v4, v4 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000012F4: 060808FA FF091404
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012FC: BF870091
	v_add_f32_dpp v4, v4, v4 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001300: 060808FA FF091804
	v_readlane_b32 s3, v4, 15                                  // 000000001308: D7600003 00011F04
	v_readlane_b32 s7, v4, 31                                  // 000000001310: D7600007 00013F04
	s_and_saveexec_b32 s6, s1                                  // 000000001318: BE862001
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000131C: BF870001
	v_add_f32_e64 v4, s3, s7                                   // 000000001320: D5030004 00000E03
	ds_store_b32 v19, v4 offset:18048                          // 000000001328: D8344680 00000413
	s_or_b32 exec_lo, exec_lo, s6                              // 000000001330: 8C7E067E
	v_mov_b32_e32 v32, 0                                       // 000000001334: 7E400280
	s_waitcnt lgkmcnt(0)                                       // 000000001338: BF89FC07
	s_barrier                                                  // 00000000133C: BFBD0000
	buffer_gl0_inv                                             // 000000001340: E0AC0000 00000000
	s_mul_i32 s6, s28, 0x258e10                                // 000000001348: 9606FF1C 00258E10
	ds_load_b128 v[4:7], v32 offset:18048                      // 000000001350: DBFC4680 04000020
	ds_load_b128 v[20:23], v32 offset:18064                    // 000000001358: DBFC4690 14000020
	ds_load_b128 v[24:27], v32 offset:17968                    // 000000001360: DBFC4630 18000020
	s_add_u32 s8, s4, s6                                       // 000000001368: 80080604
	s_addc_u32 s9, s5, 0                                       // 00000000136C: 82098005
	s_waitcnt lgkmcnt(2)                                       // 000000001370: BF89FC27
	v_add_f32_e32 v4, v4, v5                                   // 000000001374: 06080B04
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001378: BF870091
	v_add_f32_e32 v4, v6, v4                                   // 00000000137C: 06080906
	v_add_f32_e32 v4, v7, v4                                   // 000000001380: 06080907
	s_waitcnt lgkmcnt(1)                                       // 000000001384: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001388: BF870091
	v_add_f32_e32 v4, v20, v4                                  // 00000000138C: 06080914
	v_add_f32_e32 v4, v21, v4                                  // 000000001390: 06080915
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001394: BF870091
	v_add_f32_e32 v4, v22, v4                                  // 000000001398: 06080916
	v_add_f32_e32 v20, v23, v4                                 // 00000000139C: 06280917
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000013A0: BF870121
	v_mul_f32_e32 v4, 0x4f800000, v20                          // 0000000013A4: 100828FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v20                    // 0000000013AC: 7C2828FF 0F800000
	v_cndmask_b32_e32 v4, v20, v4, vcc_lo                      // 0000000013B4: 02080914
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 0000000013B8: BF870141
	v_sqrt_f32_e32 v5, v4                                      // 0000000013BC: 7E0A6704
	s_waitcnt_depctr 0xfff                                     // 0000000013C0: BF880FFF
	v_add_nc_u32_e32 v6, -1, v5                                // 0000000013C4: 4A0C0AC1
	v_add_nc_u32_e32 v7, 1, v5                                 // 0000000013C8: 4A0E0A81
	v_fma_f32 v21, -v6, v5, v4                                 // 0000000013CC: D6130015 24120B06
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000013D4: BF870112
	v_fma_f32 v22, -v7, v5, v4                                 // 0000000013D8: D6130016 24120B07
	v_cmp_ge_f32_e64 s3, 0, v21                                // 0000000013E0: D4160003 00022A80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000013E8: BF870191
	v_cndmask_b32_e64 v5, v5, v6, s3                           // 0000000013EC: D5010005 000E0D05
	v_cmp_lt_f32_e64 s3, 0, v22                                // 0000000013F4: D4110003 00022C80
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000013FC: BF870121
	v_cndmask_b32_e64 v5, v5, v7, s3                           // 000000001400: D5010005 000E0F05
	v_cmp_eq_u32_e64 s3, 0, v0                                 // 000000001408: D44A0003 00020080
	v_mul_f32_e32 v6, 0x37800000, v5                           // 000000001410: 100C0AFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001418: BF870121
	v_cndmask_b32_e32 v5, v5, v6, vcc_lo                       // 00000000141C: 020A0D05
	v_cmp_class_f32_e64 vcc_lo, v4, 0x260                      // 000000001420: D47E006A 0001FF04 00000260
	v_cndmask_b32_e32 v21, v5, v4, vcc_lo                      // 00000000142C: 022A0905
	ds_load_b128 v[4:7], v32 offset:17920                      // 000000001430: DBFC4600 04000020
	ds_load_b128 v[28:31], v32 offset:17936                    // 000000001438: DBFC4610 1C000020
	ds_load_b128 v[32:35], v32 offset:17952                    // 000000001440: DBFC4620 20000020
	v_div_scale_f32 v22, null, v21, v21, 0x41800000            // 000000001448: D6FC7C16 03FE2B15 41800000
	v_div_scale_f32 v37, vcc_lo, 0x41800000, v21, 0x41800000   // 000000001454: D6FC6A25 03FE2AFF 41800000
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001460: BF870002
	v_rcp_f32_e32 v23, v22                                     // 000000001464: 7E2E5516
	s_waitcnt_depctr 0xfff                                     // 000000001468: BF880FFF
	v_fma_f32 v36, -v22, v23, 1.0                              // 00000000146C: D6130024 23CA2F16
	s_waitcnt lgkmcnt(2)                                       // 000000001474: BF89FC27
	v_add_f32_e32 v4, v5, v4                                   // 000000001478: 06080905
	v_add_f32_e32 v5, v5, v6                                   // 00000000147C: 060A0D05
	v_add_f32_e32 v6, v7, v6                                   // 000000001480: 060C0D07
	s_waitcnt lgkmcnt(1)                                       // 000000001484: BF89FC17
	v_add_f32_e32 v7, v7, v28                                  // 000000001488: 060E3907
	v_dual_fmac_f32 v23, v36, v23 :: v_dual_add_f32 v28, v29, v28// 00000000148C: C8082F24 171C391D
	v_add_f32_e32 v29, v29, v30                                // 000000001494: 063A3D1D
	v_add_f32_e32 v30, v31, v30                                // 000000001498: 063C3D1F
	s_waitcnt lgkmcnt(0)                                       // 00000000149C: BF89FC07
	s_delay_alu instid0(VALU_DEP_3)                            // 0000000014A0: BF870003
	v_dual_add_f32 v31, v31, v32 :: v_dual_mul_f32 v38, v37, v23// 0000000014A4: C906411F 1F262F25
	ds_load_b32 v36, v10 offset:12288                          // 0000000014AC: D8D83000 2400000A
	v_add_f32_e32 v32, v33, v32                                // 0000000014B4: 06404121
	v_add_f32_e32 v33, v33, v34                                // 0000000014B8: 06424521
	v_add_f32_e32 v34, v35, v34                                // 0000000014BC: 06444523
	v_fma_f32 v39, -v22, v38, v37                              // 0000000014C0: D6130027 24964D16
	v_mul_f32_e32 v5, 0.5, v5                                  // 0000000014C8: 100A0AF0
	v_mul_f32_e32 v7, 0.5, v7                                  // 0000000014CC: 100E0EF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000014D0: BF870093
	v_fmac_f32_e32 v38, v39, v23                               // 0000000014D4: 564C2F27
	v_fma_f32 v22, -v22, v38, v37                              // 0000000014D8: D6130016 24964D16
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000014E0: BF870001
	v_div_fmas_f32 v22, v22, v23, v38                          // 0000000014E4: D6370016 049A2F16
	v_mul_f32_e32 v23, 0.5, v28                                // 0000000014EC: 102E38F0
	v_dual_add_f32 v35, v35, v24 :: v_dual_mul_f32 v6, 0.5, v6 // 0000000014F0: C9063123 23060CF0
	v_add_f32_e32 v24, v25, v24                                // 0000000014F8: 06303119
	v_add_f32_e32 v25, v25, v26                                // 0000000014FC: 06323519
	v_div_fixup_f32 v22, v22, v21, 0x41800000                  // 000000001500: D6270016 03FE2B16 41800000
	v_cmp_lt_f32_e32 vcc_lo, 0, v20                            // 00000000150C: 7C222880
	v_dual_add_f32 v26, v27, v26 :: v_dual_mul_f32 v27, 0.5, v29// 000000001510: C906351B 1A1A3AF0
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001518: BF870214
	v_mul_f32_e32 v25, 0.5, v25                                // 00000000151C: 103232F0
	v_dual_mul_f32 v29, 0.5, v32 :: v_dual_cndmask_b32 v20, 0, v22// 000000001520: C8D240F0 1D142C80
	v_dual_mul_f32 v22, 0.5, v31 :: v_dual_mul_f32 v31, 0.5, v34// 000000001528: C8C63EF0 161E44F0
	v_mul_f32_e32 v4, 0.5, v4                                  // 000000001530: 100808F0
	v_mul_f32_e32 v28, 0.5, v30                                // 000000001534: 10383CF0
	s_waitcnt lgkmcnt(0)                                       // 000000001538: BF89FC07
	v_mul_f32_e32 v32, v36, v20                                // 00000000153C: 10402924
	v_dual_mul_f32 v30, 0.5, v33 :: v_dual_mul_f32 v33, 0.5, v35// 000000001540: C8C642F0 1E2046F0
	v_mul_f32_e32 v24, 0.5, v24                                // 000000001548: 103030F0
	v_mul_f32_e32 v26, 0.5, v26                                // 00000000154C: 103434F0
	s_delay_alu instid0(VALU_DEP_4)                            // 000000001550: BF870004
	v_cmp_gt_f32_e32 vcc_lo, v32, v4                           // 000000001554: 7C280920
	v_cndmask_b32_e64 v4, 0, 1, vcc_lo                         // 000000001558: D5010004 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v5                           // 000000001560: 7C280B20
	v_cndmask_b32_e64 v5, 0, 1, vcc_lo                         // 000000001564: D5010005 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v7                           // 00000000156C: 7C280F20
	v_cndmask_b32_e64 v7, 0, 1, vcc_lo                         // 000000001570: D5010007 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v6                           // 000000001578: 7C280D20
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 00000000157C: BF870244
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v5, vcc_lo             // 000000001580: 40080B04
	v_cmp_gt_f32_e32 vcc_lo, v32, v27                          // 000000001584: 7C283720
	v_cndmask_b32_e64 v5, 0, 1, vcc_lo                         // 000000001588: D5010005 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v23                          // 000000001590: 7C282F20
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v7, vcc_lo             // 000000001594: 40080F04
	v_cmp_gt_f32_e32 vcc_lo, v32, v22                          // 000000001598: 7C282D20
	v_cndmask_b32_e64 v6, 0, 1, vcc_lo                         // 00000000159C: D5010006 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v28                          // 0000000015A4: 7C283920
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 0000000015A8: BF870244
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v5, vcc_lo             // 0000000015AC: 40080B04
	v_cmp_gt_f32_e32 vcc_lo, v32, v30                          // 0000000015B0: 7C283D20
	v_cndmask_b32_e64 v5, 0, 1, vcc_lo                         // 0000000015B4: D5010005 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v29                          // 0000000015BC: 7C283B20
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v6, vcc_lo             // 0000000015C0: 40080D04
	v_cmp_gt_f32_e32 vcc_lo, v32, v33                          // 0000000015C4: 7C284320
	v_cndmask_b32_e64 v6, 0, 1, vcc_lo                         // 0000000015C8: D5010006 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v31                          // 0000000015D0: 7C283F20
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 0000000015D4: BF870244
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v5, vcc_lo             // 0000000015D8: 40080B04
	v_cmp_gt_f32_e32 vcc_lo, v32, v25                          // 0000000015DC: 7C283320
	v_cndmask_b32_e64 v5, 0, 1, vcc_lo                         // 0000000015E0: D5010005 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v32, v24                          // 0000000015E8: 7C283120
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v6, vcc_lo             // 0000000015EC: 40080D04
	v_cmp_gt_f32_e32 vcc_lo, v32, v26                          // 0000000015F0: 7C283520
	v_lshlrev_b32_e32 v6, 1, v1                                // 0000000015F4: 300C0281
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000015F8: BF870093
	v_add_co_ci_u32_e32 v4, vcc_lo, v4, v5, vcc_lo             // 0000000015FC: 40080B04
	v_lshlrev_b32_e32 v5, 2, v4                                // 000000001600: 300A0882
	ds_load_b32 v5, v5 offset:17920                            // 000000001604: D8D84600 05000005
	s_waitcnt lgkmcnt(0)                                       // 00000000160C: BF89FC07
	v_fma_f32 v5, v36, v20, -v5                                // 000000001610: D6130005 84162924
	ds_store_2addr_stride64_b32 v10, v5, v4 offset0:62 offset1:66// 000000001618: D83C423E 0004050A
	s_and_saveexec_b32 s4, s3                                  // 000000001620: BE842003
	s_cbranch_execz 17                                         // 000000001624: BFA50011 <attn_prep_24_4_256_64_8204_11_k4jv4+0x166c>
	v_ashrrev_i32_e32 v7, 31, v6                               // 000000001628: 340E0C9F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000162C: BF870121
	v_lshlrev_b64 v[4:5], 2, v[6:7]                            // 000000001630: D73C0004 00020C82
	v_mul_f32_e32 v7, 0x3d800000, v21                          // 000000001638: 100E2AFF 3D800000
	v_add_co_u32 v4, vcc_lo, s8, v4                            // 000000001640: D7006A04 00020808
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001648: BF870113
	v_add_co_ci_u32_e32 v5, vcc_lo, s9, v5, vcc_lo             // 00000000164C: 400A0A09
	v_add_co_u32 v4, vcc_lo, 0x140000, v4                      // 000000001650: D7006A04 000208FF 00140000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000000165C: BF870002
	v_add_co_ci_u32_e32 v5, vcc_lo, 0, v5, vcc_lo              // 000000001660: 400A0A80
	global_store_b32 v[4:5], v7, off offset:1920               // 000000001664: DC6A0780 007C0704
	s_or_b32 exec_lo, exec_lo, s4                              // 00000000166C: 8C7E047E
	v_lshlrev_b64 v[4:5], 7, v[1:2]                            // 000000001670: D73C0004 00020287
	v_add_nc_u32_e32 v7, 0x3e00, v10                           // 000000001678: 4A0E14FF 00003E00
	v_add_nc_u32_e32 v20, 0x4200, v10                          // 000000001680: 4A2814FF 00004200
	v_cmp_gt_u32_e64 s4, 0x80, v0                              // 000000001688: D44C0004 000200FF 00000080
	s_waitcnt lgkmcnt(0)                                       // 000000001694: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001698: BC7C0000
	s_barrier                                                  // 00000000169C: BFBD0000
	buffer_gl0_inv                                             // 0000000016A0: E0AC0000 00000000
	s_and_saveexec_b32 s5, s4                                  // 0000000016A8: BE852004
	s_cbranch_execz 13                                         // 0000000016AC: BFA5000D <attn_prep_24_4_256_64_8204_11_k4jv4+0x16e4>
	v_lshl_add_u32 v22, v0, 2, v20                             // 0000000016B0: D6460016 04510500
	v_or_b32_e32 v24, v4, v0                                   // 0000000016B8: 38300104
	ds_load_b64 v[22:23], v22                                  // 0000000016BC: D9D80000 16000016
	s_waitcnt lgkmcnt(0)                                       // 0000000016C4: BF89FC07
	v_lshl_or_b32 v25, v23, 4, v22                             // 0000000016C8: D6560019 04590917
	v_add_co_u32 v22, vcc_lo, s8, v24                          // 0000000016D0: D7006A16 00023008
	v_add_co_ci_u32_e32 v23, vcc_lo, s9, v5, vcc_lo            // 0000000016D8: 402E0A09
	global_store_b8 v[22:23], v25, off                         // 0000000016DC: DC620000 007C1916
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000016E4: 8C7E057E
	ds_load_b32 v22, v7                                        // 0000000016E8: D8D80000 16000007
	s_waitcnt lgkmcnt(0)                                       // 0000000016F0: BF89FC07
	v_mul_f32_e32 v23, v22, v22                                // 0000000016F4: 102E2D16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000016F8: BF870091
	v_mov_b32_dpp v23, v23 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000016FC: 7E2E02FA FF091117
	v_fmac_f32_e32 v23, v22, v22                               // 000000001704: 562E2D16
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001708: BF870091
	v_add_f32_dpp v22, v23, v23 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000170C: 062C2EFA FF091217
	v_add_f32_dpp v22, v22, v22 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001714: 062C2CFA FF091416
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000171C: BF870091
	v_add_f32_dpp v22, v22, v22 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001720: 062C2CFA FF091816
	v_readlane_b32 s6, v22, 15                                 // 000000001728: D7600006 00011F16
	v_readlane_b32 s7, v22, 31                                 // 000000001730: D7600007 00013F16
	s_and_saveexec_b32 s5, s1                                  // 000000001738: BE852001
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000173C: BF870001
	v_add_f32_e64 v22, s6, s7                                  // 000000001740: D5030016 00000E06
	ds_store_b32 v19, v22 offset:18048                         // 000000001748: D8344680 00001613
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001750: 8C7E057E
	v_mov_b32_e32 v26, 0                                       // 000000001754: 7E340280
	s_waitcnt lgkmcnt(0)                                       // 000000001758: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 00000000175C: BC7C0000
	s_barrier                                                  // 000000001760: BFBD0000
	buffer_gl0_inv                                             // 000000001764: E0AC0000 00000000
	v_cmp_eq_u32_e64 s5, 0, v14                                // 00000000176C: D44A0005 00021C80
	ds_load_b128 v[22:25], v26 offset:18048                    // 000000001774: DBFC4680 1600001A
	ds_load_b128 v[26:29], v26 offset:18064                    // 00000000177C: DBFC4690 1A00001A
	ds_load_b32 v30, v7                                        // 000000001784: D8D80000 1E000007
	s_waitcnt lgkmcnt(2)                                       // 00000000178C: BF89FC27
	v_add_f32_e32 v22, v22, v23                                // 000000001790: 062C2F16
	s_waitcnt lgkmcnt(0)                                       // 000000001794: BF89FC07
	v_cndmask_b32_e64 v14, -v30, v30, s5                       // 000000001798: D501000E 20163D1E
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000017A0: BF870002
	v_add_f32_e32 v22, v22, v24                                // 0000000017A4: 062C3116
	ds_store_b32 v7, v14                                       // 0000000017A8: D8340000 00000E07
	s_waitcnt lgkmcnt(0)                                       // 0000000017B0: BF89FC07
	s_barrier                                                  // 0000000017B4: BFBD0000
	v_add_f32_e32 v22, v22, v25                                // 0000000017B8: 062C3316
	buffer_gl0_inv                                             // 0000000017BC: E0AC0000 00000000
	v_add_f32_e32 v22, v22, v26                                // 0000000017C4: 062C3516
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000017C8: BF870091
	v_add_f32_e32 v22, v22, v27                                // 0000000017CC: 062C3716
	v_add_f32_e32 v22, v22, v28                                // 0000000017D0: 062C3916
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000017D4: BF870091
	v_add_f32_e32 v22, v22, v29                                // 0000000017D8: 062C3B16
	v_mul_f32_e32 v23, 0x4f800000, v22                         // 0000000017DC: 102E2CFF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v22                    // 0000000017E4: 7C282CFF 0F800000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000017EC: BF870092
	v_cndmask_b32_e32 v22, v22, v23, vcc_lo                    // 0000000017F0: 022C2F16
	v_sqrt_f32_e32 v23, v22                                    // 0000000017F4: 7E2E6716
	s_waitcnt_depctr 0xfff                                     // 0000000017F8: BF880FFF
	v_add_nc_u32_e32 v25, -1, v23                              // 0000000017FC: 4A322EC1
	v_add_nc_u32_e32 v24, 1, v23                               // 000000001800: 4A302E81
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001804: BF870112
	v_fma_f32 v26, -v25, v23, v22                              // 000000001808: D613001A 245A2F19
	v_fma_f32 v27, -v24, v23, v22                              // 000000001810: D613001B 245A2F18
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001818: BF870112
	v_cmp_ge_f32_e64 s5, 0, v26                                // 00000000181C: D4160005 00023480
	v_cmp_lt_f32_e64 s6, 0, v27                                // 000000001824: D4110006 00023680
	s_and_saveexec_b32 s7, s4                                  // 00000000182C: BE872004
	s_cbranch_execz 9                                          // 000000001830: BFA50009 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1858>
	v_lshl_add_u32 v14, v0, 2, v7                              // 000000001834: D646000E 041D0500
	ds_load_b64 v[26:27], v14                                  // 00000000183C: D9D80000 1A00000E
	s_waitcnt lgkmcnt(0)                                       // 000000001844: BF89FC07
	v_add_f32_e32 v28, v26, v27                                // 000000001848: 0638371A
	v_sub_f32_e32 v29, v26, v27                                // 00000000184C: 083A371A
	ds_store_b64 v14, v[28:29]                                 // 000000001850: D9340000 00001C0E
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001858: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 00000000185C: BF89FC07
	s_barrier                                                  // 000000001860: BFBD0000
	buffer_gl0_inv                                             // 000000001864: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 00000000186C: BE872004
	s_cbranch_execz 14                                         // 000000001870: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x18ac>
	v_and_or_b32 v14, 0xfc, v11, v15                           // 000000001874: D657000E 043E16FF 000000FC
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001880: BF870091
	v_lshlrev_b32_e32 v14, 2, v14                              // 000000001884: 301C1C82
	v_add_nc_u32_e32 v26, 0x3c00, v14                          // 000000001888: 4A341CFF 00003C00
	ds_load_2addr_b32 v[14:15], v26 offset0:128 offset1:130    // 000000001890: D8DC8280 0E00001A
	s_waitcnt lgkmcnt(0)                                       // 000000001898: BF89FC07
	v_add_f32_e32 v27, v14, v15                                // 00000000189C: 06361F0E
	v_sub_f32_e32 v14, v14, v15                                // 0000000018A0: 081C1F0E
	ds_store_2addr_b32 v26, v27, v14 offset0:128 offset1:130   // 0000000018A4: D8388280 000E1B1A
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000018AC: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000018B0: BF89FC07
	s_barrier                                                  // 0000000018B4: BFBD0000
	buffer_gl0_inv                                             // 0000000018B8: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000018C0: BE872004
	s_cbranch_execz 14                                         // 0000000018C4: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1900>
	v_and_or_b32 v14, 0xf8, v11, v16                           // 0000000018C8: D657000E 044216FF 000000F8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000018D4: BF870091
	v_lshlrev_b32_e32 v14, 2, v14                              // 0000000018D8: 301C1C82
	v_add_nc_u32_e32 v16, 0x3c00, v14                          // 0000000018DC: 4A201CFF 00003C00
	ds_load_2addr_b32 v[14:15], v16 offset0:128 offset1:132    // 0000000018E4: D8DC8480 0E000010
	s_waitcnt lgkmcnt(0)                                       // 0000000018EC: BF89FC07
	v_add_f32_e32 v26, v14, v15                                // 0000000018F0: 06341F0E
	v_sub_f32_e32 v14, v14, v15                                // 0000000018F4: 081C1F0E
	ds_store_2addr_b32 v16, v26, v14 offset0:128 offset1:132   // 0000000018F8: D8388480 000E1A10
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001900: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001904: BF89FC07
	s_barrier                                                  // 000000001908: BFBD0000
	buffer_gl0_inv                                             // 00000000190C: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001914: BE872004
	s_cbranch_execz 14                                         // 000000001918: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1954>
	v_and_or_b32 v14, 0xf0, v11, v17                           // 00000000191C: D657000E 044616FF 000000F0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001928: BF870091
	v_lshlrev_b32_e32 v14, 2, v14                              // 00000000192C: 301C1C82
	v_add_nc_u32_e32 v16, 0x3c00, v14                          // 000000001930: 4A201CFF 00003C00
	ds_load_2addr_b32 v[14:15], v16 offset0:128 offset1:136    // 000000001938: D8DC8880 0E000010
	s_waitcnt lgkmcnt(0)                                       // 000000001940: BF89FC07
	v_add_f32_e32 v17, v14, v15                                // 000000001944: 06221F0E
	v_sub_f32_e32 v14, v14, v15                                // 000000001948: 081C1F0E
	ds_store_2addr_b32 v16, v17, v14 offset0:128 offset1:136   // 00000000194C: D8388880 000E1110
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001954: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001958: BF89FC07
	s_barrier                                                  // 00000000195C: BFBD0000
	buffer_gl0_inv                                             // 000000001960: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001968: BE872004
	s_cbranch_execz 14                                         // 00000000196C: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x19a8>
	v_and_or_b32 v14, 0xe0, v11, v18                           // 000000001970: D657000E 044A16FF 000000E0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000197C: BF870091
	v_lshlrev_b32_e32 v14, 2, v14                              // 000000001980: 301C1C82
	v_add_nc_u32_e32 v16, 0x3c00, v14                          // 000000001984: 4A201CFF 00003C00
	ds_load_2addr_b32 v[14:15], v16 offset0:128 offset1:144    // 00000000198C: D8DC9080 0E000010
	s_waitcnt lgkmcnt(0)                                       // 000000001994: BF89FC07
	v_add_f32_e32 v17, v14, v15                                // 000000001998: 06221F0E
	v_sub_f32_e32 v14, v14, v15                                // 00000000199C: 081C1F0E
	ds_store_2addr_b32 v16, v17, v14 offset0:128 offset1:144   // 0000000019A0: D8389080 000E1110
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000019A8: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000019AC: BF89FC07
	s_barrier                                                  // 0000000019B0: BFBD0000
	buffer_gl0_inv                                             // 0000000019B4: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000019BC: BE872004
	s_cbranch_execz 14                                         // 0000000019C0: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x19fc>
	v_and_or_b32 v12, 0xc0, v11, v12                           // 0000000019C4: D657000C 043216FF 000000C0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000019D0: BF870091
	v_lshlrev_b32_e32 v12, 2, v12                              // 0000000019D4: 30181882
	v_add_nc_u32_e32 v12, 0x3c00, v12                          // 0000000019D8: 4A1818FF 00003C00
	ds_load_2addr_b32 v[14:15], v12 offset0:128 offset1:160    // 0000000019E0: D8DCA080 0E00000C
	s_waitcnt lgkmcnt(0)                                       // 0000000019E8: BF89FC07
	v_add_f32_e32 v16, v14, v15                                // 0000000019EC: 06201F0E
	v_sub_f32_e32 v14, v14, v15                                // 0000000019F0: 081C1F0E
	ds_store_2addr_b32 v12, v16, v14 offset0:128 offset1:160   // 0000000019F4: D838A080 000E100C
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000019FC: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001A00: BF89FC07
	s_barrier                                                  // 000000001A04: BFBD0000
	buffer_gl0_inv                                             // 000000001A08: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001A10: BE872004
	s_cbranch_execz 12                                         // 000000001A14: BFA5000C <attn_prep_24_4_256_64_8204_11_k4jv4+0x1a48>
	v_and_or_b32 v12, 0x80, v11, v13                           // 000000001A18: D657000C 043616FF 00000080
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001A24: BF870001
	v_lshlrev_b32_e32 v14, 2, v12                              // 000000001A28: 301C1882
	ds_load_2addr_stride64_b32 v[12:13], v14 offset0:62 offset1:63// 000000001A2C: D8E03F3E 0C00000E
	s_waitcnt lgkmcnt(0)                                       // 000000001A34: BF89FC07
	v_add_f32_e32 v15, v12, v13                                // 000000001A38: 061E1B0C
	v_sub_f32_e32 v12, v12, v13                                // 000000001A3C: 08181B0C
	ds_store_2addr_stride64_b32 v14, v15, v12 offset0:62 offset1:63// 000000001A40: D83C3F3E 000C0F0E
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001A48: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001A4C: BF89FC07
	s_barrier                                                  // 000000001A50: BFBD0000
	buffer_gl0_inv                                             // 000000001A54: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001A5C: BE872004
	s_cbranch_execz 7                                          // 000000001A60: BFA50007 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1a80>
	ds_load_2addr_stride64_b32 v[12:13], v7 offset1:2          // 000000001A64: D8E00200 0C000007
	s_waitcnt lgkmcnt(0)                                       // 000000001A6C: BF89FC07
	v_add_f32_e32 v14, v12, v13                                // 000000001A70: 061C1B0C
	v_sub_f32_e32 v12, v12, v13                                // 000000001A74: 08181B0C
	ds_store_2addr_stride64_b32 v7, v14, v12 offset1:2         // 000000001A78: D83C0200 000C0E07
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001A80: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001A84: BF89FC07
	s_barrier                                                  // 000000001A88: BFBD0000
	buffer_gl0_inv                                             // 000000001A8C: E0AC0000 00000000
	ds_load_b32 v7, v7                                         // 000000001A94: D8D80000 07000007
	s_waitcnt lgkmcnt(0)                                       // 000000001A9C: BF89FC07
	v_cmp_le_f32_e64 s7, 0, v7                                 // 000000001AA0: D4130007 00020E80
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001AA8: BF870001
	v_cndmask_b32_e64 v7, 0, 1, s7                             // 000000001AAC: D5010007 001D0280
	ds_store_b32 v20, v7                                       // 000000001AB4: D8340000 00000714
	s_waitcnt lgkmcnt(0)                                       // 000000001ABC: BF89FC07
	s_barrier                                                  // 000000001AC0: BFBD0000
	buffer_gl0_inv                                             // 000000001AC4: E0AC0000 00000000
	s_and_saveexec_b32 s7, s2                                  // 000000001ACC: BE872002
	s_cbranch_execz 56                                         // 000000001AD0: BFA50038 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1bb4>
	v_lshlrev_b32_e32 v7, 5, v0                                // 000000001AD4: 300E0085
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001AD8: BF870001
	v_add_nc_u32_e32 v12, 0x420c, v7                           // 000000001ADC: 4A180EFF 0000420C
	v_add_nc_u32_e32 v14, 0x4204, v7                           // 000000001AE4: 4A1C0EFF 00004204
	v_add_nc_u32_e32 v16, 0x4214, v7                           // 000000001AEC: 4A200EFF 00004214
	v_add_nc_u32_e32 v7, 0x4000, v7                            // 000000001AF4: 4A0E0EFF 00004000
	ds_load_2addr_b32 v[12:13], v12 offset1:1                  // 000000001AFC: D8DC0100 0C00000C
	ds_load_2addr_b32 v[14:15], v14 offset1:1                  // 000000001B04: D8DC0100 0E00000E
	ds_load_2addr_b32 v[16:17], v16 offset1:1                  // 000000001B0C: D8DC0100 10000010
	ds_load_2addr_b32 v[26:27], v7 offset0:128 offset1:135     // 000000001B14: D8DC8780 1A000007
	s_waitcnt lgkmcnt(3)                                       // 000000001B1C: BF89FC37
	v_lshlrev_b32_e32 v7, 4, v13                               // 000000001B20: 300E1A84
	v_lshlrev_b32_e32 v18, 3, v12                              // 000000001B24: 30241883
	v_lshlrev_b64 v[12:13], 5, v[1:2]                          // 000000001B28: D73C000C 00020285
	s_waitcnt lgkmcnt(2)                                       // 000000001B30: BF89FC27
	v_lshlrev_b32_e32 v14, 1, v14                              // 000000001B34: 301C1C81
	v_lshl_or_b32 v7, v15, 2, v7                               // 000000001B38: D6560007 041D050F
	s_waitcnt lgkmcnt(1)                                       // 000000001B40: BF89FC17
	v_lshlrev_b32_e32 v15, 5, v16                              // 000000001B44: 301E2085
	s_waitcnt lgkmcnt(0)                                       // 000000001B48: BF89FC07
	v_lshlrev_b32_e32 v16, 7, v27                              // 000000001B4C: 30203687
	v_add_co_u32 v12, s2, v12, v0                              // 000000001B50: D700020C 0002010C
	v_or3_b32 v7, v14, v18, v7                                 // 000000001B58: D6580007 041E250E
	v_add_co_ci_u32_e64 v13, s2, 0, v13, s2                    // 000000001B60: D520020D 000A1A80
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000001B68: BF870223
	v_add_co_u32 v12, s2, v12, s8                              // 000000001B6C: D700020C 0000110C
	v_lshlrev_b32_e32 v14, 6, v17                              // 000000001B74: 301C2286
	v_or3_b32 v7, v15, v26, v7                                 // 000000001B78: D6580007 041E350F
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001B80: BF870214
	v_add_co_ci_u32_e64 v13, s2, s9, v13, s2                   // 000000001B84: D520020D 000A1A09
	v_add_co_u32 v12, s2, 0x100000, v12                        // 000000001B8C: D700020C 000218FF 00100000
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001B98: BF870193
	v_or3_b32 v7, v7, v14, v16                                 // 000000001B9C: D6580007 04421D07
	v_add_co_ci_u32_e64 v13, s2, 0, v13, s2                    // 000000001BA4: D520020D 000A1A80
	global_store_b8 v[12:13], v7, off offset:1536              // 000000001BAC: DC620600 007C070C
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001BB4: 8C7E077E
	s_and_saveexec_b32 s2, s3                                  // 000000001BB8: BE822003
	s_cbranch_execz 32                                         // 000000001BBC: BFA50020 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1c40>
	v_cndmask_b32_e64 v7, v23, v25, s5                         // 000000001BC0: D5010007 00163317
	s_add_u32 s5, s8, 0x140780                                 // 000000001BC8: 8005FF08 00140780
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001BD0: BF8700A1
	v_cndmask_b32_e64 v7, v7, v24, s6                          // 000000001BD4: D5010007 001A3107
	s_addc_u32 s6, s9, 0                                       // 000000001BDC: 82068009
	v_mul_f32_e32 v12, 0x37800000, v7                          // 000000001BE0: 10180EFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001BE8: BF870121
	v_cndmask_b32_e32 v7, v7, v12, vcc_lo                      // 000000001BEC: 020E1907
	v_cmp_class_f32_e64 vcc_lo, v22, 0x260                     // 000000001BF0: D47E006A 0001FF16 00000260
	v_cndmask_b32_e32 v7, v7, v22, vcc_lo                      // 000000001BFC: 020E2D07
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001C00: BF870121
	v_mul_f32_e32 v12, 0x3d800000, v7                          // 000000001C04: 10180EFF 3D800000
	v_ashrrev_i32_e32 v7, 31, v6                               // 000000001C0C: 340E0C9F
	v_mul_f32_e32 v12, v21, v12                                // 000000001C10: 10181915
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001C14: BF870112
	v_lshlrev_b64 v[6:7], 2, v[6:7]                            // 000000001C18: D73C0006 00020C82
	v_mul_f32_e32 v12, 0x3ba06c99, v12                         // 000000001C20: 101818FF 3BA06C99
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001C28: BF870192
	v_add_co_u32 v6, vcc_lo, s5, v6                            // 000000001C2C: D7006A06 00020C05
	v_add_co_ci_u32_e32 v7, vcc_lo, s6, v7, vcc_lo             // 000000001C34: 400E0E06
	global_store_b32 v[6:7], v12, off offset:4                 // 000000001C38: DC6A0004 007C0C06
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001C40: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 000000001C44: BC7C0000
	s_barrier                                                  // 000000001C48: BFBD0000
	buffer_gl0_inv                                             // 000000001C4C: E0AC0000 00000000
	ds_load_b32 v6, v10 offset:13312                           // 000000001C54: D8D83400 0600000A
	s_waitcnt lgkmcnt(0)                                       // 000000001C5C: BF89FC07
	v_mul_f32_e32 v7, v6, v6                                   // 000000001C60: 100E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C64: BF870091
	v_mov_b32_dpp v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C68: 7E0E02FA FF091107
	v_fmac_f32_e32 v7, v6, v6                                  // 000000001C70: 560E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C74: BF870091
	v_add_f32_dpp v6, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C78: 060C0EFA FF091207
	v_add_f32_dpp v6, v6, v6 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C80: 060C0CFA FF091406
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C88: BF870091
	v_add_f32_dpp v6, v6, v6 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001C8C: 060C0CFA FF091806
	v_readlane_b32 s5, v6, 15                                  // 000000001C94: D7600005 00011F06
	v_readlane_b32 s6, v6, 31                                  // 000000001C9C: D7600006 00013F06
	s_and_saveexec_b32 s2, s1                                  // 000000001CA4: BE822001
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001CA8: BF870001
	v_add_f32_e64 v6, s5, s6                                   // 000000001CAC: D5030006 00000C05
	ds_store_b32 v19, v6 offset:18048                          // 000000001CB4: D8344680 00000613
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001CBC: 8C7E027E
	v_mov_b32_e32 v7, 0                                        // 000000001CC0: 7E0E0280
	s_waitcnt lgkmcnt(0)                                       // 000000001CC4: BF89FC07
	s_barrier                                                  // 000000001CC8: BFBD0000
	buffer_gl0_inv                                             // 000000001CCC: E0AC0000 00000000
	ds_load_b128 v[12:15], v7 offset:18048                     // 000000001CD4: DBFC4680 0C000007
	ds_load_b128 v[16:19], v7 offset:18064                     // 000000001CDC: DBFC4690 10000007
	ds_load_b128 v[21:24], v7 offset:18032                     // 000000001CE4: DBFC4670 15000007
	s_waitcnt lgkmcnt(2)                                       // 000000001CEC: BF89FC27
	v_add_f32_e32 v6, v12, v13                                 // 000000001CF0: 060C1B0C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001CF4: BF870091
	v_add_f32_e32 v6, v14, v6                                  // 000000001CF8: 060C0D0E
	v_add_f32_e32 v6, v15, v6                                  // 000000001CFC: 060C0D0F
	s_waitcnt lgkmcnt(1)                                       // 000000001D00: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D04: BF870091
	v_add_f32_e32 v6, v16, v6                                  // 000000001D08: 060C0D10
	v_add_f32_e32 v6, v17, v6                                  // 000000001D0C: 060C0D11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D10: BF870091
	v_add_f32_e32 v6, v18, v6                                  // 000000001D14: 060C0D12
	v_add_f32_e32 v29, v19, v6                                 // 000000001D18: 063A0D13
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001D1C: BF870121
	v_mul_f32_e32 v6, 0x4f800000, v29                          // 000000001D20: 100C3AFF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v29                    // 000000001D28: 7C283AFF 0F800000
	v_cndmask_b32_e32 v6, v29, v6, vcc_lo                      // 000000001D30: 020C0D1D
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000001D34: BF870141
	v_sqrt_f32_e32 v12, v6                                     // 000000001D38: 7E186706
	s_waitcnt_depctr 0xfff                                     // 000000001D3C: BF880FFF
	v_add_nc_u32_e32 v13, -1, v12                              // 000000001D40: 4A1A18C1
	v_add_nc_u32_e32 v14, 1, v12                               // 000000001D44: 4A1C1881
	v_fma_f32 v15, -v13, v12, v6                               // 000000001D48: D613000F 241A190D
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001D50: BF870112
	v_fma_f32 v16, -v14, v12, v6                               // 000000001D54: D6130010 241A190E
	v_cmp_ge_f32_e64 s2, 0, v15                                // 000000001D5C: D4160002 00021E80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001D64: BF870191
	v_cndmask_b32_e64 v12, v12, v13, s2                        // 000000001D68: D501000C 000A1B0C
	v_cmp_lt_f32_e64 s2, 0, v16                                // 000000001D70: D4110002 00022080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D78: BF870091
	v_cndmask_b32_e64 v12, v12, v14, s2                        // 000000001D7C: D501000C 000A1D0C
	v_mul_f32_e32 v13, 0x37800000, v12                         // 000000001D84: 101A18FF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001D8C: BF870121
	v_cndmask_b32_e32 v12, v12, v13, vcc_lo                    // 000000001D90: 02181B0C
	v_cmp_class_f32_e64 vcc_lo, v6, 0x260                      // 000000001D94: D47E006A 0001FF06 00000260
	v_cndmask_b32_e32 v6, v12, v6, vcc_lo                      // 000000001DA0: 020C0D0C
	ds_load_b128 v[12:15], v7 offset:17984                     // 000000001DA4: DBFC4640 0C000007
	ds_load_b128 v[16:19], v7 offset:18000                     // 000000001DAC: DBFC4650 10000007
	ds_load_b128 v[25:28], v7 offset:18016                     // 000000001DB4: DBFC4660 19000007
	ds_load_b32 v10, v10 offset:13312                          // 000000001DBC: D8D83400 0A00000A
	s_waitcnt lgkmcnt(3)                                       // 000000001DC4: BF89FC37
	v_add_f32_e32 v12, v13, v12                                // 000000001DC8: 0618190D
	v_add_f32_e32 v13, v13, v14                                // 000000001DCC: 061A1D0D
	v_add_f32_e32 v14, v15, v14                                // 000000001DD0: 061C1D0F
	s_waitcnt lgkmcnt(2)                                       // 000000001DD4: BF89FC27
	v_add_f32_e32 v15, v15, v16                                // 000000001DD8: 061E210F
	v_add_f32_e32 v16, v17, v16                                // 000000001DDC: 06202111
	v_add_f32_e32 v17, v17, v18                                // 000000001DE0: 06222511
	v_add_f32_e32 v18, v19, v18                                // 000000001DE4: 06242513
	s_waitcnt lgkmcnt(1)                                       // 000000001DE8: BF89FC17
	v_add_f32_e32 v19, v19, v25                                // 000000001DEC: 06263313
	v_add_f32_e32 v25, v26, v25                                // 000000001DF0: 0632331A
	v_add_f32_e32 v26, v26, v27                                // 000000001DF4: 0634371A
	v_add_f32_e32 v27, v28, v27                                // 000000001DF8: 0636371C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_4) | instid1(VALU_DEP_3)// 000000001DFC: BF8701D4
	v_dual_add_f32 v28, v28, v21 :: v_dual_mul_f32 v19, 0.5, v19// 000000001E00: C9062B1C 1C1226F0
	v_add_f32_e32 v21, v22, v21                                // 000000001E08: 062A2B16
	v_div_scale_f32 v30, null, v6, v6, 0x41800000              // 000000001E0C: D6FC7C1E 03FE0D06 41800000
	v_div_scale_f32 v7, vcc_lo, 0x41800000, v6, 0x41800000     // 000000001E18: D6FC6A07 03FE0CFF 41800000
	v_mul_f32_e32 v15, 0.5, v15                                // 000000001E24: 101E1EF0
	v_rcp_f32_e32 v31, v30                                     // 000000001E28: 7E3E551E
	v_add_f32_e32 v22, v22, v23                                // 000000001E2C: 062C2F16
	v_add_f32_e32 v23, v24, v23                                // 000000001E30: 062E2F18
	v_dual_mul_f32 v13, 0.5, v13 :: v_dual_mul_f32 v14, 0.5, v14// 000000001E34: C8C61AF0 0D0E1CF0
	v_dual_mul_f32 v24, 0.5, v25 :: v_dual_mul_f32 v25, 0.5, v27// 000000001E3C: C8C632F0 181836F0
	v_dual_mul_f32 v16, 0.5, v16 :: v_dual_mul_f32 v21, 0.5, v21// 000000001E44: C8C620F0 10142AF0
	v_mul_f32_e32 v17, 0.5, v17                                // 000000001E4C: 102222F0
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001E50: BF870095
	v_fma_f32 v32, -v30, v31, 1.0                              // 000000001E54: D6130020 23CA3F1E
	v_fmac_f32_e32 v31, v32, v31                               // 000000001E5C: 563E3F20
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001E60: BF870091
	v_mul_f32_e32 v32, v7, v31                                 // 000000001E64: 10403F07
	v_fma_f32 v33, -v30, v32, v7                               // 000000001E68: D6130021 241E411E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001E70: BF870091
	v_fmac_f32_e32 v32, v33, v31                               // 000000001E74: 56403F21
	v_fma_f32 v7, -v30, v32, v7                                // 000000001E78: D6130007 241E411E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001E80: BF870121
	v_div_fmas_f32 v7, v7, v31, v32                            // 000000001E84: D6370007 04823F07
	v_cmp_lt_f32_e32 vcc_lo, 0, v29                            // 000000001E8C: 7C223A80
	v_div_fixup_f32 v7, v7, v6, 0x41800000                     // 000000001E90: D6270007 03FE0D07 41800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001E9C: BF8700A1
	v_dual_cndmask_b32 v7, 0, v7 :: v_dual_mul_f32 v12, 0.5, v12// 000000001EA0: CA460E80 070C18F0
	s_waitcnt lgkmcnt(0)                                       // 000000001EA8: BF89FC07
	v_dual_mul_f32 v18, 0.5, v18 :: v_dual_mul_f32 v7, v10, v7 // 000000001EAC: C8C624F0 12060F0A
	v_mul_f32_e32 v10, 0.5, v26                                // 000000001EB4: 101434F0
	v_mul_f32_e32 v26, 0.5, v28                                // 000000001EB8: 103438F0
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001EBC: BF870003
	v_cmp_gt_f32_e32 vcc_lo, v7, v12                           // 000000001EC0: 7C281907
	v_cndmask_b32_e64 v12, 0, 1, vcc_lo                        // 000000001EC4: D501000C 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v13                           // 000000001ECC: 7C281B07
	v_cndmask_b32_e64 v13, 0, 1, vcc_lo                        // 000000001ED0: D501000D 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v15                           // 000000001ED8: 7C281F07
	v_cndmask_b32_e64 v15, 0, 1, vcc_lo                        // 000000001EDC: D501000F 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v14                           // 000000001EE4: 7C281D07
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001EE8: BF870244
	v_add_co_ci_u32_e32 v12, vcc_lo, v12, v13, vcc_lo          // 000000001EEC: 40181B0C
	v_cmp_gt_f32_e32 vcc_lo, v7, v17                           // 000000001EF0: 7C282307
	v_cndmask_b32_e64 v13, 0, 1, vcc_lo                        // 000000001EF4: D501000D 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v16                           // 000000001EFC: 7C282107
	v_add_co_ci_u32_e32 v12, vcc_lo, v12, v15, vcc_lo          // 000000001F00: 40181F0C
	v_cmp_gt_f32_e32 vcc_lo, v7, v19                           // 000000001F04: 7C282707
	v_cndmask_b32_e64 v14, 0, 1, vcc_lo                        // 000000001F08: D501000E 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v18                           // 000000001F10: 7C282507
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001F14: BF870244
	v_add_co_ci_u32_e32 v12, vcc_lo, v12, v13, vcc_lo          // 000000001F18: 40181B0C
	v_cmp_gt_f32_e32 vcc_lo, v7, v10                           // 000000001F1C: 7C281507
	v_cndmask_b32_e64 v10, 0, 1, vcc_lo                        // 000000001F20: D501000A 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v24                           // 000000001F28: 7C283107
	v_add_co_ci_u32_e32 v12, vcc_lo, v12, v14, vcc_lo          // 000000001F2C: 40181D0C
	v_cmp_gt_f32_e32 vcc_lo, v7, v26                           // 000000001F30: 7C283507
	v_mul_f32_e32 v14, 0.5, v23                                // 000000001F34: 101C2EF0
	v_cndmask_b32_e64 v13, 0, 1, vcc_lo                        // 000000001F38: D501000D 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v25                           // 000000001F40: 7C283307
	v_add_co_ci_u32_e32 v10, vcc_lo, v12, v10, vcc_lo          // 000000001F44: 4014150C
	v_cmp_gt_f32_e32 vcc_lo, v7, v21                           // 000000001F48: 7C282B07
	v_mul_f32_e32 v12, 0.5, v22                                // 000000001F4C: 10182CF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001F50: BF870113
	v_add_co_ci_u32_e32 v10, vcc_lo, v10, v13, vcc_lo          // 000000001F54: 40141B0A
	v_cmp_gt_f32_e32 vcc_lo, v7, v12                           // 000000001F58: 7C281907
	v_cndmask_b32_e64 v12, 0, 1, vcc_lo                        // 000000001F5C: D501000C 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v7, v14                           // 000000001F64: 7C281D07
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001F68: BF870002
	v_add_co_ci_u32_e32 v7, vcc_lo, v10, v12, vcc_lo           // 000000001F6C: 400E190A
	ds_store_b32 v20, v7                                       // 000000001F70: D8340000 00000714
	s_and_saveexec_b32 s2, s3                                  // 000000001F78: BE822003
	s_cbranch_execz 15                                         // 000000001F7C: BFA5000F <attn_prep_24_4_256_64_8204_11_k4jv4+0x1fbc>
	v_lshlrev_b64 v[1:2], 2, v[1:2]                            // 000000001F80: D73C0001 00020282
	v_mul_f32_e32 v6, 0x3d800000, v6                           // 000000001F88: 100C0CFF 3D800000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001F90: BF870192
	v_add_co_u32 v1, vcc_lo, s8, v1                            // 000000001F94: D7006A01 00020208
	v_add_co_ci_u32_e32 v2, vcc_lo, s9, v2, vcc_lo             // 000000001F9C: 40040409
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001FA0: BF870112
	v_add_co_u32 v1, vcc_lo, 0x250000, v1                      // 000000001FA4: D7006A01 000202FF 00250000
	v_add_co_ci_u32_e32 v2, vcc_lo, 0, v2, vcc_lo              // 000000001FB0: 40040480
	global_store_b32 v[1:2], v6, off offset:3552               // 000000001FB4: DC6A0DE0 007C0601
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001FBC: 8C7E027E
	s_waitcnt lgkmcnt(0)                                       // 000000001FC0: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001FC4: BC7C0000
	s_barrier                                                  // 000000001FC8: BFBD0000
	buffer_gl0_inv                                             // 000000001FCC: E0AC0000 00000000
	s_and_saveexec_b32 s2, s4                                  // 000000001FD4: BE822004
	s_cbranch_execz 19                                         // 000000001FD8: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2028>
	v_lshlrev_b32_e32 v1, 2, v11                               // 000000001FDC: 30021682
	v_add_co_u32 v4, vcc_lo, s8, v4                            // 000000001FE0: D7006A04 00020808
	v_add_co_ci_u32_e32 v5, vcc_lo, s9, v5, vcc_lo             // 000000001FE8: 400A0A09
	ds_load_b64 v[1:2], v1 offset:16896                        // 000000001FEC: D9D84200 01000001
	v_add_co_u32 v0, vcc_lo, v4, v0                            // 000000001FF4: D7006A00 00020104
	v_add_co_ci_u32_e32 v4, vcc_lo, 0, v5, vcc_lo              // 000000001FFC: 40080A80
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000002000: BF8701B2
	v_add_co_u32 v0, vcc_lo, 0x150000, v0                      // 000000002004: D7006A00 000200FF 00150000
	s_waitcnt lgkmcnt(0)                                       // 000000002010: BF89FC07
	v_lshl_or_b32 v2, v2, 4, v1                                // 000000002014: D6560002 04050902
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v4, vcc_lo              // 00000000201C: 40020880
	global_store_b8 v[0:1], v2, off offset:2016                // 000000002020: DC6207E0 007C0200
	s_or_b32 exec_lo, exec_lo, s2                              // 000000002028: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 00000000202C: BC7C0000
	s_barrier                                                  // 000000002030: BFBD0000
	buffer_gl0_inv                                             // 000000002034: E0AC0000 00000000
	s_and_saveexec_b32 s2, s0                                  // 00000000203C: BE822000
	s_cbranch_execz 362                                        // 000000002040: BFA5016A <attn_prep_24_4_256_64_8204_11_k4jv4+0x25ec>
	v_lshl_or_b32 v6, v3, 10, v9                               // 000000002044: D6560006 04251503
	ds_load_b128 v[9:12], v6                                   // 00000000204C: DBFC0000 09000006
	ds_load_b128 v[13:16], v6 offset:16                        // 000000002054: DBFC0010 0D000006
	s_waitcnt lgkmcnt(1)                                       // 00000000205C: BF89FC17
	v_max3_f32 v0, |v9|, 0, |v10|                              // 000000002060: D61C0500 04290109
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002068: BF8700A1
	v_max3_f32 v0, v0, |v11|, |v12|                            // 00000000206C: D61C0600 04321700
	s_waitcnt lgkmcnt(0)                                       // 000000002074: BF89FC07
	v_max3_f32 v0, v0, |v13|, |v14|                            // 000000002078: D61C0600 043A1B00
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002080: BF870091
	v_max3_f32 v0, v0, |v15|, |v16|                            // 000000002084: D61C0600 04421F00
	v_mov_b32_dpp v1, v0 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000208C: 7E0202FA FF091100
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002094: BF870091
	v_max_f32_e32 v1, v1, v1                                   // 000000002098: 20020301
	v_max_f32_e32 v0, v0, v1                                   // 00000000209C: 20000300
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020A0: BF870091
	v_mov_b32_dpp v1, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000020A4: 7E0202FA FF091200
	v_max_f32_e32 v1, v1, v1                                   // 0000000020AC: 20020301
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020B0: BF870091
	v_max_f32_e32 v0, v0, v1                                   // 0000000020B4: 20000300
	v_mov_b32_dpp v1, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000020B8: 7E0202FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020C0: BF870091
	v_max_f32_e32 v1, v1, v1                                   // 0000000020C4: 20020301
	v_max_f32_e32 v0, v0, v1                                   // 0000000020C8: 20000300
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020CC: BF870091
	v_mov_b32_dpp v1, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000020D0: 7E0202FA FF091800
	v_max_f32_e32 v1, v1, v1                                   // 0000000020D8: 20020301
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020DC: BF870091
	v_max_f32_e32 v0, v0, v1                                   // 0000000020E0: 20000300
	v_readlane_b32 s0, v0, 31                                  // 0000000020E4: D7600000 00013F00
	v_readlane_b32 s2, v0, 15                                  // 0000000020EC: D7600002 00011F00
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000020F4: BF870112
	v_max_f32_e64 v0, s0, s0                                   // 0000000020F8: D5100000 00000000
	v_max_f32_e64 v1, s2, s2                                   // 000000002100: D5100001 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002108: BF870091
	v_max_f32_e32 v0, v1, v0                                   // 00000000210C: 20000101
	v_div_scale_f32 v1, null, 0x42fe0000, 0x42fe0000, v0       // 000000002110: D6FC7C01 0401FEFF 42FE0000
	v_div_scale_f32 v5, vcc_lo, v0, 0x42fe0000, v0             // 00000000211C: D6FC6A05 0401FF00 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002128: BF8700B2
	v_rcp_f32_e32 v2, v1                                       // 00000000212C: 7E045501
	s_waitcnt_depctr 0xfff                                     // 000000002130: BF880FFF
	v_fma_f32 v4, -v1, v2, 1.0                                 // 000000002134: D6130004 23CA0501
	v_fmac_f32_e32 v2, v4, v2                                  // 00000000213C: 56040504
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002140: BF870091
	v_mul_f32_e32 v4, v5, v2                                   // 000000002144: 10080505
	v_fma_f32 v7, -v1, v4, v5                                  // 000000002148: D6130007 24160901
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002150: BF870091
	v_fmac_f32_e32 v4, v7, v2                                  // 000000002154: 56080507
	v_fma_f32 v1, -v1, v4, v5                                  // 000000002158: D6130001 24160901
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002160: BF870091
	v_div_fmas_f32 v1, v1, v2, v4                              // 000000002164: D6370001 04120501
	v_div_fixup_f32 v7, v1, 0x42fe0000, v0                     // 00000000216C: D6270007 0401FF01 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002178: BF870121
	v_div_scale_f32 v2, null, v7, v7, 1.0                      // 00000000217C: D6FC7C02 03CA0F07
	v_div_scale_f32 v4, vcc_lo, 1.0, v7, 1.0                   // 000000002184: D6FC6A04 03CA0EF2
	v_rcp_f32_e32 v17, v2                                      // 00000000218C: 7E225502
	s_waitcnt_depctr 0xfff                                     // 000000002190: BF880FFF
	v_fma_f32 v0, -v2, v17, 1.0                                // 000000002194: D6130000 23CA2302
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000219C: BF870121
	v_fmac_f32_e32 v17, v0, v17                                // 0000000021A0: 56222300
	v_mad_u64_u32 v[0:1], null, s28, 6, v[3:4]                 // 0000000021A4: D6FE7C00 040D0C1C
	v_dual_mov_b32 v1, 0 :: v_dual_mul_f32 v18, v4, v17        // 0000000021AC: CA060080 01122304
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000021B4: BF870091
	v_fma_f32 v5, -v2, v18, v4                                 // 0000000021B8: D6130005 24122502
	v_fmac_f32_e32 v18, v5, v17                                // 0000000021C0: 56242305
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000021C4: BF870211
	v_fma_f32 v2, -v2, v18, v4                                 // 0000000021C8: D6130002 24122502
	v_mad_u64_u32 v[4:5], null, s12, 24, v[0:1]                // 0000000021D0: D6FE7C04 0401300C
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 0000000021D8: BF8701B2
	v_div_fmas_f32 v0, v2, v17, v18                            // 0000000021DC: D6370000 044A2302
	v_cmp_neq_f32_e32 vcc_lo, 0, v7                            // 0000000021E4: 7C3A0E80
	v_lshlrev_b32_e32 v2, 3, v8                                // 0000000021E8: 30041083
	v_div_fixup_f32 v17, v0, v7, 1.0                           // 0000000021EC: D6270011 03CA0F00
	v_lshlrev_b64 v[0:1], 8, v[4:5]                            // 0000000021F4: D73C0000 00020888
	v_lshlrev_b64 v[4:5], 2, v[4:5]                            // 0000000021FC: D73C0004 00020882
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002204: BF870193
	v_cndmask_b32_e32 v8, 0, v17, vcc_lo                       // 000000002208: 02102280
	v_add_co_u32 v17, vcc_lo, s16, v0                          // 00000000220C: D7006A11 00020010
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002214: BF870194
	v_add_co_ci_u32_e32 v18, vcc_lo, s17, v1, vcc_lo           // 000000002218: 40240211
	v_mul_f32_e32 v11, v11, v8                                 // 00000000221C: 1016110B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002220: BF870091
	v_rndne_f32_e32 v11, v11                                   // 000000002224: 7E16470B
	v_cvt_i32_f32_e32 v11, v11                                 // 000000002228: 7E16110B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000222C: BF870091
	v_lshlrev_b32_e32 v11, 16, v11                             // 000000002230: 30161690
	v_and_b32_e32 v11, 0xff0000, v11                           // 000000002234: 361616FF 00FF0000
	v_mul_f32_e32 v15, v15, v8                                 // 00000000223C: 101E110F
	v_mul_f32_e32 v10, v10, v8                                 // 000000002240: 1014110A
	v_mul_f32_e32 v9, v9, v8                                   // 000000002244: 10121109
	v_mul_f32_e32 v13, v13, v8                                 // 000000002248: 101A110D
	v_mul_f32_e32 v12, v12, v8                                 // 00000000224C: 1018110C
	v_rndne_f32_e32 v15, v15                                   // 000000002250: 7E1E470F
	v_rndne_f32_e32 v10, v10                                   // 000000002254: 7E14470A
	v_rndne_f32_e32 v9, v9                                     // 000000002258: 7E124709
	v_rndne_f32_e32 v13, v13                                   // 00000000225C: 7E1A470D
	v_rndne_f32_e32 v12, v12                                   // 000000002260: 7E18470C
	v_cvt_i32_f32_e32 v15, v15                                 // 000000002264: 7E1E110F
	v_cvt_i32_f32_e32 v10, v10                                 // 000000002268: 7E14110A
	v_cvt_i32_f32_e32 v9, v9                                   // 00000000226C: 7E121109
	v_cvt_i32_f32_e32 v13, v13                                 // 000000002270: 7E1A110D
	v_cvt_i32_f32_e32 v12, v12                                 // 000000002274: 7E18110C
	v_dual_mul_f32 v14, v14, v8 :: v_dual_lshlrev_b32 v15, 16, v15// 000000002278: C8E2110E 0E0E1E90
	v_mul_f32_e32 v8, v16, v8                                  // 000000002280: 10101110
	v_lshlrev_b32_e32 v10, 8, v10                              // 000000002284: 30141488
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002288: BF870214
	v_perm_b32 v12, v12, v9, 0x40c0c00                         // 00000000228C: D644000C 03FE130C 040C0C00
	v_and_b32_e32 v15, 0xff0000, v15                           // 000000002298: 361E1EFF 00FF0000
	v_rndne_f32_e32 v14, v14                                   // 0000000022A0: 7E1C470E
	v_rndne_f32_e32 v8, v8                                     // 0000000022A4: 7E104708
	v_and_b32_e32 v10, 0xff00, v10                             // 0000000022A8: 361414FF 0000FF00
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000022B0: BF870193
	v_cvt_i32_f32_e32 v14, v14                                 // 0000000022B4: 7E1C110E
	v_cvt_i32_f32_e32 v8, v8                                   // 0000000022B8: 7E101108
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000022BC: BF870193
	v_or3_b32 v10, v12, v10, v11                               // 0000000022C0: D658000A 042E150C
	v_lshlrev_b32_e32 v14, 8, v14                              // 0000000022C8: 301C1C88
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 0000000022CC: BF870233
	v_perm_b32 v13, v8, v13, 0x40c0c00                         // 0000000022D0: D644000D 03FE1B08 040C0C00
	v_add_co_u32 v8, vcc_lo, v17, v2                           // 0000000022DC: D7006A08 00020511
	v_add_co_ci_u32_e32 v9, vcc_lo, 0, v18, vcc_lo             // 0000000022E4: 40122480
	v_and_b32_e32 v14, 0xff00, v14                             // 0000000022E8: 361C1CFF 0000FF00
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000022F0: BF870001
	v_or3_b32 v11, v13, v14, v15                               // 0000000022F4: D658000B 043E1D0D
	global_store_b64 v[8:9], v[10:11], off                     // 0000000022FC: DC6E0000 007C0A08
	s_and_saveexec_b32 s0, s1                                  // 000000002304: BE802001
	s_cbranch_execz 5                                          // 000000002308: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2320>
	v_add_co_u32 v8, vcc_lo, s18, v4                           // 00000000230C: D7006A08 00020812
	v_add_co_ci_u32_e32 v9, vcc_lo, s19, v5, vcc_lo            // 000000002314: 40120A13
	global_store_b32 v[8:9], v7, off                           // 000000002318: DC6A0000 007C0708
	s_or_b32 exec_lo, exec_lo, s0                              // 000000002320: 8C7E007E
	v_lshlrev_b32_e32 v10, 2, v2                               // 000000002324: 30140482
	ds_load_b128 v[6:9], v6 offset:6144                        // 000000002328: DBFC1800 06000006
	v_lshl_or_b32 v3, v3, 10, v10                              // 000000002330: D6560003 04291503
	ds_load_b128 v[10:13], v3 offset:6160                      // 000000002338: DBFC1810 0A000003
	s_waitcnt lgkmcnt(1)                                       // 000000002340: BF89FC17
	v_max3_f32 v3, |v6|, 0, |v7|                               // 000000002344: D61C0503 041D0106
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000234C: BF8700A1
	v_max3_f32 v3, v3, |v8|, |v9|                              // 000000002350: D61C0603 04261103
	s_waitcnt lgkmcnt(0)                                       // 000000002358: BF89FC07
	v_max3_f32 v3, v3, |v10|, |v11|                            // 00000000235C: D61C0603 042E1503
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002364: BF870091
	v_max3_f32 v3, v3, |v12|, |v13|                            // 000000002368: D61C0603 04361903
	v_mov_b32_dpp v14, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002370: 7E1C02FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002378: BF870091
	v_max_f32_e32 v14, v14, v14                                // 00000000237C: 201C1D0E
	v_max_f32_e32 v3, v3, v14                                  // 000000002380: 20061D03
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002384: BF870091
	v_mov_b32_dpp v14, v3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002388: 7E1C02FA FF091203
	v_max_f32_e32 v14, v14, v14                                // 000000002390: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002394: BF870091
	v_max_f32_e32 v3, v3, v14                                  // 000000002398: 20061D03
	v_mov_b32_dpp v14, v3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000239C: 7E1C02FA FF091403
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023A4: BF870091
	v_max_f32_e32 v14, v14, v14                                // 0000000023A8: 201C1D0E
	v_max_f32_e32 v3, v3, v14                                  // 0000000023AC: 20061D03
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023B0: BF870091
	v_mov_b32_dpp v14, v3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000023B4: 7E1C02FA FF091803
	v_max_f32_e32 v14, v14, v14                                // 0000000023BC: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023C0: BF870091
	v_max_f32_e32 v3, v3, v14                                  // 0000000023C4: 20061D03
	v_readlane_b32 s0, v3, 31                                  // 0000000023C8: D7600000 00013F03
	v_readlane_b32 s2, v3, 15                                  // 0000000023D0: D7600002 00011F03
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000023D8: BF870112
	v_max_f32_e64 v3, s0, s0                                   // 0000000023DC: D5100003 00000000
	v_max_f32_e64 v14, s2, s2                                  // 0000000023E4: D510000E 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023EC: BF870091
	v_max_f32_e32 v3, v14, v3                                  // 0000000023F0: 2006070E
	v_div_scale_f32 v14, null, 0x42fe0000, 0x42fe0000, v3      // 0000000023F4: D6FC7C0E 040DFEFF 42FE0000
	v_div_scale_f32 v17, vcc_lo, v3, 0x42fe0000, v3            // 000000002400: D6FC6A11 040DFF03 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000240C: BF8700B2
	v_rcp_f32_e32 v15, v14                                     // 000000002410: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 000000002414: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 000000002418: D6130010 23CA1F0E
	v_fmac_f32_e32 v15, v16, v15                               // 000000002420: 561E1F10
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002424: BF870091
	v_mul_f32_e32 v16, v17, v15                                // 000000002428: 10201F11
	v_fma_f32 v18, -v14, v16, v17                              // 00000000242C: D6130012 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002434: BF870091
	v_fmac_f32_e32 v16, v18, v15                               // 000000002438: 56201F12
	v_fma_f32 v14, -v14, v16, v17                              // 00000000243C: D613000E 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002444: BF870091
	v_div_fmas_f32 v14, v14, v15, v16                          // 000000002448: D637000E 04421F0E
	v_div_fixup_f32 v3, v14, 0x42fe0000, v3                    // 000000002450: D6270003 040DFF0E 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000245C: BF870121
	v_div_scale_f32 v14, null, v3, v3, 1.0                     // 000000002460: D6FC7C0E 03CA0703
	v_div_scale_f32 v17, vcc_lo, 1.0, v3, 1.0                  // 000000002468: D6FC6A11 03CA06F2
	v_rcp_f32_e32 v15, v14                                     // 000000002470: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 000000002474: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 000000002478: D6130010 23CA1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002480: BF870091
	v_fmac_f32_e32 v15, v16, v15                               // 000000002484: 561E1F10
	v_mul_f32_e32 v16, v17, v15                                // 000000002488: 10201F11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000248C: BF870091
	v_fma_f32 v18, -v14, v16, v17                              // 000000002490: D6130012 2446210E
	v_fmac_f32_e32 v16, v18, v15                               // 000000002498: 56201F12
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000249C: BF870091
	v_fma_f32 v14, -v14, v16, v17                              // 0000000024A0: D613000E 2446210E
	v_div_fmas_f32 v14, v14, v15, v16                          // 0000000024A8: D637000E 04421F0E
	v_cmp_neq_f32_e32 vcc_lo, 0, v3                            // 0000000024B0: 7C3A0680
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000024B4: BF870092
	v_div_fixup_f32 v14, v14, v3, 1.0                          // 0000000024B8: D627000E 03CA070E
	v_cndmask_b32_e32 v14, 0, v14, vcc_lo                      // 0000000024C0: 021C1C80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000024C4: BF870091
	v_mul_f32_e32 v7, v7, v14                                  // 0000000024C8: 100E1D07
	v_rndne_f32_e32 v7, v7                                     // 0000000024CC: 7E0E4707
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000024D0: BF870091
	v_cvt_i32_f32_e32 v7, v7                                   // 0000000024D4: 7E0E1107
	v_lshlrev_b32_e32 v7, 8, v7                                // 0000000024D8: 300E0E88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 0000000024DC: BF8701B1
	v_dual_mul_f32 v12, v12, v14 :: v_dual_and_b32 v7, 0xff00, v7// 0000000024E0: C8E41D0C 0C060EFF 0000FF00
	v_mul_f32_e32 v8, v8, v14                                  // 0000000024EC: 10101D08
	v_mul_f32_e32 v10, v10, v14                                // 0000000024F0: 10141D0A
	v_rndne_f32_e32 v12, v12                                   // 0000000024F4: 7E18470C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000024F8: BF870193
	v_rndne_f32_e32 v8, v8                                     // 0000000024FC: 7E104708
	v_rndne_f32_e32 v10, v10                                   // 000000002500: 7E14470A
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000002504: BF870223
	v_cvt_i32_f32_e32 v12, v12                                 // 000000002508: 7E18110C
	v_mul_f32_e32 v11, v11, v14                                // 00000000250C: 10161D0B
	v_cvt_i32_f32_e32 v8, v8                                   // 000000002510: 7E101108
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002514: BF870214
	v_cvt_i32_f32_e32 v10, v10                                 // 000000002518: 7E14110A
	v_lshlrev_b32_e32 v12, 16, v12                             // 00000000251C: 30181890
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000002520: BF8701B4
	v_rndne_f32_e32 v11, v11                                   // 000000002524: 7E16470B
	v_mul_f32_e32 v6, v6, v14                                  // 000000002528: 100C1D06
	v_dual_mul_f32 v13, v13, v14 :: v_dual_lshlrev_b32 v8, 16, v8// 00000000252C: C8E21D0D 0D081090
	v_cvt_i32_f32_e32 v11, v11                                 // 000000002534: 7E16110B
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002538: BF870193
	v_rndne_f32_e32 v6, v6                                     // 00000000253C: 7E0C4706
	v_and_b32_e32 v8, 0xff0000, v8                             // 000000002540: 361010FF 00FF0000
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002548: BF870214
	v_rndne_f32_e32 v13, v13                                   // 00000000254C: 7E1A470D
	v_lshlrev_b32_e32 v11, 8, v11                              // 000000002550: 30161688
	v_mul_f32_e32 v9, v9, v14                                  // 000000002554: 10121D09
	v_cvt_i32_f32_e32 v6, v6                                   // 000000002558: 7E0C1106
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000255C: BF870194
	v_cvt_i32_f32_e32 v13, v13                                 // 000000002560: 7E1A110D
	v_rndne_f32_e32 v9, v9                                     // 000000002564: 7E124709
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002568: BF870091
	v_cvt_i32_f32_e32 v9, v9                                   // 00000000256C: 7E121109
	v_perm_b32 v6, v9, v6, 0x40c0c00                           // 000000002570: D6440006 03FE0D09 040C0C00
	s_delay_alu instid0(VALU_DEP_4)                            // 00000000257C: BF870004
	v_perm_b32 v9, v13, v10, 0x40c0c00                         // 000000002580: D6440009 03FE150D 040C0C00
	v_and_b32_e32 v10, 0xff00, v11                             // 00000000258C: 361416FF 0000FF00
	v_and_b32_e32 v11, 0xff0000, v12                           // 000000002594: 361618FF 00FF0000
	v_add_co_u32 v12, vcc_lo, s20, v0                          // 00000000259C: D7006A0C 00020014
	v_add_co_ci_u32_e32 v13, vcc_lo, s21, v1, vcc_lo           // 0000000025A4: 401A0215
	v_or3_b32 v0, v6, v7, v8                                   // 0000000025A8: D6580000 04220F06
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 0000000025B0: BF870223
	v_add_co_u32 v6, vcc_lo, v12, v2                           // 0000000025B4: D7006A06 0002050C
	v_or3_b32 v1, v9, v10, v11                                 // 0000000025BC: D6580001 042E1509
	v_add_co_ci_u32_e32 v7, vcc_lo, 0, v13, vcc_lo             // 0000000025C4: 400E1A80
	global_store_b64 v[6:7], v[0:1], off                       // 0000000025C8: DC6E0000 007C0006
	s_and_b32 exec_lo, exec_lo, s1                             // 0000000025D0: 8B7E017E
	s_cbranch_execz 5                                          // 0000000025D4: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x25ec>
	v_add_co_u32 v0, vcc_lo, s22, v4                           // 0000000025D8: D7006A00 00020816
	v_add_co_ci_u32_e32 v1, vcc_lo, s23, v5, vcc_lo            // 0000000025E0: 40020A17
	global_store_b32 v[0:1], v3, off                           // 0000000025E4: DC6A0000 007C0300
	s_endpgm                                                   // 0000000025EC: BFB00000
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
	s_code_end                                                 // 000000002700: BF9F0000
	s_code_end                                                 // 000000002704: BF9F0000
	s_code_end                                                 // 000000002708: BF9F0000
	s_code_end                                                 // 00000000270C: BF9F0000
	s_code_end                                                 // 000000002710: BF9F0000
	s_code_end                                                 // 000000002714: BF9F0000
	s_code_end                                                 // 000000002718: BF9F0000
	s_code_end                                                 // 00000000271C: BF9F0000
	s_code_end                                                 // 000000002720: BF9F0000
	s_code_end                                                 // 000000002724: BF9F0000
	s_code_end                                                 // 000000002728: BF9F0000
	s_code_end                                                 // 00000000272C: BF9F0000
	s_code_end                                                 // 000000002730: BF9F0000
	s_code_end                                                 // 000000002734: BF9F0000
	s_code_end                                                 // 000000002738: BF9F0000
	s_code_end                                                 // 00000000273C: BF9F0000
	s_code_end                                                 // 000000002740: BF9F0000
	s_code_end                                                 // 000000002744: BF9F0000
	s_code_end                                                 // 000000002748: BF9F0000
	s_code_end                                                 // 00000000274C: BF9F0000
	s_code_end                                                 // 000000002750: BF9F0000
	s_code_end                                                 // 000000002754: BF9F0000
	s_code_end                                                 // 000000002758: BF9F0000
	s_code_end                                                 // 00000000275C: BF9F0000
	s_code_end                                                 // 000000002760: BF9F0000
	s_code_end                                                 // 000000002764: BF9F0000
	s_code_end                                                 // 000000002768: BF9F0000
	s_code_end                                                 // 00000000276C: BF9F0000
	s_code_end                                                 // 000000002770: BF9F0000
	s_code_end                                                 // 000000002774: BF9F0000
	s_code_end                                                 // 000000002778: BF9F0000
	s_code_end                                                 // 00000000277C: BF9F0000
