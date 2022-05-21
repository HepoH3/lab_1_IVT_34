module kuz_cip_apb_wrapper(
		input				pclk_i,
			     			presetn_i,
	       		[31:0]		paddr_i,
		      				psel_i,
			     			penable_i,
				    		pwrite_i,
    			[31:0]	    pwdata_i, 
	       		[3:0]		pstrb_i,
		output				pready_o,
		      	[31:0]		prdata_o,
		      				pslverr_o);
	
reg [7:0]	mem[35:0];
reg	pready;

wire	resetn;
wire	req_ack;
wire	busy;
wire	valid;
wire	[127:0]	mem_in;
wire	[127:0]	mem_out;
integer i;

	kuznechik_cipher kuznechik(
	.clk_i(pclk_i),      
	.resetn_i(resetn),   
	.request_i(req_ack),  
	.ack_i(req_ack),      
	.data_i(mem_in),    
	.busy_o(busy),
	.valid_o(valid),    
	.data_o(mem_out));

always @(posedge pclk_i) begin
    if(psel_i)
	   pready <= penable_i;
end
	   
always @(posedge pclk_i) begin
    if (pwrite_i)
	   begin
	       if (!pslverr_o)
	           begin
	               case(paddr_i)
	               0:
	               begin 
	                   if (pstrb_i[0])
	                       mem[0] <= pwdata_i[7:0];
	                   if (pstrb_i[1])
			               mem[1] <= pwdata_i[15:8];
			       end
			       default : begin
			         for(i = 0; i < 4; i = i + 1)
			             mem[paddr_i + i] <= pwdata_i[i * 8 +: 8];
			       end
			     endcase 
		     end
        end
	if (valid)
	   begin
	       mem[20 + 0] <= mem_out[0 * 8 +: 8];
	       mem[20 + 1] <= mem_out[1 * 8 +: 8];
	       mem[20 + 2] <= mem_out[2 * 8 +: 8];
	       mem[20 + 3] <= mem_out[3 * 8 +: 8];
	       mem[20 + 4] <= mem_out[4 * 8 +: 8];
	       mem[20 + 5] <= mem_out[5 * 8 +: 8];
	       mem[20 + 6] <= mem_out[6 * 8 +: 8];
	       mem[20 + 7] <= mem_out[7 * 8 +: 8];
	       mem[20 + 8] <= mem_out[8 * 8 +: 8];
	       mem[20 + 9] <= mem_out[9 * 8 +: 8];
	       mem[20 + 10] <= mem_out[10 * 8 +: 8];
	       mem[20 + 11] <= mem_out[11 * 8 +: 8];
	       mem[20 + 12] <= mem_out[12 * 8 +: 8];
	       mem[20 + 13] <= mem_out[13 * 8 +: 8];
	       mem[20 + 14] <= mem_out[14 * 8 +: 8];
	       mem[20 + 15] <= mem_out[15 * 8 +: 8];
	   end
		mem[3][0] <= busy;	
		mem[2] <= valid;
	end

assign	pslverr_o = ((pwrite_i && (20 <= paddr_i)) || (paddr_i == 0 && (pstrb_i[3] || pstrb_i[2])));
assign	pready_o = pready;	
assign	resetn = mem[0] && presetn_i;
assign	req_ack = mem[1][0];
assign	mem_in = {mem[19], mem[18], mem[17], mem[16],
			mem[15], mem[14], mem[13], mem[12],
			mem[11], mem[10], mem[9], mem[8], 
			mem[7], mem[6], mem[5], mem[4]};
assign	prdata_o = {mem[paddr_i + 3], mem[paddr_i + 2], mem[paddr_i + 1], mem[paddr_i]};

endmodule