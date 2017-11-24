module SnoopDog(KEY[3:0], SW[17:0], LEDR[17:0]);
input [17:0]SW;
input [3:0]KEY;

output [17:0] LEDR;

//chaves 17 16 15 selecionam o processador
//HEX 0 1 2 indicam o estado da maquina ed estados de cada 1
//chave 0 é o clock
//chave 1 seleciona se é read ou write
//chaves 2-6 selecionam o endereco
//chaves 7-14 valor a gravar

MESI teste  (KEY[0]			//clock
			,SW[2]			//write
			,SW[3]			//miss
			,SW[4]			//invalidate
			,SW[1:0]		//state
			,SW[5] 			//share

			,LEDR[1:0]		//new state
			,LEDR[17]		//read hit
			,LEDR[16]		//read miss
			,LEDR[15]		//write hit
			,LEDR[14]		//write miss
			,LEDR[13]		//invalidate out
			,LEDR[12]		//writeback out
			,LEDR[11]);		//abort acess memory

endmodule

module MESI_OUTPUTLESS(clock,op_in,miss_in,inv_in,state,share,new_state,write_back_out);
		input clock;
		input op_in,miss_in,inv_in,share;
		input[1:0] state;
		wire read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,abort_out;
		output write_back_out;
		output[1:0] new_state;
		MESI machine(clock,op_in,miss_in,inv_in,state,share,new_state,read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,write_back_out,abort_out);	
endmodule

module MESI(clock,op_in,miss_in,inv_in,state,share,
			new_state,read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,write_back_out,abort_out);

input clock;
input op_in,miss_in,inv_in,share; // op_in = write
input[1:0] state;

output reg read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,write_back_out,abort_out;
output reg[1:0] new_state;

wire read_hit,write_hit,read_miss,write_miss;

assign read_hit = ~op_in & ~miss_in;
assign write_hit = op_in & ~miss_in;
assign read_miss = ~op_in & miss_in;
assign write_miss = op_in & miss_in;


always@(posedge clock)
begin
	read_hit_out=0;
	read_miss_out=0;
	write_hit_out=0;
	write_miss_out=0;
	invalidate_out=0;
	write_back_out=0;
	abort_out=0;

	case(state)
		0://invalidade
		begin
			if (op_in) // write
			begin
				new_state=2;
				write_miss_out=1;
			end
			else  // read
			begin
				if (share)
				begin
					new_state=1;
					read_miss_out=1;
				end
				else 
				begin
					new_state=3;
					read_miss_out=1;
				end	
			end
		end


		1://shared
		begin
			if(read_hit) begin 
				read_hit_out=1;
			end
			else if(write_hit) begin 
				write_hit_out=1;
				invalidate_out=1;
				new_state=2;
			end
			else if(read_miss) begin 
				read_miss_out=1;
			end
			else if(write_miss | inv_in) begin 
				write_miss_out=1;
				invalidate_out=1;
				new_state=0;
			end
		end


		2://modified
		begin
			if(read_hit) begin 
				read_hit_out=1;
			end
			else if(write_hit) begin 
				write_hit_out=1;
			end
			else if(read_miss) begin 
				read_miss_out=1;
				abort_out=1;
				write_back_out=1;
				new_state=1;
			end
			else if(write_miss) begin 
				write_miss_out=1;
				abort_out=1;
				write_back_out=1;
				new_state=0;
			end
		end


		3://exclusive
		begin
			if(read_hit) begin 
				read_hit_out=1;
			end
			else if(write_hit) begin 
				write_hit_out=1;
				new_state=2;
			end
			else if(read_miss) begin 
				read_miss_out=1;
				abort_out=1;
				write_back_out=1;
				new_state=1;
			end
			else if(write_miss | inv_in) begin 
				write_miss_out=1;
				abort_out=1;
				write_back_out=1;
				new_state=0;
			end
		end
	endcase
end
endmodule

module readBus();

endmodule 

module memory(clock,instr, bus);
	input clock;
	input[13:0] instr;
	inout[11:0] bus;
	
	wire op;
	wire[4:0] addr;
	wire[7:0] value;
	
	assign op = instr[0];
	assign addr = instr[5:1];
	assign value = instr[13:6];
	
	reg [7:0] mem[0:31];

	always @(posedge clock)
	begin
		if(op)
			mem[addr]=value;
		bus[4:11]=mem[addr];
	end
endmodule

module cache(clock, addr, hit, state_out, data_out);
 	input clock;
 	input[4:0] addr;

	reg[2:0] tag   [0:3];
	reg[1:0] state [0:3];
	reg[7:0] data  [0:3];

	output reg hit;
	output reg[1:0] state_out;
	output reg[7:0] data_out;

	always @(posedge clock)
	begin
		hit=(tag[addr[4:3]]==addr[2:0]);
		if(hit)
		begin
			state_out=state[addr[4:3]];
			data_out=data[addr[4:3]];
		end
	end
endmodule 



module toplovel();

	reg[2:0] selector;
	reg[13:0] instr;
	output out;
	wire bus;

	processor p0(clock,selector[0],instr,out,bus);
	processor p1(clock,selector[1],instr,out,bus);
	processor p2(clock,selector[2],instr,out,bus);
	memory m(clock, instr, bus);
	

endmodule



module processor(clock,snooping,instr,data_out,bus);
	input clock,snooping;
	input[13:0] instr;
	input[11:0] in;
	inout[11:0] bus;
	output reg[7:0] data_out;

	wire op;
	wire[4:0] addr;
	wire[7:0] value;
	wire block_hit;
	wire[1:0] block_state;
	wire[7:0] block_val;
	wire[1:0] new_state,snoop_state;

	wire read_hit,read_miss,write_hit,write_miss,invalidate,write_back,abort,wb_snoop;

	assign op = instr[0];
	assign addr = instr[5:1];
	assign value = instr[13:6];

	cache l1(clock 				// Clock 				Entrada
			,addr				// Endereço 			Entrada

			,block_hit			// Hit 					Saída
			,block_state		// Situação do bloco	Saída
			,block_val);		// Valor encontrado		Saída

	MESI machine(clock 			// Clock 				Entrada
				,op 			// Write 				Entrada
				,~block_hit		// Miss 				Entrada
				, 0 			// Invalidate 			Entrada
				,block_state 	// Situação do bloco 	Entrada
				1,
				
				, new_state		// Nova situação 		Saída
				, read_hit 		// Read hit 			Saída
				,read_miss 		// Read miss 			Saída
				,write_hit 		// Write hit 			Saída
				,write_miss 	// Write miss 			Saída
				,invalidate 	// Invalidate 			Saída
				,write_back 	// Write back 			Saída
				,abort); 		// Aborta memoria 		Saída

	MESI_OUTPUTLESS snoopMachine(clock,op, bus[1],bus[0],block_state,1,snoop_state,wb_snoop);

	always @(posedge clock)
	begin
		bus[0]=invalidate;
		bus[1]=read_miss|write_miss;
		if(~snooping)//esta escrevendo no buss
		begin
			l1.state[addr[4:3]]=new_state;
			if(read_hit)
				data_out=block_val;
			if(write_miss)
			begin
				l1.data[addr[4:3]]=value;
				l1.tag[addr[4:3]]=addr[2:0];
			end
			if(write_hit)
			begin
				//ja escreve no modulo
			end
			if(read_miss)
			begin
				l1.tag[addr[4:3]]=addr[2:0];
				l1.data[addr[4:3]]=bus[4:11];
			end
			if(write_back)
			begin
			 // need to wb
			end
		end
		else // esta lendo do bus
		begin
			if(l1.tag[addr[4:3]]==addr[2:0])
				l1.state[addr[4:3]]=snoop_state;
			if(wb_snoop)
			begin
			 // need to wb
			end
		end
	end
endmodule
