#! /bin/sh
# kbsgui.tcl -- Kitgen Build System - Graphical user interface
##@file kbsgui.tcl -- Kitgen Build System - Graphical user interface
## Launch as 'kbsgui.tcl'
##@auth <r.zaumseil@freenet.de>
##@vers $Id$
## See the file "license.terms" for information on usage and redistribution of
## this file, and for a DISCLAIMER OF ALL WARRANTIES.
#===============================================================================
# bootstrap for building wish.. \
PREFIX=`pwd`/`uname` ;\
case `uname` in \
  MINGW*) DIR="win"; EXE="${PREFIX}/bin/wish85s.exe" ;; \
  *) DIR="unix"; EXE="${PREFIX}/bin/wish8.5" ;; \
esac ;\
if test ! -d sources ; then mkdir sources; fi;\
if test ! -x ${EXE} ; then \
  if test ! -d sources/tcl-8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tcl.cvs.sourceforge.net:/cvsroot/tcl -z3 co -r core-8-5-b3 tcl && mv tcl tcl-8.5 ) ;\
  fi ;\
  if test ! -d sources/tk-8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -z3 co -r core-8-5-b3 tk && mv tk tk-8.5 ) ;\
  fi ;\
  mkdir -p ${PREFIX}/tcl ;\
  ( cd ${PREFIX}/tcl && ../../sources/tcl-8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tcl ;\
  mkdir -p ${PREFIX}/tk ;\
  ( cd ${PREFIX}/tk && ../../sources/tk-8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} --with-tcl=${PREFIX}/lib && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tk ;\
fi ;\
if test ! -d sources/kbskit-0.1 ; then\
  ( cd sources && cvs -d :pserver:anonymous@kbskit.cvs.sourceforge.net:/cvsroot/kbskit -z3 co kbskit && mv kbskit kbskit-0.1 ) ;\
fi ;\
exec ${EXE} "$0" ${1+"$@"}
#===============================================================================

interp alias {} button {} ::ttk::button
interp alias {} checkbutton {} ::ttk::checkbutton
interp alias {} entry {} ::ttk::entry
interp alias {} label {} ::ttk::label
interp alias {} labelframe {} ::ttk::labelframe
interp alias {} scrollbar {} ::ttk::scrollbar

source kbs.tcl

#===============================================================================

namespace eval kbsgui {
  variable _
}

#-------------------------------------------------------------------------------

proc kbsgui::Init {} {
  variable _

  wm withdraw .
  set w .t
  toplevel $w -class Kbs
  grid rowconfigure $w 4 -weight 1
  grid columnconfigure $w 1 -weight 1

  # directories
  set w .t.1
  grid [labelframe $w -text Directories]\
	-row 1 -column 1 -sticky ew
  grid columnconfigure $w 2 -weight 1

  grid [button $w.1 -text -builddir= -command {kbsgui::setdir builddir}]\
	-row 1 -column 1 -sticky ew
  grid [label $w.2 -anchor w -relief ridge -textvariable ::config::builddir]\
	-row 1 -column 2 -columnspan 2 -sticky ew
  grid [button $w.3 -text -sourcedir= -command {kbsgui::setdir sourcedir}]\
	-row 2 -column 1 -sticky ew
  grid [label $w.4 -anchor w -relief ridge -textvariable ::config::sourcedir]\
	-row 2 -column 2 -columnspan 2 -sticky ew

  # options
  set w .t.2
  grid [labelframe $w -text Options]\
	-row 2 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 3 -weight 1

  grid [checkbutton $w.1 -text -ignore -onvalue 1 -offvalue 0 -variable ::config::ignore]\
	-row 1 -column 1 -sticky ew
  grid [checkbutton $w.2 -text -recursive -onvalue 1 -offvalue 0 -variable ::config::recursive]\
	-row 1 -column 2 -sticky ew
  grid [checkbutton $w.3 -text -verbose -onvalue 1 -offvalue 0 -variable ::config::verbose]\
	-row 1 -column 3 -sticky ew

  # variables
  set w .t.3
  grid [labelframe $w -text Variables] -row 3 -column 1 -sticky ew
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 4 -weight 1

  grid [label $w.1 -text _(CC)= -anchor e]\
	-row 1 -column 1 -sticky ew
  grid [entry $w.2 -textvariable ::config::_(CC)]\
	-row 1 -column 2 -sticky ew
  grid [label $w.3 -text _(AQUA)= -anchor e]\
	-row 2 -column 1 -sticky ew
  grid [checkbutton $w.4 -onvalue --enable-aqua -offvalue --disable-aqua -variable ::config::_(AQUA) -textvariable ::config::_(AQUA)]\
	-row 2 -column 2 -sticky ew
  grid [label $w.5 -text _(SYMBOLS)= -anchor e]\
	-row 2 -column 3 -sticky ew
  grid [checkbutton $w.6 -onvalue --enable-symbols -offvalue --disable-symbols -variable ::config::_(SYMBOLS) -textvariable ::config::_(SYMBOLS)]\
	-row 2 -column 4 -sticky ew
  grid [label $w.7 -text _(64BIT)= -anchor e]\
	-row 3 -column 1 -sticky ew
  grid [checkbutton $w.8 -onvalue --enable-64bit -offvalue --disable-64bit -variable ::config::_(64BIT) -textvariable ::config::_(64BIT)]\
	-row 3 -column 2 -sticky ew
  grid [label $w.9 -text _(THREADS)= -anchor e]\
	-row 3 -column 3 -sticky ew
  grid [checkbutton $w.10 -onvalue --enable-threads -offvalue --disable-threads -variable ::config::_(THREADS) -textvariable ::config::_(THREADS)]\
	-row 3 -column 4 -sticky ew

  # packages
  set w .t.4
  grid [labelframe $w -text Packages]\
	-row 4 -column 1 -sticky ew
  grid rowconfigure $w 1 -weight 1
  grid columnconfigure $w 1 -weight 1

  grid [listbox $w.1 -yscrollcommand "$w.2 set" -selectmode single]\
	-row 1 -column 1 -sticky nesw
  eval $w.1 insert end [lsort -dict [array names ::config::packages]]
  set ::kbsgui::_(lb) $w.1
  grid [scrollbar $w.2 -orient vertical -command "$w.1 yview"]\
	-row 1 -column 2 -sticky ns

  # commands
  set w .t.5
  grid [labelframe $w -text Commands]\
	-row 5 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 3 -weight 1
  grid columnconfigure $w 4 -weight 1
  grid [button $w.1 -text sources -command {kbsgui::command sources}]\
	-row 1 -column 1 -sticky ew
  grid [button $w.2 -text configure -command {kbsgui::command configure}]\
	-row 1 -column 2 -sticky ew
  grid [button $w.3 -text make -command {kbsgui::command make}]\
	-row 1 -column 3 -sticky ew
  grid [button $w.4 -text install -command {kbsgui::command install}]\
	-row 1 -column 4 -sticky ew
  grid [button $w.5 -text test -command {kbsgui::command test}]\
	-row 2 -column 1 -sticky ew
  grid [button $w.6 -text clean -command {kbsgui::command clean}]\
	-row 2 -column 2 -sticky ew
  grid [button $w.7 -text distclean -command {kbsgui::command distclean}]\
	-row 2 -column 3 -sticky ew
  grid [button $w.8 -text EXIT -command {exit}]\
	-row 2 -column 4 -sticky ew

  # status
  set w .t.6
  grid [labelframe $w -text Status]\
	-row 6 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1

  grid [label $w.1 -anchor w -relief sunken -textvariable ::kbsgui::_(status)]\
	-row 1 -column 1 -sticky ew

  wm title .t KBS
  wm protocol .t WM_DELETE_WINDOW {exit}
  wm deiconify .t
}

#-------------------------------------------------------------------------------

proc kbsgui::setdir {varname} {
  set myDir [tk_chooseDirectory -parent .t -title "Directory -$varname"\
	-initialdir [subst \$::config::$varname]]
  if {$myDir == ""} return
  file mkdir $myDir
  set ::config::$varname $myDir
}

#-------------------------------------------------------------------------------

proc kbsgui::command {cmd} {
  set myWdg $::kbsgui::_(lb)
  set mySelection [$myWdg curselection]
  if {[llength $mySelection] == 0} {
    tk_messageBox -parent .t -type ok -title {No selection} -message {Please select at least one package from the list.}
    return
  }
  set myTarget [$myWdg get $mySelection]
  set ::kbsgui::_(status) "$cmd $myTarget ..."
  update idletasks
  if {[catch {kbs::$cmd $myTarget} myMsg]} {
    tk_messageBox -parent .t -type ok -title {Execution failed} -message "\"$cmd $myTarget\" failed!\n$myMsg" -icon error
  } else {
    tk_messageBox -parent .t -type ok -title {Execution finished} -message "\"$cmd $myTarget\" successfull." -icon info
  }
#  $myWdg selection clear $mySelection
  set ::kbsgui::_(status) ""
}

#-------------------------------------------------------------------------------

proc main {argv} {
  # parse options for kbs.tcl
  set argv [::config::configure {*}$argv]
  # start gui
  #option readfile [file join $::config::maindir kbs.ad] userDefault
  kbsgui::Init
}

#===============================================================================

main $argv
