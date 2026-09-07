
/tmp/tmpidz5vyzp.elf:	file format elf64-amdgpu

Disassembly of section .text:

0000000000000000 <attn_pfd>:
	s_load_b64 s[2:3], s[0:1], 0x40                            // 000000000000: F4040080 F8000040
	s_mul_hi_u32 s5, s15, 0x91f5bcb9                           // 000000000008: 9685FF0F 91F5BCB9
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000010: BF870499
	s_lshr_b32 s6, s5, 7                                       // 000000000014: 85068705
	s_and_b32 s7, s6, 0x1fffff8                                // 000000000018: 8B07FF06 01FFFFF8
	s_waitcnt lgkmcnt(0)                                       // 000000000020: BF89FC07
	s_load_b32 s4, s[2:3], 0x4                                 // 000000000024: F4000101 F8000004
	s_waitcnt lgkmcnt(0)                                       // 00000000002C: BF89FC07
	s_cmp_le_u32 s4, s7                                        // 000000000030: BF0B0704
	s_cbranch_scc1 4225                                        // 000000000034: BFA21081 <attn_pfd+0x423c>
	s_load_b32 s6, s[2:3], null                                // 000000000038: F4000181 F8000000
	s_lshr_b32 s3, s5, 8                                       // 000000000040: 85038805
	s_sub_i32 s2, s4, s7                                       // 000000000044: 81820704
	s_mul_i32 s4, s3, 0xfffffe3f                               // 000000000048: 9604FF03 FFFFFE3F
	s_min_u32 s27, s2, 8                                       // 000000000050: 899B8802
	s_add_i32 s24, s4, s15                                     // 000000000054: 81180F04
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)// 000000000058: BF8704B9
	s_lshl_b32 s25, s24, 8                                     // 00000000005C: 84198818
	s_waitcnt lgkmcnt(0)                                       // 000000000060: BF89FC07
	s_add_i32 s6, s6, s7                                       // 000000000064: 81060706
	s_add_i32 s2, s6, s27                                      // 000000000068: 81021B06
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000006C: BF870009
	s_cmp_ge_u32 s25, s2                                       // 000000000070: BF090219
	s_cbranch_scc1 4209                                        // 000000000074: BFA21071 <attn_pfd+0x423c>
	s_clause 0x1                                               // 000000000078: BF850001
	s_load_b256 s[8:15], s[0:1], null                          // 00000000007C: F40C0200 F8000000
	s_load_b256 s[16:23], s[0:1], 0x20                         // 000000000084: F40C0400 F8000020
	s_mov_b32 s0, exec_lo                                      // 00000000008C: BE80007E
	v_cmpx_gt_u32_e32 16, v0                                   // 000000000090: 7D980090
	s_cbranch_execz 290                                        // 000000000094: BFA50122 <attn_pfd+0x520>
	s_mov_b32 s1, 0                                            // 000000000098: BE810080
	s_mov_b32 s5, 0                                            // 00000000009C: BE850080
	s_mov_b32 s4, exec_lo                                      // 0000000000A0: BE84007E
	v_cmpx_lt_i32_e32 6, v0                                    // 0000000000A4: 7D820086
	s_xor_b32 s4, exec_lo, s4                                  // 0000000000A8: 8D04047E
	s_cbranch_execz 70                                         // 0000000000AC: BFA50046 <attn_pfd+0x1c8>
	s_mov_b32 s5, exec_lo                                      // 0000000000B0: BE85007E
	v_cmpx_lt_i32_e32 10, v0                                   // 0000000000B4: 7D82008A
	s_xor_b32 s5, exec_lo, s5                                  // 0000000000B8: 8D05057E
	s_cbranch_execz 35                                         // 0000000000BC: BFA50023 <attn_pfd+0x14c>
	s_mov_b32 s26, exec_lo                                     // 0000000000C0: BE9A007E
	v_cmpx_lt_i32_e32 12, v0                                   // 0000000000C4: 7D82008C
	s_xor_b32 s26, exec_lo, s26                                // 0000000000C8: 8D1A1A7E
	s_cbranch_execz 18                                         // 0000000000CC: BFA50012 <attn_pfd+0x118>
	s_mov_b32 s28, exec_lo                                     // 0000000000D0: BE9C007E
	v_cmpx_lt_i32_e32 13, v0                                   // 0000000000D4: 7D82008D
	s_xor_b32 s28, exec_lo, s28                                // 0000000000D8: 8D1C1C7E
	s_cbranch_execz 10                                         // 0000000000DC: BFA5000A <attn_pfd+0x108>
	s_mov_b32 s30, exec_lo                                     // 0000000000E0: BE9E007E
	v_cmpx_ne_u32_e32 14, v0                                   // 0000000000E4: 7D9A008E
	s_xor_b32 s30, exec_lo, s30                                // 0000000000E8: 8D1E1E7E
	s_movk_i32 s29, 0x7f                                       // 0000000000EC: B01D007F
	s_or_saveexec_b32 s30, s30                                 // 0000000000F0: BE9E221E
	v_mov_b32_e32 v1, s29                                      // 0000000000F4: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s30                            // 0000000000F8: 8D7E1E7E
	v_mov_b32_e32 v1, 0x60                                     // 0000000000FC: 7E0202FF 00000060
	s_or_b32 exec_lo, exec_lo, s30                             // 000000000104: 8C7E1E7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000108: BE9C301C
	v_mov_b32_e32 v1, 0x4b                                     // 00000000010C: 7E0202FF 0000004B
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000114: 8C7E1C7E
	s_and_not1_saveexec_b32 s26, s26                           // 000000000118: BE9A301A
	s_cbranch_execz 9                                          // 00000000011C: BFA50009 <attn_pfd+0x144>
	s_mov_b32 s28, exec_lo                                     // 000000000120: BE9C007E
	v_cmpx_lt_i32_e32 11, v0                                   // 000000000124: 7D82008B
	s_xor_b32 s28, exec_lo, s28                                // 000000000128: 8D1C1C7E
	s_mov_b32 s29, 58                                          // 00000000012C: BE9D00BA
	s_or_saveexec_b32 s28, s28                                 // 000000000130: BE9C221C
	v_mov_b32_e32 v1, s29                                      // 000000000134: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s28                            // 000000000138: 8D7E1C7E
	v_mov_b32_e32 v1, 44                                       // 00000000013C: 7E0202AC
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000140: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000144: BF870009
	s_or_b32 exec_lo, exec_lo, s26                             // 000000000148: 8C7E1A7E
	s_and_not1_saveexec_b32 s5, s5                             // 00000000014C: BE853005
	s_cbranch_execz 26                                         // 000000000150: BFA5001A <attn_pfd+0x1bc>
	s_mov_b32 s26, exec_lo                                     // 000000000154: BE9A007E
	v_cmpx_lt_i32_e32 8, v0                                    // 000000000158: 7D820088
	s_xor_b32 s26, exec_lo, s26                                // 00000000015C: 8D1A1A7E
	s_cbranch_execz 9                                          // 000000000160: BFA50009 <attn_pfd+0x188>
	s_mov_b32 s28, exec_lo                                     // 000000000164: BE9C007E
	v_cmpx_lt_i32_e32 9, v0                                    // 000000000168: 7D820089
	s_xor_b32 s28, exec_lo, s28                                // 00000000016C: 8D1C1C7E
	s_mov_b32 s29, 31                                          // 000000000170: BE9D009F
	s_or_saveexec_b32 s28, s28                                 // 000000000174: BE9C221C
	v_mov_b32_e32 v1, s29                                      // 000000000178: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s28                            // 00000000017C: 8D7E1C7E
	v_mov_b32_e32 v1, 18                                       // 000000000180: 7E020292
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000184: 8C7E1C7E
	s_and_not1_saveexec_b32 s26, s26                           // 000000000188: BE9A301A
	s_cbranch_execz 9                                          // 00000000018C: BFA50009 <attn_pfd+0x1b4>
	s_mov_b32 s28, exec_lo                                     // 000000000190: BE9C007E
	v_cmpx_lt_i32_e32 7, v0                                    // 000000000194: 7D820087
	s_xor_b32 s28, exec_lo, s28                                // 000000000198: 8D1C1C7E
	s_mov_b32 s29, 6                                           // 00000000019C: BE9D0086
	s_or_saveexec_b32 s28, s28                                 // 0000000001A0: BE9C221C
	v_mov_b32_e32 v1, s29                                      // 0000000001A4: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s28                            // 0000000001A8: 8D7E1C7E
	v_mov_b32_e32 v1, -6                                       // 0000000001AC: 7E0202C6
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000001B0: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000001B4: BF870009
	s_or_b32 exec_lo, exec_lo, s26                             // 0000000001B8: 8C7E1A7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 0000000001BC: BF870499
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000001C0: 8C7E057E
	s_mov_b32 s5, exec_lo                                      // 0000000001C4: BE85007E
	s_and_not1_saveexec_b32 s4, s4                             // 0000000001C8: BE843004
	s_cbranch_execz 63                                         // 0000000001CC: BFA5003F <attn_pfd+0x2cc>
	s_mov_b32 s26, s5                                          // 0000000001D0: BE9A0005
	s_mov_b32 s1, exec_lo                                      // 0000000001D4: BE81007E
	v_cmpx_lt_i32_e32 2, v0                                    // 0000000001D8: 7D820082
	s_xor_b32 s1, exec_lo, s1                                  // 0000000001DC: 8D01017E
	s_cbranch_execz 27                                         // 0000000001E0: BFA5001B <attn_pfd+0x250>
	s_mov_b32 s26, exec_lo                                     // 0000000001E4: BE9A007E
	v_cmpx_lt_i32_e32 4, v0                                    // 0000000001E8: 7D820084
	s_xor_b32 s26, exec_lo, s26                                // 0000000001EC: 8D1A1A7E
	s_cbranch_execz 9                                          // 0000000001F0: BFA50009 <attn_pfd+0x218>
	s_mov_b32 s28, exec_lo                                     // 0000000001F4: BE9C007E
	v_cmpx_lt_i32_e32 5, v0                                    // 0000000001F8: 7D820085
	s_xor_b32 s28, exec_lo, s28                                // 0000000001FC: 8D1C1C7E
	s_movk_i32 s29, 0xffee                                     // 000000000200: B01DFFEE
	s_or_saveexec_b32 s28, s28                                 // 000000000204: BE9C221C
	v_mov_b32_e32 v1, s29                                      // 000000000208: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s28                            // 00000000020C: 8D7E1C7E
	v_not_b32_e32 v1, 30                                       // 000000000210: 7E026E9E
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000214: 8C7E1C7E
	s_and_not1_saveexec_b32 s26, s26                           // 000000000218: BE9A301A
	s_cbranch_execz 9                                          // 00000000021C: BFA50009 <attn_pfd+0x244>
	s_mov_b32 s28, exec_lo                                     // 000000000220: BE9C007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000224: 7D820083
	s_xor_b32 s28, exec_lo, s28                                // 000000000228: 8D1C1C7E
	s_movk_i32 s29, 0xffd4                                     // 00000000022C: B01DFFD4
	s_or_saveexec_b32 s28, s28                                 // 000000000230: BE9C221C
	v_mov_b32_e32 v1, s29                                      // 000000000234: 7E02021D
	s_xor_b32 exec_lo, exec_lo, s28                            // 000000000238: 8D7E1C7E
	v_not_b32_e32 v1, 57                                       // 00000000023C: 7E026EB9
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000240: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000244: BF870499
	s_or_b32 exec_lo, exec_lo, s26                             // 000000000248: 8C7E1A7E
	s_or_b32 s26, s5, exec_lo                                  // 00000000024C: 8C1A7E05
	s_or_saveexec_b32 s1, s1                                   // 000000000250: BE812201
	s_mov_b32 s28, 0                                           // 000000000254: BE9C0080
	s_xor_b32 exec_lo, exec_lo, s1                             // 000000000258: 8D7E017E
	s_cbranch_execz 21                                         // 00000000025C: BFA50015 <attn_pfd+0x2b4>
	s_mov_b32 s29, -1                                          // 000000000260: BE9D00C1
	s_mov_b32 s30, s26                                         // 000000000264: BE9E001A
	s_mov_b32 s28, exec_lo                                     // 000000000268: BE9C007E
	v_cmpx_lt_i32_e32 0, v0                                    // 00000000026C: 7D820080
	s_cbranch_execz 10                                         // 000000000270: BFA5000A <attn_pfd+0x29c>
	v_mov_b32_e32 v1, 0xffffffa0                               // 000000000274: 7E0202FF FFFFFFA0
	s_mov_b32 s29, exec_lo                                     // 00000000027C: BE9D007E
	v_cmpx_lt_i32_e32 1, v0                                    // 000000000280: 7D820081
	v_mov_b32_e32 v1, 0xffffffb5                               // 000000000284: 7E0202FF FFFFFFB5
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000028C: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000290: BF870009
	s_xor_b32 s29, exec_lo, -1                                 // 000000000294: 8D1DC17E
	s_or_b32 s30, s26, exec_lo                                 // 000000000298: 8C1E7E1A
	s_or_b32 exec_lo, exec_lo, s28                             // 00000000029C: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000002A0: BF870009
	s_and_not1_b32 s26, s26, exec_lo                           // 0000000002A4: 911A7E1A
	s_and_b32 s30, s30, exec_lo                                // 0000000002A8: 8B1E7E1E
	s_and_b32 s28, s29, exec_lo                                // 0000000002AC: 8B1C7E1D
	s_or_b32 s26, s26, s30                                     // 0000000002B0: 8C1A1E1A
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000002B4: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000002B8: BF870009
	s_and_not1_b32 s5, s5, exec_lo                             // 0000000002BC: 91057E05
	s_and_b32 s26, s26, exec_lo                                // 0000000002C0: 8B1A7E1A
	s_and_b32 s1, s28, exec_lo                                 // 0000000002C4: 8B017E1C
	s_or_b32 s5, s5, s26                                       // 0000000002C8: 8C051A05
	s_or_b32 exec_lo, exec_lo, s4                              // 0000000002CC: 8C7E047E
	s_and_saveexec_b32 s4, s5                                  // 0000000002D0: BE842005
	s_cbranch_execz 132                                        // 0000000002D4: BFA50084 <attn_pfd+0x4e8>
	v_lshlrev_b32_e32 v2, 2, v0                                // 0000000002D8: 30040082
	s_mov_b32 s5, exec_lo                                      // 0000000002DC: BE85007E
	ds_store_b32 v2, v1 offset:20800                           // 0000000002E0: D8345140 00000102
	v_cmpx_lt_i32_e32 7, v0                                    // 0000000002E8: 7D820087
	s_xor_b32 s5, exec_lo, s5                                  // 0000000002EC: 8D05057E
	s_cbranch_execz 65                                         // 0000000002F0: BFA50041 <attn_pfd+0x3f8>
	s_mov_b32 s26, exec_lo                                     // 0000000002F4: BE9A007E
	v_cmpx_lt_i32_e32 10, v0                                   // 0000000002F8: 7D82008A
	s_xor_b32 s26, exec_lo, s26                                // 0000000002FC: 8D1A1A7E
	s_cbranch_execz 38                                         // 000000000300: BFA50026 <attn_pfd+0x39c>
	s_mov_b32 s28, exec_lo                                     // 000000000304: BE9C007E
	v_cmpx_lt_i32_e32 12, v0                                   // 000000000308: 7D82008C
	s_xor_b32 s28, exec_lo, s28                                // 00000000030C: 8D1C1C7E
	s_cbranch_execz 19                                         // 000000000310: BFA50013 <attn_pfd+0x360>
	s_mov_b32 s29, exec_lo                                     // 000000000314: BE9D007E
	v_cmpx_lt_i32_e32 13, v0                                   // 000000000318: 7D82008D
	s_xor_b32 s29, exec_lo, s29                                // 00000000031C: 8D1D1D7E
	s_cbranch_execz 11                                         // 000000000320: BFA5000B <attn_pfd+0x350>
	s_mov_b32 s30, exec_lo                                     // 000000000324: BE9E007E
	v_cmpx_ne_u32_e32 14, v0                                   // 000000000328: 7D9A008E
	s_xor_b32 s30, exec_lo, s30                                // 00000000032C: 8D1E1E7E
	s_mov_b32 s31, 0x402ee2bf                                  // 000000000330: BE9F00FF 402EE2BF
	s_or_saveexec_b32 s30, s30                                 // 000000000338: BE9E221E
	v_mov_b32_e32 v2, s31                                      // 00000000033C: 7E04021F
	s_xor_b32 exec_lo, exec_lo, s30                            // 000000000340: 8D7E1E7E
	v_mov_b32_e32 v2, 0x40046ac7                               // 000000000344: 7E0402FF 40046AC7
	s_or_b32 exec_lo, exec_lo, s30                             // 00000000034C: 8C7E1E7E
	s_and_not1_saveexec_b32 s29, s29                           // 000000000350: BE9D301D
	v_mov_b32_e32 v2, 0x3fcf1c25                               // 000000000354: 7E0402FF 3FCF1C25
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000035C: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 000000000360: BE9C301C
	s_cbranch_execz 11                                         // 000000000364: BFA5000B <attn_pfd+0x394>
	s_mov_b32 s29, exec_lo                                     // 000000000368: BE9D007E
	v_cmpx_lt_i32_e32 11, v0                                   // 00000000036C: 7D82008B
	s_xor_b32 s29, exec_lo, s29                                // 000000000370: 8D1D1D7E
	s_mov_b32 s30, 0x3fa0cc2f                                  // 000000000374: BE9E00FF 3FA0CC2F
	s_or_saveexec_b32 s29, s29                                 // 00000000037C: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 000000000380: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 000000000384: 8D7E1D7E
	v_mov_b32_e32 v2, 0x3f713d3a                               // 000000000388: 7E0402FF 3F713D3A
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000390: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000394: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000398: 8C7E1C7E
	s_and_not1_saveexec_b32 s26, s26                           // 00000000039C: BE9A301A
	s_cbranch_execz 19                                         // 0000000003A0: BFA50013 <attn_pfd+0x3f0>
	s_mov_b32 s28, exec_lo                                     // 0000000003A4: BE9C007E
	v_cmpx_lt_i32_e32 8, v0                                    // 0000000003A8: 7D820088
	s_xor_b32 s28, exec_lo, s28                                // 0000000003AC: 8D1C1C7E
	s_cbranch_execz 11                                         // 0000000003B0: BFA5000B <attn_pfd+0x3e0>
	s_mov_b32 s29, exec_lo                                     // 0000000003B4: BE9D007E
	v_cmpx_lt_i32_e32 9, v0                                    // 0000000003B8: 7D820089
	s_xor_b32 s29, exec_lo, s29                                // 0000000003BC: 8D1D1D7E
	s_mov_b32 s30, 0x3f28215d                                  // 0000000003C0: BE9E00FF 3F28215D
	s_or_saveexec_b32 s29, s29                                 // 0000000003C8: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 0000000003CC: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 0000000003D0: 8D7E1D7E
	v_mov_b32_e32 v2, 0x3ec6ae44                               // 0000000003D4: 7E0402FF 3EC6AE44
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000003DC: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 0000000003E0: BE9C301C
	v_mov_b32_e32 v2, 0x3e0379fb                               // 0000000003E4: 7E0402FF 3E0379FB
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000003EC: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000003F0: BF870009
	s_or_b32 exec_lo, exec_lo, s26                             // 0000000003F4: 8C7E1A7E
	s_and_not1_saveexec_b32 s5, s5                             // 0000000003F8: BE853005
	s_cbranch_execz 56                                         // 0000000003FC: BFA50038 <attn_pfd+0x4e0>
	s_mov_b32 s26, exec_lo                                     // 000000000400: BE9A007E
	v_cmpx_lt_i32_e32 3, v0                                    // 000000000404: 7D820083
	s_xor_b32 s26, exec_lo, s26                                // 000000000408: 8D1A1A7E
	s_cbranch_execz 30                                         // 00000000040C: BFA5001E <attn_pfd+0x488>
	s_mov_b32 s28, exec_lo                                     // 000000000410: BE9C007E
	v_cmpx_lt_i32_e32 5, v0                                    // 000000000414: 7D820085
	s_xor_b32 s28, exec_lo, s28                                // 000000000418: 8D1C1C7E
	s_cbranch_execz 11                                         // 00000000041C: BFA5000B <attn_pfd+0x44c>
	s_mov_b32 s29, exec_lo                                     // 000000000420: BE9D007E
	v_cmpx_lt_i32_e32 6, v0                                    // 000000000424: 7D820086
	s_xor_b32 s29, exec_lo, s29                                // 000000000428: 8D1D1D7E
	s_mov_b32 s30, 0xbe0379fb                                  // 00000000042C: BE9E00FF BE0379FB
	s_or_saveexec_b32 s29, s29                                 // 000000000434: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 000000000438: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 00000000043C: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbec6ae44                               // 000000000440: 7E0402FF BEC6AE44
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000448: 8C7E1D7E
	s_and_not1_saveexec_b32 s28, s28                           // 00000000044C: BE9C301C
	s_cbranch_execz 11                                         // 000000000450: BFA5000B <attn_pfd+0x480>
	s_mov_b32 s29, exec_lo                                     // 000000000454: BE9D007E
	v_cmpx_lt_i32_e32 4, v0                                    // 000000000458: 7D820084
	s_xor_b32 s29, exec_lo, s29                                // 00000000045C: 8D1D1D7E
	s_mov_b32 s30, 0xbf28215d                                  // 000000000460: BE9E00FF BF28215D
	s_or_saveexec_b32 s29, s29                                 // 000000000468: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 00000000046C: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 000000000470: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbf713d3a                               // 000000000474: 7E0402FF BF713D3A
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000047C: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000480: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 000000000484: 8C7E1C7E
	s_and_not1_saveexec_b32 s26, s26                           // 000000000488: BE9A301A
	s_cbranch_execz 18                                         // 00000000048C: BFA50012 <attn_pfd+0x4d8>
	v_mov_b32_e32 v2, 0xc0046ac7                               // 000000000490: 7E0402FF C0046AC7
	s_mov_b32 s28, exec_lo                                     // 000000000498: BE9C007E
	v_cmpx_lt_i32_e32 1, v0                                    // 00000000049C: 7D820081
	s_cbranch_execz 11                                         // 0000000004A0: BFA5000B <attn_pfd+0x4d0>
	s_mov_b32 s29, exec_lo                                     // 0000000004A4: BE9D007E
	v_cmpx_lt_i32_e32 2, v0                                    // 0000000004A8: 7D820082
	s_xor_b32 s29, exec_lo, s29                                // 0000000004AC: 8D1D1D7E
	s_mov_b32 s30, 0xbfa0cc2f                                  // 0000000004B0: BE9E00FF BFA0CC2F
	s_or_saveexec_b32 s29, s29                                 // 0000000004B8: BE9D221D
	v_mov_b32_e32 v2, s30                                      // 0000000004BC: 7E04021E
	s_xor_b32 exec_lo, exec_lo, s29                            // 0000000004C0: 8D7E1D7E
	v_mov_b32_e32 v2, 0xbfcf1c25                               // 0000000004C4: 7E0402FF BFCF1C25
	s_or_b32 exec_lo, exec_lo, s29                             // 0000000004CC: 8C7E1D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004D0: BF870009
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000004D4: 8C7E1C7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004D8: BF870009
	s_or_b32 exec_lo, exec_lo, s26                             // 0000000004DC: 8C7E1A7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004E0: BF870009
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000004E4: 8C7E057E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000004E8: BF870009
	s_or_b32 exec_lo, exec_lo, s4                              // 0000000004EC: 8C7E047E
	s_and_saveexec_b32 s4, s1                                  // 0000000004F0: BE842001
	v_mov_b32_e32 v1, 0xffffff81                               // 0000000004F4: 7E0202FF FFFFFF81
	v_dual_mov_b32 v3, 0 :: v_dual_mov_b32 v2, 0xc02ee2bf      // 0000000004FC: CA100080 030200FF C02EE2BF
	ds_store_b32 v3, v1 offset:20800                           // 000000000508: D8345140 00000103
	s_or_b32 exec_lo, exec_lo, s4                              // 000000000510: 8C7E047E
	v_lshlrev_b32_e32 v1, 2, v0                                // 000000000514: 30020082
	ds_store_b32 v1, v2 offset:20736                           // 000000000518: D8345100 00000201
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000520: 8C7E007E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000524: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000000528: BE81007E
	v_cmpx_gt_u32_e32 0x100, v0                                // 00000000052C: 7D9800FF 00000100
	s_cbranch_execz 139                                        // 000000000534: BFA5008B <attn_pfd+0x764>
	v_sub_nc_u32_e64 v1, 64, v0 clamp                          // 000000000538: D5268001 000200C0
	v_cmp_gt_u32_e32 vcc_lo, 64, v0                            // 000000000540: 7C9800C0
	v_mov_b32_e32 v6, 0                                        // 000000000544: 7E0C0280
	s_mov_b32 s5, 0                                            // 000000000548: BE850080
	s_mov_b32 s4, exec_lo                                      // 00000000054C: BE84007E
	v_subrev_co_ci_u32_e64 v1, s0, 0, v1, vcc_lo               // 000000000550: D5220001 01AA0280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000558: BF870091
	v_mul_hi_u32 v1, 0xaaaaaaab, v1                            // 00000000055C: D72D0001 000202FF AAAAAAAB
	v_lshrrev_b32_e32 v1, 7, v1                                // 000000000568: 32020287
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000056C: BF870091
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v1, vcc_lo              // 000000000570: 40020280
	v_lshrrev_b32_e32 v2, 1, v1                                // 000000000574: 32040281
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000578: BF870001
	v_add_nc_u32_e32 v2, 1, v2                                 // 00000000057C: 4A040481
	v_cmpx_lt_u32_e32 5, v1                                    // 000000000580: 7D920285
	s_cbranch_execz 74                                         // 000000000584: BFA5004A <attn_pfd+0x6b0>
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000588: BF870002
	v_and_b32_e32 v3, 0x3fffffc, v2                            // 00000000058C: 360604FF 03FFFFFC
	v_or_b32_e32 v4, 0x4e00, v0                                // 000000000594: 380800FF 00004E00
	v_mov_b32_e32 v5, 0                                        // 00000000059C: 7E0A0280
	s_mov_b32 s26, 0                                           // 0000000005A0: BE9A0080
	s_branch 13                                                // 0000000005A4: BFA0000D <attn_pfd+0x5dc>
	s_or_b32 exec_lo, exec_lo, s0                              // 0000000005A8: 8C7E007E
	s_add_i32 s0, s26, 8                                       // 0000000005AC: 8100881A
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 0000000005B0: BF870139
	v_dual_mov_b32 v6, s0 :: v_dual_add_nc_u32 v3, -4, v3      // 0000000005B4: CA200000 060206C4
	v_add_nc_u32_e32 v4, 0x600, v4                             // 0000000005BC: 4A0808FF 00000600
	s_add_i32 s26, s28, 2                                      // 0000000005C4: 811A821C
	v_cmp_eq_u32_e32 vcc_lo, 0, v3                             // 0000000005C8: 7C940680
	s_or_b32 s5, vcc_lo, s5                                    // 0000000005CC: 8C05056A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000005D0: BF870009
	s_and_not1_b32 exec_lo, exec_lo, s5                        // 0000000005D4: 917E057E
	s_cbranch_execz 52                                         // 0000000005D8: BFA50034 <attn_pfd+0x6ac>
	s_or_b32 s0, s26, 1                                        // 0000000005DC: 8C00811A
	s_mov_b32 s28, exec_lo                                     // 0000000005E0: BE9C007E
	v_cmp_le_u32_e32 vcc_lo, s0, v1                            // 0000000005E4: 7C960200
	v_cmpx_le_u32_e64 s26, v1                                  // 0000000005E8: D4CB007E 0002021A
	ds_store_b8 v4, v5                                         // 0000000005F0: D8780000 00000504
	s_or_b32 exec_lo, exec_lo, s28                             // 0000000005F8: 8C7E1C7E
	s_and_saveexec_b32 s0, vcc_lo                              // 0000000005FC: BE80206A
	ds_store_b8 v4, v5 offset:192                              // 000000000600: D87800C0 00000504
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000608: 8C7E007E
	s_add_i32 s0, s26, 3                                       // 00000000060C: 8100831A
	s_add_i32 s28, s26, 2                                      // 000000000610: 811C821A
	s_mov_b32 s29, exec_lo                                     // 000000000614: BE9D007E
	v_cmp_le_u32_e32 vcc_lo, s0, v1                            // 000000000618: 7C960200
	v_cmpx_le_u32_e64 s28, v1                                  // 00000000061C: D4CB007E 0002021C
	ds_store_b8 v4, v5 offset:384                              // 000000000624: D8780180 00000504
	s_or_b32 exec_lo, exec_lo, s29                             // 00000000062C: 8C7E1D7E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000630: BE80206A
	ds_store_b8 v4, v5 offset:576                              // 000000000634: D8780240 00000504
	s_or_b32 exec_lo, exec_lo, s0                              // 00000000063C: 8C7E007E
	s_add_i32 s0, s28, 3                                       // 000000000640: 8100831C
	s_add_i32 s28, s28, 2                                      // 000000000644: 811C821C
	s_mov_b32 s29, exec_lo                                     // 000000000648: BE9D007E
	v_cmp_le_u32_e32 vcc_lo, s0, v1                            // 00000000064C: 7C960200
	v_cmpx_le_u32_e64 s28, v1                                  // 000000000650: D4CB007E 0002021C
	ds_store_b8 v4, v5 offset:768                              // 000000000658: D8780300 00000504
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000660: 8C7E1D7E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000664: BE80206A
	ds_store_b8 v4, v5 offset:960                              // 000000000668: D87803C0 00000504
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000670: 8C7E007E
	s_add_i32 s0, s28, 3                                       // 000000000674: 8100831C
	s_add_i32 s28, s28, 2                                      // 000000000678: 811C821C
	s_mov_b32 s29, exec_lo                                     // 00000000067C: BE9D007E
	v_cmp_le_u32_e32 vcc_lo, s0, v1                            // 000000000680: 7C960200
	v_cmpx_le_u32_e64 s28, v1                                  // 000000000684: D4CB007E 0002021C
	ds_store_b8 v4, v5 offset:1152                             // 00000000068C: D8780480 00000504
	s_or_b32 exec_lo, exec_lo, s29                             // 000000000694: 8C7E1D7E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000698: BE80206A
	s_cbranch_execz 65474                                      // 00000000069C: BFA5FFC2 <attn_pfd+0x5a8>
	ds_store_b8 v4, v5 offset:1344                             // 0000000006A0: D8780540 00000504
	s_branch 65471                                             // 0000000006A8: BFA0FFBF <attn_pfd+0x5a8>
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000006AC: 8C7E057E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000006B0: BF870119
	s_or_b32 exec_lo, exec_lo, s4                              // 0000000006B4: 8C7E047E
	v_and_b32_e32 v2, 3, v2                                    // 0000000006B8: 36040483
	s_mov_b32 s4, 0                                            // 0000000006BC: BE840080
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000006C0: BF870001
	v_cmp_ne_u32_e32 vcc_lo, 0, v2                             // 0000000006C4: 7C9A0480
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000006C8: 8B7E6A7E
	s_cbranch_execz 37                                         // 0000000006CC: BFA50025 <attn_pfd+0x764>
	v_mul_lo_u32 v3, 0xc0, v6                                  // 0000000006D0: D72C0003 00020CFF 000000C0
	v_mul_u32_u24_e32 v2, 0xc0, v2                             // 0000000006DC: 160404FF 000000C0
	v_mov_b32_e32 v4, 0                                        // 0000000006E4: 7E080280
	s_delay_alu instid0(VALU_DEP_3)                            // 0000000006E8: BF870003
	v_add3_u32 v3, v0, v3, 0x4e00                              // 0000000006EC: D6550003 03FE0700 00004E00
	s_branch 12                                                // 0000000006F8: BFA0000C <attn_pfd+0x72c>
	s_nop 0                                                    // 0000000006FC: BF800000
	s_or_b32 exec_lo, exec_lo, s0                              // 000000000700: 8C7E007E
	v_add_nc_u32_e32 v2, 0xffffff40, v2                        // 000000000704: 4A0404FF FFFFFF40
	v_add_nc_u32_e32 v6, 2, v6                                 // 00000000070C: 4A0C0C82
	v_add_nc_u32_e32 v3, 0x180, v3                             // 000000000710: 4A0606FF 00000180
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000000718: BF8704A3
	v_cmp_eq_u32_e32 vcc_lo, 0, v2                             // 00000000071C: 7C940480
	s_or_b32 s4, vcc_lo, s4                                    // 000000000720: 8C04046A
	s_and_not1_b32 exec_lo, exec_lo, s4                        // 000000000724: 917E047E
	s_cbranch_execz 14                                         // 000000000728: BFA5000E <attn_pfd+0x764>
	v_or_b32_e32 v5, 1, v6                                     // 00000000072C: 380A0C81
	s_mov_b32 s5, exec_lo                                      // 000000000730: BE85007E
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000734: BF870001
	v_cmp_le_u32_e32 vcc_lo, v5, v1                            // 000000000738: 7C960305
	v_cmpx_le_u32_e64 v6, v1                                   // 00000000073C: D4CB007E 00020306
	ds_store_b8 v3, v4                                         // 000000000744: D8780000 00000403
	s_or_b32 exec_lo, exec_lo, s5                              // 00000000074C: 8C7E057E
	s_and_saveexec_b32 s0, vcc_lo                              // 000000000750: BE80206A
	s_cbranch_execz 65514                                      // 000000000754: BFA5FFEA <attn_pfd+0x700>
	ds_store_b8 v3, v4 offset:192                              // 000000000758: D87800C0 00000403
	s_branch 65511                                             // 000000000760: BFA0FFE7 <attn_pfd+0x700>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000764: 8C7E017E
	s_and_b32 s0, s3, 3                                        // 000000000768: 8B008303
	s_mov_b32 s1, exec_lo                                      // 00000000076C: BE81007E
	s_mul_i32 s26, s0, 6                                       // 000000000770: 961A8600
	v_cmpx_gt_u32_e32 48, v0                                   // 000000000774: 7D9800B0
	s_cbranch_execz 54                                         // 000000000778: BFA50036 <attn_pfd+0x854>
	v_mul_lo_u16 v1, 0xab, v0                                  // 00000000077C: D7050001 000200FF 000000AB
	v_mov_b32_e32 v3, 0                                        // 000000000788: 7E060280
	s_mov_b32 s3, exec_lo                                      // 00000000078C: BE83007E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000790: BF870092
	v_lshrrev_b16 v2, 10, v1                                   // 000000000794: D7390002 0002028A
	v_dual_mov_b32 v1, 0 :: v_dual_and_b32 v4, 0xffff, v2      // 00000000079C: CA240080 010404FF 0000FFFF
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000007A8: BF870001
	v_cmpx_gt_u32_e64 s27, v4                                  // 0000000007AC: D4CC007E 0002081B
	s_cbranch_execz 31                                         // 0000000007B4: BFA5001F <attn_pfd+0x834>
	v_add_nc_u32_e32 v3, s7, v4                                // 0000000007B8: 4A060807
	v_mad_u16 v4, v2, -6, v0                                   // 0000000007BC: D6410004 04018D02
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000007C4: BF870112
	v_mad_u64_u32 v[1:2], null, v3, 24, s[26:27]               // 0000000007C8: D6FE7C01 00693103
	v_and_b32_e32 v2, 0xff, v4                                 // 0000000007D0: 360408FF 000000FF
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000007D8: BF870091
	v_add_co_u32 v1, s4, v1, v2                                // 0000000007DC: D7000401 00020501
	v_add_co_ci_u32_e64 v2, null, 0, 0, s4                     // 0000000007E4: D5207C02 00110080
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 0000000007EC: BF8700A1
	v_lshlrev_b64 v[1:2], 2, v[1:2]                            // 0000000007F0: D73C0001 00020282
	s_waitcnt lgkmcnt(0)                                       // 0000000007F8: BF89FC07
	v_add_co_u32 v3, vcc_lo, s16, v1                           // 0000000007FC: D7006A03 00020210
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000804: BF870002
	v_add_co_ci_u32_e32 v4, vcc_lo, s17, v2, vcc_lo            // 000000000808: 40080411
	v_add_co_u32 v1, vcc_lo, s20, v1                           // 00000000080C: D7006A01 00020214
	v_add_co_ci_u32_e32 v2, vcc_lo, s21, v2, vcc_lo            // 000000000814: 40040415
	global_load_b32 v4, v[3:4], off                            // 000000000818: DC520000 047C0003
	global_load_b32 v3, v[1:2], off                            // 000000000820: DC520000 037C0001
	s_waitcnt vmcnt(1)                                         // 000000000828: BF8907F7
	v_mul_f32_e32 v1, 0x3cb04346, v4                           // 00000000082C: 100208FF 3CB04346
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000834: 8C7E037E
	v_lshlrev_b32_e32 v2, 2, v0                                // 000000000838: 30040082
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000083C: BF870001
	v_add_nc_u32_e32 v2, 0x4c00, v2                            // 000000000840: 4A0404FF 00004C00
	s_waitcnt vmcnt(0)                                         // 000000000848: BF8903F7
	ds_store_2addr_b32 v2, v1, v3 offset0:192 offset1:240      // 00000000084C: D838F0C0 00030102
	s_or_b32 exec_lo, exec_lo, s1                              // 000000000854: 8C7E017E
	v_mbcnt_lo_u32_b32 v129, -1, 0                             // 000000000858: D71F0081 000100C1
	v_lshrrev_b32_e32 v1, 2, v0                                // 000000000860: 32020082
	s_waitcnt lgkmcnt(0)                                       // 000000000864: BF89FC07
	s_barrier                                                  // 000000000868: BFBD0000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000086C: BF870112
	v_lshrrev_b32_e32 v2, 4, v129                              // 000000000870: 32050284
	v_and_b32_e32 v65, 48, v1                                  // 000000000874: 368202B0
	s_add_i32 s1, s25, 0x100                                   // 000000000878: 8101FF19 00000100
	v_lshrrev_b32_e32 v131, 5, v0                              // 000000000880: 33060085
	s_mul_i32 s0, s0, 0x20d0e10                                // 000000000884: 9600FF00 020D0E10
	s_min_u32 s28, s1, s2                                      // 00000000088C: 899C0201
	v_or_b32_e32 v121, v2, v65                                 // 000000000890: 38F28302
	v_lshlrev_b32_e32 v2, 2, v129                              // 000000000894: 30050282
	s_add_u32 s2, s22, s0                                      // 000000000898: 80020016
	s_addc_u32 s3, s23, 0                                      // 00000000089C: 82038017
	v_cmp_gt_u32_e32 vcc_lo, 0x200, v0                         // 0000000008A0: 7C9800FF 00000200
	v_lshlrev_b32_e32 v1, 2, v121                              // 0000000008A8: 3002F282
	v_add_co_u32 v132, s0, s2, v2                              // 0000000008AC: D7000084 00020402
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000008B4: BF870191
	v_add_co_ci_u32_e64 v134, null, s3, 0, s0                  // 0000000008B8: D5207C86 00010003
	v_add_nc_u32_e32 v1, 0x4c00, v1                            // 0000000008C0: 4A0202FF 00004C00
	s_add_u32 s0, s2, 0x12607e0                                // 0000000008C8: 8000FF02 012607E0
	s_addc_u32 s1, s3, 0                                       // 0000000008D0: 82018003
	v_add_co_u32 v135, s0, s0, v2                              // 0000000008D4: D7000087 00020400
	ds_load_2addr_b32 v[99:100], v1 offset0:192 offset1:194    // 0000000008DC: D8DCC2C0 63000001
	ds_load_2addr_b32 v[101:102], v1 offset0:196 offset1:198   // 0000000008E4: D8DCC6C4 65000001
	ds_load_2addr_b32 v[103:104], v1 offset0:200 offset1:202   // 0000000008EC: D8DCCAC8 67000001
	ds_load_2addr_b32 v[105:106], v1 offset0:204 offset1:206   // 0000000008F4: D8DCCECC 69000001
	ds_load_2addr_b32 v[107:108], v1 offset0:240 offset1:242   // 0000000008FC: D8DCF2F0 6B000001
	ds_load_2addr_b32 v[109:110], v1 offset0:244 offset1:246   // 000000000904: D8DCF6F4 6D000001
	ds_load_2addr_b32 v[111:112], v1 offset0:248 offset1:250   // 00000000090C: D8DCFAF8 6F000001
	ds_load_2addr_b32 v[113:114], v1 offset0:252 offset1:254   // 000000000914: D8DCFEFC 71000001
	v_or_b32_e32 v1, s25, v131                                 // 00000000091C: 38030619
	v_add_co_ci_u32_e64 v136, null, s1, 0, s0                  // 000000000920: D5207C88 00010001
	s_add_u32 s29, s2, 0xe00600                                // 000000000928: 801DFF02 00E00600
	s_addc_u32 s30, s3, 0                                      // 000000000930: 821E8003
	s_delay_alu instid0(VALU_DEP_2)                            // 000000000934: BF870002
	v_cmp_gt_u32_e64 s1, s28, v1                               // 000000000938: D44C0001 0002021C
	s_add_u32 s31, s2, 0x2060de0                               // 000000000940: 801FFF02 02060DE0
	v_cmp_eq_u32_e64 s0, 0, v129                               // 000000000948: D44A0000 00030280
	s_addc_u32 s33, s3, 0                                      // 000000000950: 82218003
	s_add_u32 s34, s2, 0x1180780                               // 000000000954: 8022FF02 01180780
	s_addc_u32 s35, s3, 0                                      // 00000000095C: 82238003
	s_and_b32 s1, vcc_lo, s1                                   // 000000000960: 8B01016A
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000964: BF870009
	s_and_saveexec_b32 s3, s1                                  // 000000000968: BE832001
	s_cbranch_execz 59                                         // 00000000096C: BFA5003B <attn_pfd+0xa5c>
	v_mov_b32_e32 v2, 0                                        // 000000000970: 7E040280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000974: BF870091
	v_lshlrev_b64 v[3:4], 5, v[1:2]                            // 000000000978: D73C0003 00020285
	v_add_co_u32 v3, s1, s29, v3                               // 000000000980: D7000103 0002061D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000988: BF870111
	v_add_co_ci_u32_e64 v9, s1, s30, v4, s1                    // 00000000098C: D5200109 0006081E
	v_add_co_u32 v11, s1, v3, v129                             // 000000000994: D700010B 00030303
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000000099C: BF870111
	v_add_co_ci_u32_e64 v10, s1, 0, v9, s1                     // 0000000009A0: D520010A 00061280
	v_and_b32_e32 v9, -4, v11                                  // 0000000009A8: 361216C4
	v_lshlrev_b64 v[5:6], 7, v[1:2]                            // 0000000009AC: D73C0005 00020287
	v_lshlrev_b64 v[7:8], 2, v[1:2]                            // 0000000009B4: D73C0007 00020282
	flat_load_b32 v9, v[9:10]                                  // 0000000009BC: DC500000 097C0009
	v_add_co_u32 v3, s2, v132, v5                              // 0000000009C4: D7000203 00020B84
	v_add_co_u32 v5, s1, v135, v5                              // 0000000009CC: D7000105 00020B87
	v_add_co_ci_u32_e64 v4, s2, v134, v6, s2                   // 0000000009D4: D5200204 000A0D86
	v_add_co_ci_u32_e64 v6, s1, v136, v6, s1                   // 0000000009DC: D5200106 00060D88
	v_add_co_u32 v7, s1, s31, v7                               // 0000000009E4: D7000107 00020E1F
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000009EC: BF870001
	v_add_co_ci_u32_e64 v8, s1, s33, v8, s1                    // 0000000009F0: D5200108 00061021
	s_clause 0x2                                               // 0000000009F8: BF850002
	global_load_b32 v84, v[3:4], off                           // 0000000009FC: DC520000 547C0003
	global_load_b32 v81, v[5:6], off                           // 000000000A04: DC520000 517C0005
	global_load_b32 v87, v[7:8], off                           // 000000000A0C: DC520000 577C0007
	v_lshlrev_b32_e32 v3, 3, v11                               // 000000000A14: 30061683
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 000000000A18: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000A1C: BF870001
	v_lshrrev_b32_e32 v90, v3, v9                              // 000000000A20: 32B41303
	s_and_saveexec_b32 s2, s0                                  // 000000000A24: BE822000
	s_cbranch_execz 11                                         // 000000000A28: BFA5000B <attn_pfd+0xa58>
	v_lshlrev_b64 v[1:2], 3, v[1:2]                            // 000000000A2C: D73C0001 00020283
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A34: BF870091
	v_add_co_u32 v1, s1, s34, v1                               // 000000000A38: D7000101 00020222
	v_add_co_ci_u32_e64 v2, s1, s35, v2, s1                    // 000000000A40: D5200102 00060423
	global_load_b64 v[93:94], v[1:2], off                      // 000000000A48: DC560000 5D7C0001
	s_waitcnt vmcnt(0)                                         // 000000000A50: BF8903F7
	v_mov_b32_e32 v96, v94                                     // 000000000A54: 7EC0035E
	s_or_b32 exec_lo, exec_lo, s2                              // 000000000A58: 8C7E027E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000000A5C: BF870139
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000A60: 8C7E037E
	v_add_nc_u32_e32 v66, 6, v131                              // 000000000A64: 4A850686
	v_cmp_gt_u32_e64 s1, 0x140, v0                             // 000000000A68: D44C0001 000200FF 00000140
	v_or_b32_e32 v1, s25, v66                                  // 000000000A74: 38028419
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A78: BF870091
	v_cmp_gt_u32_e64 s2, s28, v1                               // 000000000A7C: D44C0002 0002021C
	s_and_b32 s2, s1, s2                                       // 000000000A84: 8B020201
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000A88: BF870009
	s_and_saveexec_b32 s4, s2                                  // 000000000A8C: BE842002
	s_cbranch_execz 60                                         // 000000000A90: BFA5003C <attn_pfd+0xb84>
	v_mov_b32_e32 v2, 0                                        // 000000000A94: 7E040280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000A98: BF870091
	v_lshlrev_b64 v[3:4], 5, v[1:2]                            // 000000000A9C: D73C0003 00020285
	v_add_co_u32 v3, s2, s29, v3                               // 000000000AA4: D7000203 0002061D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000AAC: BF870111
	v_add_co_ci_u32_e64 v9, s2, s30, v4, s2                    // 000000000AB0: D5200209 000A081E
	v_add_co_u32 v11, s2, v3, v129                             // 000000000AB8: D700020B 00030303
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000AC0: BF870111
	v_add_co_ci_u32_e64 v10, s2, 0, v9, s2                     // 000000000AC4: D520020A 000A1280
	v_and_b32_e32 v9, -4, v11                                  // 000000000ACC: 361216C4
	v_lshlrev_b64 v[5:6], 7, v[1:2]                            // 000000000AD0: D73C0005 00020287
	v_lshlrev_b64 v[7:8], 2, v[1:2]                            // 000000000AD8: D73C0007 00020282
	flat_load_b32 v9, v[9:10]                                  // 000000000AE0: DC500000 097C0009
	v_add_co_u32 v3, s3, v132, v5                              // 000000000AE8: D7000303 00020B84
	v_add_co_u32 v5, s2, v135, v5                              // 000000000AF0: D7000205 00020B87
	v_add_co_ci_u32_e64 v4, s3, v134, v6, s3                   // 000000000AF8: D5200304 000E0D86
	v_add_co_ci_u32_e64 v6, s2, v136, v6, s2                   // 000000000B00: D5200206 000A0D88
	v_add_co_u32 v7, s2, s31, v7                               // 000000000B08: D7000207 00020E1F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000B10: BF870001
	v_add_co_ci_u32_e64 v8, s2, s33, v8, s2                    // 000000000B14: D5200208 000A1021
	s_clause 0x2                                               // 000000000B1C: BF850002
	global_load_b32 v85, v[3:4], off                           // 000000000B20: DC520000 557C0003
	global_load_b32 v82, v[5:6], off                           // 000000000B28: DC520000 527C0005
	global_load_b32 v88, v[7:8], off                           // 000000000B30: DC520000 587C0007
	v_lshlrev_b32_e32 v3, 3, v11                               // 000000000B38: 30061683
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 000000000B3C: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000B40: BF870001
	v_lshrrev_b32_e32 v91, v3, v9                              // 000000000B44: 32B61303
	s_and_saveexec_b32 s3, s0                                  // 000000000B48: BE832000
	s_cbranch_execz 12                                         // 000000000B4C: BFA5000C <attn_pfd+0xb80>
	v_lshlrev_b64 v[1:2], 3, v[1:2]                            // 000000000B50: D73C0001 00020283
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000B58: BF870091
	v_add_co_u32 v1, s2, s34, v1                               // 000000000B5C: D7000201 00020222
	v_add_co_ci_u32_e64 v2, s2, s35, v2, s2                    // 000000000B64: D5200202 000A0423
	global_load_b64 v[1:2], v[1:2], off                        // 000000000B6C: DC560000 017C0001
	s_waitcnt vmcnt(0)                                         // 000000000B74: BF8903F7
	v_dual_mov_b32 v94, v1 :: v_dual_mov_b32 v97, v2           // 000000000B78: CA100101 5E600102
	s_or_b32 exec_lo, exec_lo, s3                              // 000000000B80: 8C7E037E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000000B84: BF870139
	s_or_b32 exec_lo, exec_lo, s4                              // 000000000B88: 8C7E047E
	v_add3_u32 v1, v131, s25, 12                               // 000000000B8C: D6550001 02303383
	v_cmp_gt_u32_e64 s2, 0x80, v0                              // 000000000B94: D44C0002 000200FF 00000080
	v_cmp_gt_u32_e64 s3, s28, v1                               // 000000000BA0: D44C0003 0002021C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000000BA8: BF870491
	s_and_b32 s3, s2, s3                                       // 000000000BAC: 8B030302
	s_and_saveexec_b32 s5, s3                                  // 000000000BB0: BE852003
	s_cbranch_execz 60                                         // 000000000BB4: BFA5003C <attn_pfd+0xca8>
	v_mov_b32_e32 v2, 0                                        // 000000000BB8: 7E040280
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000BBC: BF870091
	v_lshlrev_b64 v[3:4], 5, v[1:2]                            // 000000000BC0: D73C0003 00020285
	v_add_co_u32 v3, s3, s29, v3                               // 000000000BC8: D7000303 0002061D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000BD0: BF870111
	v_add_co_ci_u32_e64 v9, s3, s30, v4, s3                    // 000000000BD4: D5200309 000E081E
	v_add_co_u32 v11, s3, v3, v129                             // 000000000BDC: D700030B 00030303
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000000BE4: BF870111
	v_add_co_ci_u32_e64 v10, s3, 0, v9, s3                     // 000000000BE8: D520030A 000E1280
	v_and_b32_e32 v9, -4, v11                                  // 000000000BF0: 361216C4
	v_lshlrev_b64 v[5:6], 7, v[1:2]                            // 000000000BF4: D73C0005 00020287
	v_lshlrev_b64 v[7:8], 2, v[1:2]                            // 000000000BFC: D73C0007 00020282
	flat_load_b32 v9, v[9:10]                                  // 000000000C04: DC500000 097C0009
	v_add_co_u32 v3, s4, v132, v5                              // 000000000C0C: D7000403 00020B84
	v_add_co_u32 v5, s3, v135, v5                              // 000000000C14: D7000305 00020B87
	v_add_co_ci_u32_e64 v4, s4, v134, v6, s4                   // 000000000C1C: D5200404 00120D86
	v_add_co_ci_u32_e64 v6, s3, v136, v6, s3                   // 000000000C24: D5200306 000E0D88
	v_add_co_u32 v7, s3, s31, v7                               // 000000000C2C: D7000307 00020E1F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000C34: BF870001
	v_add_co_ci_u32_e64 v8, s3, s33, v8, s3                    // 000000000C38: D5200308 000E1021
	s_clause 0x2                                               // 000000000C40: BF850002
	global_load_b32 v86, v[3:4], off                           // 000000000C44: DC520000 567C0003
	global_load_b32 v83, v[5:6], off                           // 000000000C4C: DC520000 537C0005
	global_load_b32 v89, v[7:8], off                           // 000000000C54: DC520000 597C0007
	v_lshlrev_b32_e32 v3, 3, v11                               // 000000000C5C: 30061683
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 000000000C60: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 000000000C64: BF870001
	v_lshrrev_b32_e32 v92, v3, v9                              // 000000000C68: 32B81303
	s_and_saveexec_b32 s4, s0                                  // 000000000C6C: BE842000
	s_cbranch_execz 12                                         // 000000000C70: BFA5000C <attn_pfd+0xca4>
	v_lshlrev_b64 v[1:2], 3, v[1:2]                            // 000000000C74: D73C0001 00020283
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000C7C: BF870091
	v_add_co_u32 v1, s3, s34, v1                               // 000000000C80: D7000301 00020222
	v_add_co_ci_u32_e64 v2, s3, s35, v2, s3                    // 000000000C88: D5200302 000E0423
	global_load_b64 v[1:2], v[1:2], off                        // 000000000C90: DC560000 017C0001
	s_waitcnt vmcnt(0)                                         // 000000000C98: BF8903F7
	v_dual_mov_b32 v95, v1 :: v_dual_mov_b32 v98, v2           // 000000000C9C: CA100101 5F620102
	s_or_b32 exec_lo, exec_lo, s4                              // 000000000CA4: 8C7E047E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000000CA8: BF870009
	s_or_b32 exec_lo, exec_lo, s5                              // 000000000CAC: 8C7E057E
	v_dual_mov_b32 v140, 0 :: v_dual_add_nc_u32 v141, 2, v121  // 000000000CB0: CA200080 8C8CF282
	v_dual_mov_b32 v185, 0xf149f2ca :: v_dual_add_nc_u32 v138, 4, v121// 000000000CB8: CA2000FF B98AF284 F149F2CA
	v_dual_mov_b32 v186, 0xf149f2ca :: v_dual_add_nc_u32 v133, 6, v121// 000000000CC4: CA2000FF BA84F286 F149F2CA
	v_dual_mov_b32 v193, 0xf149f2ca :: v_dual_add_nc_u32 v128, 8, v121// 000000000CD0: CA2000FF C180F288 F149F2CA
	v_dual_mov_b32 v191, 0xf149f2ca :: v_dual_add_nc_u32 v126, 10, v121// 000000000CDC: CA2000FF BF7EF28A F149F2CA
	v_dual_mov_b32 v188, 0xf149f2ca :: v_dual_add_nc_u32 v73, 12, v121// 000000000CE8: CA2000FF BC48F28C F149F2CA
	v_dual_mov_b32 v147, 0 :: v_dual_add_nc_u32 v72, 14, v121  // 000000000CF4: CA200080 9348F28E
	v_dual_mov_b32 v189, 0xf149f2ca :: v_dual_and_b32 v144, 15, v129// 000000000CFC: CA2400FF BD91028F F149F2CA
	v_mul_hi_u32 v143, 0x2aaaaaab, v121                        // 000000000D08: D72D008F 0002F2FF 2AAAAAAB
	v_mul_hi_u32 v142, 0x2aaaaaab, v141                        // 000000000D14: D72D008E 00031AFF 2AAAAAAB
	v_mul_hi_u32 v139, 0x2aaaaaab, v138                        // 000000000D20: D72D008B 000314FF 2AAAAAAB
	v_mul_hi_u32 v137, 0x2aaaaaab, v133                        // 000000000D2C: D72D0089 00030AFF 2AAAAAAB
	v_mul_hi_u32 v130, 0x2aaaaaab, v128                        // 000000000D38: D72D0082 000300FF 2AAAAAAB
	v_mul_hi_u32 v127, 0x2aaaaaab, v126                        // 000000000D44: D72D007F 0002FCFF 2AAAAAAB
	v_mul_hi_u32 v125, 0x2aaaaaab, v73                         // 000000000D50: D72D007D 000292FF 2AAAAAAB
	v_mul_hi_u32 v123, 0x2aaaaaab, v72                         // 000000000D5C: D72D007B 000290FF 2AAAAAAB
	s_add_i32 s3, s28, 15                                      // 000000000D68: 81038F1C
	v_dual_mov_b32 v192, 0xf149f2ca :: v_dual_and_b32 v145, 1, v131// 000000000D6C: CA2400FF C0910681 F149F2CA
	s_lshr_b32 s36, s3, 4                                      // 000000000D78: 85248403
	v_cmp_gt_u32_e64 s3, 0xc0, v0                              // 000000000D7C: D44C0003 000200FF 000000C0
	v_dual_mov_b32 v187, 0 :: v_dual_lshlrev_b32 v146, 2, v144 // 000000000D88: CA220080 BB932082
	v_dual_mov_b32 v194, 0xf149f2ca :: v_dual_mov_b32 v195, 0  // 000000000D90: CA1000FF C2C20080 F149F2CA
	v_dual_mov_b32 v148, 0 :: v_dual_mov_b32 v63, v140         // 000000000D9C: CA100080 943E018C
	v_dual_mov_b32 v162, 0 :: v_dual_mov_b32 v61, v140         // 000000000DA4: CA100080 A23C018C
	v_dual_mov_b32 v184, 0 :: v_dual_mov_b32 v59, v140         // 000000000DAC: CA100080 B83A018C
	v_dual_mov_b32 v190, 0 :: v_dual_mov_b32 v57, v140         // 000000000DB4: CA100080 BE38018C
	v_dual_mov_b32 v64, 0 :: v_dual_mov_b32 v55, v140          // 000000000DBC: CA100080 4036018C
	v_mov_b32_e32 v62, v140                                    // 000000000DC4: 7E7C038C
	v_mov_b32_e32 v60, v140                                    // 000000000DC8: 7E78038C
	v_mov_b32_e32 v58, v140                                    // 000000000DCC: 7E74038C
	v_dual_mov_b32 v56, 0 :: v_dual_mov_b32 v53, v140          // 000000000DD0: CA100080 3834018C
	v_mov_b32_e32 v54, v140                                    // 000000000DD8: 7E6C038C
	v_mov_b32_e32 v52, v140                                    // 000000000DDC: 7E68038C
	v_dual_mov_b32 v51, v140 :: v_dual_mov_b32 v48, 0          // 000000000DE0: CA10018C 33300080
	v_mov_b32_e32 v50, v140                                    // 000000000DE8: 7E64038C
	v_dual_mov_b32 v49, v140 :: v_dual_mov_b32 v40, 0          // 000000000DEC: CA10018C 31280080
	v_dual_mov_b32 v47, v140 :: v_dual_mov_b32 v32, 0          // 000000000DF4: CA10018C 2F200080
	v_mov_b32_e32 v46, v140                                    // 000000000DFC: 7E5C038C
	v_dual_mov_b32 v45, v140 :: v_dual_mov_b32 v24, 0          // 000000000E00: CA10018C 2D180080
	v_mov_b32_e32 v44, v140                                    // 000000000E08: 7E58038C
	v_dual_mov_b32 v43, v140 :: v_dual_mov_b32 v16, 0          // 000000000E0C: CA10018C 2B100080
	v_mov_b32_e32 v42, v140                                    // 000000000E14: 7E54038C
	v_dual_mov_b32 v41, v140 :: v_dual_mov_b32 v8, 0           // 000000000E18: CA10018C 29080080
	v_mov_b32_e32 v39, v140                                    // 000000000E20: 7E4E038C
	v_mov_b32_e32 v38, v140                                    // 000000000E24: 7E4C038C
	v_mov_b32_e32 v37, v140                                    // 000000000E28: 7E4A038C
	v_mov_b32_e32 v36, v140                                    // 000000000E2C: 7E48038C
	v_mov_b32_e32 v35, v140                                    // 000000000E30: 7E46038C
	v_mov_b32_e32 v34, v140                                    // 000000000E34: 7E44038C
	v_mov_b32_e32 v33, v140                                    // 000000000E38: 7E42038C
	v_mov_b32_e32 v31, v140                                    // 000000000E3C: 7E3E038C
	v_mov_b32_e32 v30, v140                                    // 000000000E40: 7E3C038C
	v_mov_b32_e32 v29, v140                                    // 000000000E44: 7E3A038C
	v_mov_b32_e32 v28, v140                                    // 000000000E48: 7E38038C
	v_mov_b32_e32 v27, v140                                    // 000000000E4C: 7E36038C
	v_mov_b32_e32 v26, v140                                    // 000000000E50: 7E34038C
	v_mov_b32_e32 v25, v140                                    // 000000000E54: 7E32038C
	v_mov_b32_e32 v23, v140                                    // 000000000E58: 7E2E038C
	v_mov_b32_e32 v22, v140                                    // 000000000E5C: 7E2C038C
	v_mov_b32_e32 v21, v140                                    // 000000000E60: 7E2A038C
	v_mov_b32_e32 v20, v140                                    // 000000000E64: 7E28038C
	v_mov_b32_e32 v19, v140                                    // 000000000E68: 7E26038C
	v_mov_b32_e32 v18, v140                                    // 000000000E6C: 7E24038C
	v_mov_b32_e32 v17, v140                                    // 000000000E70: 7E22038C
	v_mov_b32_e32 v15, v140                                    // 000000000E74: 7E1E038C
	v_mov_b32_e32 v14, v140                                    // 000000000E78: 7E1C038C
	v_mov_b32_e32 v13, v140                                    // 000000000E7C: 7E1A038C
	v_mov_b32_e32 v12, v140                                    // 000000000E80: 7E18038C
	v_mov_b32_e32 v11, v140                                    // 000000000E84: 7E16038C
	v_mov_b32_e32 v10, v140                                    // 000000000E88: 7E14038C
	v_mov_b32_e32 v9, v140                                     // 000000000E8C: 7E12038C
	v_mov_b32_e32 v7, v140                                     // 000000000E90: 7E0E038C
	v_mov_b32_e32 v6, v140                                     // 000000000E94: 7E0C038C
	v_mov_b32_e32 v5, v140                                     // 000000000E98: 7E0A038C
	v_mov_b32_e32 v4, v140                                     // 000000000E9C: 7E08038C
	v_mov_b32_e32 v3, v140                                     // 000000000EA0: 7E06038C
	v_mov_b32_e32 v2, v140                                     // 000000000EA4: 7E04038C
	v_mov_b32_e32 v1, v140                                     // 000000000EA8: 7E02038C
	s_lshl_b32 s37, s24, 4                                     // 000000000EAC: 84258418
	s_mov_b32 s16, 0                                           // 000000000EB0: BE900080
	s_cmp_lt_u32 s37, s36                                      // 000000000EB4: BF0A2425
	s_cbranch_scc0 2771                                        // 000000000EB8: BFA10AD3 <attn_pfd+0x3a08>
	v_or_b32_e32 v1, v144, v65                                 // 000000000EBC: 38028390
	v_dual_mov_b32 v116, 0 :: v_dual_add_nc_u32 v149, s6, v143 // 000000000EC0: CA200080 74951E06
	v_lshlrev_b32_e32 v5, 7, v129                              // 000000000EC8: 300B0287
	v_dual_mov_b32 v191, 0xf149f2ca :: v_dual_add_nc_u32 v150, s6, v142// 000000000ECC: CA2000FF BF971C06 F149F2CA
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000000ED8: BF870224
	v_mul_hi_u32 v2, 0x2aaaaaab, v1                            // 000000000EDC: D72D0002 000202FF 2AAAAAAB
	v_add_nc_u32_e32 v1, s26, v1                               // 000000000EE8: 4A02021A
	v_or_b32_e32 v8, v5, v131                                  // 000000000EEC: 38110705
	v_dual_mov_b32 v182, 0xff0000 :: v_dual_add_nc_u32 v151, s6, v139// 000000000EF0: CA2000FF B6971606 00FF0000
	v_dual_mov_b32 v181, 0xff00 :: v_dual_add_nc_u32 v152, s6, v137// 000000000EFC: CA2000FF B5991206 0000FF00
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_3) | instid1(VALU_DEP_3)// 000000000F08: BF8701C3
	v_dual_mov_b32 v16, v116 :: v_dual_lshlrev_b32 v163, 1, v8 // 000000000F0C: CA220174 10A21081
	v_cmp_gt_u32_e64 s5, s27, v2                               // 000000000F14: D44C0005 0002041B
	v_dual_mov_b32 v8, v116 :: v_dual_add_nc_u32 v153, s6, v130// 000000000F1C: CA200174 08990406
	v_dual_mov_b32 v183, 0xff000000 :: v_dual_add_nc_u32 v154, s6, v127// 000000000F24: CA2000FF B79AFE06 FF000000
	v_cndmask_b32_e64 v3, 0, v2, s5                            // 000000000F30: D5010003 00160480
	v_mul_i32_i24_e32 v2, -6, v2                               // 000000000F38: 120404C6
	v_add_nc_u32_e32 v155, s6, v125                            // 000000000F3C: 4B36FA06
	v_add_nc_u32_e32 v156, s6, v123                            // 000000000F40: 4B38F606
	v_lshlrev_b32_e32 v4, 3, v129                              // 000000000F44: 30090283
	v_add_nc_u32_e32 v3, s7, v3                                // 000000000F48: 4A060607
	v_lshl_add_u32 v157, v131, 9, 0x4200                       // 000000000F4C: D646009D 03FD1383 00004200
	v_dual_mov_b32 v12, v116 :: v_dual_lshlrev_b32 v161, 5, v144// 000000000F58: CA220174 0CA12085
	v_lshlrev_b32_e32 v6, 2, v131                              // 000000000F60: 300D0682
	s_delay_alu instid0(VALU_DEP_4)                            // 000000000F64: BF870004
	v_mul_lo_u32 v3, v3, 24                                    // 000000000F68: D72C0003 00013103
	v_or_b32_e32 v7, 0x2000, v4                                // 000000000F70: 380E08FF 00002000
	v_or_b32_e32 v4, 0x3100, v4                                // 000000000F78: 380808FF 00003100
	s_mov_b64 s[20:21], src_shared_base                        // 000000000F80: BE9401EB
	v_mul_u32_u24_e32 v158, 0x110, v144                        // 000000000F84: 173D20FF 00000110
	v_or_b32_e32 v159, 0x5080, v146                            // 000000000F8C: 393F24FF 00005080
	v_or_b32_e32 v160, 0x50c0, v146                            // 000000000F94: 394124FF 000050C0
	v_cmp_lt_u32_e64 s4, 15, v129                              // 000000000F9C: D4490004 0003028F
	v_add3_u32 v115, v1, v2, v3                                // 000000000FA4: D6550073 040E0501
	v_mul_u32_u24_e32 v3, 0x110, v131                          // 000000000FAC: 160706FF 00000110
	v_lshl_or_b32 v177, v129, 1, v157                          // 000000000FB4: D65600B1 06750381
	v_lshl_or_b32 v178, v145, 12, v161                         // 000000000FBC: D65600B2 06851991
	v_dual_mov_b32 v13, v116 :: v_dual_mov_b32 v194, 0xf149f2ca// 000000000FC4: CA100174 0DC200FF F149F2CA
	v_lshlrev_b64 v[1:2], 8, v[115:116]                        // 000000000FD0: D73C0001 0002E688
	v_dual_mov_b32 v30, v116 :: v_dual_add_nc_u32 v179, v7, v3 // 000000000FD8: CA200174 1EB20707
	v_dual_mov_b32 v193, 0xf149f2ca :: v_dual_add_nc_u32 v180, v4, v3// 000000000FE0: CA2000FF C1B40704 F149F2CA
	v_mov_b32_e32 v3, v116                                     // 000000000FEC: 7E060374
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000000FF0: BF870094
	v_add_co_u32 v10, s6, s18, v1                              // 000000000FF4: D700060A 00020212
	v_add_co_ci_u32_e64 v11, s6, s19, v2, s6                   // 000000000FFC: D520060B 001A0413
	v_add_co_u32 v1, s6, s14, v1                               // 000000001004: D7000601 0002020E
	s_delay_alu instid0(VALU_DEP_3)                            // 00000000100C: BF870003
	v_cndmask_b32_e64 v117, 0x4e00, v10, s5                    // 000000001010: D5010075 001614FF 00004E00
	v_mov_b32_e32 v10, v116                                    // 00000000101C: 7E140374
	v_or_b32_e32 v9, v5, v66                                   // 000000001020: 38128505
	v_add_co_ci_u32_e64 v2, s6, s15, v2, s6                    // 000000001024: D5200602 001A040F
	v_add_lshl_u32 v5, v5, v131, 1                             // 00000000102C: D6470005 02070705
	v_cndmask_b32_e64 v118, s21, v11, s5                       // 000000001034: D5010076 00161615
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 00000000103C: BF870214
	v_dual_mov_b32 v14, v116 :: v_dual_lshlrev_b32 v9, 1, v9   // 000000001040: CA220174 0E081281
	v_cndmask_b32_e64 v120, s21, v2, s5                        // 000000001048: D5010078 00160415
	v_cndmask_b32_e64 v119, 0x4e00, v1, s5                     // 000000001050: D5010077 001602FF 00004E00
	v_dual_mov_b32 v20, v116 :: v_dual_add_nc_u32 v167, 64, v5 // 00000000105C: CA200174 14A60AC0
	s_delay_alu instid0(VALU_DEP_4)                            // 000000001064: BF870004
	v_or_b32_e32 v166, 32, v9                                  // 000000001068: 394C12A0
	v_or_b32_e32 v168, 0x60, v9                                // 00000000106C: 395012FF 00000060
	v_dual_mov_b32 v22, v116 :: v_dual_add_nc_u32 v169, 0x80, v5// 000000001074: CA200174 16A80AFF 00000080
	v_or_b32_e32 v170, 0xa0, v9                                // 000000001080: 395412FF 000000A0
	v_dual_mov_b32 v24, v116 :: v_dual_add_nc_u32 v171, 0xc0, v5// 000000001088: CA200174 18AA0AFF 000000C0
	v_or_b32_e32 v172, 0xe0, v9                                // 000000001094: 395812FF 000000E0
	v_dual_mov_b32 v26, v116 :: v_dual_add_nc_u32 v173, 32, v5 // 00000000109C: CA200174 1AAC0AA0
	v_dual_mov_b32 v9, v116 :: v_dual_add_nc_u32 v174, 0x60, v5// 0000000010A4: CA200174 09AE0AFF 00000060
	v_dual_mov_b32 v28, v116 :: v_dual_add_nc_u32 v175, 0xa0, v5// 0000000010B0: CA200174 1CAE0AFF 000000A0
	v_dual_mov_b32 v11, v116 :: v_dual_add_nc_u32 v176, 0xe0, v5// 0000000010BC: CA200174 0BB00AFF 000000E0
	v_mov_b32_e32 v1, v116                                     // 0000000010C8: 7E020374
	v_mov_b32_e32 v2, v116                                     // 0000000010CC: 7E040374
	v_mov_b32_e32 v4, v116                                     // 0000000010D0: 7E080374
	v_dual_mov_b32 v5, v116 :: v_dual_add_nc_u32 v164, 0x50c0, v6// 0000000010D4: CA200174 05A40CFF 000050C0
	v_mov_b32_e32 v7, v116                                     // 0000000010E0: 7E0E0374
	v_dual_mov_b32 v18, v116 :: v_dual_add_nc_u32 v165, 0x5080, v6// 0000000010E4: CA200174 12A40CFF 00005080
	v_mov_b32_e32 v6, v116                                     // 0000000010F0: 7E0C0374
	v_dual_mov_b32 v15, v116 :: v_dual_mov_b32 v192, 0xf149f2ca// 0000000010F4: CA100174 0FC000FF F149F2CA
	v_dual_mov_b32 v17, v116 :: v_dual_mov_b32 v188, 0xf149f2ca// 000000001100: CA100174 11BC00FF F149F2CA
	v_dual_mov_b32 v19, v116 :: v_dual_mov_b32 v186, 0xf149f2ca// 00000000110C: CA100174 13BA00FF F149F2CA
	v_dual_mov_b32 v21, v116 :: v_dual_mov_b32 v190, 0         // 000000001118: CA100174 15BE0080
	v_dual_mov_b32 v23, v116 :: v_dual_mov_b32 v184, 0         // 000000001120: CA100174 17B80080
	v_dual_mov_b32 v25, v116 :: v_dual_mov_b32 v162, 0         // 000000001128: CA100174 19A20080
	v_dual_mov_b32 v27, v116 :: v_dual_mov_b32 v148, 0         // 000000001130: CA100174 1B940080
	v_dual_mov_b32 v29, v116 :: v_dual_mov_b32 v140, 0         // 000000001138: CA100174 1D8C0080
	v_mov_b32_e32 v31, v116                                    // 000000001140: 7E3E0374
	v_dual_mov_b32 v32, v116 :: v_dual_mov_b32 v189, 0xf149f2ca// 000000001144: CA100174 20BC00FF F149F2CA
	v_mov_b32_e32 v33, v116                                    // 000000001150: 7E420374
	v_dual_mov_b32 v34, v116 :: v_dual_mov_b32 v185, 0xf149f2ca// 000000001154: CA100174 22B800FF F149F2CA
	v_mov_b32_e32 v35, v116                                    // 000000001160: 7E460374
	v_dual_mov_b32 v36, v116 :: v_dual_mov_b32 v195, 0         // 000000001164: CA100174 24C20080
	v_mov_b32_e32 v37, v116                                    // 00000000116C: 7E4A0374
	v_dual_mov_b32 v38, v116 :: v_dual_mov_b32 v187, 0         // 000000001170: CA100174 26BA0080
	v_mov_b32_e32 v39, v116                                    // 000000001178: 7E4E0374
	v_dual_mov_b32 v40, v116 :: v_dual_mov_b32 v147, 0         // 00000000117C: CA100174 28920080
	v_mov_b32_e32 v41, v116                                    // 000000001184: 7E520374
	v_mov_b32_e32 v42, v116                                    // 000000001188: 7E540374
	v_mov_b32_e32 v43, v116                                    // 00000000118C: 7E560374
	v_mov_b32_e32 v44, v116                                    // 000000001190: 7E580374
	v_mov_b32_e32 v45, v116                                    // 000000001194: 7E5A0374
	v_mov_b32_e32 v46, v116                                    // 000000001198: 7E5C0374
	v_mov_b32_e32 v47, v116                                    // 00000000119C: 7E5E0374
	v_mov_b32_e32 v48, v116                                    // 0000000011A0: 7E600374
	v_mov_b32_e32 v49, v116                                    // 0000000011A4: 7E620374
	v_mov_b32_e32 v50, v116                                    // 0000000011A8: 7E640374
	v_mov_b32_e32 v51, v116                                    // 0000000011AC: 7E660374
	v_mov_b32_e32 v52, v116                                    // 0000000011B0: 7E680374
	v_mov_b32_e32 v53, v116                                    // 0000000011B4: 7E6A0374
	v_mov_b32_e32 v54, v116                                    // 0000000011B8: 7E6C0374
	v_mov_b32_e32 v55, v116                                    // 0000000011BC: 7E6E0374
	v_mov_b32_e32 v56, v116                                    // 0000000011C0: 7E700374
	v_mov_b32_e32 v57, v116                                    // 0000000011C4: 7E720374
	v_mov_b32_e32 v58, v116                                    // 0000000011C8: 7E740374
	v_mov_b32_e32 v59, v116                                    // 0000000011CC: 7E760374
	v_mov_b32_e32 v60, v116                                    // 0000000011D0: 7E780374
	v_mov_b32_e32 v61, v116                                    // 0000000011D4: 7E7A0374
	v_mov_b32_e32 v62, v116                                    // 0000000011D8: 7E7C0374
	v_mov_b32_e32 v63, v116                                    // 0000000011DC: 7E7E0374
	v_mov_b32_e32 v64, v116                                    // 0000000011E0: 7E800374
	s_branch 384                                               // 0000000011E4: BFA00180 <attn_pfd+0x17e8>
	s_or_b32 exec_lo, exec_lo, s6                              // 0000000011E8: 8C7E067E
	v_dual_sub_f32 v185, v185, v72 :: v_dual_sub_f32 v186, v186, v71// 0000000011EC: C94A91B9 B9BA8FBA
	v_dual_sub_f32 v188, v188, v70 :: v_dual_sub_f32 v189, v189, v69// 0000000011F4: C94A8DBC BCBC8BBD
	v_cvt_f16_f32_e32 v115, v115                               // 0000000011FC: 7EE61573
	s_delay_alu instid0(VALU_DEP_3)                            // 000000001200: BF870003
	v_dual_mul_f32 v196, 0x3fb8aa3b, v185 :: v_dual_mul_f32 v197, 0x3fb8aa3b, v186// 000000001204: C8C772FF C4C574FF 3FB8AA3B
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v185                     // 000000001210: D41B0005 000372FF C2CE8ED0
	v_sub_f32_e32 v192, v192, v68                              // 00000000121C: 098089C0
	ds_store_b16 v177, v115 offset:448                         // 000000001220: D87C01C0 000073B1
	v_fma_f32 v199, 0x3fb8aa3b, v185, -v196                    // 000000001228: D61300C7 871372FF 3FB8AA3B
	v_rndne_f32_e32 v200, v196                                 // 000000001234: 7F9047C4
	v_fma_f32 v201, 0x3fb8aa3b, v186, -v197                    // 000000001238: D61300C9 871774FF 3FB8AA3B
	v_rndne_f32_e32 v202, v197                                 // 000000001244: 7F9447C5
	v_mul_f32_e32 v198, 0x3fb8aa3b, v188                       // 000000001248: 118D78FF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001250: BF870214
	v_dual_fmac_f32 v199, 0x32a5705f, v185 :: v_dual_sub_f32 v196, v196, v200// 000000001254: C80B72FF C7C591C4 32A5705F
	v_fmac_f32_e32 v201, 0x32a5705f, v186                      // 000000001260: 579374FF 32A5705F
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001268: BF870214
	v_sub_f32_e32 v197, v197, v202                             // 00000000126C: 098B95C5
	v_fma_f32 v203, 0x3fb8aa3b, v188, -v198                    // 000000001270: D61300CB 871B78FF 3FB8AA3B
	v_rndne_f32_e32 v204, v198                                 // 00000000127C: 7F9847C6
	v_add_f32_e32 v196, v196, v199                             // 000000001280: 07898FC4
	v_cvt_i32_f32_e32 v200, v200                               // 000000001284: 7F9011C8
	v_add_f32_e32 v197, v197, v201                             // 000000001288: 078B93C5
	v_fmac_f32_e32 v203, 0x32a5705f, v188                      // 00000000128C: 579778FF 32A5705F
	v_sub_f32_e32 v198, v198, v204                             // 000000001294: 098D99C6
	v_exp_f32_e32 v196, v196                                   // 000000001298: 7F884BC4
	v_cvt_i32_f32_e32 v202, v202                               // 00000000129C: 7F9411CA
	v_exp_f32_e32 v197, v197                                   // 0000000012A0: 7F8A4BC5
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 0000000012A4: BF8701B2
	v_dual_mul_f32 v199, 0x3fb8aa3b, v189 :: v_dual_add_f32 v198, v198, v203// 0000000012A8: C8C97AFF C7C797C6 3FB8AA3B
	v_mul_f32_e32 v201, 0x3fb8aa3b, v192                       // 0000000012B4: 119380FF 3FB8AA3B
	v_cvt_i32_f32_e32 v204, v204                               // 0000000012BC: 7F9811CC
	v_fma_f32 v203, 0x3fb8aa3b, v189, -v199                    // 0000000012C0: D61300CB 871F7AFF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(TRANS32_DEP_3)// 0000000012CC: BF870394
	v_exp_f32_e32 v198, v198                                   // 0000000012D0: 7F8C4BC6
	v_ldexp_f32 v196, v196, v200                               // 0000000012D4: D71C00C4 000391C4
	v_rndne_f32_e32 v205, v199                                 // 0000000012DC: 7F9A47C7
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 0000000012E0: BF870226
	v_ldexp_f32 v197, v197, v202                               // 0000000012E4: D71C00C5 000395C5
	v_sub_f32_e32 v194, v194, v66                              // 0000000012EC: 098485C2
	v_cndmask_b32_e64 v196, 0, v196, s5                        // 0000000012F0: D50100C4 00178880
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v186                     // 0000000012F8: D41B0005 000374FF C2CE8ED0
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001304: BF870115
	v_ldexp_f32 v198, v198, v204                               // 000000001308: D71C00C6 000399C6
	v_cndmask_b32_e64 v197, 0, v197, s5                        // 000000001310: D50100C5 00178A80
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v185                     // 000000001318: D41E0005 000372FF 42B17218
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001324: BF870001
	v_cndmask_b32_e64 v122, 0x7f800000, v196, s5               // 000000001328: D501007A 001788FF 7F800000
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v186                     // 000000001334: D41E0005 000374FF 42B17218
	v_fma_f32 v186, 0x3fb8aa3b, v192, -v201                    // 000000001340: D61300BA 872780FF 3FB8AA3B
	v_fmac_f32_e32 v203, 0x32a5705f, v189                      // 00000000134C: 57977AFF 32A5705F
	v_rndne_f32_e32 v196, v201                                 // 000000001354: 7F8847C9
	v_sub_f32_e32 v199, v199, v205                             // 000000001358: 098F9BC7
	v_cndmask_b32_e64 v124, 0x7f800000, v197, s5               // 00000000135C: D501007C 00178AFF 7F800000
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v188                     // 000000001368: D41B0005 000378FF C2CE8ED0
	v_fmac_f32_e32 v186, 0x32a5705f, v192                      // 000000001374: 577580FF 32A5705F
	v_mul_f32_e32 v8, v8, v122                                 // 00000000137C: 1010F508
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001380: BF870214
	v_dual_mul_f32 v40, v40, v122 :: v_dual_fmac_f32 v79, v147, v124// 000000001384: C8C0F528 284EF993
	v_cndmask_b32_e64 v197, 0, v198, s5                        // 00000000138C: D50100C5 00178C80
	v_dual_sub_f32 v198, v201, v196 :: v_dual_add_f32 v185, v199, v203// 000000001394: C94989C9 C6B997C7
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v188                     // 00000000139C: D41E0005 000378FF 42B17218
	v_cvt_i32_f32_e32 v196, v196                               // 0000000013A8: 7F8811C4
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)// 0000000013AC: BF870213
	v_dual_add_f32 v186, v198, v186 :: v_dual_add_nc_u32 v147, v157, v161// 0000000013B0: C92175C6 BA93439D
	v_exp_f32_e32 v185, v185                                   // 0000000013B8: 7F724BB9
	s_delay_alu instid0(VALU_DEP_3)                            // 0000000013BC: BF870003
	v_cndmask_b32_e64 v188, 0x7f800000, v197, s5               // 0000000013C0: D50100BC 00178AFF 7F800000
	v_cvt_i32_f32_e32 v197, v205                               // 0000000013CC: 7F8A11CD
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v189                     // 0000000013D0: D41B0005 00037AFF C2CE8ED0
	v_exp_f32_e32 v186, v186                                   // 0000000013DC: 7F744BBA
	v_dual_mul_f32 v63, v63, v124 :: v_dual_mul_f32 v32, v32, v122// 0000000013E0: C8C6F93F 3F20F520
	v_dual_mul_f32 v55, v55, v124 :: v_dual_mul_f32 v24, v24, v122// 0000000013E8: C8C6F937 3718F518
	v_dual_mul_f32 v47, v47, v124 :: v_dual_mul_f32 v16, v16, v122// 0000000013F0: C8C6F92F 2F10F510
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(SKIP_2) | instid1(TRANS32_DEP_1)// 0000000013F8: BF8702B6
	v_ldexp_f32 v185, v185, v197                               // 0000000013FC: D71C00B9 00038BB9
	v_mul_f32_e32 v197, 0x3fb8aa3b, v194                       // 000000001404: 118B84FF 3FB8AA3B
	v_mul_f32_e32 v39, v39, v124                               // 00000000140C: 104EF927
	v_ldexp_f32 v186, v186, v196                               // 000000001410: D71C00BA 000389BA
	v_mul_f32_e32 v31, v31, v124                               // 000000001418: 103EF91F
	v_cndmask_b32_e64 v185, 0, v185, s5                        // 00000000141C: D50100B9 00177280
	v_fma_f32 v204, 0x3fb8aa3b, v194, -v197                    // 000000001424: D61300CC 871784FF 3FB8AA3B
	v_sub_f32_e32 v193, v193, v67                              // 000000001430: 098287C1
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v189                     // 000000001434: D41E0005 00037AFF 42B17218
	v_mul_f32_e32 v38, v38, v188                               // 000000001440: 104D7926
	v_mul_f32_e32 v30, v30, v188                               // 000000001444: 103D791E
	v_fmac_f32_e32 v204, 0x32a5705f, v194                      // 000000001448: 579984FF 32A5705F
	v_mul_f32_e32 v198, 0x3fb8aa3b, v193                       // 000000001450: 118D82FF 3FB8AA3B
	v_cndmask_b32_e64 v185, 0x7f800000, v185, s5               // 000000001458: D50100B9 001772FF 7F800000
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v192                     // 000000001464: D41B0005 000380FF C2CE8ED0
	v_mul_f32_e32 v22, v22, v188                               // 000000001470: 102D7916
	v_mul_f32_e32 v14, v14, v188                               // 000000001474: 101D790E
	v_rndne_f32_e32 v203, v198                                 // 000000001478: 7F9647C6
	v_sub_f32_e32 v191, v191, v65                              // 00000000147C: 097E83BF
	v_fma_f32 v200, 0x3fb8aa3b, v193, -v198                    // 000000001480: D61300C8 871B82FF 3FB8AA3B
	v_cndmask_b32_e64 v186, 0, v186, s5                        // 00000000148C: D50100BA 00177480
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v192                     // 000000001494: D41E0005 000380FF 42B17218
	v_sub_f32_e32 v198, v198, v203                             // 0000000014A0: 098D97C6
	v_mul_f32_e32 v199, 0x3fb8aa3b, v191                       // 0000000014A4: 118F7EFF 3FB8AA3B
	v_fmac_f32_e32 v200, 0x32a5705f, v193                      // 0000000014AC: 579182FF 32A5705F
	v_dual_fmac_f32 v77, v162, v185 :: v_dual_fmac_f32 v80, v140, v122// 0000000014B4: C80173A2 4D50F58C
	v_cndmask_b32_e64 v186, 0x7f800000, v186, s5               // 0000000014BC: D50100BA 001774FF 7F800000
	s_delay_alu instid0(VALU_DEP_4)                            // 0000000014C8: BF870004
	v_fma_f32 v201, 0x3fb8aa3b, v191, -v199                    // 0000000014CC: D61300C9 871F7EFF 3FB8AA3B
	v_rndne_f32_e32 v202, v199                                 // 0000000014D8: 7F9447C7
	v_add_f32_e32 v198, v198, v200                             // 0000000014DC: 078D91C6
	v_rndne_f32_e32 v205, v197                                 // 0000000014E0: 7F9A47C5
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v191                     // 0000000014E4: D41B0005 00037EFF C2CE8ED0
	v_fmac_f32_e32 v201, 0x32a5705f, v191                      // 0000000014F0: 57937EFF 32A5705F
	v_sub_f32_e32 v199, v199, v202                             // 0000000014F8: 098F95C7
	v_exp_f32_e32 v189, v198                                   // 0000000014FC: 7F7A4BC6
	v_dual_sub_f32 v197, v197, v205 :: v_dual_fmac_f32 v76, v184, v186// 000000001500: C9419BC5 C54D75B8
	v_cvt_i32_f32_e32 v198, v203                               // 000000001508: 7F8C11CB
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 00000000150C: BF870223
	v_add_f32_e32 v199, v199, v201                             // 000000001510: 078F93C7
	v_cvt_i32_f32_e32 v200, v205                               // 000000001514: 7F9011CD
	v_add_f32_e32 v197, v197, v204                             // 000000001518: 078B99C5
	v_mul_f32_e32 v61, v61, v185                               // 00000000151C: 107B733D
	v_mul_f32_e32 v53, v53, v185                               // 000000001520: 106B7335
	v_exp_f32_e32 v199, v199                                   // 000000001524: 7F8E4BC7
	s_delay_alu instid0(TRANS32_DEP_2)                         // 000000001528: BF870006
	v_ldexp_f32 v189, v189, v198                               // 00000000152C: D71C00BD 00038DBD
	v_exp_f32_e32 v196, v197                                   // 000000001534: 7F884BC5
	v_cvt_i32_f32_e32 v197, v202                               // 000000001538: 7F8A11CA
	v_mul_f32_e32 v45, v45, v185                               // 00000000153C: 105B732D
	v_mul_f32_e32 v37, v37, v185                               // 000000001540: 104B7325
	v_dual_mul_f32 v29, v29, v185 :: v_dual_mul_f32 v6, v6, v188// 000000001544: C8C7731D 1D077906
	v_dual_mul_f32 v21, v21, v185 :: v_dual_mul_f32 v64, v64, v122// 00000000154C: C8C77315 1540F540
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)// 000000001554: BF8702A6
	v_ldexp_f32 v197, v199, v197                               // 000000001558: D71C00C5 00038BC7
	v_dual_mul_f32 v13, v13, v185 :: v_dual_mul_f32 v56, v56, v122// 000000001560: C8C7730D 0D38F538
	v_ldexp_f32 v192, v196, v200                               // 000000001568: D71C00C0 000391C4
	v_dual_mul_f32 v5, v5, v185 :: v_dual_mul_f32 v48, v48, v122// 000000001570: C8C77305 0530F530
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_4) | instid1(VALU_DEP_4)// 000000001578: BF870254
	v_cndmask_b32_e64 v196, 0, v197, s5                        // 00000000157C: D50100C4 00178A80
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v193                     // 000000001584: D41B0005 000382FF C2CE8ED0
	v_mul_f32_e32 v23, v23, v124                               // 000000001590: 102EF917
	v_dual_mul_f32 v15, v15, v124 :: v_dual_mov_b32 v140, v80  // 000000001594: C8D0F90F 0F8C0150
	v_mul_f32_e32 v60, v60, v186                               // 00000000159C: 1079753C
	v_cndmask_b32_e64 v189, 0, v189, s5                        // 0000000015A0: D50100BD 00177A80
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v194                     // 0000000015A8: D41B0005 000384FF C2CE8ED0
	v_mul_f32_e32 v52, v52, v186                               // 0000000015B4: 10697534
	v_mul_f32_e32 v44, v44, v186                               // 0000000015B8: 1059752C
	v_mul_f32_e32 v36, v36, v186                               // 0000000015BC: 10497524
	v_mul_f32_e32 v28, v28, v186                               // 0000000015C0: 1039751C
	v_cndmask_b32_e64 v192, 0, v192, s5                        // 0000000015C4: D50100C0 00178080
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v191                     // 0000000015CC: D41E0005 00037EFF 42B17218
	v_mul_f32_e32 v20, v20, v186                               // 0000000015D8: 10297514
	v_mul_f32_e32 v12, v12, v186                               // 0000000015DC: 1019750C
	v_mul_f32_e32 v4, v4, v186                                 // 0000000015E0: 10097504
	v_fmac_f32_e32 v78, v148, v188                             // 0000000015E4: 569D7994
	v_cndmask_b32_e64 v191, 0x7f800000, v196, s5               // 0000000015E8: D50100BF 001788FF 7F800000
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v193                     // 0000000015F4: D41E0005 000382FF 42B17218
	v_mul_f32_e32 v62, v62, v188                               // 000000001600: 107D793E
	v_mul_f32_e32 v54, v54, v188                               // 000000001604: 106D7936
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000001608: BF870214
	v_dual_mul_f32 v46, v46, v188 :: v_dual_mul_f32 v17, v17, v191// 00000000160C: C8C7792E 2E117F11
	v_cndmask_b32_e64 v189, 0x7f800000, v189, s5               // 000000001614: D50100BD 00177AFF 7F800000
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v194                     // 000000001620: D41E0005 000384FF 42B17218
	v_mul_f32_e32 v9, v9, v191                                 // 00000000162C: 10137F09
	v_mul_f32_e32 v1, v1, v191                                 // 000000001630: 10037F01
	v_dual_mul_f32 v7, v7, v124 :: v_dual_mov_b32 v148, v78    // 000000001634: C8D0F907 0794014E
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 00000000163C: BF870244
	v_cndmask_b32_e64 v192, 0x7f800000, v192, s5               // 000000001640: D50100C0 001780FF 7F800000
	v_fmac_f32_e32 v73, v195, v191                             // 00000000164C: 56937FC3
	v_mul_f32_e32 v57, v57, v191                               // 000000001650: 10737F39
	v_mul_f32_e32 v49, v49, v191                               // 000000001654: 10637F31
	v_dual_mul_f32 v41, v41, v191 :: v_dual_mul_f32 v18, v18, v192// 000000001658: C8C77F29 29138112
	v_dual_mul_f32 v33, v33, v191 :: v_dual_mul_f32 v10, v10, v192// 000000001660: C8C77F21 210B810A
	v_dual_mul_f32 v25, v25, v191 :: v_dual_mul_f32 v2, v2, v192// 000000001668: C8C77F19 19038102
	v_fmac_f32_e32 v74, v190, v192                             // 000000001670: 569581BE
	v_mul_f32_e32 v58, v58, v192                               // 000000001674: 1075813A
	v_mul_f32_e32 v50, v50, v192                               // 000000001678: 10658132
	v_mul_f32_e32 v42, v42, v192                               // 00000000167C: 1055812A
	v_mul_f32_e32 v34, v34, v192                               // 000000001680: 10458122
	v_dual_mul_f32 v26, v26, v192 :: v_dual_fmac_f32 v75, v187, v189// 000000001684: C8C1811A 1A4B7BBB
	v_mul_f32_e32 v59, v59, v189                               // 00000000168C: 10777B3B
	v_mul_f32_e32 v51, v51, v189                               // 000000001690: 10677B33
	v_mul_f32_e32 v43, v43, v189                               // 000000001694: 10577B2B
	v_mul_f32_e32 v35, v35, v189                               // 000000001698: 10477B23
	v_mul_f32_e32 v27, v27, v189                               // 00000000169C: 10377B1B
	v_mul_f32_e32 v19, v19, v189                               // 0000000016A0: 10277B13
	v_mul_f32_e32 v11, v11, v189                               // 0000000016A4: 10177B0B
	v_mul_f32_e32 v3, v3, v189                                 // 0000000016A8: 10077B03
	ds_load_b128 v[184:187], v147                              // 0000000016AC: DBFC0000 B8000093
	ds_load_b128 v[188:191], v147 offset:16                    // 0000000016B4: DBFC0010 BC000093
	ds_load_b128 v[192:195], v178                              // 0000000016BC: DBFC0000 C00000B2
	ds_load_b128 v[196:199], v178 offset:16                    // 0000000016C4: DBFC0010 C40000B2
	ds_load_b128 v[204:207], v178 offset:528                   // 0000000016CC: DBFC0210 CC0000B2
	ds_load_b128 v[200:203], v178 offset:512                   // 0000000016D4: DBFC0200 C80000B2
	ds_load_b128 v[212:215], v178 offset:1040                  // 0000000016DC: DBFC0410 D40000B2
	ds_load_b128 v[208:211], v178 offset:1024                  // 0000000016E4: DBFC0400 D00000B2
	ds_load_b128 v[220:223], v178 offset:1552                  // 0000000016EC: DBFC0610 DC0000B2
	ds_load_b128 v[216:219], v178 offset:1536                  // 0000000016F4: DBFC0600 D80000B2
	ds_load_b128 v[228:231], v178 offset:2064                  // 0000000016FC: DBFC0810 E40000B2
	ds_load_b128 v[224:227], v178 offset:2048                  // 000000001704: DBFC0800 E00000B2
	ds_load_b128 v[236:239], v178 offset:2576                  // 00000000170C: DBFC0A10 EC0000B2
	ds_load_b128 v[232:235], v178 offset:2560                  // 000000001714: DBFC0A00 E80000B2
	ds_load_b128 v[244:247], v178 offset:3088                  // 00000000171C: DBFC0C10 F40000B2
	ds_load_b128 v[240:243], v178 offset:3072                  // 000000001724: DBFC0C00 F00000B2
	ds_load_b128 v[252:255], v178 offset:3600                  // 00000000172C: DBFC0E10 FC0000B2
	ds_load_b128 v[248:251], v178 offset:3584                  // 000000001734: DBFC0E00 F80000B2
	v_dual_mov_b32 v147, v79 :: v_dual_mov_b32 v162, v77       // 00000000173C: CA10014F 93A2014D
	s_waitcnt lgkmcnt(14)                                      // 000000001744: BF89FCE7
	v_wmma_f32_16x16x16_f16 v[57:64], v[184:191], v[192:199], v[57:64]// 000000001748: CC404039 1CE781B8
	v_mov_b32_e32 v192, v68                                    // 000000001750: 7F800344
	s_waitcnt lgkmcnt(12)                                      // 000000001754: BF89FCC7
	v_wmma_f32_16x16x16_f16 v[49:56], v[184:191], v[200:207], v[49:56]// 000000001758: CC404031 1CC791B8
	v_mov_b32_e32 v193, v67                                    // 000000001760: 7F820343
	s_waitcnt lgkmcnt(10)                                      // 000000001764: BF89FCA7
	v_wmma_f32_16x16x16_f16 v[41:48], v[184:191], v[208:215], v[41:48]// 000000001768: CC404029 1CA7A1B8
	v_mov_b32_e32 v194, v66                                    // 000000001770: 7F840342
	s_waitcnt lgkmcnt(8)                                       // 000000001774: BF89FC87
	v_wmma_f32_16x16x16_f16 v[33:40], v[184:191], v[216:223], v[33:40]// 000000001778: CC404021 1C87B1B8
	v_mov_b32_e32 v195, v73                                    // 000000001780: 7F860349
	s_waitcnt lgkmcnt(6)                                       // 000000001784: BF89FC67
	v_wmma_f32_16x16x16_f16 v[25:32], v[184:191], v[224:231], v[25:32]// 000000001788: CC404019 1C67C1B8
	s_waitcnt lgkmcnt(4)                                       // 000000001790: BF89FC47
	v_wmma_f32_16x16x16_f16 v[17:24], v[184:191], v[232:239], v[17:24]// 000000001794: CC404011 1C47D1B8
	s_waitcnt lgkmcnt(2)                                       // 00000000179C: BF89FC27
	v_wmma_f32_16x16x16_f16 v[9:16], v[184:191], v[240:247], v[9:16]// 0000000017A0: CC404009 1C27E1B8
	s_waitcnt lgkmcnt(0)                                       // 0000000017A8: BF89FC07
	v_wmma_f32_16x16x16_f16 v[1:8], v[184:191], v[248:255], v[1:8]// 0000000017AC: CC404001 1C07F1B8
	v_dual_mov_b32 v185, v72 :: v_dual_mov_b32 v186, v71       // 0000000017B4: CA100148 B9BA0147
	v_dual_mov_b32 v188, v70 :: v_dual_mov_b32 v189, v69       // 0000000017BC: CA100146 BCBC0145
	v_dual_mov_b32 v184, v76 :: v_dual_mov_b32 v191, v65       // 0000000017C4: CA10014C B8BE0141
	v_dual_mov_b32 v190, v74 :: v_dual_mov_b32 v187, v75       // 0000000017CC: CA10014A BEBA014B
	s_or_b32 exec_lo, exec_lo, s14                             // 0000000017D4: 8C7E0E7E
	s_add_i32 s37, s37, 1                                      // 0000000017D8: 81258125
	s_add_i32 s25, s25, 16                                     // 0000000017DC: 81199019
	s_cmp_ge_u32 s37, s36                                      // 0000000017E0: BF092425
	s_cbranch_scc1 2182                                        // 0000000017E4: BFA20886 <attn_pfd+0x3a00>
	v_add_nc_u32_e32 v65, s25, v131                            // 0000000017E8: 4A830619
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000017EC: BF890007
	s_barrier                                                  // 0000000017F0: BFBD0000
	s_and_saveexec_b32 s6, vcc_lo                              // 0000000017F4: BE86206A
	s_cbranch_execz 740                                        // 0000000017F8: BFA502E4 <attn_pfd+0x238c>
	v_cmp_le_u32_e64 s5, s28, v65                              // 0000000017FC: D44B0005 0002821C
	s_mov_b32 s14, 0                                           // 000000001804: BE8E0080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)// 000000001808: BF870491
	s_and_saveexec_b32 s15, s5                                 // 00000000180C: BE8F2005
	s_xor_b32 s5, exec_lo, s15                                 // 000000001810: 8D050F7E
	s_cbranch_execz 25                                         // 000000001814: BFA50019 <attn_pfd+0x187c>
	s_mov_b32 s17, s16                                         // 000000001818: BE910010
	s_and_b32 s14, s0, exec_lo                                 // 00000000181C: 8B0E7E00
	v_dual_mov_b32 v67, s17 :: v_dual_mov_b32 v66, s16         // 000000001820: CA100011 43420010
	s_mov_b32 s17, 0                                           // 000000001828: BE910080
	ds_store_b64 v179, v[66:67]                                // 00000000182C: D9340000 000042B3
	ds_store_b64 v180, v[66:67]                                // 000000001834: D9340000 000042B4
	ds_store_b16 v163, v116                                    // 00000000183C: D87C0000 000074A3
	ds_store_b16 v163, v116 offset:32                          // 000000001844: D87C0020 000074A3
	ds_store_b16 v163, v116 offset:64                          // 00000000184C: D87C0040 000074A3
	ds_store_b16 v163, v116 offset:96                          // 000000001854: D87C0060 000074A3
	ds_store_b16 v163, v116 offset:128                         // 00000000185C: D87C0080 000074A3
	ds_store_b16 v163, v116 offset:160                         // 000000001864: D87C00A0 000074A3
	ds_store_b16 v163, v116 offset:192                         // 00000000186C: D87C00C0 000074A3
	ds_store_b16 v163, v116 offset:224                         // 000000001874: D87C00E0 000074A3
	s_or_saveexec_b32 s15, s5                                  // 00000000187C: BE8F2205
	v_dual_mov_b32 v66, s17 :: v_dual_mov_b32 v67, s17         // 000000001880: CA100011 42420011
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000001888: 8D7E0F7E
	s_cbranch_execz 198                                        // 00000000188C: BFA500C6 <attn_pfd+0x1ba8>
	v_lshrrev_b32_e32 v67, 2, v84                              // 000000001890: 3286A882
	v_lshrrev_b32_e32 v68, 6, v84                              // 000000001894: 3288A886
	v_lshrrev_b32_e32 v70, 18, v84                             // 000000001898: 328CA892
	v_lshrrev_b32_e32 v69, 10, v84                             // 00000000189C: 328AA88A
	v_lshrrev_b32_e32 v71, 22, v84                             // 0000000018A0: 328EA896
	v_and_b32_e32 v66, 15, v84                                 // 0000000018A4: 3684A88F
	v_and_b32_e32 v67, 60, v67                                 // 0000000018A8: 368686BC
	v_lshrrev_b32_e32 v72, 14, v84                             // 0000000018AC: 3290A88E
	v_and_b32_e32 v68, 60, v68                                 // 0000000018B0: 368888BC
	v_and_b32_e32 v70, 60, v70                                 // 0000000018B4: 368C8CBC
	v_lshrrev_b32_e32 v73, 26, v84                             // 0000000018B8: 3292A89A
	v_and_b32_e32 v69, 60, v69                                 // 0000000018BC: 368A8ABC
	v_and_b32_e32 v71, 60, v71                                 // 0000000018C0: 368E8EBC
	v_lshlrev_b32_e32 v66, 2, v66                              // 0000000018C4: 30848482
	ds_load_b32 v67, v67 offset:20800                          // 0000000018C8: D8D85140 43000043
	ds_load_b32 v68, v68 offset:20800                          // 0000000018D0: D8D85140 44000044
	ds_load_b32 v69, v69 offset:20800                          // 0000000018D8: D8D85140 45000045
	v_and_b32_e32 v72, 60, v72                                 // 0000000018E0: 369090BC
	ds_load_b32 v70, v70 offset:20800                          // 0000000018E4: D8D85140 46000046
	ds_load_b32 v71, v71 offset:20800                          // 0000000018EC: D8D85140 47000047
	ds_load_b32 v66, v66 offset:20800                          // 0000000018F4: D8D85140 42000042
	v_and_b32_e32 v73, 60, v73                                 // 0000000018FC: 369292BC
	ds_load_b32 v72, v72 offset:20800                          // 000000001900: D8D85140 48000048
	ds_load_b32 v73, v73 offset:20800                          // 000000001908: D8D85140 49000049
	v_and_b32_e32 v74, 1, v90                                  // 000000001910: 3694B481
	v_and_b32_e32 v75, 2, v90                                  // 000000001914: 3696B482
	v_and_b32_e32 v77, 15, v81                                 // 000000001918: 369AA28F
	v_and_b32_e32 v76, 8, v90                                  // 00000000191C: 3698B488
	v_lshrrev_b32_e32 v78, 2, v81                              // 000000001920: 329CA282
	v_cmp_eq_u32_e64 s5, 0, v74                                // 000000001924: D44A0005 00029480
	v_lshrrev_b32_e32 v79, 6, v81                              // 00000000192C: 329EA286
	v_lshrrev_b32_e32 v196, 10, v81                            // 000000001930: 3388A28A
	v_lshrrev_b32_e32 v197, 14, v81                            // 000000001934: 338AA28E
	v_lshrrev_b32_e32 v198, 18, v81                            // 000000001938: 338CA292
	v_cndmask_b32_e64 v74, 1, 0xff, s5                         // 00000000193C: D501004A 0015FE81 000000FF
	s_waitcnt lgkmcnt(7)                                       // 000000001948: BF89FC77
	v_lshlrev_b32_e32 v67, 8, v67                              // 00000000194C: 30868688
	s_waitcnt lgkmcnt(6)                                       // 000000001950: BF89FC67
	v_lshlrev_b32_e32 v68, 16, v68                             // 000000001954: 30888890
	s_waitcnt lgkmcnt(4)                                       // 000000001958: BF89FC47
	v_lshlrev_b32_e32 v70, 8, v70                              // 00000000195C: 308C8C88
	v_cmp_eq_u32_e64 s5, 0, v75                                // 000000001960: D44A0005 00029680
	v_and_b32_e32 v75, 32, v90                                 // 000000001968: 3696B4A0
	s_waitcnt lgkmcnt(2)                                       // 00000000196C: BF89FC27
	v_perm_b32 v66, v67, v66, 0xc0c0500                        // 000000001970: D6440042 03FE8543 0C0C0500
	v_and_b32_e32 v67, 0xff0000, v68                           // 00000000197C: 368688FF 00FF0000
	s_waitcnt lgkmcnt(1)                                       // 000000001984: BF89FC17
	v_perm_b32 v70, v70, v72, 0xc0c0500                        // 000000001988: D6440046 03FE9146 0C0C0500
	v_cndmask_b32_e64 v68, 0x100, v181, s5                     // 000000001994: D5010044 00176AFF 00000100
	v_and_b32_e32 v72, 4, v90                                  // 0000000019A0: 3690B484
	v_lshrrev_b32_e32 v199, 22, v81                            // 0000000019A4: 338EA296
	v_lshrrev_b32_e32 v200, 26, v81                            // 0000000019A8: 3390A29A
	v_lshlrev_b32_e32 v77, 2, v77                              // 0000000019AC: 309A9A82
	v_or_b32_e32 v68, v74, v68                                 // 0000000019B0: 3888894A
	v_and_b32_e32 v74, 16, v90                                 // 0000000019B4: 3694B490
	v_cmp_eq_u32_e64 s5, 0, v72                                // 0000000019B8: D44A0005 00029080
	v_and_b32_e32 v80, 64, v90                                 // 0000000019C0: 36A0B4C0
	v_and_b32_e32 v78, 60, v78                                 // 0000000019C4: 369C9CBC
	v_and_b32_e32 v79, 60, v79                                 // 0000000019C8: 369E9EBC
	v_and_b32_e32 v196, 60, v196                               // 0000000019CC: 378988BC
	v_cndmask_b32_e64 v72, 0x10000, v182, s5                   // 0000000019D0: D5010048 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v74                                // 0000000019DC: D44A0005 00029480
	v_and_b32_e32 v197, 60, v197                               // 0000000019E4: 378B8ABC
	v_and_b32_e32 v198, 60, v198                               // 0000000019E8: 378D8CBC
	v_and_b32_e32 v199, 60, v199                               // 0000000019EC: 378F8EBC
	v_and_b32_e32 v200, 60, v200                               // 0000000019F0: 379190BC
	v_cndmask_b32_e64 v74, 1, 0xff, s5                         // 0000000019F4: D501004A 0015FE81 000000FF
	v_cmp_eq_u32_e64 s5, 0, v75                                // 000000001A00: D44A0005 00029680
	ds_load_b32 v77, v77 offset:20736                          // 000000001A08: D8D85100 4D00004D
	ds_load_b32 v78, v78 offset:20736                          // 000000001A10: D8D85100 4E00004E
	ds_load_b32 v79, v79 offset:20736                          // 000000001A18: D8D85100 4F00004F
	ds_load_b32 v196, v196 offset:20736                        // 000000001A20: D8D85100 C40000C4
	ds_load_b32 v197, v197 offset:20736                        // 000000001A28: D8D85100 C50000C5
	ds_load_b32 v198, v198 offset:20736                        // 000000001A30: D8D85100 C60000C6
	ds_load_b32 v199, v199 offset:20736                        // 000000001A38: D8D85100 C70000C7
	ds_load_b32 v200, v200 offset:20736                        // 000000001A40: D8D85100 C80000C8
	v_and_b32_e32 v115, 0x80, v90                              // 000000001A48: 36E6B4FF 00000080
	v_lshlrev_b32_e32 v71, 16, v71                             // 000000001A50: 308E8E90
	v_lshlrev_b32_e32 v69, 24, v69                             // 000000001A54: 308A8A98
	v_cndmask_b32_e64 v75, 0x100, v181, s5                     // 000000001A58: D501004B 00176AFF 00000100
	v_cmp_eq_u32_e64 s5, 0, v76                                // 000000001A64: D44A0005 00029880
	s_waitcnt lgkmcnt(8)                                       // 000000001A6C: BF89FC87
	v_lshlrev_b32_e32 v73, 24, v73                             // 000000001A70: 30929298
	v_and_b32_e32 v71, 0xff0000, v71                           // 000000001A74: 368E8EFF 00FF0000
	v_or3_b32 v66, v66, v67, v69                               // 000000001A7C: D6580042 05168742
	v_or_b32_e32 v74, v74, v75                                 // 000000001A84: 3894974A
	v_cndmask_b32_e64 v76, 0x1000000, v183, s5                 // 000000001A88: D501004C 00176EFF 01000000
	v_cmp_eq_u32_e64 s5, 0, v80                                // 000000001A94: D44A0005 0002A080
	v_or3_b32 v67, v70, v71, v73                               // 000000001A9C: D6580043 05268F46
	s_waitcnt lgkmcnt(7)                                       // 000000001AA4: BF89FC77
	v_fma_mixlo_f16 v70, v87, v77, 0                           // 000000001AA8: CC210046 02029B57
	s_waitcnt lgkmcnt(6)                                       // 000000001AB0: BF89FC67
	v_fma_mixlo_f16 v71, v87, v78, 0                           // 000000001AB4: CC210047 02029D57
	v_or3_b32 v68, v68, v72, v76                               // 000000001ABC: D6580044 05329144
	v_cndmask_b32_e64 v75, 0x10000, v182, s5                   // 000000001AC4: D501004B 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v115                               // 000000001AD0: D44A0005 0002E680
	s_waitcnt lgkmcnt(5)                                       // 000000001AD8: BF89FC57
	v_fma_mixlo_f16 v72, v87, v79, 0                           // 000000001ADC: CC210048 02029F57
	s_waitcnt lgkmcnt(4)                                       // 000000001AE4: BF89FC47
	v_fma_mixlo_f16 v73, v87, v196, 0                          // 000000001AE8: CC210049 02038957
	s_waitcnt lgkmcnt(1)                                       // 000000001AF0: BF89FC17
	v_fma_mixlo_f16 v76, v87, v199, 0                          // 000000001AF4: CC21004C 02038F57
	s_waitcnt lgkmcnt(0)                                       // 000000001AFC: BF89FC07
	v_fma_mixlo_f16 v77, v87, v200, 0                          // 000000001B00: CC21004D 02039157
	v_cndmask_b32_e64 v80, 0x1000000, v183, s5                 // 000000001B08: D5010050 00176EFF 01000000
	s_mov_b32 s5, s14                                          // 000000001B14: BE85000E
	s_delay_alu instid0(VALU_DEP_1)                            // 000000001B18: BF870001
	v_or3_b32 v69, v74, v75, v80                               // 000000001B1C: D6580045 0542974A
	v_fma_mixlo_f16 v74, v87, v197, 0                          // 000000001B24: CC21004A 02038B57
	v_fma_mixlo_f16 v75, v87, v198, 0                          // 000000001B2C: CC21004B 02038D57
	ds_store_b16 v163, v70                                     // 000000001B34: D87C0000 000046A3
	ds_store_b16 v163, v71 offset:32                           // 000000001B3C: D87C0020 000047A3
	ds_store_b16 v163, v72 offset:64                           // 000000001B44: D87C0040 000048A3
	ds_store_b16 v163, v73 offset:96                           // 000000001B4C: D87C0060 000049A3
	ds_store_b16 v163, v74 offset:128                          // 000000001B54: D87C0080 00004AA3
	ds_store_b16 v163, v75 offset:160                          // 000000001B5C: D87C00A0 00004BA3
	ds_store_b16 v163, v76 offset:192                          // 000000001B64: D87C00C0 00004CA3
	ds_store_b16 v163, v77 offset:224                          // 000000001B6C: D87C00E0 00004DA3
	ds_store_b64 v179, v[66:67]                                // 000000001B74: D9340000 000042B3
	ds_store_b64 v180, v[68:69]                                // 000000001B7C: D9340000 000044B4
	s_and_saveexec_b32 s17, s0                                 // 000000001B84: BE912000
	v_dual_mov_b32 v66, v96 :: v_dual_mov_b32 v67, v93         // 000000001B88: CA100160 4242015D
	s_or_b32 s5, s14, exec_lo                                  // 000000001B90: 8C057E0E
	s_or_b32 exec_lo, exec_lo, s17                             // 000000001B94: 8C7E117E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001B98: BF8704A9
	s_and_not1_b32 s14, s14, exec_lo                           // 000000001B9C: 910E7E0E
	s_and_b32 s5, s5, exec_lo                                  // 000000001BA0: 8B057E05
	s_or_b32 s14, s14, s5                                      // 000000001BA4: 8C0E050E
	s_or_b32 exec_lo, exec_lo, s15                             // 000000001BA8: 8C7E0F7E
	s_and_saveexec_b32 s5, s14                                 // 000000001BAC: BE85200E
	s_cbranch_execz 4                                          // 000000001BB0: BFA50004 <attn_pfd+0x1bc4>
	ds_store_b32 v165, v67                                     // 000000001BB4: D8340000 000043A5
	ds_store_b32 v164, v66                                     // 000000001BBC: D8340000 000042A4
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001BC4: 8C7E057E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001BC8: BF870009
	s_and_b32 exec_lo, exec_lo, s1                             // 000000001BCC: 8B7E017E
	s_cbranch_execz 494                                        // 000000001BD0: BFA501EE <attn_pfd+0x238c>
	v_add_nc_u32_e32 v66, 6, v65                               // 000000001BD4: 4A848286
	s_mov_b32 s14, 0                                           // 000000001BD8: BE8E0080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001BDC: BF870091
	v_cmp_le_u32_e64 s5, s28, v66                              // 000000001BE0: D44B0005 0002841C
	s_and_saveexec_b32 s15, s5                                 // 000000001BE8: BE8F2005
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001BEC: BF870009
	s_xor_b32 s5, exec_lo, s15                                 // 000000001BF0: 8D050F7E
	s_cbranch_execz 25                                         // 000000001BF4: BFA50019 <attn_pfd+0x1c5c>
	s_mov_b32 s17, s16                                         // 000000001BF8: BE910010
	s_and_b32 s14, s0, exec_lo                                 // 000000001BFC: 8B0E7E00
	v_dual_mov_b32 v67, s17 :: v_dual_mov_b32 v66, s16         // 000000001C00: CA100011 43420010
	s_mov_b32 s17, 0                                           // 000000001C08: BE910080
	ds_store_b64 v179, v[66:67] offset:1632                    // 000000001C0C: D9340660 000042B3
	ds_store_b16 v163, v116 offset:12                          // 000000001C14: D87C000C 000074A3
	ds_store_b64 v180, v[66:67] offset:1632                    // 000000001C1C: D9340660 000042B4
	ds_store_b16 v166, v116                                    // 000000001C24: D87C0000 000074A6
	ds_store_b16 v167, v116 offset:12                          // 000000001C2C: D87C000C 000074A7
	ds_store_b16 v168, v116                                    // 000000001C34: D87C0000 000074A8
	ds_store_b16 v169, v116 offset:12                          // 000000001C3C: D87C000C 000074A9
	ds_store_b16 v170, v116                                    // 000000001C44: D87C0000 000074AA
	ds_store_b16 v171, v116 offset:12                          // 000000001C4C: D87C000C 000074AB
	ds_store_b16 v172, v116                                    // 000000001C54: D87C0000 000074AC
	s_or_saveexec_b32 s15, s5                                  // 000000001C5C: BE8F2205
	v_dual_mov_b32 v66, s17 :: v_dual_mov_b32 v67, s17         // 000000001C60: CA100011 42420011
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000001C68: 8D7E0F7E
	s_cbranch_execz 201                                        // 000000001C6C: BFA500C9 <attn_pfd+0x1f94>
	v_lshrrev_b32_e32 v67, 2, v85                              // 000000001C70: 3286AA82
	v_lshrrev_b32_e32 v68, 6, v85                              // 000000001C74: 3288AA86
	v_lshrrev_b32_e32 v69, 10, v85                             // 000000001C78: 328AAA8A
	v_lshrrev_b32_e32 v70, 18, v85                             // 000000001C7C: 328CAA92
	v_lshrrev_b32_e32 v71, 22, v85                             // 000000001C80: 328EAA96
	v_and_b32_e32 v67, 60, v67                                 // 000000001C84: 368686BC
	v_and_b32_e32 v68, 60, v68                                 // 000000001C88: 368888BC
	v_lshrrev_b32_e32 v72, 26, v85                             // 000000001C8C: 3290AA9A
	v_and_b32_e32 v69, 60, v69                                 // 000000001C90: 368A8ABC
	v_and_b32_e32 v66, 15, v85                                 // 000000001C94: 3684AA8F
	v_lshrrev_b32_e32 v73, 14, v85                             // 000000001C98: 3292AA8E
	v_and_b32_e32 v70, 60, v70                                 // 000000001C9C: 368C8CBC
	ds_load_b32 v67, v67 offset:20800                          // 000000001CA0: D8D85140 43000043
	ds_load_b32 v68, v68 offset:20800                          // 000000001CA8: D8D85140 44000044
	ds_load_b32 v69, v69 offset:20800                          // 000000001CB0: D8D85140 45000045
	v_and_b32_e32 v71, 60, v71                                 // 000000001CB8: 368E8EBC
	v_and_b32_e32 v72, 60, v72                                 // 000000001CBC: 369090BC
	v_lshlrev_b32_e32 v66, 2, v66                              // 000000001CC0: 30848482
	v_and_b32_e32 v73, 60, v73                                 // 000000001CC4: 369292BC
	ds_load_b32 v70, v70 offset:20800                          // 000000001CC8: D8D85140 46000046
	ds_load_b32 v71, v71 offset:20800                          // 000000001CD0: D8D85140 47000047
	ds_load_b32 v72, v72 offset:20800                          // 000000001CD8: D8D85140 48000048
	ds_load_b32 v66, v66 offset:20800                          // 000000001CE0: D8D85140 42000042
	ds_load_b32 v73, v73 offset:20800                          // 000000001CE8: D8D85140 49000049
	v_and_b32_e32 v74, 1, v91                                  // 000000001CF0: 3694B681
	v_and_b32_e32 v75, 2, v91                                  // 000000001CF4: 3696B682
	v_lshrrev_b32_e32 v78, 10, v82                             // 000000001CF8: 329CA48A
	v_lshrrev_b32_e32 v79, 14, v82                             // 000000001CFC: 329EA48E
	v_lshrrev_b32_e32 v80, 18, v82                             // 000000001D00: 32A0A492
	v_cmp_eq_u32_e64 s5, 0, v74                                // 000000001D04: D44A0005 00029480
	v_lshrrev_b32_e32 v74, 2, v82                              // 000000001D0C: 3294A482
	v_lshrrev_b32_e32 v115, 22, v82                            // 000000001D10: 32E6A496
	v_lshrrev_b32_e32 v196, 26, v82                            // 000000001D14: 3388A49A
	v_and_b32_e32 v78, 60, v78                                 // 000000001D18: 369C9CBC
	v_and_b32_e32 v76, 64, v91                                 // 000000001D1C: 3698B6C0
	v_and_b32_e32 v74, 60, v74                                 // 000000001D20: 369494BC
	s_waitcnt lgkmcnt(7)                                       // 000000001D24: BF89FC77
	v_lshlrev_b32_e32 v67, 8, v67                              // 000000001D28: 30868688
	s_waitcnt lgkmcnt(6)                                       // 000000001D2C: BF89FC67
	v_lshlrev_b32_e32 v68, 16, v68                             // 000000001D30: 30888890
	s_waitcnt lgkmcnt(5)                                       // 000000001D34: BF89FC57
	v_lshlrev_b32_e32 v69, 24, v69                             // 000000001D38: 308A8A98
	s_waitcnt lgkmcnt(4)                                       // 000000001D3C: BF89FC47
	v_lshlrev_b32_e32 v70, 8, v70                              // 000000001D40: 308C8C88
	s_waitcnt lgkmcnt(3)                                       // 000000001D44: BF89FC37
	v_lshlrev_b32_e32 v71, 16, v71                             // 000000001D48: 308E8E90
	s_waitcnt lgkmcnt(2)                                       // 000000001D4C: BF89FC27
	v_lshlrev_b32_e32 v72, 24, v72                             // 000000001D50: 30909098
	s_waitcnt lgkmcnt(1)                                       // 000000001D54: BF89FC17
	v_perm_b32 v66, v67, v66, 0xc0c0500                        // 000000001D58: D6440042 03FE8543 0C0C0500
	v_and_b32_e32 v67, 0xff0000, v68                           // 000000001D64: 368688FF 00FF0000
	s_waitcnt lgkmcnt(0)                                       // 000000001D6C: BF89FC07
	v_perm_b32 v68, v70, v73, 0xc0c0500                        // 000000001D70: D6440044 03FE9346 0C0C0500
	v_and_b32_e32 v70, 0xff0000, v71                           // 000000001D7C: 368C8EFF 00FF0000
	v_cndmask_b32_e64 v71, 1, 0xff, s5                         // 000000001D84: D5010047 0015FE81 000000FF
	v_cmp_eq_u32_e64 s5, 0, v75                                // 000000001D90: D44A0005 00029680
	v_or3_b32 v66, v66, v67, v69                               // 000000001D98: D6580042 05168742
	v_and_b32_e32 v69, 4, v91                                  // 000000001DA0: 368AB684
	v_or3_b32 v67, v68, v70, v72                               // 000000001DA4: D6580043 05228D44
	v_and_b32_e32 v70, 16, v91                                 // 000000001DAC: 368CB690
	v_cndmask_b32_e64 v73, 0x100, v181, s5                     // 000000001DB0: D5010049 00176AFF 00000100
	v_lshrrev_b32_e32 v75, 6, v82                              // 000000001DBC: 3296A486
	v_cmp_eq_u32_e64 s5, 0, v69                                // 000000001DC0: D44A0005 00028A80
	v_and_b32_e32 v72, 8, v91                                  // 000000001DC8: 3690B688
	v_and_b32_e32 v79, 60, v79                                 // 000000001DCC: 369E9EBC
	v_or_b32_e32 v68, v71, v73                                 // 000000001DD0: 38889347
	v_and_b32_e32 v71, 32, v91                                 // 000000001DD4: 368EB6A0
	v_cndmask_b32_e64 v69, 0x10000, v182, s5                   // 000000001DD8: D5010045 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v70                                // 000000001DE4: D44A0005 00028C80
	v_and_b32_e32 v73, 15, v82                                 // 000000001DEC: 3692A48F
	v_and_b32_e32 v75, 60, v75                                 // 000000001DF0: 369696BC
	v_and_b32_e32 v80, 60, v80                                 // 000000001DF4: 36A0A0BC
	v_and_b32_e32 v115, 60, v115                               // 000000001DF8: 36E6E6BC
	v_cndmask_b32_e64 v70, 1, 0xff, s5                         // 000000001DFC: D5010046 0015FE81 000000FF
	v_cmp_eq_u32_e64 s5, 0, v71                                // 000000001E08: D44A0005 00028E80
	v_lshlrev_b32_e32 v73, 2, v73                              // 000000001E10: 30929282
	ds_load_b32 v73, v73 offset:20736                          // 000000001E14: D8D85100 49000049
	ds_load_b32 v74, v74 offset:20736                          // 000000001E1C: D8D85100 4A00004A
	ds_load_b32 v75, v75 offset:20736                          // 000000001E24: D8D85100 4B00004B
	v_cndmask_b32_e64 v71, 0x100, v181, s5                     // 000000001E2C: D5010047 00176AFF 00000100
	v_cmp_eq_u32_e64 s5, 0, v72                                // 000000001E38: D44A0005 00029080
	v_and_b32_e32 v196, 60, v196                               // 000000001E40: 378988BC
	ds_load_b32 v78, v78 offset:20736                          // 000000001E44: D8D85100 4E00004E
	ds_load_b32 v79, v79 offset:20736                          // 000000001E4C: D8D85100 4F00004F
	ds_load_b32 v80, v80 offset:20736                          // 000000001E54: D8D85100 50000050
	ds_load_b32 v115, v115 offset:20736                        // 000000001E5C: D8D85100 73000073
	ds_load_b32 v196, v196 offset:20736                        // 000000001E64: D8D85100 C40000C4
	v_and_b32_e32 v77, 0x80, v91                               // 000000001E6C: 369AB6FF 00000080
	v_or_b32_e32 v70, v70, v71                                 // 000000001E74: 388C8F46
	v_cndmask_b32_e64 v72, 0x1000000, v183, s5                 // 000000001E78: D5010048 00176EFF 01000000
	v_cmp_eq_u32_e64 s5, 0, v76                                // 000000001E84: D44A0005 00029880
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000001E8C: BF870112
	v_or3_b32 v68, v68, v69, v72                               // 000000001E90: D6580044 05228B44
	v_cndmask_b32_e64 v71, 0x10000, v182, s5                   // 000000001E98: D5010047 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v77                                // 000000001EA4: D44A0005 00029A80
	s_waitcnt lgkmcnt(7)                                       // 000000001EAC: BF89FC77
	v_fma_mixlo_f16 v73, v88, v73, 0                           // 000000001EB0: CC210049 02029358
	s_delay_alu instid0(VALU_DEP_2)                            // 000000001EB8: BF870002
	v_cndmask_b32_e64 v76, 0x1000000, v183, s5                 // 000000001EBC: D501004C 00176EFF 01000000
	s_waitcnt lgkmcnt(6)                                       // 000000001EC8: BF89FC67
	v_fma_mixlo_f16 v74, v88, v74, 0                           // 000000001ECC: CC21004A 02029558
	s_waitcnt lgkmcnt(5)                                       // 000000001ED4: BF89FC57
	v_fma_mixlo_f16 v75, v88, v75, 0                           // 000000001ED8: CC21004B 02029758
	s_waitcnt lgkmcnt(2)                                       // 000000001EE0: BF89FC27
	v_fma_mixlo_f16 v72, v88, v80, 0                           // 000000001EE4: CC210048 0202A158
	ds_store_b16 v163, v73 offset:12                           // 000000001EEC: D87C000C 000049A3
	ds_store_b16 v166, v74                                     // 000000001EF4: D87C0000 00004AA6
	ds_store_b16 v167, v75 offset:12                           // 000000001EFC: D87C000C 00004BA7
	v_or3_b32 v69, v70, v71, v76                               // 000000001F04: D6580045 05328F46
	v_fma_mixlo_f16 v70, v88, v78, 0                           // 000000001F0C: CC210046 02029D58
	v_fma_mixlo_f16 v71, v88, v79, 0                           // 000000001F14: CC210047 02029F58
	s_waitcnt lgkmcnt(4)                                       // 000000001F1C: BF89FC47
	v_fma_mixlo_f16 v73, v88, v115, 0                          // 000000001F20: CC210049 0202E758
	s_mov_b32 s5, s14                                          // 000000001F28: BE85000E
	s_waitcnt lgkmcnt(3)                                       // 000000001F2C: BF89FC37
	v_fma_mixlo_f16 v74, v88, v196, 0                          // 000000001F30: CC21004A 02038958
	ds_store_b16 v168, v70                                     // 000000001F38: D87C0000 000046A8
	ds_store_b16 v169, v71 offset:12                           // 000000001F40: D87C000C 000047A9
	ds_store_b16 v170, v72                                     // 000000001F48: D87C0000 000048AA
	ds_store_b16 v171, v73 offset:12                           // 000000001F50: D87C000C 000049AB
	ds_store_b16 v172, v74                                     // 000000001F58: D87C0000 00004AAC
	ds_store_b64 v179, v[66:67] offset:1632                    // 000000001F60: D9340660 000042B3
	ds_store_b64 v180, v[68:69] offset:1632                    // 000000001F68: D9340660 000044B4
	s_and_saveexec_b32 s17, s0                                 // 000000001F70: BE912000
	v_dual_mov_b32 v66, v97 :: v_dual_mov_b32 v67, v94         // 000000001F74: CA100161 4242015E
	s_or_b32 s5, s14, exec_lo                                  // 000000001F7C: 8C057E0E
	s_or_b32 exec_lo, exec_lo, s17                             // 000000001F80: 8C7E117E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000001F84: BF8704A9
	s_and_not1_b32 s14, s14, exec_lo                           // 000000001F88: 910E7E0E
	s_and_b32 s5, s5, exec_lo                                  // 000000001F8C: 8B057E05
	s_or_b32 s14, s14, s5                                      // 000000001F90: 8C0E050E
	s_or_b32 exec_lo, exec_lo, s15                             // 000000001F94: 8C7E0F7E
	s_and_saveexec_b32 s5, s14                                 // 000000001F98: BE85200E
	s_cbranch_execz 4                                          // 000000001F9C: BFA50004 <attn_pfd+0x1fb0>
	ds_store_b32 v165, v67 offset:24                           // 000000001FA0: D8340018 000043A5
	ds_store_b32 v164, v66 offset:24                           // 000000001FA8: D8340018 000042A4
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001FB0: 8C7E057E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001FB4: BF870009
	s_and_b32 exec_lo, exec_lo, s2                             // 000000001FB8: 8B7E027E
	s_cbranch_execz 243                                        // 000000001FBC: BFA500F3 <attn_pfd+0x238c>
	v_add_nc_u32_e32 v66, 12, v65                              // 000000001FC0: 4A84828C
	s_mov_b32 s14, 0                                           // 000000001FC4: BE8E0080
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000001FC8: BF870091
	v_cmp_le_u32_e64 s5, s28, v66                              // 000000001FCC: D44B0005 0002841C
	s_and_saveexec_b32 s15, s5                                 // 000000001FD4: BE8F2005
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000001FD8: BF870009
	s_xor_b32 s5, exec_lo, s15                                 // 000000001FDC: 8D050F7E
	s_cbranch_execz 25                                         // 000000001FE0: BFA50019 <attn_pfd+0x2048>
	s_mov_b32 s17, s16                                         // 000000001FE4: BE910010
	s_and_b32 s14, s0, exec_lo                                 // 000000001FE8: 8B0E7E00
	v_dual_mov_b32 v67, s17 :: v_dual_mov_b32 v66, s16         // 000000001FEC: CA100011 43420010
	s_mov_b32 s17, 0                                           // 000000001FF4: BE910080
	ds_store_b64 v179, v[66:67] offset:3264                    // 000000001FF8: D9340CC0 000042B3
	ds_store_b16 v163, v116 offset:24                          // 000000002000: D87C0018 000074A3
	ds_store_b16 v167, v116 offset:24                          // 000000002008: D87C0018 000074A7
	ds_store_b16 v169, v116 offset:24                          // 000000002010: D87C0018 000074A9
	ds_store_b16 v174, v116 offset:24                          // 000000002018: D87C0018 000074AE
	ds_store_b16 v175, v116 offset:24                          // 000000002020: D87C0018 000074AF
	ds_store_b16 v173, v116 offset:24                          // 000000002028: D87C0018 000074AD
	ds_store_b16 v171, v116 offset:24                          // 000000002030: D87C0018 000074AB
	ds_store_b64 v180, v[66:67] offset:3264                    // 000000002038: D9340CC0 000042B4
	ds_store_b16 v176, v116 offset:24                          // 000000002040: D87C0018 000074B0
	s_or_saveexec_b32 s15, s5                                  // 000000002048: BE8F2205
	v_dual_mov_b32 v66, s17 :: v_dual_mov_b32 v67, s17         // 00000000204C: CA100011 42420011
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002054: 8D7E0F7E
	s_cbranch_execz 196                                        // 000000002058: BFA500C4 <attn_pfd+0x236c>
	v_lshrrev_b32_e32 v67, 2, v86                              // 00000000205C: 3286AC82
	v_lshrrev_b32_e32 v68, 6, v86                              // 000000002060: 3288AC86
	v_lshrrev_b32_e32 v70, 18, v86                             // 000000002064: 328CAC92
	v_lshrrev_b32_e32 v69, 10, v86                             // 000000002068: 328AAC8A
	v_lshrrev_b32_e32 v71, 22, v86                             // 00000000206C: 328EAC96
	v_and_b32_e32 v66, 15, v86                                 // 000000002070: 3684AC8F
	v_and_b32_e32 v67, 60, v67                                 // 000000002074: 368686BC
	v_lshrrev_b32_e32 v72, 14, v86                             // 000000002078: 3290AC8E
	v_and_b32_e32 v68, 60, v68                                 // 00000000207C: 368888BC
	v_and_b32_e32 v70, 60, v70                                 // 000000002080: 368C8CBC
	v_lshrrev_b32_e32 v73, 26, v86                             // 000000002084: 3292AC9A
	v_and_b32_e32 v69, 60, v69                                 // 000000002088: 368A8ABC
	v_and_b32_e32 v71, 60, v71                                 // 00000000208C: 368E8EBC
	v_lshlrev_b32_e32 v66, 2, v66                              // 000000002090: 30848482
	ds_load_b32 v67, v67 offset:20800                          // 000000002094: D8D85140 43000043
	ds_load_b32 v68, v68 offset:20800                          // 00000000209C: D8D85140 44000044
	ds_load_b32 v69, v69 offset:20800                          // 0000000020A4: D8D85140 45000045
	v_and_b32_e32 v72, 60, v72                                 // 0000000020AC: 369090BC
	ds_load_b32 v70, v70 offset:20800                          // 0000000020B0: D8D85140 46000046
	ds_load_b32 v71, v71 offset:20800                          // 0000000020B8: D8D85140 47000047
	ds_load_b32 v66, v66 offset:20800                          // 0000000020C0: D8D85140 42000042
	v_and_b32_e32 v73, 60, v73                                 // 0000000020C8: 369292BC
	ds_load_b32 v72, v72 offset:20800                          // 0000000020CC: D8D85140 48000048
	ds_load_b32 v73, v73 offset:20800                          // 0000000020D4: D8D85140 49000049
	v_and_b32_e32 v74, 1, v92                                  // 0000000020DC: 3694B881
	v_and_b32_e32 v75, 2, v92                                  // 0000000020E0: 3696B882
	v_and_b32_e32 v77, 15, v83                                 // 0000000020E4: 369AA68F
	v_and_b32_e32 v76, 32, v92                                 // 0000000020E8: 3698B8A0
	v_lshrrev_b32_e32 v78, 2, v83                              // 0000000020EC: 329CA682
	v_cmp_eq_u32_e64 s5, 0, v74                                // 0000000020F0: D44A0005 00029480
	v_lshrrev_b32_e32 v80, 6, v83                              // 0000000020F8: 32A0A686
	v_lshlrev_b32_e32 v77, 2, v77                              // 0000000020FC: 309A9A82
	v_lshrrev_b32_e32 v115, 10, v83                            // 000000002100: 32E6A68A
	v_lshrrev_b32_e32 v196, 14, v83                            // 000000002104: 3388A68E
	v_cndmask_b32_e64 v74, 1, 0xff, s5                         // 000000002108: D501004A 0015FE81 000000FF
	s_waitcnt lgkmcnt(7)                                       // 000000002114: BF89FC77
	v_lshlrev_b32_e32 v67, 8, v67                              // 000000002118: 30868688
	s_waitcnt lgkmcnt(6)                                       // 00000000211C: BF89FC67
	v_lshlrev_b32_e32 v68, 16, v68                             // 000000002120: 30888890
	s_waitcnt lgkmcnt(4)                                       // 000000002124: BF89FC47
	v_lshlrev_b32_e32 v70, 8, v70                              // 000000002128: 308C8C88
	v_cmp_eq_u32_e64 s5, 0, v75                                // 00000000212C: D44A0005 00029680
	v_lshrrev_b32_e32 v199, 26, v83                            // 000000002134: 338EA69A
	s_waitcnt lgkmcnt(2)                                       // 000000002138: BF89FC27
	v_perm_b32 v66, v67, v66, 0xc0c0500                        // 00000000213C: D6440042 03FE8543 0C0C0500
	v_and_b32_e32 v67, 0xff0000, v68                           // 000000002148: 368688FF 00FF0000
	s_waitcnt lgkmcnt(1)                                       // 000000002150: BF89FC17
	v_perm_b32 v70, v70, v72, 0xc0c0500                        // 000000002154: D6440046 03FE9146 0C0C0500
	v_cndmask_b32_e64 v68, 0x100, v181, s5                     // 000000002160: D5010044 00176AFF 00000100
	v_and_b32_e32 v72, 4, v92                                  // 00000000216C: 3690B884
	v_lshrrev_b32_e32 v197, 18, v83                            // 000000002170: 338AA692
	v_lshrrev_b32_e32 v198, 22, v83                            // 000000002174: 338CA696
	v_and_b32_e32 v78, 60, v78                                 // 000000002178: 369C9CBC
	v_or_b32_e32 v68, v74, v68                                 // 00000000217C: 3888894A
	v_and_b32_e32 v74, 16, v92                                 // 000000002180: 3694B890
	v_cmp_eq_u32_e64 s5, 0, v72                                // 000000002184: D44A0005 00029080
	v_and_b32_e32 v75, 8, v92                                  // 00000000218C: 3696B888
	v_and_b32_e32 v80, 60, v80                                 // 000000002190: 36A0A0BC
	v_and_b32_e32 v115, 60, v115                               // 000000002194: 36E6E6BC
	ds_load_b32 v77, v77 offset:20736                          // 000000002198: D8D85100 4D00004D
	v_cndmask_b32_e64 v72, 0x10000, v182, s5                   // 0000000021A0: D5010048 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v74                                // 0000000021AC: D44A0005 00029480
	v_and_b32_e32 v196, 60, v196                               // 0000000021B4: 378988BC
	v_and_b32_e32 v199, 60, v199                               // 0000000021B8: 378F8EBC
	v_and_b32_e32 v197, 60, v197                               // 0000000021BC: 378B8ABC
	v_and_b32_e32 v198, 60, v198                               // 0000000021C0: 378D8CBC
	v_cndmask_b32_e64 v74, 1, 0xff, s5                         // 0000000021C4: D501004A 0015FE81 000000FF
	v_cmp_eq_u32_e64 s5, 0, v76                                // 0000000021D0: D44A0005 00029880
	ds_load_b32 v78, v78 offset:20736                          // 0000000021D8: D8D85100 4E00004E
	ds_load_b32 v80, v80 offset:20736                          // 0000000021E0: D8D85100 50000050
	ds_load_b32 v115, v115 offset:20736                        // 0000000021E8: D8D85100 73000073
	ds_load_b32 v196, v196 offset:20736                        // 0000000021F0: D8D85100 C40000C4
	ds_load_b32 v197, v197 offset:20736                        // 0000000021F8: D8D85100 C50000C5
	ds_load_b32 v198, v198 offset:20736                        // 000000002200: D8D85100 C60000C6
	v_and_b32_e32 v79, 64, v92                                 // 000000002208: 369EB8C0
	v_and_b32_e32 v200, 0x80, v92                              // 00000000220C: 3790B8FF 00000080
	v_lshlrev_b32_e32 v71, 16, v71                             // 000000002214: 308E8E90
	v_cndmask_b32_e64 v76, 0x100, v181, s5                     // 000000002218: D501004C 00176AFF 00000100
	v_cmp_eq_u32_e64 s5, 0, v75                                // 000000002224: D44A0005 00029680
	v_lshlrev_b32_e32 v69, 24, v69                             // 00000000222C: 308A8A98
	s_waitcnt lgkmcnt(7)                                       // 000000002230: BF89FC77
	v_lshlrev_b32_e32 v73, 24, v73                             // 000000002234: 30929298
	v_and_b32_e32 v71, 0xff0000, v71                           // 000000002238: 368E8EFF 00FF0000
	v_or_b32_e32 v74, v74, v76                                 // 000000002240: 3894994A
	ds_load_b32 v76, v199 offset:20736                         // 000000002244: D8D85100 4C0000C7
	v_cndmask_b32_e64 v75, 0x1000000, v183, s5                 // 00000000224C: D501004B 00176EFF 01000000
	v_cmp_eq_u32_e64 s5, 0, v79                                // 000000002258: D44A0005 00029E80
	s_waitcnt lgkmcnt(7)                                       // 000000002260: BF89FC77
	v_fma_mixlo_f16 v77, v89, v77, 0                           // 000000002264: CC21004D 02029B59
	v_or3_b32 v66, v66, v67, v69                               // 00000000226C: D6580042 05168742
	v_or3_b32 v67, v70, v71, v73                               // 000000002274: D6580043 05268F46
	s_waitcnt lgkmcnt(5)                                       // 00000000227C: BF89FC57
	v_fma_mixlo_f16 v70, v89, v80, 0                           // 000000002280: CC210046 0202A159
	v_cndmask_b32_e64 v79, 0x10000, v182, s5                   // 000000002288: D501004F 00176CFF 00010000
	v_cmp_eq_u32_e64 s5, 0, v200                               // 000000002294: D44A0005 00039080
	s_waitcnt lgkmcnt(3)                                       // 00000000229C: BF89FC37
	v_fma_mixlo_f16 v71, v89, v196, 0                          // 0000000022A0: CC210047 02038959
	v_or3_b32 v68, v68, v72, v75                               // 0000000022A8: D6580044 052E9144
	v_fma_mixlo_f16 v72, v89, v78, 0                           // 0000000022B0: CC210048 02029D59
	s_waitcnt lgkmcnt(1)                                       // 0000000022B8: BF89FC17
	v_fma_mixlo_f16 v73, v89, v198, 0                          // 0000000022BC: CC210049 02038D59
	v_cndmask_b32_e64 v199, 0x1000000, v183, s5                // 0000000022C4: D50100C7 00176EFF 01000000
	ds_store_b16 v163, v77 offset:24                           // 0000000022D0: D87C0018 00004DA3
	ds_store_b16 v167, v70 offset:24                           // 0000000022D8: D87C0018 000046A7
	ds_store_b16 v169, v71 offset:24                           // 0000000022E0: D87C0018 000047A9
	v_fma_mixlo_f16 v70, v89, v197, 0                          // 0000000022E8: CC210046 02038B59
	s_mov_b32 s5, s14                                          // 0000000022F0: BE85000E
	v_or3_b32 v69, v74, v79, v199                              // 0000000022F4: D6580045 071E9F4A
	v_fma_mixlo_f16 v74, v89, v115, 0                          // 0000000022FC: CC21004A 0202E759
	s_waitcnt lgkmcnt(3)                                       // 000000002304: BF89FC37
	v_fma_mixlo_f16 v71, v89, v76, 0                           // 000000002308: CC210047 02029959
	ds_store_b16 v171, v73 offset:24                           // 000000002310: D87C0018 000049AB
	ds_store_b64 v179, v[66:67] offset:3264                    // 000000002318: D9340CC0 000042B3
	ds_store_b16 v173, v72 offset:24                           // 000000002320: D87C0018 000048AD
	ds_store_b16 v174, v74 offset:24                           // 000000002328: D87C0018 00004AAE
	ds_store_b16 v175, v70 offset:24                           // 000000002330: D87C0018 000046AF
	ds_store_b16 v176, v71 offset:24                           // 000000002338: D87C0018 000047B0
	ds_store_b64 v180, v[68:69] offset:3264                    // 000000002340: D9340CC0 000044B4
	s_and_saveexec_b32 s17, s0                                 // 000000002348: BE912000
	v_dual_mov_b32 v66, v98 :: v_dual_mov_b32 v67, v95         // 00000000234C: CA100162 4242015F
	s_or_b32 s5, s14, exec_lo                                  // 000000002354: 8C057E0E
	s_or_b32 exec_lo, exec_lo, s17                             // 000000002358: 8C7E117E
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 00000000235C: BF8704A9
	s_and_not1_b32 s14, s14, exec_lo                           // 000000002360: 910E7E0E
	s_and_b32 s5, s5, exec_lo                                  // 000000002364: 8B057E05
	s_or_b32 s14, s14, s5                                      // 000000002368: 8C0E050E
	s_or_b32 exec_lo, exec_lo, s15                             // 00000000236C: 8C7E0F7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002370: BF870009
	s_and_b32 exec_lo, exec_lo, s14                            // 000000002374: 8B7E0E7E
	s_cbranch_execz 4                                          // 000000002378: BFA50004 <attn_pfd+0x238c>
	ds_store_b32 v165, v67 offset:48                           // 00000000237C: D8340030 000043A5
	ds_store_b32 v164, v66 offset:48                           // 000000002384: D8340030 000042A4
	s_or_b32 exec_lo, exec_lo, s6                              // 00000000238C: 8C7E067E
	s_waitcnt lgkmcnt(0)                                       // 000000002390: BF89FC07
	s_barrier                                                  // 000000002394: BFBD0000
	s_and_saveexec_b32 s14, s3                                 // 000000002398: BE8E2003
	s_cbranch_execz 64781                                      // 00000000239C: BFA5FD0D <attn_pfd+0x17d4>
	v_add_nc_u32_e32 v115, 16, v65                             // 0000000023A0: 4AE68290
	s_mov_b32 s15, exec_lo                                     // 0000000023A4: BE8F007E
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000023A8: BF870001
	v_cmpx_gt_u32_e64 s28, v115                                // 0000000023AC: D4CC007E 0002E61C
	s_cbranch_execz 58                                         // 0000000023B4: BFA5003A <attn_pfd+0x24a0>
	v_lshlrev_b64 v[66:67], 5, v[115:116]                      // 0000000023B8: D73C0042 0002E685
	v_lshlrev_b64 v[68:69], 7, v[115:116]                      // 0000000023C0: D73C0044 0002E687
	v_lshlrev_b64 v[72:73], 2, v[115:116]                      // 0000000023C8: D73C0048 0002E682
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000023D0: BF870093
	v_add_co_u32 v66, s5, s29, v66                             // 0000000023D4: D7000542 0002841D
	v_add_co_ci_u32_e64 v67, s5, s30, v67, s5                  // 0000000023DC: D5200543 0016861E
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000023E4: BF870194
	v_add_co_u32 v70, s6, v132, v68                            // 0000000023E8: D7000646 00028984
	v_add_co_u32 v66, s5, v66, v129                            // 0000000023F0: D7000542 00030342
	v_add_co_ci_u32_e64 v71, s6, v134, v69, s6                 // 0000000023F8: D5200647 001A8B86
	v_add_co_u32 v68, s6, v135, v68                            // 000000002400: D7000644 00028987
	v_add_co_ci_u32_e64 v75, s5, 0, v67, s5                    // 000000002408: D520054B 00168680
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002410: BF870004
	v_and_b32_e32 v74, -4, v66                                 // 000000002414: 369484C4
	v_add_co_u32 v72, s5, s31, v72                             // 000000002418: D7000548 0002901F
	v_add_co_ci_u32_e64 v69, s6, v136, v69, s6                 // 000000002420: D5200645 001A8B88
	v_add_co_ci_u32_e64 v73, s5, s33, v73, s5                  // 000000002428: D5200549 00169221
	flat_load_b32 v67, v[74:75]                                // 000000002430: DC500000 437C004A
	s_clause 0x2                                               // 000000002438: BF850002
	global_load_b32 v84, v[70:71], off                         // 00000000243C: DC520000 547C0046
	global_load_b32 v81, v[68:69], off                         // 000000002444: DC520000 517C0044
	global_load_b32 v87, v[72:73], off                         // 00000000244C: DC520000 577C0048
	s_and_saveexec_b32 s6, s0                                  // 000000002454: BE862000
	s_cbranch_execz 12                                         // 000000002458: BFA5000C <attn_pfd+0x248c>
	v_lshlrev_b64 v[68:69], 3, v[115:116]                      // 00000000245C: D73C0044 0002E683
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002464: BF870091
	v_add_co_u32 v68, s5, s34, v68                             // 000000002468: D7000544 00028822
	v_add_co_ci_u32_e64 v69, s5, s35, v69, s5                  // 000000002470: D5200545 00168A23
	global_load_b64 v[68:69], v[68:69], off                    // 000000002478: DC560000 447C0044
	s_waitcnt vmcnt(0)                                         // 000000002480: BF8903F7
	v_dual_mov_b32 v93, v68 :: v_dual_mov_b32 v96, v69         // 000000002484: CA100144 5D600145
	s_or_b32 exec_lo, exec_lo, s6                              // 00000000248C: 8C7E067E
	v_lshlrev_b32_e32 v66, 3, v66                              // 000000002490: 30848483
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 000000002494: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002498: BF870001
	v_lshrrev_b32_e32 v90, v66, v67                            // 00000000249C: 32B48742
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000024A0: 8C7E0F7E
	v_add_nc_u32_e32 v115, 22, v65                             // 0000000024A4: 4AE68296
	s_mov_b32 s15, exec_lo                                     // 0000000024A8: BE8F007E
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000024AC: BF870001
	v_cmpx_gt_u32_e64 s28, v115                                // 0000000024B0: D4CC007E 0002E61C
	s_cbranch_execz 58                                         // 0000000024B8: BFA5003A <attn_pfd+0x25a4>
	v_lshlrev_b64 v[66:67], 5, v[115:116]                      // 0000000024BC: D73C0042 0002E685
	v_lshlrev_b64 v[68:69], 7, v[115:116]                      // 0000000024C4: D73C0044 0002E687
	v_lshlrev_b64 v[72:73], 2, v[115:116]                      // 0000000024CC: D73C0048 0002E682
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000024D4: BF870093
	v_add_co_u32 v66, s5, s29, v66                             // 0000000024D8: D7000542 0002841D
	v_add_co_ci_u32_e64 v67, s5, s30, v67, s5                  // 0000000024E0: D5200543 0016861E
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000024E8: BF870194
	v_add_co_u32 v70, s6, v132, v68                            // 0000000024EC: D7000646 00028984
	v_add_co_u32 v66, s5, v66, v129                            // 0000000024F4: D7000542 00030342
	v_add_co_ci_u32_e64 v71, s6, v134, v69, s6                 // 0000000024FC: D5200647 001A8B86
	v_add_co_u32 v68, s6, v135, v68                            // 000000002504: D7000644 00028987
	v_add_co_ci_u32_e64 v75, s5, 0, v67, s5                    // 00000000250C: D520054B 00168680
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002514: BF870004
	v_and_b32_e32 v74, -4, v66                                 // 000000002518: 369484C4
	v_add_co_u32 v72, s5, s31, v72                             // 00000000251C: D7000548 0002901F
	v_add_co_ci_u32_e64 v69, s6, v136, v69, s6                 // 000000002524: D5200645 001A8B88
	v_add_co_ci_u32_e64 v73, s5, s33, v73, s5                  // 00000000252C: D5200549 00169221
	flat_load_b32 v67, v[74:75]                                // 000000002534: DC500000 437C004A
	s_clause 0x2                                               // 00000000253C: BF850002
	global_load_b32 v85, v[70:71], off                         // 000000002540: DC520000 557C0046
	global_load_b32 v82, v[68:69], off                         // 000000002548: DC520000 527C0044
	global_load_b32 v88, v[72:73], off                         // 000000002550: DC520000 587C0048
	s_and_saveexec_b32 s6, s0                                  // 000000002558: BE862000
	s_cbranch_execz 12                                         // 00000000255C: BFA5000C <attn_pfd+0x2590>
	v_lshlrev_b64 v[68:69], 3, v[115:116]                      // 000000002560: D73C0044 0002E683
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002568: BF870091
	v_add_co_u32 v68, s5, s34, v68                             // 00000000256C: D7000544 00028822
	v_add_co_ci_u32_e64 v69, s5, s35, v69, s5                  // 000000002574: D5200545 00168A23
	global_load_b64 v[68:69], v[68:69], off                    // 00000000257C: DC560000 447C0044
	s_waitcnt vmcnt(0)                                         // 000000002584: BF8903F7
	v_dual_mov_b32 v94, v68 :: v_dual_mov_b32 v97, v69         // 000000002588: CA100144 5E600145
	s_or_b32 exec_lo, exec_lo, s6                              // 000000002590: 8C7E067E
	v_lshlrev_b32_e32 v66, 3, v66                              // 000000002594: 30848483
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 000000002598: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000259C: BF870001
	v_lshrrev_b32_e32 v91, v66, v67                            // 0000000025A0: 32B68742
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000025A4: 8C7E0F7E
	v_add_nc_u32_e32 v115, 28, v65                             // 0000000025A8: 4AE6829C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000025AC: BF870091
	v_cmp_gt_u32_e64 s5, s28, v115                             // 0000000025B0: D44C0005 0002E61C
	s_and_b32 s5, s2, s5                                       // 0000000025B8: 8B050502
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000025BC: BF870009
	s_and_saveexec_b32 s15, s5                                 // 0000000025C0: BE8F2005
	s_cbranch_execz 58                                         // 0000000025C4: BFA5003A <attn_pfd+0x26b0>
	v_lshlrev_b64 v[65:66], 5, v[115:116]                      // 0000000025C8: D73C0041 0002E685
	v_lshlrev_b64 v[67:68], 7, v[115:116]                      // 0000000025D0: D73C0043 0002E687
	v_lshlrev_b64 v[71:72], 2, v[115:116]                      // 0000000025D8: D73C0047 0002E682
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000025E0: BF870093
	v_add_co_u32 v65, s5, s29, v65                             // 0000000025E4: D7000541 0002821D
	v_add_co_ci_u32_e64 v66, s5, s30, v66, s5                  // 0000000025EC: D5200542 0016841E
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 0000000025F4: BF870194
	v_add_co_u32 v69, s6, v132, v67                            // 0000000025F8: D7000645 00028784
	v_add_co_u32 v65, s5, v65, v129                            // 000000002600: D7000541 00030341
	v_add_co_ci_u32_e64 v70, s6, v134, v68, s6                 // 000000002608: D5200646 001A8986
	v_add_co_u32 v67, s6, v135, v67                            // 000000002610: D7000643 00028787
	v_add_co_ci_u32_e64 v74, s5, 0, v66, s5                    // 000000002618: D520054A 00168480
	s_delay_alu instid0(VALU_DEP_4)                            // 000000002620: BF870004
	v_and_b32_e32 v73, -4, v65                                 // 000000002624: 369282C4
	v_add_co_u32 v71, s5, s31, v71                             // 000000002628: D7000547 00028E1F
	v_add_co_ci_u32_e64 v68, s6, v136, v68, s6                 // 000000002630: D5200644 001A8988
	v_add_co_ci_u32_e64 v72, s5, s33, v72, s5                  // 000000002638: D5200548 00169021
	flat_load_b32 v66, v[73:74]                                // 000000002640: DC500000 427C0049
	s_clause 0x2                                               // 000000002648: BF850002
	global_load_b32 v86, v[69:70], off                         // 00000000264C: DC520000 567C0045
	global_load_b32 v83, v[67:68], off                         // 000000002654: DC520000 537C0043
	global_load_b32 v89, v[71:72], off                         // 00000000265C: DC520000 597C0047
	s_and_saveexec_b32 s6, s0                                  // 000000002664: BE862000
	s_cbranch_execz 12                                         // 000000002668: BFA5000C <attn_pfd+0x269c>
	v_lshlrev_b64 v[67:68], 3, v[115:116]                      // 00000000266C: D73C0043 0002E683
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002674: BF870091
	v_add_co_u32 v67, s5, s34, v67                             // 000000002678: D7000543 00028622
	v_add_co_ci_u32_e64 v68, s5, s35, v68, s5                  // 000000002680: D5200544 00168823
	global_load_b64 v[67:68], v[67:68], off                    // 000000002688: DC560000 437C0043
	s_waitcnt vmcnt(0)                                         // 000000002690: BF8903F7
	v_dual_mov_b32 v95, v67 :: v_dual_mov_b32 v98, v68         // 000000002694: CA100143 5F620144
	s_or_b32 exec_lo, exec_lo, s6                              // 00000000269C: 8C7E067E
	v_lshlrev_b32_e32 v65, 3, v65                              // 0000000026A0: 30828283
	s_waitcnt vmcnt(3) lgkmcnt(0)                              // 0000000026A4: BF890C07
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000026A8: BF870001
	v_lshrrev_b32_e32 v92, v65, v66                            // 0000000026AC: 32B88541
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000026B0: 8C7E0F7E
	flat_load_b128 v[196:199], v[119:120]                      // 0000000026B4: DC5C0000 C47C0077
	ds_load_b128 v[200:203], v158 offset:8192                  // 0000000026BC: DBFC2000 C800009E
	s_mov_b32 s23, s16                                         // 0000000026C4: BE970010
	s_mov_b32 s17, s16                                         // 0000000026C8: BE910010
	s_mov_b32 s18, s16                                         // 0000000026CC: BE920010
	s_mov_b32 s19, s16                                         // 0000000026D0: BE930010
	s_mov_b32 s20, s16                                         // 0000000026D4: BE940010
	s_mov_b32 s21, s16                                         // 0000000026D8: BE950010
	s_mov_b32 s22, s16                                         // 0000000026DC: BE960010
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000026E0: BF870009
	v_dual_mov_b32 v72, s23 :: v_dual_mov_b32 v71, s22         // 0000000026E4: CA100017 48460016
	v_dual_mov_b32 v70, s21 :: v_dual_mov_b32 v69, s20         // 0000000026EC: CA100015 46440014
	v_dual_mov_b32 v68, s19 :: v_dual_mov_b32 v67, s18         // 0000000026F4: CA100013 44420012
	v_dual_mov_b32 v66, s17 :: v_dual_mov_b32 v65, s16         // 0000000026FC: CA100011 42400010
	flat_load_b128 v[204:207], v[117:118]                      // 000000002704: DC5C0000 CC7C0075
	flat_load_b128 v[208:211], v[119:120] offset:16            // 00000000270C: DC5C0010 D07C0077
	ds_load_b128 v[212:215], v158 offset:8208                  // 000000002714: DBFC2010 D400009E
	s_waitcnt vmcnt(2) lgkmcnt(3)                              // 00000000271C: BF890837
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002720: CC444049 7D0791C4
	flat_load_b128 v[196:199], v[117:118] offset:16            // 000000002728: DC5C0010 C47C0075
	ds_load_b128 v[200:203], v158 offset:12544                 // 000000002730: DBFC3100 C800009E
	ds_load_b128 v[216:219], v158 offset:12560                 // 000000002738: DBFC3110 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(3)                              // 000000002740: BF890437
	v_wmma_i32_16x16x16_iu8 v[73:80], v[208:211], v[212:215], v[73:80] neg_lo:[1,1,0]// 000000002744: CC444049 7D27A9D0
	ds_load_b128 v[208:211], v158 offset:12592                 // 00000000274C: DBFC3130 D000009E
	flat_load_b128 v[212:215], v[119:120] offset:48            // 000000002754: DC5C0030 D47C0077
	s_waitcnt lgkmcnt(3)                                       // 00000000275C: BF89FC37
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002760: CC444041 7D0791CC
	ds_load_b128 v[200:203], v158 offset:12576                 // 000000002768: DBFC3120 C800009E
	flat_load_b128 v[204:207], v[117:118] offset:48            // 000000002770: DC5C0030 CC7C0075
	s_waitcnt vmcnt(2) lgkmcnt(4)                              // 000000002778: BF890847
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[216:219], v[65:72] neg_lo:[1,1,0]// 00000000277C: CC444041 7D07B1C4
	flat_load_b128 v[196:199], v[117:118] offset:32            // 000000002784: DC5C0020 C47C0075
	ds_load_b128 v[216:219], v158 offset:8240                  // 00000000278C: DBFC2030 D800009E
	s_waitcnt vmcnt(0) lgkmcnt(1)                              // 000000002794: BF890017
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002798: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:32            // 0000000027A0: DC5C0020 C47C0077
	ds_load_b128 v[200:203], v158 offset:8224                  // 0000000027A8: DBFC2020 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 0000000027B0: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:80            // 0000000027B8: DC5C0050 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12624                 // 0000000027C0: DBFC3150 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 0000000027C8: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 0000000027CC: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:64            // 0000000027D4: DC5C0040 C47C0075
	ds_load_b128 v[200:203], v158 offset:12608                 // 0000000027DC: DBFC3140 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 0000000027E4: CC444049 7D27B1D4
	flat_load_b128 v[212:215], v[119:120] offset:80            // 0000000027EC: DC5C0050 D47C0077
	ds_load_b128 v[216:219], v158 offset:8272                  // 0000000027F4: DBFC2050 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 0000000027FC: BF890427
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002800: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:64            // 000000002808: DC5C0040 C47C0077
	ds_load_b128 v[200:203], v158 offset:8256                  // 000000002810: DBFC2040 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 000000002818: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:112           // 000000002820: DC5C0070 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12656                 // 000000002828: DBFC3170 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002830: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 000000002834: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:96            // 00000000283C: DC5C0060 C47C0075
	ds_load_b128 v[200:203], v158 offset:12640                 // 000000002844: DBFC3160 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 00000000284C: CC444049 7D27B1D4
	flat_load_b128 v[212:215], v[119:120] offset:112           // 000000002854: DC5C0070 D47C0077
	ds_load_b128 v[216:219], v158 offset:8304                  // 00000000285C: DBFC2070 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002864: BF890427
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002868: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:96            // 000000002870: DC5C0060 C47C0077
	ds_load_b128 v[200:203], v158 offset:8288                  // 000000002878: DBFC2060 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 000000002880: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:144           // 000000002888: DC5C0090 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12688                 // 000000002890: DBFC3190 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002898: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 00000000289C: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:128           // 0000000028A4: DC5C0080 C47C0075
	ds_load_b128 v[200:203], v158 offset:12672                 // 0000000028AC: DBFC3180 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 0000000028B4: CC444049 7D27B1D4
	flat_load_b128 v[212:215], v[119:120] offset:144           // 0000000028BC: DC5C0090 D47C0077
	ds_load_b128 v[216:219], v158 offset:8336                  // 0000000028C4: DBFC2090 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 0000000028CC: BF890427
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 0000000028D0: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:128           // 0000000028D8: DC5C0080 C47C0077
	ds_load_b128 v[200:203], v158 offset:8320                  // 0000000028E0: DBFC2080 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 0000000028E8: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:176           // 0000000028F0: DC5C00B0 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12720                 // 0000000028F8: DBFC31B0 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002900: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 000000002904: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:160           // 00000000290C: DC5C00A0 C47C0075
	ds_load_b128 v[200:203], v158 offset:12704                 // 000000002914: DBFC31A0 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 00000000291C: CC444049 7D27B1D4
	flat_load_b128 v[212:215], v[119:120] offset:176           // 000000002924: DC5C00B0 D47C0077
	ds_load_b128 v[216:219], v158 offset:8368                  // 00000000292C: DBFC20B0 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002934: BF890427
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 000000002938: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:160           // 000000002940: DC5C00A0 C47C0077
	ds_load_b128 v[200:203], v158 offset:8352                  // 000000002948: DBFC20A0 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 000000002950: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:208           // 000000002958: DC5C00D0 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12752                 // 000000002960: DBFC31D0 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 000000002968: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 00000000296C: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:192           // 000000002974: DC5C00C0 C47C0075
	ds_load_b128 v[200:203], v158 offset:12736                 // 00000000297C: DBFC31C0 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 000000002984: CC444049 7D27B1D4
	flat_load_b128 v[212:215], v[119:120] offset:208           // 00000000298C: DC5C00D0 D47C0077
	ds_load_b128 v[216:219], v158 offset:8400                  // 000000002994: DBFC20D0 D800009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 00000000299C: BF890427
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 0000000029A0: CC444041 7D0791C4
	flat_load_b128 v[196:199], v[119:120] offset:192           // 0000000029A8: DC5C00C0 C47C0077
	ds_load_b128 v[200:203], v158 offset:8384                  // 0000000029B0: DBFC20C0 C800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 0000000029B8: CC444041 7D07A1CC
	flat_load_b128 v[204:207], v[117:118] offset:240           // 0000000029C0: DC5C00F0 CC7C0075
	ds_load_b128 v[208:211], v158 offset:12784                 // 0000000029C8: DBFC31F0 D000009E
	s_waitcnt vmcnt(1) lgkmcnt(2)                              // 0000000029D0: BF890427
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[200:203], v[73:80] neg_lo:[1,1,0]// 0000000029D4: CC444049 7D2791C4
	flat_load_b128 v[196:199], v[117:118] offset:224           // 0000000029DC: DC5C00E0 C47C0075
	ds_load_b128 v[200:203], v158 offset:12768                 // 0000000029E4: DBFC31E0 C800009E
	v_wmma_i32_16x16x16_iu8 v[73:80], v[212:215], v[216:219], v[73:80] neg_lo:[1,1,0]// 0000000029EC: CC444049 7D27B1D4
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000029F4: BF890007
	v_wmma_i32_16x16x16_iu8 v[65:72], v[196:199], v[200:203], v[65:72] neg_lo:[1,1,0]// 0000000029F8: CC444041 7D0791C4
	s_clause 0x1                                               // 000000002A00: BF850001
	flat_load_b128 v[196:199], v[119:120] offset:224           // 000000002A04: DC5C00E0 C47C0077
	flat_load_b128 v[200:203], v[119:120] offset:240           // 000000002A0C: DC5C00F0 C87C0077
	ds_load_b128 v[212:215], v158 offset:8416                  // 000000002A14: DBFC20E0 D400009E
	ds_load_b128 v[216:219], v158 offset:8432                  // 000000002A1C: DBFC20F0 D800009E
	v_wmma_i32_16x16x16_iu8 v[65:72], v[204:207], v[208:211], v[65:72] neg_lo:[1,1,0]// 000000002A24: CC444041 7D07A1CC
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002A2C: BF870091
	v_cvt_f32_i32_e32 v65, v65                                 // 000000002A30: 7E820B41
	v_mul_f32_e32 v65, v107, v65                               // 000000002A34: 1082836B
	s_waitcnt vmcnt(1) lgkmcnt(1)                              // 000000002A38: BF890417
	v_wmma_i32_16x16x16_iu8 v[73:80], v[196:199], v[212:215], v[73:80] neg_lo:[1,1,0]// 000000002A3C: CC444049 7D27A9C4
	ds_load_b32 v196, v160                                     // 000000002A44: D8D80000 C40000A0
	ds_load_b32 v115, v159                                     // 000000002A4C: D8D80000 7300009F
	v_add_nc_u32_e32 v197, s25, v144                           // 000000002A54: 4B8B2019
	s_waitcnt vmcnt(0) lgkmcnt(2)                              // 000000002A58: BF890027
	v_wmma_i32_16x16x16_iu8 v[73:80], v[200:203], v[216:219], v[73:80] neg_lo:[1,1,0]// 000000002A5C: CC444049 7D27B1C8
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000002A64: BF8701A2
	v_cmp_gt_u32_e64 s5, s28, v197                             // 000000002A68: D44C0005 00038A1C
	v_cmp_le_i32_e64 s6, v197, v149                            // 000000002A70: D4430006 00032BC5
	v_cvt_f32_i32_e32 v73, v73                                 // 000000002A78: 7E920B49
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002A7C: BF870092
	s_and_b32 s6, s6, s5                                       // 000000002A80: 8B060506
	v_mul_f32_e32 v73, v99, v73                                // 000000002A84: 10929363
	s_waitcnt lgkmcnt(1)                                       // 000000002A88: BF89FC17
	v_mul_f32_e32 v65, v196, v65                               // 000000002A8C: 108283C4
	s_waitcnt lgkmcnt(0)                                       // 000000002A90: BF89FC07
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002A94: BF870091
	v_fmac_f32_e32 v65, v73, v115                              // 000000002A98: 5682E749
	v_cndmask_b32_e64 v73, 0xf149f2ca, v65, s6                 // 000000002A9C: D5010049 001A82FF F149F2CA
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AA8: BF870091
	v_mov_b32_e32 v65, v73                                     // 000000002AAC: 7E820349
	v_mov_b32_dpp v65, v65 row_shr:1 row_mask:0xf bank_mask:0xf// 000000002AB0: 7E8202FA FF011141
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AB8: BF870091
	v_max_f32_e32 v65, v65, v65                                // 000000002ABC: 20828341
	v_max_f32_e32 v65, v73, v65                                // 000000002AC0: 20828349
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AC4: BF870091
	v_mov_b32_e32 v198, v65                                    // 000000002AC8: 7F8C0341
	v_mov_b32_dpp v198, v198 row_shr:2 row_mask:0xf bank_mask:0xf// 000000002ACC: 7F8C02FA FF0112C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AD4: BF870091
	v_max_f32_e32 v198, v198, v198                             // 000000002AD8: 218D8DC6
	v_max_f32_e32 v65, v65, v198                               // 000000002ADC: 20838D41
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AE0: BF870091
	v_mov_b32_e32 v198, v65                                    // 000000002AE4: 7F8C0341
	v_mov_b32_dpp v198, v198 row_shr:4 row_mask:0xf bank_mask:0xf// 000000002AE8: 7F8C02FA FF0114C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AF0: BF870091
	v_max_f32_e32 v198, v198, v198                             // 000000002AF4: 218D8DC6
	v_max_f32_e32 v65, v65, v198                               // 000000002AF8: 20838D41
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002AFC: BF870091
	v_mov_b32_e32 v198, v65                                    // 000000002B00: 7F8C0341
	v_mov_b32_dpp v198, v198 row_shr:8 row_mask:0xf bank_mask:0xf// 000000002B04: 7F8C02FA FF0118C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002B0C: BF870091
	v_max_f32_e32 v198, v198, v198                             // 000000002B10: 218D8DC6
	v_max_f32_e32 v65, v65, v198                               // 000000002B14: 20838D41
	s_and_saveexec_b32 s15, s4                                 // 000000002B18: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002B1C: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 000000002B20: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000002B24: BFA50003 <attn_pfd+0x2b34>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002B28: BF870001
	v_readlane_b32 s6, v65, 31                                 // 000000002B2C: D7600006 00013F41
	s_or_saveexec_b32 s15, s15                                 // 000000002B34: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002B38: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002B3C: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002B40: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000002B44: BFA50004 <attn_pfd+0x2b58>
	v_readlane_b32 s6, v65, 15                                 // 000000002B48: D7600006 00011F41
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002B50: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002B54: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000002B58: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002B5C: BF870091
	v_dual_max_f32 v65, v198, v198 :: v_dual_max_f32 v198, v191, v191// 000000002B60: CA958DC6 41C77FBF
	v_max_f32_e32 v65, v198, v65                               // 000000002B68: 208283C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002B6C: BF870091
	v_sub_f32_e32 v73, v73, v65                                // 000000002B70: 08928349
	v_mul_f32_e32 v198, 0x3fb8aa3b, v73                        // 000000002B74: 118C92FF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002B7C: BF8700A1
	v_fma_f32 v199, 0x3fb8aa3b, v73, -v198                     // 000000002B80: D61300C7 871A92FF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 000000002B8C: 7F9047C6
	v_dual_sub_f32 v198, v198, v200 :: v_dual_fmac_f32 v199, 0x32a5705f, v73// 000000002B90: C94191C6 C6C692FF 32A5705F
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v73                      // 000000002B9C: D41B0006 000292FF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002BA8: BF870122
	v_add_f32_e32 v198, v198, v199                             // 000000002BAC: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000002BB0: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 000000002BB4: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000002BB8: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 000000002BBC: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002BC4: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 000000002BC8: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v73                      // 000000002BD0: D41E0006 000292FF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 000000002BDC: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002BE8: BF870091
	v_add_f32_dpp v73, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BEC: 06938CFA FF0911C6
	v_add_f32_dpp v73, v73, v73 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002BF4: 069292FA FF091249
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002BFC: BF870091
	v_add_f32_dpp v73, v73, v73 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C00: 069292FA FF091449
	v_add_f32_dpp v199, v73, v73 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002C08: 078E92FA FF091849
	s_and_saveexec_b32 s15, s4                                 // 000000002C10: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002C14: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 000000002C18: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000002C1C: BFA50003 <attn_pfd+0x2c2c>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002C20: BF870001
	v_readlane_b32 s6, v199, 31                                // 000000002C24: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 000000002C2C: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002C30: BF870001
	v_mov_b32_e32 v73, s6                                      // 000000002C34: 7E920206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002C38: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000002C3C: BFA50004 <attn_pfd+0x2c50>
	v_readlane_b32 s6, v199, 15                                // 000000002C40: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002C48: BF870001
	v_mov_b32_e32 v73, s6                                      // 000000002C4C: 7E920206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000002C50: 8C7E0F7E
	v_cvt_f32_i32_e32 v66, v66                                 // 000000002C54: 7E840B42
	v_cvt_f32_i32_e32 v74, v74                                 // 000000002C58: 7E940B4A
	v_cmp_le_i32_e64 s6, v197, v150                            // 000000002C5C: D4430006 00032DC5
	v_cvt_f16_f32_e64 v198, v198                               // 000000002C64: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002C6C: BF870214
	v_mul_f32_e32 v66, v108, v66                               // 000000002C70: 1084856C
	v_mul_f32_e32 v74, v100, v74                               // 000000002C74: 10949564
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002C78: BF8700B4
	s_and_b32 s6, s6, s5                                       // 000000002C7C: 8B060506
	ds_store_b16 v177, v198                                    // 000000002C80: D87C0000 0000C6B1
	v_mul_f32_e32 v66, v196, v66                               // 000000002C88: 108485C4
	v_fmac_f32_e32 v66, v74, v115                              // 000000002C8C: 5684E74A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002C90: BF870091
	v_cndmask_b32_e64 v74, 0xf149f2ca, v66, s6                 // 000000002C94: D501004A 001A84FF F149F2CA
	v_mov_b32_e32 v66, v74                                     // 000000002CA0: 7E84034A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CA4: BF870091
	v_mov_b32_dpp v66, v66 row_shr:1 row_mask:0xf bank_mask:0xf// 000000002CA8: 7E8402FA FF011142
	v_max_f32_e32 v66, v66, v66                                // 000000002CB0: 20848542
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CB4: BF870091
	v_max_f32_e32 v66, v74, v66                                // 000000002CB8: 2084854A
	v_mov_b32_e32 v199, v66                                    // 000000002CBC: 7F8E0342
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CC0: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 000000002CC4: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 000000002CCC: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CD0: BF870091
	v_max_f32_e32 v66, v66, v199                               // 000000002CD4: 20858F42
	v_mov_b32_e32 v199, v66                                    // 000000002CD8: 7F8E0342
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CDC: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 000000002CE0: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 000000002CE8: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CEC: BF870091
	v_max_f32_e32 v66, v66, v199                               // 000000002CF0: 20858F42
	v_mov_b32_e32 v199, v66                                    // 000000002CF4: 7F8E0342
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002CF8: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 000000002CFC: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 000000002D04: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000002D08: BF8704A1
	v_max_f32_e32 v66, v66, v199                               // 000000002D0C: 20858F42
	s_and_saveexec_b32 s15, s4                                 // 000000002D10: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 000000002D14: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000002D18: BFA50003 <attn_pfd+0x2d28>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002D1C: BF870001
	v_readlane_b32 s6, v66, 31                                 // 000000002D20: D7600006 00013F42
	s_or_saveexec_b32 s15, s15                                 // 000000002D28: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002D2C: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002D30: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002D34: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000002D38: BFA50004 <attn_pfd+0x2d4c>
	v_readlane_b32 s6, v66, 15                                 // 000000002D3C: D7600006 00011F42
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002D44: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002D48: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000002D4C: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002D50: BF8700A1
	v_max_f32_e32 v66, v198, v198                              // 000000002D54: 20858DC6
	v_max_f32_e32 v198, v194, v194                             // 000000002D58: 218D85C2
	v_max_f32_e32 v66, v198, v66                               // 000000002D5C: 208485C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002D60: BF870091
	v_sub_f32_e32 v74, v74, v66                                // 000000002D64: 0894854A
	v_mul_f32_e32 v198, 0x3fb8aa3b, v74                        // 000000002D68: 118C94FF 3FB8AA3B
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v74                      // 000000002D70: D41B0006 000294FF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002D7C: BF8700A2
	v_fma_f32 v199, 0x3fb8aa3b, v74, -v198                     // 000000002D80: D61300C7 871A94FF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 000000002D8C: 7F9047C6
	v_dual_fmac_f32 v199, 0x32a5705f, v74 :: v_dual_sub_f32 v198, v198, v200// 000000002D90: C80A94FF C7C791C6 32A5705F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002D9C: BF870121
	v_add_f32_e32 v198, v198, v199                             // 000000002DA0: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000002DA4: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 000000002DA8: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000002DAC: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 000000002DB0: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002DB8: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 000000002DBC: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v74                      // 000000002DC4: D41E0006 000294FF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 000000002DD0: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002DDC: BF870091
	v_add_f32_dpp v74, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002DE0: 06958CFA FF0911C6
	v_add_f32_dpp v74, v74, v74 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002DE8: 069494FA FF09124A
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002DF0: BF870091
	v_add_f32_dpp v74, v74, v74 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002DF4: 069494FA FF09144A
	v_add_f32_dpp v199, v74, v74 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002DFC: 078E94FA FF09184A
	s_and_saveexec_b32 s15, s4                                 // 000000002E04: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002E08: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 000000002E0C: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000002E10: BFA50003 <attn_pfd+0x2e20>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002E14: BF870001
	v_readlane_b32 s6, v199, 31                                // 000000002E18: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 000000002E20: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002E24: BF870001
	v_mov_b32_e32 v74, s6                                      // 000000002E28: 7E940206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002E2C: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000002E30: BFA50004 <attn_pfd+0x2e44>
	v_readlane_b32 s6, v199, 15                                // 000000002E34: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002E3C: BF870001
	v_mov_b32_e32 v74, s6                                      // 000000002E40: 7E940206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000002E44: 8C7E0F7E
	v_cvt_f32_i32_e32 v67, v67                                 // 000000002E48: 7E860B43
	v_cvt_f32_i32_e32 v75, v75                                 // 000000002E4C: 7E960B4B
	v_cmp_le_i32_e64 s6, v197, v151                            // 000000002E50: D4430006 00032FC5
	v_cvt_f16_f32_e64 v198, v198                               // 000000002E58: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000002E60: BF870214
	v_mul_f32_e32 v67, v109, v67                               // 000000002E64: 1086876D
	v_mul_f32_e32 v75, v101, v75                               // 000000002E68: 10969765
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000002E6C: BF8700B4
	s_and_b32 s6, s6, s5                                       // 000000002E70: 8B060506
	ds_store_b16 v177, v198 offset:64                          // 000000002E74: D87C0040 0000C6B1
	v_mul_f32_e32 v67, v196, v67                               // 000000002E7C: 108687C4
	v_fmac_f32_e32 v67, v75, v115                              // 000000002E80: 5686E74B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002E84: BF870091
	v_cndmask_b32_e64 v75, 0xf149f2ca, v67, s6                 // 000000002E88: D501004B 001A86FF F149F2CA
	v_mov_b32_e32 v67, v75                                     // 000000002E94: 7E86034B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002E98: BF870091
	v_mov_b32_dpp v67, v67 row_shr:1 row_mask:0xf bank_mask:0xf// 000000002E9C: 7E8602FA FF011143
	v_max_f32_e32 v67, v67, v67                                // 000000002EA4: 20868743
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EA8: BF870091
	v_max_f32_e32 v67, v75, v67                                // 000000002EAC: 2086874B
	v_mov_b32_e32 v199, v67                                    // 000000002EB0: 7F8E0343
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EB4: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 000000002EB8: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 000000002EC0: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EC4: BF870091
	v_max_f32_e32 v67, v67, v199                               // 000000002EC8: 20878F43
	v_mov_b32_e32 v199, v67                                    // 000000002ECC: 7F8E0343
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002ED0: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 000000002ED4: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 000000002EDC: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EE0: BF870091
	v_max_f32_e32 v67, v67, v199                               // 000000002EE4: 20878F43
	v_mov_b32_e32 v199, v67                                    // 000000002EE8: 7F8E0343
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002EEC: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 000000002EF0: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 000000002EF8: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 000000002EFC: BF8704A1
	v_max_f32_e32 v67, v67, v199                               // 000000002F00: 20878F43
	s_and_saveexec_b32 s15, s4                                 // 000000002F04: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 000000002F08: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000002F0C: BFA50003 <attn_pfd+0x2f1c>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002F10: BF870001
	v_readlane_b32 s6, v67, 31                                 // 000000002F14: D7600006 00013F43
	s_or_saveexec_b32 s15, s15                                 // 000000002F1C: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002F20: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002F24: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000002F28: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000002F2C: BFA50004 <attn_pfd+0x2f40>
	v_readlane_b32 s6, v67, 15                                 // 000000002F30: D7600006 00011F43
	s_delay_alu instid0(VALU_DEP_1)                            // 000000002F38: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000002F3C: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000002F40: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002F44: BF870091
	v_dual_max_f32 v67, v198, v198 :: v_dual_max_f32 v198, v193, v193// 000000002F48: CA958DC6 43C783C1
	v_max_f32_e32 v67, v198, v67                               // 000000002F50: 208687C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002F54: BF870091
	v_sub_f32_e32 v75, v75, v67                                // 000000002F58: 0896874B
	v_mul_f32_e32 v198, 0x3fb8aa3b, v75                        // 000000002F5C: 118C96FF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002F64: BF8700A1
	v_fma_f32 v199, 0x3fb8aa3b, v75, -v198                     // 000000002F68: D61300C7 871A96FF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 000000002F74: 7F9047C6
	v_dual_sub_f32 v198, v198, v200 :: v_dual_fmac_f32 v199, 0x32a5705f, v75// 000000002F78: C94191C6 C6C696FF 32A5705F
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v75                      // 000000002F84: D41B0006 000296FF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000002F90: BF870122
	v_add_f32_e32 v198, v198, v199                             // 000000002F94: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000002F98: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 000000002F9C: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000002FA0: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 000000002FA4: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000002FAC: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 000000002FB0: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v75                      // 000000002FB8: D41E0006 000296FF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 000000002FC4: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002FD0: BF870091
	v_add_f32_dpp v75, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FD4: 06978CFA FF0911C6
	v_add_f32_dpp v75, v75, v75 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FDC: 069696FA FF09124B
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000002FE4: BF870091
	v_add_f32_dpp v75, v75, v75 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FE8: 069696FA FF09144B
	v_add_f32_dpp v199, v75, v75 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000002FF0: 078E96FA FF09184B
	s_and_saveexec_b32 s15, s4                                 // 000000002FF8: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000002FFC: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 000000003000: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000003004: BFA50003 <attn_pfd+0x3014>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003008: BF870001
	v_readlane_b32 s6, v199, 31                                // 00000000300C: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 000000003014: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003018: BF870001
	v_mov_b32_e32 v75, s6                                      // 00000000301C: 7E960206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000003020: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003024: BFA50004 <attn_pfd+0x3038>
	v_readlane_b32 s6, v199, 15                                // 000000003028: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003030: BF870001
	v_mov_b32_e32 v75, s6                                      // 000000003034: 7E960206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003038: 8C7E0F7E
	v_cvt_f32_i32_e32 v68, v68                                 // 00000000303C: 7E880B44
	v_cvt_f32_i32_e32 v76, v76                                 // 000000003040: 7E980B4C
	v_cmp_le_i32_e64 s6, v197, v152                            // 000000003044: D4430006 000331C5
	v_cvt_f16_f32_e64 v198, v198                               // 00000000304C: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000003054: BF870214
	v_mul_f32_e32 v68, v110, v68                               // 000000003058: 1088896E
	v_mul_f32_e32 v76, v102, v76                               // 00000000305C: 10989966
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000003060: BF8700B4
	s_and_b32 s6, s6, s5                                       // 000000003064: 8B060506
	ds_store_b16 v177, v198 offset:128                         // 000000003068: D87C0080 0000C6B1
	v_mul_f32_e32 v68, v196, v68                               // 000000003070: 108889C4
	v_fmac_f32_e32 v68, v76, v115                              // 000000003074: 5688E74C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003078: BF870091
	v_cndmask_b32_e64 v76, 0xf149f2ca, v68, s6                 // 00000000307C: D501004C 001A88FF F149F2CA
	v_mov_b32_e32 v68, v76                                     // 000000003088: 7E88034C
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000308C: BF870091
	v_mov_b32_dpp v68, v68 row_shr:1 row_mask:0xf bank_mask:0xf// 000000003090: 7E8802FA FF011144
	v_max_f32_e32 v68, v68, v68                                // 000000003098: 20888944
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000309C: BF870091
	v_max_f32_e32 v68, v76, v68                                // 0000000030A0: 2088894C
	v_mov_b32_e32 v199, v68                                    // 0000000030A4: 7F8E0344
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030A8: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 0000000030AC: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 0000000030B4: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030B8: BF870091
	v_max_f32_e32 v68, v68, v199                               // 0000000030BC: 20898F44
	v_mov_b32_e32 v199, v68                                    // 0000000030C0: 7F8E0344
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030C4: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 0000000030C8: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 0000000030D0: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030D4: BF870091
	v_max_f32_e32 v68, v68, v199                               // 0000000030D8: 20898F44
	v_mov_b32_e32 v199, v68                                    // 0000000030DC: 7F8E0344
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000030E0: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 0000000030E4: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 0000000030EC: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000030F0: BF8704A1
	v_max_f32_e32 v68, v68, v199                               // 0000000030F4: 20898F44
	s_and_saveexec_b32 s15, s4                                 // 0000000030F8: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 0000000030FC: 8D0F0F7E
	s_cbranch_execz 3                                          // 000000003100: BFA50003 <attn_pfd+0x3110>
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003104: BF870001
	v_readlane_b32 s6, v68, 31                                 // 000000003108: D7600006 00013F44
	s_or_saveexec_b32 s15, s15                                 // 000000003110: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003114: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000003118: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 00000000311C: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003120: BFA50004 <attn_pfd+0x3134>
	v_readlane_b32 s6, v68, 15                                 // 000000003124: D7600006 00011F44
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000312C: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000003130: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003134: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003138: BF8700A1
	v_max_f32_e32 v68, v198, v198                              // 00000000313C: 20898DC6
	v_max_f32_e32 v198, v192, v192                             // 000000003140: 218D81C0
	v_max_f32_e32 v68, v198, v68                               // 000000003144: 208889C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003148: BF870091
	v_sub_f32_e32 v76, v76, v68                                // 00000000314C: 0898894C
	v_mul_f32_e32 v198, 0x3fb8aa3b, v76                        // 000000003150: 118C98FF 3FB8AA3B
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v76                      // 000000003158: D41B0006 000298FF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000003164: BF870122
	v_fma_f32 v199, 0x3fb8aa3b, v76, -v198                     // 000000003168: D61300C7 871A98FF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 000000003174: 7F9047C6
	v_fmac_f32_e32 v199, 0x32a5705f, v76                       // 000000003178: 578E98FF 32A5705F
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003180: BF870092
	v_sub_f32_e32 v198, v198, v200                             // 000000003184: 098D91C6
	v_add_f32_e32 v198, v198, v199                             // 000000003188: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 00000000318C: 7F8E11C8
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000003190: BF8700B2
	v_exp_f32_e32 v198, v198                                   // 000000003194: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000003198: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 00000000319C: D71C00C6 00038FC6
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 0000000031A4: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v76                      // 0000000031AC: D41E0006 000298FF 42B17218
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000031B8: BF870091
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 0000000031BC: D50100C6 001B8CFF 7F800000
	v_add_f32_dpp v76, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031C8: 06998CFA FF0911C6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000031D0: BF870091
	v_add_f32_dpp v76, v76, v76 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031D4: 069898FA FF09124C
	v_add_f32_dpp v76, v76, v76 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031DC: 069898FA FF09144C
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000031E4: BF8704A1
	v_add_f32_dpp v199, v76, v76 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000031E8: 078E98FA FF09184C
	s_and_saveexec_b32 s15, s4                                 // 0000000031F0: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 0000000031F4: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000031F8: BFA50003 <attn_pfd+0x3208>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000031FC: BF870001
	v_readlane_b32 s6, v199, 31                                // 000000003200: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 000000003208: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000320C: BF870001
	v_mov_b32_e32 v76, s6                                      // 000000003210: 7E980206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000003214: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003218: BFA50004 <attn_pfd+0x322c>
	v_readlane_b32 s6, v199, 15                                // 00000000321C: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003224: BF870001
	v_mov_b32_e32 v76, s6                                      // 000000003228: 7E980206
	s_or_b32 exec_lo, exec_lo, s15                             // 00000000322C: 8C7E0F7E
	v_cvt_f32_i32_e32 v69, v69                                 // 000000003230: 7E8A0B45
	v_cvt_f32_i32_e32 v77, v77                                 // 000000003234: 7E9A0B4D
	v_cmp_le_i32_e64 s6, v197, v153                            // 000000003238: D4430006 000333C5
	v_cvt_f16_f32_e64 v198, v198                               // 000000003240: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000003248: BF870214
	v_mul_f32_e32 v69, v111, v69                               // 00000000324C: 108A8B6F
	v_mul_f32_e32 v77, v103, v77                               // 000000003250: 109A9B67
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000003254: BF8700B4
	s_and_b32 s6, s6, s5                                       // 000000003258: 8B060506
	ds_store_b16 v177, v198 offset:192                         // 00000000325C: D87C00C0 0000C6B1
	v_mul_f32_e32 v69, v196, v69                               // 000000003264: 108A8BC4
	v_fmac_f32_e32 v69, v77, v115                              // 000000003268: 568AE74D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000326C: BF870091
	v_cndmask_b32_e64 v77, 0xf149f2ca, v69, s6                 // 000000003270: D501004D 001A8AFF F149F2CA
	v_mov_b32_e32 v69, v77                                     // 00000000327C: 7E8A034D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003280: BF870091
	v_mov_b32_dpp v69, v69 row_shr:1 row_mask:0xf bank_mask:0xf// 000000003284: 7E8A02FA FF011145
	v_max_f32_e32 v69, v69, v69                                // 00000000328C: 208A8B45
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003290: BF870091
	v_max_f32_e32 v69, v77, v69                                // 000000003294: 208A8B4D
	v_mov_b32_e32 v199, v69                                    // 000000003298: 7F8E0345
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000329C: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 0000000032A0: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 0000000032A8: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032AC: BF870091
	v_max_f32_e32 v69, v69, v199                               // 0000000032B0: 208B8F45
	v_mov_b32_e32 v199, v69                                    // 0000000032B4: 7F8E0345
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032B8: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 0000000032BC: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 0000000032C4: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032C8: BF870091
	v_max_f32_e32 v69, v69, v199                               // 0000000032CC: 208B8F45
	v_mov_b32_e32 v199, v69                                    // 0000000032D0: 7F8E0345
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000032D4: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 0000000032D8: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 0000000032E0: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000032E4: BF8704A1
	v_max_f32_e32 v69, v69, v199                               // 0000000032E8: 208B8F45
	s_and_saveexec_b32 s15, s4                                 // 0000000032EC: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 0000000032F0: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000032F4: BFA50003 <attn_pfd+0x3304>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000032F8: BF870001
	v_readlane_b32 s6, v69, 31                                 // 0000000032FC: D7600006 00013F45
	s_or_saveexec_b32 s15, s15                                 // 000000003304: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003308: BF870001
	v_mov_b32_e32 v198, s6                                     // 00000000330C: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000003310: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003314: BFA50004 <attn_pfd+0x3328>
	v_readlane_b32 s6, v69, 15                                 // 000000003318: D7600006 00011F45
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003320: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000003324: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003328: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000332C: BF870091
	v_dual_max_f32 v69, v198, v198 :: v_dual_max_f32 v198, v189, v189// 000000003330: CA958DC6 45C77BBD
	v_max_f32_e32 v69, v198, v69                               // 000000003338: 208A8BC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000333C: BF870091
	v_sub_f32_e32 v77, v77, v69                                // 000000003340: 089A8B4D
	v_mul_f32_e32 v198, 0x3fb8aa3b, v77                        // 000000003344: 118C9AFF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000334C: BF8700A1
	v_fma_f32 v199, 0x3fb8aa3b, v77, -v198                     // 000000003350: D61300C7 871A9AFF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 00000000335C: 7F9047C6
	v_dual_sub_f32 v198, v198, v200 :: v_dual_fmac_f32 v199, 0x32a5705f, v77// 000000003360: C94191C6 C6C69AFF 32A5705F
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v77                      // 00000000336C: D41B0006 00029AFF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000003378: BF870122
	v_add_f32_e32 v198, v198, v199                             // 00000000337C: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000003380: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 000000003384: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000003388: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 00000000338C: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003394: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 000000003398: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v77                      // 0000000033A0: D41E0006 00029AFF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 0000000033AC: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000033B8: BF870091
	v_add_f32_dpp v77, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000033BC: 069B8CFA FF0911C6
	v_add_f32_dpp v77, v77, v77 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000033C4: 069A9AFA FF09124D
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000033CC: BF870091
	v_add_f32_dpp v77, v77, v77 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000033D0: 069A9AFA FF09144D
	v_add_f32_dpp v199, v77, v77 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000033D8: 078E9AFA FF09184D
	s_and_saveexec_b32 s15, s4                                 // 0000000033E0: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000033E4: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 0000000033E8: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000033EC: BFA50003 <attn_pfd+0x33fc>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000033F0: BF870001
	v_readlane_b32 s6, v199, 31                                // 0000000033F4: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 0000000033FC: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003400: BF870001
	v_mov_b32_e32 v77, s6                                      // 000000003404: 7E9A0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000003408: 8D7E0F7E
	s_cbranch_execz 4                                          // 00000000340C: BFA50004 <attn_pfd+0x3420>
	v_readlane_b32 s6, v199, 15                                // 000000003410: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003418: BF870001
	v_mov_b32_e32 v77, s6                                      // 00000000341C: 7E9A0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003420: 8C7E0F7E
	v_cvt_f32_i32_e32 v70, v70                                 // 000000003424: 7E8C0B46
	v_cvt_f32_i32_e32 v78, v78                                 // 000000003428: 7E9C0B4E
	v_cmp_le_i32_e64 s6, v197, v154                            // 00000000342C: D4430006 000335C5
	v_cvt_f16_f32_e64 v198, v198                               // 000000003434: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 00000000343C: BF870214
	v_mul_f32_e32 v70, v112, v70                               // 000000003440: 108C8D70
	v_mul_f32_e32 v78, v104, v78                               // 000000003444: 109C9D68
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000003448: BF8700B4
	s_and_b32 s6, s6, s5                                       // 00000000344C: 8B060506
	ds_store_b16 v177, v198 offset:256                         // 000000003450: D87C0100 0000C6B1
	v_mul_f32_e32 v70, v196, v70                               // 000000003458: 108C8DC4
	v_fmac_f32_e32 v70, v78, v115                              // 00000000345C: 568CE74E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003460: BF870091
	v_cndmask_b32_e64 v78, 0xf149f2ca, v70, s6                 // 000000003464: D501004E 001A8CFF F149F2CA
	v_mov_b32_e32 v70, v78                                     // 000000003470: 7E8C034E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003474: BF870091
	v_mov_b32_dpp v70, v70 row_shr:1 row_mask:0xf bank_mask:0xf// 000000003478: 7E8C02FA FF011146
	v_max_f32_e32 v70, v70, v70                                // 000000003480: 208C8D46
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003484: BF870091
	v_max_f32_e32 v70, v78, v70                                // 000000003488: 208C8D4E
	v_mov_b32_e32 v199, v70                                    // 00000000348C: 7F8E0346
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003490: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 000000003494: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 00000000349C: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000034A0: BF870091
	v_max_f32_e32 v70, v70, v199                               // 0000000034A4: 208D8F46
	v_mov_b32_e32 v199, v70                                    // 0000000034A8: 7F8E0346
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000034AC: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 0000000034B0: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 0000000034B8: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000034BC: BF870091
	v_max_f32_e32 v70, v70, v199                               // 0000000034C0: 208D8F46
	v_mov_b32_e32 v199, v70                                    // 0000000034C4: 7F8E0346
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000034C8: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 0000000034CC: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 0000000034D4: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000034D8: BF8704A1
	v_max_f32_e32 v70, v70, v199                               // 0000000034DC: 208D8F46
	s_and_saveexec_b32 s15, s4                                 // 0000000034E0: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 0000000034E4: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000034E8: BFA50003 <attn_pfd+0x34f8>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000034EC: BF870001
	v_readlane_b32 s6, v70, 31                                 // 0000000034F0: D7600006 00013F46
	s_or_saveexec_b32 s15, s15                                 // 0000000034F8: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000034FC: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000003500: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 000000003504: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003508: BFA50004 <attn_pfd+0x351c>
	v_readlane_b32 s6, v70, 15                                 // 00000000350C: D7600006 00011F46
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003514: BF870001
	v_mov_b32_e32 v198, s6                                     // 000000003518: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 00000000351C: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003520: BF8700A1
	v_max_f32_e32 v70, v198, v198                              // 000000003524: 208D8DC6
	v_max_f32_e32 v198, v188, v188                             // 000000003528: 218D79BC
	v_max_f32_e32 v70, v198, v70                               // 00000000352C: 208C8DC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003530: BF870091
	v_sub_f32_e32 v78, v78, v70                                // 000000003534: 089C8D4E
	v_mul_f32_e32 v198, 0x3fb8aa3b, v78                        // 000000003538: 118C9CFF 3FB8AA3B
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v78                      // 000000003540: D41B0006 00029CFF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000354C: BF8700A2
	v_fma_f32 v199, 0x3fb8aa3b, v78, -v198                     // 000000003550: D61300C7 871A9CFF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 00000000355C: 7F9047C6
	v_dual_fmac_f32 v199, 0x32a5705f, v78 :: v_dual_sub_f32 v198, v198, v200// 000000003560: C80A9CFF C7C791C6 32A5705F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 00000000356C: BF870121
	v_add_f32_e32 v198, v198, v199                             // 000000003570: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000003574: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 000000003578: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 00000000357C: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 000000003580: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003588: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 00000000358C: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v78                      // 000000003594: D41E0006 00029CFF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 0000000035A0: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000035AC: BF870091
	v_add_f32_dpp v78, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035B0: 069D8CFA FF0911C6
	v_add_f32_dpp v78, v78, v78 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035B8: 069C9CFA FF09124E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000035C0: BF870091
	v_add_f32_dpp v78, v78, v78 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035C4: 069C9CFA FF09144E
	v_add_f32_dpp v199, v78, v78 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000035CC: 078E9CFA FF09184E
	s_and_saveexec_b32 s15, s4                                 // 0000000035D4: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000035D8: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 0000000035DC: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000035E0: BFA50003 <attn_pfd+0x35f0>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000035E4: BF870001
	v_readlane_b32 s6, v199, 31                                // 0000000035E8: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 0000000035F0: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000035F4: BF870001
	v_mov_b32_e32 v78, s6                                      // 0000000035F8: 7E9C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 0000000035FC: 8D7E0F7E
	s_cbranch_execz 4                                          // 000000003600: BFA50004 <attn_pfd+0x3614>
	v_readlane_b32 s6, v199, 15                                // 000000003604: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000360C: BF870001
	v_mov_b32_e32 v78, s6                                      // 000000003610: 7E9C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003614: 8C7E0F7E
	v_cvt_f32_i32_e32 v71, v71                                 // 000000003618: 7E8E0B47
	v_cvt_f32_i32_e32 v79, v79                                 // 00000000361C: 7E9E0B4F
	v_cmp_le_i32_e64 s6, v197, v155                            // 000000003620: D4430006 000337C5
	v_cvt_f16_f32_e64 v198, v198                               // 000000003628: D58A00C6 000001C6
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000003630: BF870214
	v_mul_f32_e32 v71, v113, v71                               // 000000003634: 108E8F71
	v_mul_f32_e32 v79, v105, v79                               // 000000003638: 109E9F69
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000363C: BF8700B4
	s_and_b32 s6, s6, s5                                       // 000000003640: 8B060506
	ds_store_b16 v177, v198 offset:320                         // 000000003644: D87C0140 0000C6B1
	v_mul_f32_e32 v71, v196, v71                               // 00000000364C: 108E8FC4
	v_fmac_f32_e32 v71, v79, v115                              // 000000003650: 568EE74F
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003654: BF870091
	v_cndmask_b32_e64 v79, 0xf149f2ca, v71, s6                 // 000000003658: D501004F 001A8EFF F149F2CA
	v_mov_b32_e32 v71, v79                                     // 000000003664: 7E8E034F
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003668: BF870091
	v_mov_b32_dpp v71, v71 row_shr:1 row_mask:0xf bank_mask:0xf// 00000000366C: 7E8E02FA FF011147
	v_max_f32_e32 v71, v71, v71                                // 000000003674: 208E8F47
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003678: BF870091
	v_max_f32_e32 v71, v79, v71                                // 00000000367C: 208E8F4F
	v_mov_b32_e32 v199, v71                                    // 000000003680: 7F8E0347
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003684: BF870091
	v_mov_b32_dpp v199, v199 row_shr:2 row_mask:0xf bank_mask:0xf// 000000003688: 7F8E02FA FF0112C7
	v_max_f32_e32 v199, v199, v199                             // 000000003690: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003694: BF870091
	v_max_f32_e32 v71, v71, v199                               // 000000003698: 208F8F47
	v_mov_b32_e32 v199, v71                                    // 00000000369C: 7F8E0347
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000036A0: BF870091
	v_mov_b32_dpp v199, v199 row_shr:4 row_mask:0xf bank_mask:0xf// 0000000036A4: 7F8E02FA FF0114C7
	v_max_f32_e32 v199, v199, v199                             // 0000000036AC: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000036B0: BF870091
	v_max_f32_e32 v71, v71, v199                               // 0000000036B4: 208F8F47
	v_mov_b32_e32 v199, v71                                    // 0000000036B8: 7F8E0347
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000036BC: BF870091
	v_mov_b32_dpp v199, v199 row_shr:8 row_mask:0xf bank_mask:0xf// 0000000036C0: 7F8E02FA FF0118C7
	v_max_f32_e32 v199, v199, v199                             // 0000000036C8: 218F8FC7
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000036CC: BF8704A1
	v_max_f32_e32 v71, v71, v199                               // 0000000036D0: 208F8F47
	s_and_saveexec_b32 s15, s4                                 // 0000000036D4: BE8F2004
	s_xor_b32 s15, exec_lo, s15                                // 0000000036D8: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000036DC: BFA50003 <attn_pfd+0x36ec>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000036E0: BF870001
	v_readlane_b32 s6, v71, 31                                 // 0000000036E4: D7600006 00013F47
	s_or_saveexec_b32 s15, s15                                 // 0000000036EC: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000036F0: BF870001
	v_mov_b32_e32 v198, s6                                     // 0000000036F4: 7F8C0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 0000000036F8: 8D7E0F7E
	s_cbranch_execz 4                                          // 0000000036FC: BFA50004 <attn_pfd+0x3710>
	v_readlane_b32 s6, v71, 15                                 // 000000003700: D7600006 00011F47
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003708: BF870001
	v_mov_b32_e32 v198, s6                                     // 00000000370C: 7F8C0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003710: 8C7E0F7E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003714: BF8700A1
	v_max_f32_e32 v71, v198, v198                              // 000000003718: 208F8DC6
	v_max_f32_e32 v198, v186, v186                             // 00000000371C: 218D75BA
	v_max_f32_e32 v71, v198, v71                               // 000000003720: 208E8FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003724: BF870091
	v_sub_f32_e32 v79, v79, v71                                // 000000003728: 089E8F4F
	v_mul_f32_e32 v198, 0x3fb8aa3b, v79                        // 00000000372C: 118C9EFF 3FB8AA3B
	v_cmp_ngt_f32_e64 s6, 0xc2ce8ed0, v79                      // 000000003734: D41B0006 00029EFF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003740: BF8700A2
	v_fma_f32 v199, 0x3fb8aa3b, v79, -v198                     // 000000003744: D61300C7 871A9EFF 3FB8AA3B
	v_rndne_f32_e32 v200, v198                                 // 000000003750: 7F9047C6
	v_dual_fmac_f32 v199, 0x32a5705f, v79 :: v_dual_sub_f32 v198, v198, v200// 000000003754: C80A9EFF C7C791C6 32A5705F
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000003760: BF870121
	v_add_f32_e32 v198, v198, v199                             // 000000003764: 078D8FC6
	v_cvt_i32_f32_e32 v199, v200                               // 000000003768: 7F8E11C8
	v_exp_f32_e32 v198, v198                                   // 00000000376C: 7F8C4BC6
	s_waitcnt_depctr 0xfff                                     // 000000003770: BF880FFF
	v_ldexp_f32 v198, v198, v199                               // 000000003774: D71C00C6 00038FC6
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000000377C: BF8700A1
	v_cndmask_b32_e64 v198, 0, v198, s6                        // 000000003780: D50100C6 001B8C80
	v_cmp_nlt_f32_e64 s6, 0x42b17218, v79                      // 000000003788: D41E0006 00029EFF 42B17218
	v_cndmask_b32_e64 v198, 0x7f800000, v198, s6               // 000000003794: D50100C6 001B8CFF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000037A0: BF870091
	v_add_f32_dpp v79, v198, v198 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000037A4: 069F8CFA FF0911C6
	v_add_f32_dpp v79, v79, v79 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000037AC: 069E9EFA FF09124F
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000037B4: BF870091
	v_add_f32_dpp v79, v79, v79 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000037B8: 069E9EFA FF09144F
	v_add_f32_dpp v199, v79, v79 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000037C0: 078E9EFA FF09184F
	s_and_saveexec_b32 s15, s4                                 // 0000000037C8: BE8F2004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000037CC: BF870009
	s_xor_b32 s15, exec_lo, s15                                // 0000000037D0: 8D0F0F7E
	s_cbranch_execz 3                                          // 0000000037D4: BFA50003 <attn_pfd+0x37e4>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000037D8: BF870001
	v_readlane_b32 s6, v199, 31                                // 0000000037DC: D7600006 00013FC7
	s_or_saveexec_b32 s15, s15                                 // 0000000037E4: BE8F220F
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000037E8: BF870001
	v_mov_b32_e32 v79, s6                                      // 0000000037EC: 7E9E0206
	s_xor_b32 exec_lo, exec_lo, s15                            // 0000000037F0: 8D7E0F7E
	s_cbranch_execz 4                                          // 0000000037F4: BFA50004 <attn_pfd+0x3808>
	v_readlane_b32 s6, v199, 15                                // 0000000037F8: D7600006 00011FC7
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003800: BF870001
	v_mov_b32_e32 v79, s6                                      // 000000003804: 7E9E0206
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003808: 8C7E0F7E
	v_cvt_f32_i32_e32 v72, v72                                 // 00000000380C: 7E900B48
	v_cvt_f32_i32_e32 v80, v80                                 // 000000003810: 7EA00B50
	v_cmp_le_i32_e64 s6, v197, v156                            // 000000003814: D4430006 000339C5
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000000381C: BF870193
	v_mul_f32_e32 v72, v114, v72                               // 000000003820: 10909172
	v_mul_f32_e32 v80, v106, v80                               // 000000003824: 10A0A16A
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000003828: BF870113
	s_and_b32 s5, s6, s5                                       // 00000000382C: 8B050506
	v_mul_f32_e32 v72, v196, v72                               // 000000003830: 109091C4
	v_cvt_f16_f32_e64 v196, v198                               // 000000003834: D58A00C4 000001C6
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000000383C: BF8700B2
	v_fmac_f32_e32 v72, v80, v115                              // 000000003840: 5690E750
	ds_store_b16 v177, v196 offset:384                         // 000000003844: D87C0180 0000C4B1
	v_cndmask_b32_e64 v80, 0xf149f2ca, v72, s5                 // 00000000384C: D5010050 001690FF F149F2CA
	v_mov_b32_e32 v72, v80                                     // 000000003858: 7E900350
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000385C: BF870091
	v_mov_b32_dpp v72, v72 row_shr:1 row_mask:0xf bank_mask:0xf// 000000003860: 7E9002FA FF011148
	v_max_f32_e32 v72, v72, v72                                // 000000003868: 20909148
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000386C: BF870091
	v_max_f32_e32 v72, v80, v72                                // 000000003870: 20909150
	v_mov_b32_e32 v115, v72                                    // 000000003874: 7EE60348
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003878: BF870091
	v_mov_b32_dpp v115, v115 row_shr:2 row_mask:0xf bank_mask:0xf// 00000000387C: 7EE602FA FF011273
	v_max_f32_e32 v115, v115, v115                             // 000000003884: 20E6E773
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003888: BF870091
	v_max_f32_e32 v72, v72, v115                               // 00000000388C: 2090E748
	v_mov_b32_e32 v115, v72                                    // 000000003890: 7EE60348
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003894: BF870091
	v_mov_b32_dpp v115, v115 row_shr:4 row_mask:0xf bank_mask:0xf// 000000003898: 7EE602FA FF011473
	v_max_f32_e32 v115, v115, v115                             // 0000000038A0: 20E6E773
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000038A4: BF870091
	v_max_f32_e32 v72, v72, v115                               // 0000000038A8: 2090E748
	v_mov_b32_e32 v115, v72                                    // 0000000038AC: 7EE60348
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000038B0: BF870091
	v_mov_b32_dpp v115, v115 row_shr:8 row_mask:0xf bank_mask:0xf// 0000000038B4: 7EE602FA FF011873
	v_max_f32_e32 v115, v115, v115                             // 0000000038BC: 20E6E773
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)// 0000000038C0: BF8704A1
	v_max_f32_e32 v72, v72, v115                               // 0000000038C4: 2090E748
	s_and_saveexec_b32 s6, s4                                  // 0000000038C8: BE862004
	s_xor_b32 s6, exec_lo, s6                                  // 0000000038CC: 8D06067E
	s_cbranch_execz 3                                          // 0000000038D0: BFA50003 <attn_pfd+0x38e0>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000038D4: BF870001
	v_readlane_b32 s5, v72, 31                                 // 0000000038D8: D7600005 00013F48
	s_or_saveexec_b32 s6, s6                                   // 0000000038E0: BE862206
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000038E4: BF870001
	v_mov_b32_e32 v115, s5                                     // 0000000038E8: 7EE60205
	s_xor_b32 exec_lo, exec_lo, s6                             // 0000000038EC: 8D7E067E
	s_cbranch_execz 4                                          // 0000000038F0: BFA50004 <attn_pfd+0x3904>
	v_readlane_b32 s5, v72, 15                                 // 0000000038F4: D7600005 00011F48
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000038FC: BF870001
	v_mov_b32_e32 v115, s5                                     // 000000003900: 7EE60205
	s_or_b32 exec_lo, exec_lo, s6                              // 000000003904: 8C7E067E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003908: BF870091
	v_dual_max_f32 v72, v115, v115 :: v_dual_max_f32 v115, v185, v185// 00000000390C: CA94E773 487373B9
	v_max_f32_e32 v72, v115, v72                               // 000000003914: 20909173
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003918: BF870091
	v_sub_f32_e32 v80, v80, v72                                // 00000000391C: 08A09150
	v_mul_f32_e32 v115, 0x3fb8aa3b, v80                        // 000000003920: 10E6A0FF 3FB8AA3B
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003928: BF8700A1
	v_fma_f32 v196, 0x3fb8aa3b, v80, -v115                     // 00000000392C: D61300C4 85CEA0FF 3FB8AA3B
	v_rndne_f32_e32 v197, v115                                 // 000000003938: 7F8A4773
	v_dual_sub_f32 v115, v115, v197 :: v_dual_fmac_f32 v196, 0x32a5705f, v80// 00000000393C: C9418B73 73C4A0FF 32A5705F
	v_cmp_ngt_f32_e64 s5, 0xc2ce8ed0, v80                      // 000000003948: D41B0005 0002A0FF C2CE8ED0
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000003954: BF870122
	v_add_f32_e32 v115, v115, v196                             // 000000003958: 06E78973
	v_cvt_i32_f32_e32 v196, v197                               // 00000000395C: 7F8811C5
	v_exp_f32_e32 v115, v115                                   // 000000003960: 7EE64B73
	s_waitcnt_depctr 0xfff                                     // 000000003964: BF880FFF
	v_ldexp_f32 v115, v115, v196                               // 000000003968: D71C0073 00038973
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000003970: BF8700A1
	v_cndmask_b32_e64 v115, 0, v115, s5                        // 000000003974: D5010073 0016E680
	v_cmp_nlt_f32_e64 s5, 0x42b17218, v80                      // 00000000397C: D41E0005 0002A0FF 42B17218
	v_cndmask_b32_e64 v115, 0x7f800000, v115, s5               // 000000003988: D5010073 0016E6FF 7F800000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003994: BF870091
	v_add_f32_dpp v80, v115, v115 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1// 000000003998: 06A0E6FA FF091173
	v_add_f32_dpp v80, v80, v80 row_shr:2 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000039A0: 06A0A0FA FF091250
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000039A8: BF870091
	v_add_f32_dpp v80, v80, v80 row_shr:4 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000039AC: 06A0A0FA FF091450
	v_add_f32_dpp v196, v80, v80 row_shr:8 row_mask:0xf bank_mask:0xf bound_ctrl:1// 0000000039B4: 0788A0FA FF091850
	s_and_saveexec_b32 s6, s4                                  // 0000000039BC: BE862004
	s_delay_alu instid0(SALU_CYCLE_1)                          // 0000000039C0: BF870009
	s_xor_b32 s6, exec_lo, s6                                  // 0000000039C4: 8D06067E
	s_cbranch_execz 3                                          // 0000000039C8: BFA50003 <attn_pfd+0x39d8>
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000039CC: BF870001
	v_readlane_b32 s5, v196, 31                                // 0000000039D0: D7600005 00013FC4
	s_or_saveexec_b32 s6, s6                                   // 0000000039D8: BE862206
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000039DC: BF870001
	v_mov_b32_e32 v80, s5                                      // 0000000039E0: 7EA00205
	s_xor_b32 exec_lo, exec_lo, s6                             // 0000000039E4: 8D7E067E
	s_cbranch_execz 62975                                      // 0000000039E8: BFA5F5FF <attn_pfd+0x11e8>
	v_readlane_b32 s5, v196, 15                                // 0000000039EC: D7600005 00011FC4
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000039F4: BF870001
	v_mov_b32_e32 v80, s5                                      // 0000000039F8: 7EA00205
	s_branch 62970                                             // 0000000039FC: BFA0F5FA <attn_pfd+0x11e8>
	v_add_nc_u32_e32 v72, 14, v121                             // 000000003A00: 4A90F28E
	v_add_nc_u32_e32 v73, 12, v121                             // 000000003A04: 4A92F28C
	s_mov_b32 s0, exec_lo                                      // 000000003A08: BE80007E
	v_cmpx_gt_u32_e32 0xc0, v0                                 // 000000003A0C: 7D9800FF 000000C0
	s_cbranch_execz 521                                        // 000000003A14: BFA50209 <attn_pfd+0x423c>
	v_lshlrev_b32_e32 v0, 9, v145                              // 000000003A18: 30012289
	v_or_b32_e32 v65, v144, v145                               // 000000003A1C: 38832390
	s_mov_b32 s25, 0                                           // 000000003A20: BE990080
	s_mov_b32 s1, exec_lo                                      // 000000003A24: BE81007E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003A28: BF870092
	v_add_co_u32 v0, s0, s8, v0                                // 000000003A2C: D7000000 00020008
	v_add_co_ci_u32_e64 v66, null, s9, 0, s0                   // 000000003A34: D5207C42 00010009
	v_cmp_eq_u32_e32 vcc_lo, 0, v65                            // 000000003A3C: 7C948280
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003A40: BF870093
	v_add_co_u32 v67, s0, v0, v146                             // 000000003A44: D7000043 00032500
	v_add_co_ci_u32_e64 v68, s0, 0, v66, s0                    // 000000003A4C: D5200044 00028480
	v_cmpx_gt_u32_e64 s27, v143                                // 000000003A54: D4CC007E 00031E1B
	s_cbranch_execz 58                                         // 000000003A5C: BFA5003A <attn_pfd+0x3b48>
	v_mul_i32_i24_e32 v0, -6, v143                             // 000000003A60: 12011EC6
	v_dual_mov_b32 v66, 0 :: v_dual_add_nc_u32 v71, s7, v143   // 000000003A64: CA200080 42471E07
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003A6C: BF870092
	v_add3_u32 v65, v121, s26, v0                              // 000000003A70: D6550041 04003579
	v_mad_u64_u32 v[69:70], null, v71, 24, v[65:66]            // 000000003A78: D6FE7C45 05053147
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003A80: BF870091
	v_mad_u64_u32 v[65:66], null, 0x1c1, v69, s[24:25]         // 000000003A84: D6FE7C41 00628AFF 000001C1
	v_mad_u32_u24 v66, 0x1c1, v70, v66                         // 000000003A90: D60B0042 050A8CFF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003A9C: BF870091
	v_lshlrev_b64 v[69:70], 10, v[65:66]                       // 000000003AA0: D73C0045 0002828A
	v_add_co_u32 v69, s0, v67, v69                             // 000000003AA8: D7000045 00028B43
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003AB0: BF870001
	v_add_co_ci_u32_e64 v70, s0, v68, v70, s0                  // 000000003AB4: D5200046 00028D44
	s_clause 0x7                                               // 000000003ABC: BF850007
	global_store_b32 v[69:70], v57, off                        // 000000003AC0: DC6A0000 007C3945
	global_store_b32 v[69:70], v49, off offset:64              // 000000003AC8: DC6A0040 007C3145
	global_store_b32 v[69:70], v41, off offset:128             // 000000003AD0: DC6A0080 007C2945
	global_store_b32 v[69:70], v33, off offset:192             // 000000003AD8: DC6A00C0 007C2145
	global_store_b32 v[69:70], v25, off offset:256             // 000000003AE0: DC6A0100 007C1945
	global_store_b32 v[69:70], v17, off offset:320             // 000000003AE8: DC6A0140 007C1145
	global_store_b32 v[69:70], v9, off offset:384              // 000000003AF0: DC6A0180 007C0945
	global_store_b32 v[69:70], v1, off offset:448              // 000000003AF8: DC6A01C0 007C0145
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000003B00: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000003B04: BFA50010 <attn_pfd+0x3b48>
	v_lshlrev_b64 v[0:1], 2, v[65:66]                          // 000000003B08: D73C0000 00028282
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003B10: BF870091
	v_add_co_u32 v65, s0, s10, v0                              // 000000003B14: D7000041 0002000A
	v_add_co_ci_u32_e64 v66, s0, s11, v1, s0                   // 000000003B1C: D5200042 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000003B24: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003B2C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000003B30: D5200001 0002020D
	global_store_b32 v[65:66], v191, off                       // 000000003B38: DC6A0000 007CBF41
	global_store_b32 v[0:1], v195, off                         // 000000003B40: DC6A0000 007CC300
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003B48: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003B4C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000003B50: BE81007E
	v_cmpx_gt_u32_e64 s27, v142                                // 000000003B54: D4CC007E 00031C1B
	s_cbranch_execz 58                                         // 000000003B5C: BFA5003A <attn_pfd+0x3c48>
	v_mul_i32_i24_e32 v0, -6, v142                             // 000000003B60: 12011CC6
	v_add_nc_u32_e32 v9, s7, v142                              // 000000003B64: 4A131C07
	v_mov_b32_e32 v1, 0                                        // 000000003B68: 7E020280
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003B6C: BF870093
	v_add3_u32 v0, v141, s26, v0                               // 000000003B70: D6550000 0400358D
	v_mad_u64_u32 v[65:66], null, v9, 24, v[0:1]               // 000000003B78: D6FE7C41 04013109
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003B80: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v65, s[24:25]           // 000000003B84: D6FE7C00 006282FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v66, v1                           // 000000003B90: D60B0001 040684FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003B9C: BF870091
	v_lshlrev_b64 v[65:66], 10, v[0:1]                         // 000000003BA0: D73C0041 0002008A
	v_add_co_u32 v65, s0, v67, v65                             // 000000003BA8: D7000041 00028343
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003BB0: BF870001
	v_add_co_ci_u32_e64 v66, s0, v68, v66, s0                  // 000000003BB4: D5200042 00028544
	s_clause 0x7                                               // 000000003BBC: BF850007
	global_store_b32 v[65:66], v58, off                        // 000000003BC0: DC6A0000 007C3A41
	global_store_b32 v[65:66], v50, off offset:64              // 000000003BC8: DC6A0040 007C3241
	global_store_b32 v[65:66], v42, off offset:128             // 000000003BD0: DC6A0080 007C2A41
	global_store_b32 v[65:66], v34, off offset:192             // 000000003BD8: DC6A00C0 007C2241
	global_store_b32 v[65:66], v26, off offset:256             // 000000003BE0: DC6A0100 007C1A41
	global_store_b32 v[65:66], v18, off offset:320             // 000000003BE8: DC6A0140 007C1241
	global_store_b32 v[65:66], v10, off offset:384             // 000000003BF0: DC6A0180 007C0A41
	global_store_b32 v[65:66], v2, off offset:448              // 000000003BF8: DC6A01C0 007C0241
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000003C00: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000003C04: BFA50010 <attn_pfd+0x3c48>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000003C08: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003C10: BF870091
	v_add_co_u32 v9, s0, s10, v0                               // 000000003C14: D7000009 0002000A
	v_add_co_ci_u32_e64 v10, s0, s11, v1, s0                   // 000000003C1C: D520000A 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000003C24: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003C2C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000003C30: D5200001 0002020D
	global_store_b32 v[9:10], v194, off                        // 000000003C38: DC6A0000 007CC209
	global_store_b32 v[0:1], v190, off                         // 000000003C40: DC6A0000 007CBE00
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003C48: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003C4C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000003C50: BE81007E
	v_cmpx_gt_u32_e64 s27, v139                                // 000000003C54: D4CC007E 0003161B
	s_cbranch_execz 58                                         // 000000003C5C: BFA5003A <attn_pfd+0x3d48>
	v_mul_i32_i24_e32 v0, -6, v139                             // 000000003C60: 120116C6
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v2, s7, v139     // 000000003C64: CA200080 01031607
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003C6C: BF870092
	v_add3_u32 v0, v138, s26, v0                               // 000000003C70: D6550000 0400358A
	v_mad_u64_u32 v[9:10], null, v2, 24, v[0:1]                // 000000003C78: D6FE7C09 04013102
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003C80: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v9, s[24:25]            // 000000003C84: D6FE7C00 006212FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v10, v1                           // 000000003C90: D60B0001 040614FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003C9C: BF870091
	v_lshlrev_b64 v[9:10], 10, v[0:1]                          // 000000003CA0: D73C0009 0002008A
	v_add_co_u32 v9, s0, v67, v9                               // 000000003CA8: D7000009 00021343
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003CB0: BF870001
	v_add_co_ci_u32_e64 v10, s0, v68, v10, s0                  // 000000003CB4: D520000A 00021544
	s_clause 0x7                                               // 000000003CBC: BF850007
	global_store_b32 v[9:10], v59, off                         // 000000003CC0: DC6A0000 007C3B09
	global_store_b32 v[9:10], v51, off offset:64               // 000000003CC8: DC6A0040 007C3309
	global_store_b32 v[9:10], v43, off offset:128              // 000000003CD0: DC6A0080 007C2B09
	global_store_b32 v[9:10], v35, off offset:192              // 000000003CD8: DC6A00C0 007C2309
	global_store_b32 v[9:10], v27, off offset:256              // 000000003CE0: DC6A0100 007C1B09
	global_store_b32 v[9:10], v19, off offset:320              // 000000003CE8: DC6A0140 007C1309
	global_store_b32 v[9:10], v11, off offset:384              // 000000003CF0: DC6A0180 007C0B09
	global_store_b32 v[9:10], v3, off offset:448               // 000000003CF8: DC6A01C0 007C0309
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000003D00: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000003D04: BFA50010 <attn_pfd+0x3d48>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000003D08: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003D10: BF870091
	v_add_co_u32 v2, s0, s10, v0                               // 000000003D14: D7000002 0002000A
	v_add_co_ci_u32_e64 v3, s0, s11, v1, s0                    // 000000003D1C: D5200003 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000003D24: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003D2C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000003D30: D5200001 0002020D
	global_store_b32 v[2:3], v193, off                         // 000000003D38: DC6A0000 007CC102
	global_store_b32 v[0:1], v187, off                         // 000000003D40: DC6A0000 007CBB00
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003D48: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003D4C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000003D50: BE81007E
	v_cmpx_gt_u32_e64 s27, v137                                // 000000003D54: D4CC007E 0003121B
	s_cbranch_execz 58                                         // 000000003D5C: BFA5003A <attn_pfd+0x3e48>
	v_mul_i32_i24_e32 v0, -6, v137                             // 000000003D60: 120112C6
	v_add_nc_u32_e32 v9, s7, v137                              // 000000003D64: 4A131207
	v_mov_b32_e32 v1, 0                                        // 000000003D68: 7E020280
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003D6C: BF870093
	v_add3_u32 v0, v133, s26, v0                               // 000000003D70: D6550000 04003585
	v_mad_u64_u32 v[2:3], null, v9, 24, v[0:1]                 // 000000003D78: D6FE7C02 04013109
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003D80: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v2, s[24:25]            // 000000003D84: D6FE7C00 006204FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v3, v1                            // 000000003D90: D60B0001 040606FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003D9C: BF870091
	v_lshlrev_b64 v[2:3], 10, v[0:1]                           // 000000003DA0: D73C0002 0002008A
	v_add_co_u32 v2, s0, v67, v2                               // 000000003DA8: D7000002 00020543
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003DB0: BF870001
	v_add_co_ci_u32_e64 v3, s0, v68, v3, s0                    // 000000003DB4: D5200003 00020744
	s_clause 0x7                                               // 000000003DBC: BF850007
	global_store_b32 v[2:3], v60, off                          // 000000003DC0: DC6A0000 007C3C02
	global_store_b32 v[2:3], v52, off offset:64                // 000000003DC8: DC6A0040 007C3402
	global_store_b32 v[2:3], v44, off offset:128               // 000000003DD0: DC6A0080 007C2C02
	global_store_b32 v[2:3], v36, off offset:192               // 000000003DD8: DC6A00C0 007C2402
	global_store_b32 v[2:3], v28, off offset:256               // 000000003DE0: DC6A0100 007C1C02
	global_store_b32 v[2:3], v20, off offset:320               // 000000003DE8: DC6A0140 007C1402
	global_store_b32 v[2:3], v12, off offset:384               // 000000003DF0: DC6A0180 007C0C02
	global_store_b32 v[2:3], v4, off offset:448                // 000000003DF8: DC6A01C0 007C0402
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000003E00: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000003E04: BFA50010 <attn_pfd+0x3e48>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000003E08: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003E10: BF870091
	v_add_co_u32 v2, s0, s10, v0                               // 000000003E14: D7000002 0002000A
	v_add_co_ci_u32_e64 v3, s0, s11, v1, s0                    // 000000003E1C: D5200003 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000003E24: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003E2C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000003E30: D5200001 0002020D
	global_store_b32 v[2:3], v192, off                         // 000000003E38: DC6A0000 007CC002
	global_store_b32 v[0:1], v184, off                         // 000000003E40: DC6A0000 007CB800
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003E48: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003E4C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000003E50: BE81007E
	v_cmpx_gt_u32_e64 s27, v130                                // 000000003E54: D4CC007E 0003041B
	s_cbranch_execz 58                                         // 000000003E5C: BFA5003A <attn_pfd+0x3f48>
	v_mul_i32_i24_e32 v0, -6, v130                             // 000000003E60: 120104C6
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v4, s7, v130     // 000000003E64: CA200080 01050407
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003E6C: BF870092
	v_add3_u32 v0, v128, s26, v0                               // 000000003E70: D6550000 04003580
	v_mad_u64_u32 v[2:3], null, v4, 24, v[0:1]                 // 000000003E78: D6FE7C02 04013104
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003E80: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v2, s[24:25]            // 000000003E84: D6FE7C00 006204FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v3, v1                            // 000000003E90: D60B0001 040606FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003E9C: BF870091
	v_lshlrev_b64 v[2:3], 10, v[0:1]                           // 000000003EA0: D73C0002 0002008A
	v_add_co_u32 v2, s0, v67, v2                               // 000000003EA8: D7000002 00020543
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003EB0: BF870001
	v_add_co_ci_u32_e64 v3, s0, v68, v3, s0                    // 000000003EB4: D5200003 00020744
	s_clause 0x7                                               // 000000003EBC: BF850007
	global_store_b32 v[2:3], v61, off                          // 000000003EC0: DC6A0000 007C3D02
	global_store_b32 v[2:3], v53, off offset:64                // 000000003EC8: DC6A0040 007C3502
	global_store_b32 v[2:3], v45, off offset:128               // 000000003ED0: DC6A0080 007C2D02
	global_store_b32 v[2:3], v37, off offset:192               // 000000003ED8: DC6A00C0 007C2502
	global_store_b32 v[2:3], v29, off offset:256               // 000000003EE0: DC6A0100 007C1D02
	global_store_b32 v[2:3], v21, off offset:320               // 000000003EE8: DC6A0140 007C1502
	global_store_b32 v[2:3], v13, off offset:384               // 000000003EF0: DC6A0180 007C0D02
	global_store_b32 v[2:3], v5, off offset:448                // 000000003EF8: DC6A01C0 007C0502
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000003F00: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000003F04: BFA50010 <attn_pfd+0x3f48>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000003F08: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003F10: BF870091
	v_add_co_u32 v2, s0, s10, v0                               // 000000003F14: D7000002 0002000A
	v_add_co_ci_u32_e64 v3, s0, s11, v1, s0                    // 000000003F1C: D5200003 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000003F24: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003F2C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000003F30: D5200001 0002020D
	global_store_b32 v[2:3], v189, off                         // 000000003F38: DC6A0000 007CBD02
	global_store_b32 v[0:1], v162, off                         // 000000003F40: DC6A0000 007CA200
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003F48: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000003F4C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000003F50: BE81007E
	v_cmpx_gt_u32_e64 s27, v127                                // 000000003F54: D4CC007E 0002FE1B
	s_cbranch_execz 58                                         // 000000003F5C: BFA5003A <attn_pfd+0x4048>
	v_mul_i32_i24_e32 v0, -6, v127                             // 000000003F60: 1200FEC6
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v4, s7, v127     // 000000003F64: CA200080 0104FE07
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003F6C: BF870092
	v_add3_u32 v0, v126, s26, v0                               // 000000003F70: D6550000 0400357E
	v_mad_u64_u32 v[2:3], null, v4, 24, v[0:1]                 // 000000003F78: D6FE7C02 04013104
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003F80: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v2, s[24:25]            // 000000003F84: D6FE7C00 006204FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v3, v1                            // 000000003F90: D60B0001 040606FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000003F9C: BF870091
	v_lshlrev_b64 v[2:3], 10, v[0:1]                           // 000000003FA0: D73C0002 0002008A
	v_add_co_u32 v2, s0, v67, v2                               // 000000003FA8: D7000002 00020543
	s_delay_alu instid0(VALU_DEP_1)                            // 000000003FB0: BF870001
	v_add_co_ci_u32_e64 v3, s0, v68, v3, s0                    // 000000003FB4: D5200003 00020744
	s_clause 0x7                                               // 000000003FBC: BF850007
	global_store_b32 v[2:3], v62, off                          // 000000003FC0: DC6A0000 007C3E02
	global_store_b32 v[2:3], v54, off offset:64                // 000000003FC8: DC6A0040 007C3602
	global_store_b32 v[2:3], v46, off offset:128               // 000000003FD0: DC6A0080 007C2E02
	global_store_b32 v[2:3], v38, off offset:192               // 000000003FD8: DC6A00C0 007C2602
	global_store_b32 v[2:3], v30, off offset:256               // 000000003FE0: DC6A0100 007C1E02
	global_store_b32 v[2:3], v22, off offset:320               // 000000003FE8: DC6A0140 007C1602
	global_store_b32 v[2:3], v14, off offset:384               // 000000003FF0: DC6A0180 007C0E02
	global_store_b32 v[2:3], v6, off offset:448                // 000000003FF8: DC6A01C0 007C0602
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000004000: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000004004: BFA50010 <attn_pfd+0x4048>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000004008: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000004010: BF870091
	v_add_co_u32 v2, s0, s10, v0                               // 000000004014: D7000002 0002000A
	v_add_co_ci_u32_e64 v3, s0, s11, v1, s0                    // 00000000401C: D5200003 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000004024: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000402C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000004030: D5200001 0002020D
	global_store_b32 v[2:3], v188, off                         // 000000004038: DC6A0000 007CBC02
	global_store_b32 v[0:1], v148, off                         // 000000004040: DC6A0000 007C9400
	s_or_b32 exec_lo, exec_lo, s1                              // 000000004048: 8C7E017E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000000404C: BF870009
	s_mov_b32 s1, exec_lo                                      // 000000004050: BE81007E
	v_cmpx_gt_u32_e64 s27, v125                                // 000000004054: D4CC007E 0002FA1B
	s_cbranch_execz 58                                         // 00000000405C: BFA5003A <attn_pfd+0x4148>
	v_mul_i32_i24_e32 v0, -6, v125                             // 000000004060: 1200FAC6
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v4, s7, v125     // 000000004064: CA200080 0104FA07
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000406C: BF870092
	v_add3_u32 v0, v73, s26, v0                                // 000000004070: D6550000 04003549
	v_mad_u64_u32 v[2:3], null, v4, 24, v[0:1]                 // 000000004078: D6FE7C02 04013104
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000004080: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v2, s[24:25]            // 000000004084: D6FE7C00 006204FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v3, v1                            // 000000004090: D60B0001 040606FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000409C: BF870091
	v_lshlrev_b64 v[2:3], 10, v[0:1]                           // 0000000040A0: D73C0002 0002008A
	v_add_co_u32 v2, s0, v67, v2                               // 0000000040A8: D7000002 00020543
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000040B0: BF870001
	v_add_co_ci_u32_e64 v3, s0, v68, v3, s0                    // 0000000040B4: D5200003 00020744
	s_clause 0x7                                               // 0000000040BC: BF850007
	global_store_b32 v[2:3], v63, off                          // 0000000040C0: DC6A0000 007C3F02
	global_store_b32 v[2:3], v55, off offset:64                // 0000000040C8: DC6A0040 007C3702
	global_store_b32 v[2:3], v47, off offset:128               // 0000000040D0: DC6A0080 007C2F02
	global_store_b32 v[2:3], v39, off offset:192               // 0000000040D8: DC6A00C0 007C2702
	global_store_b32 v[2:3], v31, off offset:256               // 0000000040E0: DC6A0100 007C1F02
	global_store_b32 v[2:3], v23, off offset:320               // 0000000040E8: DC6A0140 007C1702
	global_store_b32 v[2:3], v15, off offset:384               // 0000000040F0: DC6A0180 007C0F02
	global_store_b32 v[2:3], v7, off offset:448                // 0000000040F8: DC6A01C0 007C0702
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000004100: 8B7E6A7E
	s_cbranch_execz 16                                         // 000000004104: BFA50010 <attn_pfd+0x4148>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000004108: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000004110: BF870091
	v_add_co_u32 v2, s0, s10, v0                               // 000000004114: D7000002 0002000A
	v_add_co_ci_u32_e64 v3, s0, s11, v1, s0                    // 00000000411C: D5200003 0002020B
	v_add_co_u32 v0, s0, s12, v0                               // 000000004124: D7000000 0002000C
	s_delay_alu instid0(VALU_DEP_1)                            // 00000000412C: BF870001
	v_add_co_ci_u32_e64 v1, s0, s13, v1, s0                    // 000000004130: D5200001 0002020D
	global_store_b32 v[2:3], v186, off                         // 000000004138: DC6A0000 007CBA02
	global_store_b32 v[0:1], v147, off                         // 000000004140: DC6A0000 007C9300
	s_or_b32 exec_lo, exec_lo, s1                              // 000000004148: 8C7E017E
	v_cmp_gt_u32_e64 s0, s27, v123                             // 00000000414C: D44C0000 0002F61B
	s_delay_alu instid0(VALU_DEP_1)                            // 000000004154: BF870001
	s_and_b32 exec_lo, exec_lo, s0                             // 000000004158: 8B7E007E
	s_cbranch_execz 55                                         // 00000000415C: BFA50037 <attn_pfd+0x423c>
	v_mul_i32_i24_e32 v0, -6, v123                             // 000000004160: 1200F6C6
	v_dual_mov_b32 v1, 0 :: v_dual_add_nc_u32 v4, s7, v123     // 000000004164: CA200080 0104F607
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000416C: BF870092
	v_add3_u32 v0, v72, s26, v0                                // 000000004170: D6550000 04003548
	v_mad_u64_u32 v[2:3], null, v4, 24, v[0:1]                 // 000000004178: D6FE7C02 04013104
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000004180: BF870091
	v_mad_u64_u32 v[0:1], null, 0x1c1, v2, s[24:25]            // 000000004184: D6FE7C00 006204FF 000001C1
	v_mad_u32_u24 v1, 0x1c1, v3, v1                            // 000000004190: D60B0001 040606FF 000001C1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000000419C: BF870091
	v_lshlrev_b64 v[2:3], 10, v[0:1]                           // 0000000041A0: D73C0002 0002008A
	v_add_co_u32 v2, s0, v67, v2                               // 0000000041A8: D7000002 00020543
	s_delay_alu instid0(VALU_DEP_1)                            // 0000000041B0: BF870001
	v_add_co_ci_u32_e64 v3, s0, v68, v3, s0                    // 0000000041B4: D5200003 00020744
	s_clause 0x7                                               // 0000000041BC: BF850007
	global_store_b32 v[2:3], v64, off                          // 0000000041C0: DC6A0000 007C4002
	global_store_b32 v[2:3], v56, off offset:64                // 0000000041C8: DC6A0040 007C3802
	global_store_b32 v[2:3], v48, off offset:128               // 0000000041D0: DC6A0080 007C3002
	global_store_b32 v[2:3], v40, off offset:192               // 0000000041D8: DC6A00C0 007C2802
	global_store_b32 v[2:3], v32, off offset:256               // 0000000041E0: DC6A0100 007C2002
	global_store_b32 v[2:3], v24, off offset:320               // 0000000041E8: DC6A0140 007C1802
	global_store_b32 v[2:3], v16, off offset:384               // 0000000041F0: DC6A0180 007C1002
	global_store_b32 v[2:3], v8, off offset:448                // 0000000041F8: DC6A01C0 007C0802
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000004200: 8B7E6A7E
	s_cbranch_execz 13                                         // 000000004204: BFA5000D <attn_pfd+0x423c>
	v_lshlrev_b64 v[0:1], 2, v[0:1]                            // 000000004208: D73C0000 00020082
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000004210: BF870111
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000004214: D7006A02 0002000A
	v_add_co_ci_u32_e32 v3, vcc_lo, s11, v1, vcc_lo            // 00000000421C: 4006020B
	v_add_co_u32 v0, vcc_lo, s12, v0                           // 000000004220: D7006A00 0002000C
	v_add_co_ci_u32_e32 v1, vcc_lo, s13, v1, vcc_lo            // 000000004228: 4002020D
	global_store_b32 v[2:3], v185, off                         // 00000000422C: DC6A0000 007CB902
	global_store_b32 v[0:1], v140, off                         // 000000004234: DC6A0000 007C8C00
	s_nop 0                                                    // 00000000423C: BF800000
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)                       // 000000004240: BFB60003
	s_endpgm                                                   // 000000004244: BFB00000
	s_code_end                                                 // 000000004248: BF9F0000
	s_code_end                                                 // 00000000424C: BF9F0000
	s_code_end                                                 // 000000004250: BF9F0000
	s_code_end                                                 // 000000004254: BF9F0000
	s_code_end                                                 // 000000004258: BF9F0000
	s_code_end                                                 // 00000000425C: BF9F0000
	s_code_end                                                 // 000000004260: BF9F0000
	s_code_end                                                 // 000000004264: BF9F0000
	s_code_end                                                 // 000000004268: BF9F0000
	s_code_end                                                 // 00000000426C: BF9F0000
	s_code_end                                                 // 000000004270: BF9F0000
	s_code_end                                                 // 000000004274: BF9F0000
	s_code_end                                                 // 000000004278: BF9F0000
	s_code_end                                                 // 00000000427C: BF9F0000
	s_code_end                                                 // 000000004280: BF9F0000
	s_code_end                                                 // 000000004284: BF9F0000
	s_code_end                                                 // 000000004288: BF9F0000
	s_code_end                                                 // 00000000428C: BF9F0000
	s_code_end                                                 // 000000004290: BF9F0000
	s_code_end                                                 // 000000004294: BF9F0000
	s_code_end                                                 // 000000004298: BF9F0000
	s_code_end                                                 // 00000000429C: BF9F0000
	s_code_end                                                 // 0000000042A0: BF9F0000
	s_code_end                                                 // 0000000042A4: BF9F0000
	s_code_end                                                 // 0000000042A8: BF9F0000
	s_code_end                                                 // 0000000042AC: BF9F0000
	s_code_end                                                 // 0000000042B0: BF9F0000
	s_code_end                                                 // 0000000042B4: BF9F0000
	s_code_end                                                 // 0000000042B8: BF9F0000
	s_code_end                                                 // 0000000042BC: BF9F0000
	s_code_end                                                 // 0000000042C0: BF9F0000
	s_code_end                                                 // 0000000042C4: BF9F0000
	s_code_end                                                 // 0000000042C8: BF9F0000
	s_code_end                                                 // 0000000042CC: BF9F0000
	s_code_end                                                 // 0000000042D0: BF9F0000
	s_code_end                                                 // 0000000042D4: BF9F0000
	s_code_end                                                 // 0000000042D8: BF9F0000
	s_code_end                                                 // 0000000042DC: BF9F0000
	s_code_end                                                 // 0000000042E0: BF9F0000
	s_code_end                                                 // 0000000042E4: BF9F0000
	s_code_end                                                 // 0000000042E8: BF9F0000
	s_code_end                                                 // 0000000042EC: BF9F0000
	s_code_end                                                 // 0000000042F0: BF9F0000
	s_code_end                                                 // 0000000042F4: BF9F0000
	s_code_end                                                 // 0000000042F8: BF9F0000
	s_code_end                                                 // 0000000042FC: BF9F0000
	s_code_end                                                 // 000000004300: BF9F0000
	s_code_end                                                 // 000000004304: BF9F0000
	s_code_end                                                 // 000000004308: BF9F0000
	s_code_end                                                 // 00000000430C: BF9F0000
	s_code_end                                                 // 000000004310: BF9F0000
	s_code_end                                                 // 000000004314: BF9F0000
	s_code_end                                                 // 000000004318: BF9F0000
	s_code_end                                                 // 00000000431C: BF9F0000
	s_code_end                                                 // 000000004320: BF9F0000
	s_code_end                                                 // 000000004324: BF9F0000
	s_code_end                                                 // 000000004328: BF9F0000
	s_code_end                                                 // 00000000432C: BF9F0000
	s_code_end                                                 // 000000004330: BF9F0000
	s_code_end                                                 // 000000004334: BF9F0000
	s_code_end                                                 // 000000004338: BF9F0000
	s_code_end                                                 // 00000000433C: BF9F0000
	s_code_end                                                 // 000000004340: BF9F0000
	s_code_end                                                 // 000000004344: BF9F0000
	s_code_end                                                 // 000000004348: BF9F0000
	s_code_end                                                 // 00000000434C: BF9F0000
	s_code_end                                                 // 000000004350: BF9F0000
	s_code_end                                                 // 000000004354: BF9F0000
	s_code_end                                                 // 000000004358: BF9F0000
	s_code_end                                                 // 00000000435C: BF9F0000
	s_code_end                                                 // 000000004360: BF9F0000
	s_code_end                                                 // 000000004364: BF9F0000
	s_code_end                                                 // 000000004368: BF9F0000
	s_code_end                                                 // 00000000436C: BF9F0000
	s_code_end                                                 // 000000004370: BF9F0000
	s_code_end                                                 // 000000004374: BF9F0000
	s_code_end                                                 // 000000004378: BF9F0000
	s_code_end                                                 // 00000000437C: BF9F0000
	s_code_end                                                 // 000000004380: BF9F0000
	s_code_end                                                 // 000000004384: BF9F0000
	s_code_end                                                 // 000000004388: BF9F0000
	s_code_end                                                 // 00000000438C: BF9F0000
	s_code_end                                                 // 000000004390: BF9F0000
	s_code_end                                                 // 000000004394: BF9F0000
	s_code_end                                                 // 000000004398: BF9F0000
	s_code_end                                                 // 00000000439C: BF9F0000
	s_code_end                                                 // 0000000043A0: BF9F0000
	s_code_end                                                 // 0000000043A4: BF9F0000
	s_code_end                                                 // 0000000043A8: BF9F0000
	s_code_end                                                 // 0000000043AC: BF9F0000
	s_code_end                                                 // 0000000043B0: BF9F0000
	s_code_end                                                 // 0000000043B4: BF9F0000
	s_code_end                                                 // 0000000043B8: BF9F0000
	s_code_end                                                 // 0000000043BC: BF9F0000
	s_code_end                                                 // 0000000043C0: BF9F0000
	s_code_end                                                 // 0000000043C4: BF9F0000
	s_code_end                                                 // 0000000043C8: BF9F0000
	s_code_end                                                 // 0000000043CC: BF9F0000
	s_code_end                                                 // 0000000043D0: BF9F0000
	s_code_end                                                 // 0000000043D4: BF9F0000
	s_code_end                                                 // 0000000043D8: BF9F0000
	s_code_end                                                 // 0000000043DC: BF9F0000
	s_code_end                                                 // 0000000043E0: BF9F0000
	s_code_end                                                 // 0000000043E4: BF9F0000
	s_code_end                                                 // 0000000043E8: BF9F0000
	s_code_end                                                 // 0000000043EC: BF9F0000
	s_code_end                                                 // 0000000043F0: BF9F0000
	s_code_end                                                 // 0000000043F4: BF9F0000
	s_code_end                                                 // 0000000043F8: BF9F0000
	s_code_end                                                 // 0000000043FC: BF9F0000
