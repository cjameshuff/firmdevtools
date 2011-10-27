#!/usr/bin/env ruby
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


# Field types:
# :uint8_t: 1-byte unsigned int
# :uint16_t: 2-byte unsigned int
# :string16_t: 2-byte character string, no termination (length specified separately)
# hash of subfields, type being number of bits per field (not implemented yet)


# USB Standard Device Descriptor
USB_DEVICE_DESCRIPTOR = {
    type_id: 1,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bcdUSB: :uint16_t,
        bDeviceClass: :uint8_t,
        bDeviceSubClass: :uint8_t,
        bDeviceProtocol: :uint8_t,
        bMaxPacketSize0: :uint8_t,
        idVendor: :uint16_t,
        idProduct: :uint16_t,
        bcdDevice: :uint16_t,
        iManufacturer: :uint8_t,
        iProduct: :uint8_t,
        iSerialNumber: :uint8_t,
        bNumConfigurations: :uint8_t
    }
}

# USB Standard Configuration Descriptor
USB_CONFIGURATION_DESCRIPTOR = {
    type_id: 2,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        wTotalLength: :uint16_t,
        bNumInterfaces: :uint8_t,
        bConfigurationValue: :uint8_t,
        iConfiguration: :uint8_t,
        bmAttributes: :uint8_t,
        bMaxPower: :uint8_t
    }
}

# USB String Descriptor
# Start of a list of string descriptors. Append actual string descriptors.
USB_STRING_DESCRIPTORS = {
    type_id: 3,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        wLANGID: :uint16_t
    }
}
USB_STRING_DESCRIPTOR = {
    type_id: 3,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bString: :string16_t
    }
}

# USB Interface Descriptor
USB_INTERFACE_DESCRIPTOR = {
    type_id: 4,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bInterfaceNumber: :uint8_t,
        bAlternateSetting: :uint8_t,
        bNumEndpoints: :uint8_t,
        bInterfaceClass: :uint8_t,
        bInterfaceSubClass: :uint8_t,
        bInterfaceProtocol: :uint8_t,
        iInterface: :uint8_t
    }
}

# USB Standard Endpoint Descriptor
USB_ENDPOINT_DESCRIPTOR = {
    type_id: 5,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bEndpointAddress: :uint8_t,
        bmAttributes: :uint8_t,
        wMaxPacketSize: :uint16_t,
        bInterval: :uint8_t
    }
}

# USB 2.0 Device Qualifier Descriptor
USB_DEVICE_QUALIFIER_DESCRIPTOR = {
    type_id: 6,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bcdUSB: :uint16_t,
        bDeviceClass: :uint8_t,
        bDeviceSubClass: :uint8_t,
        bDeviceProtocol: :uint8_t,
        bMaxPacketSize0: :uint8_t,
        bNumConfigurations: :uint8_t,
        bReserved: :uint8_t
    }
}

# USB Standard Interface Association Descriptor
USB_INTERFACE_ASSOCIATION_DESCRIPTOR = {
    type_id: 11,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bFirstInterface: :uint8_t,
        bInterfaceCount: :uint8_t,
        bFunctionClass: :uint8_t,
        bFunctionSubClass: :uint8_t,
        bFunctionProtocol: :uint8_t,
        iFunction: :uint8_t
    }
}

# CDC functional Descriptor
CDC_HEADER_DESCRIPTOR = {
    type_id: 0x24,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bDescriptorSubtype: :uint8_t,
        bcdCDC: :uint16_t
    }
}
CDC_CALL_MANAGEMENT_DESCRIPTOR = {
    type_id: 0x24,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bDescriptorSubtype: :uint8_t,
        bmCapabilities: :uint8_t,
        bDataInterface: :uint8_t
    }
}
CDC_ABSTRACT_CONTROL_MANAGEMENT_DESCRIPTOR = {
    type_id: 0x24,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bDescriptorSubtype: :uint8_t,
        bmCapabilities: :uint8_t
    }
}
CDC_UNION_DESCRIPTOR_1SLAVE = {
    type_id: 0x24,
    fields: {
        bLength: :uint8_t,
        bDescriptorType: :uint8_t,
        bDescriptorSubtype: :uint8_t,
        bMasterInterface: :uint8_t,
        bSlaveInterface: :uint8_t
    }
}

USB_DEVICE_CLASS_RESERVED           = 0x00
USB_DEVICE_CLASS_AUDIO              = 0x01
USB_DEVICE_CLASS_COMMUNICATIONS     = 0x02
USB_DEVICE_CLASS_HUMAN_INTERFACE    = 0x03
USB_DEVICE_CLASS_MONITOR            = 0x04
USB_DEVICE_CLASS_PHYSICAL_INTERFACE = 0x05
USB_DEVICE_CLASS_POWER              = 0x06
USB_DEVICE_CLASS_PRINTER            = 0x07
USB_DEVICE_CLASS_STORAGE            = 0x08
USB_DEVICE_CLASS_HUB                = 0x09
USB_DEVICE_CLASS_MISCELLANEOUS      = 0xEF
USB_DEVICE_CLASS_VENDOR_SPECIFIC    = 0xFF

USB_ENDPOINT_TYPE_CONTROL            = 0x00
USB_ENDPOINT_TYPE_ISOCHRONOUS        = 0x01
USB_ENDPOINT_TYPE_BULK               = 0x02
USB_ENDPOINT_TYPE_INTERRUPT          = 0x03
USB_ENDPOINT_SYNC_MASK               = 0x0C
USB_ENDPOINT_SYNC_NO_SYNCHRONIZATION = 0x00
USB_ENDPOINT_SYNC_ASYNCHRONOUS       = 0x04
USB_ENDPOINT_SYNC_ADAPTIVE           = 0x08
USB_ENDPOINT_SYNC_SYNCHRONOUS        = 0x0C
USB_ENDPOINT_USAGE_MASK              = 0x30
USB_ENDPOINT_USAGE_DATA              = 0x00
USB_ENDPOINT_USAGE_FEEDBACK          = 0x10
USB_ENDPOINT_USAGE_IMPLICIT_FEEDBACK = 0x20
USB_ENDPOINT_USAGE_RESERVED          = 0x30

USB_CONFIG_BUS_POWERED   = 0x80
USB_CONFIG_SELF_POWERED  = 0xC0
USB_CONFIG_REMOTE_WAKEUP = 0x20



class Descriptor
    attr_accessor :desctype
    
    def initialize(type, &block)
        @desctype = type
        @hashfields = {bLength: 0, bDescriptorType: desctype[:type_id]}
        @appended_descriptors = []
        instance_eval &block
    end
    
    def append(desc)
        @appended_descriptors.push(desc)
    end
    
    def emit(bin, key)
        val = @hashfields[key]
        valtype = @desctype[:fields][key]
        if(valtype == :uint8_t)
            bin.push("0x%02X" % (val & 0xFF))
        elsif(valtype == :uint16_t)
            bin.push("0x%02X" % (val & 0xFF))
            bin.push("0x%02X" % ((val >> 8) & 0xFF))
        elsif(valtype == :string16_t)
            val.each_byte{|byte| bin.push("\'#{byte.chr}\'"); bin.push("\'\\0\'")}
        else
            raise "unknown type: #{valtype.to_s}, for key: #{key.to_s}"
        end
        bin
    end
    
    def type_size(val, valtype)
        if(valtype == :uint8_t)
            return 1
        elsif(valtype == :uint16_t)
            return 2
        elsif(valtype == :string16_t)
            return val.length*2
        else
            raise "unknown type: #{valtype.to_s}"
        end
    end

    def bin_length()
        desctype[:fields].keys.inject(0) {|size, key| size + type_size(@hashfields[key], desctype[:fields][key])}
    end

    def total_length()
        bin_length() + @appended_descriptors.inject(0){|total, d| total + d.total_length}
    end
    
    def method_missing(method, *args)
        if(desctype[:fields].keys.include?(method))
            @hashfields[method] = args[0]
        else
            puts "Unknown field: #{method.to_s}"
        end
    end
    
    def set_computed_fields()
        @hashfields[:bLength] = bin_length()
        if(desctype == USB_CONFIGURATION_DESCRIPTOR)
            @hashfields[:wTotalLength] = total_length()
        end
    end
    
    def to_s
        set_computed_fields()
        # (["{#{@hashfields.to_s}\n#{desctype[:fields].to_s}}"] +
        str = desctype[:fields].each_pair.map{|key, valtype|
            "#{key}: (#{valtype.to_s})#{@hashfields[key]}"
        }.join(",\n")
        (["{#{str}}"] +
            @appended_descriptors.map{|d| d.to_s}
        ).join("\n")
    end
    
    def to_hex
        set_computed_fields()
        bin = desctype[:fields].keys.inject([]) {|bin, key| emit(bin, key)}
        # ([bin.map {|x| "0x%02X" % x}.join(', ')] +
        ([bin.join(', ')] + @appended_descriptors.map{|d| d.to_hex}).join(",\n")
    end
end
