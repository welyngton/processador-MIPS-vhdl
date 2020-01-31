# Processador MIPS em VHDL
Código VHDL para processador MIPS que suporta as instruções LRW, PUSH e POP, além das básicas da ULA

## Implementação de Instruções novas no MIPS
### Rafael Rotelok1, Welyngton J. V. Dal Prá¹
### Bacharelado em Ciência da Computação – Universidade Federal do Paraná (UFPR)
Curitiba – PR – Brasil

## Abstract.
This meta-paper describes the modifications in the reduced version of MIPS 32 bits implentation using VHDL to insert the instructions LRW, PUSH and POP.  The source-code alterations will be described, also the corrections to keep the other instructions working.
## Resumo.
Este artigo descreve as alterações na implementação de uma versão reduzida do MIPS 32bits em VHDL para suportar as instruções LRW, PUSH e POP. Serão descritos os códigos inseridos e as modificações realizadas para que não houvesse impacto nas demais instruções.
# 1. Visão geral
	O objetivo deste trabalho é modificar um código reduzido do MIPS, criando novas instruções para este processador, tais como:
	LRW, semelhante a LW (load word) convencional, carrega um dado da memória em um registrador, porém ao invés do deslocamento ser passado de forma imediata na instrução, ele é carregado de outro registrador.
	PUSH, empilha um registrador na memória decrementando 4 posições do ponteiro de pilha.
	POP, desempilha um registrador da memória incrementando 4 posições no ponteiro de pilha.

# 2. Arquivos utilizados para implementação e testes
	Os arquivos que foram utilizados são:
	MAKEFILE: contém instruções para facilitar compilação e o teste.
	prog_from_hell.txt: programa com código de máquina em hexadecimal que utiliza as instruções do MIPS – utilizado na simulação.
	rarot05-wepra05.patch: patch que altera o código-fonte.
	Mrstd.vhd: contém o código de uma versão reduzida do MIPS em VHDL.
	Mrstd_tb.vhd: contém os sinais para teste do código do MIPS, funções para simular uma memória assincrona e instruções para carregar um arquivo texto – com código de máquina - do programa para esta memória.

# 3. Alterações no código
## 3.1. Implementação da instrução LRW
	Formato: lrw $rd, $rs($rt)
	Instrução adicionada no tipo inst_type, que lista todas as operações, foi incluida na habilitação do um marcador tipoR que indica quais os bits que selecionam registradores para uso no datapath. Foi adicionada uma condição para o registrador destino do banco receber os dados da memória nesta instrução e foi habilitada a leitura da memória de dados para a lrw.
## 3.2. Implementação da instrução PUSH
	Geralmente o rs é o sp (stack pointer)
	Formato: push $rt, $rs
	A instrução foi adicionada na lista inst_type e no marcador tipoR. Na ULA a operação de subtração foi selecionada para esta instrução e foi criada uma condição para selecionar entre a entrada B da ULA ou o valor “4” quando a instrução for push ou pop.  Além disso foram habilitadas a memória de dados e a escrita nesta memória para push.
## 3.3. Implementação da instrução POP
	Geralmente o rs é o sp (stack pointer)
	Formato: pop $rt, $rs	

# 4. Simulação
 	Para criar o programa “prog_from_hell.txt” foi utilizado o arquivo “tabela.txt” na tradução do código assembly para o código de máquina (binário).
	Para realizar a simulação do MIPS e rodar o programa “prog_from_hell.txt” é necessário digitar no terminal:
	$ make
	Este comando vai alterar os códigos do MIPS com um patch, depois compilar os códigos VHDL, rodar o programa assembly e criar um arquivo com as ondas e valores de sinais. O arquivo resultado: mrstd.vcd, pode ser analisado no software GTKwave.
# 5. Referências
Patterson, D.A. e Hennessy, J.L. Organização e projeto de computadores - A interface hardware/software, Bibliografia básica da disciplina;
http://www.inf.ufpr.br/todt/ci210/MRstd.vhd, MIPS parcial v0 (Moraes & Calazans), código em VHDL utilizado para a implementação das novas instruções;
http://en.wikipedia.org/wiki/MIPS_architecture, Resumo geral do assunto;
http://www.langens.eu/tim/ea/mips_en.php, Base de referencia com conteúdo diverso sobre arquitetura, implementação e simulação do MIPS completo;
http://logos.cs.uic.edu/366/notes/MIPS%20Quick%20Tutorial.htm, Manual com as instruções MIPS;
http://zetcode.com/tutorials/gtktutorial, Tutorial básico de GTKwave.


