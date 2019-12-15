module sd_spi_led_alarm(
        input wire              clk         ,
        input wire              reset_n     ,
        output wire     [5:0]   led         ,
        input wire              error_flag
);

    reg led_error;

    assign led = {5'b0, led_error};

    always @(posedge clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            led_error <= 1'b0;
        end
        else
        begin
            if(error_flag)
                led_error <= 1'b1;
        end
    end


endmodule // sd_spi_led_alarm