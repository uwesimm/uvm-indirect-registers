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

 @version 1.1
 @author uwes@cadence.com

 */

package cdns_generic_indirect_register;
	import uvm_pkg::*;

	// index API definition

	// @param index - defines the actual type of the index
	virtual class IndexProviderI#(type INDEX=int);

		// @return the current index
		pure virtual function INDEX getIndex();

		// sets the current index
		// @param idx - current index
		pure virtual task setIndex(INDEX idx);
	endclass

	// storage API
	// @param STORAGE - type of a storage element
	// @param INDEX - type of index
	virtual class IndexableStorageI#(type STORAGE=int,INDEX=int);
		typedef STORAGE AtomicStorage[];
		protected AtomicStorage thisStore;

		// sets the actual reference to the actual storage elements for this indexable storage
		// @param r - the actual storage
		// @return the current IndexableStorage
		virtual function IndexableStorageI#(STORAGE,INDEX) set(AtomicStorage r);
			thisStore=r;
			return this;
		endfunction

		// returns the actual storage element set for the given index
		// @param idx - the index
		// @return the set of selected storage elements
		pure virtual function AtomicStorage getSelectedAtomicEntities(const ref INDEX idx);

		// returns the index for the given set of storage elements
		// @param storage - set of storage elements
		// @return the index selecting the provided elements
		pure virtual function INDEX getIndexForStorage(AtomicStorage storage);
	endclass

	// the generic register groups storage+index into a uvm_reg comptible register
	// @param STORAGE - the storage element type (default=uvm_reg). for this implementation the
	//                  type STORAGE needs to implement the do_predict (API)
	// @param INDEX - the index type (default=int unsigned)

	class GenericIndirectRegister#(type STORAGE=uvm_reg,INDEX=int unsigned) extends uvm_reg;
		local IndexableStorageI#(STORAGE,INDEX) storageP;
		local IndexProviderI#(INDEX) indexP;

		// sets the storage for this register instance
		// @param storage - the current storage
		// @return the current instance
		virtual function GenericIndirectRegister#(STORAGE,INDEX) setStorage(
									IndexableStorageI#(STORAGE,INDEX) storage);
			storageP=storage;
			return this;
		endfunction

		// sets the index provider for the current instance
		// @param index - the current index provider
		// @return the current instance
		virtual function GenericIndirectRegister#(STORAGE,INDEX) setIndexProvider(
									IndexProviderI#(INDEX) index);
			indexP=index;
			return this;
		endfunction

		// ctor matching the uvm_reg ctor
		function new(string name="", int unsigned n_bits, int has_coverage);
			super.new(name,n_bits,has_coverage);
		endfunction

		// the actual indirect implementation. this particular implementation uses
		// the provided index provider to determine the actual index and
		// forwards the 'prediction' to the selected storage elements
		// this implementation assumes that the storage elements implement do_predict
		// this is compatible with uvm_reg and uvm_reg_field
		virtual function void do_predict (uvm_reg_item      rw,
				uvm_predict_e     kind = UVM_PREDICT_DIRECT,
				uvm_reg_byte_en_t be = -1);

			//NOTE limit to 2**32 registers
			begin
				INDEX idx = indexP.getIndex();
				STORAGE rg[] = storageP.getSelectedAtomicEntities(idx);
				foreach(rg[idx])
					rg[idx].do_predict(rw, kind, be);
			end
		endfunction
	endclass

	// custom implementation:
	// using a uvm_reg_field as index provider providing an 'int unsigned' index
	class URFindexProvider extends IndexProviderI#(int unsigned);
		// the reference to the uvm_reg_field holding the numeric index
		local uvm_reg_field store;

		// setter for store
		virtual function URFindexProvider set(uvm_reg_field s);
			store=s;
			return this;
		endfunction

		virtual function INDEX getIndex();
			return store.get_mirrored_value();
		endfunction

		virtual task setIndex(INDEX idx);
			uvm_status_e status;
			store.write(status,idx);
		endtask
	endclass

	// custom implementation:
	// storage is an "uvm_reg" array indexed by a single "int unsigned"
	// this indexable storage supports only single index selection
	class MyIndexableStorageI extends IndexableStorageI#(uvm_reg,int unsigned);
		virtual function AtomicStorage getSelectedAtomicEntities(const ref INDEX idx);
			AtomicStorage t=new[1];
			t[0]=thisStore[idx];
			return t;
		endfunction
		// might use an AA instead of the search
		virtual function INDEX getIndexForStorage(AtomicStorage storage);
			int q[$]=thisStore.find_first_index(item) with (item==storage[0]);
			assert(q.size()>0);
			return q[0];
		endfunction
	endclass

	// (optional) custom implementation:
	// a frontdoor for the GenericIndirectRegister
	// this translates a direct uvmreg access to an indexed register into
	// an indirect register utilizing the index and data registers
	// @see uvm_reg_frontdoor
	//
	class IregFrontdoor#(type STORAGE=uvm_reg,INDEX=int unsigned) extends uvm_reg_frontdoor;
		local uvm_reg data;
		local IndexProviderI#(INDEX) idx;
		local IndexableStorageI#(STORAGE,INDEX) storage;
		local STORAGE this_reg;

		virtual task body();
			uvm_status_e status;
			STORAGE x[$];
			INDEX i;
			x.push_back(this_reg);
			i = storage.getIndexForStorage(x);
			idx.setIndex(i);
			if(rw_info.kind==UVM_WRITE)
				data.write(status,rw_info.value[0]);
			else
				data.read(status,rw_info.value[0]);
		endtask

		virtual function void configure(uvm_reg theIreg,
				IndexProviderI#(INDEX) idx,
				IndexableStorageI#(STORAGE,INDEX) storage,
				STORAGE this_reg);
			this.data=theIreg;
			this.idx=idx;
			this.storage=storage;
			this.this_reg=this_reg;
		endfunction

		function new(string name="IregFrontdoor");
			super.new(name);
		endfunction
	endclass

endpackage
