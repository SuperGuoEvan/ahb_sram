//`define byte_mode   //hsize_i can be 3'b000 001 010 
//`define halfword_mode //hsize_i can be 3'b001 010 
`define word_mode   //hsize_i can be 3'b010

//Info :  1 cycle cen for write operation and byte_enable ram read operation , 2 cycles for other ram read operation
/*
*       ________________                                                                        ________________________________________________ 
*ahs0                  |________________________________________________________________________|
*                       _________________________________________________________________________
*ahs1   _______________|                                                                        |________________________________________________  
*                                                                               __________________________________________________________________ 
*data   _______________________________________________________________________|_________________________________________________________________
*               ________         ________       ________         ________       ________         ________       ________         ________
*CLKB   _______|       |________|       |______|       |________|       |______|       |________|       |______|       |________|       |________
*       ________________                                _________________________________________________________________________________________
*CENB                  |_______________________________|                              
*       ________________                 _________________________________________________________________________________________________________
*WENB                  |________________|
*                       ________________________________                                              
*ADDR   _______________|_______________________________|__________________________________________________________________________________________
*                                                       __________________________________________________________________________________________
*DOUT   _______________________________________________|__________________________________________________________________________________________
*/
