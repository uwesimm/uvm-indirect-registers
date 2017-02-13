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

 // example testbench illustrating the indirect package

`include "uvm_macros.svh"
package tb_pkg;
	import  uvm_pkg::*;

	// model of an index register
	// has one dummy field
	class reg_R extends uvm_reg;
		rand uvm_reg_field _dummy;

		function new(string name = "R");
			super.new(name, 32, UVM_NO_COVERAGE);
		endfunction

		virtual function void build();
			this._dummy = uvm_reg_field::type_id::create("value");
			this._dummy.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 0);
		endfunction

		`uvm_object_utils(reg_R)
	endclass

	// model of enclosing block
	class block_B extends uvm_reg_block;
		function new(string name = "B");
			super.new(name,UVM_NO_COVERAGE);
		endfunction

		`uvm_object_utils(block_B)
	endclass

	// a low level transaction
	class trans_t extends uvm_sequence_item;
		`uvm_object_utils(trans_t)

		string lower;
		uvm_reg_bus_op orig;

		function new(string name = "trans_t");
			super.new(name);
		endfunction
	endclass

	// a bus adapter translating between uvm_reg_bus_op and the low level transaction (trans_t)
	class bus2reg_adapter extends uvm_reg_adapter;
		`uvm_object_utils(bus2reg_adapter)

		function new(string name = "bus2reg_adapter");
			super.new(name);
		endfunction

		virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
			trans_t t;
			t=new();
			t.lower=$sformatf("%p",rw);
			t.orig=rw;
			return t;
		endfunction

		virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
			trans_t bus;
			$cast(bus,bus_item);
			rw.addr=bus.orig.addr;
			rw.byte_en=bus.orig.byte_en;
			rw.kind=bus.orig.kind;
			rw.n_bits=bus.orig.n_bits;
			rw.status=bus.orig.status;
			rw.data=bus.orig.data;
		endfunction
	endclass
endpackage
