`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/02 15:36:08
// Design Name: 
// Module Name: testbench
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

// clka 50M clkb 25M
`define CYCLEA 20  
`define CYCLEB 40 
`include "../../sources_1/new/define.v"

module testbench(

    );
	
	
always #(0.5*`CYCLEA) clka=~clka;
always #(0.5*`CYCLEB) clkb=~clkb;	

reg		clka,clkb;
reg		rst;

//		dual_sram
reg		cena;
reg		wena;
reg	[12:0]	aa;
reg	[31:0]	da;

//ahb_slv
reg		hsel_i;
reg	[31:0]	haddr_i;
reg	[1:0]	htrans_i;
reg		hwrite_i;

reg	[2:0]	hsize_i;
reg	[2:0]	hburst_i;
reg	[31:0]	hwdata_i;
//wire	hreadyslv_i;

wire [31:0] hrdata_o;
wire [1:0]  hresep_o;
wire		hready_o;


wire [31:0] qa;
wire [31:0] sram_dout;
wire 		sram_ack;
wire		sram_cen;
wire [12:0] sram_addr;
wire		sram_wen;
wire [31:0] sram_din;
wire [3:0]  sram_be;

//assign hreadyslv_i = my_ahs.hready_o;
ahs my_ahs (
	.hclk_i(clkb),
	.hreset_n(rst),
	.hsel_i(hsel_i),
	.haddr_i(haddr_i),
	.htrans_i(htrans_i),
	.hwrite_i(hwrite_i),
	.hsize_i(hsize_i),
	.hburst_i(hburst_i),
	.hwdata_i(hwdata_i),
	.hreadyslv_i(1'b1),
//    .hreadyslv_i(hready_o), // error in incr trans
	.hready_o(hready_o),
	.hrdata_o(hrdata_o),
	.hresep_o(hresep_o),

	.sram_dout(sram_dout),
	.sram_ack(sram_ack),
	.sram_cen(sram_cen),
	.sram_addr(sram_addr),
	.sram_wen(sram_wen),
	.sram_din(sram_din),
	.sram_be(sram_be)
);

dual_sram_wrapper my_dual_sram_wrapper (
	.clk(clka),
	.resetn(rst),
	
	.clka(clka),
	.cena(cena),
	.wena(wena),
	.aa(aa),
	.da(da),
	.qa(qa),
	
	.clkb(clkb),
	.cenb(sram_cen),
	.wenb(sram_wen),
	.ab({2'b00,sram_addr[12:2]}),
	.db(sram_din),
	.qb(sram_dout),
	.sram_ack(sram_ack),
	.sram_be(sram_be)
	);


    initial 
    begin
        clka =0;
		clkb =0;
        rst = 0;
        cena = 1;
        wena = 1;
        aa = 0;
        da = 0;	
     
		
		hsel_i = 0;
		haddr_i = 15'h0;
		htrans_i = 2'b00;
		hwrite_i = 1'b0;
		hsize_i = 3'b000;
		hburst_i = 3'b000;
		hwdata_i = 32'h0;
	//	hreadyslv_i = 1;
		
    
        # 58   rst =1;
		sram_init;
//		sram_read;
	 
       
       ahb_rd_word_single(16'h10);
	   ahb_rd_word_single(16'h20);	
       ahb_rd_word_single(16'h30);	
       ahb_wr_word_single(16'h10,32'h5555);
       ahb_wr_word_single(16'h20,32'haaaa);    
       ahb_wr_word_single(16'h30,32'hffff);      
       ahb_rd_word_single(16'h10);
       ahb_rd_word_single(16'h20);    
       ahb_rd_word_single(16'h30);        
       
     //  ahb_wr_byte_single(16'h31,32'h55555555);
       ahb_wr_half_single(16'h32,32'h55555555);
       ahb_rd_word_single(16'h30);
       
       ahb_rd_4word_incr4(16'h30);
       
        #500;
         $finish;
    end 	
	
	task sram_init;
	
	reg[31:0] i;
	for (i=0;i<=8000;i=i+1)
	begin
	  @(negedge clka);
	   begin
	  	 cena = 1'b0;
         wena = 1'b0;
         aa = i[12:0];
		 da = i[31:0];
		 
		end
		
	 @(negedge clka);
	   begin
	     #3;
		 cena = 1'b1;
		 wena = 1'b1;
		 aa = 0;
		 da = 0;
	  end 		 
	end
	
	
	endtask
	
		task sram_read;
    
    reg[31:0] i;
    for (i=0;i<=100;i=i+1)
    begin
      wait (!clka)
       begin
         cena = 1'b0;
         wena = 1'b1;
         aa = i[12:0];
         da = i[31:0];
         
        end
        
      wait(clka)
       begin
         #3;
         cena = 1'b1;
         wena = 1'b1;
         aa = 0;
         da = 0;
      end          
    end
       
    endtask
	
	task ahb_rd_word_single;
	input [15:0] ahb_addr;
	begin
	@(negedge clkb);
	#3;
	hsel_i = 1;
	haddr_i = ahb_addr[15:0];
	hwrite_i = 0;
	hsize_i = 3'b010;
	hburst_i = 3'b001;
	htrans_i = 2'b10;
	@(posedge clkb);
	#2;
	hsel_i = 0;
	haddr_i = 16'h0;
	hwrite_i = 0;
	hsize_i = 3'b000;
	hburst_i = 3'b000;	
	htrans_i = 2'b00;
	
	#(8*`CYCLEB);
	end
	
	endtask
	
	task ahb_rd_4word_incr4;
    input [15:0] ahb_addr;
    begin
    @(negedge clkb);
    #3;
    hsel_i = 1;
    haddr_i = ahb_addr[15:0];
    hwrite_i = 0;
    hsize_i = 3'b010;
    hburst_i = 3'b11;
    htrans_i = 2'b10;
  
    #`CYCLEB;   
   wait(hready_o);
     @(negedge clkb);
     #3;    
     haddr_i = ahb_addr[15:0]+16'h4;    
  
     htrans_i = 2'b11;
     
   #`CYCLEB;   
    wait(hready_o);
      @(negedge clkb);
      #3;    
      haddr_i = ahb_addr[15:0]+16'h8;    
  
   #`CYCLEB; 
   wait(hready_o);
     @(negedge clkb);
     #3;    
     haddr_i = ahb_addr[15:0]+16'hc;      
     @(posedge clkb);
     #2;
     hsel_i = 0;
     haddr_i = 16'h0;
     hwrite_i = 0;
     hsize_i = 3'b000;
     hburst_i = 3'b000;    
    end
    
    endtask	
	
	
	task ahb_wr_word_single;
    input [15:0] ahb_addr;
    input [31:0] ahb_wdata;
    begin
    @(negedge clkb);
    
    hsel_i = 1;
    haddr_i = ahb_addr[15:0];
   	hwdata_i = ahb_wdata; 
    hwrite_i = 1;
    hsize_i = 3'b010;
    hburst_i = 3'b001;
    htrans_i = 2'b10;
	
	@(posedge clkb);
	#2;
    hsel_i = 0;
    haddr_i = 16'h0;
    hwrite_i = 0;
    hsize_i = 3'b000;
    hburst_i = 3'b000;    
    htrans_i = 2'b00;	

	

	
   @(posedge clkb);
    wait(hready_o);
    #2;

    hwdata_i = 32'h0;

    
    #(4*`CYCLEB);
    end
    
    endtask
	
	task ahb_wr_byte_single;
    input [15:0] ahb_addr;
    input [31:0] ahb_wdata;
    begin
    @(negedge clkb);
    
    hsel_i = 1;
    haddr_i = ahb_addr[15:0];
       hwdata_i = ahb_wdata; 
    hwrite_i = 1;
    hsize_i = 3'b000;
    hburst_i = 3'b001;
    htrans_i = 2'b10;
    
    @(posedge clkb);
    #2;
    hsel_i = 0;
    haddr_i = 16'h0;
    hwrite_i = 0;
    hsize_i = 3'b000;
    hburst_i = 3'b000;    
    htrans_i = 2'b00;    

    

    
   @(posedge clkb);
    wait(hready_o);
    #2;

    hwdata_i = 32'h0;

    
    #(4*`CYCLEB);
    end
    
    endtask
    
 	task ahb_wr_half_single;
    input [15:0] ahb_addr;
    input [31:0] ahb_wdata;
    begin
    @(negedge clkb);
    
    hsel_i = 1;
    haddr_i = ahb_addr[15:0];
       hwdata_i = ahb_wdata; 
    hwrite_i = 1;
    hsize_i = 3'b001;
    hburst_i = 3'b001;
    htrans_i = 2'b10;
    
    @(posedge clkb);
    #2;
    hsel_i = 0;
    haddr_i = 16'h0;
    hwrite_i = 0;
    hsize_i = 3'b000;
    hburst_i = 3'b000;    
    htrans_i = 2'b00;    

    

    
   @(posedge clkb);
    wait(hready_o);
    #2;

    hwdata_i = 32'h0;

    
    #(4*`CYCLEB);
    end
    
    endtask   
/*	
// mem_address_not_aligned check
always@(posedge clkb)
begin
`ifdef word_mode
    begin
        if(haddr_i[1:0] != 2'b00)
            begin
                $display("mem_address_not_aligned @ %t!!!",$time);
                $finish;
            end
    end
`elsif halfword_mode
    begin
    if(haddr_i[0] != 1'b0)
        begin
            $display("mem_address_not_aligned @ %t!!!",$time);
            $finish;
        end
    end
 `endif   
end
*/	
	
endmodule
