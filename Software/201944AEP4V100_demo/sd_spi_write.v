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

    parameter WRITE_SECTOR_START_BYTE = 8'hFE;

    reg             wr_en_delay0;
    reg             wr_en_delay1;
    wire            pos_wr_en;

    // respond data
    reg             res_en;
    reg     [7:0]   res_data;
    reg             res_flag;
    reg     [5:0]   res_wr_bit_cnt;
    // command
    reg     [3:0]   wr_fsm_state;
    reg     [47:0]  cmd_wr;
    reg     [5:0]   cmd_wr_bit_cnt;

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
            res_en <= 1'b0;
            res_data <= 8'd0;
            res_flag <= 1'b0;
            res_wr_bit_cnt <= 6'd0;
        end
        else
        begin
            // miso = 0, first bit
            if(sd_spi_miso == 1'b0 && res_flag == 1'b0)
            begin
                res_flag <= 1'b1;
                res_data <= {res_data[6:0], sd_spi_miso};
                res_wr_bit_cnt <= res_wr_bit_cnt + 6'd1;
                res_en <= 1'b0;
            end
            else if(res_flag)
            begin
                res_data <= {res_data[6:0], sd_spi_miso};
                res_wr_bit_cnt <= res_wr_bit_cnt + 6'd1;
                if(res_wr_bit_cnt == 6'd7)
                begin
                    res_flag <= 1'b0;
                    res_wr_bit_cnt <= 6'd0;
                    res_en <= 1'b1;
                end
            end
            else
                res_en <= 1'b0;
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
            sd_spi_cs <= 1'b1;
            sd_spi_mosi <= 1'b1;
            wr_fsm_state <= 4'd0;
            wr_busy <= 1'b0;
            cmd_wr <= 48'd0;
            cmd_wr_bit_cnt <= 6'd0;
            wr_bit_cnt <= 4'd0;
            wr_data_buf <= 16'd0;
            wr_data_cnt <= 9'd0;
            wr_req <= 1'b0;
            detect_done_flag <= 1'b0;
        end
        else
        begin
            wr_req <= 1'b0;
            case (wr_fsm_state)
                4'd0:   // prepare for send command
                begin
                    wr_busy <= 1'b0;
                    sd_spi_cs <= 1'b1;
                    sd_spi_mosi <= 1'b1;
                    if(pos_wr_en)
                    begin
                        // begin
                        cmd_wr <= {8'h58, wr_sec_addr, 8'hff};  // CMD24
                        wr_fsm_state <= wr_fsm_state + 4'd1;
                        wr_busy <= 1'b1;
                    end
                end
                4'd1:   // send command
                begin
                    if(cmd_wr_bit_cnt <= 6'd47)
                    begin
                        cmd_wr_bit_cnt <= cmd_wr_bit_cnt + 6'd1;
                        sd_spi_cs <= 1'b0;
                        sd_spi_mosi <= cmd_wr[6'd47 - cmd_wr_bit_cnt];
                    end
                    else
                    begin
                        sd_spi_mosi <= 1'b1;
                        if(res_en)
                        begin
                            cmd_wr_bit_cnt <= 6'd0;
                            wr_bit_cnt <= 4'd1;
                            wr_fsm_state <= wr_fsm_state + 4'd1;
                        end
                    end
                end
                4'd2:   // nop and request data to write
                begin
                    wr_bit_cnt <= wr_bit_cnt + 4'd1;
                    if(wr_bit_cnt >= 4'd8 && wr_bit_cnt <= 4'd15)
                    begin
                        sd_spi_mosi <= WRITE_SECTOR_START_BYTE[4'd15-wr_bit_cnt];
                        if(wr_bit_cnt == 4'd14)
                            wr_req <= 1'b1;
                        else if(wr_bit_cnt == 4'd15)
                            wr_fsm_state <= wr_fsm_state + 4'd1;
                    end
                end
                4'd3:   // write sector
                begin
                    wr_bit_cnt <= wr_bit_cnt + 4'd1;
                    if(wr_bit_cnt == 4'd0)
                    begin
                        sd_spi_mosi <= wr_data[4'd15-wr_bit_cnt];
                        wr_data_buf <= wr_data;
                    end
                    else
                        sd_spi_mosi <= wr_data_buf[4'd15-wr_bit_cnt];

                    if((wr_bit_cnt == 4'd14) && (wr_data_cnt <= 9'd255))
                        wr_req <= 1'b1;     //???

                    if(wr_bit_cnt == 4'd15)
                    begin
                        wr_data_cnt <= wr_data_cnt + 9'd1;
                        if(wr_data_cnt == 9'd255)
                        begin
                            wr_data_cnt <= 9'd0;
                            wr_fsm_state <= wr_fsm_state + 4'd1;
                        end
                    end
                end
                4'd4:   // 16bit CRC (unchecked)
                begin
                    wr_bit_cnt <= wr_bit_cnt + 4'd1;
                    sd_spi_mosi <= 1'b1;
                    if(wr_bit_cnt == 4'd15)
                        wr_fsm_state <= wr_fsm_state + 4'd1; 
                end
                4'd5:   // get respond
                begin
                    if(res_en)
                        wr_fsm_state <= wr_fsm_state + 4'd1;
                end
                4'd6:   // wait for write busy
                begin
                    detect_done_flag <= 1'b1;
                    if(detect_data == 8'hff)
                    begin
                        wr_fsm_state <= wr_fsm_state + 4'd1;
                        detect_done_flag <= 1'b0;
                    end
                end
                default:    // cs=1, wait 8 clk
                begin
                    sd_spi_cs <= 1'b1;
                    wr_fsm_state <= wr_fsm_state + 4'd1;
                end 
            endcase
        end
    end

endmodule // sd_spi_write