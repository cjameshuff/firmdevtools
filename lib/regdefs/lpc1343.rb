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

require 'regdefs/regdefs'

################################################################################

LPC13XX_PMU_PROTO = def_periph(-1, "PMU") {
    reg32(:PCON,   0x000, :rw, {DPDEN:1, SLEEPFLAG:8, DPDFLAG:11})
    reg32(:GPREG0, 0x004, :rw, {GPDATA:0..31})
    reg32(:GPREG1, 0x008, :rw, {GPDATA:0..31})
    reg32(:GPREG2, 0x00C, :rw, {GPDATA:0..31})
    reg32(:GPREG3, 0x010, :rw, {GPDATA:0..31})
    reg32(:GPREG4, 0x014, :rw, {WAKEUPHYS:10, GPDATA:11..31})
}

################################################################################

LPC13XX_SYSCON_PROTO = def_periph(-1, "SYSCON") {
    reg32(:SYSMEMREMAP,   0x000, :rw, {MAP:0..1})
    reg32(:PRESETCTRL,    0x004, :rw, {SSP0_RST_N:0, I2C_RST_N:1, SSP1_RST_N:2})
    reg32(:SYSPLLCTRL,    0x008, :rw, {MSEL:0..4, PSEL:5..6})
    reg32(:SYSPLLSTAT,    0x00C, :r, {LOCK:0})
    reg32(:USBPLLCTRL,    0x010, :rw, {MSEL:0..4, PSEL:5..6})
    reg32(:USBPLLSTAT,    0x014, :r, {LOCK:0})
    defreg(:SYSMEMREMAP) {vals(:MAP, BOOTLOADER:0, USER_RAM:1, USER_FLASH:2)}
    defreg(:SYSPLLCTRL) {vals(:PSEL, P1:0x1, P2:0x2, P4:0x3, P8:0x4)}
    defreg(:USBPLLCTRL) {vals(:PSEL, P1:0x1, P2:0x2, P4:0x3, P8:0x4)}

    reg32(:SYSOSCCTRL,    0x020, :rw, {BYPASS:0, FREQRANGE:1})
    reg32(:WDTOSCCTRL,    0x024, :rw, {DIVSEL:0..4, FREQSEL:5..8})
    reg32(:IRCCTRL,       0x02C, :rw, {TRIM:0..7})
    defreg(:SYSOSCCTRL) {vals(:FREQRANGE, FREQRANGE_1_20MHz:0, FREQRANGE_15_25MHz:1)}
    defreg(:WDTOSCCTRL) {
        vals(:FREQSEL,
            FREQ0_5MHz: 0x1,
            FREQ0_8MHz: 0x2,
            FREQ1_1MHz: 0x3,
            FREQ1_4MHz: 0x4,
            FREQ1_6MHz: 0x5,
            FREQ1_8MHz: 0x6,
            FREQ2_0MHz: 0x7,
            FREQ2_2MHz: 0x8,
            FREQ2_4MHz: 0x9,
            FREQ2_6MHz: 0xA,
            FREQ2_7MHz: 0xB,
            FREQ2_9MHz: 0xC,
            FREQ3_1MHz: 0xD,
            FREQ3_2MHz: 0xE,
            FREQ3_4MHz: 0xF)
    }
    
    reg32(:SYSRESSTAT,    0x030, :r, {POR:0, EXTRST:1, WDT:2, POD:3, SYSRST:4})

    reg32(:SYSPLLCLKSEL,  0x040, :rw, {SEL:0..1})
    reg32(:SYSPLLCLKUEN,  0x044, :rw, {ENA: 0})
    reg32(:USBPLLCLKSEL,  0x048, :rw, {SEL:0..1})
    reg32(:USBPLLCLKUEN,  0x04C, :rw, {ENA: 0})
    
    defreg(:SYSPLLCLKSEL) {vals(:SEL, IRCOSC: 0x0, SYSOSC: 0x1)}
    defreg(:USBPLLCLKSEL) {vals(:SEL, IRCOSC: 0x0, SYSOSC: 0x1)}
    
    reg32(:MAINCLKSEL,    0x070, :rw, {SEL:0..1})
    reg32(:MAINCLKUEN,    0x074, :rw, {ENA:0})
    reg32(:SYSAHBCLKDIV,  0x078, :rw, {DIV:0..7})
    
    defreg(:MAINCLKSEL) {vals(:SEL, IRCOSC: 0x0, SYSPLLIN: 0x1, WDTOSC: 0x2, SYSPLLOUT: 0x3)}

    reg32(:SYSAHBCLKCTRL, 0x080, :rw, {SYS:0, ROM:1, RAM:2, FLASHREG:3, FLASHARRAY:4,
        I2C:5, GPIO:6, CT16B0:7, CT16B1:8, CT32B0:9, CT32B1:10, SSP0:11, UART:12,
        ADC:13, USB_REG:14, WDT:15, IOCON:16, SSP1:18})

    reg32(:SSP0CLKDIV,    0x094, :rw, {DIV:0..7})
    reg32(:UARTCLKDIV,    0x098, :rw, {DIV:0..7})
    reg32(:SSP1CLKDIV,    0x09C, :rw, {DIV:0..7})

    reg32(:TRACECLKDIV,   0x0AC, :rw, {DIV:0..7})
    reg32(:SYSTICKCLKDIV, 0x0B0, :rw, {DIV:0..7})

    reg32(:USBCLKSEL,     0x0C0, :rw, {SEL:0..1})
    reg32(:USBCLKUEN,     0x0C4, :rw, {ENA:0})
    reg32(:USBCLKDIV,     0x0C8, :rw, {DIV:0..7})
    
    defreg(:USBCLKSEL) {vals(:SEL, USBPLL: 0x0, MAINCLK: 0x1)}

    reg32(:WDTCLKSEL,     0x0D0, :rw, {SEL:0..1})
    reg32(:WDTCLKUEN,     0x0D4, :rw, {ENA:0})
    reg32(:WDTCLKDIV,     0x0D8, :rw, {DIV:0..7})
    
    defreg(:WDTCLKSEL) {vals(:SEL, IRCOSC: 0x0, MAINCLK: 0x1, WDTOSC: 0x2)}

    reg32(:CLKOUTCLKSEL,  0x0E0, :rw, {SEL:0..1})
    reg32(:CLKOUTUEN,     0x0E4, :rw, {ENA:0})
    reg32(:CLKOUTDIV,     0x0E8, :rw, {DIV:0..7})
    
    defreg(:CLKOUTCLKSEL) {vals(:SEL, IRCOSC: 0x0, SYSOSC: 0x1, WDTOSC: 0x2, MAINCLK: 0x3)}

    reg32(:PIOPORCAP0,    0x100, :r, {CAPPIO0:0..11, CAPPIO1:12..23, CAPPIO2:24..31})
    reg32(:PIOPORCAP1,    0x104, :r, {CAPPIO2:0..3, CAPPIO3:4..9})
    
    # defreg(:PIOPORCAP0) {
    #     (0..11).each {|pio| flag("CAPPIO0_#{pio}", pio)}
    #     (0..11).each {|pio| flag("CAPPIO1_#{pio}", (pio+12))}
    #     (0..7).each {|pio| flag("CAPPIO2_#{pio}", (pio+24))}
    # }
    # defreg(:PIOPORCAP1) {
    #     (0..3).each {|pio| flag("CAPPIO2_#{pio+8}", pio)}
    #     (0..5).each {|pio| flag("CAPPIO3_#{pio}", (pio+4))}
    # }

    reg32(:BODCTRL,       0x150, :rw, {BODRSTLEV:0..1, BODINTVAL:2..3, BODRSTENA:4})
    # Note: user.manual.lpc13xx.pdf has SYSTCKCAL at offset 0x154, LPC13xx.h in CMSISv2p00
    # has it at offset 0x158.
    reg32(:SYSTCKCAL,     0x154, :rw, {CAL:0..25})
    defreg(:BODCTRL) {
        # See datasheet for full details on thresholds
        vals(:BODRSTLEV, RSTLEV1_49V: 0x0, RSTLEV2_06V: 0x1, RSTLEV2_35V: 0x2, RSTLEV2_63V: 0x3)
        vals(:BODINTVAL, INTLEV1_69V: 0x0, INTLEV2_29V: 0x1, INTLEV2_59V: 0x2, INTLEV2_87V: 0x3)
    }

    reg32(:STARTAPRP0,    0x200, :rw, {APRPIO0:0..11, APRPIO1:12..23, APRPIO2:24..31})
    reg32(:STARTERP0,     0x204, :rw, {ERPIO0:0..11, ERPIO1:12..23, ERPIO2:24..31})
    reg32(:STARTRSRP0CLR, 0x208, :w, {RSRPIO0:0..11, RSRPIO1:12..23, RSRPIO2:24..31})
    reg32(:STARTSRP0,     0x20C, :r, {SRPIO0:0..11, SRPIO1:12..23, SRPIO2:24..31})
    reg32(:STARTAPRP1,    0x210, :rw, {APRPIO2:0..3, APRPIO3:4..7})
    reg32(:STARTERP1,     0x214, :rw, {ERPIO2:0..3, ERPIO3:4..7})
    reg32(:STARTRSRP1CLR, 0x218, :w, {RSRPIO2:0..3, RSRPIO3:4..7})
    reg32(:STARTSRP1,     0x21C, :r, {SRPIO2:0..3, SRPIO3:4..7})
    # reg32(:STARTAPRP0,    0x200, :rw)
    # reg32(:STARTERP0,     0x204, :rw)
    # reg32(:STARTRSRP0CLR, 0x208, :w)
    # reg32(:STARTSRP0,     0x20C, :r)
    # reg32(:STARTAPRP1,    0x210, :rw)
    # reg32(:STARTERP1,     0x214, :rw)
    # reg32(:STARTRSRP1CLR, 0x218, :w)
    # reg32(:STARTSRP1,     0x21C, :r)
    # defreg(:STARTAPRP0) {
    #     (0..11).each {|pio| flag(pio, "APRPIO0_#{pio}")}
    #     (0..11).each {|pio| flag((pio+12), "APRPIO1_#{pio}")}
    #     (0..7).each {|pio| flag((pio+24), "APRPIO2_#{pio}")}
    # }
    # defreg(:STARTERP0) {
    #     (0..11).each {|pio| flag(pio, "ERPIO0_#{pio}")}
    #     (0..11).each {|pio| flag((pio+12), "ERPIO1_#{pio}")}
    #     (0..7).each {|pio| flag((pio+24), "ERPIO2_#{pio}")}
    # }
    # defreg(:STARTRSRP0CLR) {
    #     (0..11).each {|pio| flag(pio, "RSRPIO0_#{pio}")}
    #     (0..11).each {|pio| flag((pio+12), "RSRPIO1_#{pio}")}
    #     (0..7).each {|pio| flag((pio+24), "RSRPIO2_#{pio}")}
    # }
    # defreg(:STARTSRP0) {
    #     (0..11).each {|pio| flag(pio, "SRPIO0_#{pio}")}
    #     (0..11).each {|pio| flag((pio+12), "SRPIO1_#{pio}")}
    #     (0..7).each {|pio| flag((pio+24), "SRPIO2_#{pio}")}
    # }
    # defreg(:STARTAPRP1) {
    #     (0..3).each {|pio| flag(pio, "APRPIO2_#{pio+8}")}
    #     (0..3).each {|pio| flag((pio+4), "APRPIO3_#{pio}")}
    # }
    # defreg(:STARTERP1) {
    #     (0..3).each {|pio| flag(pio, "ERPIO2_#{pio+8}")}
    #     (0..3).each {|pio| flag((pio+4), "ERPIO3_#{pio}")}
    # }
    # defreg(:STARTRSRP1CLR) {
    #     (0..3).each {|pio| flag(pio, "RSRPIO2_#{pio+8}")}
    #     (0..3).each {|pio| flag((pio+4), "RSRPIO3_#{pio}")}
    # }
    # defreg(:STARTSRP1) {
    #     (0..3).each {|pio| flag(pio, "SRPIO2_#{pio+8}")}
    #     (0..3).each {|pio| flag((pio+4), "SRPIO3_#{pio}")}
    # }

    reg32(:PDSLEEPCFG,    0x230, :rw, {BOD_PD:3, WDTOSC_PD:6})
    reg32(:PDAWAKECFG,    0x234, :rw, {IRCOUT_PD:0, IRC_PD:1, FLASH_PD:2, BOD_PD:3, ADC_PD:4, SYSOSC_PD:5,
        WDTOSC_PD:6, SYSPLL_PD:7, USBPLL_PD:8, USBPAD_PD:10, FIXEDVAL:11})
    # note: FIXEDVAL bit must always be set
    reg32(:PDRUNCFG,      0x238, :rw, {IRCOUT_PD:0, IRC_PD:1, FLASH_PD:2, BOD_PD:3, ADC_PD:4, SYSOSC_PD:5,
        WDTOSC_PD:6, SYSPLL_PD:7, USBPLL_PD:8, USBPAD_PD:10, FIXEDVAL:11})
    # note: FIXEDVAL bit must always be set
    
    defreg(:PDSLEEPCFG) {vals(:_, WDON_BODON: 0x0FB7, WDOFF_BODON: 0x0FF7, WDON_BODOFF: 0x0FBF, WDOFF_BODOFF: 0x0FFF)}

    reg32(:DEVICE_ID,     0x3F4, :r, {DEVICEID:0..31})
}

################################################################################

# LPC13XX_NVIC_PROTO = def_periph(-1, "NVIC") {
#     reg32(:ISER0, 0x100, :rw)
#     reg32(:ISER1, 0x104, :rw)
#     reg32(:ICER0, 0x180, :rw)
#     reg32(:ICER1, 0x184, :rw)
#     reg32(:ISPR0, 0x200, :rw)
#     reg32(:ISPR1, 0x204, :rw)
#     reg32(:ICPR0, 0x280, :rw)
#     reg32(:ICPR1, 0x284, :rw)
#     reg32(:IABR0, 0x300, :r)
#     reg32(:IABR1, 0x300, :r)
#     (0..14).each {|r| reg32("IPR#{r}", 0x400 + r*4, :rw)}
#     reg32(:STIR, 0xF00, :w)
#     reg32(:NVIC0, 0x000, :none)
#     reg32(:NVIC1, 0x000, :none)
#     defreg(:NVIC0) {
#         (0..11).each {|p| flag(p, "PIO0_#{p}")}
#         (0..11).each {|p| flag((p + 12), "PIO1_#{p}")}
#         (0..7).each {|p| flag((p + 24), "PIO2_#{p}")}
#     }
#     defreg(:NVIC1) {
#         (8..11).each {|p| flag((p - 8), "PIO2_#{p}")}
#         (0..3).each {|p| flag((p + 4), "PIO3_#{p}")}
#         %w(
#             I2C0 CT16B0 CT16B1 CT32B0 CT32B1
#             SSP0 UART USBIRQ USBFRQ ADC WDT BOD RESERVED
#             PIO_3 PIO_2 PIO_1 PIO_0 SSP1
#         ).each_with_index {|i, b| flag((b + 8), i)}
#     }
# }

################################################################################

LPC13XX_IOCON_PROTO = def_periph(-1, "IOCON") {
    reg32(:PIO,   0x000, :none) # Dummy to generate generic definitions
    reg32(:PIO2_6,  0x000, :rw)
    
    reg32(:PIO2_0,  0x008, :rw)
    reg32(:PIO0_0,  0x00C, :rw)
    reg32(:PIO0_1,  0x010, :rw)
    
    reg32(:PIO1_8,  0x014, :rw)
    
    reg32(:PIO0_2,  0x01C, :rw)
    
    reg32(:PIO2_7,  0x020, :rw)
    reg32(:PIO2_8,  0x024, :rw)
    reg32(:PIO2_1,  0x028, :rw)
    reg32(:PIO0_3,  0x02C, :rw)
    reg32(:PIO0_4,  0x030, :rw)
    reg32(:PIO0_5,  0x034, :rw)
    reg32(:PIO1_9,  0x038, :rw)
    reg32(:PIO3_4,  0x03C, :rw)
    reg32(:PIO2_4,  0x040, :rw)
    reg32(:PIO2_5,  0x044, :rw)
    reg32(:PIO3_5,  0x048, :rw)
    reg32(:PIO0_6,  0x04C, :rw)
    reg32(:PIO0_7,  0x050, :rw)
    reg32(:PIO2_9,  0x054, :rw)
    reg32(:PIO2_10, 0x058, :rw)
    reg32(:PIO2_2,  0x05C, :rw)
    reg32(:PIO0_8,  0x060, :rw)
    reg32(:PIO0_9,  0x064, :rw)
    
    reg32(:PIO0_10, 0x068, :rw)
    
    reg32(:PIO1_10, 0x06C, :rw)
    
    reg32(:PIO2_11, 0x070, :rw)
    reg32(:PIO0_11, 0x074, :rw)
    reg32(:PIO1_0,  0x078, :rw)
    
    reg32(:PIO1_1,  0x07C, :rw)
    reg32(:PIO1_2,  0x080, :rw)
    
    reg32(:PIO3_0,  0x084, :rw)
    reg32(:PIO3_1,  0x088, :rw)
    reg32(:PIO2_3,  0x08C, :rw)
    reg32(:PIO1_3,  0x090, :rw)
    
    reg32(:PIO1_4,  0x094, :rw)
    reg32(:PIO1_11, 0x098, :rw)
    reg32(:PIO3_2,  0x09C, :rw)
    reg32(:PIO1_5,  0x0A0, :rw)
    reg32(:PIO1_6,  0x0A4, :rw)
    reg32(:PIO1_7,  0x0A8, :rw)
    reg32(:PIO3_3,  0x0AC, :rw)
    reg32(:SCK0_LOC,0x0B0, :rw, {LOC:0..1})
    reg32(:DSR_LOC, 0x0B4, :rw, {LOC:0..1})
    reg32(:DCD_LOC, 0x0B8, :rw, {LOC:0..1})
    reg32(:RI_LOC,  0x0BC, :rw, {LOC:0..1})
    
    # The FUNC values are very pin-specific, but the other fields can be grouped into
    # three basic types of GPIO pins...plain GPIO, GPIO with analog, and I2C
    # General purpose pins...all but pin 0_4 and 0_5
    [
        :PIO,
        :PIO0_0, :PIO0_1, :PIO0_2, :PIO0_3, :PIO0_10, :PIO0_11,
        :PIO1_0, :PIO1_1, :PIO1_2, :PIO1_3, :PIO1_4, :PIO1_5, :PIO1_6, :PIO1_7, :PIO1_8, :PIO1_9, :PIO1_10, :PIO1_11,
        :PIO2_0, :PIO2_1, :PIO2_2, :PIO2_3, :PIO2_4, :PIO2_5, :PIO2_6, :PIO2_7, :PIO2_8, :PIO2_9, :PIO2_10, :PIO2_11,
        :PIO3_0, :PIO3_1, :PIO3_2, :PIO3_3, :PIO3_4, :PIO3_5, :PIO0_6, :PIO0_7, :PIO0_8, :PIO0_9
    ].each {|pin|
        defreg(pin) {
            field(:FUNC, 0..2)
            field(:MODE, 3..4)
            flag(:HYSTERESIS, 5)
            flag(:OPEN_DRAIN, 10)
            vals(:MODE, MODE_INACTIVE: 0, MODE_PULLDOWN: 1, MODE_PULLUP: 2, MODE_REPEATER: 3)
        }
    }
    
    # True open-drain pins, only used for SDA and SCL
    [:PIO, :PIO0_4, :PIO0_5].each {|pin|
        defreg(pin) {
            field(:FUNC, 0..1)
            field(:I2CMODE, 8..9)
            vals(:I2CMODE, I2CMODE_STANDARD_I2C: 0, I2CMODE_STANDARD_IO: 1, I2CMODE_FAST_PLUS_I2C: 2)
        }
    }
    
    # Analog input pins
    # PIO0_11: AD0, PIO1_0: AD1, PIO1_1: AD2, PIO1_2: AD3, PIO1_3: AD4
    # PIO1_4: AD5, PIO1_10: AD6, PIO1_11: AD7
    [:PIO, :PIO0_11, :PIO1_0, :PIO1_1, :PIO1_2, :PIO1_3, :PIO1_4, :PIO1_10, :PIO1_11].each {|pin|
        defreg(pin) {
            flag(:ADMODE, 7)
            vals(:ADMODE, ADMODE_ANALOG: 0, ADMODE_DIGITAL: 1)
        }
    }
    
    # Pin functions
    defreg(:PIO2_6)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_0)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DTR: 0x1, FUNC_SSEL1: 0x2)}
    defreg(:PIO0_0)  {vals(:FUNC, FUNC_RESET: 0x0, FUNC_GPIO: 0x1)}
    defreg(:PIO0_1)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_CLKOUT: 0x1, FUNC_CT32B0_MAT2: 0x2, FUNC_USB_FTOGGLE: 0x3)}
    defreg(:PIO1_8)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_CT16B1_CAP0: 0x1)}
    defreg(:PIO0_2)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_SSEL0: 0x1, FUNC_CT16B0_CAP0: 0x2)}
    defreg(:PIO2_7)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_8)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_1)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DSR: 0x1, FUNC_SCK1: 0x2)}
    defreg(:PIO0_3)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_USB_VBUS: 0x1)}
    defreg(:PIO0_4)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_I2C: 0x1, FUNC_SCL: 0x1)}
    defreg(:PIO0_5)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_I2C: 0x1, FUNC_SDA: 0x1)}
    defreg(:PIO1_9)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_CT16B1_MAT0: 0x1)}
    defreg(:PIO3_4)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_4)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_5)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO3_5)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO0_6)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_USB_CONNECT: 0x1, FUNC_SCK0: 0x2)}
    defreg(:PIO0_7)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_CTS: 0x1)}
    defreg(:PIO2_9)  {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_10) {vals(:FUNC, FUNC_GPIO: 0x0)}
    defreg(:PIO2_2)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DCD: 0x1, FUNC_MISO1: 0x2)}
    defreg(:PIO0_8)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_MISO0: 0x1, FUNC_CT16B0_MAT0: 0x2)}
    defreg(:PIO0_9)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_MOSI0: 0x1, FUNC_CT16B0_MAT1: 0x2, FUNC_SWO: 0x3)}
    defreg(:PIO0_10) {vals(:FUNC, FUNC_SWCLK: 0x0, FUNC_GPIO: 0x1, FUNC_SCK0: 0x2, FUNC_CT16B0_MAT2: 0x3)}
    defreg(:PIO1_10) {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_AD6: 0x1, FUNC_CT16B1_MAT1: 0x2)}
    defreg(:PIO2_11) {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_SCK0: 0x1)}
    defreg(:PIO0_11) {vals(:FUNC, FUNC_GPIO: 0x1, FUNC_AD0: 0x2, FUNC_CT32B0_MAT3: 0x3)}
    defreg(:PIO1_0)  {vals(:FUNC, FUNC_GPIO: 0x1, FUNC_AD1: 0x2, FUNC_CT32B1_CAP0: 0x3)}
    defreg(:PIO1_1)  {vals(:FUNC, FUNC_GPIO: 0x1, FUNC_AD2: 0x2, FUNC_CT32B1_MAT0: 0x3)}
    defreg(:PIO1_2)  {vals(:FUNC, FUNC_GPIO: 0x1, FUNC_AD3: 0x2, FUNC_CT32B1_MAT1: 0x3)}
    defreg(:PIO3_0)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DTR: 0x1)}
    defreg(:PIO3_1)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DSR: 0x1)}
    defreg(:PIO2_3)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_RI: 0x1, FUNC_MOSI1: 0x2)}
    defreg(:PIO1_3)  {vals(:FUNC, FUNC_SWDIO: 0x0, FUNC_GPIO: 0x1, FUNC_AD4: 0x2, FUNC_CT32B1_MAT2: 0x3)}
    defreg(:PIO1_4)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_AD5: 0x1, FUNC_CT32B1_MAT3: 0x2)}
    defreg(:PIO1_11) {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_AD7: 0x1)}
    defreg(:PIO3_2)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_DCD: 0x1)}
    defreg(:PIO1_5)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_RTS: 0x1, FUNC_CT32B0_CAP0: 0x2)}
    defreg(:PIO1_6)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_RXD: 0x1, FUNC_CT32B0_MAT0: 0x2)}
    defreg(:PIO1_7)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_TXD: 0x1, FUNC_CT32B0_MAT1: 0x2)}
    defreg(:PIO3_3)  {vals(:FUNC, FUNC_GPIO: 0x0, FUNC_RI: 0x1)}
    
    # pin assignment registers
    defreg(:SCK0_LOC) {vals(:LOC, PIO0_10:0, PIO2_11:1, PIO0_6:2)}
    defreg(:DSR_LOC) {vals(:LOC, PIO2_1:0, PIO3_1:1)}
    defreg(:DCD_LOC) {vals(:LOC, PIO2_2:0, PIO3_2:1)}
    defreg(:RI_LOC) {vals(:LOC, PIO2_3:0, PIO3_3:1)}
}

################################################################################

LPC13XX_GPIO_PROTO = def_periph(0xFFFFFFFF, "GPIO") {
    # Bits 0xFFF of the index into MASKED_DATA are the mask to use when reading/writing DATA.
    reg32(:MASKED_DATA, 0x000..0x3FFB, :rw, {DATA:0..11})
    reg32(:DATA,     0x3FFC, :rw, {DATA:0..11})
    reg32(:DIR,      0x8000, :rw, {DIR:0..11})
    reg32(:IS,       0x8004, :rw, {IS:0..11})
    reg32(:IBE,      0x8008, :rw, {IBE:0..11})
    reg32(:IEV,      0x800C, :rw, {IEV:0..11})
    reg32(:IE,       0x8010, :rw, {IE:0..11})
    reg32(:RIS,      0x8014, :r, {RIS:0..11})
    reg32(:MIS,      0x8018, :r, {MIS:0..11})
    reg32(:IC,       0x801C, :w, {IC:0..11})
}

################################################################################

LPC13XX_USB_PROTO = def_periph(-1, "USB") {
    intbits = {FRAME: 0,
        EP0: 1, EP1: 2, EP2: 3, EP3: 4, EP4: 5, EP5: 6, EP6: 7, EP7: 8,
        STAT: 9, CC_EMPTY: 10, CD_FULL: 11, RxENDPKT: 12, TxENDPKT: 13
    }
    reg32(:DevInt,  0x000, :none, intbits)
    # reg32(:DevIntSt,  0x000, :r, 0..13)
    # reg32(:DevIntEn,  0x004, :rw, 0..13)
    # reg32(:DevIntClr, 0x008, :w, 0..13)
    # reg32(:DevIntSet, 0x00C, :w, 0..13)
    reg32(:DevIntSt,  0x000, :r, intbits)
    reg32(:DevIntEn,  0x004, :rw, intbits)
    reg32(:DevIntClr, 0x008, :w, intbits)
    reg32(:DevIntSet, 0x00C, :w, intbits)
    reg32(:CmdCode, 0x010, :w, {CMD_PHASE:8..15, CODE_WDATA:16..23})
    reg32(:CmdData, 0x014, :r, {CMD_RDATA:0..7})
    reg32(:RxData, 0x018, :r, {DATA:0..31})
    reg32(:TxData, 0x01C, :w, {DATA:0..31})
    reg32(:RxPLen, 0x020, :r, {PLEN:0..9, DV:10})
    reg32(:TxPLen, 0x024, :w, {PLEN:0..9})
    reg32(:Ctrl, 0x028, :rw, {RD_EN:0, WR_EN:1, LOG_ENDPOINT:2..5})
    reg32(:DevFIQSel, 0x02C, :w, {FRAME:0, BULKOUT:1, BULKIN:2})
    defreg(:CmdCode) {
        vals(:CMD_PHASE, WRITE: 0x01, READ:0x02, COMMAND:0x05)
        vals(:CODE_WDATA,
            SET_ADDRESS:        0xD0,
            CONFIGURE_DEVICE:    0xD8,
            SET_MODE:            0xF3,
            READ_IR_STATUS:      0xF4,
            READ_CURR_FRAME_NUM: 0xF5,
            READ_CHIP_ID:        0xFD,
            SET_DEVICE_STATUS:   0xFE,
            GET_DEVICE_STATUS:   0xFE,
            GET_ERROR_CODE:      0xFF,
            CLEAR_BUFFER:        0xF2,
            VALIDATE_BUFFER:     0xFA)
        (0..9).each {|ep| vals(:CODE_WDATA, "SELECT_EP#{ep}" => ep)}
        (0..7).each {|ep| vals(:CODE_WDATA, "CLEAR_IR_EP#{ep}" => 0x40 | ep)}
        (0..9).each {|ep| vals(:CODE_WDATA, "SET_STATUS_EP#{ep}" => 0x40 | ep)}
    }
}

################################################################################

LPC13XX_UART_PROTO = def_periph(-1, "UART") {
    union {
        union {
            reg32(:RBR,  0x000, :r, {RBR:0..7})
            reg32(:THR,  0x000, :w, {THR:0..7})
        }
        reg32(:DLL,  0x000, :rw, {DLLSB:0..7})
    }
    union {
        reg32(:IER,  0x004, :rw, {RBRIE:0, THREIE:1, RXLIE:2, ABEOINTEN:8, ABTOINTEN:9})
        reg32(:DLM,  0x004, :rw, {DLMSB:0..7})
    }
    union {
        reg32(:IIR,  0x008, :r, {INTSTATUS:0, INTID:1..3, FIFOEN:6..7, ABEOINT:8, ABTOINT:9})
        reg32(:FCR,  0x008, :w, {FIFOEN:0, RXFIFOR:1, TXFIFOR:2, RXTLVL:6..7})
    }
    reg32(:LCR,  0x00C, :rw, {WLS:0..1, SBS:2, PE:3, PS:4..5, BC:6, DLAB:7})
    reg32(:MCR,  0x010, :rw, {DTRCTRL:0, RTSCTRL:1, LMS:4, RTSEN:6, CTSEN:7})
    reg32(:LSR,  0x014, :r, {RDR:0, OE:1, PE:2, FE:3, BI:4, THRE:5, TEMT:6, RXFE:7})
    reg32(:MSR,  0x018, :r, {DELTACTS:0, DELTADSR:1, TERI:2, DELTADCD:3, CTS:4, DSR:5, RI:6, DCD:7})
    reg32(:SCR,  0x01C, :rw, {SCRATCHPAD:0..7})
    reg32(:ACR,  0x020, :rw, {START:0, MODE:1, AUTORESTART:2, ABEOINTCLR:8, ABTOINTCLR:9})
    reg32(:FDR,  0x028, :rw, {DIVADDVAL:0..3, MULVAL:4..7})
    reg32(:TER,  0x030, :rw, {TXEN:7})
    reg32(:RS485CTRL,  0x04C, :rw, {NMMEN:0, RXDIS:1, AADEN:2, SEL:3, DCTRL:4, OINV:5})
    reg32(:RS485ADR_MATCH,  0x050, :rw, {ADRMATCH:0..7})
    reg32(:RS485DLY,  0x054, :rw, {DLY:0..7})
    # FIFOLVL? Not listed in manual, but in LPC13xx.h
}

################################################################################

LPC13XX_I2C_PROTO = def_periph(-1, "I2C") {
    reg32(:I2C0CONSET,  0x000, :rw, {AA:2, SI:3, STO:4, STA:5, I2EN:6})
    reg32(:I2C0STAT,  0x004, :rw, {STATUS:3..7})
    reg32(:I2C0DAT,   0x008, :rw, {DATA:0..7})
    reg32(:I2C0ADR0,   0x00C, :rw, {GC:0, ADDR:1..7})
    reg32(:I2C0SCLH, 0x010, :rw, {SCLH:0..15})
    reg32(:I2C0SCLL, 0x014, :rw, {SCLL:0..15})
    reg32(:I2C0CONCLR, 0x018, :w, {AAC:2, SIC:3, STAC:5, I2ENC:6})
    reg32(:I2C0MMCTRL, 0x01C, :rw, {MM_ENA:0, ENA_SCL:1, MATCH_ALL:2})
    reg32(:I2C0ADR1, 0x020, :rw, {GC:0, ADDR:1..7})
    reg32(:I2C0ADR2, 0x024, :rw, {GC:0, ADDR:1..7})
    reg32(:I2C0ADR3, 0x028, :rw, {GC:0, ADDR:1..7})
    reg32(:I2C0DATA_BUFFER, 0x02C, :r, {DATA:0..7})
    reg32(:I2C0MASK0, 0x030, :rw, {MASK:1..7})
    reg32(:I2C0MASK1, 0x034, :rw, {MASK:1..7})
    reg32(:I2C0MASK2, 0x038, :rw, {MASK:1..7})
    reg32(:I2C0MASK3, 0x03C, :rw, {MASK:1..7})
}

################################################################################

LPC13XX_SSP_PROTO = def_periph(-1, "SSP") {
    reg32(:CR0,  0x000, :rw, {DSS:0..3, FRF:4..5, CPOL:6, CPHA:7, SCR:8..15})
    reg32(:CR1,  0x004, :rw, {LBM:0, SSE:1, MS:2, SOD:3})
    reg32(:DR,   0x008, :rw, {DATA:0..15})
    reg32(:SR,   0x00C, :r, {TFE:0, TNF:1, RNE:2, RFF:3, BSY:4})
    reg32(:CPSR, 0x010, :rw, {CPSDVSR:0..7})
    reg32(:IMSK, 0x014, :rw, {RORIM:0, RTIM:1, RXIM:2, TXIM:3})
    reg32(:RIS, 0x018, :r, {RORIS:0, RTIS:1, RXIS:2, TXIS:3})
    reg32(:MIS, 0x01C, :r, {RORMIS:0, RTMIS:1, RXMIS:2, TXMIS:3})
    reg32(:ICR, 0x020, :w, {RORIC:0, RTIC:1})
    
    defreg(:CR0) {
        (4..15).each {|ds| vals(:DSS, "DS#{ds}" => ds - 1)}
        vals(:FRF, SPI: 0, TI: 1, MICROWIRE: 2)
    }
    defreg(:CR1) {vals(:_, SLAVE: (1<<2), MASTER:0, SLAVE_NO_OUT: ((1<<2) | (1<<3)))}
}

################################################################################

LPC13XX_CT32_PROTO = def_periph(-1, "TMR") {
    reg32(:IR,  0x000, :rw, {MR0INT:0, MR1INT:1, MR2INT:2, MR3INT:3, CR0INT:4})
    reg32(:TCR, 0x004, :rw, {CEN:0, CRES:1})
    reg32(:TC,  0x008, :rw, {TC:0..31})
    reg32(:PR,  0x00C, :rw, {PR:0..31})
    reg32(:PC,  0x010, :rw, {PC:0..31})
    reg32(:MCR, 0x014, :rw, {MR0I:0, MR0R:1, MR0S:2, MR1I:3, MR1R:4, MR1S:5, MR2I:6,
        MR2R:7, MR2S:8, MR3I:9, MR3R:10, MR3S:11})
    reg32(:MR0, 0x018, :rw, {MATCH:0..31})
    reg32(:MR1, 0x01C, :rw, {MATCH:0..31})
    reg32(:MR2, 0x020, :rw, {MATCH:0..31})
    reg32(:MR3, 0x024, :rw, {MATCH:0..31})
    reg32(:CCR, 0x028, :rw, {CAP0RE:0, CAP0FE:1, CAP0I:2})
    reg32(:CR0, 0x02C, :r, {CAP:0..31})
    reg32(:EMR, 0x03C, :rw)
    reg32(:CTCR, 0x070, :rw, {CTM:0..1})
    reg32(:PWMC, 0x074, :rw, {PWMEN0:0, PWMEN1:1, PWMEN2:2, PWMEN3:3})
    
    defreg(:EMR) {
        %w{EM0 EM1 EM2 EM3}.each_with_index {|b, i| flag(b, i)}
        %w{EMC0 EMC1 EMC2 EMC3
        }.each_with_index {|b, i|
            field(b, ((i*2 + 4)..(i*2 + 5)))
            vals(b, "#{b}_NOTHING" => 0, "#{b}_CLR" => 1, "#{b}_SET" => 2, "#{b}_TOG" => 3)
        }
    }
    defreg(:CTCR) {
        vals(:CTM, PCLK_RISE:0, CAP_RISE:1, CAP_FALL:2, CAP_BOTH:3)
        # field(:CIS, 2..3) # only valid setting is 0
    }
}

################################################################################

LPC13XX_SYSTICK_PROTO = def_periph(-1, "SYSTICK") {
    reg32(:CTRL,  0x000, :rw, {ENABLE:0, TICKINT:1, CLKSOURCE:2, COUNTFLAG:16})
    reg32(:LOAD,  0x004, :rw, {RELOAD:0..23})
    reg32(:VAL,   0x008, :rw, {CURRENT:0..23})
    reg32(:CALIB, 0x00C, :r, {TENMS:0..23, SKEW:30, NOREF:31})
}
################################################################################

LPC13XX_WDT_PROTO = def_periph(-1, "WDT") {
    reg32(:WDMOD,  0x000, :rw, {WDEN:0, WDRESET:1, WDTOF:2, WDINT:3})
    reg32(:WDTC,   0x004, :rw, {COUNT:0..23})
    reg32(:WDFEED, 0x008, :w, {FEED:0..23})
    reg32(:WDTV,   0x00C, :r, {COUNT:0..23})
}
################################################################################

LPC13XX_ADC_PROTO = def_periph(-1, "ADC") {
    reg32(:ADCR,    0x000, :rw, {SEL:0..7, CLKDIV:8..15, BURST:16, CLKS:17..19, START:24..26, EDGE:27})
    reg32(:ADGDR,   0x004, :rw, {V_VREF:6..15, CHN:24..26, OVERRUN:30, DONE:31})
    reg32(:ADINTEN, 0x00C, :rw, {ADINTEN:0..7, ADGINTEN:8})
    reg32(:ADDR, 0x010..0x02F, :rw, {V_VREF:6..15, OVERRUN:30, DONE:31})
    reg32(:ADSTAT,  0x030, :r, {DONE:0..7, OVERRUN:8..15, ADINT:16})
    # defreg(:ADCR) {}
}

################################################################################
################################################################################

# A device definition is just a hash of peripherals for now.
# Many times there are multiple identical peripherals. A "dummy" peripheral with
# a base address of -1 can be used to generate generic defines for a peripheral
# class, without generating defines for accessing that specific peripheral.
# When this is done, the output can be set to registers only, to suppress
# declarations of identical field masks and values for each instance of the
# peripheral.




# memory map:
# 0x00000000-0x00002000: 8 kB Flash
# 0x00000000-0x00004000: 16 kB Flash
# 0x00000000-0x00008000: 32 kB Flash
# 0x00008000-0x10000000: reserved
# 0x10000000-0x10001000: 4 kB SRAM
# 0x10000000-0x10002000: 8 kB SRAM
# 0x10002000-0x1FFF0000: reserved
# 0x1FFF0000-0x1FFF4000: 16 kB boot ROM
# 0x1FFF4000-0x20000000: reserved
# 0x20000000-0x40000000: reserved
# 0x40000000-0x40080000: APB peripherals
# 0x40080000-0x50000000: reserved
# 0x50000000-0x50200000: AHB peripherals
# 0x50200000-0xE0000000: reserved
# 0xE0000000-0xE0100000: private peripheral bus
# 0xE0100000-0xFFFFFFFF: reserved
#
# APB peripherals:
# 0x40000000-0x40004000: I2C bus
# 0x40004000-0x40008000: WDT/WWDT
# 0x40008000-0x4000C000: UART
# 0x4000C000-0x40010000: 16-bit timer/counter 0
# 0x40010000-0x40014000: 16-bit timer/counter 1
# 0x40014000-0x40018000: 32-bit timer/counter 0
# 0x40018000-0x4001C000: 32-bit timer/counter 1
# 0x4001C000-0x40020000: ADC
# 0x40020000-0x40024000: USB (LPC1342/43 only)
# 0x40024000-0x40028000: reserved
# 0x40028000-0x40038000: reserved
# 0x40038000-0x4003C000: PMU
# 0x4003C000-0x40040000: flash controller
# 0x40040000-0x40044000: SSP0
# 0x40044000-0x40048000: IOCONFIG
# 0x40048000-0x4004C000: system control
# 0x4004C000-0x40058000: reserved
# 0x40058000-0x4005C000: SSP1
# 0x4005C000-0x40080000: reserved
#
# AHB peripherals:
# 0x50000000-0x50010000: GPIO PIO0
# 0x50010000-0x50020000: GPIO PIO1
# 0x50020000-0x50030000: GPIO PIO2
# 0x50030000-0x50040000: GPIO PIO3
# 0x50040000-0x50200000: reserved

LPC1343 = {
    PMU: LPC13XX_PMU_PROTO.merge({name: 'PMU', base: 0x40038000}),
    IOCON: LPC13XX_IOCON_PROTO.merge({name: 'IOCON', base: 0x40044000}),
    SYSCON: LPC13XX_SYSCON_PROTO.merge({name: 'SYSCON', base: 0x40048000}),
    I2C: LPC13XX_I2C_PROTO.merge({name: 'I2C', base: -1}),
    I2C0: LPC13XX_I2C_PROTO.merge({name: 'I2C0', base: 0x40000000, output: [:regs]}),
    UART: LPC13XX_UART_PROTO.merge({name: 'UART', base: -1}),
    UART0: LPC13XX_UART_PROTO.merge({name: 'UART0', base: 0x40008000, output: [:regs]}),
    USB: LPC13XX_USB_PROTO.merge({name: 'USB', base: 0x40020000}),
    SSP: LPC13XX_SSP_PROTO.merge({name: 'SSP', base: -1}),
    SSP0: LPC13XX_SSP_PROTO.merge({name: 'SSP0', base: 0x40040000, output: [:regs]}),
# 16 bit timers are identical to the 32 bit timers, they simply have different masks
# for the counts, etc.
# TODO: fix the 16-bit masks
    CT16: LPC13XX_CT32_PROTO.merge({name: 'CT16', base: -1}),
    CT16B0: LPC13XX_CT32_PROTO.merge({name: 'CT16B0', base: 0x4000C000, output: [:regs]}),
    CT16B1: LPC13XX_CT32_PROTO.merge({name: 'CT16B1', base: 0x40010000, output: [:regs]}),
    CT32: LPC13XX_CT32_PROTO.merge({name: 'CT32', base: -1}),
    CT32B0: LPC13XX_CT32_PROTO.merge({name: 'CT32B0', base: 0x40014000, output: [:regs]}),
    CT32B1: LPC13XX_CT32_PROTO.merge({name: 'CT32B1', base: 0x40018000, output: [:regs]}),
    SYSTICK: LPC13XX_SYSTICK_PROTO.merge({name: 'SYSTICK', base: 0xE0000000}),
    WDT: LPC13XX_WDT_PROTO.merge({name: 'WDT', base: 0x40004000}),
    ADC: LPC13XX_ADC_PROTO.merge({name: 'ADC', base: 0x4001C000}),
    
    GPIO: LPC13XX_GPIO_PROTO.merge({name: 'GPIO', base: -1}),
    GPIO0: LPC13XX_GPIO_PROTO.merge({name: 'GPIO0', base: 0x50000000, output: [:regs]}),
    GPIO1: LPC13XX_GPIO_PROTO.merge({name: 'GPIO1', base: 0x50010000, output: [:regs]}),
    GPIO2: LPC13XX_GPIO_PROTO.merge({name: 'GPIO2', base: 0x50020000, output: [:regs]}),
    GPIO3: LPC13XX_GPIO_PROTO.merge({name: 'GPIO3', base: 0x50030000, output: [:regs]})
    # NVIC: LPC13XX_NVIC_PROTO.merge({name: 'NVIC', base: 0xE000E000}),
    # FMC
    # SWD
}
