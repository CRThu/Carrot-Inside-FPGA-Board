module sd_spi_init(
    input wire  clk_sd,
    input wire  reset_n,

    /*  SPI  */
    input wire  sd_spi_miso,
    output wire sd_spi_clk,
    output reg  sd_spi_cs,
    output reg  sd_spi_mosi,

    output reg  sd_init_done
);

    // SD Write Command : { CMD, DATA, DATA, DATA, DATA, CRC }
    // in CMD : { 0, 1, 6'b CMD }
    // in CRC : { 7'b CRC, 1 }

    // software reset
    parameter CMD0  = { 8'h40, 8'h00, 8'h00, 8'h00, 8'h00, 8'h95 };
    // send master voltage
    parameter CMD8  = { 8'h48, 8'h00, 8'h00, 8'h01, 8'haa, 8'h87 };
    // convert to app command
    parameter CMD55 = { 8'h77, 8'h00, 8'h00, 8'h00, 8'h00, 8'h65 };
    // send OCR register
    parameter ACMD41 = { 8'h69, 8'h40, 8'h00, 8'h00, 8'h00, 8'h77 };
    // divider for clock, 50MHz / 200 = 250KHz
    parameter CLK_INIT_DIV = 200;
    // wait 74+ clk when power on
    parameter POWERON_CLK_NUM = 5000;
    // timeout length, 250KHz = 4us, 4us * 25000 = 100ms
    parameter TIMEOUT_NUM = 25000;

    // fsm
    parameter fsm_state_idle        = 3'd1;     // wait for sd when power on
    parameter fsm_state_send_cmd0   = 3'd2;     // send reset cmd
    parameter fsm_state_wait_cmd0   = 3'd3;     // wait for respond of reset
    parameter fsm_state_send_cmd8   = 3'd4;     // send master voltage
    parameter fsm_state_send_cmd55  = 3'd5;     // convert to app command
    parameter fsm_state_send_acmd41 = 3'd6;     // send OCR register
    parameter fsm_state_init_done   = 3'd7;     // sd initial done


    reg     [7:0]   current_fsm_state;
    reg     [7:0]   next_fsm_state;

    reg     [7:0]   init_div_cnt;
    reg             init_div_clk;
    wire            init_div_clk_n;

    reg     [12:0]  poweron_cnt;

    /*  respond data  */
    reg             re_en;
    reg     [47:0]  re_data;
    reg             re_flag;
    reg     [5:0]   re_bit_cnt;

    reg     [5:0]   cmd_bit_cnt;    // cmd send counter
    reg     [15:0]  timeout_cnt;    // timeout counter
    reg             timeout_en;

    // clk
    assign sd_spi_clk = ~init_div_clk;
    assign init_div_clk_n = ~init_div_clk;

    always @(posedge clk_sd or negedge reset_n)
    begin
        if(!reset_n)
        begin
            init_div_clk <= 1'b0;
            init_div_cnt <= 8'd0;
        end
        else
        begin
            if(init_div_cnt == CLK_INIT_DIV/2 - 1'b1)
            begin
                init_div_clk <= ~init_div_clk;
                init_div_cnt <= 8'd0;
            end
            else
                init_div_cnt <= init_div_cnt + 1'b1;
        end
    end

    // wait for poweron
    always @(posedge init_div_clk or negedge reset_n)
    begin
        if(!reset_n)
            poweron_cnt <= 13'd0;
        else if(current_fsm_state == fsm_state_idle)
        begin
            if(poweron_cnt < POWERON_CLK_NUM)
                poweron_cnt = poweron_cnt + 1'd1;
        end
        else
            poweron_cnt <= 13'd0;
    end

    // get respond data
    always @(posedge init_div_clk_n or negedge reset_n)
    begin
        if(!reset_n)
        begin
            re_en       <= 1'b0;
            re_data     <= 48'd0;
            re_flag     <= 1'b0;
            re_bit_cnt  <= 6'd0;
        end
        else
        begin
            // respond data
            if(sd_spi_miso == 1'b0 && re_flag == 1'b0)
            begin
                // first bit received
                re_flag         <= 1'b1;
                re_data         <= {re_data[46:0], sd_spi_miso};
                re_bit_cnt      <= re_bit_cnt + 6'd1;
            end
            else if(re_flag == 1'b1)
            begin
                // 5 bytes + NOP byte
                re_data         <= {re_data[46:0], sd_spi_miso};
                re_bit_cnt      <= re_bit_cnt + 6'd1;
                // received complete
                if(re_bit_cnt == 6'd47)
                begin
                    re_flag     <= 1'b0;
                    re_bit_cnt  <= 6'd0;
                    re_en       <= 1'b1;
                end
            end
            else
                re_en <= 1'b0;
        end
    end

    // fsm state
    always @(posedge init_div_clk or negedge reset_n)
    begin
        if(!reset_n)
            current_fsm_state <= fsm_state_idle;
        else
            current_fsm_state <= next_fsm_state;
    end

    // fsm
    always @(*)
    begin
        next_fsm_state = fsm_state_idle;
        case (current_fsm_state)
            fsm_state_idle:
            begin
                if(poweron_cnt == POWERON_CLK_NUM)
                    next_fsm_state = fsm_state_send_cmd0;
                else
                    next_fsm_state = fsm_state_idle;
            end
            fsm_state_send_cmd0:
            begin
                if(cmd_bit_cnt == 6'd47)
                    next_fsm_state = fsm_state_wait_cmd0;
                else
                    next_fsm_state = fsm_state_send_cmd0;
            end
            fsm_state_wait_cmd0:
            begin
                if(re_en)
                begin
                    // R1 = {1Byte RETURN, 5Byte NOP}
                    if(re_data[47:40] == 8'h01)
                        next_fsm_state = fsm_state_send_cmd8;
                    else
                        next_fsm_state = fsm_state_idle;
                end
                else if(timeout_en)
                    next_fsm_state = fsm_state_idle;
                else
                    next_fsm_state = fsm_state_wait_cmd0;
            end
            fsm_state_send_cmd8:
            begin
                if(re_en)
                begin
                    // R7 = {5Byte RETURN, 1Byte NOP}
                    if(re_data[19:16] == 4'b0001)
                        next_fsm_state = fsm_state_send_cmd55;
                    else
                        next_fsm_state = fsm_state_idle;
                end
                else
                    next_fsm_state = fsm_state_send_cmd8;
            end
            fsm_state_send_cmd55:
            begin
                if(re_en)
                begin
                    // R1 = {1Byte RETURN, 5Byte NOP}
                    if(re_data[47:40] == 8'h01)
                        next_fsm_state = fsm_state_send_acmd41;
                    else
                        next_fsm_state = fsm_state_send_cmd55;
                end
                else
                    next_fsm_state = fsm_state_send_cmd55;
            end
            fsm_state_send_acmd41:
            begin
                if(re_en)
                begin
                    // R1 = {1Byte RETURN, 5Byte NOP}
                    if(re_data[47:40] == 8'h00)
                        next_fsm_state = fsm_state_init_done;
                    else
                        next_fsm_state = fsm_state_send_acmd41;
                end
                else
                    next_fsm_state = fsm_state_send_acmd41;
            end
            fsm_state_init_done:
            begin
                next_fsm_state = fsm_state_init_done;
            end
            default: 
            begin
                next_fsm_state = fsm_state_idle;
            end
        endcase
    end

    // output data
    always @(posedge init_div_clk or negedge reset_n) begin
        if(!reset_n)
        begin
            sd_spi_cs <= 1'b1;
            sd_spi_mosi <= 1'b1;
            sd_init_done <= 1'b0;
            cmd_bit_cnt <= 6'd0;
            timeout_cnt <= 16'd0;
            timeout_en <= 1'b0;
        end
        else
        begin
            timeout_en <= 1'b0;
            case (current_fsm_state)
                fsm_state_idle: 
                begin
                    // when power on
                    sd_spi_cs <= 1'b1;
                    sd_spi_mosi <= 1'b1;
                end
                fsm_state_send_cmd0: 
                begin
                    // software reset
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_spi_cs <= 1'b0;
                    sd_spi_mosi <= CMD0[6'd47 - cmd_bit_cnt];   // MSB->LSB
                    if(cmd_bit_cnt == 6'd47)
                        cmd_bit_cnt <= 6'd0;
                end
                fsm_state_wait_cmd0: 
                begin
                    // wait for respond
                    sd_spi_mosi <= 1'b1;
                    if(re_en)
                        sd_spi_cs <= 1'b1;
                    timeout_cnt <= timeout_cnt + 1'b1;
                    // timeout
                    if(timeout_cnt == TIMEOUT_NUM - 1'b1)
                        timeout_en <= 1'b1;
                    if(timeout_en)
                        timeout_cnt <= 16'd0;
                end
                fsm_state_send_cmd8: 
                begin
                    // send cmd8
                    if(cmd_bit_cnt <= 6'd47)
                    begin
                        cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                        sd_spi_cs <= 1'b0;
                        sd_spi_mosi <= CMD8[6'd47 - cmd_bit_cnt];
                    end
                    else
                    begin
                        // respond
                        sd_spi_mosi <= 1'b1;
                        if(re_en)
                        begin
                            sd_spi_cs <= 1'b1;
                            cmd_bit_cnt <= 6'd0;
                        end
                    end
                end
                fsm_state_send_cmd55: 
                begin
                    // send cmd55
                    if(cmd_bit_cnt <= 6'd47)
                    begin
                        cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                        sd_spi_cs <= 1'b0;
                        sd_spi_mosi <= CMD55[6'd47 - cmd_bit_cnt];
                    end
                    else
                    begin
                        // respond
                        sd_spi_mosi <= 1'b1;
                        if(re_en)
                        begin
                            sd_spi_cs <= 1'b1;
                            cmd_bit_cnt <= 6'd0;
                        end
                    end
                end
                fsm_state_send_acmd41: 
                begin
                    // send acmd41
                    if(cmd_bit_cnt <= 6'd47)
                    begin
                        cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                        sd_spi_cs <= 1'b0;
                        sd_spi_mosi <= ACMD41[6'd47 - cmd_bit_cnt];
                    end
                    else
                    begin
                        // respond
                        sd_spi_mosi <= 1'b1;
                        if(re_en)
                        begin
                            sd_spi_cs <= 1'b1;
                            cmd_bit_cnt <= 6'd0;
                        end
                    end
                end
                fsm_state_init_done: 
                begin
                    // initial done 
                    sd_init_done <= 1'b1;
                    sd_spi_cs <= 1'b1;
                    sd_spi_mosi <= 1'b1;
                end
                default: 
                begin
                    sd_spi_cs <= 1'b1;
                    sd_spi_mosi <= 1'b1;
                end
            endcase
        end
    end

endmodule // sd_spi_init