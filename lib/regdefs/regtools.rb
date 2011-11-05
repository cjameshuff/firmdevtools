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

require 'regdefs/regdefs'

module RegDefs

ALL_PARTS = Dir.glob(File.dirname(__FILE__) + "/*").map{|e| File.basename(e, '.rb')}
ALL_PARTS.delete('regdefs')
ALL_PARTS.delete('regtools')

REGSIZES = {reg8: 1, reg16: 2, reg32: 4}
REGTYPESTRS32 = {r: '__R_REG32 ', w: '__W_REG32 ', rw: '__RW_REG32'}
FIELDTYPESTRS = {r: '__R_FIELD ', w: '__W_FIELD ', rw: '__RW_FIELD'}

def self.range_mask(r)
    (2 << r.end) - (1 << r.begin)
end

# Emit a union of a bitfield and a flat (integer) register
def self.emit_c_bitfield(fout, indent, reg, opts)
    start = reg[:offset].begin
    size = (1 + reg[:offset].end - reg[:offset].begin)/4
    array_str = (size > 1)? "[#{size}]" : ""
    fout.puts indent + "union {"
    fout.puts indent + "\t#{REGTYPESTRS32[reg[:access]]} %s%s;" % [reg[:name].to_s, array_str]
    
    n = 0
    fout.puts indent + "\tstruct {"
    reg[:fields].each {|name, f|
        if(f[:bits].begin != n)
            fout.puts indent + "\t\t__PADDING  pad%d:%d;"%[n, f[:bits].begin - n]
        end
        fout.puts indent + "\t\t#{FIELDTYPESTRS[reg[:access]]} %s:%d;"%[name.to_s, 1 + f[:bits].end - f[:bits].begin]
        n = f[:bits].end + 1
    }
    if(n < 32)
        fout.puts indent + "\t\t__PADDING pad%d:%d;"%[n, 32 - n]
    end
    fout.puts indent + "\t} %s_bf;" % [reg[:name].to_s, array_str]
    fout.puts indent + "};" % [reg[:name].to_s, array_str]
end # emit_c_bitfield()

# Emit members of a struct or union (such as a peripheral or subgroup of registers)
def self.emit_c_struct_members(fout, indent, base, addr, regs, opts)
    regs.each {|reg|
        start = reg[:offset].begin
        size = (1 + reg[:offset].end - reg[:offset].begin)/4
        # + 1 for inclusive range, + 3 for remaining 3 bytes of 4-byte word,
        # + 3 to force rounding up
        regtype = REGTYPESTRS32[reg[:access]]
        if(addr != base + start)
            padsize = (start + base - addr)/4
            if(padsize > 1)
                fout.puts indent + "uint32_t PAD_%04X[%d];" % [addr - base, padsize]
            else
                fout.puts indent + "uint32_t PAD_%04X;" % [addr - base]
            end
            addr = base + start;
        end
        
        if(reg[:type] == :union)
            fout.puts indent + "union {"
            reg[:reglist].each {|reg|
                emit_c_struct_members(fout, indent + "\t", base, addr, [reg], opts)
            }
            fout.puts indent + "};"
        elsif(reg[:type] == :struct)
            fout.puts indent + "union {"
            emit_c_struct_members(fout, indent + "\t", base, addr, reg[:reglist], opts)
            fout.puts indent + "};"
        elsif(reg[:type] == :pad32)
            if(size > 1)
                fout.puts indent + "uint32_t PAD_%04X[%d];" % [addr - base, size]
            else
                fout.puts indent + "uint32_t PAD_%04X;" % [addr - base]
            end
        elsif(size > 1)
            fout.puts indent + "#{regtype} %s[%d]; // %04X" % [reg[:name].to_s, size, addr - base]
        else
            # if(opts[:bitfields])
                emit_c_bitfield(fout, indent, reg, opts)
            # else
            #     puts indent + "#{regtype} %s; // %04X" % [reg[:name].to_s, addr - base]
            # end
        end
        addr += size*4;
    }
end # emit_c_struct_members()

# Emit C struct declaration and typedef for a peripheral. Name of type will be [STRUCT_NAME]_struct.
def self.emit_c_struct(fout, periph, opts = {})
    base = periph[:base]
    sname = periph[:struct_name]
    
    fout.puts "typedef struct {"
    emit_c_struct_members(fout, "\t", base, base, periph[:reglist], opts)
    fout.puts "} %s_struct;" % [sname]
end # emit_c_struct()

# Emit C struct variable declaration for a peripheral.
def self.emit_c_structdecl(fout, periph)
    if(periph[:base] == -1)
        return # not a real peripheral, defined only to attach register fields/values
    end
    pname = periph[:name]
    sname = periph.fetch(:struct_name) {periph[:name]}
    fout.puts "#define MCU_%s  ((%s_struct *)0x%X)" % [pname, sname, periph[:base]]
end # emit_c_structdecl()

# Emit declarations for direct register access, not as members of a struct.
def self.emit_regs(fout, periph)
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
            fout.puts "#define %s_%s  (*(uint32_t *)0x%X)" % [periph[:name], regname.to_s, (base + offset.begin)]
        end
    }
end # emit_regs()

# Emit definitions of masks and values for fields of each register
def self.emit_vals(fout, periph)
    if(!periph[:output].include? :fields)
        return
    end
    
    periph[:regs_by_name].each {|regname, reg|
        if(reg[:fields].length > 0)
            reg[:fields].each {|fieldname, field|
                if(fieldname == :_)
                    fout.puts "#define %s_BM  (0x%X)" % [regname.to_s, range_mask(field[:bits])]
                    fout.puts "#define %s_BP  (%d)" % [regname.to_s, field[:bits].begin]
                else
                    fout.puts "#define %s_%s_BM  (0x%X)" % [regname.to_s, fieldname.to_s, range_mask(field[:bits])]
                    fout.puts "#define %s_%s_BP  (%d)" % [regname.to_s, fieldname.to_s, field[:bits].begin]
                end
            }
            fout.puts ""
        else
            $stderr.puts "Incomplete definition for #{regname.to_s} in #{periph[:name]}"
        end
        
        # Register field values
        if(reg[:fields].length > 0)
            clean = true
            reg[:fields].each {|fieldname, field|
                field[:vals].each {|valname, val|
                    fout.puts "#define %s_%s  (0x%X)" % [regname.to_s, valname.to_s, val << field[:bits].begin]
                    clean = false
                }
            }
            if(!clean)
                fout.puts ""
            end
        end
        
        # Register values
        if(reg[:vals].length > 0)
            reg[:vals].each {|valname, val|
                fout.puts "#define %s_%s  (0x%X)" % [regname.to_s, valname.to_s, val]
            }
            fout.puts ""
        end
    }
end # emit_vals()

def self.emit_cinc_header(fout, fname, opts = {})
    fout.puts "#ifndef #{fname.upcase}REGS_H"
    fout.puts "#define #{fname.upcase}REGS_H"
    fout.puts ""
    fout.puts "#define __R_REG32  volatile const uint32_t"
    fout.puts "#define __W_REG32  volatile uint32_t"
    fout.puts "#define __RW_REG32  volatile uint32_t"
    fout.puts "#define __R_FIELD  volatile const unsigned int"
    fout.puts "#define __W_FIELD  volatile unsigned int"
    fout.puts "#define __RW_FIELD  volatile unsigned int"
    fout.puts "#define __PADDING  volatile const unsigned int"
    fout.puts ""
    fout.puts ""
end

def self.emit_cinc_footer(fout, fname, opts = {})
    fout.puts ""
    fout.puts "#endif // #{fname.upcase}REGS_H"
    fout.puts ""
end

# Generate a C include for a microcontroller, with peripherals in its memory space,
# with complete struct access and bitfields by default.
def generate_uc_cincludes(ucname, opts = {})
    opts = {
        incdir: '.'
    }.merge(opts)
    
    incdir = opts[:incdir]
    ucname = ucname.upcase
    peripherals = eval("#{ucname}::#{ucname}")
    struct_types = peripherals.values.uniq{|p| p[:struct_name]}
    
    fout = File.new("#{ucname.downcase}.h", 'w')
    emit_cinc_header(fout, "#{ucname.downcase}", opts)
    
    # Generate struct declarations
    struct_types.each {|v|
        fout.puts "\n//" + "*"*78
        fout.puts "// #{v[:struct_name]} struct definition"
        fout.puts "//" + "*"*78
        emit_c_struct(fout, v)
        fout.puts
    }
    
    peripherals.each {|k, v|
        fout.puts "\n//" + "*"*78
        fout.puts "// #{v[:name]} registers"
        fout.puts "//" + "*"*78
        emit_c_structdecl(fout, v)
        fout.puts
        emit_regs(fout, v)
        fout.puts
        fout.puts "\n//" + "*"*78
        fout.puts "// #{v[:name]} bitdefs"
        fout.puts "//" + "*"*78
        emit_vals(fout, v)
        fout.puts
    }
    
    emit_cinc_footer(fout, ucname, opts)
end # generate_uc_cincludes()
module_function :generate_uc_cincludes

end # module RegDefs
