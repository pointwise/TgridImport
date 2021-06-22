#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

###############################################################
#   Fluent Tgrid Import Script
#   This script will import a Fluent Tgrid file
#   as Gridgen surface domains.
#   The VRML file format is used as an intermediary step.
#
#   The basic process is:
#     1) Parse the Tgrid file for surface grid zone definitions.
#     2) Export each surface grid zone as a VRML file.
#     3) Import each VRML file into Gridgen as domains.
#     4) Apply the zone name as a boundary condition to
#        the relevant domains.
#     5) Perform a clean-up to remove any non-manifold
#        domain adjacency in the grid.
###############################################################

package require PWI_Glyph 2.4

#-- This script requires write permission to a temporary directory
#-- A few different places will be tried, but it will try
#-- here first.
set temp_dir [pwd]

#-- Set the script mode (gui or stand_alone)
set scriptMode "gui"
#set scriptMode "stand_alone"


#-- Set Tgrid filename
set tgrid_file "test.msh"

#-- Set domain split options
set doDomSplit 1  ;#  1=on, 0=off
set split_angle 50.0 ;# angles greater than this will cause a split

#-- To disable dom splitting on pyramid face zones,
#-- set pyramid_zone_split to 0 and define
#-- a regular expression to identify the pyramid face
#-- zones by name.
#-- These settings are ignored if dom split is disabled.
#
set pyramid_zone_split 0  ;#  1=split, 0=don't split
set pyramid_zone_regexp ".*-pyramid-.*"


#-- Some grid zones (roughly equal to domains in Gridgen) may
#-- intersect in a non-manifold way.
#-- Gridgen can not handle non-manifold domain intersections,
#-- therefore, a check is performed and domains are split to
#-- ensure that all domain intersections are manifold.
#-- This check is very expensive for large models.
#--
#-- If it is known that *only* zones marked as baffles
#-- (through zone naming) have non-manifold intersections,
#-- then we can perform the non-manifold check only on
#-- those zones which will save a lot of time.
#
set non_manifold_check_baffle_zone_only 0  ;#  0=check all zones
                                            #  1=check only baffle zones
set baffle_zone_regexp "baffle.*"  ;# zone name starts with "baffle"


#-- Tgrid zone IDs (should not need to be changed)
set dimension_zone_id 2
set node_zone_id 10
set cell_zone_id 12
set face_zone_id 13
set zoneInfo_zone_id 45
set interior_face_type 2

set script_dir [file dirname [info script]]

proc CenterWindow {w {parent ""} {xoff "0"} {yoff "0"}} {
  global tcl_platform

  if [winfo exists $parent] {
    set rootx [winfo rootx $parent]
    set rooty [winfo rooty $parent]
    set pwidth [winfo width $parent]
    set pheight [winfo height $parent]
  } else {
    set parent "."
    set rootx 0
    set rooty 0
    set pwidth [winfo screenwidth $parent]
    set pheight [winfo screenheight $parent]

    set winInfo [list $pwidth $pheight 0 0 0]
    set pwidth [lindex $winInfo 0]
    set pheight [lindex $winInfo 1]
  }

  set screenwidth [winfo screenwidth .]
  set screenheight [winfo screenheight .]

  set winInfo [list $screenwidth $screenheight 0 0 0]
  set screenwidth [lindex $winInfo 0]
  set screenheight [lindex $winInfo 1]
  set l_off [lindex $winInfo 2]
  set t_off [lindex $winInfo 3]

  update idletasks
  set wwidth [winfo reqwidth $w]
  set wheight [winfo reqheight $w]
  set x0 [expr $rootx+($pwidth-$wwidth)/2+$xoff]
  set y0 [expr $rooty+($pheight-$wheight)/2+$yoff]

  set border 4
  set maxW [expr $x0 + $wwidth + 2*$border]
  if { $maxW > $screenwidth} {
    set x0 [expr $screenwidth-$wwidth - 2*$border]
  } elseif { $x0 < 0 } {
    set x0 0
  }

  set border 4
  set maxH [expr $y0 + $wheight + 2*$border]
  if { $maxH > $screenheight} {
    set y0 [expr $screenheight-$wheight - 2*$border]
  } elseif { $y0 < 0 } {
    set y0 0
  }

  #-- allow for windows taskbar
  if { $tcl_platform(platform) == "windows" } {
    set x0 [expr $x0+$l_off]
    set y0 [expr $y0+$t_off]
  }

  wm geometry $w "+$x0+$y0"

  if {0} {
   foreach var {rootx rooty pwidth pheight wwidth wheight x0 y0} {
    set val [set $var]
    puts "$var: $val"
   }
  }
}


proc write_vrml_nodes {f} {
  global tri quad pts

  puts $f "   Coordinate3 \{"
  puts $f "      point \["
#    set line [format "%f  %f  %f" $pts($i,x) $pts($i,y) $pts($i,z)]
#    puts $f $line
  for { set i 0 } { $i < $pts(num)} {incr i} {
    puts $f "$pts($i,x) $pts($i,y) $pts($i,z)"
  }
  puts $f "      \]"
  puts $f "   \}"
}

proc write_vrml_cells {f} {
  global tri quad pts

  puts $f "   IndexedFaceSet \{"
  puts $f "      coordIndex \["
#    set line [format "%d %d %d -1" \
#       [expr $tri($i,0) -1] \
#       [expr $tri($i,1) -1] \
#       [expr $tri($i,2) -1] ]
#    puts $f $line
  for { set i 0 } { $i < $tri(num)} {incr i} {
puts $f "[expr $tri($i,0) -1] [expr $tri($i,1) -1] [expr $tri($i,2) -1] -1"
  }
#    set line [format "%d %d %d %d -1" \
#        [expr $quad($i,0)-1] \
#        [expr $quad($i,1)-1] \
#        [expr $quad($i,2)-1] \
#        [expr $quad($i,3)-1] ]
#    puts $f $line
  for { set i 0 } { $i < $quad(num)} {incr i} {
    puts $f "[expr $quad($i,0)-1] [expr $quad($i,1)-1] [expr $quad($i,2)-1] [expr $quad($i,3)-1] -1"
  }
  puts $f "      \]"
  puts $f "   \}"
}

proc write_dom_as_vrml {dom} {
  global pts tri quad total_tri total_quad
  global temp_dir

  if {$pts(num) == 0} {
    resetCellData
    return
  }

  if {$tri(num) == 0 && $quad(num) == 0} {
    resetCellData
    return
  }

  TextInsert "Writing domain..."
  update
  set outfile [file join $temp_dir "dom$dom.wrl"]
  write_vrml $outfile

  #- reset cell list
  resetCellData
  TextInsert "...done"
}

proc resetCellData {} {
  global tri quad total_tri total_quad
  #- reset cell list
  set total_tri [expr $total_tri+$tri(num)]
  set total_quad [expr $total_quad+$quad(num)]
  set tri(num) 0
  set quad(num) 0
}


proc write_vrml_stub_file {} {
  global vrml_stub_file temp_dir
  global vrml_stub_filename

  set vrml_stub_filename [file join $temp_dir "_vrmlstub.wrl"]

  if [ catch {open $vrml_stub_filename w} f ] {
    puts $f
    exit
  }
  puts $f "#VRML V1.0 ascii"
  puts $f "#Exported from TgridImport GridgenGlyph"
  puts $f "Separator \{"
  write_vrml_nodes $f
  close $f
  set vrml_stub_file 1
}


proc write_vrml {outfile} {
  global vrml_stub_file
  global vrml_stub_filename

  #-- write the stub file (header and nodes) if nec'y
  if { !$vrml_stub_file } {
    write_vrml_stub_file
  }

  #-- copy the stub file
  if [catch {file copy -force $vrml_stub_filename $outfile} msg] {
    puts $msg
    exit
  }

  #-- append cell data
  if [ catch {open $outfile a} f ] {
    puts $f
    exit
  }
  write_vrml_cells $f
  puts $f "\}"
  close $f
}


proc read_fluent_dimension {f header} {
  global fluent_file_dim

  set n [scan $header "( %d %d )" zone fluent_file_dim]

  if { $n != 2 } {
    TextInsert "Reading dimension\n bad header: $header"
    return
  }
}


proc read_fluent_nodes {f header} {
  global pts

  set n [scan $header "( %x ( %x %x %x %x %x ) (" zone zn beg end bc type]

  if { $zn == 0 } { return }
  if { $n != 6 } {
    set n [scan $header "( %x ( %x %x %x %x ) (" zone zn beg end bc]
    if { $n != 5 } {
      TextInsert "Reading nodes\n bad header: $header"
      return
    }
  }

  TextInsert "Reading nodes $beg through $end..."
  update

  if { $end > $pts(num) } { set pts(num) $end }

  for { set i [expr $beg-1]} { $i < $end } {incr i} {
     gets $f line
     set n [scan $line "%f %f %f" pts($i,x) pts($i,y) pts($i,z)]
     if {$n == 2} {
       set pts($i,z) 0.0
       set n 3
     }
     if { $n != 3 } {
       TextInsert "Bad node: $line"
       return
     }
  }
}


proc read_fluent_cells {f header} {
  global tri quad pts ncells

  set n [scan $header "( %x ( %x %x %x %x ) (" zone zn beg end type]

  if { $zn == 0 } {
    set ncells $end
    TextInsert "Reading $ncells cells"
    update
  }
  if { $n != 5 } {
    TextInsert " bad header: $header"
    return
  }
}


proc read_fluent_zoneInfo {f header} {
  global zoneInfo
  global non_manifold_check_baffle_zone_only  baffle_zone_regexp


#(45 (1 wall default-wall)())

  set nline 0
  set n [scan $header "( %d ( %d %s %s ) ())" zoneinfo zone bc name]


  set old_name ""
  while {[string compare $name $old_name] != 0} {
    set old_name $name
    set name [string trim $name]
    set name [string trim $name "("]
    set name [string trim $name ")"]
  }
  if { $n != 4 } {
    TextInsert "Reading Zone Info\n bad header: $header"
    return
  }

  set zoneInfo($zone,bc) $bc
  set zoneInfo($zone,name) $name
  set zoneInfo($zone,is_baffle) 0

  if [regexp $baffle_zone_regexp $zoneInfo($zone,name)] {
     set zoneInfo($zone,is_baffle) 1
  }

}



proc read_fluent_faces {f header} {
  global tri quad pts maxcell ncells maxpt cell
  global faceZone interior_face_type

  set nline 0
  set n [scan $header "( %x ( %x %x %x %x %x ) (" zone zn beg end bc type]

  if { $zn == 0 } { return }
  if { $n != 6 } {
    TextInsert "Reading faces\n bad header: $header"
    return
  }
  TextInsert "Reading faces $beg through $end..."
  if { $bc == $interior_face_type } {
     TextInsert "  interior face list - skipping"
     return
  }
  update

  set nzone $faceZone(num_zones)
  set faceZone($nzone,zone) $zn
  incr faceZone(num_zones)

  for { set i [expr $beg-1]} { $i < $end } {incr i} {
     gets $f line
     incr nline
     set n [scan $line "%x %x %x %x %x" v0 v1 v2 v3 v4]
     if { $n != 5 } {
       puts "bad cell: $line"
       exit
     }
     if { $type == 0 } {
       if { $v0 == 3 } {
         set n [scan $line "%x %x %x %x %x %x" v0 v1 v2 v3 v4 v5]
         if { $n != 6 } { puts "bad cell: $line"; exit }
       } elseif { $v0 == 4 } {
         set n [scan $line "%x %x %x %x %x %x %x" v0 v1 v2 v3 v4 v5 v6]
         if { $n != 7 } { puts "bad cell: $line"; exit }
       }
     } else {
       if {$type == 3 } {
       } else {
         set n [scan $line "%x %x %x %x %x %x" v0 v1 v2 v3 v4 v5]
         if { $n != 6 } { puts "bad cell: $line"; exit }
       }
     }
     if { $type == 3 } {
       #-- Triangles
       set tri($tri(num),0) $v0
       set tri($tri(num),1) $v1
       set tri($tri(num),2) $v2
       incr tri(num)
     } elseif { $type == 4 } {
       #-- Quadrangles
       set quad($quad(num),0) $v0
       set quad($quad(num),1) $v1
       set quad($quad(num),2) $v2
       set quad($quad(num),3) $v3
       incr quad(num)
     } elseif { $type == 0 } {
       #-- Mixed
       set ltype $v0
       if { $ltype == 3 } {
         #-- Triangles
         set tri($tri(num),0) $v1
         set tri($tri(num),1) $v2
         set tri($tri(num),2) $v3
         incr tri(num)
       } elseif { $ltype == 4 } {
         #-- Quadrangles
         set quad($quad(num),0) $v1
         set quad($quad(num),1) $v2
         set quad($quad(num),2) $v3
         set quad($quad(num),3) $v4
         incr quad(num)
       } else {
         puts "Bad cell type: $type"
         puts $line
         exit
       }
     } else {
       puts "Bad cell type: $type"
       puts $line
       exit
     }
  }
  TextInsert "  read $nline lines"
  update
}

proc read_fluent {infile} {
  global dimension_zone_id node_zone_id cell_zone_id face_zone_id
  global maxcell maxpt fluent_file_dim
  global zoneInfo_zone_id faceZone zoneInfo
  global pts tri quad total_tri total_quad
  global vrml_stub_file vrml_stub_filename

  GetTempDir

  set maxpt 0
  set maxcell 0
  set pts(num) 0
  set tri(num) 0
  set quad(num) 0
  set total_tri 0
  set total_quad 0
  set faceZone(num_zones) 0
  set vrml_stub_file 0

  if [ catch {open $infile r} f ] {
    puts $f
    exit
  }
  while { [gets $f line] >= 0 } {
     set zone [get_zone $line]
     if { $zone == $node_zone_id } {
#  TextInsert "Read nodes..."
        read_fluent_nodes $f $line
#  TextInsert "...done"
     } elseif { $zone == $dimension_zone_id } {
        read_fluent_dimension $f $line
        if {$fluent_file_dim != 3 } {
          TextInsert "Only 3 dimensional files are supported."
          close $f
          return 1
        }
     } elseif { $zone == $cell_zone_id } {
#  TextInsert "Read cells..."
        read_fluent_cells $f $line
#  TextInsert "...done"
     } elseif { $zone == $face_zone_id } {
#  TextInsert "Read cells..."
        set nzone $faceZone(num_zones)
        read_fluent_faces $f $line
        #-- export this list of faces as a domain
        if { $faceZone(num_zones) > $nzone } {
          write_dom_as_vrml  $faceZone(num_zones)
        }
#  TextInsert "...done"
     } elseif { $zone == $zoneInfo_zone_id } {
        read_fluent_zoneInfo $f $line
     }
  }
  close $f

  #-- cleanup stub file
  catch {file delete $vrml_stub_filename}

  return 0
}

proc get_zone {line} {

   set n [scan $line "( %d" zone]

   if { $n != 1 } {
     return 0
   }

   if ![is_integer $zone] {
     TextInsert "error zone not int: $line"
     return 0
   }
   return $zone
}

proc is_integer {num} {
  if [catch {incr num} f] {
    return 0
  }
  return 1
}


#--  Executable statements  --------------------------------
#console show

proc setState {parent state} {

  catch {$parent configure -state $state}

  set wlist [winfo children $parent]
  foreach win $wlist {
    setState $win $state
  }
}

proc import_domains {infile} {
  global msgBox scriptMode title tl
  global closeBtn
  global pts tri quad zoneInfo faceZone

  if {$scriptMode == "gui"} {
    #-- Clear text box
    $msgBox configure -state normal
    $msgBox delete 0.0 end
    $msgBox configure -state disabled
  }

  TextInsert "Import $infile...\n"

  set errRtn [convert_tgrid_file $infile]

  if $errRtn {
    set tmsg "\nImport Failed."
  } else {
    set tmsg "\nImport Complete."
    load_doms
  }

  #-- clean up
  foreach var [list pts tri quad zoneInfo faceZone] {
    catch {unset $var}
  }

  if {$scriptMode == "gui"} {
    setState $tl disabled
    $title configure -state normal
    $closeBtn configure -state normal
    $closeBtn configure -text "Close"
  }

  TextInsert $tmsg
}

proc convert_tgrid_file {infile} {
  global maxpt maxcell
  global pts tri quad zoneInfo faceZone
  global total_tri total_quad
  set maxcell 0

  set rtn [read_fluent $infile]
  if $rtn { return 1 }

  TextInsert "\nImport Summary"
  TextInsert "--------------"
  TextInsert "Read $pts(num) nodes"
  TextInsert "Read $total_tri triangles"
  TextInsert "Read $total_quad quadrangles"
  if {$faceZone(num_zones) == 0} {
    set msg "Read $faceZone(num_zones) surface zones."
  } elseif {$faceZone(num_zones) == 1} {
    set msg "Read $faceZone(num_zones) surface zone:"
  } else {
    set msg "Read $faceZone(num_zones) surface zones:"
  }
  TextInsert $msg

  if {$pts(num) == 0} {
    TextInsert "\nError no points read."
    return 1
  }

  if {$total_tri == 0 && $total_quad == 0} {
    TextInsert "\nError no faces read."
    return 1
  }


  set nskip 0
  for {set zi 0} {$zi < $faceZone(num_zones)} {incr zi} {
    set zone $faceZone($zi,zone)
    TextInsert "  Tgrid Zone: $zone"
    set dom [expr $zi+1]
    if [info exists zoneInfo($zone,bc)] {
      TextInsert "    BC: $zoneInfo($zone,bc)"
      TextInsert "    Name: $zoneInfo($zone,name)"
    } else {
      TextInsert "    BC: MISSING!"
      TextInsert "    Name: MISSING!"
    }
  }

  return 0
}


proc load_doms {} {
  global zoneInfo faceZone
  global split_angle doDomSplit
  global pyramid_zone_split pyramid_zone_regexp
  global temp_dir non_manifold_check_baffle_zone_only

  set baffle_doms ""
  set maxcell 0

  TextInsert "\nLoad Domains..."

  set ndoms_orig [llength [pw::Grid getAll -type pw::Domain]]

  set nskip 0
  for {set zi 0} {$zi < $faceZone(num_zones)} {incr zi} {
    set zone $faceZone($zi,zone)
    set dom [expr $zi+1]
    set ndoms [llength [pw::Grid getAll -type pw::Domain]]
    set fn [file join $temp_dir "dom$dom.wrl"]

    set pyrZone 0
    if { $doDomSplit && !$pyramid_zone_split } {
      #-- Don't split pyramid zones
      if [info exists zoneInfo($zone,bc)] {
        if [regexp $pyramid_zone_regexp $zoneInfo($zone,name)] {
          set pyrZone 1
          TextInsert "  warning: not splitting doms in zone $zoneInfo($zone,name)"
          TextInsert "    because it has been identified as containing pyramid faces."
        }
      }
    }

    if { !$pyrZone && $doDomSplit} {
      pw::Grid setImportSplitAngle $split_angle
      pw::Grid import -type VRML $fn
    } else {
      pw::Grid setImportSplitAngle 0
      pw::Grid import -type VRML $fn
    }
    catch {file delete $fn}
    if [info exists zoneInfo($zone,bc)] {
      set bc [pw::BoundaryCondition create]
      if {[catch {$bc setName "$zoneInfo($zone,name)"}]} {
         unset bc
      }

     set ndoms2 [llength [pw::Grid getAll -type pw::Domain]]
      for {set dom [expr $ndoms+1]} {$dom <= $ndoms2} {incr dom} {
        set bc [pw::BoundaryCondition getByName "$zoneInfo($zone,name)"]
        set domObj [pw::Entity getByName "dom-$dom"]
        $bc apply $domObj 
        if {$zoneInfo($zone,is_baffle)} {
          set domObj [pw::Entity getByName "dom-$dom"]
          lappend baffle_doms $domObj
        }
      }
    }
  }

  set ndoms_after [llength [pw::Grid getAll -type pw::Domain]]
  set nnew [expr $ndoms_after-$ndoms_orig]

  #-- send the new domains through a cleanup routine
  #-- to separate any non-manifold domain intersections

  if { $non_manifold_check_baffle_zone_only } {
    #-- only check new baffle-zone domains
    set new_doms $baffle_doms
    TextInsert "  checking BAFFLE domains for non-manifold intersections"
  } else {
    #-- check all new domains
    set new_doms ""
    for {set dom [expr $ndoms_orig+1]} {$dom <= $ndoms_after} {incr dom} {
      set domObj [pw::Entity getByName "dom-$dom"]
      lappend new_doms $domObj
    }
    TextInsert "  checking ALL domains for non-manifold intersections"
  }

  set ndoms_after [llength [pw::Grid getAll -type pw::Domain]]
  set nnew [expr $ndoms_after-$ndoms_orig]

  if { $nnew == 1 } {
    set msg "  loaded $nnew new domain."
  } else {
    set msg "  loaded $nnew new domains."
  }
  TextInsert $msg

  pw::Display resetView
  return
}

proc splitToggle {} {
  global  doDomSplit angleWidgets

  set state disabled
  if $doDomSplit {set state normal}

  foreach w $angleWidgets {
    catch {$w configure -state $state}
  }
}


proc TextInsert {line} {
  global msgBox scriptMode
  if {$scriptMode == "gui" } {
    $msgBox configure -state normal
    $msgBox insert end "$line\n"
    $msgBox see end
    $msgBox configure -state disabled
  } else {
    puts $line
  }
  update
}


proc GetFile {} {
  global tgrid_file

  set types {
    {{Tgrid Mesh Files}   {.msh}  }
    {{All Files}   *  }
  }
  set file [tk_getOpenFile -defaultextension "cas" -filetypes $types \
           -title "Load Tgrid File" -parent .]
  if {$file == ""} {
    #-- cancel
    return
  }

  if ![file exists $file] {
    TextInsert "Can't open file $file"
    return
  }
  set tgrid_file $file

  return
}


proc GetTempDir {} {
  global tgrid_file temp_dir script_dir

  #-- Can we write in the current temp_dir?
  if {[info exists temp_dir] && [file isdirectory $temp_dir]} {
    set fn [file join $temp_dir .aaa]
    puts -nonewline "Trying temp_dir = $temp_dir..."
    if ![catch {open $fn w} f] {
      #-- temp_dir is good
      close $f
      catch {file delete $fn}
      puts "good"
      return
    }
    puts "\nUnable to write to $temp_dir."
  }

  #-- try dir containing tgrid_file
  set temp_dir [file dirname $tgrid_file]
  if {$temp_dir == "."} {
    set temp_dir [pwd]
  }

  set fn [file join $temp_dir .aaa]
  puts -nonewline "Trying temp_dir = $temp_dir..."
  if ![catch {open $fn w} f] {
    #-- temp_dir is good
    close $f
    catch {file delete $fn}
    puts "good"
    return
  }
  puts "\nUnable to write to $temp_dir."


  #-- try script_dir
  set temp_dir $script_dir

  puts -nonewline "Trying temp_dir = $temp_dir..."
  set fn [file join $temp_dir .aaa]
  if ![catch {open $fn w} f] {
    #-- temp_dir is good
    close $f
    catch {file delete $fn}
    puts "good"
    return
  }
  puts "\nUnable to write to $temp_dir."

  puts "\nUnable to find a suitable temporary directory."
  puts "Please set an appropriate value for the \"temp_dir\""
  puts "variable at the beginning of the script file."
  exit
}


if {$scriptMode == "gui" } {
  #################################################################
  ##  GUI MODE
  #################################################################

  pw::Script loadTk

  set tl .
  wm withdraw $tl

  set tf [frame $tl.title]
  pack $tf -side top -fill x -expand 0 -padx 2 -pady 2

  label $tf.l -text "Fluent Tgrid File Import" -anchor c -font {Arial 12 bold}
  pack $tf.l -side top
  set title $tf.l

  set tf [frame $tl.top]
  pack $tf -side top -fill x -expand 0 -padx 2 -pady 2

  set bf [frame $tl.bot]
  pack $bf -side bottom -fill both -expand 1 -padx 2 -pady 2


  set f [frame $tf.1]
  pack $f -side top  -fill x -expand 0 -padx 0 -pady 2
  set fileFrame $f

  label $f.file -text "Tgrid file:"
  pack $f.file -side left

  entry $f.e -textvariable tgrid_file -width 20
  pack $f.e -side left -fill x -expand 1

  frame $f.spc -width 3
  pack $f.spc -side left

  button $f.browse -text "Browse" -command GetFile -width 6
  pack $f.browse -side left


  set f [frame $tf.2]
  pack $f -side top  -fill x -expand 0 -padx 0 -pady 2
  set splitFrame $f

  checkbutton $f.dosplit -text "Split domains at corners" \
      -variable doDomSplit  -command splitToggle
  pack $f.dosplit -side left

  frame $f.spc -width 6
  pack $f.spc -side left

  label $f.angle -text "Split angle:"
  pack $f.angle -side left

  entry $f.e -textvariable split_angle -width 8
  pack $f.e -side left -fill x -expand 0

  set angleWidgets [list $f.angle $f.e]


  set f [frame $tf.3 -bd 2 -relief groove]
  pack $f -side top -fill x -expand 0 -padx 0 -pady 4

  button $f.import -text "Import Domains" \
     -command {import_domains $tgrid_file} -width 12
  pack $f.import -side left -padx 2 -pady 2

  button $f.cancel -text "Cancel" \
     -command {exit} -width 12
  pack $f.cancel -side right -padx 2 -pady 2

  set importBtn $f.import
  set closeBtn $f.cancel


  set f $bf

  set sbar [scrollbar $f.sbar -command "$f.t yview"]
  pack $sbar -side right -fill y -expand 0

  set msgBox [text $f.t -width 65 -height 20 \
     -font {courier 10} -yscrollcommand "$sbar set" -state disabled]
  set t $f.t
  pack $msgBox -side left -fill both -expand 1

  #-- set some bindings so we can select text with the mouse
  bind $msgBox <KeyPress> {
    $msgBox configure -state disabled
  }
  bind $msgBox <ButtonPress-1> {
    $msgBox configure -state normal
  }
  bind $msgBox <ButtonRelease-1> {
    $msgBox configure -state disabled
  }

  TextInsert "This script will scan a Fluent Tgrid file"
  TextInsert "for surface mesh and import it as unstructured"
  TextInsert "Gridgen domains. "

  TextInsert "\nEach Fluent surface mesh zone will become"
  TextInsert "a Gridgen domain.  If desired, each domain"
  TextInsert "can be further sub-divided based on turning"
  TextInsert "angle using the \"Split domains at corners\""
  TextInsert "option."

  TextInsert "\nFluent surface mesh zone names (taken"
  TextInsert "from section 45) are used to apply boundary"
  TextInsert "conditions to the Gridgen domains."

  TextInsert "\nBefore running this script you should:"
  TextInsert "  1. Restart the grid system if necessary."
  TextInsert "  2. Set the desired flow solver."
  TextInsert "  3. Set the grid tolerances appropriately."

  CenterWindow $tl
  wm deiconify $tl


} else {

  #################################################################
  ##  STAND_ALONE MODE
  #################################################################

  import_domains $tgrid_file
}


#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################

