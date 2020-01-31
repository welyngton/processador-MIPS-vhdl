--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Implementa��o de um sistema completo usando o processador MIPS.
--		Este arquivo cont�m descri��es de:
--			- um pacote de defini��es relacionadas a mem�rias 
--				de instru��es e de dados (package aux_functions)
--			- uma implementa��o de uma RAM com acesso ass�ncrono
--				(par E/A RAM_mem)
--			- um testbench que instancia a mem�ria de dados, a
--				mem�ria de instru��es a CPU do MIPS e carrega
--				as mem�rias com instru��es e dados de um arquivo
--				externo
--		Note-se que:
--			- o processador � mantido em estado de reset at�
--		que as mem�rias de instru��es e de dados tenham sido
--		preenchidas
--			- Assume-se uma organiza��o do tipo HARVARD, com mem�rias
--				de instru��es e de dados distintas e independentes
--
--	Vers�o 	Inicial 	- Moraes 13/outubro/2004
--			Revisado 	- Ney 24/outubro/2008 - Altera��o para eliminar
-- 						o registrador IR e tornar a MIPS_V0 realmente
--						monociclo.
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library IEEE;
use IEEE.Std_Logic_1164.all;

package aux_functions is  

   subtype reg32  is std_logic_vector(31 downto 0);
   subtype reg16  is std_logic_vector(15 downto 0);
   subtype reg8   is std_logic_vector( 7 downto 0);
   subtype reg4   is std_logic_vector( 3 downto 0);

   -- defini��o do tipo 'memory', que ser� utilizado para as mem�rias de dados/instru��es
   constant MEMORY_SIZE : integer := 2048;     
   type memory is array (0 to MEMORY_SIZE) of reg8;

   constant TAM_LINHA : integer := 200;
   
   function CONV_VECTOR( letra : string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector;
   
end aux_functions;

package body aux_functions is

  --
  -- converte um caracter de uma dada linha em um std_logic_vector
  --
  function CONV_VECTOR( letra:string(1 to TAM_LINHA);  pos: integer ) return std_logic_vector is         
     variable bin: reg4;
   begin
      case (letra(pos)) is  
              when '0' => bin := "0000";
              when '1' => bin := "0001";
              when '2' => bin := "0010";
              when '3' => bin := "0011";
              when '4' => bin := "0100";
              when '5' => bin := "0101";
              when '6' => bin := "0110";
              when '7' => bin := "0111";
              when '8' => bin := "1000";
              when '9' => bin := "1001";
              when 'A' | 'a' => bin := "1010";
              when 'B' | 'b' => bin := "1011";
              when 'C' | 'c' => bin := "1100";
              when 'D' | 'd' => bin := "1101";
              when 'E' | 'e' => bin := "1110";
              when 'F' | 'f' => bin := "1111";
              when others =>  bin := "0000";  
      end case;
     return bin;
  end CONV_VECTOR;

end aux_functions;     

--------------------------------------------------------------------------
-- M�dulo que implementa um modelo comportamental de uma RAM Ass�ncrona
--------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use work.aux_functions.all;

entity RAM_mem is
      generic(  START_ADDRESS: reg32 := (others=>'0')  );
      port( ce_n, we_n, oe_n, bw: in std_logic;
	  address: in reg32;   data: inout reg32);
end RAM_mem;

architecture RAM_mem of RAM_mem is 
   signal RAM : memory;
   signal tmp_address: reg32;
   alias  low_address: reg16 is tmp_address(15 downto 0);
   	--  baixa para 16 bits devido ao CONV_INTEGER --
begin     

   tmp_address <= (address - START_ADDRESS) after 0.01 ns;   
   	--  offset do endere�amento  -- 
   
   -- escreve sincronamente na mem�ria  -- LITTLE ENDIAN -------------------
   process(ce_n, we_n, low_address)
   begin
	   if ce_n='0' and we_n='0' then
		   if CONV_INTEGER(low_address)>=0
			   and CONV_INTEGER(low_address+3)<=MEMORY_SIZE then
			   if bw='1' then
				RAM(CONV_INTEGER(low_address+3)) <= data(31 downto 24);
				RAM(CONV_INTEGER(low_address+2)) <= data(23 downto 16);
				RAM(CONV_INTEGER(low_address+1)) <= data(15 downto  8);
         	   end if;
           	RAM(CONV_INTEGER(low_address)) <= data( 7 downto  0); 
       	   end if;
        end if;
    end process;   
    
   -- l� da mem�ria
   process(ce_n, oe_n, low_address)
     begin
       if ce_n='0' and oe_n='0' and
          CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address+3)<=MEMORY_SIZE then
            data(31 downto 24) <= RAM(CONV_INTEGER(low_address+3));
            data(23 downto 16) <= RAM(CONV_INTEGER(low_address+2));
            data(15 downto  8) <= RAM(CONV_INTEGER(low_address+1));
            data( 7 downto  0) <= RAM(CONV_INTEGER(low_address  ));
        else
            data(31 downto 24) <= (others=>'Z');
            data(23 downto 16) <= (others=>'Z');
            data(15 downto  8) <= (others=>'Z');
            data( 7 downto  0) <= (others=>'Z');
        end if;
   end process;   

end RAM_mem;

-------------------------------------------------------------------------
--  TESTBENCH de SIMULA��O do MIPS  
-------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          
use STD.TEXTIO.all;
use work.aux_functions.all;

entity MRstd_tb is
end MRstd_tb;

architecture cpu_tb of MRstd_tb is
    
    signal Dadress, Ddata, Iadress, Idata,
           i_cpu_address, d_cpu_address, data_cpu, tb_add, tb_data : reg32 := (others => '0' );
    
    signal Dce_n, Dwe_n, Doe_n, Ice_n, Iwe_n, Ioe_n, ck, rst, rstCPU, 
           go_i, go_d, ce, rw, bw: std_logic;
    
    file ARQ : TEXT open READ_MODE is "prog_from_hell.txt";
 
begin
           
    Data_mem:  entity work.RAM_mem 
               generic map( START_ADDRESS => x"10010000" )
               port map (ce_n=>Dce_n, we_n=>Dwe_n, 
			   oe_n=>Doe_n, bw=>bw, address=>Dadress,
			   data=>Ddata);
                                            
    Instr_mem: entity work.RAM_mem 
               generic map( START_ADDRESS => x"00400000" )	-- ATEN��O a este VALOR!! 
	   										-- Ele depende do simulador!!
	   										-- Para o SPIM --> 	use x"00400020"
											-- Para o MARS -->	use x"00400000"
               port map (ce_n=>Ice_n, we_n=>Iwe_n, 
			   oe_n=>Ioe_n, bw=>'1', address=>Iadress,
			   data=>Idata);
        
    -- sinais para a mem�ria de dados --------------------------------------------------------
    Dce_n <= '0' when  ce='1' or go_d='1'             else '1';
    Doe_n <= '0' when (ce='1' and rw='1')             else '1';       
    Dwe_n <= '0' when (ce='1' and rw='0') or go_d='1' else '1';    

    Dadress <= tb_add  when rstCPU='1' else d_cpu_address;
    Ddata   <= tb_data when rstCPU='1' else data_cpu when (ce='1' and rw='0') else (others=>'Z'); 
    
    data_cpu <= Ddata when (ce='1' and rw='1') else (others=>'Z');
    
    -- sinais para a mem�ria de instru��es --------------------------------------------------------
    Ice_n <= '0';                                 
    Ioe_n <= '1' when rstCPU='1' else '0';           -- impede leitura enquanto est� escrevendo                             
    Iwe_n <= '0' when go_i='1'   else '1';           -- escrita durante a leitura do arquivo 
    
    Iadress <= tb_add  when rstCPU='1' else i_cpu_address;
    Idata   <= tb_data when rstCPU='1' else (others => 'Z'); 
  

    cpu: entity work.MRstd  port map(
              clock=>ck, reset=>rstCPU,
              i_address => i_cpu_address,
              instruction => Idata,
              ce=>ce,  rw=>rw,  bw=>bw,
              d_address => d_cpu_address,
              data => data_cpu
        ); 

    rst <='1', '0' after 25 ns;       -- gera o sinal de reset

    process                          -- gera o clock
        begin
        ck <= '0', '1' after 10 ns;
        wait for 20 ns;
    end process;
    
    -----------------------------------------------------------------------------
    -- Este processo carrega a mem�ria de instru��es e a de dados durante o reset
    --		Trata-se de um parser que l� c�digo gerado por um simulador (SPIM/MARS)
	--		com formato mais ou menos livre, tentando encontrar n�meros que
	--		representem endere�os e c�digos, que devem ter a forma de "0x" seguido
	--		de exatamente 8 d�gitos hexadecimais. Em cada linha, assume-se que
	--		o primeiro n�mero � o endere�o inicial da linha, enquanto os n�meros
	--		seguintes s�o os conte�dos a partir daquele endere�o (sejam instru��es
	--		ou dados). Por exemplo, o SPIM gera:
    --
    --      .CODE
    --      [0x00400020] 0x3c011001  lui $1, 4097 [d2]   ; 16: la    $t0, d2
    --      [0x00400024] 0x34280004  ori $8, $1, 4 [d2]
    --      [0x00400028] 0x8d080000  lw $8, 0($8)        ; 17: lw    $t0,0($t0)
    --      .....
    --      [0x00400048] 0x0810000f  j 0x0040003c [loop] ; 30: j     loop
    --      [0x0040004c] 0x01284821  addu $9, $9, $8     ; 32: addu $t1, $t1, $t0
    --      [0x00400050] 0x08100014  j 0x00400050 [x]    ; 34: j     x
    --      .DATA
    --      [0x10010000]     0x0000faaa  0x00000083  0x00000000  0x00000000
    --		   
    ----------------------------------------------------------------------------
    process
        variable ARQ_LINE : LINE;
        variable line_arq : string(1 to 200);
        variable code     : boolean;
        variable i, address_flag : integer;
    begin  
        go_i <= '0';
        go_d <= '0';
        rstCPU <= '1';	-- segura o processador em reset 
			-- durante a leitura do arquivo
        code:=true;     -- valor "default" de code � 1 (c�digo, e n�o dados)
                                 
        wait until rst = '1';
        
        while NOT (endfile(ARQ)) loop    
		-- IN�CIO DA LEITURA DO ARQUIVO CONTENDO INSTRU��O E DADOS -----
            readline(ARQ, ARQ_LINE);      
            read(ARQ_LINE, line_arq(1 to  ARQ_LINE'length) );
                        
            if line_arq(1 to 5)=".CODE" then 
                   code:=true;                     -- c�digo
            elsif line_arq(1 to 5)=".DATA" then
                   code:=false;                    -- dados 
            else 
               i := 1;	-- LEITORA DE LINHA - analizar o loop 
				   		-- abaixo para compreender 
               address_flag := 0; -- para INSTRU��O � um para (end,inst)
                                  -- para DADO aceita (end, dado 0, dado 1, dado 2 ....)
               loop                                     
                  if line_arq(i) = '0' and line_arq(i+1) = 'x' then      
					-- encontrou indica��o de n�mero hexa: '0x'
                         i := i + 2;
                         if address_flag=0 then
                               for w in 0 to 7 loop
                                   tb_add( (31-w*4) downto (32-(w+1)*4))  <=
								   	CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8; 
                               address_flag := 1;    
							   -- sinaliza que j� leu o conte�do do endere�o;
                         else
                               for w in 0 to 7 loop
                                   tb_data( (31-w*4) downto (32-(w+1)*4))  <=
								   	CONV_VECTOR(line_arq,i+w);
                               end loop;    
                               i := i + 8;
                               
                               wait for 0.1 ns;
                               
                               if code=true then go_i <= '1';    
								   -- o sinal go_i habilita a escrita na mem�ria de instru��es
							   else go_d <= '1';    
								   -- o sinal go_i habilita a escrita na mem�ria de dados
                               end if; 
                               
                               wait for 0.1 ns;
                               
                               tb_add <= tb_add + 4;       
							   -- *great!* consigo ler mais de uma word por linha!
                               go_i <= '0';
                               go_d <= '0'; 
                               
                               address_flag := 2;    
							   -- sinaliza que j� leu o conte�do do endere�o;

                         end if;
                  end if;
                  i := i + 1;
                  
                  -- sai da linha quando chegou no seu final OU j� 
				  -- leu par(endere�o, instru��o) no caso de c�digo
                  exit when i=TAM_LINHA or (code=true and address_flag=2);
               end loop;
            end if;
            
        end loop;                       
		-- FINAL DA LEITURA DO ARQUIVO CONTENDO INSTRU��O E DADOS -----
        
        rstCPU <= '0';   -- libera o processador para executar o programa
        wait for 2 ns;   -- Espera para ativar o sinal de reset da CPU
        wait until rst = '1';  -- para entrar em Hold de novo!
        
    end process;
    
end cpu_tb;
