module led(
    input   wire        clk_50m,
    input   wire        reset,
    output  reg [5:0]   led = 6'b0
    );
    

    reg [31:0] cnt = 32'h0;

    always@(posedge clk_50m or negedge reset)
    begin
        if(!reset)
        begin
            cnt = 32'h0;
            led = 6'b0;
        end
        else
        begin
            if(cnt == 32'd5_000_000)
            begin
                cnt = 32'h0;
                
                led = led << 1;
                
                if(led == 6'b0)
                    led = 6'b1;
            end
            else
            begin
                cnt = cnt + 32'h1;
            end
            
        end
    end

    
endmodule