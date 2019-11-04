#
# PyFPGA Master Tcl
#
# Copyright (C) 2015-2019 INTI
# Copyright (C) 2015-2019 Rodrigo A. Melo <rmelo@inti.gob.ar>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Description: Tcl script to create a new project and performs synthesis,
# implementation and bitstream generation.
#
# Supported TOOLs: ise, libero, quartus, vivado
#
# Note: fpga_ is used to avoid name collisions.
#

#
# Things to tuneup (#SOMETHING#) for each project
#

global TOOL
set TOOL     #TOOL#
set PROJECT  #PROJECT#
set PART     #PART#
set TOP      #TOP#
set STRATEGY #STRATEGY#
set TASK     #TASK#

proc fpga_options { PHASE } {
    if {[catch {
        switch $PHASE {
            "project" {
#PROJECT_OPTS#
            }
            "preflow" {
#PREFLOW_OPTS#
            }
            "postsyn" {
#POSTSYN_OPTS#
            }
            "postimp" {
#POSTIMP_OPTS#
            }
            "postbit" {
#POSTBIT_OPTS#
            }
        }
    } ERRMSG]} {
        puts "ERROR: there was a problem applying your $PHASE options.\n"
        puts $ERRMSG
        exit $ERR_PHASE
    }
}

#
# Constants
#

set ERR_PROJECT 1
set ERR_PART    2
set ERR_PHASE   3
set ERR_FLOW    4

#
# Procedures for multi vendor support
#

proc fpga_create { PROJECT } {
    global TOOL
    switch $TOOL {
        "ise"     { project new $PROJECT.xise }
        "libero"  {
            new_project -name $PROJECT -location {temp-libero} -hdl {VHDL} -family {SmartFusion2}
        }
        "quartus" {
            package require ::quartus::project
            project_new $PROJECT -overwrite
        }
        "vivado"  { create_project -force $PROJECT }
    }
}

proc fpga_open { PROJECT } {
    global TOOL
    switch $TOOL {
        "ise"     { project open $PROJECT.xise }
        "libero"  {
            open_project temp-libero/$PROJECT.prjx
        }
        "quartus" {
            package require ::quartus::flow
            project_open -force $PROJECT.qpf
        }
        "vivado"  { project open $PROJECT }
    }
}

proc fpga_close {} {
    global TOOL
    switch $TOOL {
        "ise"     { project close }
        "libero"  { close_project }
        "quartus" { project_close }
        "vivado"  { close_project }
    }
}

proc fpga_part { PART } {
    global TOOL
    if {[catch {
        switch $TOOL {
            "ise"     {
                regexp -nocase {(.*)-(.*)-(.*)} $PART -> DEVICE SPEED PACKAGE
                set FAMILY "Unknown"
                if {[regexp -nocase {xc7a\d+l} $DEVICE]} {
                    set FAMILY "artix7l"
                } elseif {[regexp -nocase {xc7a} $DEVICE]} {
                    set FAMILY "artix7"
                } elseif {[regexp -nocase {xc7k\d+l} $DEVICE]} {
                    set FAMILY "kintex7l"
                } elseif {[regexp -nocase {xc7k} $DEVICE]} {
                    set FAMILY "kintex7"
                } elseif {[regexp -nocase {xc3sd\d+a} $DEVICE]} {
                    set FAMILY "spartan3adsp"
                } elseif {[regexp -nocase {xc3s\d+a} $DEVICE]} {
                    set FAMILY "spartan3a"
                } elseif {[regexp -nocase {xc3s\d+e} $DEVICE]} {
                    set FAMILY "spartan3e"
                } elseif {[regexp -nocase {xc3s} $DEVICE]} {
                    set FAMILY "spartan3"
                } elseif {[regexp -nocase {xc6s\d+l} $DEVICE]} {
                    set FAMILY "spartan6l"
                } elseif {[regexp -nocase {xc6s} $DEVICE]} {
                    set FAMILY "spartan6"
                } elseif {[regexp -nocase {xc4v} $DEVICE]} {
                    set FAMILY "virtex4"
                } elseif {[regexp -nocase {xc5v} $DEVICE]} {
                    set FAMILY "virtex5"
                } elseif {[regexp -nocase {xc6v\d+l} $DEVICE]} {
                    set FAMILY "virtex6l"
                } elseif {[regexp -nocase {xc6v} $DEVICE]} {
                    set FAMILY "virtex6"
                } elseif {[regexp -nocase {xc7v\d+l} $DEVICE]} {
                    set FAMILY "virtex7l"
                } elseif {[regexp -nocase {xc7v} $DEVICE]} {
                    set FAMILY "virtex7"
                } elseif {[regexp -nocase {xc7z} $DEVICE]} {
                    set FAMILY "zynq"
                } else {
                    puts "The family of the device $DEVICE is $FAMILY."
                }
                project set family  $FAMILY
                project set device  $DEVICE
                project set package $PACKAGE
                project set speed   $SPEED
            }
            "libero"  {
                regexp -nocase {(.*)-(.*)-(.*)} $PART -> DEVICE SPEED PACKAGE
                set FAMILY "Unknown"
                if {[regexp -nocase {m2s} $DEVICE]} {
                    set FAMILY "SmartFusion2"
                } elseif {[regexp -nocase {m2gl} $DEVICE]} {
                    set FAMILY "Igloo2"
                } elseif {[regexp -nocase {rt4g} $DEVICE]} {
                    set FAMILY "RTG4"
                } elseif {[regexp -nocase {a2f} $DEVICE]} {
                    set FAMILY "SmartFusion"
                } elseif {[regexp -nocase {afs} $DEVICE]} {
                    set FAMILY "Fusion"
                } elseif {[regexp -nocase {aglp} $DEVICE]} {
                    set FAMILY "IGLOO+"
                } elseif {[regexp -nocase {agle} $DEVICE]} {
                    set FAMILY "IGLOOE"
                } elseif {[regexp -nocase {agl} $DEVICE]} {
                    set FAMILY "IGLOO"
                } elseif {[regexp -nocase {a3p\d+l} $DEVICE]} {
                    set FAMILY "ProAsic3L"
                } elseif {[regexp -nocase {a3pe} $DEVICE]} {
                    set FAMILY "ProAsic3E"
                } elseif {[regexp -nocase {a3p} $DEVICE]} {
                    set FAMILY "ProAsic3"
                } else {
                    puts "The family of the device $DEVICE is $FAMILY."
                }
                set_device -family $FAMILY -die $DEVICE -package $PACKAGE -speed $SPEED
            }
            "quartus" {
                set_global_assignment -name DEVICE $PART
            }
            "vivado"  {
                set_property "part" $PART [current_project]
            }
        }
    } ERRMSG]} {
        puts "ERROR: there was a problem with the specified PART $PART.\n"
        puts $ERRMSG
        exit $ERR_PART
    }
}

proc fpga_file {FILE {LIB ""}} {
    global TOOL
    regexp -nocase {\.(\w*)$} $FILE -> ext
    if { $ext == "tcl" } {
        source $FILE
        return
    }
    switch $TOOL {
        "ise" {
            if { $LIB != "" } {
                lib_vhdl new $LIB
                xfile add $FILE -lib_vhdl $LIB
            } else {
                xfile add $FILE
            }
        }
        "libero" {
            if {$ext == "pdc"} {
                create_links -io_pdc $FILE
                organize_tool_files -tool {PLACEROUTE} -file $FILE -input_type {constraint}
            } elseif {$ext == "sdc"} {
                create_links -sdc $FILE
                organize_tool_files -tool {SYNTHESIZE} -file $FILE -input_type {constraint}
                organize_tool_files -tool {VERIFYTIMING} -file $FILE -input_type {constraint}
            } else {
                create_links -hdl_source $FILE
            }
            if { $LIB != "" } {
                add_library -library $LIB
                add_file_to_library -library $LIB -file $FILE
            }
        }
        "quartus" {
            if {$ext == "v"} {
                set TYPE VERILOG_FILE
            } elseif {$ext == "sv"} {
                set TYPE SYSTEMVERILOG_FILE
            } else {
                set TYPE VHDL_FILE
            }
            if { $LIB != "" } {
                set_global_assignment -name $TYPE $FILE -library $LIB
            } else {
                set_global_assignment -name $TYPE $FILE
            }
        }
        "vivado" {
            add_files $FILE
            if { $LIB != "" } {
                set_property library $LIB [get_files $FILE]
            }
        }
    }
}

proc fpga_top { TOP } {
    global TOOL
    switch $TOOL {
        "ise"     { project set top $TOP }
        "libero"  { set_root $TOP }
        "quartus" { set_global_assignment -name TOP_LEVEL_ENTITY $TOP }
        "vivado"  { set_property top $TOP [current_fileset] }
    }
}

proc fpga_area_opts {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            project set "Optimization Goal" "Area"
        }
        "libero"  {
            configure_tool -name {SYNTHESIZE} -params {RAM_OPTIMIZED_FOR_POWER:true}
        }
        "quartus" {
            set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE AREA"
            set_global_assignment -name OPTIMIZATION_TECHNIQUE AREA
        }
        "vivado"  {
            set obj [get_runs synth_1]
            set_property strategy "Flow_AreaOptimized_high" $obj
            set_property "steps.synth_design.args.directive" "AreaOptimized_high" $obj
            set_property "steps.synth_design.args.control_set_opt_threshold" "1" $obj
            set obj [get_runs impl_1]
            set_property strategy "Area_Explore" $obj
            set_property "steps.opt_design.args.directive" "ExploreArea" $obj
        }
    }
}

proc fpga_power_opts {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            project set "Optimization Goal" "Area"
            project set "Power Reduction" "true" -process "Synthesize - XST"
            project set "Power Reduction" "high" -process "Map"
            project set "Power Reduction" "true" -process "Place & Route"
        }
        "libero"  {
            configure_tool -name {SYNTHESIZE} -params {RAM_OPTIMIZED_FOR_POWER:true}
            configure_tool -name {PLACEROUTE} -params {PDPR:true}
        }
        "quartus" {
            set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE POWER"
            set_global_assignment -name OPTIMIZE_POWER_DURING_SYNTHESIS "EXTRA EFFORT"
            set_global_assignment -name OPTIMIZE_POWER_DURING_FITTING "EXTRA EFFORT"
        }
        "vivado"  {
            #enable power_opt_design and phys_opt_design
            set obj [get_runs synth_1]
            set_property strategy "Vivado Synthesis Defaults" $obj
            set obj [get_runs impl_1]
            set_property strategy "Power_DefaultOpt" $obj
            set_property "steps.power_opt_design.is_enabled" "1" $obj
            set_property "steps.phys_opt_design.is_enabled" "1" $obj
        }
    }
}

proc fpga_speed_opts {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            project set "Optimization Goal" "Speed"
        }
        "libero"  {
            configure_tool -name {SYNTHESIZE} -params {RAM_OPTIMIZED_FOR_POWER:false}
            configure_tool -name {PLACEROUTE} -params {EFFORT_LEVEL:true}
        }
        "quartus" {
            set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"
            set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
        }
        "vivado"  {
            #enable phys_opt_design
            set obj [get_runs synth_1]
            set_property strategy "Flow_PerfOptimized_high" $obj
            set_property "steps.synth_design.args.fanout_limit" "400" $obj
            set_property "steps.synth_design.args.keep_equivalent_registers" "1" $obj
            set_property "steps.synth_design.args.resource_sharing" "off" $obj
            set_property "steps.synth_design.args.no_lc" "1" $obj
            set_property "steps.synth_design.args.shreg_min_size" "5" $obj
            set obj [get_runs impl_1]
            set_property strategy "Performance_Explore" $obj
            set_property "steps.opt_design.args.directive" "Explore" $obj
            set_property "steps.place_design.args.directive" "Explore" $obj
            set_property "steps.phys_opt_design.is_enabled" "1" $obj
            set_property "steps.phys_opt_design.args.directive" "Explore" $obj
            set_property "steps.route_design.args.directive" "Explore" $obj
        }
    }
}

proc fpga_run_syn {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            process run "Synthesize" -force rerun
        }
        "libero"  {
            run_tool -name {COMPILE}
        }
        "quartus" {
            execute_module -tool map
        }
        "vivado"  {
            reset_run synth_1
            launch_runs synth_1
            wait_on_run synth_1
        }
    }
}

proc fpga_run_imp {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            process run "Translate" -force rerun
            process run "Map" -force rerun
            process run "Place & Route" -force rerun
        }
        "libero"  {
            configure_tool -name {PLACEROUTE} -params {REPAIR_MIN_DELAY:true}
            run_tool -name {PLACEROUTE}
            run_tool -name {VERIFYTIMING}
        }
        "quartus" {
            execute_module -tool fit
            execute_module -tool sta
        }
        "vivado"  {
            open_run synth_1
            launch_runs impl_1
            wait_on_run impl_1
        }
    }
}

proc fpga_run_bit {} {
    global TOOL
    switch $TOOL {
        "ise"     {
            process run "Generate Programming File" -force rerun
        }
        "libero"  {
            run_tool -name {GENERATEPROGRAMMINGFILE}
        }
        "quartus" {
            execute_module -tool asm
        }
        "vivado"  {
            open_run impl_1
            launch_run impl_1 -to_step write_bitstream
            wait_on_run impl_1
        }
    }
}

#
# Project files
#

proc fpga_files {} {
#FILES#
}

#
# Project Creation
#

if {[catch {
    fpga_create $PROJECT
    fpga_part $PART
    fpga_files
    fpga_top $TOP
    switch $STRATEGY {
        "area"  {fpga_area_opts}
        "power" {fpga_power_opts}
        "speed" {fpga_speed_opts}
    }
    fpga_options "project"
    fpga_close
} ERRMSG]} {
    puts "ERROR: there was a problem creating a new project.\n"
    puts $ERRMSG
    exit $ERR_PROJECT
}

#
# Flow
#

if {[catch {
    fpga_open $PROJECT
    fpga_options "preflow"
    if { $TASK=="syn" || $TASK=="imp" || $TASK=="bit" } {
        fpga_run_syn
        fpga_options "postsyn"
    }
    if { $TASK=="imp" || $TASK=="bit" } {
        fpga_run_imp
        fpga_options "postimp"
    }
    if { $TASK=="bit" } {
        fpga_run_bit
        fpga_options "postbit"
    }
    fpga_close
} ERRMSG]} {
    puts "ERROR: there was a problem running the flow ($TASK).\n"
    puts $ERRMSG
    exit $ERR_FLOW
}