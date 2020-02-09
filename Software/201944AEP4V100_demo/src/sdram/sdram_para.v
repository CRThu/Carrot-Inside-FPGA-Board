// SDRAM initial fsm state
`define		I_NOP	        5'd0    // 200us for sdram initial
`define		I_PRE 	        5'd1    // precharge
`define		I_TRP 	        5'd2    // waiting for precharge            tRP
`define		I_AR 	        5'd3    // auto refresh
`define		I_TRF	        5'd4    // waiting for auto refresh         tRFC
`define		I_MRS	        5'd5    // mode register set
`define		I_TRSC	        5'd6    // waiting for mode register set    tRSC
`define		I_DONE	        5'd7    // initial done

// SDRAM working fsm state
`define		W_IDLE		    4'd0    // IDLE
`define		W_ACTIVE	    4'd1    // ACTIVE   R/W Row 
`define		W_TRCD		    4'd2    // tRCD
`define		W_READ		    4'd3    // READ     R   Column 
`define		W_CL		    4'd4    // CL
`define		W_RD		    4'd5    //          R   Dout
`define		W_WRITE		    4'd6    // WRITE    W   Column 
`define		W_WD		    4'd7    //          W   Din
`define		W_TWR		    4'd8    // tWR
`define		W_PRE		    4'd9    // PRECHARGE
`define		W_TRP		    4'd10   // tRP
`define		W_AR		    4'd11   // AUTO REFRESH
`define		W_TRFC		    4'd12   // tRFC
  
// delay counter
`define	    end_trp			cnt_clk	== TRP_CLK              // tRP
`define	    end_trfc		cnt_clk	== TRC_CLK              // tRFC
`define	    end_trsc		cnt_clk	== TRSC_CLK             // tRSC
`define	    end_trcd		cnt_clk	== TRCD_CLK-1           // tRCD
`define     end_tcl			cnt_clk == TCL_CLK-1            // CL
`define     end_rdburst		cnt_clk == sdram_rd_burst-4     // read burst stop
`define	    end_tread		cnt_clk	== sdram_rd_burst+2     // read burst end   
`define     end_wrburst		cnt_clk == sdram_wr_burst-1     // write burst stop
`define	    end_twrite		cnt_clk	== sdram_wr_burst-1     // write burst end
`define	    end_twr		    cnt_clk	== TWR_CLK	            // tWR

// sdram op
`define		CMD_INIT 	    5'b01111    // INIT
`define		CMD_NOP		    5'b10111	// NOP
`define		CMD_ACTIVE	    5'b10011    // ACTIVE
`define		CMD_READ	    5'b10101    // READ
`define		CMD_WRITE	    5'b10100    // WRITE
`define		CMD_B_STOP	    5'b10110    // BURST STOP
`define		CMD_PRGE	    5'b10010    // PRECHARGE
`define		CMD_A_REF	    5'b10001    // AUTO REFRESH
`define		CMD_LMR		    5'b10000    // LODE MODE REGISTER
