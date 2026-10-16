
################################################################
# This is a generated script based on design: top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source top_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a100tcsg324-1
   set_property BOARD_PART gamebub.org:gamebub_rev4:part0:2.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:microblaze_riscv:1.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:inline_hdl:ilconcat:1.0\
xilinx.com:ip:mdm_riscv:1.0\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
gamebub.org:ip:gamebub_esp32_v102:1.14\
xilinx.com:ip:axi_gpio:2.0\
gamebub.org:ip:gamebub_sram_mem:1.6\
gamebub.org:ip:gamebub_sdram_mem:1.6\
gamebub.org:ip:gamebub_dac_audio:1.3\
gamebub.org:ip:gamebub_lcd_axis:1.5\
xilinx.com:ip:v_tpg:8.2\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_riscv_0_local_memory
proc create_hier_cell_microblaze_riscv_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_riscv_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb [get_bd_intf_pins dlmb_v10/LMB_M] [get_bd_intf_pins DLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb_bus [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb [get_bd_intf_pins ilmb_v10/LMB_M] [get_bd_intf_pins ILMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1  [get_bd_pins SYS_Rst] \
  [get_bd_pins dlmb_v10/SYS_Rst] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins ilmb_v10/SYS_Rst] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_riscv_0_Clk  [get_bd_pins LMB_Clk] \
  [get_bd_pins dlmb_v10/LMB_Clk] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins ilmb_v10/LMB_Clk] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set mcu_qspi [ create_bd_intf_port -mode Slave -vlnv gamebub.org:interface:esp32_qspi_rtl:1.0 mcu_qspi ]

  set buttons_12bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 buttons_12bits ]

  set mcu_irq_gate [ create_bd_intf_port -mode Master -vlnv gamebub.org:interface:esp32_irq_rtl:1.0 mcu_irq_gate ]

  set vibration [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 vibration ]

  set sram [ create_bd_intf_port -mode Master -vlnv gamebub.org:interface:sram_rtl:1.0 sram ]

  set sdram [ create_bd_intf_port -mode Master -vlnv gamebub.org:interface:sdram_rtl:1.0 sdram ]

  set dac_dsp [ create_bd_intf_port -mode Master -vlnv gamebub.org:interface:dac_dsp_rtl:1.0 dac_dsp ]

  set lcd_rgb888 [ create_bd_intf_port -mode Master -vlnv gamebub.org:interface:lcd_rgb888_rtl:1.0 lcd_rgb888 ]


  # Create ports
  set clk_50mhz [ create_bd_port -dir I -type clk -freq_hz 50000000 clk_50mhz ]
  set_property -dict [ list \
   CONFIG.PHASE {0.0} \
 ] $clk_50mhz

  # Create instance: microblaze_riscv_0, and set properties
  set microblaze_riscv_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv:1.0 microblaze_riscv_0 ]
  set_property -dict [list \
    CONFIG.C_DCACHE_BASEADDR {0x0000000070000000} \
    CONFIG.C_DCACHE_BYTE_SIZE {4096} \
    CONFIG.C_DCACHE_HIGHADDR {0x000000007FFFFFFF} \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_ICACHE_BASEADDR {0x0000000070000000} \
    CONFIG.C_ICACHE_BYTE_SIZE {4096} \
    CONFIG.C_ICACHE_HIGHADDR {0x000000007FFFFFFF} \
    CONFIG.C_I_LMB {1} \
    CONFIG.C_USE_DCACHE {1} \
    CONFIG.C_USE_ICACHE {1} \
  ] $microblaze_riscv_0


  # Create instance: microblaze_riscv_0_local_memory
  create_hier_cell_microblaze_riscv_0_local_memory [current_bd_instance .] microblaze_riscv_0_local_memory

  # Create instance: microblaze_riscv_0_axi_periph, and set properties
  set microblaze_riscv_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 microblaze_riscv_0_axi_periph ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {3} \
    CONFIG.NUM_MI {8} \
    CONFIG.NUM_SI {1} \
  ] $microblaze_riscv_0_axi_periph


  # Create instance: microblaze_riscv_0_axi_intc, and set properties
  set microblaze_riscv_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_riscv_0_axi_intc ]
  set_property CONFIG.C_HAS_FAST {1} $microblaze_riscv_0_axi_intc


  # Create instance: microblaze_riscv_0_xlconcat, and set properties
  set microblaze_riscv_0_xlconcat [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 microblaze_riscv_0_xlconcat ]
  set_property CONFIG.NUM_PORTS {1} $microblaze_riscv_0_xlconcat


  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm_riscv:1.0 mdm_1 ]
  set_property -dict [list \
    CONFIG.C_ADDR_SIZE {32} \
    CONFIG.C_M_AXI_ADDR_WIDTH {32} \
    CONFIG.C_USE_UART {1} \
  ] $mdm_1


  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {200.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {162.035} \
    CONFIG.CLKOUT1_PHASE_ERROR {164.985} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {142.107} \
    CONFIG.CLKOUT2_PHASE_ERROR {164.985} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {192.113} \
    CONFIG.CLKOUT3_PHASE_ERROR {164.985} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {50.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {BUFG} \
    CONFIG.CLKOUT5_DRIVES {BUFG} \
    CONFIG.CLKOUT6_DRIVES {BUFG} \
    CONFIG.CLKOUT7_DRIVES {BUFG} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {clk_50mhz} \
    CONFIG.CLK_OUT1_PORT {clk_out100} \
    CONFIG.CLK_OUT2_PORT {clk_out200} \
    CONFIG.CLK_OUT3_PORT {clk_out50} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {20} \
    CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {10} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {5} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {20} \
    CONFIG.MMCM_COMPENSATION {ZHOLD} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIMITIVE {PLL} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_1


  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]

  # Create instance: gamebub_esp32_v102_0, and set properties
  set gamebub_esp32_v102_0 [ create_bd_cell -type ip -vlnv gamebub.org:ip:gamebub_esp32_v102:1.14 gamebub_esp32_v102_0 ]
  set_property -dict [list \
    CONFIG.BUTTONS_BOARD_INTERFACE {buttons_12bits} \
    CONFIG.C_ENABLE_CPU_OVERLAY {true} \
    CONFIG.C_ENABLE_OVERLAY_AXIS {true} \
    CONFIG.IRQ_BOARD_INTERFACE {mcu_irq_gate} \
    CONFIG.QSPI_BOARD_INTERFACE {mcu_qspi} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $gamebub_esp32_v102_0


  # Create instance: rst_clk_wiz_1_200M, and set properties
  set rst_clk_wiz_1_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_200M ]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.GPIO_BOARD_INTERFACE {vibration} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_gpio_0


  # Create instance: gamebub_sram_mem_0, and set properties
  set gamebub_sram_mem_0 [ create_bd_cell -type ip -vlnv gamebub.org:ip:gamebub_sram_mem:1.6 gamebub_sram_mem_0 ]
  set_property -dict [list \
    CONFIG.SRAM_BOARD_INTERFACE {sram} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $gamebub_sram_mem_0


  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {2} \
  ] $axi_smc


  # Create instance: gamebub_sdram_mem_0, and set properties
  set gamebub_sdram_mem_0 [ create_bd_cell -type ip -vlnv gamebub.org:ip:gamebub_sdram_mem:1.6 gamebub_sdram_mem_0 ]
  set_property -dict [list \
    CONFIG.SDRAM_BOARD_INTERFACE {sdram} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $gamebub_sdram_mem_0


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT1_JITTER {355.609} \
    CONFIG.CLKOUT1_PHASE_ERROR {391.866} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {29.362} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {56.375} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {32.000} \
    CONFIG.MMCM_DIVCLK_DIVIDE {3} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0


  # Create instance: gamebub_dac_audio_0, and set properties
  set gamebub_dac_audio_0 [ create_bd_cell -type ip -vlnv gamebub.org:ip:gamebub_dac_audio:1.3 gamebub_dac_audio_0 ]
  set_property -dict [list \
    CONFIG.AUDIO_BOARD_INTERFACE {dac_dsp} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $gamebub_dac_audio_0


  # Create instance: rst_clk_wiz_0_29M, and set properties
  set rst_clk_wiz_0_29M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_0_29M ]

  # Create instance: gamebub_lcd_axis_0, and set properties
  set gamebub_lcd_axis_0 [ create_bd_cell -type ip -vlnv gamebub.org:ip:gamebub_lcd_axis:1.5 gamebub_lcd_axis_0 ]
  set_property -dict [list \
    CONFIG.C_ENABLE_OVERLAY {1} \
    CONFIG.LCD_BOARD_INTERFACE {lcd_rgb888} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $gamebub_lcd_axis_0


  # Create instance: v_tpg_0, and set properties
  set v_tpg_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tpg:8.2 v_tpg_0 ]
  set_property -dict [list \
    CONFIG.MAX_COLS {480} \
    CONFIG.MAX_ROWS {800} \
  ] $v_tpg_0


  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {4096} \
    CONFIG.IS_ACLK_ASYNC {1} \
  ] $axis_data_fifo_0


  # Create interface connections
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports vibration] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins gamebub_sram_mem_0/MEM_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins gamebub_sdram_mem_0/MEM_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins gamebub_lcd_axis_0/S_AXIS_VIDEO]
  connect_bd_intf_net -intf_net gamebub_dac_audio_0_AUDIO [get_bd_intf_ports dac_dsp] [get_bd_intf_pins gamebub_dac_audio_0/AUDIO]
  connect_bd_intf_net -intf_net gamebub_esp32_v102_0_BUTTONS [get_bd_intf_ports buttons_12bits] [get_bd_intf_pins gamebub_esp32_v102_0/BUTTONS]
  connect_bd_intf_net -intf_net gamebub_esp32_v102_0_IRQ_GATE [get_bd_intf_ports mcu_irq_gate] [get_bd_intf_pins gamebub_esp32_v102_0/IRQ_GATE]
  connect_bd_intf_net -intf_net gamebub_esp32_v102_0_M_AXIS_OVERLAY [get_bd_intf_pins gamebub_esp32_v102_0/M_AXIS_OVERLAY] [get_bd_intf_pins gamebub_lcd_axis_0/S_AXIS_OVERLAY]
  connect_bd_intf_net -intf_net gamebub_lcd_axis_0_LCD [get_bd_intf_ports lcd_rgb888] [get_bd_intf_pins gamebub_lcd_axis_0/LCD]
  connect_bd_intf_net -intf_net gamebub_sdram_mem_0_SDRAM [get_bd_intf_ports sdram] [get_bd_intf_pins gamebub_sdram_mem_0/SDRAM]
  connect_bd_intf_net -intf_net gamebub_sram_mem_0_SRAM [get_bd_intf_ports sram] [get_bd_intf_pins gamebub_sram_mem_0/SRAM]
  connect_bd_intf_net -intf_net mcu_qspi_1 [get_bd_intf_ports mcu_qspi] [get_bd_intf_pins gamebub_esp32_v102_0/QSPI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_M_AXI_DC [get_bd_intf_pins microblaze_riscv_0/M_AXI_DC] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_M_AXI_IC [get_bd_intf_pins microblaze_riscv_0/M_AXI_IC] [get_bd_intf_pins axi_smc/S01_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_dp [get_bd_intf_pins microblaze_riscv_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_riscv_0/M_AXI_DP]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M02_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M02_AXI] [get_bd_intf_pins gamebub_esp32_v102_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M03_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M03_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M04_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M04_AXI] [get_bd_intf_pins gamebub_sram_mem_0/CTRL_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M05_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M05_AXI] [get_bd_intf_pins gamebub_sdram_mem_0/CTRL_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M06_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M06_AXI] [get_bd_intf_pins gamebub_dac_audio_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_riscv_0_axi_periph_M07_AXI [get_bd_intf_pins microblaze_riscv_0_axi_periph/M07_AXI] [get_bd_intf_pins v_tpg_0/s_axi_CTRL]
  connect_bd_intf_net -intf_net microblaze_riscv_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_riscv_0_dlmb_1 [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_ilmb_1 [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_riscv_0_intc_axi [get_bd_intf_pins microblaze_riscv_0_axi_periph/M00_AXI] [get_bd_intf_pins microblaze_riscv_0_axi_intc/s_axi]
  connect_bd_intf_net -intf_net microblaze_riscv_0_interrupt [get_bd_intf_pins microblaze_riscv_0_axi_intc/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]
  connect_bd_intf_net -intf_net microblaze_riscv_0_mdm_axi [get_bd_intf_pins microblaze_riscv_0_axi_periph/M01_AXI] [get_bd_intf_pins mdm_1/S_AXI]
  connect_bd_intf_net -intf_net v_tpg_0_m_axis_video [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins v_tpg_0/m_axis_video]

  # Create port connections
  connect_bd_net -net clk_50mhz_1  [get_bd_ports clk_50mhz] \
  [get_bd_pins clk_wiz_1/clk_in1]
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins gamebub_dac_audio_0/audio_clk] \
  [get_bd_pins microblaze_riscv_0_axi_periph/aclk2] \
  [get_bd_pins rst_clk_wiz_0_29M/slowest_sync_clk] \
  [get_bd_pins gamebub_esp32_v102_0/overlay_clk] \
  [get_bd_pins gamebub_lcd_axis_0/pixel_clk] \
  [get_bd_pins axis_data_fifo_0/m_axis_aclk]
  connect_bd_net -net clk_wiz_0_locked  [get_bd_pins clk_wiz_0/locked] \
  [get_bd_pins rst_clk_wiz_0_29M/dcm_locked] \
  [get_bd_pins rst_clk_wiz_0_29M/ext_reset_in]
  connect_bd_net -net clk_wiz_1_clk_out50  [get_bd_pins clk_wiz_1/clk_out50] \
  [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net clk_wiz_1_clk_out200  [get_bd_pins clk_wiz_1/clk_out200] \
  [get_bd_pins gamebub_esp32_v102_0/service_clk] \
  [get_bd_pins microblaze_riscv_0_axi_periph/aclk1] \
  [get_bd_pins rst_clk_wiz_1_200M/slowest_sync_clk] \
  [get_bd_pins gamebub_sdram_mem_0/refclk200]
  connect_bd_net -net clk_wiz_1_locked  [get_bd_pins clk_wiz_1/locked] \
  [get_bd_pins rst_clk_wiz_1_100M/dcm_locked] \
  [get_bd_pins rst_clk_wiz_1_200M/dcm_locked] \
  [get_bd_pins rst_clk_wiz_1_200M/ext_reset_in] \
  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net gamebub_esp32_v102_0_cpu_irq  [get_bd_pins gamebub_esp32_v102_0/cpu_irq] \
  [get_bd_pins microblaze_riscv_0_xlconcat/In0]
  connect_bd_net -net mdm_1_debug_sys_rst  [get_bd_pins mdm_1/Debug_SYS_Rst] \
  [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_riscv_0_Clk  [get_bd_pins clk_wiz_1/clk_out100] \
  [get_bd_pins microblaze_riscv_0/Clk] \
  [get_bd_pins microblaze_riscv_0_axi_periph/aclk] \
  [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] \
  [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] \
  [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] \
  [get_bd_pins mdm_1/S_AXI_ACLK] \
  [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins gamebub_sram_mem_0/host_clk] \
  [get_bd_pins axi_smc/aclk] \
  [get_bd_pins gamebub_sdram_mem_0/host_clk] \
  [get_bd_pins v_tpg_0/ap_clk] \
  [get_bd_pins axis_data_fifo_0/s_axis_aclk]
  connect_bd_net -net microblaze_riscv_0_intr  [get_bd_pins microblaze_riscv_0_xlconcat/dout] \
  [get_bd_pins microblaze_riscv_0_axi_intc/intr]
  connect_bd_net -net rst_clk_wiz_0_29M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_0_29M/peripheral_aresetn] \
  [get_bd_pins gamebub_dac_audio_0/audio_resetn] \
  [get_bd_pins gamebub_esp32_v102_0/overlay_resetn] \
  [get_bd_pins gamebub_lcd_axis_0/pixel_resetn] \
  [get_bd_pins gamebub_dac_audio_0/stop_n]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset  [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] \
  [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset  [get_bd_pins rst_clk_wiz_1_100M/mb_reset] \
  [get_bd_pins microblaze_riscv_0/Reset] \
  [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] \
  [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] \
  [get_bd_pins mdm_1/S_AXI_ARESETN] \
  [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins gamebub_sram_mem_0/host_resetn] \
  [get_bd_pins axi_smc/aresetn] \
  [get_bd_pins gamebub_sdram_mem_0/host_resetn] \
  [get_bd_pins v_tpg_0/ap_rst_n] \
  [get_bd_pins axis_data_fifo_0/s_axis_aresetn]
  connect_bd_net -net rst_clk_wiz_1_200M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_1_200M/peripheral_aresetn] \
  [get_bd_pins gamebub_esp32_v102_0/service_resetn] \
  [get_bd_pins gamebub_sdram_mem_0/ref_resetn]

  # Create address segments
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_dac_audio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_esp32_v102_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_sdram_mem_0/CTRL_AXI/Control] -force
  assign_bd_address -offset 0x78000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_sdram_mem_0/MEM_AXI/Mem] -force
  assign_bd_address -offset 0x76000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_sram_mem_0/MEM_AXI/Mem] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs gamebub_sram_mem_0/CTRL_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs mdm_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs v_tpg_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x78000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Instruction] [get_bd_addr_segs gamebub_sdram_mem_0/MEM_AXI/Mem] -force
  assign_bd_address -offset 0x76000000 -range 0x00080000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Instruction] [get_bd_addr_segs gamebub_sram_mem_0/MEM_AXI/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00004000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Instruction] [get_bd_addr_segs microblaze_riscv_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


