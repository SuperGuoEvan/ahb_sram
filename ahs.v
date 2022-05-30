`timescale 1ns / 1ps

`define IDLE	2'b00
`define	BUSY	2'b01
`define NSEQ	2'b10
`define	SEQ		2'b11


`define HWIDTH		16
`define DATAWIDTH	32
`define DEPTH		13

module ahs(
	hclk_i,
	hreset_n,
	hsel_i,
	haddr_i,
	htrans_i,
	hwrite_i,
	hsize_i,
	hburst_i,
	hwdata_i,
	hreadyslv_i,
	hready_o,
	hrdata_o,
	hresep_o,
	
	sram_dout,
	sram_ack,
	sram_cen,
	sram_addr,
	sram_wen,
	sram_din,
	sram_be
	    );
		
//Inputs from the ahb bus
input					hclk_i;		//	AHB Master clock
input					hreset_n;	//	AHB Master reset

input					hsel_i;		//	When `H,indicates AHB Slave port is selected
input	[`HWIDTH-1:0]	haddr_i;	//	AHB slave port address					
input	[1:0]			htrans_i;	//	AHB slave trans type	
input					hwrite_i;	//	When `H,indicates a write operation
									//	When `L,indicates a read operation

input	[2:0]			hsize_i;	//	Indicates the size of the Data transfer
input	[2:0]			hburst_i;	//	Indicates AHB burst type(SINGLE,INCR,INCR4/8/16)
input	[`DATAWIDTH-1:0]  hwdata_i;	//	Data to be written to sram
input					hreadyslv_i;//	Indicates that the hready on the AHB bus

//Outputs to the AHB 
output					hready_o;	//	AHB slave rady out used to indicates completion of 
									//	1 transfer cycle
output	[`DATAWIDTH-1:0]  hrdata_o;	//	Data read from sram	
output	[1:0]			hresep_o;	//	AHB slave response; is tied to "00" (OK)  hresep_o

//Inputs from sram	
input	[31:0]			sram_dout;	//	Read data from sram
input					sram_ack;	//	Ack ,for data transfer from sram

//Outputs to sram	
output					sram_cen;	//	Asserted to access the sram space
output	[`DEPTH-1:0]	sram_addr;	//	Address of the sram
output					sram_wen;	//	1-Read operation,0-Write operation						
output	[31:0]			sram_din;	//	Write datas to sram
output	[3:0]			sram_be;	//	Byte enables for sram_din


// reg declarations
reg						hready_o;
reg		[`DATAWIDTH-1:0]  hrdata_o;

reg						sram_cen;
reg						sram_wen;
reg		[3:0]			sram_be;
reg		[31:0]			sram_din;

reg		[1:0]			ahs_state;  //	Current state for AHS I/F FSM
reg		[1:0]			next_ahs_state ;

reg		[3:0]			ahs_be;		//	Generating byte enables based on size & addr
reg		[11:0]	sram_addr_int;	//	Internsl sram_addr required bits   ???
reg		[31:0]			narrow_wdarta;

// wire declarations
wire	[1:0]			hresep_o;
wire	[`DEPTH-1:0]	sram_addr;   //ahs_slave[15:0], sram[12:0]
wire					ahs_sel;
wire	[3:0]			ahs_be_end;	// endian-converted byte-enables

// parameter declarations
parameter				AHS_IDLE	= 0,
						AHS_DATA	= 1;

assign 	ahs_sel  	=	hsel_i  &  hreadyslv_i & (haddr_i[15:13] == 3'b000)	&
						(htrans_i == `NSEQ || htrans_i == `SEQ);
always @(*)
begin
	next_ahs_state  = 2'b00;
	case(1'b1)
	ahs_state[AHS_IDLE]: begin
	  if (ahs_sel)
		  next_ahs_state[AHS_DATA] = 1'b1;
	  else
	      next_ahs_state[AHS_IDLE] = 1'b1;
	end
	
	ahs_state[AHS_DATA]: begin
//	  if (sram_ack & !ahs_sel)  // 1208 for hready_o
	  if (sram_ack_later2 & !ahs_sel)
	    next_ahs_state[AHS_IDLE] = 1'b1;
	  else 
	    next_ahs_state[AHS_DATA] = 1'b1;
    end
	
	endcase
end
	
always @(posedge hclk_i or negedge hreset_n)
begin
  if(!hreset_n)
	ahs_state <= 2'b01;
  else
    ahs_state <= next_ahs_state;
end	

always @(posedge hclk_i or negedge hreset_n)
begin
  if (!hreset_n)
	hready_o <= 1'b1;
//  else if ((ahs_sel & ahs_state[AHS_IDLE]) | ahs_state[AHS_DATA])
//	hready_o <= sram_ack;
//	hready_o <= sram_ack & (!(ahs_sel & ahs_state[AHS_IDLE]));
/*
    begin   //1207,fixed for hready_o must down to 0 after hsel_i =1
	  if(ahs_sel)
		hready_o <= 1'b0;
	  else
	    hready_o <= sram_ack;
    end
*/

  else if (ahs_sel & ahs_state[AHS_IDLE]) 
	hready_o <= 1'b0;
//  else if (ahs_state[AHS_DATA])	
//	hready_o <= sram_ack_later;

//1212 for hready_o
  else if (ahs_state[AHS_DATA] & ahs_sel)	
	hready_o <= sram_ack_later;
  else if (ahs_state[AHS_DATA] & (!ahs_sel))
	hready_o <= sram_ack_later_0;
//

  else
    hready_o <= 1'b1;
end


assign hresep_o = 2'b00;		//always OK response

always @(*)
begin
  case (hsize_i)		
  3'b000 : begin				// 8-bit transfers
	case(haddr_i[1:0])
	2'b00:	ahs_be = 4'b0001;
	2'b01:  ahs_be = 4'b0010;
	2'b10:  ahs_be = 4'b0100;
	2'b11:  ahs_be = 4'b1000;
	endcase
  end

  3'b001 : begin				// 16-bit transfers
    case(haddr_i[1])
	1'b0:   ahs_be = 4'b0011;
	1'b1:   ahs_be = 4'b1100;
	endcase
  end
  
  default : ahs_be = 4'b1111;  // all other transfer sizes
  endcase
end

//assign ahs_be_end = {ahs_be[0],ahs_be[1],ahs_be[2],ahs_be[3]};
assign ahs_be_end = {ahs_be[3],ahs_be[2],ahs_be[1],ahs_be[0]};

reg	 [3:0]	ahs_be_r;
always @(posedge hclk_i or negedge hreset_n)
  if (!hreset_n)
	ahs_be_r <= 4'b1111;
  else
	ahs_be_r <= ahs_be;

always @(posedge hclk_i or negedge hreset_n)
begin
  if (!hreset_n)
	sram_cen <= 1'b1;
  else if (ahs_sel & hready_o)
    sram_cen <= 1'b0;
//  else if (!hready_o & sram_ack &ahs_state[AHS_DATA])  //at least 2 cycle
  else if (sram_ack &ahs_state[AHS_DATA])  //at least 2 cycle
	sram_cen <= 1'b1;
end

always @(posedge hclk_i or negedge hreset_n)
begin
  if (!hreset_n) begin
	sram_wen 		<= 1'b1;
	sram_addr_int 	<= 12'h000;
	sram_be 		<= 4'b1111;
  end
  else if (ahs_sel & (ahs_state[AHS_IDLE]) || (ahs_state[AHS_DATA])) begin
	sram_wen		<= !hwrite_i;
	sram_addr_int	<= haddr_i[13:2];
	sram_be			<= ahs_be_end;  //why endian-converted  ???  1209
//	sram_be			<= ahs_be_r;//20211208
  end
end

assign sram_addr   = {sram_addr_int , 2'b00};

always @(posedge hclk_i or negedge hreset_n)
  if(!hreset_n)
	sram_din  <= 32'h0000_0000;
  else 
    sram_din  <= narrow_wdarta;


reg sram_ack_later ; 
always @(posedge hclk_i or negedge hreset_n)
  if(!hreset_n)
    sram_ack_later  <= 1'b0;
  else 
    sram_ack_later  <=  sram_ack;
	
reg sram_ack_later_0 ; 
always @(posedge hclk_i or negedge hreset_n)
  if(!hreset_n)
    sram_ack_later_0  <= 1'b0;
  else if(sram_ack)
    sram_ack_later_0  <= 1'b1 ;	
  else if (ahs_sel & hready_o)
    sram_ack_later_0  <= 1'b0 ;
  
reg sram_ack_later2 ; 
always @(posedge hclk_i or negedge hreset_n)
  if(!hreset_n)
    sram_ack_later2  <= 1'b0;
  else 
    sram_ack_later2  <=  sram_ack_later;

always @(posedge hclk_i or negedge hreset_n)
  if(!hreset_n)
    hrdata_o  <= {`DATAWIDTH{1'b0}};
//  else if(sram_ack&sram_wen)  // waiting for check
  else if (sram_ack_later)
    hrdata_o  <=  sram_dout;
 
//if use byte_enable ram,then read operation only need 1 cycle, while others need 2 cycles. 
	
always @(*)
  narrow_wdarta <= hwdata_i;

		
endmodule
