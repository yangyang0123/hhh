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

architecture Behavioral of traffic_light_dual_road is
    type state_type is (MAIN_GREEN, MAIN_YELLOW, SIDE_GREEN, SIDE_YELLOW);
    signal state, next_state : state_type := MAIN_GREEN;
    
    -- 时间常数配置
    constant MAIN_GREEN_TIME  : integer := 60;  
    constant SIDE_GREEN_TIME  : integer := 45;  
    constant YELLOW_TIME      : integer := 5;   
    
    -- 控制信号
    signal cycle_counter  : integer range 0 to 1 := 0;  
    signal auto_reset     : STD_LOGIC := '0';
    signal load_pulse     : STD_LOGIC := '0';
    signal global_var : STD_LOGIC_VECTOR(1 downto 0) := "00";
-- 定义一个两位的信号，并初始化为 "00"

-- 自动循环控制逻辑
process(clk)
begin
    if rising_edge(clk) then
        if state = SIDE_YELLOW and next_state = MAIN_GREEN then
            global_var <= std_logic_vector(unsigned(global_var) + 1);
        end if;
        -- 检测完整循环（4次状态切换）
        if global_var = "11" then
            auto_reset <= '1';
            global_var <= "00";
        else
            auto_reset <= '0';
        end if;
    end if;
end process;


-- 状态寄存器与自动重置
process(clk, auto_reset)
begin
    if auto_reset = '1' then
        state <= MAIN_GREEN;
        main_preset_high <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME/10,4));
        main_preset_low <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME mod 10,4));
        -- 重置其他必要信号
    elsif rising_edge(clk) then
        state <= next_state;
    end if;
end process;

-- 状态转换逻辑
process(state, main_preset_high, main_preset_low, side_preset_high, side_preset_low)
begin
    next_state <= state;
    case state is
        when MAIN_GREEN =>
            if unsigned(main_preset_high) = 0 and unsigned(main_preset_low) = 0 then
                next_state <= MAIN_YELLOW ;
					 global_var <= std_logic_vector(unsigned(global_var) + 1);
            end if;
        when MAIN_YELLOW =>
            if unsigned(main_preset_high) = 0 and unsigned(main_preset_low) = 0 then
                next_state <= SIDE_GREEN ;
					 global_var <= std_logic_vector(unsigned(global_var) + 1);
            end if;
        when SIDE_GREEN =>
            if unsigned(side_preset_high) = 0 and unsigned(side_preset_low) = 0 then
                next_state <= SIDE_YELLOW ;
					 global_var <= std_logic_vector(unsigned(global_var) + 1);
            end if;
        when SIDE_YELLOW =>
            if unsigned(side_preset_high) = 0 and unsigned(side_preset_low) = 0 then
                next_state <= MAIN_GREEN ;
					 global_var <= std_logic_vector(unsigned(global_var) + 1);
            end if;
    end case;
end process;

-- 倒计时预设值控制
process(state)
begin
    main_preset_high <= (others => '0');
    main_preset_low  <= (others => '0');
    side_preset_high <= (others => '0');
    side_preset_low  <= (others => '0');
    load_pulse <= '0';

    case state is
        when MAIN_GREEN =>
            main_preset_high <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME/10, 4));
            main_preset_low  <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME mod 10, 4));
				-- 支干道红灯时间 = 主干道绿灯 + 黄灯
            side_preset_high <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME+YELLOW_TIME)/10,4));
            side_preset_low <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME+YELLOW_TIME) mod 10,4));
            load_pulse <= '1';
        when MAIN_YELLOW =>
            main_preset_high <= std_logic_vector(to_unsigned(YELLOW_TIME/10, 4));
            main_preset_low  <= std_logic_vector(to_unsigned(YELLOW_TIME mod 10, 4));
            load_pulse <= '1';
        when SIDE_GREEN =>
            side_preset_high <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME/10, 4));
            side_preset_low  <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME mod 10, 4));
				main_preset_high <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME+YELLOW_TIME/10, 4));
            main_preset_low  <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME+YELLOW_TIME mod 10, 4));
            load_pulse <= '1';
        when SIDE_YELLOW =>
            side_preset_high <= std_logic_vector(to_unsigned(YELLOW_TIME/10, 4));
            side_preset_low  <= std_logic_vector(to_unsigned(YELLOW_TIME mod 10, 4));
            load_pulse <= '1';
    end case;
end process;

-- 加载信号生成（单周期脉冲）
process(clk)
begin
    if rising_edge(clk) then
        load_pulse <= '0';
        if state /= previous_state then
            load_pulse <= '1';
            previous_state <= state;
        end if;
    end if;
end process;

process(clk)

-- 车辆信号控制
process(state)
begin
    main_red <= '0'; main_yellow <= '0'; main_green <= '0';
    side_red <= '0'; side_yellow <= '0'; side_green <= '0';
    case state is
        when MAIN_GREEN =>
            main_green <= '1';
            side_red <= '1';
        when MAIN_YELLOW =>
            main_yellow <= '1';
            side_red <= '1';
        when SIDE_GREEN =>
            side_green <= '1';
            main_red <= '1';
        when SIDE_YELLOW =>
            side_yellow <= '1';
            main_red <= '1';
    end case;
end process;

-- 行人信号控制
process(state)
begin
    ped_main_green <= '0';  -- 默认红灯
    ped_side_green <= '0';
    case state is
        when MAIN_GREEN =>
            ped_side_green <= '1';
        when SIDE_GREEN =>
            ped_main_green <= '1';
        when others =>  -- 黄灯期间保持红灯
            null;
    end case;
end process;
-- 进位信号生成
down <= '1' when (unsigned(main_preset_low) = 0) else '0';

end Behavioral;