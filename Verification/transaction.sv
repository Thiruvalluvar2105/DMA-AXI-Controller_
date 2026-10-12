import uvm_pkg::*;
`include "uvm_macros.svh"

class dma_transaction extends uvm_sequence_item;

    localparam int unsigned ADDR_WIDTH     = 32;
    localparam int unsigned DATA_WIDTH     = 64;
    localparam int unsigned MEM_DEPTH      = 1024;
    localparam int unsigned BYTES_PER_BEAT = DATA_WIDTH/8;
    localparam int unsigned MAX_BEATS      = 64;

    rand bit [ADDR_WIDTH-1:0] src_addr;
    rand bit [ADDR_WIDTH-1:0] dst_addr;
    rand bit [31:0]           transfer_size;

    bit                       dma_done;
    bit                       dma_error;
    bit [DATA_WIDTH-1:0]      rd_data[$];
    bit [DATA_WIDTH-1:0]      wr_data[$];
    bit [ADDR_WIDTH-1:0]      rd_addr[$];
    bit [ADDR_WIDTH-1:0]      wr_addr[$];

    `uvm_object_utils_begin(dma_transaction)
        `uvm_field_int       (src_addr,       UVM_ALL_ON | UVM_HEX)
        `uvm_field_int       (dst_addr,       UVM_ALL_ON | UVM_HEX)
        `uvm_field_int       (transfer_size,  UVM_ALL_ON | UVM_DEC)
        `uvm_field_int       (dma_done,       UVM_ALL_ON | UVM_BIN)
        `uvm_field_int       (dma_error,      UVM_ALL_ON | UVM_BIN)
        `uvm_field_queue_int (rd_data,        UVM_ALL_ON | UVM_HEX)
        `uvm_field_queue_int (wr_data,        UVM_ALL_ON | UVM_HEX)
        `uvm_field_queue_int (rd_addr,        UVM_ALL_ON | UVM_HEX)
        `uvm_field_queue_int (wr_addr,        UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    constraint valid_transfer {
        transfer_size inside {[BYTES_PER_BEAT : MAX_BEATS*BYTES_PER_BEAT]};
        transfer_size[$clog2(BYTES_PER_BEAT)-1:0] == 0;

        src_addr < MEM_DEPTH - 1;
        dst_addr < MEM_DEPTH - 1;
        src_addr + (transfer_size >> $clog2(BYTES_PER_BEAT)) <= MEM_DEPTH - 1;
        dst_addr + (transfer_size >> $clog2(BYTES_PER_BEAT)) <= MEM_DEPTH - 1;

        (src_addr + (transfer_size >> $clog2(BYTES_PER_BEAT)) <= dst_addr) ||
        (dst_addr + (transfer_size >> $clog2(BYTES_PER_BEAT)) <= src_addr);

        solve transfer_size before src_addr;
        solve transfer_size before dst_addr;
    }

    function new(string name = "dma_transaction");
        super.new(name);
    endfunction

    function int unsigned num_beats();
        int unsigned beats;
        beats = (transfer_size + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;
        return (beats == 0) ? 1 : beats;
    endfunction

    function string convert2string();
        return $sformatf("src=0x%0h dst=0x%0h size=%0dB beats=%0d | done=%0b error=%0b rd_beats=%0d wr_beats=%0d",
                         src_addr, dst_addr, transfer_size, num_beats(),
                         dma_done, dma_error, rd_data.size(), wr_data.size());
    endfunction

endclass : dma_transaction
