//`define __LED_FLOW__
//`define __LED_UART__
`define __LED_SD_TEST__

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
    output  wire        sd_spi_mosi
);

    /*  PLL  */
    wire clk_50m;
    wire clk_sd;
    wire clk_sd_n;
    wire pll_locked;
    wire reset_pll_n = reset_n & pll_locked;
    
    /*  Timer  */
    wire    [15:0]  timer_second;
    wire            timer_pps;
    /*  UART  */
    reg     [7:0]   uart_tx_data = 8'b0;
    reg             uart_tx_enable = 1'b0;
    wire    [7:0]   uart_rx_data;
    wire            uart_rx_done;
    
    /*  Instance  */
    /*  PLL  */
    ip_pll	u_ip_pll (
        .areset         (   ~reset_n        ),
        .inclk0         (   clk_in          ),      // clk_in = 50MHz
        .c0             (   clk_50m         ),      // c0 = 50MHz @ 0deg
        .c1             (   clk_sd          ),      // c1 = 20MHz @ 0deg
        .c2             (   clk_sd_n        ),      // c2 = 20MHz @ 180deg
        .locked         (   pll_locked      )
	);
    
    /*  LED Flow  */
    `ifdef __LED_FLOW__
        led u_led(
            .clk_50m        (   clk_50m         ),
            .reset_n        (   reset_pll_n     ),
            .led            (   led             )
        );
    `endif
    
    
    /*  Timer  */
    timer u_timer(
        .clk_50m        (   clk_50m         ),
        .reset_n        (   reset_pll_n     ),
        .second         (   timer_second    ),
        .pps            (   timer_pps       )
        );
    
    /*  UART_TX  */
    uart_tx_path u_uart_tx_path(
        .clk_in         (   clk_50m         ),
        .uart_tx_data   (   uart_tx_data    ),
        .uart_tx_enable (   uart_tx_enable  ),
        .uart_tx_path   (   uart_tx_path    )
        );
        
    /*  UART_RX  */
    uart_rx_path u_uart_rx_path(
        .clk_in         (   clk_50m         ),
        .uart_rx_path   (   uart_rx_path    ),
        .uart_rx_data   (   uart_rx_data    ),
        .uart_rx_done   (   uart_rx_done    )
        );
    
    /*  Send second to uart  */
    always@(timer_pps)
    begin
        if(timer_pps)
        begin
            uart_tx_data <= timer_second[7:0];
            uart_tx_enable <= 1'b1;
        end
        else
            uart_tx_enable <= 1'b0;
    end
    
    /*  Receive byte to control led  */
    /*  LED UART  */
    `ifdef __LED_UART__
        /*  UART Control Bit  */
        reg [5:0]   led_bit_reg = 6'b000000;
        assign led = led_bit_reg;
        
        always@(posedge uart_rx_done or negedge reset_pll_n)
        begin
            if(!reset_pll_n)
            begin
                led_bit_reg = 6'b000000;
            end
            else
            begin
                case(uart_rx_data)
                    6'h00:  led_bit_reg[0] = ~led_bit_reg[0];
                    6'h01:  led_bit_reg[1] = ~led_bit_reg[1];
                    6'h02:  led_bit_reg[2] = ~led_bit_reg[2];
                    6'h03:  led_bit_reg[3] = ~led_bit_reg[3];
                    6'h04:  led_bit_reg[4] = ~led_bit_reg[4];
                    6'h05:  led_bit_reg[5] = ~led_bit_reg[5];
                    default: ;
                endcase
            end
        end
    `endif
    
    `ifdef __LED_SD_TEST__
        wire            wr_start_en;
        wire    [31:0]  wr_sec_addr;
        wire    [15:0]  wr_data;
        wire            rd_start_en;
        wire    [31:0]  rd_sec_addr;
        wire            error_flag;
        
        wire            wr_busy;
        wire            wr_req;
        wire            rd_busy;
        wire            rd_en;
        wire    [15:0]  rd_data;
        wire            sd_init_done;
        
        sd_spi_data_gen u_sd_spi_data_gen(
            .clk_sd         (   clk_sd          ),      // clock
            .reset_n        (   reset_pll_n     ),      // reset
            .sd_init_done   (   sd_init_done    ),      // sd initial done
            .wr_busy        (   wr_busy         ),      // write busy
            .wr_req         (   wr_req          ),      // write request
            .wr_start_en    (   wr_start_en     ),      // start writing data
            .wr_sec_addr    (   wr_sec_addr     ),      // write sector address
            .wr_data        (   wr_data         ),      // write data
            .rd_en          (   rd_en           ),      // read enable
            .rd_data        (   rd_data         ),      // read data
            .rd_start_en    (   rd_start_en     ),      // start reading data
            .rd_sec_addr    (   rd_sec_addr     ),      // read sector address
            .error_flag     (   error_flag      )       // sd error flag
        );
        
        sd_spi_controller u_sd_spi_controller(
            .clk_sd         (   clk_sd          ),
            .clk_sd_n       (   clk_sd_n        ),
            .reset_n        (   reset_pll_n     ),
            .sd_spi_miso    (   sd_spi_miso     ),
            .sd_spi_clk     (   sd_spi_clk      ),
            .sd_spi_cs      (   sd_spi_cs       ),
            .sd_spi_mosi    (   sd_spi_mosi     ),
            .wr_start_en    (   wr_start_en     ),      // start writing data
            .wr_sec_addr    (   wr_sec_addr     ),      // write sector address
            .wr_data        (   wr_data         ),      // write data
            .wr_busy        (   wr_busy         ),      // write busy
            .wr_req         (   wr_req          ),      // write request
            .rd_start_en    (   rd_start_en     ),      // start reading data
            .rd_sec_addr    (   rd_sec_addr     ),      // read sector address
            .rd_busy        (   rd_busy         ),      // read busy
            .rd_en          (   rd_en           ),      // read enable
            .rd_data        (   rd_data         ),      // read data
            .sd_init_done   (   sd_init_done    )       // sd initial done
        );
        
        // led1 on:test success
        //      flash:error_flag=1
        // led2 on:initial done
        sd_led_alarm #(.T_DIV  (25'd5_000_000))  
        u_led_alarm(
            .clock          (   clk_sd          ),
            .reset_n        (   reset_pll_n     ),
            .led            (   led             ),
            .sd_init_done   (   sd_init_done    ),
            .error_flag     (   error_flag      )
        );
        
    `endif
    
endmodule