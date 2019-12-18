module sd_spi_write(
    input wire          clk_sd      ,
    input wire          clk_sd_n    ,
    input wire          reset_n     ,
    /*  SPI  */
    input wire          sd_spi_miso ,
    output reg          sd_spi_cs   ,
    output reg          sd_spi_mosi ,
    /*  Write  */
    input wire          wr_start_en ,
    input wire  [31:0]  wr_sec_addr ,
    input wire  [15:0]  wr_data     ,
    output reg          wr_busy     ,
    output reg          wr_req
);

    parameter HEAD_BYTE = 8'hFE;

    
    reg             wr_en_delay0;
    reg             wr_en_delay1;
    wire            pos_wr_en;

    // respond data
    reg             re_en;
    reg     [7:0]   re_data;
    reg             re_flag;
    reg     [5:0]   re_bit_cnt;
    // command
    reg     [3:0]   wr_ctrl_cnt;
    reg     [47:0]  cmd_wr;
    reg     [5:0]   cmd_bit_cnt;

    // write
    reg     [3:0]   wr_bit_cnt;
    reg     [8:0]   wr_data_cnt;
    reg     [15:0]  wr_data_buf;

    reg             detect_done_flag;
    reg     [7:0]   detect_data;

    assign pos_wr_en = ( ~wr_en_delay1 ) & wr_en_delay0;

    // wr_start_en
    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            wr_en_delay0 <= 1'b0;
            wr_en_delay1 <= 1'b0;
        end
        else
        begin
            wr_en_delay0 <= wr_start_en;
            wr_en_delay1 <= wr_en_delay0;
        end
    end

    // receive respond data
    always @(posedge clk_sd_n or negedge reset_n)
    begin
        if(!reset_n)
        begin
            re_en <= 1'b0;
            re_data <= 8'd0;
            re_flag <= 1'b0;
            re_bit_cnt <= 6'd0;
        end
        else
        begin
            if(sd_spi_miso == 1'b0 && re_flag == 1'b0)
            begin
                re_flag <= 1'b1;
                re_data <= {re_data[6:0], sd_spi_miso};
                re_bit_cnt <= re_bit_cnt + 6'd1;
                re_en <= 1'b0;
            end
            else if(re_flag)
            begin
                re_data <= {re_data[6:0], sd_spi_miso};
                re_bit_cnt <= re_bit_cnt + 6'd1;
                if(re_bit_cnt == 6'd7)
                begin
                    re_flag <= 1'b0;
                    re_bit_cnt <= 6'd0;
                    re_en <= 1'b1;
                end
            end
            else
                re_en <= 1'b0;
        end
    end

    // detect if sd is busy
    always @(posedge clk_sd or negedge reset_n) begin
        if(!reset_n)
            detect_data <= 8'd0;
        else if(detect_done_flag)
            detect_data <= {detect_data[6:0], sd_spi_miso};
        else
            detect_data <= 8'd0;
    end

    // write data
    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            sd_cs <= 1'b1;
            sd_spi_mosi <= 1'b1;
            wr_ctrl_cnt <= 4'd0;
            wr_busy <= 1'b0;
            cmd_wr <= 48'd0;
            cmd_bit_cnt <= 6'd0;
            bit_cnt <= 4'd0;
            wr_data_t <= 16'd0;
            data_cnt <= 9'd0;
            wr_req <= 1'b0;
            detect_done_flag <= 1'b0;
        end
        else
        begin
            
        end
    end




endmodule // sd_spi_write