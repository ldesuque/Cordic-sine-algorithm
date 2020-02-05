
----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11/12/2019 09:55:21 AM
-- Design Name:
-- Module Name: FFT - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity FFT is
generic (
    w : natural := 23);
    
Port (
    -- I/O
    value   :in signed(w-1 downto 0);
    iterations   :in signed(w-1 downto 0);
    I_Real_2   :in signed(w-1 downto 0);
    O_Real_0   :out signed(w+2 downto 0);
);
end FFT;



architecture Behavioral of FFT is
    -- Signals
      
    type T_complex is ARRAY(0 to 1) of signed(w+1 downto 0);
    type T_complex_w is ARRAY(0 to 1) of signed(w+2 downto 0);
    type T_but_result is ARRAY(0 to 3) of std_logic_vector(w+2 downto 0);
    --type T_but_result_test is ARRAY(3 downto 0) of std_logic_vector(w+3 downto 0);
    constant cpi4 :signed (w+2 downto 0):= to_signed(integer(round(cos(MATH_PI_OVER_4)*2.0**(w+3-2))), W+3);
    constant Mcpi4 :signed (w+2 downto 0):= to_signed(integer(round(-1.0*cos(MATH_PI_OVER_4)*2.0**(w+3-2))), W+3);
    
    
    constant W_0_2_Real:signed(w+2 downto 0) := to_signed(integer(2.0**(w+1)), w+3);-- 1,00000000...
    constant W_0_2_Imag:signed(w+2 downto 0) := (others=>'0');-- 0,00000000...
    constant W_0_4_Real:signed(w+2 downto 0) := to_signed(integer(2.0**(w+1)), w+3);-- 1,00000000...
    constant W_0_4_Imag:signed(w+2 downto 0) := (others=>'0');-- 0,00000000...
    constant W_1_4_Real:signed(w+2 downto 0) := (others=>'0');-- 0,00000000...
    constant W_1_4_Imag:signed(w+2 downto 0) := to_signed(integer(-1.0*2.0**(w+1)), w+3);-- -1,00000000...
    constant W_0_8_Real:signed(w+2 downto 0) := to_signed(integer(2.0**(w+1)), w+3);-- 1,00000000...
    constant W_0_8_Imag:signed(w+2 downto 0) :=(others=>'0');-- 0,00000000...
    constant W_1_8_Real:signed(w+2 downto 0) := cpi4;
    constant W_1_8_Imag:signed(w+2 downto 0) := Mcpi4;
    constant W_2_8_Real:signed(w+2 downto 0) := (others=>'0');-- 0,00000000...
    constant W_2_8_Imag:signed(w+2 downto 0) := to_signed(integer(-1.0*2.0**(w+1)), w+3);-- -1,00000000...
    constant W_3_8_Real:signed(w+2 downto 0) := Mcpi4;
    constant W_3_8_Imag:signed(w+2 downto 0) := Mcpi4;
  
  FUNCTION sign(
        z : signed)
    return signed is
        variable z_sig : signed;
    BEGIN
        if z(z'left) = '1' then -- Negative
            z_sig := -z;
        else
            z_sig := z;
        end if;
        return z_sig;
  END sign;
  
  FUNCTION round_signed (
        val : real;
        n : integer)
    return signed is
    
    variable x : integer := 1;
    variable y : integer := 0;
    variable a : integer := 1;
    variable z : real;

  BEGIN
    z := ROUND((val)*(2.0**n))/2.0**n;
    
    for k in 0 to n-1 loop
        d = sign(z)
        
    end loop
    
    if input(input'length-output_size-1) = '1' then
      result := input(input'length-1 downto input'length-output_size) + 1;
    else
      result := input(input'length-1 downto input'length-output_size);
    end if;
    --VHDL 2008:
    --result := input(input'length-1 downto input'length-output_size) + 1 when input(input'length-output_size-1)='1' else input(input'length-1 downto input'length-output_size);
    return result;
  end round_signed;
 
    function BUT
       (
        IN_0 :  in T_complex;
         IN_1 :  in T_complex;
         WEIGTH : in T_complex_w
        ) return T_but_result is

        variable tmp : T_but_result;
        variable sm       : signed(2*w+4 downto 0);
        variable sa       : signed(w+3 downto 0);
        variable sar, sbr : signed(w+2 downto 0);
        
    begin


    
--[sign bit|w-1 bits of amplitude]*[sign bit|1 bit of integer part to code 1.0|w-1 bits of fractional part]
  sm  := IN_1(0) * WEIGTH(0);          -- on 2*w+1 bits
  --[sign bit|w+1 bits of mitigated amplitude|w-1 bits of accuracy bits]
  sa  := round_signed(w+4, sm);
  -- since the largest value coded for weight is 1.0, no need for the extra
  -- leftmost bit
  sar := resize(sa, w+3);
  --do the same for  s_in1_i * s_weight_i
  sbr  := resize(round_signed(w+4, IN_1(1) * WEIGTH(1)), w+3);


    tmp(0) := std_logic_vector(resize(IN_0(0), w+3) + sar - sbr);
    tmp(1) := std_logic_vector(resize(IN_0(1), w+3) + (resize(round_signed(w+4, IN_1(0) * WEIGTH(1)), w+3) + resize(round_signed(w+4, IN_1(1) * WEIGTH(0)), w+3)));
    tmp(2) := std_logic_vector(resize(IN_0(0), w+3) - (resize(round_signed(w+4, IN_1(0) * WEIGTH(0)), w+3) - resize(round_signed(w+4, IN_1(1)  * WEIGTH(1)), w+3)));
    tmp(3) := std_logic_vector(resize(IN_0(1), w+3) - (resize(round_signed(w+4, IN_1(0) * WEIGTH(1)), w+3) + resize(round_signed(w+4, IN_1(1)  * WEIGTH(0)), w+3)));

    return tmp;

end BUT;

-- STAGE 1
signal STAGE_1_POS_0_AND_1 : T_but_result;
signal STAGE_1_POS_2_AND_3 : T_but_result;
signal STAGE_1_POS_4_AND_5 : T_but_result;
signal STAGE_1_POS_6_AND_7 : T_but_result;

-- STAGE 
signal STAGE_2_POS_0_AND_2 : T_but_result;
signal STAGE_2_POS_1_AND_3 : T_but_result;
signal STAGE_2_POS_4_AND_6 : T_but_result;
signal STAGE_2_POS_5_AND_7 : T_but_result;

-- STAGE 
signal STAGE_3_POS_0_AND_4 : T_but_result;
signal STAGE_3_POS_1_AND_5 : T_but_result;
signal STAGE_3_POS_2_AND_6 : T_but_result;
signal STAGE_3_POS_3_AND_7 : T_but_result;


--	but(&weights[0], &in[0], &in[4], &stage1[0], &stage1[1]);
--	but(&weights[0], &in[2], &in[6], &stage1[2], &stage1[3]);
--	but(&weights[0], &in[1], &in[5], &stage1[4], &stage1[5]);
--	but(&weights[0], &in[3], &in[7], &stage1[6], &stage1[7]);

--	// Second stage
--	but(&weights[0], &stage1[0], &stage1[2], &stage2[0], &stage2[2]);
--	but(&weights[2], &stage1[1], &stage1[3], &stage2[1], &stage2[3]);
--	but(&weights[0], &stage1[4], &stage1[6], &stage2[4], &stage2[6]);
--	but(&weights[2], &stage1[5], &stage1[7], &stage2[5], &stage2[7]);
                
--	// Etape 3
--	but(&weights[0], &stage2[0], &stage2[4], &out[0], &out[4]);
--	but(&weights[1], &stage2[1], &stage2[5], &out[1], &out[5]);
--	but(&weights[2], &stage2[2], &stage2[6], &out[2], &out[6]);
--	but(&weights[3], &stage2[3], &stage2[7], &out[3], &out[7]);*/

begin
--    --STAGE 1
     STAGE_1_POS_0_AND_1 <= BUT((resize(I_Real_0,w+2),resize(I_Imag_0,w+2)), (resize(I_Real_4,w+2),resize(I_Imag_4,w+2)), (W_0_2_Real,W_0_2_Imag));
     STAGE_1_POS_2_AND_3 <= BUT((resize(I_Real_2,w+2),resize(I_Imag_2,w+2)), (resize(I_Real_6,w+2),resize(I_Imag_6,w+2)), (W_0_2_Real,W_0_2_Imag));
     STAGE_1_POS_4_AND_5 <= BUT((resize(I_Real_1,w+2),resize(I_Imag_1,w+2)), (resize(I_Real_5,w+2),resize(I_Imag_5,w+2)), (W_0_2_Real,W_0_2_Imag));
     STAGE_1_POS_6_AND_7 <= BUT((resize(I_Real_3,w+2),resize(I_Imag_3,w+2)), (resize(I_Real_7,w+2),resize(I_Imag_7,w+2)), (W_0_2_Real,W_0_2_Imag));

--    --STAGE 2
     STAGE_2_POS_0_AND_2 <= BUT((resize(signed(STAGE_1_POS_0_AND_1(0)),w+2), resize(signed(STAGE_1_POS_0_AND_1(1)),w+2)), (resize(signed(STAGE_1_POS_2_AND_3(0)),w+2), resize(signed(STAGE_1_POS_2_AND_3(1)),w+2)),(W_0_4_Real, W_0_4_Imag));
     STAGE_2_POS_1_AND_3 <= BUT((resize(signed(STAGE_1_POS_0_AND_1(2)),w+2), resize(signed(STAGE_1_POS_0_AND_1(3)),w+2)), (resize(signed(STAGE_1_POS_2_AND_3(2)),w+2), resize(signed(STAGE_1_POS_2_AND_3(3)),w+2)),(W_1_4_Real, W_1_4_Imag));
     STAGE_2_POS_4_AND_6 <= BUT((resize(signed(STAGE_1_POS_4_AND_5(0)),w+2), resize(signed(STAGE_1_POS_4_AND_5(1)),w+2)), (resize(signed(STAGE_1_POS_6_AND_7(0)),w+2), resize(signed(STAGE_1_POS_6_AND_7(1)),w+2)),(W_0_4_Real, W_0_4_Imag));
     STAGE_2_POS_5_AND_7 <= BUT((resize(signed(STAGE_1_POS_4_AND_5(2)),w+2), resize(signed(STAGE_1_POS_4_AND_5(3)),w+2)), (resize(signed(STAGE_1_POS_6_AND_7(2)),w+2), resize(signed(STAGE_1_POS_6_AND_7(3)),w+2)),(W_1_4_Real, W_1_4_Imag));

--    --STAGE 3
     STAGE_3_POS_0_AND_4 <= BUT((resize(signed(STAGE_2_POS_0_AND_2(0)),w+2), resize(signed(STAGE_2_POS_0_AND_2(1)),w+2)), (resize(signed(STAGE_2_POS_4_AND_6(0)),w+2), resize(signed(STAGE_2_POS_4_AND_6(1)),w+2)), (W_0_8_Real,W_0_8_Imag));
     STAGE_3_POS_1_AND_5 <= BUT((resize(signed(STAGE_2_POS_1_AND_3(0)),w+2), resize(signed(STAGE_2_POS_1_AND_3(1)),w+2)), (resize(signed(STAGE_2_POS_5_AND_7(0)),w+2), resize(signed(STAGE_2_POS_5_AND_7(1)),w+2)), (W_1_8_Real,W_1_8_Imag));
     STAGE_3_POS_2_AND_6 <= BUT((resize(signed(STAGE_2_POS_0_AND_2(2)),w+2), resize(signed(STAGE_2_POS_0_AND_2(3)),w+2)), (resize(signed(STAGE_2_POS_4_AND_6(2)),w+2), resize(signed(STAGE_2_POS_4_AND_6(3)),w+2)), (W_2_8_Real,W_2_8_Imag));
     STAGE_3_POS_3_AND_7 <= BUT((resize(signed(STAGE_2_POS_1_AND_3(2)),w+2), resize(signed(STAGE_2_POS_1_AND_3(3)),w+2)), (resize(signed(STAGE_2_POS_5_AND_7(2)),w+2), resize(signed(STAGE_2_POS_5_AND_7(3)),w+2)), (W_3_8_Real,W_3_8_Imag));

     O_Real_0  <=SIGNED(STAGE_3_POS_0_AND_4(0));
     O_Imag_0  <=SIGNED(STAGE_3_POS_0_AND_4(1));

     O_Real_1  <=SIGNED(STAGE_3_POS_1_AND_5(0));
     O_Imag_1  <=SIGNED(STAGE_3_POS_1_AND_5(1));

     O_Real_2  <=SIGNED(STAGE_3_POS_2_AND_6(0));
     O_Imag_2  <=SIGNED(STAGE_3_POS_2_AND_6(1));

     O_Real_3  <=SIGNED(STAGE_3_POS_3_AND_7(0));
     O_Imag_3  <=SIGNED(STAGE_3_POS_3_AND_7(1));

     O_Real_4  <=SIGNED(STAGE_3_POS_0_AND_4(2));
     O_Imag_4  <=SIGNED(STAGE_3_POS_0_AND_4(3));

     O_Real_5  <=SIGNED(STAGE_3_POS_1_AND_5(2));
     O_Imag_5  <=SIGNED(STAGE_3_POS_1_AND_5(3));

     O_Real_6  <=SIGNED(STAGE_3_POS_2_AND_6(2));
     O_Imag_6  <=SIGNED(STAGE_3_POS_2_AND_6(3));

     O_Real_7  <=SIGNED(STAGE_3_POS_3_AND_7(2));
     O_Imag_7  <=SIGNED(STAGE_3_POS_3_AND_7(3));


end Behavioral;
