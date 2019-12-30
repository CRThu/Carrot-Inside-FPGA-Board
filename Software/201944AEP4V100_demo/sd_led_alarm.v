module sd_led_alarm #(parameter T_DIV = 25'd25_000_000)(
    input wire          clock,
    input wire          reset_n,

    output wire [5:0]   led,
    
    input wire          error_flag,
    input wire          sd_init_done
);

    reg               led_buf;
    reg    [24:0]     led_cnt;
    
    assign  led = {4'b0000,sd_init_done,led_buf};
    
    always @(posedge clock or negedge reset_n) begin
        if(!reset_n)
        begin
            led_cnt <= 25'd0;
            led_buf <= 1'b0;
        end
        else
        begin
            if(error_flag)
            begin
                if(led_cnt == T_DIV - 1'b1)
                begin
                    led_cnt <= 25'd0;
                    led_buf <= ~led_buf;
                end
                else
                    led_cnt <= led_cnt + 25'd1;
            end
            else
            begin
                led_cnt <= 25'd0;
                led_buf <= 1'b1;
            end
        end
    end

endmodule