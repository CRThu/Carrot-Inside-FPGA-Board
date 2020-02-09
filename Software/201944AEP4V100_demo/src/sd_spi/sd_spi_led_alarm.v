module sd_spi_led_alarm
    #(parameter    L_TIME = 25'd25_000_000)
    (
    input wire              clk         ,
    input wire              reset_n     ,
    output wire     [5:0]   led         ,
    input wire              error_flag  ,
    input wire              sd_init_done
);

    reg led_error;
    reg [24:0] div_cnt;

    // led1|all test completed  |error:flash success:1
    // led2|init completed      |error:0     success:1
    
    assign led = {4'b0, sd_init_done, led_error};

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            div_cnt <= 25'd0;
            led_error <= 1'b0;
        end
        else
        begin
            if(error_flag)
            begin
                if(div_cnt == L_TIME - 1'b1)
                begin
                    div_cnt <= 25'd0;
                    led_error <= ~led_error;
                end
                else
                    div_cnt <= div_cnt + 25'd1;
            end
            else
            begin
                div_cnt <= 25'd0;
                led_error <= 1'b1;
            end
        end
    end

endmodule // sd_spi_led_alarm