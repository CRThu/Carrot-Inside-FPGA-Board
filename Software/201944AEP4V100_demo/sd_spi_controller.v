module sd_spi_controller(
    input wire          clk_50m         ,
    input wire          clk_50m_n       ,
    input wire          reset_n         ,
    /*  SPI  */
    input wire          sd_miso         ,
    output wire         sd_clk          ,
    output reg          sd_cs           ,
    output reg          sd_mosi         ,
    /*  Write  */
    input wire          wr_start_en     ,   // start writing data
    input wire  [31:0]  wr_sec_addr     ,   // write sector address
    input wire  [15:0]  wr_data         ,   // write data
    output wire         wr_busy         ,   // write busy
    output wire         wr_req          ,   // write request
    /*  Read  */
    input wire          rd_start_en     ,   // start reading data
    input wire  [31:0]  rd_sec_addr     ,   // read sector address
    output wire         rd_busy         ,   // read busy
    output wire         rd_en           ,   // read enable
    output wire [15:0]  rd_data         ,   // read data

    output wire         sd_init_done        // sd initial done
);
    
    wire init_sd_clk    ;       // low speed clk when initial
    wire init_sd_cs     ;       // cs when initial
    wire init_sd_mosi   ;       // mosi when initial
    wire wr_sd_cs     ;         // cs when write
    wire wr_sd_mosi   ;         // mosi when write
    wire rd_sd_cs     ;         // cs when read
    wire rd_sd_mosi   ;         // mosi when read

    // sd clk mux
    assign sd_clk = (!sd_init_done) ? init_sd_clk : clk_50m_n;

    // sd signal mux
    always @(*)
    begin
        if(!sd_init_done)
        begin
            sd_cs = init_sd_cs;
            sd_mosi = init_sd_mosi;
        end
        else if(wr_busy)
        begin
            sd_cs = wr_sd_cs;
            sd_mosi = wr_sd_mosi;
        end
        else if(rd_busy)
        begin
            sd_cs = rd_sd_cs;
            sd_mosi = rd_sd_mosi;
        end
        else
        begin
            sd_cs = 1'b1;
            sd_mosi = 1'b1;
        end
    end
    
    /*  Instance  */
    sd_spi_init u_sd_spi_init();
    sd_spi_write u_sd_spi_write();
    sd_spi_read u_sd_spi_read();
    
endmodule
