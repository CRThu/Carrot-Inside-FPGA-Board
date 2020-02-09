module sdram_controller(
    input         clk,		        // clock
    input         reset_n,	        // reset_n
    
	// sdram write	
    input         sdram_wr_req,		// sdram write request
    output        sdram_wr_ack,		// sdram write ack
    input  [23:0] sdram_wr_addr,	// sdram write address
    input  [ 9:0] sdram_wr_burst,   // sdram write burst length
    input  [15:0] sdram_din,	    // sdram write data
    
	// sdram read
    input         sdram_rd_req,		// sdram read request
    output        sdram_rd_ack,		// sdram read ack
    input  [23:0] sdram_rd_addr,	// sdram read address
    input  [ 9:0] sdram_rd_burst,   // sdram read burst length
    output [15:0] sdram_dout,	    // sdram read data
    
    // sdram signal
    output	      sdram_init_done,  // sdram initial done
                                     
	// sdram interface
    output        sdram_cke,
    output        sdram_cs_n,
    output        sdram_ras_n,
    output        sdram_cas_n,
    output        sdram_we_n,
    output [ 1:0] sdram_bs,
    output [12:0] sdram_addr,
    inout  [15:0] sdram_data
);
    
    wire [4:0] init_state;          // sdram initial fsm state
    wire [3:0] work_state;          // sdram working fsm state
    wire [9:0] cnt_clk;             // delay counter
    wire       sdram_rd_wr;			// w/r:0/1
    
    // sdram control module
    sdram_ctrl u_sdram_ctrl(
        .clk                (clk),
        .reset_n            (reset_n),

        .sdram_wr_req       (sdram_wr_req),
        .sdram_rd_req       (sdram_rd_req),
        .sdram_wr_ack       (sdram_wr_ack),
        .sdram_rd_ack       (sdram_rd_ack),
        .sdram_wr_burst     (sdram_wr_burst),
        .sdram_rd_burst     (sdram_rd_burst),
        .sdram_init_done    (sdram_init_done),
        
        .init_state         (init_state),
        .work_state         (work_state),
        .cnt_clk            (cnt_clk),
        .sdram_rd_wr        (sdram_rd_wr)
    );
    
    // sdram command module
    sdram_cmd u_sdram_cmd(
        .clk                (clk),
        .reset_n            (reset_n),

        .sys_wraddr         (sdram_wr_addr),
        .sys_rdaddr         (sdram_rd_addr),
        .sdram_wr_burst     (sdram_wr_burst),
        .sdram_rd_burst     (sdram_rd_burst),
        
        .init_state         (init_state),
        .work_state         (work_state),
        .cnt_clk            (cnt_clk),
        .sdram_rd_wr        (sdram_rd_wr),
        
        .sdram_cke          (sdram_cke),
        .sdram_cs_n         (sdram_cs_n),
        .sdram_ras_n        (sdram_ras_n),
        .sdram_cas_n        (sdram_cas_n),
        .sdram_we_n         (sdram_we_n),
        .sdram_bs           (sdram_bs),
        .sdram_addr         (sdram_addr)
    );
    
    // sdram data module
    sdram_data u_sdram_data(
        .clk                (clk),
        .reset_n            (reset_n),
        
        .sdram_data_in      (sdram_din),
        .sdram_data_out     (sdram_dout),
        .work_state         (work_state),
        .cnt_clk            (cnt_clk),
        
        .sdram_data         (sdram_data)
    );

endmodule 