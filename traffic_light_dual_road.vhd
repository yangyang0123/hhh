library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light_dual_road is
    Port ( 
        clk           : in  STD_LOGIC;  -- 外部555提供的1Hz时钟信号
        flash_trigger : in  STD_LOGIC;  -- 用户按键，触发/停止黄灯闪烁模式

        -- 主干道车辆倒计时接口
        down              : out STD_LOGIC;  
        load              : out STD_LOGIC;  
        main_preset_high   : out STD_LOGIC_VECTOR(3 downto 0);  
        main_preset_low    : out STD_LOGIC_VECTOR(3 downto 0);  
        low_q             : in  STD_LOGIC_VECTOR(3 downto 0);  
        high_q            : in  STD_LOGIC_VECTOR(3 downto 0);  

        -- 支干道车辆倒计时接口
        side_preset_high   : out STD_LOGIC_VECTOR(3 downto 0);  
        side_preset_low    : out STD_LOGIC_VECTOR(3 downto 0);  
        side_low_q         : in  STD_LOGIC_VECTOR(3 downto 0);  
        side_high_q        : in  STD_LOGIC_VECTOR(3 downto 0);  

        -- 主干道人行道倒计时接口
        ped_down           : out STD_LOGIC;  
        ped_load           : out STD_LOGIC;  
        ped_main_preset_high : out STD_LOGIC_VECTOR(3 downto 0);  
        ped_main_preset_low  : out STD_LOGIC_VECTOR(3 downto 0);  
        ped_low_q          : in  STD_LOGIC_VECTOR(3 downto 0);  
        ped_high_q         : in  STD_LOGIC_VECTOR(3 downto 0);  

        -- 支干道人行道倒计时接口
        ped_side_preset_high : out STD_LOGIC_VECTOR(3 downto 0);  
        ped_side_preset_low  : out STD_LOGIC_VECTOR(3 downto 0);  
        ped_side_low_q      : in  STD_LOGIC_VECTOR(3 downto 0);  
        ped_side_high_q     : in  STD_LOGIC_VECTOR(3 downto 0)   
    );
end traffic_light_dual_road;

architecture Behavioral of traffic_light_dual_road is
    type state_type is (MAIN_GREEN, MAIN_YELLOW, SIDE_GREEN, SIDE_YELLOW, EMERGENCY);
    signal state : state_type := MAIN_GREEN;
    signal previous_state : state_type := MAIN_GREEN;  -- 记录前一个状态
    
    constant MAIN_GREEN_TIME : integer := 60;  
    constant SIDE_GREEN_TIME : integer := 45;  
    constant YELLOW_TIME     : integer := 5;   

    signal flash_active : STD_LOGIC := '0';  
    signal auto_rst     : STD_LOGIC := '0';  
    signal carry        : STD_LOGIC := '0';
    signal yellow_light : STD_LOGIC := '1'; -- 控制黄灯闪烁

begin

    -- 自动复位
    process(clk)
    begin
        if rising_edge(clk) then
            if (state = SIDE_YELLOW and side_high_q = "0000" and side_low_q = "0000") then
                auto_rst <= '1';
            else
                auto_rst <= '0';
            end if;
        end if;
    end process;

    -- 状态转换
    process(clk, auto_rst)
    begin
        if auto_rst = '1' then
            state <= MAIN_GREEN;
            flash_active <= '0';
        elsif rising_edge(clk) then
            if flash_trigger = '1' then
                flash_active <= not flash_active;
            end if;

            case state is
                when MAIN_GREEN =>
                    if (high_q = "0000" and low_q = "0000") then
                        previous_state <= state;
                        state <= MAIN_YELLOW;
                    end if;
                when MAIN_YELLOW =>
                    if (high_q = "0000" and low_q = "0000") then
                        previous_state <= state;
                        state <= SIDE_GREEN;
                    end if;
                when SIDE_GREEN =>
                    if (side_high_q = "0000" and side_low_q = "0000") then
                        previous_state <= state;
                        state <= SIDE_YELLOW;
                    end if;
                when SIDE_YELLOW =>
                    if (side_high_q = "0000" and side_low_q = "0000") then
                        previous_state <= state;
                        state <= MAIN_GREEN;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- 进位信号生成
    process(clk)
    begin
        if rising_edge(clk) then
            if low_q = "0000" then  
                carry <= '1';
            else  
                carry <= '0';
            end if;
        end if;
    end process;
    down <= carry;

    -- 车辆倒计时预置
    process(state)
    begin
        case state is
            when MAIN_GREEN =>
                main_preset_high <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME / 10, 4));
                main_preset_low  <= std_logic_vector(to_unsigned(MAIN_GREEN_TIME mod 10, 4));
                side_preset_high <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME + YELLOW_TIME) / 10, 4));
                side_preset_low  <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME + YELLOW_TIME) mod 10, 4));
                load <= '1';
            when MAIN_YELLOW =>
                main_preset_high <= std_logic_vector(to_unsigned(YELLOW_TIME / 10, 4));
                main_preset_low  <= std_logic_vector(to_unsigned(YELLOW_TIME mod 10, 4));
                load <= '1';
            when SIDE_GREEN =>
                side_preset_high <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME / 10, 4));
                side_preset_low  <= std_logic_vector(to_unsigned(SIDE_GREEN_TIME mod 10, 4));
                main_preset_high <= std_logic_vector(to_unsigned((SIDE_GREEN_TIME + YELLOW_TIME) / 10, 4));
                main_preset_low  <= std_logic_vector(to_unsigned((SIDE_GREEN_TIME + YELLOW_TIME) mod 10, 4));
                load <= '1';
            when SIDE_YELLOW =>
                side_preset_high <= std_logic_vector(to_unsigned(YELLOW_TIME / 10, 4));
                side_preset_low  <= std_logic_vector(to_unsigned(YELLOW_TIME mod 10, 4));
                load <= '1';
            when others =>
                load <= '0';
        end case;
    end process;

    -- 人行道倒计时预置
    process(state)
    begin
        case state is
            when MAIN_GREEN =>
                ped_side_preset_high <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME + YELLOW_TIME) / 10, 4));
                ped_side_preset_low  <= std_logic_vector(to_unsigned((MAIN_GREEN_TIME + YELLOW_TIME) mod 10, 4));
                ped_load <= '1';
            when SIDE_GREEN =>
                ped_main_preset_high <= std_logic_vector(to_unsigned((SIDE_GREEN_TIME + YELLOW_TIME) / 10, 4));
                ped_main_preset_low  <= std_logic_vector(to_unsigned((SIDE_GREEN_TIME + YELLOW_TIME) mod 10, 4));
                ped_load <= '1';
            when others =>
                ped_load <= '0';
        end case;
    end process;

    -- 黄灯闪烁逻辑
    process(clk)
    begin
        if rising_edge(clk) then
            if (flash_active = '1' and (state = MAIN_YELLOW or state = SIDE_YELLOW)) then
                yellow_light <= not yellow_light; -- 闪烁
            else
                yellow_light <= '1'; -- 常亮
            end if;
        end if;
    end process;

    ped_down <= '1';

end Behavioral;