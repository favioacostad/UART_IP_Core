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
module BB_SYSTEM (
//////////// OUTPUTS ////////////
	BB_SYSTEM_tx_Out,
	BB_SYSTEM_busy_Out,
//////////// INPUTS ////////////
	BB_SYSTEM_CLOCK_50,
	BB_SYSTEM_RESET_InHigh,
	BB_SYSTEM_LOCK_InHigh,
	BB_SYSTEM_newData_InHigh,
	BB_SYSTEM_data_In
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// BAUD RATE ////////////
// Ratio between the internal frequency and the baud rate
parameter CLOCK_PER_BIT = 434;		// CLOCK_PER_BIT = 50MHz/115200Bauds
//parameter CLOCK_PER_BIT = 868;		// CLOCK_PER_BIT = 50MHz/57600Bauds
//parameter CLOCK_PER_BIT = 2604;	// CLOCK_PER_BIT = 50MHz/19200Bauds
//parameter CLOCK_PER_BIT = 5208;	// CLOCK_PER_BIT = 50MHz/9600Bauds
//////////// SIZES ////////////
// Data width of the imput bus
parameter DATAWIDTH_BUS = 8;
// Size for the states needed into the protocol
parameter STATE_SIZE = 3;

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	BB_SYSTEM_tx_Out;
output	BB_SYSTEM_busy_Out;
//////////// INPUTS ////////////
input 	BB_SYSTEM_CLOCK_50;
input 	BB_SYSTEM_RESET_InHigh;
input		BB_SYSTEM_LOCK_InHigh;
input		BB_SYSTEM_newData_InHigh;
input		[DATAWIDTH_BUS-1:0] BB_SYSTEM_data_In;

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
UART_TX #(.CLOCK_PER_BIT(CLOCK_PER_BIT), .DATAWIDTH_BUS(DATAWIDTH_BUS), .STATE_SIZE(STATE_SIZE)) UART_TX_u0 (
// Port map - connection between master ports and signals/registers  
//////////// OUTPUTS ////////////
	.UART_TX_tx_Out(BB_SYSTEM_tx_Out),
	.UART_TX_busy_Out(BB_SYSTEM_busy_Out),
//////////// INPUTS ////////////
	.UART_TX_CLOCK_50(BB_SYSTEM_CLOCK_50),
	.UART_TX_RESET_InHigh(BB_SYSTEM_RESET_InHigh),
	.UART_TX_LOCK_InHigh(BB_SYSTEM_LOCK_InHigh),
	.UART_TX_newData_InHigh(BB_SYSTEM_newData_InHigh),
	.UART_TX_data_In(BB_SYSTEM_data_In)
);

endmodule
