module uart_rx_path
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
    input wire          clk_in,
        
    output reg  [7:0]   uart_rx_data = 8'b0,
    output reg          uart_rx_done = 1'b0,
        
    input wire          uart_rx_path
);
    
    parameter [31:0] BAUD_RATE_CNT		    = CLK_FREQ / UART_BAUD; // baud rate
    parameter [31:0] BAUD_RATE_CNT_HALF	    = BAUD_RATE_CNT / 2;    // half of baud rate

    reg [31:0]  baud_rate_counter = 32'b0;		    // baud rate counter
    reg         baud_bps = 1'b0;                    // read bit signal
    reg         bps_start = 1'b0;                   // start for read byte
    
    // generate baud_bps for reading bit signal
    always@(posedge clk_in)
    begin
        if(baud_rate_counter == BAUD_RATE_CNT_HALF)	    	     
        begin
            baud_bps <= 1'b1;
            baud_rate_counter <= baud_rate_counter + 32'b1;
        end
        else
        if(baud_rate_counter < BAUD_RATE_CNT && bps_start)
        begin
            baud_rate_counter <= baud_rate_counter + 32'b1;
            baud_bps <= 1'b0;
        end
        else
        begin
            baud_bps <= 1'b0;
            baud_rate_counter <= 32'b0;
        end
    end

    reg [4:0]   uart_rx_in = 5'b11111;	            // read data register
    always@(posedge clk_in)
    begin
        uart_rx_in <= {uart_rx_in[3:0], uart_rx_path};
    end
    // when receive 5 low level signal, enable uart_rx_int = 0
    wire uart_rx_int = uart_rx_in[4] | uart_rx_in[3] | uart_rx_in[2] | uart_rx_in[1] | uart_rx_in[0];
    
    reg [3:0] bit_cursor = 4'd0;	        // receive cursor
    reg state = 1'b0;

    reg [7:0] uart_rx_data_temp = 8'b0;	    // byte register when receiving

    always@(posedge clk_in)
    begin
        uart_rx_done <= 1'b0;
        case(state)
            1'b0 :
                if(!uart_rx_int) // when uart_rx_int = 0, start receiving data
                begin
                    bps_start <= 1'b1;
                    state <= 1'b1;
                end
            1'b1 :
                if(baud_bps)	// when data receiving, move data to register
                begin
                    bit_cursor <= bit_cursor + 1'b1;
                    if(bit_cursor < 4'd9)	// byte : 1bit start + 8bit byte + 1bit end
                        uart_rx_data_temp[bit_cursor - 4'd1] <= uart_rx_path;
                end
                else
                if(bit_cursor == 4'd10) //when data received
                begin
                    bit_cursor <= 4'd0;
                    uart_rx_done <= 1'b1;
                    uart_rx_data <= uart_rx_data_temp;
                    state <= 1'b0;	// to state 0
                    bps_start <= 1'b0;
                end
        endcase
    end
endmodule
