module SnoopDog();

//chaves 17 16 15 selecionam o processador
//HEX 0 1 2 indicam o estado da maquina ed estados de cada 1
//chave 0 é o clock
//chave 1 seleciona se é read ou write
//chaves 2-4 selecionam o endereco
//chaves 5-7 valor a gravar

endmodule

module MESI(clock,op_in,miss_in,inv_in,state,new_state,
	        read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,invalidade_out,write_back_out,abort_out);

input clock;
input  op_in,miss_in,inv_in,state;

output reg read_hit_out,read_miss_out,write_hit_out,write_miss_out,invalidate_out,invalidade_out,write_back_out,abort_out,new_state;

wire read_hit,write_hit,read_miss,write_miss

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
	invalidade_out=0;
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
				new_state=1;
				read_miss_out=1;	
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

module cache();
	reg[] tag   [3:0];
	reg[] state [3:0];
	reg[] data  [3:0];
endmodule


module processor();

	always @(*)
	begin
		if(instr==0)//read
		begin
			
		end
		else        //write
		begin
		
		end
	end

endmodule 