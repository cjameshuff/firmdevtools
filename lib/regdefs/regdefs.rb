#*******************************************************************************
# Copyright (c) 2011 Christopher James Huff
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#*******************************************************************************

# These builder classes construct a heirarchy of hashes defining registers for a device.
# This data structure can then be used to generate include files with register definitions,
# drive a device remotely with Ruby code, etc. The goal is to reduce redundancy and simplify
# description of the registers, as well as allowing for greater flexibility in use. For
# example, the same definitions can be used to generate both a struct-based API and a simple
# set of separately defined registers.
#
# They are arranged in groups of registers for each peripheral.
# Each peripheral contains:
# :name, the name of the peripheral
# :struct_name, the name of the peripheral type..."GPIO" as opposed to "GPIO1", for example.
# :base, base address of the peripheral
# :regs_by_name, a hash with the various registers belonging to the peripheral, keyed by name
# :reglist, array of registers and register groupings in memory order.
#
# Each register is a hash with the following pieces of information:
# offset: offset from base address of peripheral
# access: allowed access methods: :r, :w, :rw FIXME: needs to be made per-field
# fields: a hash of bit subfields of the register, containing bit range and associated values.
#   Fields must not overlap.
# vals: a hash of settings for the register. May contain higher level settings that affect
#   multiple fields, or just values for a register without any fields.
#
# For example, a SYSTICK peripheral, with CTRL, LOAD, VAL, and CALIB registers:
# {
#     base: 0xE0000000,
#     name: "SYSTICK",
#     struct_name: "SYSTICK",
#     output: [:struct, :regs, :fields],
#     regs_by_name: {
#         CTRL: {
#             offset: 0,
#             access: :rw,
#             fields: {
#                 ENABLE: {bits: 0..0, vals: {ENABLE: (1<<0)}},
#                 TICKINT: {bits: 1..1, vals: {TICKINT: (1<<1)}},
#                 CLKSOURCE: {bits: 2..2, vals: {CLKSOURCE: (1<<2)}},
#                 COUNTFLAG: {bits: 16..16, vals: {COUNTFLAG: (1<<16)}},
#             },
#             vals: {...}
#         },
#         LOAD: {:offset: 4, access: rw, fields: {RELOAD: 16777215}},
#         VAL: {:offset: 8, access: rw, fields: {VAL: 16777215}},
#         CALIB: {:offset: 12, access: r, fields: {CALIB: 16777215}}
#     },
#     reglist: [...]
# }


ALL_PARTS = Dir.glob(File.dirname(__FILE__) + "/*").map{|e| File.basename(e, '.rb')}
ALL_PARTS.delete('regdefs')

REGSIZES = {reg8: 1, reg16: 2, reg32: 4}
REGTYPESTRS32 = {r: '__R_REG32 ', w: '__W_REG32 ', rw: '__RW_REG32'}
FIELDTYPESTRS = {r: '__R_FIELD ', w: '__W_FIELD ', rw: '__RW_FIELD'}

class RegisterBuilder
    def initialize(periph, regname, &block)
        @register = periph[:regs_by_name][regname]
        instance_eval &block
    end
    
    # Define fields from bit range for a single unnamed field, or from a hash
    # of bit ranges.
    # Values are automatically generated for 1-bit fields from the field name.
    def quick_fields(qfields)
        # Hash: fname:bitnum, fname:bitrange
        if(qfields.kind_of? Range)
            # No fields, just a mask for the register as a whole
            field(:_, qfields)
        elsif(qfields.kind_of? Hash)
            qfields.each {|fieldname, fieldmask|
                if(fieldmask.kind_of? Range)
                    field(fieldname, fieldmask)
                else# 1 bit field
                    flag(fieldname, fieldmask)
                end
            }
        end
    end
    
    # Define mask and values for a 1-bit field
    # By default, defines a value with the same name as the field. Can optionally
    # override this, as well as defining a value for the bit not being set.
    # The bit is specified by bit index.
    def flag(flagname, bit, onvalname = nil, offvalname = nil)
        field(flagname, bit..bit)
        if(onvalname)
            vals(flagname, onvalname.to_sym => 1)
        else
            vals(flagname, flagname => 1)
        end
        if(offvalname)
            vals(flagname, offvalname.to_sym => 0)
        end
    end
    
    def flags(flag_hash)
        flag_hash.each{|k,v| flag(k, v)}
    end
    
    # rebuild hash to ensure fields are sorted by position
    def resort_fields()
        @register[:fields] = Hash[
            @register[:fields].to_a.sort{|a, b| a[1][:bits].begin <=> b[1][:bits].begin}
        ]
    end
    
    # Define a field of a register, a contiguous range of bits grouped for a specific
    # function.
    # It often does not make sense to give a field a name separate from that of
    # the register itself, for instance in GPIO data or direction registers,
    # timer/counter value registers, etc. One field per register may be unnamed,
    # use the symbol :_ for these fields.
    # 
    # field(fieldname, bitrange)
    # field(fieldname, values)
    # field(fieldname, bitrange, values)
    def field(fieldname, x, y = nil)
        fieldname = fieldname.to_sym
        if(!@register[:fields][fieldname])
            @register[:fields][fieldname] = {bits: nil, vals: {}}
        end
        val_hash = y
        if(x.kind_of? Range)
            @register[:fields][fieldname][:bits] = x
            resort_fields()
        elsif(x.kind_of? Numeric)
            @register[:fields][fieldname][:bits] = x..x
            resort_fields()
        else
            val_hash = x
        end
        
        if(val_hash)
            val_hash.each {|valname, val|
                valname = valname.to_sym
                @register[:fields][fieldname][:vals][valname] = val
            }
        end
    end
    
    # Specify values for a register or register field.
    # Use a fieldname of :_ to specify values for the register as a whole.
    # Values are specified and stored as integer value of field, and must be
    # shifted properly before used in direct register writes.
    def vals(fieldname, val_hash)
        fieldname = fieldname.to_sym
        if(fieldname == :_)
            val_hash.each {|valname, val| @register[:vals][valname.to_sym] = val}
        else
            field(fieldname, val_hash)
        end
    end
end

# A set of associated, contiguous registers, typically a particular peripheral.
# The initialize() method takes the base address, a type/instance name (instance
# names must be overridden later if distinct from the type name), and a block
# containing the definition of the registers.
#
# The base address may be given as -1 instead of an actual address. This will
# signal the code to not output registers, only masks and values, allowing for
# generic definitions shared among multiple identical peripherals, such as the
# various GPIO ports.
#
# Similarly, individual registers can be defined with access permissions of :none,
# allowing bit definitions to be generated for multiple registers under a generic
# name.
#
# Hash:
# base: base address of peripheral
# name: name of peripheral
# struct_name: name of peripheral type
# output: an array of things to output for include file generation, etc. By default:
#   :struct: struct definitions and declarations
#   :regs: direct register access definitions
#   :fields: mask, bit, and value definitions for each register's fields
class RegSetBuilder
    attr_accessor :peripheral
    def initialize(base, name, &block)
        @regs_by_name = {}
        @reglist = []
        @peripheral = {
            base: base,
            name: name.to_sym,
            struct_name: name.to_sym,
            output: [:struct, :regs, :fields],
            regs_by_name: @regs_by_name,
            reglist: @reglist
        }
        instance_eval &block
    end
    
    # Declare a 32 bit register. At present, registers should be declared in the
    # order they appear in in memory.
    # access may be :r, :w, :rw, or :none. Access of :none is used to declare a
    # "ghost" register that is not used directly, but can be used to define generic
    # masks and values that may be used with a group of registers.
    def declreg(regname, offset, access, type)
        if(offset.kind_of? Numeric)
            offset = (offset..(offset + REGSIZES[type]))
        end
        reg = {
            name: regname.to_sym,
            type: type,
            offset: offset,
            access: (access)? access : :rw,
            fields: {},
            vals: {}
        }
        @regs_by_name[regname.to_sym] = reg
        if(reg[:access] != :none)
            @reglist.push(reg)
            @reglist.sort!{|a, b| a[:offset].begin <=> b[:offset].begin}
        end
    end
    
    def union(&block)
        saved_reglist = @reglist
        @reglist = []
        instance_eval &block
        grouped_registers = @reglist
        @reglist = saved_reglist
        # TODO: check that union members are of equal size, add padding as necessary
        add_grouped_registers(grouped_registers, :union)
    end
    
    def struct(&block)
        saved_reglist = @reglist
        @reglist = []
        instance_eval &block
        grouped_registers = @reglist
        @reglist = saved_reglist
        add_grouped_registers(grouped_registers, :struct)
    end
    
    def add_grouped_registers(grouped_registers, type)
        grouped_registers.sort!{|a, b| a[:offset].begin <=> b[:offset].begin}
        max_offset = grouped_registers.map{|r| r[:offset].end}.max
        @reglist.push({
            type: type,
            offset: grouped_registers.first[:offset].begin..max_offset,
            reglist: grouped_registers
        })
    end
    
    # Define further fields and values for a register
    def defreg(regname, &block)
        if(!@regs_by_name[regname.to_sym])
            raise "Register #{regname.to_s} not declared!"
        end
        RegisterBuilder.new(@peripheral, regname, &block)
    end
    
    # Declare and define a 32 bit register
    def reg32(regname, offset, access, qfields = {})
        declreg(regname, offset, access, :reg32)
        RegisterBuilder.new(@peripheral, regname) {quick_fields(qfields)}
    end
    
    # Declare and define a 16 bit register
    def reg16(regname, offset, access, qfields = {})
        declreg(regname, offset, access, :reg16)
        RegisterBuilder.new(@peripheral, regname) {quick_fields(qfields)}
    end
    
    # Declare and define a 8 bit register
    def reg8(regname, offset, access, qfields = {})
        declreg(regname, offset, access, :reg8)
        RegisterBuilder.new(@peripheral, regname) {quick_fields(qfields)}
    end
    
    # def regvals(regname, val_hash)
    #     register = @regs_by_name[regname]
    #     if(!register[:vals])
    #         register[:vals] = {}
    #     end
    #     register[:vals].merge!(val_hash)
    # end
end

def def_periph(base, name, &block)
    RegSetBuilder.new(base, name, &block).peripheral
end

def range_mask(r)
    (2 << r.end) - (1 << r.begin)
end

# Emit a union of a bitfield and a flat register
def emit_c_bitfield(indent, reg, opts)
    start = reg[:offset].begin
    size = (1 + reg[:offset].end - reg[:offset].begin)/4
    array_str = (size > 1)? "[#{size}]" : ""
    puts indent + "union {"
    puts indent + "\t#{REGTYPESTRS32[reg[:access]]} %s%s;" % [reg[:name].to_s, array_str]
    
    n = 0
    puts indent + "\tstruct {"
    reg[:fields].each {|name, f|
        if(f[:bits].begin != n)
            puts indent + "\t\t__PADDING  pad%d:%d;"%[n, f[:bits].begin - n]
        end
        puts indent + "\t\t#{FIELDTYPESTRS[reg[:access]]} %s:%d;"%[name.to_s, 1 + f[:bits].end - f[:bits].begin]
        n = f[:bits].end + 1
    }
    if(n < 32)
        puts indent + "\t\t__PADDING pad%d:%d;"%[n, 32 - n]
    end
    puts indent + "\t} %s_bf;" % [reg[:name].to_s, array_str]
    puts indent + "};" % [reg[:name].to_s, array_str]
end

# Emit members of a struct or union (such as a peripheral or subgroup of registers)
def emit_c_struct_members(indent, base, addr, regs, opts)
    regs.each {|reg|
        start = reg[:offset].begin
        size = (1 + reg[:offset].end - reg[:offset].begin)/4
        # + 1 for inclusive range, + 3 for remaining 3 bytes of 4-byte word,
        # + 3 to force rounding up
        regtype = REGTYPESTRS32[reg[:access]]
        if(addr != base + start)
            padsize = (start + base - addr)/4
            if(padsize > 1)
                puts indent + "uint32_t PAD_%04X[%d];" % [addr - base, padsize]
            else
                puts indent + "uint32_t PAD_%04X;" % [addr - base]
            end
            addr = base + start;
        end
        
        if(reg[:type] == :union)
            puts indent + "union {"
            reg[:reglist].each {|reg|
                emit_c_struct_members(indent + "\t", base, addr, [reg], opts)
            }
            puts indent + "};"
        elsif(reg[:type] == :struct)
            puts indent + "union {"
            emit_c_struct_members(indent + "\t", base, addr, reg[:reglist], opts)
            puts indent + "};"
        elsif(reg[:type] == :pad32)
            if(size > 1)
                puts indent + "uint32_t PAD_%04X[%d];" % [addr - base, size]
            else
                puts indent + "uint32_t PAD_%04X;" % [addr - base]
            end
        elsif(size > 1)
            puts indent + "#{regtype} %s[%d]; // %04X" % [reg[:name].to_s, size, addr - base]
        else
            # if(opts[:bitfields])
                emit_c_bitfield(indent, reg, opts)
            # else
            #     puts indent + "#{regtype} %s; // %04X" % [reg[:name].to_s, addr - base]
            # end
        end
        addr += size*4;
    }
end

# Emit C struct declaration and typedef for a peripheral. Name of type will be [STRUCT_NAME]_struct.
def emit_c_struct(periph, opts = {})
    base = periph[:base]
    sname = periph[:struct_name]
    
    puts "typedef struct {"
    emit_c_struct_members("\t", base, base, periph[:reglist], opts)
    puts "} %s_struct;" % [sname]
end

# Emit C struct variable declaration for a peripheral.
def emit_c_structdecl(periph)
    if(periph[:base] == -1)
        return # not a real peripheral, defined only to attach register fields/values
    end
    pname = periph[:name]
    sname = periph.fetch(:struct_name) {periph[:name]}
    puts "#define %s  ((%s_struct *)0x%X)" % [pname, sname, periph[:base]]
end

# Emit declarations for direct register access, not as members of a struct.
def print_regs(periph)
    if(periph[:base] == -1)
        return # not a real peripheral, defined only to attach register fields/values
    end
    
    if(!periph[:output].include? :regs)
        return
    end
    
    base = periph[:base]
    periph[:regs_by_name].each {|regname, reg|
        if(reg[:access] != :none)
            offset = reg[:offset]
            puts "#define %s_%s  (*(uint32_t *)0x%X)" % [periph[:name], regname.to_s, (base + offset.begin)]
        end
    }
end

# Emit definitions of masks and values for fields of each register
def print_vals(periph)
    if(!periph[:output].include? :fields)
        return
    end
    
    periph[:regs_by_name].each {|regname, reg|
        if(reg[:fields])
            reg[:fields].each {|fieldname, field|
                if(fieldname == :_)
                    puts "#define %s_MASK  0x%X" % [regname.to_s, range_mask(field[:bits])]
                    # puts "#define %s_%s_MASK  0x%X" % [periph[:name], regname.to_s, val]
                else
                    puts "#define %s_%s_MASK  0x%X" % [regname.to_s, fieldname.to_s, range_mask(field[:bits])]
                    # puts "#define %s_%s_%s_MASK  0x%X" % [periph[:name], regname.to_s, valname.to_s, val]
                end
            }
            puts ""
        else
            $stderr.puts "Incomplete definition for #{regname.to_s} in #{periph[:name]}"
        end
        
        # Register field values
        if(reg[:fields].length > 0)
            reg[:fields].each {|fieldname, field|
                field[:vals].each {|valname, val|
                    puts "#define %s_%s  0x%X" % [regname.to_s, valname.to_s, val << field[:bits].begin]
                }
            }
            puts ""
        end
        
        # Register values
        if(reg[:vals].length > 0)
            reg[:vals].each {|valname, val|
                # puts "#define %s_%s_%s  0x%X" % [periph[:name], regname.to_s, valname.to_s, val]
                puts "#define %s_%s  0x%X" % [regname.to_s, valname.to_s, val]
            }
            puts ""
        end
    }
end

# Generate a C include for a microcontroller, with peripherals in its memory space,
# with complete struct access and bitfields by default.
def generate_uc_cinclude(ucname, opts = {})
    ucname = ucname.upcase
    puts "#ifndef #{ucname}REGS_H"
    puts "#define #{ucname}REGS_H"
    puts ""
    puts "#define __R_REG32  volatile const uint32_t"
    puts "#define __W_REG32  volatile uint32_t"
    puts "#define __RW_REG32  volatile uint32_t"
    puts "#define __R_FIELD  volatile const unsigned int"
    puts "#define __W_FIELD  volatile unsigned int"
    puts "#define __RW_FIELD  volatile unsigned int"
    puts "#define __PADDING  volatile const unsigned int"
    puts ""
    puts ""
    
    # Generate struct declarations
    already_printed = {}
    peripherals = eval(ucname)
    peripherals.each {|k, v|
        if(!already_printed[v[:struct_name]])
            puts "\n//" + "*"*78
            puts "// #{v[:name]} struct definition"
            puts "//" + "*"*78
            emit_c_struct(v)
            already_printed[v[:struct_name]] = true
            puts
        end
    
        puts "\n//" + "*"*78
        puts "// #{v[:name]} registers"
        puts "//" + "*"*78
        emit_c_structdecl(v)
        puts
        print_regs(v)
        puts
    }
    peripherals.each {|k, v|
        puts "\n//" + "*"*78
        puts "// #{v[:name]} bitdefs"
        puts "//" + "*"*78
        print_vals(v)
        puts
    }
    puts ""
    puts "#endif // #{ucname}REGS_H"
    puts ""
end
