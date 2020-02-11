module uart_tx_path
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
	input wire          clk_in,
    
	input wire  [7:0]   uart_tx_data,
	input wire          uart_tx_enable,
	
	output reg          uart_tx_path = 1'b1
);

    parameter [31:0] BAUD_RATE_CNT			= CLK_FREQ / UART_BAUD; // baud rate
    parameter [31:0] BAUD_RATE_CNT_HALF		= BAUD_RATE_CNT / 2;    // half of baud rate

    reg         uart_tx_en_signal = 1'b0;
    reg [31:0]  baud_rate_counter = 32'b0;  // baud rate counter
    reg         baud_bps = 1'b0;            // send bit signal
    reg [9:0]   send_byte = 10'b1111111111;	// send byte : 1bit start + 8bit byte + 1bit end
    reg [3:0]   bit_cursor = 4'b0;          // send cursor
    reg         uart_send_flag = 1'b0;      // data send flag
    
    // prevent uart_tx_enable width shorter than clk_in period 
    always@(posedge uart_tx_enable or posedge clk_in)
    begin
        if(uart_tx_enable)
        begin
            uart_tx_en_signal <= 1'b1;
        end
        else
        if(uart_tx_en_signal)	// wait for sending enable signal
        begin
            uart_tx_en_signal <= 1'b0;
        end
    end
    
    // generate baud_bps for sending bit signal
    always@(posedge clk_in)
    begin
        if(baud_rate_counter == BAUD_RATE_CNT_HALF)
        begin
            baud_bps <= 1'b1;
            baud_rate_counter <= baud_rate_counter + 1'b1;
        end
        else
        if(baud_rate_counter < BAUD_RATE_CNT && uart_send_flag)
        begin
            baud_bps <= 1'b0;	
            baud_rate_counter <= baud_rate_counter + 1'b1;
        end
        else
        begin
            baud_bps <= 1'b0;
            baud_rate_counter <= 32'b0;
        end
    end
    
    // uart_tx_data to send_byte register
    always@(posedge clk_in)
    begin
        if(uart_tx_en_signal)	// wait for sending enable signal
        begin
            uart_send_flag <= 1'b1;
            send_byte <= {1'b1, uart_tx_data, 1'b0};	// send byte : 1bit start + 8bit byte + 1bit end
        end
        else
        if(bit_cursor == 4'd10)	// wait for sending finished and clear send data
        begin
            uart_send_flag <= 1'b0;
            send_byte <= 10'b1111111111;
        end
    end

    // send bit and move bit_cursor
    always@(posedge clk_in)
    begin
        if(uart_send_flag)	// wait for send flag
        begin
            if(baud_bps)	// wait for send bit signal
            begin
                if(bit_cursor <= 4'd9)
                begin
                    uart_tx_path <= send_byte[bit_cursor];	// send bit in send byte register
                    bit_cursor <= bit_cursor + 1'b1;
                end
            end
            else
                if(bit_cursor == 4'd10)
                    bit_cursor <= 4'd0;
            end
        else
        begin
            uart_tx_path <= 1'b1;	// when available, send high
            bit_cursor <= 4'd0;
        end
    end

endmodule
