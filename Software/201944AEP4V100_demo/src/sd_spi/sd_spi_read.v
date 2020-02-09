module sd_spi_read(
    input wire          clk_sd      ,
    input wire          clk_sd_n    ,
    input wire          reset_n     ,
    /*  SPI  */
    input wire          sd_spi_miso ,
    output reg          sd_spi_cs   ,
    output reg          sd_spi_mosi ,
    /*  Read  */
    input wire          rd_start_en ,
    input wire  [31:0]  rd_sec_addr ,
    output reg  [15:0]  rd_data     ,
    output reg          rd_busy     ,
    output reg          rd_en       
);

    reg             rd_en_delay0;
    reg             rd_en_delay1;
    wire            pos_rd_en;

    // respond data
    reg             res_en;
    reg     [7:0]   res_data;
    reg             res_flag;
    reg     [5:0]   res_bit_cnt;

    // read
    reg             rd_en_buf;
    reg     [15:0]  rd_data_buf;
    reg             rd_flag;
    reg     [3:0]   rd_bit_cnt;
    reg     [8:0]   rd_data_cnt;
    reg             rd_finish_en;

    // command
    reg     [3:0]   rd_fsm_state;
    reg     [3:0]   rd_ctrl_cnt;
    reg     [47:0]  cmd_rd;
    reg     [5:0]   cmd_bit_cnt;
    reg             rd_data_flag;

    assign pos_rd_en = ( ~rd_en_delay1 ) & rd_en_delay0;

    // rd_start_en
    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_en_delay0 <= 1'b0;
            rd_en_delay1 <= 1'b0;
        end
        else
        begin
            rd_en_delay0 <= rd_start_en;
            rd_en_delay1 <= rd_en_delay0;
        end
    end

    // receive respond data
    always @(posedge clk_sd_n or negedge reset_n)
    begin
        if(!reset_n)
        begin
            res_en <= 1'b0;
            res_data <= 8'd0;
            res_flag <= 1'b0;
            res_bit_cnt <= 6'd0;
        end
        else
        begin
            // miso = 0, first bit
            if(sd_spi_miso == 1'b0 && res_flag == 1'b0)
            begin
                res_flag <= 1'b1;
                res_data <= {res_data[6:0],sd_spi_miso};
                res_bit_cnt <= res_bit_cnt + 6'd1;
                res_en <= 1'b0;
            end
            else if(res_flag)
            begin
                res_data <= {res_data[6:0],sd_spi_miso};
                res_bit_cnt <= res_bit_cnt + 6'd1;
                if(res_bit_cnt == 6'd7)
                begin
                    res_flag <= 1'b0;
                    res_bit_cnt <= 6'd0;
                    res_en <= 1'b1;
                end
            end
            else
                res_en <= 1'b0;
        end
    end

    // read data
    always @(posedge clk_sd_n or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_en_buf <= 1'b0;
            rd_data_buf <= 16'd0;
            rd_flag <= 1'b0;
            rd_bit_cnt <= 4'd0;
            rd_data_cnt <= 9'd0;
            rd_finish_en <= 1'b0;
        end
        else
        begin
            rd_en_buf <= 1'b0;
            rd_finish_en <= 1'b0;
            // 0xFE
            if(rd_data_flag && sd_spi_miso == 1'b0 && rd_flag == 1'b0)
                rd_flag <= 1'b1;
            else if(rd_flag)
            begin
                rd_bit_cnt <= rd_bit_cnt + 4'd1;
                rd_data_buf <= {rd_data_buf[14:0],sd_spi_miso};
                if(rd_bit_cnt == 4'd15)
                begin
                    rd_data_cnt <= rd_data_cnt + 9'd1;
                    // 1 block = 256*16b
                    if(rd_data_cnt <= 9'd255)
                        rd_en_buf <= 1'b1;
                    else if(rd_data_cnt == 9'd257)
                    begin
                        rd_flag <= 1'b0;
                        rd_finish_en <= 1'b1;
                        rd_data_cnt <= 9'd0;
                        rd_bit_cnt <= 4'd0;
                    end
                end
            end
            else
                rd_data_buf <= 16'd0;
        end
    end

    // read_data
    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            rd_en <= 1'b0;
            rd_data <= 16'd0;
        end
        else
        begin
            if(rd_en_buf)
            begin
                rd_en <= 1'b1;
                rd_data <= rd_data_buf;
            end
            else
                rd_en <= 1'b0;
        end
    end

    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            sd_spi_cs <= 1'b1;
            sd_spi_mosi <= 1'b1;
            rd_ctrl_cnt <= 4'd0;
            cmd_rd <= 48'd0;
            cmd_bit_cnt <= 6'd0;
            rd_busy <= 1'b0;
            rd_data_flag <= 1'b0;
        end
        else
        begin
            case (rd_ctrl_cnt)
                4'd0:
                begin
                    rd_busy <= 1'b0;
                    sd_spi_cs <= 1'b1;
                    sd_spi_mosi <= 1'b1;
                    if(pos_rd_en)
                    begin
                        cmd_rd <= {8'h51,rd_sec_addr,8'hff};
                        rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
                        rd_busy <= 1'b1;
                    end
                end 
                4'd1:
                begin
                    if(cmd_bit_cnt <= 6'd47)
                    begin
                        cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                        sd_spi_cs <= 1'b0;
                        sd_spi_mosi <= cmd_rd[6'd47 - cmd_bit_cnt];
                    end
                    else
                    begin
                        sd_spi_mosi <= 1'b1;
                        if(res_en)
                        begin
                            rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
                            cmd_bit_cnt <= 6'd0;
                        end
                    end
                end
                4'd2:
                begin
                    rd_data_flag <= 1'b1;
                    if(rd_finish_en)
                    begin
                        rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
                        rd_data_flag <= 1'b0;
                        sd_spi_cs <= 1'b1;
                    end
                end
                default: 
                begin
                    sd_spi_cs <= 1'b1;
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
                end
            endcase
        end
    end


endmodule // sd_spi_read