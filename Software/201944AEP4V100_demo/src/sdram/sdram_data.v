module sdram_data(
    input             clk,			    // clock
    input             reset_n,			// reset_n

    input   [15:0]    sdram_data_in,    // sdram Din
    output  [15:0]    sdram_data_out,   // sdram Dout
    input   [ 3:0]    work_state,	    // sdram working fsm state
    input   [ 9:0]    cnt_clk, 		    // delay counter
    
    inout   [15:0]    sdram_data		// sdram interface
);

    `include "sdram_para.v"

    reg        sdram_out_en;            // sdram data output enable
    reg [15:0] sdram_din_r;             // Din Register
    reg [15:0] sdram_dout_r;            // Dout Register

    // I/O mux
    assign sdram_data = sdram_out_en ? sdram_din_r : 16'hzzzz;
    
    // Dout
    assign sdram_data_out = sdram_dout_r;
    
    // sdram data output enable
    always @ (posedge clk or negedge reset_n)
    begin 
        if(!reset_n)
           sdram_out_en <= 1'b0;
       else if((work_state == `W_WRITE) | (work_state == `W_WD))
           sdram_out_en <= 1'b1;
       else 
           sdram_out_en <= 1'b0;
    end
    
    // Din Register
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) 
            sdram_din_r <= 16'd0;
        else if((work_state == `W_WRITE) | (work_state == `W_WD))
            sdram_din_r <= sdram_data_in;
    end
    
    // Dout Register
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n)
            sdram_dout_r <= 16'd0;
        else if(work_state == `W_RD) 
            sdram_dout_r <= sdram_data;
    end
    
endmodule 