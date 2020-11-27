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
module UART_RX #(parameter CLOCK_PER_BIT, parameter DATAWIDTH_BUS = 8, parameter STATE_SIZE = 3)(
//////////// OUTPUTS ////////////
	UART_RX_newData_Out,
	UART_RX_data_Out,
//////////// INPUTS ////////////
	UART_RX_CLOCK_50,
	UART_RX_RESET_InHigh,
	UART_RX_rx_InLow
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// STATES ////////////
localparam		State_IDLE = 3'b000;
localparam		State_WAIT_HALF = 3'b001;
localparam		State_WAIT_FULL_INIT = 3'b010;
localparam		State_WAIT_FULL_END = 3'b011;
localparam		State_WAIT_HIGH = 3'b100;	
//////////// SIZES ////////////
// Ceiling of log base 2 to get the number of bits needed to store a value
// CLOCK_PER_BIT = 50MHz/115200Bauds
localparam		COUNTER_SIZE = $clog2(CLOCK_PER_BIT); // 8 bits

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	UART_RX_newData_Out;
output	[DATAWIDTH_BUS-1:0] UART_RX_data_Out;
//////////// INPUTS ////////////
input 	UART_RX_CLOCK_50;
input 	UART_RX_RESET_InHigh;
input		UART_RX_rx_InLow;
//////////// FLAGS ////////////

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
//////////// REGISTERS ////////////
// Boolean variable to inform of new data
reg NewData_Register;
// Data in terms of bytes 
reg [DATAWIDTH_BUS-1:0] Data_Register;
// Receptor
reg Rx_Register;
// Current state of the protocol
reg [STATE_SIZE-1:0] State_Register;
// Counter for the clock cycles carried out so far
reg [COUNTER_SIZE-1:0] Counter_Register;
// Counter for the number of bits carried out so far
reg [2:0] BitCounter_Register;
//////////// SIGNALS ////////////
reg NewData_Signal;
reg [DATAWIDTH_BUS-1:0] Data_Signal;
reg Rx_Signal;
reg [STATE_SIZE-1:0] State_Signal;
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
		Rx_Signal = UART_RX_rx_InLow;
		Counter_Signal = Counter_Register;
		BitCounter_Signal = BitCounter_Register;
		
		case (State_Register)
			State_IDLE:
				begin 
					Counter_Signal = {COUNTER_SIZE{1'b0}};
					BitCounter_Signal = 3'b000;
					if (Rx_Register)
						State_Signal = State_IDLE;
					else 
						State_Signal = State_WAIT_HALF;
				end
				
			State_WAIT_HALF:
				begin
					Counter_Signal = Counter_Register + 1'b1;
					if (Counter_Register == (CLOCK_PER_BIT >> 1))
						begin
							State_Signal = State_WAIT_FULL_INIT;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
						end
					else	
						State_Signal = State_WAIT_HALF;
				end

			State_WAIT_FULL_INIT: 		
				begin
					Counter_Signal = Counter_Register + 1'b1;
					if (Counter_Register == CLOCK_PER_BIT-1)
						begin
							State_Signal = State_WAIT_FULL_END;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
						end
					else
						State_Signal = State_WAIT_FULL_INIT;
				end
				
			State_WAIT_FULL_END:
				begin
					BitCounter_Signal = BitCounter_Register + 1'b1;
					if (BitCounter_Register == DATAWIDTH_BUS-1)
						begin
							State_Signal = State_WAIT_HIGH;
							Counter_Signal = {COUNTER_SIZE{1'b0}};
							BitCounter_Signal = 3'b000;
						end
					else
						State_Signal = State_WAIT_FULL_INIT;
				end
				
			State_WAIT_HIGH:
				begin
					if (Rx_Register)
						State_Signal = State_IDLE;
					else
						State_Signal = State_WAIT_HIGH;
				end
				
			default: State_Signal = State_IDLE;
		endcase
	end
	
// STATE REGISTER : Sequential
always @(posedge UART_RX_CLOCK_50, posedge UART_RX_RESET_InHigh)
	begin
		if (UART_RX_RESET_InHigh)
			begin
				NewData_Register <= 1'b0;
				Data_Register <= {DATAWIDTH_BUS{1'b0}};
				Rx_Register <= 1'b1;
				State_Register <= State_IDLE;
				Counter_Register <= {COUNTER_SIZE{1'b0}};
				BitCounter_Register <= 3'b000;
			end
			
		else
			begin
				NewData_Register <= NewData_Signal;
				Data_Register <= Data_Signal;
				Rx_Register <= Rx_Signal;
				State_Register <= State_Signal;
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
		case (State_Register)
			State_IDLE:
				begin
					NewData_Signal = 1'b0; 
					Data_Signal = Data_Register;
				end
			
			State_WAIT_HALF: 
				begin
					NewData_Signal = 1'b0; 
					Data_Signal = Data_Register;
				end
				
			State_WAIT_FULL_INIT:		
				begin
					NewData_Signal = 1'b0; 
					Data_Signal = Data_Register;
				end
				
			State_WAIT_FULL_END:
				begin
					NewData_Signal = 1'b1; 
					Data_Signal = {Rx_Register,Data_Register[7:1]};
				end
				
			State_WAIT_HIGH:
				begin		
					NewData_Signal = 1'b0; 
					Data_Signal = Data_Register;
				end
			
			default:
				begin
					NewData_Signal = 1'b0; 
					Data_Signal = Data_Register;
				end
		endcase
	end
	
// OUTPUT ASSIGNMENTS
assign	UART_RX_newData_Out = NewData_Register;	
assign	UART_RX_data_Out = Data_Register;

endmodule
