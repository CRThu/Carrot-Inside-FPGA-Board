module sd_spi_controller(
    input wire          clk_sd          ,
    input wire          clk_sd_n        ,
    input wire          reset_n         ,
    /*  SPI  */
    input wire          sd_spi_miso     ,
    output wire         sd_spi_clk      ,
    output reg          sd_spi_cs       ,
    output reg          sd_spi_mosi     ,
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
    assign sd_spi_clk = ( !sd_init_done ) ? sd_spi_init_clk : clk_sd_n;

    // sd signal mux
    always @(*)
    begin
        if(!sd_init_done)
        begin
            sd_spi_cs = sd_spi_init_cs;
            sd_spi_mosi = sd_spi_init_mosi;
        end
        else if(wr_busy)
        begin
            sd_spi_cs = sd_spi_wr_cs;
            sd_spi_mosi = sd_spi_wr_mosi;
        end
        else if(rd_busy)
        begin
            sd_spi_cs = sd_spi_rd_cs;
            sd_spi_mosi = sd_spi_rd_mosi;
        end
        else
        begin
            sd_spi_cs = 1'b1;
            sd_spi_mosi = 1'b1;
        end
    end
    
    /*  Instance  */
    sd_spi_init u_sd_spi_init(
    .clk_sd         (clk_sd),
    .reset_n        (reset_n),

    .sd_spi_miso    (sd_spi_miso),
    .sd_spi_clk     (sd_spi_init_clk),  // low speed
    .sd_spi_cs      (sd_spi_init_cs),
    .sd_spi_mosi    (sd_spi_init_mosi),

    .sd_init_done   (sd_init_done)
    );
    
    sd_spi_write u_sd_spi_write(
    .clk_sd         (clk_sd),
    .clk_sd_n       (clk_sd_n),
    .reset_n        (reset_n),
    /*  SPI  */
    .sd_spi_miso    (sd_spi_miso),
    .sd_spi_cs      (sd_spi_wr_cs),
    .sd_spi_mosi    (sd_spi_wr_mosi),
    /*  Write  */
    .wr_start_en    (wr_start_en),
    .wr_sec_addr    (wr_sec_addr),
    .wr_data        (wr_data),
    .wr_busy        (wr_busy),
    .wr_req         (wr_req)
    );
    
    sd_spi_read u_sd_spi_read(
    .clk_sd         (clk_sd),
    .clk_sd_n       (clk_sd_n),
    .reset_n        (reset_n),
    /*  SPI  */
    .sd_spi_miso    (sd_spi_miso),
    .sd_spi_cs      (sd_spi_rd_cs),
    .sd_spi_mosi    (sd_spi_rd_mosi),
    /*  Read  */
    .rd_start_en    (rd_start_en),
    .rd_sec_addr    (rd_sec_addr),
    .rd_data        (rd_data),
    .rd_busy        (rd_busy),
    .rd_en          (rd_en)
    );
    
endmodule
