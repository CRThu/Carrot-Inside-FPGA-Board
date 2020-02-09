module	sdram_top(
	input         ref_clk,          // sdram controller logic clock
	input         out_clk,          // sdram controller output clock
	input         reset_n,          // reset_n
    
    // FIFO Write	
	input         wr_clk,           // FIFO Write clock
	input         wr_en,            // FIFO Write enable
    input  [15:0] wr_data,          // FIFO Write data
	input  [23:0] wr_min_addr,      // sdram Write address start
	input  [23:0] wr_max_addr,      // sdram Write address stop
	input  [ 9:0] wr_len,           // sdram Write burst length
	input         wr_load,          // clear write address and fifo
    
    // FIFO Read
	input         rd_clk,           // FIFO Read clock
	input         rd_en,            // FIFO Read enable
	output [15:0] rd_data,          // FIFO Read data
	input  [23:0] rd_min_addr,      // sdram Read address start
	input  [23:0] rd_max_addr,      // sdram Read address stop
	input  [ 9:0] rd_len,           // sdram Read burst length
	input         rd_load,          // clear read address and fifo
    
    // sdram signal
    input         sdram_read_valid, // sdram read valid
	output        sdram_init_done,  // sdram initial done
    
	// sdram interface
	output        sdram_clk,
	output        sdram_cke,
	output        sdram_cs_n,
	output        sdram_ras_n,
	output        sdram_cas_n,
	output        sdram_we_n,
	output [ 1:0] sdram_bs,
	output [12:0] sdram_addr,
	inout  [15:0] sdram_data,
	output [ 1:0] sdram_dqm
);

    wire        sdram_wr_req;       // sdram write request
    wire        sdram_wr_ack;       // sdram write ack
    wire [23:0]	sdram_wr_addr;      // sdram write address
    wire [15:0]	sdram_din;          // sdram write data

    wire        sdram_rd_req;       // sdram read request
    wire        sdram_rd_ack;       // sdram read ack
    wire [23:0]	sdram_rd_addr;      // sdram read address
    wire [15:0]	sdram_dout;         // sdram read data
    
    
    assign	sdram_clk = out_clk;    // sdram clock
    assign	sdram_dqm = 2'b00;      // sdram mask
    
    // sdram fifo controller
    sdram_fifo_ctrl u_sdram_fifo_ctrl(
        .clk_ref			(ref_clk),          // clock
        .reset_n            (reset_n),			// reset_n

        // FIFO Write
        .clk_write 			(wr_clk),    	    // FIFO Write clock
        .fifo_wr_req        (wr_en),			// FIFO Write request
        .fifo_wr_din        (wr_data),		    // FIFO Write data
        .wr_min_addr	    (wr_min_addr),		// sdram Write address start
        .wr_max_addr		(wr_max_addr),		// sdram Write address stop
        .wr_length			(wr_len),		    // sdram Write burst length
        .wr_load			(wr_load),			// clear write address and fifo
        
        // FIFO Read
        .clk_read			(rd_clk),     	    // FIFO Read clock
        .fifo_rd_req        (rd_en),			// FIFO Read request
        .fifo_rd_dout       (rd_data),		    // FIFO Read data
        .rd_min_addr		(rd_min_addr),	    // sdram Read address start
        .rd_max_addr		(rd_max_addr),		// sdram Read address stop
        .rd_length			(rd_len),		    // sdram Read burst length
        .rd_load			(rd_load),			// clear read address and fifo
       
        // sdram signal
        .sdram_read_valid	(sdram_read_valid), // sdram read valid
        .sdram_init_done	(sdram_init_done),	// sdram initial done

        // sdram write interface
        .sdram_wr_req		(sdram_wr_req),		// sdram write request
        .sdram_wr_ack		(sdram_wr_ack),	    // sdram write ack
        .sdram_wr_addr		(sdram_wr_addr),	// sdram write address
        .sdram_din			(sdram_din),		// sdram write data
        
        // sdram read interface
        .sdram_rd_req		(sdram_rd_req),		// sdram read request
        .sdram_rd_ack		(sdram_rd_ack),	    // sdram read ack
        .sdram_rd_addr		(sdram_rd_addr),    // sdram read address
        .sdram_dout			(sdram_dout)		// sdram read data
    );
    
    // sdram controller
    sdram_controller u_sdram_controller(
        .clk				(ref_clk),			// clock
        .reset_n            (reset_n),			// reset_n
        
        // sdram write
        .sdram_wr_req		(sdram_wr_req), 	// sdram write request
        .sdram_wr_ack		(sdram_wr_ack), 	// sdram write ack
        .sdram_wr_addr		(sdram_wr_addr), 	// sdram write address
        .sdram_wr_burst		(wr_len),		    // sdram write burst length
        .sdram_din  		(sdram_din),    	// sdram write data
        
        // sdram read
        .sdram_rd_req		(sdram_rd_req), 	// sdram read request
        .sdram_rd_ack		(sdram_rd_ack),		// sdram read ack
        .sdram_rd_addr		(sdram_rd_addr), 	// sdram read address
        .sdram_rd_burst		(rd_len),		    // sdram read burst length
        .sdram_dout		    (sdram_dout),       // sdram read data
        
        // sdram signal
        .sdram_init_done	(sdram_init_done),	// sdram initial done
        
        // sdram interface
        .sdram_cke			(sdram_cke),
        .sdram_cs_n			(sdram_cs_n),
        .sdram_ras_n		(sdram_ras_n),
        .sdram_cas_n		(sdram_cas_n),
        .sdram_we_n			(sdram_we_n),
        .sdram_bs			(sdram_bs),	
        .sdram_addr			(sdram_addr),
        .sdram_data			(sdram_data)
    );
    
endmodule 