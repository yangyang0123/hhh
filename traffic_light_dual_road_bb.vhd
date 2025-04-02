library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light_dual_road is
    Port ( 
        clk           : in  STD_LOGIC;   -- 1Hz时钟信号
        -- 车辆信号灯接口
        main_red    : out STD_LOGIC;
        main_yellow : out STD_LOGIC;
        main_green  : out STD_LOGIC;
        side_red    : out STD_LOGIC;
        side_yellow : out STD_LOGIC;
        side_green  : out STD_LOGIC;
        -- 行人信号灯接口
        ped_main_red   : out STD_LOGIC;
        ped_main_green : out STD_LOGIC;
        ped_side_red   : out STD_LOGIC;
        ped_side_green : out STD_LOGIC;
        -- 倒计时控制接口
        down              : out STD_LOGIC;
        load              : out STD_LOGIC;
        main_preset_high  : out STD_LOGIC_VECTOR(3 downto 0);
        main_preset_low   : out STD_LOGIC_VECTOR(3 downto 0);
        side_preset_high  : out STD_LOGIC_VECTOR(3 downto 0);
        side_preset_low   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end traffic_light_dual_road;

-- 添加黑盒属性（部分工具需要此声明）
attribute syn_black_box : boolean;
attribute syn_black_box of traffic_light_dual_road : entity is true;

architecture blackbox of traffic_light_dual_road is
begin
    -- 作为黑盒模块，不提供内部实现
    -- 如需仿真初始值，可以对输出赋予缺省值
    main_red         <= '0';
    main_yellow      <= '0';
    main_green       <= '0';
    side_red         <= '0';
    side_yellow      <= '0';
    side_green       <= '0';
    ped_main_red     <= '0';
    ped_main_green   <= '0';
    ped_side_red     <= '0';
    ped_side_green   <= '0';
    down             <= '0';
    load             <= '0';
    main_preset_high <= (others => '0');
    main_preset_low  <= (others => '0');
    side_preset_high <= (others => '0');
    side_preset_low  <= (others => '0');
end blackbox;