
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;

ENTITY cordic_sin IS
    GENERIC (
        width : INTEGER;
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
    
    SIGNAL X, Y, Z : signed_pipeline(1 TO iterations);
    SIGNAL x_start, y_start, z_start : signed(angle_in'RANGE);
    SIGNAL x_array, y_array, z_array : signed_pipeline(0 TO iterations);
    
    -- Cordic lookup table [ATAN_TABLE(i)]
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
    
    CONSTANT cordic_lut_c : signed_pipeline(0 TO iterations-1) := atan_gen(width, iterations);

    -- Cordic gain
    FUNCTION cordic_gain(iterations : INTEGER)
        RETURN REAL IS
        VARIABLE g : REAL := 1.0;
    BEGIN
        FOR i IN 0 TO iterations-1 LOOP
            g := g * sqrt(1.0 + 2.0**(-2*i));
        END LOOP;
        RETURN g;
    END FUNCTION;
    
    -- Adjust quadrant
    PROCEDURE adjust_angle(
        x, y, z : IN signed;
    SIGNAL xa, ya, za : OUT signed) IS
        VARIABLE quadrant : unsigned(1 DOWNTO 0); 
        VARIABLE zp : signed(z'LENGTH - 1 DOWNTO 0) := z;
        VARIABLE yp : signed(y'LENGTH - 1 DOWNTO 0) := y;
        VARIABLE xp : signed(x'LENGTH - 1 DOWNTO 0) := x;
    BEGIN
        quadrant := unsigned(zp(zp'HIGH DOWNTO zp'HIGH - 1));
        
        IF quadrant = 1 OR quadrant = 2 THEN
            xp := - xp;
            yp := - yp;
            zp := (NOT zp(zp'LEFT)) & zp(zp'LEFT - 1 DOWNTO 0);
        END IF;
        
        xa <= xp;
        ya <= yp;
        za <= zp;
    END PROCEDURE;

BEGIN
    x_array <= x_start & X;
	y_array <= y_start & Y;
	z_array <= z_start & Z;
	
    angle_adjust : PROCESS (clk, rst) IS
        CONSTANT Y : signed(angle_in'RANGE) := (OTHERS => '0');
        CONSTANT X : signed(angle_in'RANGE) := to_signed(INTEGER(1.0/cordic_gain(iterations) * 2.0 ** (width - 2)), angle_in'length);
    BEGIN
        IF (rst = '1') THEN
            x_start <= (OTHERS => '0');
            y_start <= (OTHERS => '0');
            z_start <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            adjust_angle(X, Y, angle_in, x_start, y_start, z_start);
        END IF;
    END PROCESS;
    
    -- Pipelined stages
	pipelined_cordic : PROCESS (clk, rst) IS
	BEGIN
        -- Clear the whole pipeline on reset
		IF (rst = '1') THEN
			X <= (OTHERS => (OTHERS => '0'));
			Y <= (OTHERS => (OTHERS => '0'));
			Z <= (OTHERS => (OTHERS => '0'));
		ELSIF rising_edge(clk) THEN
			FOR i IN 1 TO iterations LOOP
				IF (z_array(i-1)(z_start'high) = '1') THEN
				    -- z < 0
					X(i) <= x_array(i-1) + shift_right(y_array(i-1), i-1);
					Y(i) <= y_array(i-1) - shift_right(x_array(i-1), i-1);
					Z(i) <= z_array(i-1) + cordic_lut_c(i-1);
				ELSE
				    -- z >= 0
					X(i) <= x_array(i-1) - shift_right(y_array(i-1), i-1);
					Y(i) <= y_array(i-1) + shift_right(x_array(i-1), i-1);
					Z(i) <= z_array(i-1) - cordic_lut_c(i-1);
				END IF;
			END LOOP;
		END IF;
	END PROCESS;

	sine_out <= y_array(y_array'high);

END ARCHITECTURE;
 