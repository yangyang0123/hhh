library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_74LS192 is
    Port(
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        load     : in  STD_LOGIC;
        data     : in  STD_LOGIC_VECTOR(3 downto 0);
        up_down  : in  STD_LOGIC;
        count    : out STD_LOGIC_VECTOR(3 downto 0)
    );
end counter_74LS192;

architecture blackbox of counter_74LS192 is
begin
    -- 此处不提供内部实现，仅作为黑盒（black box）使用
    count <= (others => '0');
end blackbox;