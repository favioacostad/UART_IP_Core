/*###########################################################################
//# G0B1T: HDL SERIAL COMMUNICATION PROTOCOLS. 2020.
//###########################################################################
//# Copyright (C) 2018. F.E.Segura Quijano (FES) fsegura@uniandes.edu.co
//# Copyright (C) 2020. F.A.Acosta David   (FAD) fa.acostad@uniandes.edu.co
//# 
//# This program is free software: you can redistribute it and/or modify
//# it under the terms of the GNU General Public License as published by
//# the Free Software Foundation, version 3 of the License.
//#
//# This program is distributed in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//# GNU General Public License for more details.
//#
//# You should have received a copy of the GNU General Public License
//# along with this program.  If not, see <http://www.gnu.org/licenses/>
//#########################################################################*/

//===========================================================================
//  MODULE Definition
//===========================================================================
module UART_TX #(parameter CLOCK_PER_BIT, parameter DATAWIDTH_BUS = 8, parameter STATE_SIZE = 3)(
//////////// OUTPUTS ////////////
	UART_TX_tx_Out,
	UART_TX_busy_Out,
//////////// INPUTS ////////////
	UART_TX_CLOCK_50,
	UART_TX_RESET_InHigh,
	UART_TX_LOCK_InHigh,
	UART_TX_newData_InHigh,
	UART_TX_data_In
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// STATES ////////////
localparam		State_LOCKED_IDLE = 3'b000;
localparam		State_UNLOCKED_IDLE = 3'b001;
localparam		State_START_BIT = 3'b010;
localparam		State_DATA_INIT = 3'b011;
localparam		State_DATA_END = 3'b100;
localparam		State_STOP_BIT = 3'b101;	
//////////// SIZES ////////////
// Ceiling of log base 2 to get the number of bits needed to store a value
// CLOCK_PER_BIT = 50MHz/115200Bauds
localparam		COUNTER_SIZE = $clog2(CLOCK_PER_BIT); // 8 bits

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	UART_TX_tx_Out;
output	UART_TX_busy_Out;
//////////// INPUTS ////////////
input 	UART_TX_CLOCK_50;
input 	UART_TX_RESET_InHigh;
input		UART_TX_LOCK_InHigh;
input		UART_TX_newData_InHigh;
input		[DATAWIDTH_BUS-1:0] UART_TX_data_In;
//////////// FLAGS ////////////

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
//////////// REGISTERS ////////////
// Transmitter
reg Tx_Register;
// Boolean variable to indicate if the module is currently busy or idle
reg Busy_Register;
// Current state of the protocol
reg [STATE_SIZE-1:0] State_Register;
// Boolean variable to lock or not the module
reg Lock_Register;
// Boolean variable to inform of new data
reg NewData_Register;
// Data in terms of bytes 
reg [DATAWIDTH_BUS-1:0] Data_Register;
// Counter for the clock cycles carried out so far
reg [COUNTER_SIZE-1:0] Counter_Register;
// Counter for the number of bits carried out so far
reg [2:0] BitCounter_Register;
//////////// SIGNALS ////////////
reg Tx_Signal;
reg Busy_Signal;
reg [STATE_SIZE-1:0] State_Signal;
reg Lock_Signal;
reg NewData_Signal;
reg [DATAWIDTH_BUS-1:0] Data_Signal;
reg [COUNTER_SIZE-1:0] Counter_Signal;
reg [2:0] BitCounter_Signal;

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
// INPUT LOGIC: Combinational
always @(*)
	begin
		// To init registers
		//State_Signal = State_Register;
		Lock_Signal = UART_TX_LOCK_InHigh;
		NewData_Signal = UART_TX_newData_InHigh;
		Data_Signal = Data_Register;
		Counter_Signal = Counter_Register;
		BitCounter_Signal = BitCounter_Register;
		
		case (State_Register)
			State_LOCKED_IDLE: 
				begin 
					if (Lock_Register)
						State_Signal = State_LOCKED_IDLE;
					else 
						State_Signal = State_UNLOCKED_IDLE;
				end
				
			State_UNLOCKED_IDLE: 
				begin
					Counter_Signal = {COUNTER_SIZE{1'b0}};
					BitCounter_Signal = 3'b000;
					if (NewData_Register)
						begin
							State_Signal = State_START_BIT;
							Data_Signal = UART_TX_data_In;
						end
					else if (~NewData_Register	& ~Lock_Register)
						State_Signal = State_UNLOCKED_IDLE;
					else
						State_Signal = State_LOCKED_IDLE;
				end
				
			State_START_BIT: 		
				begin
					Counter_Signal = Counter_Register + 1'b1;
					if (Counter_Register == CLOCK_PER_BIT-1)
						begin
							State_Signal = State_DATA_INIT;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
						end
					else
						State_Signal = State_START_BIT;
				end
				
			State_DATA_INIT: 
				begin
					Counter_Signal = Counter_Register + 1'b1;
					if (Counter_Register == CLOCK_PER_BIT-1)
						begin
							State_Signal = State_DATA_END;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
						end
					else
						State_Signal = State_DATA_INIT;
				end
				
			State_DATA_END:
				begin
					BitCounter_Signal = BitCounter_Register + 1'b1;
					if (BitCounter_Register == DATAWIDTH_BUS-1)
						begin
							State_Signal = State_STOP_BIT;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
							BitCounter_Signal = 3'b000;
						end
					else
						State_Signal = State_DATA_INIT;
				end
				
			State_STOP_BIT: 
				begin
					Counter_Signal = Counter_Register + 1'b1;
					if (Counter_Register == CLOCK_PER_BIT-1)
						begin
							State_Signal = State_LOCKED_IDLE;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
						end
					else
						State_Signal = State_STOP_BIT;
				end
			
			default: State_Signal = State_LOCKED_IDLE;
		endcase
	end
	
// STATE REGISTER : Sequential
always @(posedge UART_TX_CLOCK_50, posedge UART_TX_RESET_InHigh)
	begin
		if (UART_TX_RESET_InHigh)
			begin
				Tx_Register <= 1'b1;
				Busy_Register <= 1'b0;
				State_Register <= State_LOCKED_IDLE;
				Lock_Register <= 1'b0;
				NewData_Register <= 1'b0;
				Data_Register <= {DATAWIDTH_BUS{1'b0}};
				Counter_Register <= {COUNTER_SIZE{1'b0}};
				BitCounter_Register <= 3'b000;
			end
			
		else
			begin
				Tx_Register <= Tx_Signal;
				Busy_Register <= Busy_Signal;
				State_Register <= State_Signal;
				Lock_Register <= Lock_Signal;
				NewData_Register <= NewData_Signal;
				Data_Register <= Data_Signal;
				Counter_Register <= Counter_Signal;
				BitCounter_Register <= BitCounter_Signal;
			end
	end
	
//===========================================================================
//  OUTPUTS
//===========================================================================
// OUTPUT LOGIC: Combinational
always @(*)
	begin
		// To init registers
		//Busy_Signal = Busy_Register;
		//Tx_Signal = Tx_Register;
		
		case (State_Register)
			State_LOCKED_IDLE:
				begin
					Tx_Signal = 1'b1;
					Busy_Signal = 1'b1;
				end
			
			State_UNLOCKED_IDLE: 
				begin
					Tx_Signal = 1'b1;
					Busy_Signal = 1'b0;
				end
				
			State_START_BIT:		
				begin
					Tx_Signal = 1'b0;
					Busy_Signal = 1'b1;
				end
				
			State_DATA_INIT:		
				begin
					Tx_Signal = Data_Register[BitCounter_Register];
					Busy_Signal = 1'b1;
				end
				
			State_DATA_END:
				begin		
					Tx_Signal = Data_Register[BitCounter_Register];
					Busy_Signal = 1'b1;
				end
			
			State_STOP_BIT:		
				begin
					Tx_Signal = 1'b1;
					Busy_Signal = 1'b0;
				end
			
			default:
				begin
					Tx_Signal = 1'b1;
					Busy_Signal = 1'b0;
				end
		endcase
	end
	
// OUTPUT ASSIGNMENTS
assign UART_TX_tx_Out = Tx_Register;
assign UART_TX_busy_Out = Busy_Register;

endmodule
