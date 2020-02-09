// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

module sdram
(
// {ALTERA_ARGS_BEGIN} DO NOT REMOVE THIS LINE!

	clk_in,
	reset_n,
	led,
    
	sdram_clk,
	sdram_cke,
	sdram_cs_n,
	sdram_ras_n,
	sdram_cas_n,
	sdram_we_n,
	sdram_bs,
	sdram_addr,
	sdram_data,
	sdram_dqm
// {ALTERA_ARGS_END} DO NOT REMOVE THIS LINE!

);

// {ALTERA_IO_BEGIN} DO NOT REMOVE THIS LINE!
input			clk_in;
input			reset_n;
output  [5:0]	led;

output			sdram_clk;
output			sdram_cke;
output			sdram_cs_n;
output			sdram_ras_n;
output			sdram_cas_n;
output			sdram_we_n;
output	[1:0]	sdram_bs;
output	[12:0]	sdram_addr;
inout	[15:0]	sdram_data;
output	[1:0]	sdram_dqm;

// {ALTERA_IO_END} DO NOT REMOVE THIS LINE!
// {ALTERA_MODULE_BEGIN} DO NOT REMOVE THIS LINE!

    wire        clk_50m;                        // sdram test clock
    wire        clk_100m;                       // sdram controller logic clock
    wire        clk_100m_shift;                 // sdram controller output clock
         
    wire        wr_en;                          // sdram write enable
    wire [15:0] wr_data;                        // sdram write data
    wire        rd_en;                          // sdram read enable
    wire [15:0] rd_data;                        // sdram read data
    wire        sdram_init_done;                // sdram initial done

    wire        locked;
    wire        sys_reset_n;
    wire        error_flag;                     // sdram error flag

    assign sys_reset_n = reset_n & locked;

    // pll
    pll_clk u_pll_clk(
        .inclk0             (clk_in),
        .areset             (~reset_n),
        
        .c0                 (clk_50m),
        .c1                 (clk_100m_logic),
        .c2                 (clk_100m_sdram),
        .locked             (locked)
    );

    // sdram test
    sdram_test u_sdram_test(
        .clk_50m            (clk_50m),
        .reset_n            (sys_reset_n),
        
        .wr_en              (wr_en),
        .wr_data            (wr_data),
        .rd_en              (rd_en),
        .rd_data            (rd_data),   
        
        .sdram_init_done    (sdram_init_done),    
        .error_flag         (error_flag)
    );

    // led
    led_disp u_led_disp(
        .clk_50m            (clk_50m),
        .reset_n            (sys_reset_n),
       
        .sdram_init_done    (sdram_init_done),
        .error_flag         (error_flag),
        .led                (led)             
    );

    // sdram controller
    // SDRAM addr: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
    sdram_top u_sdram_top(
        .ref_clk			(clk_100m_logic),   // sdram controller logic clock
        .out_clk			(clk_100m_sdram),	// sdram controller output clock
        .reset_n            (sys_reset_n),		// reset_n
        
        // FIFO Write
        .wr_clk 			(clk_50m),		    // FIFO Write clock
        .wr_en				(wr_en),			// FIFO Write enable
        .wr_data		    (wr_data),		    // FIFO Write data
        .wr_min_addr		(24'd0),			// sdram Write address start
        .wr_max_addr		(24'd1024),		    // sdram Write address stop
        .wr_len			    (10'd512),			// sdram Write burst length
        .wr_load			(~sys_reset_n),		// clear write address and fifo
       
        // FIFO Read
        .rd_clk             (clk_50m),			// FIFO Read clock
        .rd_en				(rd_en),			// FIFO Read enable
        .rd_data	    	(rd_data),		    // FIFO Read data
        .rd_min_addr		(24'd0),			// sdram Read address start
        .rd_max_addr		(24'd1024),	    	// sdram Read address stop
        .rd_len 			(10'd512),			// sdram Read burst length
        .rd_load			(~sys_reset_n),		// clear read address and fifo
           
        // sdram signal
        .sdram_read_valid	(1'b1),             // sdram read valid
        .sdram_init_done	(sdram_init_done),	// sdram initial done
       
        // sdram interface
        .sdram_clk			(sdram_clk),
        .sdram_cke			(sdram_cke),
        .sdram_cs_n			(sdram_cs_n),
        .sdram_ras_n		(sdram_ras_n),
        .sdram_cas_n		(sdram_cas_n),
        .sdram_we_n			(sdram_we_n),
        .sdram_bs			(sdram_bs),
        .sdram_addr			(sdram_addr),
        .sdram_data			(sdram_data),
        .sdram_dqm			(sdram_dqm)
    );

// {ALTERA_MODULE_END} DO NOT REMOVE THIS LINE!

endmodule
