---------------------------------------------------------------------------
-- Change Log
-- Version 0.0.1 : Initial version
---------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE std.textio.ALL;
USE IEEE.math_real.ALL;

ENTITY tb_cordic_sin IS
END tb_cordic_sin;

ARCHITECTURE testbench OF tb_cordic_sin IS
    CONSTANT width : INTEGER := 22;
    CONSTANT iterations: INTEGER := 15;
    
    TYPE array_f is ARRAY(0 TO 5) OF REAL;
    CONSTANT angle_array : array_f := (MATH_PI_OVER_4, MATH_PI_OVER_3, MATH_PI_OVER_2, MATH_PI_OVER_4, MATH_PI_OVER_3, MATH_PI_OVER_2) ;

	SIGNAL clk:    std_logic := '0';
	SIGNAL rst:    std_logic := '0';
	SIGNAL angle:  signed(width-1 DOWNTO 0) := (others => '0');
	SIGNAL sine:   signed(width-1 DOWNTO 0);

	CONSTANT clk_period : TIME := 1 ns;

BEGIN
	uut : ENTITY work.cordic_sin
        GENERIC MAP(
        width => width,
        iterations => iterations
        )
        PORT MAP(
        clk => clk, 
        rst => rst, 
        angle_in => angle, 
        sine_out => sine
        );
        
        clk_gen : PROCESS
        BEGIN
            clk <= '1';
            WAIT FOR clk_period/2;
            clk <= '0';
            WAIT FOR clk_period/2;
        END PROCESS clk_gen;
        
        rst_gen : PROCESS
        BEGIN
            rst <= '1';
            WAIT FOR clk_period * 3.5;
            rst <= '0';
            WAIT;
        END PROCESS rst_gen;
        
        angle_gen : PROCESS (clk, rst)
                        VARIABLE   count : INTEGER := 0;
        
        BEGIN
            IF rst = '1' THEN
               angle <= (others => '0');
            ELSIF rising_edge(clk) AND count < 5 THEN
               angle  <= to_signed(integer(angle_array(count) * 2.0**22/MATH_2_PI), width); 
               count := count + 1;
            END IF;
        
        END PROCESS angle_gen;

END testbench;