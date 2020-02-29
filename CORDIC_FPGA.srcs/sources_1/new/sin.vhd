
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;

ENTITY cordic_sin IS
    GENERIC (
        width : INTEGER;
        fraction : INTEGER;
        iterations : INTEGER
    );
    PORT (
        clk : std_ulogic;
        rst : std_ulogic; 
        angle_in : IN signed(width - 1 DOWNTO 0);
        sine_out : OUT signed(width - 1 DOWNTO 0)
    );
END cordic_sin;

ARCHITECTURE behavioral OF cordic_sin IS

    TYPE signed_pipeline IS ARRAY (NATURAL RANGE <>) OF signed(width - 1 DOWNTO 0);
    
    SIGNAL x_pl, y_pl, z_pl : signed_pipeline(1 TO ITERATIONS);
    SIGNAL x_array, y_array, z_array : signed_pipeline(0 TO ITERATIONS);
    
    --Cordic lookup table [ATAN_TABLE(i)]
    FUNCTION atan_gen(
        size : INTEGER;
        iterations : INTEGER)
        RETURN signed_pipeline IS VARIABLE lut : signed_pipeline(0 TO iterations - 1);
    BEGIN
        FOR i IN lut'RANGE LOOP
            lut(i) := to_signed(INTEGER(ARCTAN(2.0**(-i))*2.0**size/ MATH_2_PI), size);
        END LOOP;
        RETURN lut;
    END FUNCTION;
    
    CONSTANT ATAN_TABLE : signed_pipeline(0 TO ITERATIONS - 1) := atan_gen(width, iterations);


    --## Compute gain from CORDIC pseudo-rotations
    function cordic_gain(iterations : positive)
        return real is
        variable g : real := 1.0;
    begin
        for i in 0 to iterations-1 loop
            g := g * sqrt(1.0 + 2.0**(-2*i));
        end loop;
        return g;
    end function;
    
    CONSTANT LUT_depth_c : INTEGER := width;
    CONSTANT LUT_width_c : INTEGER := width;
    TYPE LUT_t IS ARRAY (0 TO LUT_depth_c - 1) OF signed(LUT_width_c - 1 DOWNTO 0);

    -- ATAN Generator
    FUNCTION atan_gen
        return LUT_t is
        variable lut : LUT_t;
    BEGIN
        -- Cordic lookup table [ATAN_TABLE(i)]
    
        --FOR i IN LUT_width_c-1 DOWNTO 0 LOOP
        FOR i IN 0 TO LUT_width_c-1 LOOP
            lut(i) := to_signed(integer(round(ARCTAN(2.0**(-i))*2.0**(LUT_width_c-2))), LUT_width_c);
        END LOOP;
        RETURN lut;
    END FUNCTION atan_gen;

  procedure adjust_angle(x, y, z : in signed; signal xa, ya, za : out signed) is
    variable quad : unsigned(1 downto 0);  
    variable zp : signed(z'length-1 downto 0) := z;
    variable yp : signed(y'length-1 downto 0) := y;
    variable xp : signed(x'length-1 downto 0) := x;
  begin

    -- 0-based quadrant number of angle
    quad := unsigned(zp(zp'high downto zp'high-1));

    if quad = 1 or quad = 2 then -- Rotate into quadrant 0 and 3 (right half of plane)
      xp := -xp;
      yp := -yp;
      -- Add 180 degrees (flip the sign bit)
      zp := (not zp(zp'left)) & zp(zp'left-1 downto 0);
    end if;

    xa <= xp;
    ya <= yp;
    za <= zp;
  end procedure;

    signal x_start, y_start, z_start : signed(angle_in'range);

BEGIN
    x_array <= x_start & x_pl;
	y_array <= y_start & y_pl;
	z_array <= z_start & z_pl;
	
    adj: PROCESS (clk, rst) IS
        constant Y : signed(angle_in'range) := (others => '0');
        constant X : signed(angle_in'range) := to_signed(integer(1.0/cordic_gain(ITERATIONS)* 2.0 ** (width-2)), angle_in'length);
    begin

        IF (rst = '1') THEN
            x_start <= (others => '0');
            y_start <= (others => '0');
            z_start <= (others => '0');
        ELSIF rising_edge(clk) THEN
            adjust_angle(X, Y, angle_in, x_start, y_start, Z_start);
        end if;
    end process;

	cordic : PROCESS (clk, rst) IS
	BEGIN
		IF (rst = '1') THEN
			x_pl <= (OTHERS => (OTHERS => '0'));
			y_pl <= (OTHERS => (OTHERS => '0'));
			z_pl <= (OTHERS => (OTHERS => '0'));

		ELSIF rising_edge(clk) THEN
			FOR i IN 1 TO ITERATIONS LOOP

				--if z_array(i-1)(z'high) = '1' then -- z is negative
				IF (z_array(i - 1)(z_start'high) = '1') THEN
					--x_pl(i) <= x_array(i-1) + (y_array(i-1) / 2**(i-1));
					--y_pl(i) <= y_array(i-1) - (x_array(i-1) / 2**(i-1));
					x_pl(i) <= x_array(i - 1) + shift_right(y_array(i - 1), i - 1);
					y_pl(i) <= y_array(i - 1) - shift_right(x_array(i - 1), i - 1);--
					z_pl(i) <= z_array(i - 1) + ATAN_TABLE(i - 1);
				ELSE -- z or y is positive
					x_pl(i) <= x_array(i - 1) - shift_right(y_array(i - 1), i - 1);
					y_pl(i) <= y_array(i - 1) + shift_right(x_array(i - 1), i - 1);
					z_pl(i) <= z_array(i - 1) - ATAN_TABLE(i - 1);
				END IF;
			END LOOP;
		END IF;
	END PROCESS;

	sine_out <= y_array(y_array'high);

end architecture;
 