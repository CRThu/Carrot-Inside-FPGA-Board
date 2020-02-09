module led_flow
    #(
        parameter CLK_DIV = 32'd5_000_000
    )
    (
        input wire          clk_50m,
        input wire          reset_n,
    
        output reg  [5:0]   led
    );
    
    reg [31:0] cnt;

    always@(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            cnt <= 32'd0;
            led <= 6'b0;
        end
        else
        begin
            if(cnt == CLK_DIV)
            begin
                cnt <= 32'd0;
                if(led == 6'b0)
                    led <= 6'b1;
                else
                    led <= (led << 1);
            end
            else
            begin
                cnt <= cnt + 32'd1;
                led <= led;
            end
            
        end
    end

    
endmodule