
/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad/isa/attn_prep_24_4_256_64_8204_11_k4jv4�_dc921509.elf:	file format elf64-amdgpu

Disassembly of section .text:

0000000000000000 <attn_prep_24_4_256_64_8204_11_k4jv4>:
	s_load_b64 s[28:29], s[0:1], 0x58                          // 000000000000: F4040700 F8000058
	s_lshr_b32 s12, s15, 2                                     // 000000000008: 850C820F
	s_waitcnt lgkmcnt(0)                                       // 00000000000C: BF89FC07
	s_load_b32 s2, s[28:29], 0x4                               // 000000000010: F400008E F8000004
	s_waitcnt lgkmcnt(0)                                       // 000000000018: BF89FC07
	s_cmp_ge_u32 s12, s2                                       // 00000000001C: BF09020C
	s_cbranch_scc1 2349                                        // 000000000020: BFA2092D <attn_prep_24_4_256_64_8204_11_k4jv4+0x24d8>
	s_clause 0x3                                               // 000000000024: BF850003
	s_load_b64 s[2:3], s[0:1], 0x50                            // 000000000028: F4040080 F8000050
	s_load_b128 s[24:27], s[0:1], 0x40                         // 000000000030: F4080600 F8000040
	s_load_b256 s[16:23], s[0:1], null                         // 000000000038: F40C0400 F8000000
	s_load_b256 s[4:11], s[0:1], 0x20                          // 000000000040: F40C0100 F8000020
	s_load_b32 s29, s[28:29], null                             // 000000000048: F400074E F8000000
	s_mov_b32 s0, exec_lo                                      // 000000000050: BE80007E
	v_cmpx_gt_u32_e32 16, v0                                   // 000000000054: 7D980090
	s_cbranch_execz 299                                        // 000000000058: BFA5012B <attn_prep_24_4_256_64_8204_11_k4jv4+0x508>
	s_mov_b32 s1, 0                                            // 00000000005C: BE810080
	s_mov_b32 s14, 0                                           // 000000000060: BE8E0080
	s_mov_b32 s13, exec_lo                                     // 000000000064: BE8D007E
	v_cmpx_lt_i32_e32 6, v0                                    // 000000000068: 7D820086
	s_xor_b32 s13, exec_lo, s13                                // 00000000006C: 8D0D0D7E
	s_cbranch_execz 77                                         // 000000000070: BFA5004D <attn_prep_24_4_256_64_8204_11_k4jv4+0x1a8>
	s_mov_b32 s14, exec_lo                                     // 000000000074: BE8E007E
	v_cmpx_lt_i32_e32 10, v0                                   // 000000000078: 7D82008A
	s_xor_b32 s14, exec_lo, s14                                // 00000000007C: 8D0E0E7E
	s_cbranch_execz 38                                         // 000000000080: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x11c>
	s_mov_b32 s28, exec_lo                                     // 000000000084: BE9C007E
	v_cmpx_lt_i32_e32 12, v0                                   // 000000000088: 7D82008C
	s_xor_b32 s28, exec_lo, s28                                // 00000000008C: 8D1C1C7E
	s_cbranch_execz 19                                         // 000000000090: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0xe0>
	s_mov_b32 s30, exec_lo                                     // 000000000094: BE9E007E
	v_cmpx_lt_i32_e32 13, v0                                   // 000000000098: 7D82008D
	s_xor_b32 s30, exec_lo, s30                                // 00000000009C: 8D1E1E7E
	s_cbranch_execz 11                                         // 0000000000A0: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0xd0>
	s_mov_b32 s33, exec_lo                                     // 0000000000A4: BEA1007E
	v_cmpx_ne_u32_e32 14, v0                                   // 0000000000A8: 7D9A008E
	s_xor_b32 s33, exec_lo, s33                                // 0000000000AC: 8D21217E
	s_mov_b32 s31, 0x402ee2bf                                  // 0000000000B0: BE9F00FF 402EE2BF
	s_or_saveexec_b32 s33, s33                                 // 0000000000B8: BEA12221
	v_mov_b32_e32 v1, s31                                      // 0000000000BC: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s33                            // 0000000000C0: 8D7E217E
	v_mov_b32_e32 v1, 0x40046ac7                               // 0000000000C4: 7E0202FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s33                             // 0000000000CC: 8C7E217E
	s_and_not1_saveexec_b32 s30, s30                           // 0000000000D0: BE9E301E
	v_mov_b32_e32 v1, 0x3fcf1c25                               // 0000000000D4: 7E0202FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000000DC: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 0000000000E0: BE9C301C
	s_cbranch_execz 11                                         // 0000000000E4: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x114>
	s_mov_b32 s30, exec_lo                                     // 0000000000E8: BE9E007E
	v_cmpx_lt_i32_e32 11, v0                                   // 0000000000EC: 7D82008B
	s_xor_b32 s30, exec_lo, s30                                // 0000000000F0: 8D1E1E7E
	s_mov_b32 s31, 0x3fa0cc2f                                  // 0000000000F4: BE9F00FF 3FA0CC2F
	s_or_saveexec_b32 s30, s30                                 // 0000000000FC: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000100: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000104: 8D7E1E7E
	v_mov_b32_e32 v1, 0x3f713d3a                               // 000000000108: 7E0202FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000110: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000114: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000118: 8C7E1C7E
	s_and_not1_saveexec_b32 s14, s14                           // 00000000011C: BE8E300E
	s_cbranch_execz 30                                         // 000000000120: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x19c>
	s_mov_b32 s28, exec_lo                                     // 000000000124: BE9C007E
	v_cmpx_lt_i32_e32 8, v0                                    // 000000000128: 7D820088
	s_xor_b32 s28, exec_lo, s28                                // 00000000012C: 8D1C1C7E
	s_cbranch_execz 11                                         // 000000000130: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x160>
	s_mov_b32 s30, exec_lo                                     // 000000000134: BE9E007E
	v_cmpx_lt_i32_e32 9, v0                                    // 000000000138: 7D820089
	s_xor_b32 s30, exec_lo, s30                                // 00000000013C: 8D1E1E7E
	s_mov_b32 s31, 0x3f28215d                                  // 000000000140: BE9F00FF 3F28215D
	s_or_saveexec_b32 s30, s30                                 // 000000000148: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 00000000014C: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000150: 8D7E1E7E
	v_mov_b32_e32 v1, 0x3ec6ae44                               // 000000000154: 7E0202FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s30                             // 00000000015C: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000160: BE9C301C
	s_cbranch_execz 11                                         // 000000000164: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x194>
	s_mov_b32 s30, exec_lo                                     // 000000000168: BE9E007E
	v_cmpx_lt_i32_e32 7, v0                                    // 00000000016C: 7D820087
	s_xor_b32 s30, exec_lo, s30                                // 000000000170: 8D1E1E7E
	s_mov_b32 s31, 0x3e0379fb                                  // 000000000174: BE9F00FF 3E0379FB
	s_or_saveexec_b32 s30, s30                                 // 00000000017C: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000180: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000184: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbe0379fb                               // 000000000188: 7E0202FF BE0379FB
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000190: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000194: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000198: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 00000000019C: BF870499
	s_or_b32 exec_lo, exec_lo, s14                             // 0000000001A0: 8C7E0E7E
	s_mov_b32 s14, exec_lo                                     // 0000000001A4: BE8E007E
	s_and_not1_saveexec_b32 s13, s13                           // 0000000001A8: BE8D300D
	s_cbranch_execz 67                                         // 0000000001AC: BFA50043 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2bc>
	s_mov_b32 s28, s14                                         // 0000000001B0: BE9C000E
	s_mov_b32 s1, exec_lo                                      // 0000000001B4: BE81007E
	v_cmpx_lt_i32_e32 2, v0                                    // 0000000001B8: 7D820082
	s_xor_b32 s1, exec_lo, s1                                  // 0000000001BC: 8D01017E
	s_cbranch_execz 31                                         // 0000000001C0: BFA5001F <attn_prep_24_4_256_64_8204_11_k4jv4+0x240>
	s_mov_b32 s28, exec_lo                                     // 0000000001C4: BE9C007E
	v_cmpx_lt_i32_e32 4, v0                                    // 0000000001C8: 7D820084
	s_xor_b32 s28, exec_lo, s28                                // 0000000001CC: 8D1C1C7E
	s_cbranch_execz 11                                         // 0000000001D0: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x200>
	s_mov_b32 s30, exec_lo                                     // 0000000001D4: BE9E007E
	v_cmpx_lt_i32_e32 5, v0                                    // 0000000001D8: 7D820085
	s_xor_b32 s30, exec_lo, s30                                // 0000000001DC: 8D1E1E7E
	s_mov_b32 s31, 0xbec6ae44                                  // 0000000001E0: BE9F00FF BEC6AE44
	s_or_saveexec_b32 s30, s30                                 // 0000000001E8: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 0000000001EC: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000001F0: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbf28215d                               // 0000000001F4: 7E0202FF BF28215D
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000001FC: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000200: BE9C301C
	s_cbranch_execz 11                                         // 000000000204: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x234>
	s_mov_b32 s30, exec_lo                                     // 000000000208: BE9E007E
	v_cmpx_lt_i32_e32 3, v0                                    // 00000000020C: 7D820083
	s_xor_b32 s30, exec_lo, s30                                // 000000000210: 8D1E1E7E
	s_mov_b32 s31, 0xbf713d3a                                  // 000000000214: BE9F00FF BF713D3A
	s_or_saveexec_b32 s30, s30                                 // 00000000021C: BE9E221E
	v_mov_b32_e32 v1, s31                                      // 000000000220: 7E02021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000224: 8D7E1E7E
	v_mov_b32_e32 v1, 0xbfa0cc2f                               // 000000000228: 7E0202FF BFA0CC2F
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000230: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000234: BF870499
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000238: 8C7E1C7E
	s_or_b32 s28, s14, exec_lo                                 // 00000000023C: 8C1C7E0E
	s_or_saveexec_b32 s1, s1                                   // 000000000240: BE812201
	s_mov_b32 s30, 0                                           // 000000000244: BE9E0080
	s_xor_b32 exec_lo, exec_lo, s1                             // 000000000248: 8D7E017E
	s_cbranch_execz 21                                         // 00000000024C: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0x2a4>
	s_mov_b32 s31, -1                                          // 000000000250: BE9F00C1
	s_mov_b32 s33, s28                                         // 000000000254: BEA1001C
	s_mov_b32 s30, exec_lo                                     // 000000000258: BE9E007E
	v_cmpx_lt_i32_e32 0, v0                                    // 00000000025C: 7D820080
	s_cbranch_execz 10                                         // 000000000260: BFA5000A <attn_prep_24_4_256_64_8204_11_k4jv4+0x28c>
	v_mov_b32_e32 v1, 0xc0046ac7                               // 000000000264: 7E0202FF C0046AC7
	s_mov_b32 s31, exec_lo                                     // 00000000026C: BE9F007E
	v_cmpx_lt_i32_e32 1, v0                                    // 000000000270: 7D820081
	v_mov_b32_e32 v1, 0xbfcf1c25                               // 000000000274: 7E0202FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 00000000027C: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000280: BF870009
	s_xor_b32 s31, exec_lo, -1                                 // 000000000284: 8D1FC17E
	s_or_b32 s33, s28, exec_lo                                 // 000000000288: 8C217E1C
	s_or_b32 exec_lo, exec_lo, s30                             // 00000000028C: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000290: BF870009
	s_and_not1_b32 s28, s28, exec_lo                           // 000000000294: 911C7E1C
	s_and_b32 s33, s33, exec_lo                                // 000000000298: 8B217E21
	s_and_b32 s30, s31, exec_lo                                // 00000000029C: 8B1E7E1F
	s_or_b32 s28, s28, s33                                     // 0000000002A0: 8C1C211C
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000002A4: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000002A8: BF870009
	s_and_not1_b32 s14, s14, exec_lo                           // 0000000002AC: 910E7E0E
	s_and_b32 s28, s28, exec_lo                                // 0000000002B0: 8B1C7E1C
	s_and_b32 s1, s30, exec_lo                                 // 0000000002B4: 8B017E1E
	s_or_b32 s14, s14, s28                                     // 0000000002B8: 8C0E1C0E
	s_or_b32 exec_lo, exec_lo, s13                             // 0000000002BC: 8C7E0D7E
	s_and_saveexec_b32 s13, s14                                // 0000000002C0: BE8D200E
	s_cbranch_execz 132                                        // 0000000002C4: BFA50084 <attn_prep_24_4_256_64_8204_11_k4jv4+0x4d8>
	v_lshlrev_b32_e32 v2, 2, v0                                // 0000000002C8: 30040082
	s_mov_b32 s14, exec_lo                                     // 0000000002CC: BE8E007E
	ds_store_b32 v2, v1 offset:17920                           // 0000000002D0: D8344600 00000102
	v_cmpx_lt_i32_e32 7, v0                                    // 0000000002D8: 7D820087
	s_xor_b32 s14, exec_lo, s14                                // 0000000002DC: 8D0E0E7E
	s_cbranch_execz 65                                         // 0000000002E0: BFA50041 <attn_prep_24_4_256_64_8204_11_k4jv4+0x3e8>
	s_mov_b32 s28, exec_lo                                     // 0000000002E4: BE9C007E
	v_cmpx_lt_i32_e32 10, v0                                   // 0000000002E8: 7D82008A
	s_xor_b32 s28, exec_lo, s28                                // 0000000002EC: 8D1C1C7E
	s_cbranch_execz 38                                         // 0000000002F0: BFA50026 <attn_prep_24_4_256_64_8204_11_k4jv4+0x38c>
	s_mov_b32 s30, exec_lo                                     // 0000000002F4: BE9E007E
	v_cmpx_lt_i32_e32 12, v0                                   // 0000000002F8: 7D82008C
	s_xor_b32 s30, exec_lo, s30                                // 0000000002FC: 8D1E1E7E
	s_cbranch_execz 19                                         // 000000000300: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x350>
	s_mov_b32 s31, exec_lo                                     // 000000000304: BE9F007E
	v_cmpx_lt_i32_e32 13, v0                                   // 000000000308: 7D82008D
	s_xor_b32 s31, exec_lo, s31                                // 00000000030C: 8D1F1F7E
	s_cbranch_execz 11                                         // 000000000310: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x340>
	s_mov_b32 s33, exec_lo                                     // 000000000314: BEA1007E
	v_cmpx_ne_u32_e32 14, v0                                   // 000000000318: 7D9A008E
	s_xor_b32 s33, exec_lo, s33                                // 00000000031C: 8D21217E
	s_mov_b32 s34, 0x402ee2bf                                  // 000000000320: BEA200FF 402EE2BF
	s_or_saveexec_b32 s33, s33                                 // 000000000328: BEA12221
	v_mov_b32_e32 v2, s34                                      // 00000000032C: 7E040222
	s_xor_b32 exec_lo, exec_lo, s33                            // 000000000330: 8D7E217E
	v_mov_b32_e32 v2, 0x40046ac7                               // 000000000334: 7E0402FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s33                             // 00000000033C: 8C7E217E
	s_and_not1_saveexec_b32 s31, s31                           // 000000000340: BE9F301F
	v_mov_b32_e32 v2, 0x3fcf1c25                               // 000000000344: 7E0402FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 00000000034C: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 000000000350: BE9E301E
	s_cbranch_execz 11                                         // 000000000354: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x384>
	s_mov_b32 s31, exec_lo                                     // 000000000358: BE9F007E
	v_cmpx_lt_i32_e32 11, v0                                   // 00000000035C: 7D82008B
	s_xor_b32 s31, exec_lo, s31                                // 000000000360: 8D1F1F7E
	s_mov_b32 s33, 0x3fa0cc2f                                  // 000000000364: BEA100FF 3FA0CC2F
	s_or_saveexec_b32 s31, s31                                 // 00000000036C: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 000000000370: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 000000000374: 8D7E1F7E
	v_mov_b32_e32 v2, 0x3f713d3a                               // 000000000378: 7E0402FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000380: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000384: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000388: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 00000000038C: BE9C301C
	s_cbranch_execz 19                                         // 000000000390: BFA50013 <attn_prep_24_4_256_64_8204_11_k4jv4+0x3e0>
	s_mov_b32 s30, exec_lo                                     // 000000000394: BE9E007E
	v_cmpx_lt_i32_e32 8, v0                                    // 000000000398: 7D820088
	s_xor_b32 s30, exec_lo, s30                                // 00000000039C: 8D1E1E7E
	s_cbranch_execz 11                                         // 0000000003A0: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x3d0>
	s_mov_b32 s31, exec_lo                                     // 0000000003A4: BE9F007E
	v_cmpx_lt_i32_e32 9, v0                                    // 0000000003A8: 7D820089
	s_xor_b32 s31, exec_lo, s31                                // 0000000003AC: 8D1F1F7E
	s_mov_b32 s33, 0x3f28215d                                  // 0000000003B0: BEA100FF 3F28215D
	s_or_saveexec_b32 s31, s31                                 // 0000000003B8: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 0000000003BC: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000003C0: 8D7E1F7E
	v_mov_b32_e32 v2, 0x3ec6ae44                               // 0000000003C4: 7E0402FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000003CC: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 0000000003D0: BE9E301E
	v_mov_b32_e32 v2, 0x3e0379fb                               // 0000000003D4: 7E0402FF 3E0379FB
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000003DC: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000003E0: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000003E4: 8C7E1C7E
	s_and_not1_saveexec_b32 s14, s14                           // 0000000003E8: BE8E300E
	s_cbranch_execz 56                                         // 0000000003EC: BFA50038 <attn_prep_24_4_256_64_8204_11_k4jv4+0x4d0>
	s_mov_b32 s28, exec_lo                                     // 0000000003F0: BE9C007E
	v_cmpx_lt_i32_e32 3, v0                                    // 0000000003F4: 7D820083
	s_xor_b32 s28, exec_lo, s28                                // 0000000003F8: 8D1C1C7E
	s_cbranch_execz 30                                         // 0000000003FC: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x478>
	s_mov_b32 s30, exec_lo                                     // 000000000400: BE9E007E
	v_cmpx_lt_i32_e32 5, v0                                    // 000000000404: 7D820085
	s_xor_b32 s30, exec_lo, s30                                // 000000000408: 8D1E1E7E
	s_cbranch_execz 11                                         // 00000000040C: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x43c>
	s_mov_b32 s31, exec_lo                                     // 000000000410: BE9F007E
	v_cmpx_lt_i32_e32 6, v0                                    // 000000000414: 7D820086
	s_xor_b32 s31, exec_lo, s31                                // 000000000418: 8D1F1F7E
	s_mov_b32 s33, 0xbe0379fb                                  // 00000000041C: BEA100FF BE0379FB
	s_or_saveexec_b32 s31, s31                                 // 000000000424: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 000000000428: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 00000000042C: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbec6ae44                               // 000000000430: 7E0402FF BEC6AE44
	s_or_b32 exec_lo, exec_lo, s31                             // 000000000438: 8C7E1F7E
	s_and_not1_saveexec_b32 s30, s30                           // 00000000043C: BE9E301E
	s_cbranch_execz 11                                         // 000000000440: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x470>
	s_mov_b32 s31, exec_lo                                     // 000000000444: BE9F007E
	v_cmpx_lt_i32_e32 4, v0                                    // 000000000448: 7D820084
	s_xor_b32 s31, exec_lo, s31                                // 00000000044C: 8D1F1F7E
	s_mov_b32 s33, 0xbf28215d                                  // 000000000450: BEA100FF BF28215D
	s_or_saveexec_b32 s31, s31                                 // 000000000458: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 00000000045C: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 000000000460: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbf713d3a                               // 000000000464: 7E0402FF BF713D3A
	s_or_b32 exec_lo, exec_lo, s31                             // 00000000046C: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000470: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000474: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000478: BE9C301C
	s_cbranch_execz 18                                         // 00000000047C: BFA50012 <attn_prep_24_4_256_64_8204_11_k4jv4+0x4c8>
	v_mov_b32_e32 v2, 0xc0046ac7                               // 000000000480: 7E0402FF C0046AC7
	s_mov_b32 s30, exec_lo                                     // 000000000488: BE9E007E
	v_cmpx_lt_i32_e32 1, v0                                    // 00000000048C: 7D820081
	s_cbranch_execz 11                                         // 000000000490: BFA5000B <attn_prep_24_4_256_64_8204_11_k4jv4+0x4c0>
	s_mov_b32 s31, exec_lo                                     // 000000000494: BE9F007E
	v_cmpx_lt_i32_e32 2, v0                                    // 000000000498: 7D820082
	s_xor_b32 s31, exec_lo, s31                                // 00000000049C: 8D1F1F7E
	s_mov_b32 s33, 0xbfa0cc2f                                  // 0000000004A0: BEA100FF BFA0CC2F
	s_or_saveexec_b32 s31, s31                                 // 0000000004A8: BE9F221F
	v_mov_b32_e32 v2, s33                                      // 0000000004AC: 7E040221
	s_xor_b32 exec_lo, exec_lo, s31                            // 0000000004B0: 8D7E1F7E
	v_mov_b32_e32 v2, 0xbfcf1c25                               // 0000000004B4: 7E0402FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s31                             // 0000000004BC: 8C7E1F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004C0: BF870009
	s_or_b32 exec_lo, exec_lo, s30                             // 0000000004C4: 8C7E1E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004C8: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000004CC: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004D0: BF870009
	s_or_b32 exec_lo, exec_lo, s14                             // 0000000004D4: 8C7E0E7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004D8: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 0000000004DC: 8C7E0D7E
	s_and_saveexec_b32 s13, s1                                 // 0000000004E0: BE8D2001
	v_dual_mov_b32 v2, 0xc02ee2bf :: v_dual_mov_b32 v1, 0      // 0000000004E4: CA1000FF 02000080 C02EE2BF
	ds_store_b32 v1, v2 offset:17920                           // 0000000004F0: D8344600 00000201
	s_or_b32 exec_lo, exec_lo, s13                             // 0000000004F8: 8C7E0D7E
	v_lshlrev_b32_e32 v1, 2, v0                                // 0000000004FC: 30020082
	ds_store_b32 v1, v2 offset:17984                           // 000000000500: D8344640 00000201
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000508: 8C7E007E
	v_mbcnt_lo_u32_b32 v4, -1, 0                               // 00000000050C: D71F0004 000100C1
	v_lshrrev_b32_e32 v1, 5, v0                                // 000000000514: 32020085
	v_cmp_gt_u32_e64 s0, 0xc0, v0                              // 000000000518: D44C0000 000200FF 000000C0
	s_and_b32 s28, s15, 3                                      // 000000000524: 8B1C830F
	s_mov_b32 s13, 0                                           // 000000000528: BE8D0080
	s_mov_b32 s1, exec_lo                                      // 00000000052C: BE81007E
	v_cmpx_lt_u32_e32 0xbf, v0                                 // 000000000530: 7D9200FF 000000BF
	s_xor_b32 s30, exec_lo, s1                                 // 000000000538: 8D1E017E
	s_cbranch_execz 171                                        // 00000000053C: BFA500AB <attn_prep_24_4_256_64_8204_11_k4jv4+0x7ec>
	s_lshl_b64 s[14:15], s[12:13], 10                          // 000000000540: 848E8A0C
	s_mov_b32 s1, exec_lo                                      // 000000000544: BE81007E
	v_cmpx_lt_i32_e32 6, v1                                    // 000000000548: 7D820286
	s_xor_b32 s1, exec_lo, s1                                  // 00000000054C: 8D01017E
	s_cbranch_execz 24                                         // 000000000550: BFA50018 <attn_prep_24_4_256_64_8204_11_k4jv4+0x5b4>
	s_mov_b32 s13, exec_lo                                     // 000000000554: BE8D007E
	v_cmpx_eq_u32_e32 7, v1                                    // 000000000558: 7D940287
	s_cbranch_execz 20                                         // 00000000055C: BFA50014 <attn_prep_24_4_256_64_8204_11_k4jv4+0x5b0>
	s_lshl_b64 s[34:35], s[14:15], 2                           // 000000000560: 84A2820E
	v_lshlrev_b32_e32 v2, 5, v4                                // 000000000564: 30040885
	s_waitcnt lgkmcnt(0)                                       // 000000000568: BF89FC07
	s_add_u32 s10, s10, s34                                    // 00000000056C: 800A220A
	s_addc_u32 s11, s11, s35                                   // 000000000570: 820B230B
	s_lshl_b32 s31, s28, 10                                    // 000000000574: 841F8A1C
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000578: BF870009
	s_add_u32 s10, s10, s31                                    // 00000000057C: 800A1F0A
	s_addc_u32 s11, s11, 0                                     // 000000000580: 820B800B
	s_clause 0x1                                               // 000000000584: BF850001
	global_load_b128 v[5:8], v2, s[10:11]                      // 000000000588: DC5E0000 050A0002
	global_load_b128 v[9:12], v2, s[10:11] offset:16           // 000000000590: DC5E0010 090A0002
	s_waitcnt vmcnt(1)                                         // 000000000598: BF8907F7
	ds_store_b128 v2, v[5:8] offset:13312                      // 00000000059C: DB7C3400 00000502
	s_waitcnt vmcnt(0)                                         // 0000000005A4: BF8903F7
	ds_store_b128 v2, v[9:12] offset:13328                     // 0000000005A8: DB7C3410 00000902
	s_or_b32 exec_lo, exec_lo, s13                             // 0000000005B0: 8C7E0D7E
	s_waitcnt lgkmcnt(0)                                       // 0000000005B4: BF89FC07
	s_and_not1_saveexec_b32 s10, s1                            // 0000000005B8: BE8A3001
	s_cbranch_execz 137                                        // 0000000005BC: BFA50089 <attn_prep_24_4_256_64_8204_11_k4jv4+0x7e4>
	s_mov_b32 s11, exec_lo                                     // 0000000005C0: BE8B007E
	v_cmpx_eq_u32_e32 6, v1                                    // 0000000005C4: 7D940286
	s_cbranch_execz 133                                        // 0000000005C8: BFA50085 <attn_prep_24_4_256_64_8204_11_k4jv4+0x7e0>
	s_lshl_b64 s[14:15], s[14:15], 2                           // 0000000005CC: 848E820E
	v_lshlrev_b32_e32 v2, 5, v4                                // 0000000005D0: 30040885
	s_add_u32 s1, s8, s14                                      // 0000000005D4: 80010E08
	s_addc_u32 s9, s9, s15                                     // 0000000005D8: 82090F09
	s_lshl_b32 s8, s28, 10                                     // 0000000005DC: 84088A1C
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000005E0: BF870009
	s_add_u32 s8, s1, s8                                       // 0000000005E4: 80080801
	s_addc_u32 s9, s9, 0                                       // 0000000005E8: 82098009
	s_clause 0x3                                               // 0000000005EC: BF850003
	global_load_b128 v[5:8], v2, s[8:9]                        // 0000000005F0: DC5E0000 05080002
	global_load_b128 v[9:12], v2, s[8:9] offset:16             // 0000000005F8: DC5E0010 09080002
	global_load_b128 v[13:16], v2, s[26:27]                    // 000000000600: DC5E0000 0D1A0002
	global_load_b128 v[17:20], v2, s[26:27] offset:16          // 000000000608: DC5E0010 111A0002
	s_waitcnt vmcnt(3)                                         // 000000000610: BF890FF7
	v_mul_f32_e32 v3, v6, v6                                   // 000000000614: 10060D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000618: BF870091
	v_fmac_f32_e32 v3, v5, v5                                  // 00000000061C: 56060B05
	v_fmac_f32_e32 v3, v7, v7                                  // 000000000620: 56060F07
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000624: BF8700A1
	v_fmac_f32_e32 v3, v8, v8                                  // 000000000628: 56061108
	s_waitcnt vmcnt(2)                                         // 00000000062C: BF890BF7
	v_fmac_f32_e32 v3, v9, v9                                  // 000000000630: 56061309
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000634: BF870091
	v_fmac_f32_e32 v3, v10, v10                                // 000000000638: 5606150A
	v_fmac_f32_e32 v3, v11, v11                                // 00000000063C: 5606170B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000640: BF870091
	v_fmac_f32_e32 v3, v12, v12                                // 000000000644: 5606190C
	v_add_f32_dpp v3, v3, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000648: 060606FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000650: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000654: 060606FA FF091203
	v_add_f32_dpp v3, v3, v3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000065C: 060606FA FF091403
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000664: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000000668: 060606FA FF091803
	v_readlane_b32 s1, v3, 15                                  // 000000000670: D7600001 00011F03
	v_readlane_b32 s8, v3, 31                                  // 000000000678: D7600008 00013F03
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000680: BF870001
	v_add_f32_e64 v3, s1, s8                                   // 000000000684: D5030003 00001001
	s_mov_b32 s1, 0x3b800000                                   // 00000000068C: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 000000000694: BF870481
	v_fmaak_f32 v3, s1, v3, 0x358637bd                         // 000000000698: 5A060601 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000006A0: BF870121
	v_mul_f32_e32 v21, 0x4f800000, v3                          // 0000000006A4: 102A06FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v3                     // 0000000006AC: 7C2806FF 0F800000
	v_cndmask_b32_e32 v3, v3, v21, vcc_lo                      // 0000000006B4: 02062B03
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 0000000006B8: BF870141
	v_sqrt_f32_e32 v21, v3                                     // 0000000006BC: 7E2A6703
	s_waitcnt_depctr 0xfff                                     // 0000000006C0: BF880FFF
	v_add_nc_u32_e32 v22, -1, v21                              // 0000000006C4: 4A2C2AC1
	v_add_nc_u32_e32 v23, 1, v21                               // 0000000006C8: 4A2E2A81
	v_fma_f32 v24, -v22, v21, v3                               // 0000000006CC: D6130018 240E2B16
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000006D4: BF870112
	v_fma_f32 v25, -v23, v21, v3                               // 0000000006D8: D6130019 240E2B17
	v_cmp_ge_f32_e64 s1, 0, v24                                // 0000000006E0: D4160001 00023080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000006E8: BF870191
	v_cndmask_b32_e64 v21, v21, v22, s1                        // 0000000006EC: D5010015 00062D15
	v_cmp_lt_f32_e64 s1, 0, v25                                // 0000000006F4: D4110001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000006FC: BF870091
	v_cndmask_b32_e64 v21, v21, v23, s1                        // 000000000700: D5010015 00062F15
	v_mul_f32_e32 v22, 0x37800000, v21                         // 000000000708: 102C2AFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000710: BF870121
	v_cndmask_b32_e32 v21, v21, v22, vcc_lo                    // 000000000714: 022A2D15
	v_cmp_class_f32_e64 vcc_lo, v3, 0x260                      // 000000000718: D47E006A 0001FF03 00000260
	v_cndmask_b32_e32 v3, v21, v3, vcc_lo                      // 000000000724: 02060715
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000728: BF870121
	v_div_scale_f32 v21, null, v3, v3, 1.0                     // 00000000072C: D6FC7C15 03CA0703
	v_div_scale_f32 v24, vcc_lo, 1.0, v3, 1.0                  // 000000000734: D6FC6A18 03CA06F2
	v_rcp_f32_e32 v22, v21                                     // 00000000073C: 7E2C5515
	s_waitcnt_depctr 0xfff                                     // 000000000740: BF880FFF
	v_fma_f32 v23, -v21, v22, 1.0                              // 000000000744: D6130017 23CA2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000074C: BF870091
	v_fmac_f32_e32 v22, v23, v22                               // 000000000750: 562C2D17
	v_mul_f32_e32 v23, v24, v22                                // 000000000754: 102E2D18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000758: BF870091
	v_fma_f32 v25, -v21, v23, v24                              // 00000000075C: D6130019 24622F15
	v_fmac_f32_e32 v23, v25, v22                               // 000000000764: 562E2D19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000768: BF870091
	v_fma_f32 v21, -v21, v23, v24                              // 00000000076C: D6130015 24622F15
	v_div_fmas_f32 v21, v21, v22, v23                          // 000000000774: D6370015 045E2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000077C: BF870091
	v_div_fixup_f32 v3, v21, v3, 1.0                           // 000000000780: D6270003 03CA0715
	v_mul_f32_e32 v10, v10, v3                                 // 000000000788: 1014070A
	v_mul_f32_e32 v5, v5, v3                                   // 00000000078C: 100A0705
	v_mul_f32_e32 v6, v6, v3                                   // 000000000790: 100C0706
	v_mul_f32_e32 v7, v7, v3                                   // 000000000794: 100E0707
	v_mul_f32_e32 v8, v8, v3                                   // 000000000798: 10100708
	v_mul_f32_e32 v9, v9, v3                                   // 00000000079C: 10120709
	v_mul_f32_e32 v11, v11, v3                                 // 0000000007A0: 1016070B
	v_mul_f32_e32 v3, v12, v3                                  // 0000000007A4: 1006070C
	s_waitcnt vmcnt(1)                                         // 0000000007A8: BF8907F7
	v_dual_mul_f32 v5, v13, v5 :: v_dual_mul_f32 v6, v14, v6   // 0000000007AC: C8C60B0D 05060D0E
	v_dual_mul_f32 v7, v15, v7 :: v_dual_mul_f32 v8, v8, v16   // 0000000007B4: C8C60F0F 07082108
	s_waitcnt vmcnt(0)                                         // 0000000007BC: BF8903F7
	v_dual_mul_f32 v9, v9, v17 :: v_dual_mul_f32 v10, v10, v18 // 0000000007C0: C8C62309 090A250A
	v_mul_f32_e32 v11, v11, v19                                // 0000000007C8: 1016270B
	v_mul_f32_e32 v12, v3, v20                                 // 0000000007CC: 10182903
	ds_store_b128 v2, v[5:8] offset:12288                      // 0000000007D0: DB7C3000 00000502
	ds_store_b128 v2, v[9:12] offset:12304                     // 0000000007D8: DB7C3010 00000902
	s_or_b32 exec_lo, exec_lo, s11                             // 0000000007E0: 8C7E0B7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000007E4: BF870009
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000007E8: 8C7E0A7E
	s_waitcnt lgkmcnt(0)                                       // 0000000007EC: BF89FC07
	s_or_saveexec_b32 s8, s30                                  // 0000000007F0: BE88221E
	v_lshlrev_b32_e32 v2, 5, v4                                // 0000000007F4: 30040885
	s_xor_b32 exec_lo, exec_lo, s8                             // 0000000007F8: 8D7E087E
	s_cbranch_execz 159                                        // 0000000007FC: BFA5009F <attn_prep_24_4_256_64_8204_11_k4jv4+0xa7c>
	s_mul_i32 s1, s28, 6                                       // 000000000800: 9601861C
	s_mul_i32 s9, s12, 0xc000                                  // 000000000804: 9609FF0C 0000C000
	v_add_lshl_u32 v3, s1, v1, 11                              // 00000000080C: D6470003 022E0201
	s_mul_hi_u32 s1, s12, 0xc000                               // 000000000814: 9681FF0C 0000C000
	s_add_u32 s6, s6, s9                                       // 00000000081C: 80060906
	s_addc_u32 s1, s7, s1                                      // 000000000820: 82010107
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000824: BF870091
	v_add_co_u32 v3, s6, s6, v3                                // 000000000828: D7000603 00020606
	v_add_co_ci_u32_e64 v5, null, s1, 0, s6                    // 000000000830: D5207C05 00190001
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000838: BF870112
	v_add_co_u32 v9, vcc_lo, v3, v2                            // 00000000083C: D7006A09 00020503
	v_add_co_ci_u32_e32 v10, vcc_lo, 0, v5, vcc_lo             // 000000000844: 40140A80
	s_clause 0x1                                               // 000000000848: BF850001
	global_load_b128 v[5:8], v[9:10], off                      // 00000000084C: DC5E0000 057C0009
	global_load_b128 v[9:12], v[9:10], off offset:16           // 000000000854: DC5E0010 097C0009
	s_clause 0x1                                               // 00000000085C: BF850001
	global_load_b128 v[13:16], v2, s[24:25]                    // 000000000860: DC5E0000 0D180002
	global_load_b128 v[17:20], v2, s[24:25] offset:16          // 000000000868: DC5E0010 11180002
	s_waitcnt vmcnt(3)                                         // 000000000870: BF890FF7
	v_mul_f32_e32 v3, v6, v6                                   // 000000000874: 10060D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000878: BF870091
	v_fmac_f32_e32 v3, v5, v5                                  // 00000000087C: 56060B05
	v_fmac_f32_e32 v3, v7, v7                                  // 000000000880: 56060F07
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000000884: BF8700A1
	v_fmac_f32_e32 v3, v8, v8                                  // 000000000888: 56061108
	s_waitcnt vmcnt(2)                                         // 00000000088C: BF890BF7
	v_fmac_f32_e32 v3, v9, v9                                  // 000000000890: 56061309
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000894: BF870091
	v_fmac_f32_e32 v3, v10, v10                                // 000000000898: 5606150A
	v_fmac_f32_e32 v3, v11, v11                                // 00000000089C: 5606170B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008A0: BF870091
	v_fmac_f32_e32 v3, v12, v12                                // 0000000008A4: 5606190C
	v_add_f32_dpp v3, v3, v3 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000008A8: 060606FA FF091103
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008B0: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000008B4: 060606FA FF091203
	v_add_f32_dpp v3, v3, v3 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000008BC: 060606FA FF091403
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000008C4: BF870091
	v_add_f32_dpp v3, v3, v3 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000008C8: 060606FA FF091803
	v_readlane_b32 s1, v3, 15                                  // 0000000008D0: D7600001 00011F03
	v_readlane_b32 s6, v3, 31                                  // 0000000008D8: D7600006 00013F03
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000008E0: BF870001
	v_add_f32_e64 v3, s1, s6                                   // 0000000008E4: D5030003 00000C01
	s_mov_b32 s1, 0x3b800000                                   // 0000000008EC: BE8100FF 3B800000
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)    // 0000000008F4: BF870481
	v_fmaak_f32 v3, s1, v3, 0x358637bd                         // 0000000008F8: 5A060601 358637BD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000900: BF870121
	v_mul_f32_e32 v21, 0x4f800000, v3                          // 000000000904: 102A06FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v3                     // 00000000090C: 7C2806FF 0F800000
	v_cndmask_b32_e32 v3, v3, v21, vcc_lo                      // 000000000914: 02062B03
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000000918: BF870141
	v_sqrt_f32_e32 v21, v3                                     // 00000000091C: 7E2A6703
	s_waitcnt_depctr 0xfff                                     // 000000000920: BF880FFF
	v_add_nc_u32_e32 v22, -1, v21                              // 000000000924: 4A2C2AC1
	v_add_nc_u32_e32 v23, 1, v21                               // 000000000928: 4A2E2A81
	v_fma_f32 v24, -v22, v21, v3                               // 00000000092C: D6130018 240E2B16
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000934: BF870112
	v_fma_f32 v25, -v23, v21, v3                               // 000000000938: D6130019 240E2B17
	v_cmp_ge_f32_e64 s1, 0, v24                                // 000000000940: D4160001 00023080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000948: BF870191
	v_cndmask_b32_e64 v21, v21, v22, s1                        // 00000000094C: D5010015 00062D15
	v_cmp_lt_f32_e64 s1, 0, v25                                // 000000000954: D4110001 00023280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000095C: BF870091
	v_cndmask_b32_e64 v21, v21, v23, s1                        // 000000000960: D5010015 00062F15
	v_mul_f32_e32 v22, 0x37800000, v21                         // 000000000968: 102C2AFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000970: BF870121
	v_cndmask_b32_e32 v21, v21, v22, vcc_lo                    // 000000000974: 022A2D15
	v_cmp_class_f32_e64 vcc_lo, v3, 0x260                      // 000000000978: D47E006A 0001FF03 00000260
	v_cndmask_b32_e32 v3, v21, v3, vcc_lo                      // 000000000984: 02060715
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000000988: BF870121
	v_div_scale_f32 v21, null, v3, v3, 1.0                     // 00000000098C: D6FC7C15 03CA0703
	v_div_scale_f32 v24, vcc_lo, 1.0, v3, 1.0                  // 000000000994: D6FC6A18 03CA06F2
	v_rcp_f32_e32 v22, v21                                     // 00000000099C: 7E2C5515
	s_waitcnt_depctr 0xfff                                     // 0000000009A0: BF880FFF
	v_fma_f32 v23, -v21, v22, 1.0                              // 0000000009A4: D6130017 23CA2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009AC: BF870091
	v_fmac_f32_e32 v22, v23, v22                               // 0000000009B0: 562C2D17
	v_mul_f32_e32 v23, v24, v22                                // 0000000009B4: 102E2D18
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009B8: BF870091
	v_fma_f32 v25, -v21, v23, v24                              // 0000000009BC: D6130019 24622F15
	v_fmac_f32_e32 v23, v25, v22                               // 0000000009C4: 562E2D19
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000009C8: BF870091
	v_fma_f32 v21, -v21, v23, v24                              // 0000000009CC: D6130015 24622F15
	v_div_fmas_f32 v21, v21, v22, v23                          // 0000000009D4: D6370015 045E2D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000009DC: BF870121
	v_div_fixup_f32 v3, v21, v3, 1.0                           // 0000000009E0: D6270003 03CA0715
	v_lshl_or_b32 v21, v1, 10, v2                              // 0000000009E8: D6560015 04091501
	v_mul_f32_e32 v5, v5, v3                                   // 0000000009F0: 100A0705
	v_mul_f32_e32 v6, v6, v3                                   // 0000000009F4: 100C0706
	v_mul_f32_e32 v7, v7, v3                                   // 0000000009F8: 100E0707
	v_mul_f32_e32 v8, v8, v3                                   // 0000000009FC: 10100708
	v_mul_f32_e32 v9, v9, v3                                   // 000000000A00: 10120709
	v_mul_f32_e32 v10, v10, v3                                 // 000000000A04: 1014070A
	v_mul_f32_e32 v11, v11, v3                                 // 000000000A08: 1016070B
	v_mul_f32_e32 v3, v12, v3                                  // 000000000A0C: 1006070C
	s_waitcnt vmcnt(1)                                         // 000000000A10: BF8907F7
	v_dual_mul_f32 v5, v13, v5 :: v_dual_mul_f32 v6, v14, v6   // 000000000A14: C8C60B0D 05060D0E
	v_dual_mul_f32 v7, v15, v7 :: v_dual_mul_f32 v8, v8, v16   // 000000000A1C: C8C60F0F 07082108
	s_waitcnt vmcnt(0)                                         // 000000000A24: BF8903F7
	v_dual_mul_f32 v9, v9, v17 :: v_dual_mul_f32 v10, v10, v18 // 000000000A28: C8C62309 090A250A
	v_mul_f32_e32 v11, v11, v19                                // 000000000A30: 1016270B
	v_mul_f32_e32 v3, v3, v20                                  // 000000000A34: 10062903
	v_dual_mul_f32 v5, 0x3d800000, v5 :: v_dual_mul_f32 v6, 0x3d800000, v6// 000000000A38: C8C60AFF 05060CFF 3D800000
	v_dual_mul_f32 v7, 0x3d800000, v7 :: v_dual_mul_f32 v8, 0x3d800000, v8// 000000000A44: C8C60EFF 070810FF 3D800000
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000A50: BF870003
	v_dual_mul_f32 v12, 0x3d800000, v3 :: v_dual_mul_f32 v9, 0x3d800000, v9// 000000000A54: C8C606FF 0C0812FF 3D800000
	v_dual_mul_f32 v10, 0x3d800000, v10 :: v_dual_mul_f32 v11, 0x3d800000, v11// 000000000A60: C8C614FF 0A0A16FF 3D800000
	ds_store_b128 v21, v[5:8]                                  // 000000000A6C: DB7C0000 00000515
	ds_store_b128 v21, v[9:12] offset:16                       // 000000000A74: DB7C0010 00000915
	s_or_b32 exec_lo, exec_lo, s8                              // 000000000A7C: 8C7E087E
	s_add_i32 s8, s29, s12                                     // 000000000A80: 81080C1D
	v_and_b32_e32 v6, 31, v0                                   // 000000000A84: 360C009F
	s_ashr_i32 s9, s8, 31                                      // 000000000A88: 86099F08
	s_waitcnt lgkmcnt(0)                                       // 000000000A8C: BF89FC07
	s_lshl_b64 s[6:7], s[8:9], 8                               // 000000000A90: 84868808
	s_barrier                                                  // 000000000A94: BFBD0000
	s_add_u32 s6, s2, s6                                       // 000000000A98: 80060602
	s_addc_u32 s7, s3, s7                                      // 000000000A9C: 82070703
	buffer_gl0_inv                                             // 000000000AA0: E0AC0000 00000000
	s_and_saveexec_b32 s1, s0                                  // 000000000AA8: BE812000
	s_cbranch_execz 25                                         // 000000000AAC: BFA50019 <attn_prep_24_4_256_64_8204_11_k4jv4+0xb14>
	v_lshlrev_b32_e32 v3, 2, v6                                // 000000000AB0: 30060C82
	s_clause 0x1                                               // 000000000AB4: BF850001
	global_load_b32 v5, v3, s[6:7] offset:128                  // 000000000AB8: DC520080 05060003
	global_load_b32 v9, v3, s[6:7]                             // 000000000AC0: DC520000 09060003
	v_lshl_or_b32 v7, v1, 10, v3                               // 000000000AC8: D6560007 040D1501
	ds_load_2addr_b32 v[7:8], v7 offset1:32                    // 000000000AD0: D8DC2000 07000007
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000AD8: BF890407
	v_mul_f32_e32 v10, v5, v8                                  // 000000000ADC: 10141105
	v_mul_f32_e32 v5, v5, v7                                   // 000000000AE0: 100A0F05
	v_lshl_or_b32 v3, v1, 8, v3                                // 000000000AE4: D6560003 040D1101
	s_waitcnt vmcnt(0)                                         // 000000000AEC: BF8903F7
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000AF0: BF870193
	v_fma_f32 v7, v9, v7, -v10                                 // 000000000AF4: D6130007 842A0F09
	v_fmac_f32_e32 v5, v9, v8                                  // 000000000AFC: 560A1109
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000B00: BF870003
	v_add_nc_u32_e32 v3, 0x3800, v3                            // 000000000B04: 4A0606FF 00003800
	ds_store_2addr_b32 v3, v7, v5 offset1:32                   // 000000000B0C: D8382000 00050703
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000B14: 8C7E017E
	v_cmp_gt_u32_e64 s2, 32, v0                                // 000000000B18: D44C0002 000200A0
	v_dual_mov_b32 v5, 0 :: v_dual_mov_b32 v8, 0               // 000000000B20: CA100080 05080080
	v_lshlrev_b32_e32 v3, 2, v0                                // 000000000B28: 30060082
	s_delay_alu instid0(VALU_DEP_3)                            // 000000000B2C: BF870003
	s_and_saveexec_b32 s1, s2                                  // 000000000B30: BE812002
	s_cbranch_execz 17                                         // 000000000B34: BFA50011 <attn_prep_24_4_256_64_8204_11_k4jv4+0xb7c>
	s_clause 0x1                                               // 000000000B38: BF850001
	global_load_b32 v9, v3, s[6:7] offset:128                  // 000000000B3C: DC520080 09060003
	global_load_b32 v10, v3, s[6:7]                            // 000000000B44: DC520000 0A060003
	v_add_nc_u32_e32 v5, 0x3000, v3                            // 000000000B4C: 4A0A06FF 00003000
	ds_load_2addr_b32 v[7:8], v5 offset1:32                    // 000000000B54: D8DC2000 07000005
	s_waitcnt vmcnt(1) lgkmcnt(0)                              // 000000000B5C: BF890407
	v_mul_f32_e32 v11, v9, v8                                  // 000000000B60: 10161109
	s_waitcnt vmcnt(0)                                         // 000000000B64: BF8903F7
	v_mul_f32_e32 v5, v10, v8                                  // 000000000B68: 100A110A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000B6C: BF870112
	v_fma_f32 v8, v10, v7, -v11                                // 000000000B70: D6130008 842E0F0A
	v_fmac_f32_e32 v5, v9, v7                                  // 000000000B78: 560A0F09
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000B7C: 8C7E017E
	v_and_b32_e32 v7, 63, v0                                   // 000000000B80: 360E00BF
	v_or_b32_e32 v13, 0xffffff00, v0                           // 000000000B84: 381A00FF FFFFFF00
	s_mov_b32 s1, exec_lo                                      // 000000000B8C: BE81007E
	s_waitcnt lgkmcnt(0)                                       // 000000000B90: BF89FC07
	s_barrier                                                  // 000000000B94: BFBD0000
	buffer_gl0_inv                                             // 000000000B98: E0AC0000 00000000
	v_cmpx_gt_u32_e32 0x180, v0                                // 000000000BA0: 7D9800FF 00000180
	s_cbranch_execz 30                                         // 000000000BA8: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0xc24>
	v_lshrrev_b32_e32 v10, 6, v0                               // 000000000BAC: 32140086
	v_lshlrev_b32_e32 v11, 2, v7                               // 000000000BB0: 30160E82
	v_or_b32_e32 v9, 0xffffff00, v0                            // 000000000BB4: 381200FF FFFFFF00
	s_mov_b32 s3, 0                                            // 000000000BBC: BE830080
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000BC0: BF870193
	v_lshlrev_b32_e32 v12, 8, v10                              // 000000000BC4: 30181488
	v_lshl_or_b32 v10, v10, 10, v11                            // 000000000BC8: D656000A 042D150A
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000BD0: BF870002
	v_or3_b32 v11, v12, v11, 0x3800                            // 000000000BD4: D658000B 03FE170C 00003800
	ds_load_b32 v12, v11                                       // 000000000BE0: D8D80000 0C00000B
	v_add_nc_u32_e32 v9, 0x100, v9                             // 000000000BE8: 4A1212FF 00000100
	v_add_nc_u32_e32 v11, 0x400, v11                           // 000000000BF0: 4A1616FF 00000400
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000BF8: BF870002
	v_cmp_lt_u32_e32 vcc_lo, 0x7f, v9                          // 000000000BFC: 7C9212FF 0000007F
	s_or_b32 s3, vcc_lo, s3                                    // 000000000C04: 8C03036A
	s_waitcnt lgkmcnt(0)                                       // 000000000C08: BF89FC07
	ds_store_b32 v10, v12                                      // 000000000C0C: D8340000 00000C0A
	v_add_nc_u32_e32 v10, 0x1000, v10                          // 000000000C14: 4A1414FF 00001000
	s_and_not1_b32 exec_lo, exec_lo, s3                        // 000000000C1C: 917E037E
	s_cbranch_execnz 65519                                     // 000000000C20: BFA6FFEF <attn_prep_24_4_256_64_8204_11_k4jv4+0xbe0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000C24: 8C7E017E
	s_and_saveexec_b32 s1, s2                                  // 000000000C28: BE812002
	v_add_nc_u32_e32 v9, 0x3000, v3                            // 000000000C2C: 4A1206FF 00003000
	ds_store_2addr_b32 v9, v8, v5 offset1:32                   // 000000000C34: D8382000 00050809
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000C3C: 8C7E017E
	v_xor_b32_e32 v5, 0x1234567, v0                            // 000000000C40: 3A0A00FF 01234567
	v_xor_b32_e32 v8, 0x7654321, v0                            // 000000000C48: 3A1000FF 07654321
	s_mov_b32 s6, 0                                            // 000000000C50: BE860080
	s_waitcnt lgkmcnt(0)                                       // 000000000C54: BF89FC07
	s_barrier                                                  // 000000000C58: BFBD0000
	v_mul_lo_u32 v5, 0x9e3779b1, v5                            // 000000000C5C: D72C0005 00020AFF 9E3779B1
	v_mul_lo_u32 v8, 0x9e3779b1, v8                            // 000000000C68: D72C0008 000210FF 9E3779B1
	buffer_gl0_inv                                             // 000000000C74: E0AC0000 00000000
	v_bcnt_u32_b32 v5, v5, 0                                   // 000000000C7C: D71E0005 00010105
	v_bcnt_u32_b32 v8, v8, 0                                   // 000000000C84: D71E0008 00010108
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000C8C: BF870112
	v_and_b32_e32 v9, 1, v5                                    // 000000000C90: 36120A81
	v_and_b32_e32 v8, 1, v8                                    // 000000000C94: 36101081
	v_or_b32_e32 v5, 0xffffe800, v3                            // 000000000C98: 380A06FF FFFFE800
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000000CA0: BF870223
	v_cmp_eq_u32_e32 vcc_lo, 0, v9                             // 000000000CA4: 7C941280
	v_mov_b32_e32 v9, v13                                      // 000000000CA8: 7E12030D
	v_cmp_eq_u32_e64 s1, 0, v8                                 // 000000000CAC: D44A0001 00021080
	s_set_inst_prefetch_distance 0x1                           // 000000000CB4: BF840001
	s_branch 15                                                // 000000000CB8: BFA0000F <attn_prep_24_4_256_64_8204_11_k4jv4+0xcf8>
	s_nop 0                                                    // 000000000CBC: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000CC0: 8C7E037E
	v_add_nc_u32_e32 v9, 0x100, v9                             // 000000000CC4: 4A1212FF 00000100
	ds_store_b32 v5, v10 offset:6144                           // 000000000CCC: D8341800 00000A05
	v_add_nc_u32_e32 v5, 0x400, v5                             // 000000000CD4: 4A0A0AFF 00000400
	v_cmp_lt_u32_e64 s3, 0xcff, v9                             // 000000000CDC: D4490003 000212FF 00000CFF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000CE8: BF870491
	s_or_b32 s6, s3, s6                                        // 000000000CEC: 8C060603
	s_and_not1_b32 exec_lo, exec_lo, s6                        // 000000000CF0: 917E067E
	s_cbranch_execz 23                                         // 000000000CF4: BFA50017 <attn_prep_24_4_256_64_8204_11_k4jv4+0xd54>
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000CF8: BF870092
	v_add_nc_u32_e32 v10, 0xfffffb00, v9                       // 000000000CFC: 4A1412FF FFFFFB00
	v_cmp_lt_u32_e64 s3, 0x5ff, v10                            // 000000000D04: D4490003 000214FF 000005FF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000D10: BF870491
	s_and_saveexec_b32 s7, s3                                  // 000000000D14: BE872003
	s_xor_b32 s3, exec_lo, s7                                  // 000000000D18: 8D03077E
	s_cbranch_execz 5                                          // 000000000D1C: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0xd34>
	ds_load_b32 v10, v5 offset:6144                            // 000000000D20: D8D81800 0A000005
	s_waitcnt lgkmcnt(0)                                       // 000000000D28: BF89FC07
	v_cndmask_b32_e64 v10, -v10, v10, vcc_lo                   // 000000000D2C: D501000A 21AA150A
	s_and_not1_saveexec_b32 s3, s3                             // 000000000D34: BE833003
	s_cbranch_execz 65505                                      // 000000000D38: BFA5FFE1 <attn_prep_24_4_256_64_8204_11_k4jv4+0xcc0>
	ds_load_b32 v10, v5                                        // 000000000D3C: D8D80000 0A000005
	s_waitcnt lgkmcnt(0)                                       // 000000000D44: BF89FC07
	v_cndmask_b32_e64 v10, -v10, v10, s1                       // 000000000D48: D501000A 2006150A
	s_branch 65499                                             // 000000000D50: BFA0FFDB <attn_prep_24_4_256_64_8204_11_k4jv4+0xcc0>
	s_set_inst_prefetch_distance 0x2                           // 000000000D54: BF840002
	s_or_b32 exec_lo, exec_lo, s6                              // 000000000D58: 8C7E067E
	v_dual_mov_b32 v10, v13 :: v_dual_lshlrev_b32 v5, 1, v0    // 000000000D5C: CA22010D 0A040081
	s_mov_b32 s1, 0                                            // 000000000D64: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000D68: BF89FC07
	s_barrier                                                  // 000000000D6C: BFBD0000
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000D70: BF870001
	v_mov_b32_e32 v9, v5                                       // 000000000D74: 7E120305
	buffer_gl0_inv                                             // 000000000D78: E0AC0000 00000000
	v_lshlrev_b32_e32 v11, 2, v9                               // 000000000D80: 30161282
	v_add_nc_u32_e32 v10, 0x100, v10                           // 000000000D84: 4A1414FF 00000100
	v_add_nc_u32_e32 v9, 0x200, v9                             // 000000000D8C: 4A1212FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000D94: BF870193
	v_and_b32_e32 v16, 0x3ff8, v11                             // 000000000D98: 362016FF 00003FF8
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v10                        // 000000000DA0: 7C9214FF 000005FF
	ds_load_b64 v[11:12], v16                                  // 000000000DA8: D9D80000 0B000010
	s_or_b32 s1, vcc_lo, s1                                    // 000000000DB0: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000DB4: BF89FC07
	v_sub_f32_e32 v15, v11, v12                                // 000000000DB8: 081E190B
	v_add_f32_e32 v14, v11, v12                                // 000000000DBC: 061C190B
	ds_store_b64 v16, v[14:15]                                 // 000000000DC0: D9340000 00000E10
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000DC8: 917E017E
	s_cbranch_execnz 65516                                     // 000000000DCC: BFA6FFEC <attn_prep_24_4_256_64_8204_11_k4jv4+0xd80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000DD0: 8C7E017E
	v_dual_mov_b32 v10, v5 :: v_dual_and_b32 v9, 1, v0         // 000000000DD4: CA240105 0A080081
	v_mov_b32_e32 v11, v13                                     // 000000000DDC: 7E16030D
	s_mov_b32 s1, 0                                            // 000000000DE0: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000DE4: BF89FC07
	s_barrier                                                  // 000000000DE8: BFBD0000
	buffer_gl0_inv                                             // 000000000DEC: E0AC0000 00000000
	s_nop 0                                                    // 000000000DF4: BF800000
	s_nop 0                                                    // 000000000DF8: BF800000
	s_nop 0                                                    // 000000000DFC: BF800000
	v_and_or_b32 v12, 0xffc, v10, v9                           // 000000000E00: D657000C 042614FF 00000FFC
	v_add_nc_u32_e32 v11, 0x100, v11                           // 000000000E0C: 4A1616FF 00000100
	v_add_nc_u32_e32 v10, 0x200, v10                           // 000000000E14: 4A1414FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000E1C: BF870193
	v_lshlrev_b32_e32 v12, 2, v12                              // 000000000E20: 30181882
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v11                        // 000000000E24: 7C9216FF 000005FF
	ds_load_2addr_b32 v[14:15], v12 offset1:2                  // 000000000E2C: D8DC0200 0E00000C
	s_or_b32 s1, vcc_lo, s1                                    // 000000000E34: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000E38: BF89FC07
	v_add_f32_e32 v16, v14, v15                                // 000000000E3C: 06201F0E
	v_sub_f32_e32 v14, v14, v15                                // 000000000E40: 081C1F0E
	ds_store_2addr_b32 v12, v16, v14 offset1:2                 // 000000000E44: D8380200 000E100C
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000E4C: 917E017E
	s_cbranch_execnz 65515                                     // 000000000E50: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xe00>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000E54: 8C7E017E
	v_dual_mov_b32 v11, v5 :: v_dual_and_b32 v10, 3, v0        // 000000000E58: CA240105 0B0A0083
	v_mov_b32_e32 v12, v13                                     // 000000000E60: 7E18030D
	s_mov_b32 s1, 0                                            // 000000000E64: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000E68: BF89FC07
	s_barrier                                                  // 000000000E6C: BFBD0000
	buffer_gl0_inv                                             // 000000000E70: E0AC0000 00000000
	s_nop 0                                                    // 000000000E78: BF800000
	s_nop 0                                                    // 000000000E7C: BF800000
	v_and_or_b32 v14, 0xff8, v11, v10                          // 000000000E80: D657000E 042A16FF 00000FF8
	v_add_nc_u32_e32 v12, 0x100, v12                           // 000000000E8C: 4A1818FF 00000100
	v_add_nc_u32_e32 v11, 0x200, v11                           // 000000000E94: 4A1616FF 00000200
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000000E9C: BF870193
	v_lshlrev_b32_e32 v16, 2, v14                              // 000000000EA0: 30201C82
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v12                        // 000000000EA4: 7C9218FF 000005FF
	ds_load_2addr_b32 v[14:15], v16 offset1:4                  // 000000000EAC: D8DC0400 0E000010
	s_or_b32 s1, vcc_lo, s1                                    // 000000000EB4: 8C01016A
	s_waitcnt lgkmcnt(0)                                       // 000000000EB8: BF89FC07
	v_add_f32_e32 v17, v14, v15                                // 000000000EBC: 06221F0E
	v_sub_f32_e32 v14, v14, v15                                // 000000000EC0: 081C1F0E
	ds_store_2addr_b32 v16, v17, v14 offset1:4                 // 000000000EC4: D8380400 000E1110
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000ECC: 917E017E
	s_cbranch_execnz 65515                                     // 000000000ED0: BFA6FFEB <attn_prep_24_4_256_64_8204_11_k4jv4+0xe80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000ED4: 8C7E017E
	v_dual_mov_b32 v12, v5 :: v_dual_and_b32 v11, 7, v0        // 000000000ED8: CA240105 0C0A0087
	v_mov_b32_e32 v14, v13                                     // 000000000EE0: 7E1C030D
	s_mov_b32 s1, 0                                            // 000000000EE4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000EE8: BF89FC07
	s_barrier                                                  // 000000000EEC: BFBD0000
	buffer_gl0_inv                                             // 000000000EF0: E0AC0000 00000000
	s_nop 0                                                    // 000000000EF8: BF800000
	s_nop 0                                                    // 000000000EFC: BF800000
	v_and_or_b32 v15, 0xff0, v12, v11                          // 000000000F00: D657000F 042E18FF 00000FF0
	v_add_nc_u32_e32 v12, 0x200, v12                           // 000000000F0C: 4A1818FF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000F14: BF870002
	v_lshlrev_b32_e32 v17, 2, v15                              // 000000000F18: 30221E82
	ds_load_2addr_b32 v[15:16], v17 offset1:8                  // 000000000F1C: D8DC0800 0F000011
	v_add_nc_u32_e32 v14, 0x100, v14                           // 000000000F24: 4A1C1CFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 000000000F2C: BF89FC07
	v_add_f32_e32 v18, v15, v16                                // 000000000F30: 0624210F
	v_sub_f32_e32 v15, v15, v16                                // 000000000F34: 081E210F
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000000F38: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v14                        // 000000000F3C: 7C921CFF 000005FF
	ds_store_2addr_b32 v17, v18, v15 offset1:8                 // 000000000F44: D8380800 000F1211
	s_or_b32 s1, vcc_lo, s1                                    // 000000000F4C: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000F50: 917E017E
	s_cbranch_execnz 65514                                     // 000000000F54: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0xf00>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000F58: 8C7E017E
	v_dual_mov_b32 v15, v13 :: v_dual_and_b32 v12, 15, v0      // 000000000F5C: CA24010D 0F0C008F
	v_mov_b32_e32 v14, v5                                      // 000000000F64: 7E1C0305
	s_mov_b32 s1, 0                                            // 000000000F68: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000F6C: BF89FC07
	s_barrier                                                  // 000000000F70: BFBD0000
	buffer_gl0_inv                                             // 000000000F74: E0AC0000 00000000
	s_nop 0                                                    // 000000000F7C: BF800000
	v_and_or_b32 v16, 0xfe0, v14, v12                          // 000000000F80: D6570010 04321CFF 00000FE0
	v_add_nc_u32_e32 v14, 0x200, v14                           // 000000000F8C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000F94: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000000F98: 30242082
	ds_load_2addr_b32 v[16:17], v18 offset1:16                 // 000000000F9C: D8DC1000 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 000000000FA4: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 000000000FAC: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 000000000FB0: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 000000000FB4: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000000FB8: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 000000000FBC: 7C921EFF 000005FF
	ds_store_2addr_b32 v18, v19, v16 offset1:16                // 000000000FC4: D8381000 00101312
	s_or_b32 s1, vcc_lo, s1                                    // 000000000FCC: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000000FD0: 917E017E
	s_cbranch_execnz 65514                                     // 000000000FD4: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0xf80>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000FD8: 8C7E017E
	v_mov_b32_e32 v14, v5                                      // 000000000FDC: 7E1C0305
	v_mov_b32_e32 v15, v13                                     // 000000000FE0: 7E1E030D
	s_mov_b32 s1, 0                                            // 000000000FE4: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000000FE8: BF89FC07
	s_barrier                                                  // 000000000FEC: BFBD0000
	buffer_gl0_inv                                             // 000000000FF0: E0AC0000 00000000
	s_nop 0                                                    // 000000000FF8: BF800000
	s_nop 0                                                    // 000000000FFC: BF800000
	v_and_or_b32 v16, 0xfc0, v14, v6                           // 000000001000: D6570010 041A1CFF 00000FC0
	v_add_nc_u32_e32 v14, 0x200, v14                           // 00000000100C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001014: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000001018: 30242082
	ds_load_2addr_b32 v[16:17], v18 offset1:32                 // 00000000101C: D8DC2000 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 000000001024: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 00000000102C: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 000000001030: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 000000001034: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000001038: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 00000000103C: 7C921EFF 000005FF
	ds_store_2addr_b32 v18, v19, v16 offset1:32                // 000000001044: D8382000 00101312
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
	v_and_or_b32 v16, 0xf80, v14, v7                           // 000000001080: D6570010 041E1CFF 00000F80
	v_add_nc_u32_e32 v14, 0x200, v14                           // 00000000108C: 4A1C1CFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001094: BF870002
	v_lshlrev_b32_e32 v18, 2, v16                              // 000000001098: 30242082
	ds_load_2addr_stride64_b32 v[16:17], v18 offset1:1         // 00000000109C: D8E00100 10000012
	v_add_nc_u32_e32 v15, 0x100, v15                           // 0000000010A4: 4A1E1EFF 00000100
	s_waitcnt lgkmcnt(0)                                       // 0000000010AC: BF89FC07
	v_add_f32_e32 v19, v16, v17                                // 0000000010B0: 06262310
	v_sub_f32_e32 v16, v16, v17                                // 0000000010B4: 08202310
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 0000000010B8: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v15                        // 0000000010BC: 7C921EFF 000005FF
	ds_store_2addr_stride64_b32 v18, v19, v16 offset1:1        // 0000000010C4: D83C0100 00101312
	s_or_b32 s1, vcc_lo, s1                                    // 0000000010CC: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 0000000010D0: 917E017E
	s_cbranch_execnz 65514                                     // 0000000010D4: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1080>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000010D8: 8C7E017E
	v_dual_mov_b32 v15, v5 :: v_dual_and_b32 v14, 0x7f, v0     // 0000000010DC: CA240105 0F0E00FF 0000007F
	v_mov_b32_e32 v16, v13                                     // 0000000010E8: 7E20030D
	s_mov_b32 s1, 0                                            // 0000000010EC: BE810080
	s_waitcnt lgkmcnt(0)                                       // 0000000010F0: BF89FC07
	s_barrier                                                  // 0000000010F4: BFBD0000
	buffer_gl0_inv                                             // 0000000010F8: E0AC0000 00000000
	v_and_or_b32 v17, 0xf00, v15, v14                          // 000000001100: D6570011 043A1EFF 00000F00
	v_add_nc_u32_e32 v15, 0x200, v15                           // 00000000110C: 4A1E1EFF 00000200
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001114: BF870002
	v_lshlrev_b32_e32 v19, 2, v17                              // 000000001118: 30262282
	ds_load_2addr_stride64_b32 v[17:18], v19 offset1:2         // 00000000111C: D8E00200 11000013
	v_add_nc_u32_e32 v16, 0x100, v16                           // 000000001124: 4A2020FF 00000100
	s_waitcnt lgkmcnt(0)                                       // 00000000112C: BF89FC07
	v_add_f32_e32 v20, v17, v18                                // 000000001130: 06282511
	v_sub_f32_e32 v17, v17, v18                                // 000000001134: 08222511
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000001138: BF8704B3
	v_cmp_lt_u32_e32 vcc_lo, 0x5ff, v16                        // 00000000113C: 7C9220FF 000005FF
	ds_store_2addr_stride64_b32 v19, v20, v17 offset1:2        // 000000001144: D83C0200 00111413
	s_or_b32 s1, vcc_lo, s1                                    // 00000000114C: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 000000001150: 917E017E
	s_cbranch_execnz 65514                                     // 000000001154: BFA6FFEA <attn_prep_24_4_256_64_8204_11_k4jv4+0x1100>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000001158: 8C7E017E
	v_mov_b32_e32 v14, v3                                      // 00000000115C: 7E1C0303
	s_mov_b32 s1, 0                                            // 000000001160: BE810080
	s_waitcnt lgkmcnt(0)                                       // 000000001164: BF89FC07
	s_barrier                                                  // 000000001168: BFBD0000
	buffer_gl0_inv                                             // 00000000116C: E0AC0000 00000000
	s_branch 13                                                // 000000001174: BFA0000D <attn_prep_24_4_256_64_8204_11_k4jv4+0x11ac>
	s_nop 0                                                    // 000000001178: BF800000
	s_nop 0                                                    // 00000000117C: BF800000
	s_or_b32 exec_lo, exec_lo, s3                              // 000000001180: 8C7E037E
	v_add_nc_u32_e32 v13, 0x100, v13                           // 000000001184: 4A1A1AFF 00000100
	v_add_nc_u32_e32 v14, 0x400, v14                           // 00000000118C: 4A1C1CFF 00000400
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001194: BF8704A2
	v_cmp_lt_u32_e32 vcc_lo, 0xcff, v13                        // 000000001198: 7C921AFF 00000CFF
	s_or_b32 s1, vcc_lo, s1                                    // 0000000011A0: 8C01016A
	s_and_not1_b32 exec_lo, exec_lo, s1                        // 0000000011A4: 917E017E
	s_cbranch_execz 15                                         // 0000000011A8: BFA5000F <attn_prep_24_4_256_64_8204_11_k4jv4+0x11e8>
	v_add_nc_u32_e32 v15, 0xfffff500, v13                      // 0000000011AC: 4A1E1AFF FFFFF500
	s_mov_b32 s3, exec_lo                                      // 0000000011B4: BE83007E
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000011B8: BF870001
	v_cmpx_gt_u32_e32 0xfffffa00, v15                          // 0000000011BC: 7D981EFF FFFFFA00
	s_cbranch_execz 65518                                      // 0000000011C4: BFA5FFEE <attn_prep_24_4_256_64_8204_11_k4jv4+0x1180>
	ds_load_b32 v15, v14                                       // 0000000011C8: D8D80000 0F00000E
	s_waitcnt lgkmcnt(0)                                       // 0000000011D0: BF89FC07
	v_mul_f32_e32 v15, 0x3d800000, v15                         // 0000000011D4: 101E1EFF 3D800000
	ds_store_b32 v14, v15                                      // 0000000011DC: D8340000 00000F0E
	s_branch 65510                                             // 0000000011E4: BFA0FFE6 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1180>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000011E8: 8C7E017E
	s_waitcnt lgkmcnt(0)                                       // 0000000011EC: BF89FC07
	s_barrier                                                  // 0000000011F0: BFBD0000
	buffer_gl0_inv                                             // 0000000011F4: E0AC0000 00000000
	ds_load_b32 v13, v3 offset:12288                           // 0000000011FC: D8D83000 0D000003
	v_cmp_eq_u32_e64 s1, 0, v4                                 // 000000001204: D44A0001 00020880
	s_waitcnt lgkmcnt(0)                                       // 00000000120C: BF89FC07
	v_mul_f32_e32 v14, v13, v13                                // 000000001210: 101C1B0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001214: BF870091
	v_mov_b32_dpp v14, v14 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001218: 7E1C02FA FF09110E
	v_fmac_f32_e32 v14, v13, v13                               // 000000001220: 561C1B0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001224: BF870091
	v_add_f32_dpp v13, v14, v14 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001228: 061A1CFA FF09120E
	v_add_f32_dpp v13, v13, v13 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001230: 061A1AFA FF09140D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001238: BF870091
	v_add_f32_dpp v13, v13, v13 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000123C: 061A1AFA FF09180D
	v_readlane_b32 s3, v13, 15                                 // 000000001244: D7600003 00011F0D
	v_readlane_b32 s7, v13, 31                                 // 00000000124C: D7600007 00013F0D
	v_lshlrev_b32_e32 v13, 2, v1                               // 000000001254: 301A0282
	s_and_saveexec_b32 s6, s1                                  // 000000001258: BE862001
	s_delay_alu instid0(VALU_DEP_2)                            // 00000000125C: BF870002
	v_add_f32_e64 v14, s3, s7                                  // 000000001260: D503000E 00000E03
	ds_store_b32 v13, v14 offset:18048                         // 000000001268: D8344680 00000E0D
	s_or_b32 exec_lo, exec_lo, s6                              // 000000001270: 8C7E067E
	v_mov_b32_e32 v30, 0                                       // 000000001274: 7E3C0280
	s_waitcnt lgkmcnt(0)                                       // 000000001278: BF89FC07
	s_barrier                                                  // 00000000127C: BFBD0000
	buffer_gl0_inv                                             // 000000001280: E0AC0000 00000000
	s_mul_i32 s6, s28, 0x258e10                                // 000000001288: 9606FF1C 00258E10
	ds_load_b128 v[14:17], v30 offset:18048                    // 000000001290: DBFC4680 0E00001E
	ds_load_b128 v[18:21], v30 offset:18064                    // 000000001298: DBFC4690 1200001E
	ds_load_b128 v[22:25], v30 offset:17968                    // 0000000012A0: DBFC4630 1600001E
	s_add_u32 s10, s4, s6                                      // 0000000012A8: 800A0604
	s_addc_u32 s11, s5, 0                                      // 0000000012AC: 820B8005
	s_waitcnt lgkmcnt(2)                                       // 0000000012B0: BF89FC27
	v_add_f32_e32 v14, v14, v15                                // 0000000012B4: 061C1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012B8: BF870091
	v_add_f32_e32 v14, v16, v14                                // 0000000012BC: 061C1D10
	v_add_f32_e32 v14, v17, v14                                // 0000000012C0: 061C1D11
	s_waitcnt lgkmcnt(1)                                       // 0000000012C4: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012C8: BF870091
	v_add_f32_e32 v14, v18, v14                                // 0000000012CC: 061C1D12
	v_add_f32_e32 v14, v19, v14                                // 0000000012D0: 061C1D13
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000012D4: BF870091
	v_add_f32_e32 v14, v20, v14                                // 0000000012D8: 061C1D14
	v_add_f32_e32 v14, v21, v14                                // 0000000012DC: 061C1D15
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000012E0: BF870121
	v_mul_f32_e32 v15, 0x4f800000, v14                         // 0000000012E4: 101E1CFF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v14                    // 0000000012EC: 7C281CFF 0F800000
	v_cndmask_b32_e32 v15, v14, v15, vcc_lo                    // 0000000012F4: 021E1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 0000000012F8: BF870141
	v_sqrt_f32_e32 v16, v15                                    // 0000000012FC: 7E20670F
	s_waitcnt_depctr 0xfff                                     // 000000001300: BF880FFF
	v_add_nc_u32_e32 v18, 1, v16                               // 000000001304: 4A242081
	v_add_nc_u32_e32 v17, -1, v16                              // 000000001308: 4A2220C1
	v_fma_f32 v20, -v18, v16, v15                              // 00000000130C: D6130014 243E2112
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001314: BF870092
	v_fma_f32 v19, -v17, v16, v15                              // 000000001318: D6130013 243E2111
	v_cmp_ge_f32_e64 s3, 0, v19                                // 000000001320: D4160003 00022680
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001328: BF870211
	v_cndmask_b32_e64 v16, v16, v17, s3                        // 00000000132C: D5010010 000E2310
	v_cmp_lt_f32_e64 s3, 0, v20                                // 000000001334: D4110003 00022880
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000133C: BF870121
	v_cndmask_b32_e64 v16, v16, v18, s3                        // 000000001340: D5010010 000E2510
	v_cmp_eq_u32_e64 s3, 0, v0                                 // 000000001348: D44A0003 00020080
	v_mul_f32_e32 v17, 0x37800000, v16                         // 000000001350: 102220FF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001358: BF870121
	v_cndmask_b32_e32 v16, v16, v17, vcc_lo                    // 00000000135C: 02202310
	v_cmp_class_f32_e64 vcc_lo, v15, 0x260                     // 000000001360: D47E006A 0001FF0F 00000260
	v_cndmask_b32_e32 v15, v16, v15, vcc_lo                    // 00000000136C: 021E1F10
	ds_load_b128 v[16:19], v30 offset:17920                    // 000000001370: DBFC4600 1000001E
	ds_load_b128 v[26:29], v30 offset:17936                    // 000000001378: DBFC4610 1A00001E
	ds_load_b128 v[30:33], v30 offset:17952                    // 000000001380: DBFC4620 1E00001E
	ds_load_b32 v36, v3 offset:12288                           // 000000001388: D8D83000 24000003
	v_div_scale_f32 v20, null, v15, v15, 0x41800000            // 000000001390: D6FC7C14 03FE1F0F 41800000
	v_div_scale_f32 v35, vcc_lo, 0x41800000, v15, 0x41800000   // 00000000139C: D6FC6A23 03FE1EFF 41800000
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000013A8: BF870002
	v_rcp_f32_e32 v21, v20                                     // 0000000013AC: 7E2A5514
	s_waitcnt lgkmcnt(3)                                       // 0000000013B0: BF89FC37
	v_add_f32_e32 v16, v17, v16                                // 0000000013B4: 06202111
	s_waitcnt_depctr 0xfff                                     // 0000000013B8: BF880FFF
	v_fma_f32 v34, -v20, v21, 1.0                              // 0000000013BC: D6130022 23CA2B14
	v_add_f32_e32 v17, v17, v18                                // 0000000013C4: 06222511
	v_add_f32_e32 v18, v19, v18                                // 0000000013C8: 06242513
	s_waitcnt lgkmcnt(2)                                       // 0000000013CC: BF89FC27
	v_add_f32_e32 v19, v19, v26                                // 0000000013D0: 06263513
	v_dual_add_f32 v26, v27, v26 :: v_dual_fmac_f32 v21, v34, v21// 0000000013D4: C900351B 1A142B22
	v_mul_f32_e32 v17, 0.5, v17                                // 0000000013DC: 102222F0
	v_add_f32_e32 v27, v27, v28                                // 0000000013E0: 0636391B
	s_delay_alu instid0(VALU_DEP_4)                            // 0000000013E4: BF870004
	v_dual_add_f32 v28, v29, v28 :: v_dual_mul_f32 v19, 0.5, v19// 0000000013E8: C906391D 1C1226F0
	s_waitcnt lgkmcnt(1)                                       // 0000000013F0: BF89FC17
	v_dual_mul_f32 v34, v35, v21 :: v_dual_add_f32 v29, v29, v30// 0000000013F4: C8C82B23 221C3D1D
	v_add_f32_e32 v30, v31, v30                                // 0000000013FC: 063C3D1F
	v_add_f32_e32 v31, v31, v32                                // 000000001400: 063E411F
	v_add_f32_e32 v32, v33, v32                                // 000000001404: 06404121
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000001408: BF8701B4
	v_fma_f32 v37, -v20, v34, v35                              // 00000000140C: D6130025 248E4514
	v_dual_add_f32 v33, v33, v22 :: v_dual_mul_f32 v16, 0.5, v16// 000000001414: C9062D21 211020F0
	v_add_f32_e32 v22, v23, v22                                // 00000000141C: 062C2D17
	v_fmac_f32_e32 v34, v37, v21                               // 000000001420: 56442B25
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001424: BF870091
	v_fma_f32 v20, -v20, v34, v35                              // 000000001428: D6130014 248E4514
	v_div_fmas_f32 v20, v20, v21, v34                          // 000000001430: D6370014 048A2B14
	v_add_f32_e32 v21, v23, v24                                // 000000001438: 062A3117
	v_cmp_lt_f32_e32 vcc_lo, 0, v14                            // 00000000143C: 7C221C80
	v_add_f32_e32 v23, v25, v24                                // 000000001440: 062E3119
	v_mul_f32_e32 v25, 0.5, v28                                // 000000001444: 103238F0
	v_div_fixup_f32 v20, v20, v15, 0x41800000                  // 000000001448: D6270014 03FE1F14 41800000
	v_mul_f32_e32 v18, 0.5, v18                                // 000000001454: 102424F0
	v_mul_f32_e32 v24, 0.5, v26                                // 000000001458: 103034F0
	v_dual_mul_f32 v26, 0.5, v29 :: v_dual_mul_f32 v29, 0.5, v31// 00000000145C: C8C63AF0 1A1C3EF0
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 000000001464: BF8701C4
	v_cndmask_b32_e32 v14, 0, v20, vcc_lo                      // 000000001468: 021C2880
	v_dual_mul_f32 v20, 0.5, v27 :: v_dual_mul_f32 v27, 0.5, v30// 00000000146C: C8C636F0 141A3CF0
	v_dual_mul_f32 v31, 0.5, v33 :: v_dual_mul_f32 v30, 0.5, v32// 000000001474: C8C642F0 1F1E40F0
	s_waitcnt lgkmcnt(0)                                       // 00000000147C: BF89FC07
	v_mul_f32_e32 v28, v36, v14                                // 000000001480: 10381D24
	v_mul_f32_e32 v22, 0.5, v22                                // 000000001484: 102C2CF0
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001488: BF870002
	v_cmp_gt_f32_e32 vcc_lo, v28, v16                          // 00000000148C: 7C28211C
	v_cndmask_b32_e64 v16, 0, 1, vcc_lo                        // 000000001490: D5010010 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v17                          // 000000001498: 7C28231C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 00000000149C: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v19                          // 0000000014A4: 7C28271C
	v_cndmask_b32_e64 v19, 0, 1, vcc_lo                        // 0000000014A8: D5010013 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v18                          // 0000000014B0: 7C28251C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 0000000014B4: BF870244
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 0000000014B8: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v20                          // 0000000014BC: 7C28291C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 0000000014C0: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v24                          // 0000000014C8: 7C28311C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v19, vcc_lo          // 0000000014CC: 40202710
	v_cmp_gt_f32_e32 vcc_lo, v28, v26                          // 0000000014D0: 7C28351C
	v_mul_f32_e32 v19, 0.5, v23                                // 0000000014D4: 10262EF0
	v_cndmask_b32_e64 v18, 0, 1, vcc_lo                        // 0000000014D8: D5010012 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v25                          // 0000000014E0: 7C28331C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 0000000014E4: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v29                          // 0000000014E8: 7C283B1C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 0000000014EC: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v27                          // 0000000014F4: 7C28371C
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 0000000014F8: BF870244
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v18, vcc_lo          // 0000000014FC: 40202510
	v_cmp_gt_f32_e32 vcc_lo, v28, v31                          // 000000001500: 7C283F1C
	v_cndmask_b32_e64 v18, 0, 1, vcc_lo                        // 000000001504: D5010012 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v30                          // 00000000150C: 7C283D1C
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 000000001510: 40202310
	v_cmp_gt_f32_e32 vcc_lo, v28, v22                          // 000000001514: 7C282D1C
	v_mul_f32_e32 v17, 0.5, v21                                // 000000001518: 10222AF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000151C: BF870113
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v18, vcc_lo          // 000000001520: 40202510
	v_cmp_gt_f32_e32 vcc_lo, v28, v17                          // 000000001524: 7C28231C
	v_cndmask_b32_e64 v17, 0, 1, vcc_lo                        // 000000001528: D5010011 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v28, v19                          // 000000001530: 7C28271C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001534: BF870092
	v_add_co_ci_u32_e32 v16, vcc_lo, v16, v17, vcc_lo          // 000000001538: 40202310
	v_lshlrev_b32_e32 v17, 2, v16                              // 00000000153C: 30222082
	ds_load_b32 v17, v17 offset:17920                          // 000000001540: D8D84600 11000011
	s_waitcnt lgkmcnt(0)                                       // 000000001548: BF89FC07
	v_fma_f32 v14, v36, v14, -v17                              // 00000000154C: D613000E 84461D24
	ds_store_2addr_stride64_b32 v3, v14, v16 offset0:62 offset1:66// 000000001554: D83C423E 00100E03
	s_and_saveexec_b32 s4, s3                                  // 00000000155C: BE842003
	s_cbranch_execz 12                                         // 000000001560: BFA5000C <attn_prep_24_4_256_64_8204_11_k4jv4+0x1594>
	s_lshl_b32 s6, s8, 1                                       // 000000001564: 84068108
	v_mul_f32_e32 v14, 0x3d800000, v15                         // 000000001568: 101C1EFF 3D800000
	s_ashr_i32 s7, s6, 31                                      // 000000001570: 86079F06
	v_mov_b32_e32 v16, 0x140000                                // 000000001574: 7E2002FF 00140000
	s_lshl_b64 s[6:7], s[6:7], 2                               // 00000000157C: 84868206
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001580: BF870009
	s_add_u32 s6, s10, s6                                      // 000000001584: 8006060A
	s_addc_u32 s7, s11, s7                                     // 000000001588: 8207070B
	global_store_b32 v16, v14, s[6:7] offset:1920              // 00000000158C: DC6A0780 00060E10
	s_or_b32 exec_lo, exec_lo, s4                              // 000000001594: 8C7E047E
	v_add_nc_u32_e32 v16, 0x3e00, v3                           // 000000001598: 4A2006FF 00003E00
	v_add_nc_u32_e32 v14, 0x4200, v3                           // 0000000015A0: 4A1C06FF 00004200
	v_cmp_gt_u32_e64 s4, 0x80, v0                              // 0000000015A8: D44C0004 000200FF 00000080
	s_waitcnt lgkmcnt(0)                                       // 0000000015B4: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 0000000015B8: BC7C0000
	s_barrier                                                  // 0000000015BC: BFBD0000
	buffer_gl0_inv                                             // 0000000015C0: E0AC0000 00000000
	s_and_saveexec_b32 s5, s4                                  // 0000000015C8: BE852004
	s_cbranch_execz 16                                         // 0000000015CC: BFA50010 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1610>
	v_lshl_add_u32 v17, v0, 2, v14                             // 0000000015D0: D6460011 04390500
	s_lshl_b64 s[6:7], s[8:9], 7                               // 0000000015D8: 84868708
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000015DC: BF870009
	v_or_b32_e32 v19, s6, v0                                   // 0000000015E0: 38260006
	v_mov_b32_e32 v20, s7                                      // 0000000015E4: 7E280207
	ds_load_b64 v[17:18], v17                                  // 0000000015E8: D9D80000 11000011
	s_waitcnt lgkmcnt(0)                                       // 0000000015F0: BF89FC07
	v_lshl_or_b32 v21, v18, 4, v17                             // 0000000015F4: D6560015 04450912
	v_add_co_u32 v17, vcc_lo, s10, v19                         // 0000000015FC: D7006A11 0002260A
	v_add_co_ci_u32_e32 v18, vcc_lo, s11, v20, vcc_lo          // 000000001604: 4024280B
	global_store_b8 v[17:18], v21, off                         // 000000001608: DC620000 007C1511
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001610: 8C7E057E
	ds_load_b32 v17, v16                                       // 000000001614: D8D80000 11000010
	s_waitcnt lgkmcnt(0)                                       // 00000000161C: BF89FC07
	v_mul_f32_e32 v18, v17, v17                                // 000000001620: 10242311
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001624: BF870091
	v_mov_b32_dpp v18, v18 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001628: 7E2402FA FF091112
	v_fmac_f32_e32 v18, v17, v17                               // 000000001630: 56242311
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001634: BF870091
	v_add_f32_dpp v17, v18, v18 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001638: 062224FA FF091212
	v_add_f32_dpp v17, v17, v17 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001640: 062222FA FF091411
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001648: BF870091
	v_add_f32_dpp v17, v17, v17 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000164C: 062222FA FF091811
	v_readlane_b32 s6, v17, 15                                 // 000000001654: D7600006 00011F11
	v_readlane_b32 s7, v17, 31                                 // 00000000165C: D7600007 00013F11
	s_and_saveexec_b32 s5, s1                                  // 000000001664: BE852001
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001668: BF870001
	v_add_f32_e64 v17, s6, s7                                  // 00000000166C: D5030011 00000E06
	ds_store_b32 v13, v17 offset:18048                         // 000000001674: D8344680 0000110D
	s_or_b32 exec_lo, exec_lo, s5                              // 00000000167C: 8C7E057E
	v_mov_b32_e32 v21, 0                                       // 000000001680: 7E2A0280
	s_waitcnt lgkmcnt(0)                                       // 000000001684: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001688: BC7C0000
	s_barrier                                                  // 00000000168C: BFBD0000
	buffer_gl0_inv                                             // 000000001690: E0AC0000 00000000
	v_cmp_eq_u32_e64 s5, 0, v8                                 // 000000001698: D44A0005 00021080
	ds_load_b128 v[17:20], v21 offset:18048                    // 0000000016A0: DBFC4680 11000015
	ds_load_b128 v[21:24], v21 offset:18064                    // 0000000016A8: DBFC4690 15000015
	ds_load_b32 v25, v16                                       // 0000000016B0: D8D80000 19000010
	s_waitcnt lgkmcnt(2)                                       // 0000000016B8: BF89FC27
	v_add_f32_e32 v17, v17, v18                                // 0000000016BC: 06222511
	s_waitcnt lgkmcnt(0)                                       // 0000000016C0: BF89FC07
	v_cndmask_b32_e64 v8, -v25, v25, s5                        // 0000000016C4: D5010008 20163319
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000016CC: BF870002
	v_add_f32_e32 v17, v17, v19                                // 0000000016D0: 06222711
	ds_store_b32 v16, v8                                       // 0000000016D4: D8340000 00000810
	s_waitcnt lgkmcnt(0)                                       // 0000000016DC: BF89FC07
	s_barrier                                                  // 0000000016E0: BFBD0000
	v_add_f32_e32 v17, v17, v20                                // 0000000016E4: 06222911
	buffer_gl0_inv                                             // 0000000016E8: E0AC0000 00000000
	v_add_f32_e32 v17, v17, v21                                // 0000000016F0: 06222B11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000016F4: BF870091
	v_add_f32_e32 v17, v17, v22                                // 0000000016F8: 06222D11
	v_add_f32_e32 v17, v17, v23                                // 0000000016FC: 06222F11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001700: BF870091
	v_add_f32_e32 v17, v17, v24                                // 000000001704: 06223111
	v_mul_f32_e32 v18, 0x4f800000, v17                         // 000000001708: 102422FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v17                    // 000000001710: 7C2822FF 0F800000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001718: BF870092
	v_cndmask_b32_e32 v17, v17, v18, vcc_lo                    // 00000000171C: 02222511
	v_sqrt_f32_e32 v18, v17                                    // 000000001720: 7E246711
	s_waitcnt_depctr 0xfff                                     // 000000001724: BF880FFF
	v_add_nc_u32_e32 v20, -1, v18                              // 000000001728: 4A2824C1
	v_add_nc_u32_e32 v19, 1, v18                               // 00000000172C: 4A262481
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001730: BF870112
	v_fma_f32 v21, -v20, v18, v17                              // 000000001734: D6130015 24462514
	v_fma_f32 v22, -v19, v18, v17                              // 00000000173C: D6130016 24462513
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001744: BF870112
	v_cmp_ge_f32_e64 s5, 0, v21                                // 000000001748: D4160005 00022A80
	v_cmp_lt_f32_e64 s6, 0, v22                                // 000000001750: D4110006 00022C80
	s_and_saveexec_b32 s7, s4                                  // 000000001758: BE872004
	s_cbranch_execz 9                                          // 00000000175C: BFA50009 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1784>
	v_lshl_add_u32 v8, v0, 2, v16                              // 000000001760: D6460008 04410500
	ds_load_b64 v[21:22], v8                                   // 000000001768: D9D80000 15000008
	s_waitcnt lgkmcnt(0)                                       // 000000001770: BF89FC07
	v_add_f32_e32 v23, v21, v22                                // 000000001774: 062E2D15
	v_sub_f32_e32 v24, v21, v22                                // 000000001778: 08302D15
	ds_store_b64 v8, v[23:24]                                  // 00000000177C: D9340000 00001708
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001784: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001788: BF89FC07
	s_barrier                                                  // 00000000178C: BFBD0000
	buffer_gl0_inv                                             // 000000001790: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001798: BE872004
	s_cbranch_execz 14                                         // 00000000179C: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x17d8>
	v_and_or_b32 v8, 0xfc, v5, v9                              // 0000000017A0: D6570008 04260AFF 000000FC
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000017AC: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 0000000017B0: 30101082
	v_add_nc_u32_e32 v21, 0x3c00, v8                           // 0000000017B4: 4A2A10FF 00003C00
	ds_load_2addr_b32 v[8:9], v21 offset0:128 offset1:130      // 0000000017BC: D8DC8280 08000015
	s_waitcnt lgkmcnt(0)                                       // 0000000017C4: BF89FC07
	v_add_f32_e32 v22, v8, v9                                  // 0000000017C8: 062C1308
	v_sub_f32_e32 v8, v8, v9                                   // 0000000017CC: 08101308
	ds_store_2addr_b32 v21, v22, v8 offset0:128 offset1:130    // 0000000017D0: D8388280 00081615
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000017D8: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000017DC: BF89FC07
	s_barrier                                                  // 0000000017E0: BFBD0000
	buffer_gl0_inv                                             // 0000000017E4: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000017EC: BE872004
	s_cbranch_execz 14                                         // 0000000017F0: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x182c>
	v_and_or_b32 v8, 0xf8, v5, v10                             // 0000000017F4: D6570008 042A0AFF 000000F8
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001800: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 000000001804: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 000000001808: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:132      // 000000001810: D8DC8480 0800000A
	s_waitcnt lgkmcnt(0)                                       // 000000001818: BF89FC07
	v_add_f32_e32 v21, v8, v9                                  // 00000000181C: 062A1308
	v_sub_f32_e32 v8, v8, v9                                   // 000000001820: 08101308
	ds_store_2addr_b32 v10, v21, v8 offset0:128 offset1:132    // 000000001824: D8388480 0008150A
	s_or_b32 exec_lo, exec_lo, s7                              // 00000000182C: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001830: BF89FC07
	s_barrier                                                  // 000000001834: BFBD0000
	buffer_gl0_inv                                             // 000000001838: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001840: BE872004
	s_cbranch_execz 14                                         // 000000001844: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1880>
	v_and_or_b32 v8, 0xf0, v5, v11                             // 000000001848: D6570008 042E0AFF 000000F0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001854: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 000000001858: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 00000000185C: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:136      // 000000001864: D8DC8880 0800000A
	s_waitcnt lgkmcnt(0)                                       // 00000000186C: BF89FC07
	v_add_f32_e32 v11, v8, v9                                  // 000000001870: 06161308
	v_sub_f32_e32 v8, v8, v9                                   // 000000001874: 08101308
	ds_store_2addr_b32 v10, v11, v8 offset0:128 offset1:136    // 000000001878: D8388880 00080B0A
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001880: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001884: BF89FC07
	s_barrier                                                  // 000000001888: BFBD0000
	buffer_gl0_inv                                             // 00000000188C: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001894: BE872004
	s_cbranch_execz 14                                         // 000000001898: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x18d4>
	v_and_or_b32 v8, 0xe0, v5, v12                             // 00000000189C: D6570008 04320AFF 000000E0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000018A8: BF870091
	v_lshlrev_b32_e32 v8, 2, v8                                // 0000000018AC: 30101082
	v_add_nc_u32_e32 v10, 0x3c00, v8                           // 0000000018B0: 4A1410FF 00003C00
	ds_load_2addr_b32 v[8:9], v10 offset0:128 offset1:144      // 0000000018B8: D8DC9080 0800000A
	s_waitcnt lgkmcnt(0)                                       // 0000000018C0: BF89FC07
	v_add_f32_e32 v11, v8, v9                                  // 0000000018C4: 06161308
	v_sub_f32_e32 v8, v8, v9                                   // 0000000018C8: 08101308
	ds_store_2addr_b32 v10, v11, v8 offset0:128 offset1:144    // 0000000018CC: D8389080 00080B0A
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000018D4: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000018D8: BF89FC07
	s_barrier                                                  // 0000000018DC: BFBD0000
	buffer_gl0_inv                                             // 0000000018E0: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 0000000018E8: BE872004
	s_cbranch_execz 14                                         // 0000000018EC: BFA5000E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1928>
	v_and_or_b32 v6, 0xc0, v5, v6                              // 0000000018F0: D6570006 041A0AFF 000000C0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000018FC: BF870091
	v_lshlrev_b32_e32 v6, 2, v6                                // 000000001900: 300C0C82
	v_add_nc_u32_e32 v6, 0x3c00, v6                            // 000000001904: 4A0C0CFF 00003C00
	ds_load_2addr_b32 v[8:9], v6 offset0:128 offset1:160       // 00000000190C: D8DCA080 08000006
	s_waitcnt lgkmcnt(0)                                       // 000000001914: BF89FC07
	v_add_f32_e32 v10, v8, v9                                  // 000000001918: 06141308
	v_sub_f32_e32 v8, v8, v9                                   // 00000000191C: 08101308
	ds_store_2addr_b32 v6, v10, v8 offset0:128 offset1:160     // 000000001920: D838A080 00080A06
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001928: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 00000000192C: BF89FC07
	s_barrier                                                  // 000000001930: BFBD0000
	buffer_gl0_inv                                             // 000000001934: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 00000000193C: BE872004
	s_cbranch_execz 12                                         // 000000001940: BFA5000C <attn_prep_24_4_256_64_8204_11_k4jv4+0x1974>
	v_and_or_b32 v6, 0x80, v5, v7                              // 000000001944: D6570006 041E0AFF 00000080
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001950: BF870001
	v_lshlrev_b32_e32 v8, 2, v6                                // 000000001954: 30100C82
	ds_load_2addr_stride64_b32 v[6:7], v8 offset0:62 offset1:63// 000000001958: D8E03F3E 06000008
	s_waitcnt lgkmcnt(0)                                       // 000000001960: BF89FC07
	v_add_f32_e32 v9, v6, v7                                   // 000000001964: 06120F06
	v_sub_f32_e32 v6, v6, v7                                   // 000000001968: 080C0F06
	ds_store_2addr_stride64_b32 v8, v9, v6 offset0:62 offset1:63// 00000000196C: D83C3F3E 00060908
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001974: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 000000001978: BF89FC07
	s_barrier                                                  // 00000000197C: BFBD0000
	buffer_gl0_inv                                             // 000000001980: E0AC0000 00000000
	s_and_saveexec_b32 s7, s4                                  // 000000001988: BE872004
	s_cbranch_execz 7                                          // 00000000198C: BFA50007 <attn_prep_24_4_256_64_8204_11_k4jv4+0x19ac>
	ds_load_2addr_stride64_b32 v[6:7], v16 offset1:2           // 000000001990: D8E00200 06000010
	s_waitcnt lgkmcnt(0)                                       // 000000001998: BF89FC07
	v_add_f32_e32 v8, v6, v7                                   // 00000000199C: 06100F06
	v_sub_f32_e32 v6, v6, v7                                   // 0000000019A0: 080C0F06
	ds_store_2addr_stride64_b32 v16, v8, v6 offset1:2          // 0000000019A4: D83C0200 00060810
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000019AC: 8C7E077E
	s_waitcnt lgkmcnt(0)                                       // 0000000019B0: BF89FC07
	s_barrier                                                  // 0000000019B4: BFBD0000
	buffer_gl0_inv                                             // 0000000019B8: E0AC0000 00000000
	ds_load_b32 v6, v16                                        // 0000000019C0: D8D80000 06000010
	s_waitcnt lgkmcnt(0)                                       // 0000000019C8: BF89FC07
	v_cmp_le_f32_e64 s7, 0, v6                                 // 0000000019CC: D4130007 00020C80
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000019D4: BF870001
	v_cndmask_b32_e64 v6, 0, 1, s7                             // 0000000019D8: D5010006 001D0280
	ds_store_b32 v14, v6                                       // 0000000019E0: D8340000 0000060E
	s_waitcnt lgkmcnt(0)                                       // 0000000019E8: BF89FC07
	s_barrier                                                  // 0000000019EC: BFBD0000
	buffer_gl0_inv                                             // 0000000019F0: E0AC0000 00000000
	s_and_saveexec_b32 s7, s2                                  // 0000000019F8: BE872002
	s_cbranch_execz 51                                         // 0000000019FC: BFA50033 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1acc>
	v_lshlrev_b32_e32 v10, 5, v0                               // 000000001A00: 30140085
	s_lshl_b64 s[14:15], s[8:9], 5                             // 000000001A04: 848E8508
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001A08: BF8700A9
	s_add_u32 s2, s14, 0x100600                                // 000000001A0C: 8002FF0E 00100600
	s_addc_u32 s13, s15, 0                                     // 000000001A14: 820D800F
	v_add_nc_u32_e32 v6, 0x420c, v10                           // 000000001A18: 4A0C14FF 0000420C
	v_add_nc_u32_e32 v8, 0x4204, v10                           // 000000001A20: 4A1014FF 00004204
	v_add_nc_u32_e32 v11, 0x4214, v10                          // 000000001A28: 4A1614FF 00004214
	v_add_nc_u32_e32 v12, 0x4000, v10                          // 000000001A30: 4A1814FF 00004000
	ds_load_2addr_b32 v[6:7], v6 offset1:1                     // 000000001A38: D8DC0100 06000006
	ds_load_2addr_b32 v[8:9], v8 offset1:1                     // 000000001A40: D8DC0100 08000008
	ds_load_2addr_b32 v[10:11], v11 offset1:1                  // 000000001A48: D8DC0100 0A00000B
	ds_load_2addr_b32 v[21:22], v12 offset0:128 offset1:135    // 000000001A50: D8DC8780 1500000C
	s_waitcnt lgkmcnt(3)                                       // 000000001A58: BF89FC37
	v_lshlrev_b32_e32 v7, 4, v7                                // 000000001A5C: 300E0E84
	v_lshlrev_b32_e32 v6, 3, v6                                // 000000001A60: 300C0C83
	s_waitcnt lgkmcnt(2)                                       // 000000001A64: BF89FC27
	v_lshlrev_b32_e32 v8, 1, v8                                // 000000001A68: 30101081
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000001A6C: BF870133
	v_lshl_or_b32 v7, v9, 2, v7                                // 000000001A70: D6560007 041D0509
	s_waitcnt lgkmcnt(1)                                       // 000000001A78: BF89FC17
	v_dual_mov_b32 v10, s13 :: v_dual_lshlrev_b32 v9, 5, v10   // 000000001A7C: CA22000D 0A081485
	v_or3_b32 v6, v8, v6, v7                                   // 000000001A84: D6580006 041E0D08
	v_lshlrev_b32_e32 v7, 6, v11                               // 000000001A8C: 300E1686
	s_waitcnt lgkmcnt(0)                                       // 000000001A90: BF89FC07
	v_lshlrev_b32_e32 v8, 7, v22                               // 000000001A94: 30102C87
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001A98: BF870123
	v_or3_b32 v6, v9, v21, v6                                  // 000000001A9C: D6580006 041A2B09
	v_or_b32_e32 v9, s2, v0                                    // 000000001AA4: 38120002
	v_or3_b32 v8, v6, v7, v8                                   // 000000001AA8: D6580008 04220F06
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001AB0: BF870092
	v_add_co_u32 v6, s2, s10, v9                               // 000000001AB4: D7000206 0002120A
	v_add_co_ci_u32_e64 v7, s2, s11, v10, s2                   // 000000001ABC: D5200207 000A140B
	global_store_b8 v[6:7], v8, off                            // 000000001AC4: DC620000 007C0806
	s_or_b32 exec_lo, exec_lo, s7                              // 000000001ACC: 8C7E077E
	s_and_saveexec_b32 s2, s3                                  // 000000001AD0: BE822003
	s_cbranch_execz 30                                         // 000000001AD4: BFA5001E <attn_prep_24_4_256_64_8204_11_k4jv4+0x1b50>
	v_cndmask_b32_e64 v6, v18, v20, s5                         // 000000001AD8: D5010006 00162912
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001AE0: BF8704A1
	v_cndmask_b32_e64 v6, v6, v19, s6                          // 000000001AE4: D5010006 001A2706
	s_lshl_b32 s6, s8, 1                                       // 000000001AEC: 84068108
	s_ashr_i32 s7, s6, 31                                      // 000000001AF0: 86079F06
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001AF4: BF870099
	s_lshl_b64 s[6:7], s[6:7], 2                               // 000000001AF8: 84868206
	v_mul_f32_e32 v7, 0x37800000, v6                           // 000000001AFC: 100E0CFF 37800000
	s_add_u32 s6, s10, s6                                      // 000000001B04: 8006060A
	s_addc_u32 s7, s11, s7                                     // 000000001B08: 8207070B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001B0C: BF870121
	v_dual_cndmask_b32 v6, v6, v7 :: v_dual_mov_b32 v7, 0x140000// 000000001B10: CA500F06 060600FF 00140000
	v_cmp_class_f32_e64 vcc_lo, v17, 0x260                     // 000000001B1C: D47E006A 0001FF11 00000260
	v_cndmask_b32_e32 v6, v6, v17, vcc_lo                      // 000000001B28: 020C2306
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B2C: BF870091
	v_mul_f32_e32 v6, 0x3d800000, v6                           // 000000001B30: 100C0CFF 3D800000
	v_mul_f32_e32 v6, v15, v6                                  // 000000001B38: 100C0D0F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001B3C: BF870001
	v_mul_f32_e32 v6, 0x3ba06c99, v6                           // 000000001B40: 100C0CFF 3BA06C99
	global_store_b32 v7, v6, s[6:7] offset:1924                // 000000001B48: DC6A0784 00060607
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001B50: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 000000001B54: BC7C0000
	s_barrier                                                  // 000000001B58: BFBD0000
	buffer_gl0_inv                                             // 000000001B5C: E0AC0000 00000000
	ds_load_b32 v6, v3 offset:13312                            // 000000001B64: D8D83400 06000003
	s_waitcnt lgkmcnt(0)                                       // 000000001B6C: BF89FC07
	v_mul_f32_e32 v7, v6, v6                                   // 000000001B70: 100E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B74: BF870091
	v_mov_b32_dpp v7, v7 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001B78: 7E0E02FA FF091107
	v_fmac_f32_e32 v7, v6, v6                                  // 000000001B80: 560E0D06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B84: BF870091
	v_add_f32_dpp v6, v7, v7 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001B88: 060C0EFA FF091207
	v_add_f32_dpp v6, v6, v6 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001B90: 060C0CFA FF091406
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001B98: BF870091
	v_add_f32_dpp v6, v6, v6 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001B9C: 060C0CFA FF091806
	v_readlane_b32 s5, v6, 15                                  // 000000001BA4: D7600005 00011F06
	v_readlane_b32 s6, v6, 31                                  // 000000001BAC: D7600006 00013F06
	s_and_saveexec_b32 s2, s1                                  // 000000001BB4: BE822001
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001BB8: BF870001
	v_add_f32_e64 v6, s5, s6                                   // 000000001BBC: D5030006 00000C05
	ds_store_b32 v13, v6 offset:18048                          // 000000001BC4: D8344680 0000060D
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001BCC: 8C7E027E
	v_mov_b32_e32 v23, 0                                       // 000000001BD0: 7E2E0280
	s_waitcnt lgkmcnt(0)                                       // 000000001BD4: BF89FC07
	s_barrier                                                  // 000000001BD8: BFBD0000
	buffer_gl0_inv                                             // 000000001BDC: E0AC0000 00000000
	ds_load_b128 v[6:9], v23 offset:18048                      // 000000001BE4: DBFC4680 06000017
	ds_load_b128 v[10:13], v23 offset:18064                    // 000000001BEC: DBFC4690 0A000017
	ds_load_b128 v[15:18], v23 offset:18032                    // 000000001BF4: DBFC4670 0F000017
	s_waitcnt lgkmcnt(2)                                       // 000000001BFC: BF89FC27
	v_add_f32_e32 v6, v6, v7                                   // 000000001C00: 060C0F06
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C04: BF870091
	v_add_f32_e32 v6, v8, v6                                   // 000000001C08: 060C0D08
	v_add_f32_e32 v6, v9, v6                                   // 000000001C0C: 060C0D09
	s_waitcnt lgkmcnt(1)                                       // 000000001C10: BF89FC17
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C14: BF870091
	v_add_f32_e32 v6, v10, v6                                  // 000000001C18: 060C0D0A
	v_add_f32_e32 v6, v11, v6                                  // 000000001C1C: 060C0D0B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C20: BF870091
	v_add_f32_e32 v6, v12, v6                                  // 000000001C24: 060C0D0C
	v_add_f32_e32 v11, v13, v6                                 // 000000001C28: 06160D0D
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001C2C: BF870121
	v_mul_f32_e32 v6, 0x4f800000, v11                          // 000000001C30: 100C16FF 4F800000
	v_cmp_gt_f32_e32 vcc_lo, 0xf800000, v11                    // 000000001C38: 7C2816FF 0F800000
	v_cndmask_b32_e32 v6, v11, v6, vcc_lo                      // 000000001C40: 020C0D0B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_2)// 000000001C44: BF870141
	v_sqrt_f32_e32 v7, v6                                      // 000000001C48: 7E0E6706
	s_waitcnt_depctr 0xfff                                     // 000000001C4C: BF880FFF
	v_add_nc_u32_e32 v8, -1, v7                                // 000000001C50: 4A100EC1
	v_add_nc_u32_e32 v9, 1, v7                                 // 000000001C54: 4A120E81
	v_fma_f32 v10, -v8, v7, v6                                 // 000000001C58: D613000A 241A0F08
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001C60: BF870112
	v_fma_f32 v12, -v9, v7, v6                                 // 000000001C64: D613000C 241A0F09
	v_cmp_ge_f32_e64 s2, 0, v10                                // 000000001C6C: D4160002 00021480
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001C74: BF870191
	v_cndmask_b32_e64 v7, v7, v8, s2                           // 000000001C78: D5010007 000A1107
	v_cmp_lt_f32_e64 s2, 0, v12                                // 000000001C80: D4110002 00021880
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001C88: BF870091
	v_cndmask_b32_e64 v7, v7, v9, s2                           // 000000001C8C: D5010007 000A1307
	v_mul_f32_e32 v8, 0x37800000, v7                           // 000000001C94: 10100EFF 37800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000001C9C: BF870121
	v_cndmask_b32_e32 v7, v7, v8, vcc_lo                       // 000000001CA0: 020E1107
	v_cmp_class_f32_e64 vcc_lo, v6, 0x260                      // 000000001CA4: D47E006A 0001FF06 00000260
	v_cndmask_b32_e32 v6, v7, v6, vcc_lo                       // 000000001CB0: 020C0D07
	ds_load_b128 v[7:10], v23 offset:17984                     // 000000001CB4: DBFC4640 07000017
	ds_load_b128 v[19:22], v23 offset:18000                    // 000000001CBC: DBFC4650 13000017
	ds_load_b128 v[23:26], v23 offset:18016                    // 000000001CC4: DBFC4660 17000017
	ds_load_b32 v3, v3 offset:13312                            // 000000001CCC: D8D83400 03000003
	s_waitcnt lgkmcnt(3)                                       // 000000001CD4: BF89FC37
	v_add_f32_e32 v7, v8, v7                                   // 000000001CD8: 060E0F08
	v_add_f32_e32 v8, v8, v9                                   // 000000001CDC: 06101308
	v_add_f32_e32 v9, v10, v9                                  // 000000001CE0: 0612130A
	s_waitcnt lgkmcnt(2)                                       // 000000001CE4: BF89FC27
	v_add_f32_e32 v10, v10, v19                                // 000000001CE8: 0614270A
	v_add_f32_e32 v19, v20, v19                                // 000000001CEC: 06262714
	v_div_scale_f32 v12, null, v6, v6, 0x41800000              // 000000001CF0: D6FC7C0C 03FE0D06 41800000
	v_div_scale_f32 v28, vcc_lo, 0x41800000, v6, 0x41800000    // 000000001CFC: D6FC6A1C 03FE0CFF 41800000
	v_add_f32_e32 v20, v20, v21                                // 000000001D08: 06282B14
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001D0C: BF870003
	v_rcp_f32_e32 v13, v12                                     // 000000001D10: 7E1A550C
	v_add_f32_e32 v21, v22, v21                                // 000000001D14: 062A2B16
	s_waitcnt lgkmcnt(1)                                       // 000000001D18: BF89FC17
	v_dual_add_f32 v22, v22, v23 :: v_dual_mul_f32 v9, 0.5, v9 // 000000001D1C: C9062F16 160812F0
	v_add_f32_e32 v23, v24, v23                                // 000000001D24: 062E2F18
	v_dual_mul_f32 v7, 0.5, v7 :: v_dual_mul_f32 v8, 0.5, v8   // 000000001D28: C8C60EF0 070810F0
	s_waitcnt_depctr 0xfff                                     // 000000001D30: BF880FFF
	v_fma_f32 v27, -v12, v13, 1.0                              // 000000001D34: D613001B 23CA1B0C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D3C: BF870091
	v_fmac_f32_e32 v13, v27, v13                               // 000000001D40: 561A1B1B
	v_mul_f32_e32 v27, v28, v13                                // 000000001D44: 10361B1C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D48: BF870091
	v_fma_f32 v29, -v12, v27, v28                              // 000000001D4C: D613001D 2472370C
	v_fmac_f32_e32 v27, v29, v13                               // 000000001D54: 56361B1D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001D58: BF870091
	v_fma_f32 v12, -v12, v27, v28                              // 000000001D5C: D613000C 2472370C
	v_div_fmas_f32 v12, v12, v13, v27                          // 000000001D64: D637000C 046E1B0C
	v_cmp_lt_f32_e32 vcc_lo, 0, v11                            // 000000001D6C: 7C221680
	v_dual_add_f32 v13, v16, v17 :: v_dual_mul_f32 v10, 0.5, v10// 000000001D70: C9062310 0D0A14F0
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001D78: BF870003
	v_div_fixup_f32 v12, v12, v6, 0x41800000                   // 000000001D7C: D627000C 03FE0D0C 41800000
	v_add_f32_e32 v24, v24, v25                                // 000000001D88: 06303318
	v_add_f32_e32 v25, v26, v25                                // 000000001D8C: 0632331A
	v_add_f32_e32 v26, v26, v15                                // 000000001D90: 06341F1A
	v_add_f32_e32 v15, v16, v15                                // 000000001D94: 061E1F10
	v_dual_cndmask_b32 v11, 0, v12 :: v_dual_add_f32 v16, v18, v17// 000000001D98: CA481880 0B102312
	v_dual_mul_f32 v17, 0.5, v19 :: v_dual_mul_f32 v12, 0.5, v20// 000000001DA0: C8C626F0 110C28F0
	v_mul_f32_e32 v19, 0.5, v22                                // 000000001DA8: 10262CF0
	s_waitcnt lgkmcnt(0)                                       // 000000001DAC: BF89FC07
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000001DB0: BF8701B3
	v_dual_mul_f32 v3, v3, v11 :: v_dual_mul_f32 v18, 0.5, v21 // 000000001DB4: C8C61703 03122AF0
	v_dual_mul_f32 v11, 0.5, v24 :: v_dual_mul_f32 v20, 0.5, v23// 000000001DBC: C8C630F0 0B142EF0
	v_mul_f32_e32 v21, 0.5, v25                                // 000000001DC4: 102A32F0
	v_cmp_gt_f32_e32 vcc_lo, v3, v7                            // 000000001DC8: 7C280F03
	v_dual_mul_f32 v22, 0.5, v26 :: v_dual_mul_f32 v15, 0.5, v15// 000000001DCC: C8C634F0 160E1EF0
	v_cndmask_b32_e64 v7, 0, 1, vcc_lo                         // 000000001DD4: D5010007 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v8                            // 000000001DDC: 7C281103
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001DE0: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v10                           // 000000001DE8: 7C281503
	v_cndmask_b32_e64 v10, 0, 1, vcc_lo                        // 000000001DEC: D501000A 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v9                            // 000000001DF4: 7C281303
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001DF8: BF870244
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001DFC: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v12                           // 000000001E00: 7C281903
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001E04: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v17                           // 000000001E0C: 7C282303
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v10, vcc_lo            // 000000001E10: 400E1507
	v_cmp_gt_f32_e32 vcc_lo, v3, v19                           // 000000001E14: 7C282703
	v_mul_f32_e32 v10, 0.5, v16                                // 000000001E18: 101420F0
	v_cndmask_b32_e64 v9, 0, 1, vcc_lo                         // 000000001E1C: D5010009 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v18                           // 000000001E24: 7C282503
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001E28: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v11                           // 000000001E2C: 7C281703
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001E30: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v20                           // 000000001E38: 7C282903
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 000000001E3C: BF870244
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v9, vcc_lo             // 000000001E40: 400E1307
	v_cmp_gt_f32_e32 vcc_lo, v3, v22                           // 000000001E44: 7C282D03
	v_cndmask_b32_e64 v9, 0, 1, vcc_lo                         // 000000001E48: D5010009 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v21                           // 000000001E50: 7C282B03
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v8, vcc_lo             // 000000001E54: 400E1107
	v_cmp_gt_f32_e32 vcc_lo, v3, v15                           // 000000001E58: 7C281F03
	v_mul_f32_e32 v8, 0.5, v13                                 // 000000001E5C: 10101AF0
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001E60: BF870113
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v9, vcc_lo             // 000000001E64: 400E1307
	v_cmp_gt_f32_e32 vcc_lo, v3, v8                            // 000000001E68: 7C281103
	v_cndmask_b32_e64 v8, 0, 1, vcc_lo                         // 000000001E6C: D5010008 01A90280
	v_cmp_gt_f32_e32 vcc_lo, v3, v10                           // 000000001E74: 7C281503
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001E78: BF870002
	v_add_co_ci_u32_e32 v3, vcc_lo, v7, v8, vcc_lo             // 000000001E7C: 40061107
	ds_store_b32 v14, v3                                       // 000000001E80: D8340000 0000030E
	s_and_saveexec_b32 s2, s3                                  // 000000001E88: BE822003
	s_cbranch_execz 9                                          // 000000001E8C: BFA50009 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1eb4>
	v_mul_f32_e32 v3, 0x3d800000, v6                           // 000000001E90: 10060CFF 3D800000
	s_lshl_b64 s[6:7], s[8:9], 2                               // 000000001E98: 84868208
	v_mov_b32_e32 v6, 0x250000                                 // 000000001E9C: 7E0C02FF 00250000
	s_add_u32 s6, s10, s6                                      // 000000001EA4: 8006060A
	s_addc_u32 s7, s11, s7                                     // 000000001EA8: 8207070B
	global_store_b32 v6, v3, s[6:7] offset:3552                // 000000001EAC: DC6A0DE0 00060306
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001EB4: 8C7E027E
	s_waitcnt lgkmcnt(0)                                       // 000000001EB8: BF89FC07
	s_waitcnt_vscnt null, 0x0                                  // 000000001EBC: BC7C0000
	s_barrier                                                  // 000000001EC0: BFBD0000
	buffer_gl0_inv                                             // 000000001EC4: E0AC0000 00000000
	s_and_saveexec_b32 s2, s4                                  // 000000001ECC: BE822004
	s_cbranch_execz 21                                         // 000000001ED0: BFA50015 <attn_prep_24_4_256_64_8204_11_k4jv4+0x1f28>
	v_lshlrev_b32_e32 v3, 2, v5                                // 000000001ED4: 30060A82
	s_lshl_b64 s[4:5], s[8:9], 7                               // 000000001ED8: 84848708
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_3) | instid1(VALU_DEP_1)// 000000001EDC: BF8700C9
	s_add_u32 s3, s10, s4                                      // 000000001EE0: 8003040A
	s_addc_u32 s4, s11, s5                                     // 000000001EE4: 8204050B
	ds_load_b64 v[5:6], v3 offset:16896                        // 000000001EE8: D9D84200 05000003
	v_add_co_u32 v0, s3, s3, v0                                // 000000001EF0: D7000300 00020003
	v_add_co_ci_u32_e64 v3, null, s4, 0, s3                    // 000000001EF8: D5207C03 000D0004
	s_waitcnt lgkmcnt(0)                                       // 000000001F00: BF89FC07
	v_lshl_or_b32 v7, v6, 4, v5                                // 000000001F04: D6560007 04150906
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000001F0C: BF870193
	v_add_co_u32 v5, vcc_lo, 0x150000, v0                      // 000000001F10: D7006A05 000200FF 00150000
	v_add_co_ci_u32_e32 v6, vcc_lo, 0, v3, vcc_lo              // 000000001F1C: 400C0680
	global_store_b8 v[5:6], v7, off offset:2016                // 000000001F20: DC6207E0 007C0705
	s_or_b32 exec_lo, exec_lo, s2                              // 000000001F28: 8C7E027E
	s_waitcnt_vscnt null, 0x0                                  // 000000001F2C: BC7C0000
	s_barrier                                                  // 000000001F30: BFBD0000
	buffer_gl0_inv                                             // 000000001F34: E0AC0000 00000000
	s_and_saveexec_b32 s2, s0                                  // 000000001F3C: BE822000
	s_cbranch_execz 357                                        // 000000001F40: BFA50165 <attn_prep_24_4_256_64_8204_11_k4jv4+0x24d8>
	v_lshl_or_b32 v6, v1, 10, v2                               // 000000001F44: D6560006 04091501
	ds_load_b128 v[8:11], v6                                   // 000000001F4C: DBFC0000 08000006
	ds_load_b128 v[12:15], v6 offset:16                        // 000000001F54: DBFC0010 0C000006
	s_waitcnt lgkmcnt(1)                                       // 000000001F5C: BF89FC17
	v_max3_f32 v0, |v8|, 0, |v9|                               // 000000001F60: D61C0500 04250108
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000001F68: BF8700A1
	v_max3_f32 v0, v0, |v10|, |v11|                            // 000000001F6C: D61C0600 042E1500
	s_waitcnt lgkmcnt(0)                                       // 000000001F74: BF89FC07
	v_max3_f32 v0, v0, |v12|, |v13|                            // 000000001F78: D61C0600 04361900
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001F80: BF870091
	v_max3_f32 v0, v0, |v14|, |v15|                            // 000000001F84: D61C0600 043E1D00
	v_mov_b32_dpp v2, v0 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001F8C: 7E0402FA FF091100
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001F94: BF870091
	v_max_f32_e32 v2, v2, v2                                   // 000000001F98: 20040502
	v_max_f32_e32 v0, v0, v2                                   // 000000001F9C: 20000500
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FA0: BF870091
	v_mov_b32_dpp v2, v0 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001FA4: 7E0402FA FF091200
	v_max_f32_e32 v2, v2, v2                                   // 000000001FAC: 20040502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FB0: BF870091
	v_max_f32_e32 v0, v0, v2                                   // 000000001FB4: 20000500
	v_mov_b32_dpp v2, v0 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001FB8: 7E0402FA FF091400
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FC0: BF870091
	v_max_f32_e32 v2, v2, v2                                   // 000000001FC4: 20040502
	v_max_f32_e32 v0, v0, v2                                   // 000000001FC8: 20000500
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FCC: BF870091
	v_mov_b32_dpp v2, v0 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000001FD0: 7E0402FA FF091800
	v_max_f32_e32 v2, v2, v2                                   // 000000001FD8: 20040502
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FDC: BF870091
	v_max_f32_e32 v0, v0, v2                                   // 000000001FE0: 20000500
	v_readlane_b32 s0, v0, 31                                  // 000000001FE4: D7600000 00013F00
	v_readlane_b32 s2, v0, 15                                  // 000000001FEC: D7600002 00011F00
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001FF4: BF870112
	v_max_f32_e64 v0, s0, s0                                   // 000000001FF8: D5100000 00000000
	v_max_f32_e64 v2, s2, s2                                   // 000000002000: D5100002 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002008: BF870091
	v_max_f32_e32 v0, v2, v0                                   // 00000000200C: 20000102
	v_div_scale_f32 v2, null, 0x42fe0000, 0x42fe0000, v0       // 000000002010: D6FC7C02 0401FEFF 42FE0000
	v_div_scale_f32 v7, vcc_lo, v0, 0x42fe0000, v0             // 00000000201C: D6FC6A07 0401FF00 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002028: BF8700B2
	v_rcp_f32_e32 v3, v2                                       // 00000000202C: 7E065502
	s_waitcnt_depctr 0xfff                                     // 000000002030: BF880FFF
	v_fma_f32 v5, -v2, v3, 1.0                                 // 000000002034: D6130005 23CA0702
	v_fmac_f32_e32 v3, v5, v3                                  // 00000000203C: 56060705
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002040: BF870091
	v_mul_f32_e32 v5, v7, v3                                   // 000000002044: 100A0707
	v_fma_f32 v16, -v2, v5, v7                                 // 000000002048: D6130010 241E0B02
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002050: BF870091
	v_fmac_f32_e32 v5, v16, v3                                 // 000000002054: 560A0710
	v_fma_f32 v2, -v2, v5, v7                                  // 000000002058: D6130002 241E0B02
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002060: BF870091
	v_div_fmas_f32 v2, v2, v3, v5                              // 000000002064: D6370002 04160702
	v_div_fixup_f32 v7, v2, 0x42fe0000, v0                     // 00000000206C: D6270007 0401FF02 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002078: BF870121
	v_div_scale_f32 v0, null, v7, v7, 1.0                      // 00000000207C: D6FC7C00 03CA0F07
	v_div_scale_f32 v16, vcc_lo, 1.0, v7, 1.0                  // 000000002084: D6FC6A10 03CA0EF2
	v_rcp_f32_e32 v5, v0                                       // 00000000208C: 7E0A5500
	s_waitcnt_depctr 0xfff                                     // 000000002090: BF880FFF
	v_fma_f32 v2, -v0, v5, 1.0                                 // 000000002094: D6130002 23CA0B00
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000209C: BF870121
	v_fmac_f32_e32 v5, v2, v5                                  // 0000000020A0: 560A0B02
	v_mad_u64_u32 v[2:3], null, s28, 6, v[1:2]                 // 0000000020A4: D6FE7C02 04050C1C
	v_dual_mov_b32 v3, 0 :: v_dual_mul_f32 v18, v16, v5        // 0000000020AC: CA060080 03120B10
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000020B4: BF870091
	v_fma_f32 v17, -v0, v18, v16                               // 0000000020B8: D6130011 24422500
	v_fmac_f32_e32 v18, v17, v5                                // 0000000020C0: 56240B11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000020C4: BF870211
	v_fma_f32 v0, -v0, v18, v16                                // 0000000020C8: D6130000 24422500
	v_mad_u64_u32 v[16:17], null, s12, 24, v[2:3]              // 0000000020D0: D6FE7C10 0409300C
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 0000000020D8: BF8701A2
	v_div_fmas_f32 v0, v0, v5, v18                             // 0000000020DC: D6370000 044A0B00
	v_cmp_neq_f32_e32 vcc_lo, 0, v7                            // 0000000020E4: 7C3A0E80
	v_lshlrev_b64 v[2:3], 8, v[16:17]                          // 0000000020E8: D73C0002 00022088
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000020F0: BF870123
	v_div_fixup_f32 v5, v0, v7, 1.0                            // 0000000020F4: D6270005 03CA0F00
	v_lshlrev_b32_e32 v0, 3, v4                                // 0000000020FC: 30000883
	v_cndmask_b32_e32 v4, 0, v5, vcc_lo                        // 000000002100: 02080A80
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000002104: BF8701A4
	v_add_co_u32 v5, vcc_lo, s16, v2                           // 000000002108: D7006A05 00020410
	v_add_co_ci_u32_e32 v18, vcc_lo, s17, v3, vcc_lo           // 000000002110: 40240611
	v_mul_f32_e32 v13, v13, v4                                 // 000000002114: 101A090D
	v_mul_f32_e32 v9, v9, v4                                   // 000000002118: 10120909
	v_mul_f32_e32 v10, v10, v4                                 // 00000000211C: 1014090A
	v_mul_f32_e32 v14, v14, v4                                 // 000000002120: 101C090E
	v_mul_f32_e32 v11, v11, v4                                 // 000000002124: 1016090B
	v_rndne_f32_e32 v13, v13                                   // 000000002128: 7E1A470D
	v_rndne_f32_e32 v9, v9                                     // 00000000212C: 7E124709
	v_rndne_f32_e32 v10, v10                                   // 000000002130: 7E14470A
	v_rndne_f32_e32 v14, v14                                   // 000000002134: 7E1C470E
	v_rndne_f32_e32 v11, v11                                   // 000000002138: 7E16470B
	v_cvt_i32_f32_e32 v13, v13                                 // 00000000213C: 7E1A110D
	v_mul_f32_e32 v8, v8, v4                                   // 000000002140: 10100908
	v_cvt_i32_f32_e32 v9, v9                                   // 000000002144: 7E121109
	v_cvt_i32_f32_e32 v10, v10                                 // 000000002148: 7E14110A
	v_cvt_i32_f32_e32 v14, v14                                 // 00000000214C: 7E1C110E
	v_dual_mul_f32 v12, v12, v4 :: v_dual_lshlrev_b32 v13, 8, v13// 000000002150: C8E2090C 0C0C1A88
	v_mul_f32_e32 v4, v15, v4                                  // 000000002158: 1008090F
	v_rndne_f32_e32 v8, v8                                     // 00000000215C: 7E104708
	v_cvt_i32_f32_e32 v11, v11                                 // 000000002160: 7E16110B
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002164: BF870004
	v_and_b32_e32 v13, 0xff00, v13                             // 000000002168: 361A1AFF 0000FF00
	v_rndne_f32_e32 v12, v12                                   // 000000002170: 7E18470C
	v_rndne_f32_e32 v4, v4                                     // 000000002174: 7E084704
	v_cvt_i32_f32_e32 v8, v8                                   // 000000002178: 7E101108
	v_lshlrev_b32_e32 v9, 8, v9                                // 00000000217C: 30121288
	v_lshlrev_b32_e32 v10, 16, v10                             // 000000002180: 30141490
	v_cvt_i32_f32_e32 v12, v12                                 // 000000002184: 7E18110C
	v_cvt_i32_f32_e32 v4, v4                                   // 000000002188: 7E081104
	v_lshlrev_b32_e32 v14, 16, v14                             // 00000000218C: 301C1C90
	v_perm_b32 v11, v11, v8, 0x40c0c00                         // 000000002190: D644000B 03FE110B 040C0C00
	v_and_b32_e32 v10, 0xff0000, v10                           // 00000000219C: 361414FF 00FF0000
	v_add_co_u32 v8, vcc_lo, v5, v0                            // 0000000021A4: D7006A08 00020105
	v_perm_b32 v4, v4, v12, 0x40c0c00                          // 0000000021AC: D6440004 03FE1904 040C0C00
	v_and_b32_e32 v12, 0xff00, v9                              // 0000000021B8: 361812FF 0000FF00
	v_and_b32_e32 v14, 0xff0000, v14                           // 0000000021C0: 361C1CFF 00FF0000
	v_add_co_ci_u32_e32 v9, vcc_lo, 0, v18, vcc_lo             // 0000000021C8: 40122480
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000021CC: BF870193
	v_or3_b32 v10, v11, v12, v10                               // 0000000021D0: D658000A 042A190B
	v_or3_b32 v11, v4, v13, v14                                // 0000000021D8: D658000B 043A1B04
	v_lshlrev_b64 v[4:5], 2, v[16:17]                          // 0000000021E0: D73C0004 00022082
	global_store_b64 v[8:9], v[10:11], off                     // 0000000021E8: DC6E0000 007C0A08
	s_and_saveexec_b32 s0, s1                                  // 0000000021F0: BE802001
	s_cbranch_execz 5                                          // 0000000021F4: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x220c>
	v_add_co_u32 v8, vcc_lo, s18, v4                           // 0000000021F8: D7006A08 00020812
	v_add_co_ci_u32_e32 v9, vcc_lo, s19, v5, vcc_lo            // 000000002200: 40120A13
	global_store_b32 v[8:9], v7, off                           // 000000002204: DC6A0000 007C0708
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000220C: 8C7E007E
	v_lshlrev_b32_e32 v10, 2, v0                               // 000000002210: 30140082
	ds_load_b128 v[6:9], v6 offset:6144                        // 000000002214: DBFC1800 06000006
	v_lshl_or_b32 v1, v1, 10, v10                              // 00000000221C: D6560001 04291501
	ds_load_b128 v[10:13], v1 offset:6160                      // 000000002224: DBFC1810 0A000001
	s_waitcnt lgkmcnt(1)                                       // 00000000222C: BF89FC17
	v_max3_f32 v1, |v6|, 0, |v7|                               // 000000002230: D61C0501 041D0106
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002238: BF8700A1
	v_max3_f32 v1, v1, |v8|, |v9|                              // 00000000223C: D61C0601 04261101
	s_waitcnt lgkmcnt(0)                                       // 000000002244: BF89FC07
	v_max3_f32 v1, v1, |v10|, |v11|                            // 000000002248: D61C0601 042E1501
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002250: BF870091
	v_max3_f32 v1, v1, |v12|, |v13|                            // 000000002254: D61C0601 04361901
	v_mov_b32_dpp v14, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 00000000225C: 7E1C02FA FF091101
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002264: BF870091
	v_max_f32_e32 v14, v14, v14                                // 000000002268: 201C1D0E
	v_max_f32_e32 v1, v1, v14                                  // 00000000226C: 20021D01
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002270: BF870091
	v_mov_b32_dpp v14, v1 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002274: 7E1C02FA FF091201
	v_max_f32_e32 v14, v14, v14                                // 00000000227C: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002280: BF870091
	v_max_f32_e32 v1, v1, v14                                  // 000000002284: 20021D01
	v_mov_b32_dpp v14, v1 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002288: 7E1C02FA FF091401
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002290: BF870091
	v_max_f32_e32 v14, v14, v14                                // 000000002294: 201C1D0E
	v_max_f32_e32 v1, v1, v14                                  // 000000002298: 20021D01
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000229C: BF870091
	v_mov_b32_dpp v14, v1 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000022A0: 7E1C02FA FF091801
	v_max_f32_e32 v14, v14, v14                                // 0000000022A8: 201C1D0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000022AC: BF870091
	v_max_f32_e32 v1, v1, v14                                  // 0000000022B0: 20021D01
	v_readlane_b32 s0, v1, 31                                  // 0000000022B4: D7600000 00013F01
	v_readlane_b32 s2, v1, 15                                  // 0000000022BC: D7600002 00011F01
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000022C4: BF870112
	v_max_f32_e64 v1, s0, s0                                   // 0000000022C8: D5100001 00000000
	v_max_f32_e64 v14, s2, s2                                  // 0000000022D0: D510000E 00000402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000022D8: BF870091
	v_max_f32_e32 v1, v14, v1                                  // 0000000022DC: 2002030E
	v_div_scale_f32 v14, null, 0x42fe0000, 0x42fe0000, v1      // 0000000022E0: D6FC7C0E 0405FEFF 42FE0000
	v_div_scale_f32 v17, vcc_lo, v1, 0x42fe0000, v1            // 0000000022EC: D6FC6A11 0405FF01 42FE0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 0000000022F8: BF8700B2
	v_rcp_f32_e32 v15, v14                                     // 0000000022FC: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 000000002300: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 000000002304: D6130010 23CA1F0E
	v_fmac_f32_e32 v15, v16, v15                               // 00000000230C: 561E1F10
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002310: BF870091
	v_mul_f32_e32 v16, v17, v15                                // 000000002314: 10201F11
	v_fma_f32 v18, -v14, v16, v17                              // 000000002318: D6130012 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002320: BF870091
	v_fmac_f32_e32 v16, v18, v15                               // 000000002324: 56201F12
	v_fma_f32 v14, -v14, v16, v17                              // 000000002328: D613000E 2446210E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002330: BF870091
	v_div_fmas_f32 v14, v14, v15, v16                          // 000000002334: D637000E 04421F0E
	v_div_fixup_f32 v1, v14, 0x42fe0000, v1                    // 00000000233C: D6270001 0405FF0E 42FE0000
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002348: BF870121
	v_div_scale_f32 v14, null, v1, v1, 1.0                     // 00000000234C: D6FC7C0E 03CA0301
	v_div_scale_f32 v17, vcc_lo, 1.0, v1, 1.0                  // 000000002354: D6FC6A11 03CA02F2
	v_rcp_f32_e32 v15, v14                                     // 00000000235C: 7E1E550E
	s_waitcnt_depctr 0xfff                                     // 000000002360: BF880FFF
	v_fma_f32 v16, -v14, v15, 1.0                              // 000000002364: D6130010 23CA1F0E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000236C: BF870091
	v_fmac_f32_e32 v15, v16, v15                               // 000000002370: 561E1F10
	v_mul_f32_e32 v16, v17, v15                                // 000000002374: 10201F11
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002378: BF870091
	v_fma_f32 v18, -v14, v16, v17                              // 00000000237C: D6130012 2446210E
	v_fmac_f32_e32 v16, v18, v15                               // 000000002384: 56201F12
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002388: BF870091
	v_fma_f32 v14, -v14, v16, v17                              // 00000000238C: D613000E 2446210E
	v_div_fmas_f32 v14, v14, v15, v16                          // 000000002394: D637000E 04421F0E
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 00000000239C: 7C3A0280
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023A0: BF870092
	v_div_fixup_f32 v14, v14, v1, 1.0                          // 0000000023A4: D627000E 03CA030E
	v_cndmask_b32_e32 v14, 0, v14, vcc_lo                      // 0000000023AC: 021C1C80
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023B0: BF870091
	v_mul_f32_e32 v7, v7, v14                                  // 0000000023B4: 100E1D07
	v_rndne_f32_e32 v7, v7                                     // 0000000023B8: 7E0E4707
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023BC: BF870091
	v_cvt_i32_f32_e32 v7, v7                                   // 0000000023C0: 7E0E1107
	v_lshlrev_b32_e32 v7, 8, v7                                // 0000000023C4: 300E0E88
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 0000000023C8: BF8701B1
	v_dual_mul_f32 v12, v12, v14 :: v_dual_and_b32 v7, 0xff00, v7// 0000000023CC: C8E41D0C 0C060EFF 0000FF00
	v_mul_f32_e32 v8, v8, v14                                  // 0000000023D8: 10101D08
	v_mul_f32_e32 v10, v10, v14                                // 0000000023DC: 10141D0A
	v_rndne_f32_e32 v12, v12                                   // 0000000023E0: 7E18470C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000023E4: BF870193
	v_rndne_f32_e32 v8, v8                                     // 0000000023E8: 7E104708
	v_rndne_f32_e32 v10, v10                                   // 0000000023EC: 7E14470A
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 0000000023F0: BF870223
	v_cvt_i32_f32_e32 v12, v12                                 // 0000000023F4: 7E18110C
	v_mul_f32_e32 v11, v11, v14                                // 0000000023F8: 10161D0B
	v_cvt_i32_f32_e32 v8, v8                                   // 0000000023FC: 7E101108
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002400: BF870214
	v_cvt_i32_f32_e32 v10, v10                                 // 000000002404: 7E14110A
	v_lshlrev_b32_e32 v12, 16, v12                             // 000000002408: 30181890
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 00000000240C: BF8701B4
	v_rndne_f32_e32 v11, v11                                   // 000000002410: 7E16470B
	v_mul_f32_e32 v6, v6, v14                                  // 000000002414: 100C1D06
	v_dual_mul_f32 v13, v13, v14 :: v_dual_lshlrev_b32 v8, 16, v8// 000000002418: C8E21D0D 0D081090
	v_cvt_i32_f32_e32 v11, v11                                 // 000000002420: 7E16110B
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002424: BF870193
	v_rndne_f32_e32 v6, v6                                     // 000000002428: 7E0C4706
	v_and_b32_e32 v8, 0xff0000, v8                             // 00000000242C: 361010FF 00FF0000
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002434: BF870214
	v_rndne_f32_e32 v13, v13                                   // 000000002438: 7E1A470D
	v_lshlrev_b32_e32 v11, 8, v11                              // 00000000243C: 30161688
	v_mul_f32_e32 v9, v9, v14                                  // 000000002440: 10121D09
	v_cvt_i32_f32_e32 v6, v6                                   // 000000002444: 7E0C1106
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000002448: BF870194
	v_cvt_i32_f32_e32 v13, v13                                 // 00000000244C: 7E1A110D
	v_rndne_f32_e32 v9, v9                                     // 000000002450: 7E124709
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002454: BF870091
	v_cvt_i32_f32_e32 v9, v9                                   // 000000002458: 7E121109
	v_perm_b32 v6, v9, v6, 0x40c0c00                           // 00000000245C: D6440006 03FE0D09 040C0C00
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002468: BF870004
	v_perm_b32 v9, v13, v10, 0x40c0c00                         // 00000000246C: D6440009 03FE150D 040C0C00
	v_and_b32_e32 v10, 0xff00, v11                             // 000000002478: 361416FF 0000FF00
	v_and_b32_e32 v11, 0xff0000, v12                           // 000000002480: 361618FF 00FF0000
	v_add_co_u32 v12, vcc_lo, s20, v2                          // 000000002488: D7006A0C 00020414
	v_add_co_ci_u32_e32 v13, vcc_lo, s21, v3, vcc_lo           // 000000002490: 401A0615
	v_or3_b32 v2, v6, v7, v8                                   // 000000002494: D6580002 04220F06
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 00000000249C: BF870223
	v_add_co_u32 v6, vcc_lo, v12, v0                           // 0000000024A0: D7006A06 0002010C
	v_or3_b32 v3, v9, v10, v11                                 // 0000000024A8: D6580003 042E1509
	v_add_co_ci_u32_e32 v7, vcc_lo, 0, v13, vcc_lo             // 0000000024B0: 400E1A80
	global_store_b64 v[6:7], v[2:3], off                       // 0000000024B4: DC6E0000 007C0206
	s_and_b32 exec_lo, exec_lo, s1                             // 0000000024BC: 8B7E017E
	s_cbranch_execz 5                                          // 0000000024C0: BFA50005 <attn_prep_24_4_256_64_8204_11_k4jv4+0x24d8>
	v_add_co_u32 v2, vcc_lo, s22, v4                           // 0000000024C4: D7006A02 00020816
	v_add_co_ci_u32_e32 v3, vcc_lo, s23, v5, vcc_lo            // 0000000024CC: 40060A17
	global_store_b32 v[2:3], v1, off                           // 0000000024D0: DC6A0000 007C0102
	s_endpgm                                                   // 0000000024D8: BFB00000
	s_code_end                                                 // 0000000024DC: BF9F0000
	s_code_end                                                 // 0000000024E0: BF9F0000
	s_code_end                                                 // 0000000024E4: BF9F0000
	s_code_end                                                 // 0000000024E8: BF9F0000
	s_code_end                                                 // 0000000024EC: BF9F0000
	s_code_end                                                 // 0000000024F0: BF9F0000
	s_code_end                                                 // 0000000024F4: BF9F0000
	s_code_end                                                 // 0000000024F8: BF9F0000
	s_code_end                                                 // 0000000024FC: BF9F0000
	s_code_end                                                 // 000000002500: BF9F0000
	s_code_end                                                 // 000000002504: BF9F0000
	s_code_end                                                 // 000000002508: BF9F0000
	s_code_end                                                 // 00000000250C: BF9F0000
	s_code_end                                                 // 000000002510: BF9F0000
	s_code_end                                                 // 000000002514: BF9F0000
	s_code_end                                                 // 000000002518: BF9F0000
	s_code_end                                                 // 00000000251C: BF9F0000
	s_code_end                                                 // 000000002520: BF9F0000
	s_code_end                                                 // 000000002524: BF9F0000
	s_code_end                                                 // 000000002528: BF9F0000
	s_code_end                                                 // 00000000252C: BF9F0000
	s_code_end                                                 // 000000002530: BF9F0000
	s_code_end                                                 // 000000002534: BF9F0000
	s_code_end                                                 // 000000002538: BF9F0000
	s_code_end                                                 // 00000000253C: BF9F0000
	s_code_end                                                 // 000000002540: BF9F0000
	s_code_end                                                 // 000000002544: BF9F0000
	s_code_end                                                 // 000000002548: BF9F0000
	s_code_end                                                 // 00000000254C: BF9F0000
	s_code_end                                                 // 000000002550: BF9F0000
	s_code_end                                                 // 000000002554: BF9F0000
	s_code_end                                                 // 000000002558: BF9F0000
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
