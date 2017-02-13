/**
 #----------------------------------------------------------------------
 #   Copyright 2007-2017 Cadence Design Systems, Inc.
 #   All Rights Reserved Worldwide
 #
 #   Licensed under the Apache License, Version 2.0 (the
 #   "License"); you may not use this file except in
 #   compliance with the License.  You may obtain a copy of
 #   the License at
 #
 #       http://www.apache.org/licenses/LICENSE-2.0
 #
 #   Unless required by applicable law or agreed to in
 #   writing, software distributed under the License is
 #   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 #   CONDITIONS OF ANY KIND, either express or implied.  See
 #   the License for the specific language governing
 #   permissions and limitations under the License.
 #----------------------------------------------------------------------

 */

// example DUT
// addr=0 is the data register
// addr=4 is the index register
// upon read/write the dut is operating on a set of 10 values

module dut;
	import uvm_pkg::*;

	// the data store
	uvm_reg_data_t store[10];

	// the index
	int unsigned idx;

	function uvm_reg_data_t read(uvm_reg_addr_t addr);
		case(addr)
			4: return idx; // addr=4 is the index register
			0 : return store[idx]; // addr=0 is the data register
			default: return '0;
		endcase
	endfunction
	function void write(uvm_reg_addr_t addr, uvm_reg_data_t data);
		case(addr)
			4: idx=data;
			0 : store[idx]=data;
		endcase
	endfunction
endmodule
