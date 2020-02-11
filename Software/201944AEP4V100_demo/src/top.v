//`define __LED_FLOW__
//`define __LED_UART__
`define __LED_SD_SDRAM_UART__

module top(
    /*  clock and reset_n  */
    input   wire        clk_in,
    input   wire        reset_n,
    /*  LED  */
    output  wire [5:0]  led,
    /*  UART  */
    output  wire        uart_tx_path,   // to CH340 RXD
    input   wire        uart_rx_path,   // to CH340 TXD
    /*  SD SPI  */
    input   wire        sd_spi_miso,
    output  wire        sd_spi_clk,
    output  wire        sd_spi_cs,
    output  wire        sd_spi_mosi,
    /*  SDRAM  */
	output	wire 		sdram_clk,
	output	wire 		sdram_cke,
	output	wire 		sdram_cs_n,
	output	wire 		sdram_ras_n,
	output	wire 		sdram_cas_n,
	output  wire        sdram_we_n,
	output	wire [1:0]	sdram_bs,
	output	wire [12:0]	sdram_addr,
	inout	wire [15:0]	sdram_data,
	output	wire [1:0]	sdram_dqm
);
    
    parameter CLK_FREQ = 32'd50_000_000;
    parameter UART_BAUD = 32'd115200;
    
    /*  PLL  */
    wire clk_50m;
    wire clk_sd;
    wire clk_sd_n;
    wire clk_100m_logic;    // sdram controller logic clock
    wire clk_100m_sdram;    // sdram controller output clock
    wire pll_locked;
    wire reset_sys_n = reset_n & pll_locked;
    
    /*  LED Wire  */
    wire [5:0]  led_flow_w;
    wire [5:0]  led_uart_w;
    wire [1:0]  led_sd_w;
    wire [1:0]  led_sdram_w;
    
    `ifdef __LED_FLOW__
        assign led = led_flow_w;
    `endif
    `ifdef __LED_UART__
        assign led = led_uart_w;
    `endif
    `ifdef __LED_SD_SDRAM_UART__
        assign led = {led_sd_w,led_sdram_w,led_uart_w[1:0]};
    `endif
    
    /*  UART  */
    wire [7:0]  uart_tx_data;
    wire        uart_tx_enable;
    wire [7:0]  uart_rx_data;
    wire        uart_rx_done;
    
    /*  SD SPI  */
    wire        sd_wr_start_en;
    wire [31:0] sd_wr_sec_addr;
    wire        sd_rd_start_en;
    wire [31:0] sd_rd_sec_addr;
    wire        sd_error_flag;
    wire        sd_wr_busy;
    wire        sd_wr_req;
    wire [15:0] sd_wr_data;
    wire        sd_rd_busy;
    wire        sd_rd_en;
    wire [15:0] sd_rd_data;
    wire        sd_init_done;
    
    assign led_sd_w = {sd_init_done,~sd_error_flag};

    /*  SDRAM  */
    wire        sdram_wr_en;            // sdram write enable
    wire [15:0] sdram_wr_data;          // sdram write data
    wire        sdram_rd_en;            // sdram read enable
    wire [15:0] sdram_rd_data;          // sdram read data
    wire        sdram_init_done;        // sdram initial done
    wire        sdram_error_flag;       // sdram error flag
    
    assign led_sdram_w = {sdram_init_done,~sdram_error_flag};
    
    /*  Instance  */
    /*  PLL  */
    pll	u_pll (
        .areset         (~reset_n),
        .inclk0         (clk_in),       // clk_in = 50MHz
        .c0             (clk_50m),      // c0 = 50MHz @ 0deg
        .c1             (clk_sd),       // c1 = 20MHz @ 0deg
        .c2             (clk_sd_n),     // c2 = 20MHz @ 180deg
        .c3             (clk_100m_logic),
        .c4             (clk_100m_sdram),
        .locked         (pll_locked)
	);
    
    /*  LED Flow  */
    led_flow
    #(
        .CLK_DIV        (CLK_FREQ/32'd10)
    )
    u_led_flow
    (
        .clk_50m        (clk_50m),
        .reset_n        (reset_sys_n),
        
        .led            (led_flow_w)
    );
    
    /*  UART  */
    uart_controller
    #(
        .CLK_FREQ       (CLK_FREQ),
        .UART_BAUD      (UART_BAUD)
    )
    u_uart_controller(
        .uart_clk_in    (clk_50m),
        
        .uart_tx_data   (uart_tx_data),
        .uart_tx_enable (uart_tx_enable),
        
        .uart_rx_data   (uart_rx_data),
        .uart_rx_done   (uart_rx_done),
        
        .uart_tx_path   (uart_tx_path),
        .uart_rx_path   (uart_rx_path)
    );
    
    uart_test
    #(
        .CLK_FREQ       (CLK_FREQ)
    )
    u_uart_test(
        .clk_50m        (clk_50m),
        .reset_n        (reset_sys_n),
        
        .uart_tx_data   (uart_tx_data),
        .uart_tx_enable (uart_tx_enable),
        
        .uart_rx_data   (uart_rx_data),
        .uart_rx_done   (uart_rx_done),
        
        .led            (led_uart_w)
    );
    
    /*  SD SPI  */
    sd_spi_controller u_sd_spi_controller(
        .clk_sd         (clk_sd),
        .clk_sd_n       (clk_sd_n),
        .reset_n        (reset_sys_n),
        .sd_spi_miso    (sd_spi_miso),
        .sd_spi_clk     (sd_spi_clk),
        .sd_spi_cs      (sd_spi_cs),
        .sd_spi_mosi    (sd_spi_mosi),
        .wr_start_en    (sd_wr_start_en),   // start writing data
        .wr_sec_addr    (sd_wr_sec_addr),   // write sector address
        .wr_data        (sd_wr_data),       // write data
        .wr_busy        (sd_wr_busy),       // write busy
        .wr_req         (sd_wr_req),        // write request
        .rd_start_en    (sd_rd_start_en),   // start reading data
        .rd_sec_addr    (sd_rd_sec_addr),   // read sector address
        .rd_busy        (sd_rd_busy),       // read busy
        .rd_en          (sd_rd_en),         // read enable
        .rd_data        (sd_rd_data),       // read data
        .sd_init_done   (sd_init_done)      // sd initial done
    );
    
    sd_spi_data_gen u_sd_spi_data_gen(
        .clk_sd         (clk_sd),           // clock
        .reset_n        (reset_sys_n),      // reset
        .sd_init_done   (sd_init_done),     // sd initial done
        .wr_busy        (sd_wr_busy),       // write busy
        .wr_req         (sd_wr_req),        // write request
        .wr_start_en    (sd_wr_start_en),   // start writing data
        .wr_sec_addr    (sd_wr_sec_addr),   // write sector address
        .wr_data        (sd_wr_data),       // write data
        .rd_en          (sd_rd_en),         // read enable
        .rd_data        (sd_rd_data),       // read data
        .rd_start_en    (sd_rd_start_en),   // start reading data
        .rd_sec_addr    (sd_rd_sec_addr),   // read sector address
        .error_flag     (sd_error_flag)     // sd error flag
    );
        
    /*  SDRAM  */
    // SDRAM addr: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
    sdram_top u_sdram_top(
        .ref_clk			(clk_100m_logic),   // sdram controller logic clock
        .out_clk			(clk_100m_sdram),	// sdram controller output clock
        .reset_n            (reset_sys_n),		// reset_n
        
        // FIFO Write
        .wr_clk 			(clk_50m),		    // FIFO Write clock
        .wr_en				(sdram_wr_en),      // FIFO Write enable
        .wr_data		    (sdram_wr_data),    // FIFO Write data
        .wr_min_addr		(24'd0),			// sdram Write address start
        .wr_max_addr		(24'd1024),		    // sdram Write address stop
        .wr_len			    (10'd512),			// sdram Write burst length
        .wr_load			(~reset_sys_n),		// clear write address and fifo
       
        // FIFO Read
        .rd_clk             (clk_50m),			// FIFO Read clock
        .rd_en				(sdram_rd_en),      // FIFO Read enable
        .rd_data	    	(sdram_rd_data),    // FIFO Read data
        .rd_min_addr		(24'd0),			// sdram Read address start
        .rd_max_addr		(24'd1024),	    	// sdram Read address stop
        .rd_len 			(10'd512),			// sdram Read burst length
        .rd_load			(~reset_sys_n),		// clear read address and fifo
           
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

    sdram_test u_sdram_test(
        .clk_50m            (clk_50m),
        .reset_n            (reset_sys_n),
        
        .wr_en              (sdram_wr_en),
        .wr_data            (sdram_wr_data),
        .rd_en              (sdram_rd_en),
        .rd_data            (sdram_rd_data),   
        
        .sdram_init_done    (sdram_init_done),    
        .error_flag         (sdram_error_flag)
    );

endmodule 