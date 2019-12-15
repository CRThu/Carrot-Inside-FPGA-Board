module sd_spi_controller(
    input wire clk_in,
    input wire reset_n,
);
    
    wire clk_50m;
    wire clk_50m_n;
    wire pll_locked;
    
    ip_pll	u_ip_pll (
        .areset     ( ~reset_n      ),
        .inclk0     ( clk_in        ),
        .c0         ( clk_50m       ),
        .c1         ( clk_50m_n     ),
        .locked     ( pll_locked    )
	);

    
    
    
endmodule
