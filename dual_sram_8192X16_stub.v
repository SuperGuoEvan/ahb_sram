// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Thu Dec  9 16:39:21 2021
// Host        : DESKTOP-DO2GEU9 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/guoj/vivado/ahb_slv_if_test/ahb_slv_if_test.srcs/sources_1/ip/dual_sram_8192X16/dual_sram_8192X16_stub.v
// Design      : dual_sram_8192X16
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu440-flga2892-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_1,Vivado 2017.4" *)
module dual_sram_8192X16(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[1:0],addra[12:0],dina[15:0],douta[15:0],clkb,enb,web[1:0],addrb[12:0],dinb[15:0],doutb[15:0]" */;
  input clka;
  input ena;
  input [1:0]wea;
  input [12:0]addra;
  input [15:0]dina;
  output [15:0]douta;
  input clkb;
  input enb;
  input [1:0]web;
  input [12:0]addrb;
  input [15:0]dinb;
  output [15:0]doutb;
endmodule
