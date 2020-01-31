--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Implementa��o em hardware sintetiz�vel de uma organiza��o monociclo
--	do processador MIPS. Apenas 9 das instru��es do MIPS s�o aceitas
--	por esta organiza��o:
--	ADDU, SUBU, AAND, OOR, XXOR, NNOR, LW, SW e ORI	
--
--	Vers�o 	Inicial 	- Moraes 20/setembro/2006
--			Revis�o 	- Ney 07/maio/2008
--			Revis�o 	- Ney 09/maio/2008 - removido bug do ORI
--				ORI opera agora com extens�o de 0 e n�o extens�o de sinal
--			Revisado 	- Ney 24/outubro/2008 - Altera��o para eliminar
-- 						o registrador IR e tornar a MIPS_V0 realmente
--						monociclo.
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- IMPLEMENTAR O MULTIPLEXADOR NA ENTRADA NA SAIDA DA ULA PARA APONTAR
-- ENDERE�O NA MEM�RIA (POP), ANTES DE DECREMENTAR O VALOR DE $rs

-- IMPLEMENTAR DUPLA ENTRADA NO BANCO DE REGISTRADORES PARA INSTRU��O POP

-- PERGUNTAR SE EST� CERTO wregA EM CONTROL_UNIT (SP -> LW)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- package com tipos b�sicos
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;

package p_MI0 is  
  
  subtype reg32 is std_logic_vector(31 downto 0);  
  -- tipo para os barramentos de 32 bits
  
  --enum com os tipos de instrucao
  type inst_type is (ADDU, SUBU, AAND, OOR, XXOR, NNOR, LW, LRW, PUSH, POP, SW, 
  	ORI, invalid_instruction);

  type microinstruction is record
    ce:    std_logic;       -- ce e rw s�o os controles da mem�ria
    rw:    std_logic;
    i:     inst_type;        
    wregA: std_logic;		-- wregA diz se o banco de registradores deve ou n�o ser escrito
	wregB: std_logic;		-- wregB diz se o banco de registradores deve escrever o valor da ALU (POP)

  end record;
    
end p_MI0;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Registrador gen�rico sens�vel � borda de subida do clock
-- com possibilidade de inicializa��o de valor
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MI0.all;

entity reg32_ce is
           generic( INIT_VALUE : reg32 := (others=>'0') );
           port(  ck, rst, ce : in std_logic;
                  D : in  reg32;
                  Q : out reg32
               );
end reg32_ce;

architecture reg32_ce of reg32_ce is 
begin

  process(ck, rst)
  begin
       if rst = '1' then
              Q <= INIT_VALUE(31 downto 0);
       elsif ck'event and ck = '1' then
           if ce = '1' then
              Q <= D; 
           end if;
       end if;
  end process;
        
end reg32_ce;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Banco de registradores - 31 registradores de uso geral - reg(0): cte 0
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;   
use work.p_MI0.all;

entity reg_bank is
       port( ck, rst, wregA, wregB :    in std_logic;
             AdRs, AdRt, adRD, adRD_2 : in std_logic_vector( 4 downto 0);
             RD, RD_2 : in reg32;
             R1, R2: out reg32 
           );
end reg_bank;

architecture reg_bank of reg_bank is
   type bank is array(0 to 31) of reg32;
   signal reg : bank ;                            
   signal wen, RF : reg32 ;
begin            

    g1: for i in 0 to 31 generate        

        wen(i) <= '1' when i/=0 and ((adRD=i and wregA='1') or (adRD_2=i and wregB='1')) else '0';
			
		RF <= RD_2 when(adRD_2=i and wregB='1') else RD;

		rx: entity work.reg32_ce port map
			(ck=>ck, rst=>rst, ce=>wen(i), D=>RF, Q=>reg(i));
				
    end generate g1;      

    R1 <= reg(CONV_INTEGER(AdRs));    -- sele��o do fonte 1  

    R2 <= reg(CONV_INTEGER(AdRt));    -- sele��o do fonte 2 
   
end reg_bank;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ALU - a opera��o depende somente da instru��o corrente que �
-- 	decodificada na Unidade de Controle
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.p_MI0.all;

entity alu is
       port( op1, op2 : in  reg32;
	   		 outalu :   out reg32; 
	   		 zero	:	out std_logic;
             op_alu :   in  inst_type   
           );
end alu;

architecture alu of alu is 
signal int_alu	: reg32;
begin
    outalu <= int_alu;
    int_alu <=  
        op1 - op2      when  op_alu=SUBU or op_alu=PUSH	else
        op1 and op2    when  op_alu=AAND				else 
        op1 or  op2    when  op_alu=OOR  or op_alu=ORI	else 
        op1 xor op2    when  op_alu=XXOR              	else 
        op1 nor op2    when  op_alu=NNOR             	else 
        op1 + op2;      --- default � a soma
	zero <= '1' when int_alu=x"00000000" else '0';
end alu;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Descri��o do Bloco de Dados (Datapath)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Std_Logic_signed.all; 
use work.p_MI0.all;
   
entity datapath is
      port(  ck, rst :     in    std_logic;
             i_address :   out   reg32;
             instruction : in    reg32;
             d_address :   out   reg32;
             data :        inout reg32;  
             uins :        in    microinstruction;
             IR_OUT :      out   reg32
          );
end datapath;

architecture datapath of datapath is
   signal incpc, ent_pc, pc_mais_offset, pc, result, R1, R2, ext32, op2, reg_destA, reg_destB : reg32;
   signal adD, adD_2   : std_logic_vector(4 downto 0) ;       
   signal tipoR, tipoI, zero : std_logic ;       
begin           
        
   tipoR <= '1' when uins.i=ADDU or uins.i=SUBU or 
		uins.i=AAND or uins.i=OOR or uins.i=XXOR or uins.i=NNOR or
		 uins.i=LRW or uins.i=PUSH or uins.i=POP else '0';
   
   tipoI <= '1' when uins.i=LW or uins.i=ORI or uins.i=SW else '0';	

   --======  Hardware para a busca de instru��es  =============================================
 
   incpc <= pc + 4;	--Avanca para a proxima instrucao
   
   rpc: entity work.reg32_ce 
	   generic map(INIT_VALUE=>x"00400000")	-- ATEN��O a este VALOR!! 
	   										-- Ele depende do simulador!!
	   										-- Para o SPIM --> 	use x"00400020"
											-- Para o MARS -->	use x"00400000"
              port map(ck=>ck, rst=>rst, ce=>'1', 
			  D=>incpc, Q=>pc);
           
   IR_OUT <= instruction ;	
   -- IR_OUT � o sinal de sa�da do Bloco de Dados, que cont�m
   -- o c�digo da instru��o em execu��o no momento. � passado
   -- ao Bloco de Controle             
   i_address <= pc;
   
   --======== hardware do banco de registradores e extens�o de sinal ou de 0 ================

   adD <= instruction(15 downto 11) when tipoR='1' and not (uins.i=PUSH or uins.i=POP) else
          instruction(20 downto 16) ;

	 -- TOMAR CUIDADO COM others=>'Z' OU colocar '0'
	 -- Se for zero n�o escreve no banco de registradores
   adD_2 <= instruction(15 downto 11) when uins.i=POP else (others=>'Z');
   
   REGS: entity work.reg_bank port map
	   (ck=>ck, rst=>rst, wregA=>uins.wregA, wregB=>uins.wregB, AdRs=>instruction(25 downto 21),
	   		AdRt=>instruction(20 downto 16), adRD=>adD, adRD_2=>adD_2, RD=>reg_destA, RD_2=>reg_destB, R1=>R1, R2=>R2);
    
   -- Extens�o de 0 ou extens�o de sinal
   ext32 <=	x"FFFF" & instruction(15 downto 0) when (instruction(15)='1' 
   and (uins.i=LW or uins.i=SW)) else
	   	-- LW and SW use signal extension, ORI uses 0-extension
			x"0000" & instruction(15 downto 0);
	   	-- other instructions do not use this information,
			-- thus anything is good 0 or sign extension
    
   --=========  hardware da ALU e em volta dela ==========================================
   
			--	 TOMAR CUIDADO POR CAUSA DA COMPARA��O
			--	(SUPOSI��O -> AVALIA SE A INSTRU��O � DO TIPO PUSH OU POP ANTES DE tipoR)
   op2 <= x"00000004" when uins.i=PUSH or uins.i=POP else
					R2 when tipoR='1' and not (uins.i=PUSH or uins.i=POP) else ext32; 
                 
   inst_alu: entity work.alu port map (op1=>R1, op2=>op2,
	   outalu=>result, zero=>zero, op_alu=>uins.i);
                                               
   -- operacao com a mem�ria de dados
     
   d_address <= R1 when uins.i=POP else result;
       
   data <= R2 when uins.ce='1' and uins.rw='0' else (others=>'Z');  
 
   reg_destA <=  data when uins.i=LW or uins.i=LRW or uins.i=POP else result;

   reg_destB <= result;

end datapath;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  Unidade de Controle - decodifica a instru��o e gera os sinais de controle
--		nesta implementa��o � um bloco puramente combinacional
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use work.p_MI0.all;

entity control_unit is
	port(ck, rst: in std_logic; 	-- estes sinais s�o in�teis nesta vers�o da
									-- Unidade de Controle, pois ela � combinacional
         uins :   out microinstruction;
         ir :     in reg32
        );
end control_unit;
                   
architecture control_unit of control_unit is
  signal i : inst_type;
begin
    
    uins.i <= i;
    
    i <= ADDU   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100001" else
         SUBU   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100011" else
         AAND   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100100" else
         OOR    when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100101" else
         XXOR   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100110" else
         NNOR   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000100111" else
         LRW    when ir(31 downto 26)="000000" and ir(10 downto 0)="00000101000" else
         PUSH   when ir(31 downto 26)="000000" and ir(10 downto 0)="00000101001" else
         POP    when ir(31 downto 26)="000000" and ir(10 downto 0)="00000101010" else
         ORI    when ir(31 downto 26)="001101" else
         LW     when ir(31 downto 26)="100011" else
         SW     when ir(31 downto 26)="101011" else
         invalid_instruction ; -- IMPORTANTE: condi��o "default" � invalid instruction;
        
    assert i /= invalid_instruction
          report "******************* INVALID INSTRUCTION *************"
          severity error;
                   
    uins.ce    <= '1' when i=SW or i=LW or i=LRW or i=PUSH or i=POP else '0';
    
    uins.rw    <= '0' when i=SW or i=PUSH else '1';

    uins.wregA  <= '0' when i=SW else '1';
		
    uins.wregB <= '1' when i=POP else '0';
    
end control_unit;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Topo da Hierarquia do Processador - instancia��o dos Blocos de 
-- 		Dados e de Controle
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;
use work.p_MI0.all;

entity MRstd is
    port( clock, reset:         in    std_logic;
          ce, rw, bw:           out   std_logic;
          i_address, d_address: out   reg32;
          instruction:          in    reg32;
          data:                 inout reg32);
end MRstd;

architecture MRstd of MRstd is
      signal IR: reg32;
      signal uins: microinstruction;
 begin

     dp: entity work.datapath   
         port map( ck=>clock, rst=>reset, IR_OUT=>IR, uins=>uins, i_address=>i_address, 
                   instruction=>instruction, d_address=>d_address,  data=>data);

     ct: entity work.control_unit port map( ck=>clock, rst=>reset, IR=>IR, uins=>uins);
         
     ce <= uins.ce;
     rw <= uins.rw;
         
     bw <= '1';	-- Esta vers�o trabalha apenas em modo word (32 bits).
	 			-- Logo, este sinal � in�til aqui
     
end MRstd;
