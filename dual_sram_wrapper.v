`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 14:46:58
// Design Name: 
// Module Name: dual_sram_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//`define byte_mode   //hsize_i can be 3'b000 001 010 
//`define halfword_mode //hsize_i can be 3'b001 010 
//Attention : Memory mode must adapt to the size of the Data transfer

//Info :  1 cycle cen for write operation , 2 cycle cen for read operation
/*
*               ________         ________       ________         ________       ________         ________       ________         ________
*CLKB    ______|       |________|       |______|       |________|       |______|       |________|       |______|       |________|       |________
*        _______________                                _________________________________________________________________________________________
*CENB                  |_______________________________|                              
*       _______________                 _________________________________________________________________________________________________________
*WENB                 |________________|
*                                                       ________________________________________________________________________________________
*DATA__________________________________________________|________________________________________________________________________________________
*/
//  read 1 cycle after byte_enable is setted

`include "define.v"

module dual_sram_wrapper(
    // sys
	clk,
	resetn,
     
    //with testbench
	clka,
	cena,
	wena,
	aa,
    da,
	qa,
	
	//with ahb_slv_if
	clkb,
	cenb,
	wenb,
	ab,
	db,
	qb,
	sram_ack,
	sram_be
	
    );

input				clk;
input				resetn;
	
input				clka;
input				cena;
input   			wena;
input	[12:0]		aa;
input	[31:0]		da;
output	[31:0]		qa;

input				clkb;
input				cenb;
input   			wenb;
input	[12:0]		ab;
input	[31:0]		db;
output	[31:0]		qb;	

output				sram_ack;
input	[3:0]		sram_be;

reg				   sram_ack;
reg                cenb_r;
wire		[3:0]	   sram_be_act;

reg    [12:0] addr_reg;

always @(posedge clkb or negedge resetn )  //must be ahb_clk!!!
begin
  if(!resetn)
	sram_ack	<= 1'b0;
  else if((!cenb)&cenb_r)
	sram_ack  <= ~sram_ack;
  else
	sram_ack    <=  1'b0;
end

always @(posedge clkb or negedge resetn )  //
begin
  if(!resetn)
	cenb_r	<= 1'b0;
  else
	cenb_r  <= cenb;
end

assign sram_be_act = ((!cenb)&cenb_r) ? sram_be : 4'b1111;


always @(posedge clkb or negedge resetn )  //
begin
  if(!resetn)
	addr_reg  <= 13'h0;
  else
	addr_reg  <= ab;
end

wire [12:0] addr_b;
assign addr_b = (!cenb) ? (ab| addr_b) : 13'h0 ;

`ifdef byte_mode
dual_sram_8192x8 my_dual_sram_8192x8_0 (

   .clka(clka),
   .ena(!cena),
   .wea(!wena), //1 write ,0 read
   .addra(aa),
   .dina(da[7:0]),
   .douta(qa[7:0]),  // wait 1 cycle
   .clkb(clkb),
   .enb((!cenb)),
   .web((!wenb)&sram_be_act[0]),
//   .enb((!cenb)&sram_be[0]),
//   .web((!wenb)&sram_be[0]),  
   .addrb(ab),
   .dinb(db[7:0]),
   .doutb(qb[7:0])
);

dual_sram_8192x8 my_dual_sram_8192x8_1 (

   .clka(clka),
   .ena(!cena),
   .wea(!wena), //1 write ,0 read
   .addra(aa),
   .dina(da[15:8]),
   .douta(qa[15:8]),  // wait 1 cycle
   .clkb(clkb),
   .enb((!cenb)),
   .web((!wenb)&sram_be_act[1]),
 //   .enb((!cenb)&sram_be[1]),
 //  .web((!wenb)&sram_be[1]),  
   .addrb(ab),
   .dinb(db[15:8]),
   .doutb(qb[15:8])
);

dual_sram_8192x8 my_dual_sram_8192x8_2 (

   .clka(clka),
   .ena(!cena),
   .wea(!wena), //1 write ,0 read
   .addra(aa),
   .dina(da[23:16]),
   .douta(qa[23:16]),  // wait 1 cycle
   .clkb(clkb),
   .enb((!cenb)),
   .web((!wenb)&sram_be_act[2]), 
 //  .enb((!cenb)&sram_be[2]),
 //  .web((!wenb)&sram_be[2]),  
   .addrb(ab),
   .dinb(db[23:16]),
   .doutb(qb[23:16])
);

dual_sram_8192x8 my_dual_sram_8192x8_3 (

   .clka(clka),
   .ena(!cena),
   .wea(!wena), //1 write ,0 read
   .addra(aa),
   .dina(da[31:24]),
   .douta(qa[31:24]),  // wait 1 cycle
   .clkb(clkb), 
   .enb((!cenb)),
   .web((!wenb)&sram_be_act[3]),
 //  .enb((!cenb)&sram_be[3]),
//   .web((!wenb)&sram_be[3]),  
   .addrb(ab),
   .dinb(db[31:24]),
   .doutb(qb[31:24])
);

`elsif halfword_mode
dual_sram_8192X16 my_dual_sram_8192x16_0 (
   .clka(clka),
   .ena(!cena),
   .wea({2{!wena}}), //1 write ,0 read
   .addra(aa),
   .dina(da[15:0]),
   .douta(qa[15:0]),  // wait 1 cycle
   .clkb(clkb),
   .enb(!cenb),
   .web({2{!wenb}}&sram_be_act[1:0]), 
   .addrb(ab),
   .dinb(db[15:0]),
   .doutb(qb[15:0])
);
dual_sram_8192X16 my_dual_sram_8192x16_1 (

   .clka(clka),
   .ena(!cena),
   .wea({2{!wena}}), //1 write ,0 read
   .addra(aa),
   .dina(da[31:16]),
   .douta(qa[31:16]),  // wait 1 cycle
   .clkb(clkb),
   .enb(!cenb),
   .web({2{!wenb}}&sram_be_act[3:2]), 
   .addrb(ab),
   .dinb(db[31:16]),
   .doutb(qb[31:16])
);

`elsif word_mode 
dual_sram_8192x32 my_dual_sram_8192x32 (

   .clka(clka),
   .ena(!cena),
   .wea({4{!wena}}), //1 write ,0 read
   .addra(aa),
   .dina(da),
   .douta(qa),  // wait 1 cycle
   .clkb(clkb),
   .enb(!cenb),
   .web({4{!wenb}}&sram_be_act),  
 //  .addrb(ab),
   .addrb(addr_b),  // work for byte_enable
   .dinb(db),
   .doutb(qb)
);
`else

`endif	
	
	
endmodule
