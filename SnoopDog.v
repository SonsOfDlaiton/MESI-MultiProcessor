module SnoopDog();

//chaves 17 16 15 selecionam o processador
//HEX 0 1 2 indicam o estado da maquina ed estados de cada 1
//chave 0 é o clock
//chave 1 seleciona se é read ou write
//chaves 2-4 selecionam o endereco
//chaves 5-7 valor a gravar

endmodule

module machine(clock,write,read,state, read_miss_in, write_miss_in, invalidate_in, shared);
input clock, write, read, read_miss_in, write_miss_in, shared;
output reg[1:0] state;
output reg read_miss_out, invalidate_out, write_miss_out, writeback, abort_memory;

assign read_hit = ~read_miss_in;
assign write_hit = ~write_miss_in;
assign not_shared= ~shared;


always@(posedge clock)
read_miss_out=0;
invalidate_out=0;
write_miss_out=0; 
writeback=0;
abort_memory=0;
case(state)
	0://invalid
	begin
	 if(read & shared)
	 begin
		state=1;
		read_miss_out=1;
	 end
	 if(read & not_shared)
	 begin
		read_miss_out=1;
		state=3;
	 end
	 if(write)
	 begin
		state=2;
		write_miss_out=1;
	 end
	end
	1://Shared
	begin
	if((write & write_miss_in) | (invalidate_in & !write & !read ))
	 begin
		state=0;
	 end
	 if(write)
	 begin
		invalidate=1;
		state=2;
	 end
	end
	2://Modified
	begin
		if(write_miss_in & write)
		 begin
			writeback=1;
			abort_memory=1;
			state=0;
		 end
		 if(read_miss_in & read)
		 begin
			writeback=1;
			abort=1;
			state=1;
		 end
		end
	end
	3://Excl
	begin
		if(write_miss_in | invalidate_in)
		begin
			state=0;
		end
		if(write_hit & write)
		begin
			state=2;
		end
		if(read & read_miss_in)
		begin
			state=1;
		end
	end
endcase

endmodule 


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