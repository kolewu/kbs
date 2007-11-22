#! /bin/sh
##@file kbs.tcl -- Kitgen Build System
## Launch as 'kbs.tcl' to get a brief help text
##@auth <jcw@equi4.com>
## Initial ideas and kbskit sources
##@auth <r.zaumseil@freenet.de>
## kbskit TEA extension and development
##@vers $Id$
## See the file "license.terms" for information on usage and redistribution of
## this file, and for a DISCLAIMER OF ALL WARRANTIES.
#===============================================================================
# bootstrap for building tclsh.. \
PREFIX=`pwd`/`uname` ;\
case `uname` in \
  MINGW*) DIR="win"; EXE="${PREFIX}/bin/tclsh85s.exe" ;; \
  *) DIR="unix"; EXE="${PREFIX}/bin/tclsh8.5" ;; \
esac ;\
if test ! -d sources ; then mkdir sources; fi;\
if test ! -x ${EXE} ; then \
  if test ! -d sources/tcl-8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tcl.cvs.sourceforge.net:/cvsroot/tcl -z3 co -r core-8-5-b3 tcl && mv tcl tcl-8.5 ) ;\
  fi ;\
  mkdir ${PREFIX} ;\
  mkdir ${PREFIX}/tcl ;\
  ( cd ${PREFIX}/tcl && ../../sources/tcl-8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tcl ;\
fi ;\
if test ! -d sources/kbskit-0.1 ; then\
  ( cd sources && cvs -d :pserver:anonymous@kbskit.cvs.sourceforge.net:/cvsroot/kbskit -z3 co kbskit && mv kbskit kbskit-0.1 ) ;\
fi ;\
exec ${EXE} "$0" ${1+"$@"}
#===============================================================================

namespace eval kbs {
}
    
#-------------------------------------------------------------------------------

proc kbs::help {} {
  puts {Kitgen Build System
kbs.tcl ?options? mode ?args?
options:
  -builddir=?dir?      default is 'build$tcl_platform(os)', use with [Builddir]
  -sourcedir=?dir?     default is 'sources'
  -pkgfile=?file?      default is 'sources/kbskit-0.1/kbskit.kbs', contain used Package definitions
  -i -ignore           ignore errors and proceed (default is disabled)
  -r -recursive        recursive Require packages (default is disabled)
  -v -verbose          display running commands and command output
  --CC=?command?       set configuration variable _(CC)
                       default is 'gcc' or existing environment variable 'CC'
  --enable-symbols
  --disable-symbols    set configuration variable _(SYMBOLS)
  --enable-64bit
  --disable-64bit      set configuration variable _(64BIT)
  --enable-threads
  --disable-threads    set configuration variable _(THREADS)
  --enable-aqua
  --disable-aqua       set configuration variable _(AQUA)
 mode:
  help                 this text
  kbs                  return information about *.kbs commands
  list ?pattern?       list packages matching pattern (default is *)
  require package ..   return call trace of packages
  sources package ..   get package source files (under sources/)
  configure package .. create [Makedir] (in [Builddir]) and configure package
  make package ..      make package (in [Makedir])
  install package ..   install package (in [Builddir])
  test package ..      test package
  clean package ..     remove make targets
  distclean package .. remove [Makedir]
package is used for glob style matching against available packages
(Beware, you need to hide the special meaning of * like foo\*)

The following configuration variables can be used:}
  namespace eval ::config {parray _}
}

#-------------------------------------------------------------------------------

proc kbs::kbs {} {
  set myFd [open [info script] r]
  while {[gets $myFd myLine] != -1} {
    if {[string range $myLine 0 1] == "##"} {
      puts [string range $myLine 2 end]
    }
  }
  close $myFd
}

#-------------------------------------------------------------------------------

proc kbs::list {{pattern *}} {
  puts [lsort -dict [array names ::config::packages $pattern]]
}

#-------------------------------------------------------------------------------

proc kbs::require {args} {
  ::config::init {Require} {Source Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::sources {args} {
  ::config::init {Require Source} {Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::configure {args} {
  ::config::init {Require Source Configure} {Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::make {args} {
  ::config::init {Require Source Configure Make} {Test Install Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::test {args} {
  ::config::init {Require Source Test} {Configure Make Install Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::install {args} {
  ::config::init {Require Source Configure Make Install} {Test Clean} $args
}

#-------------------------------------------------------------------------------

proc kbs::clean {args} {
  ::config::init {Clean} {Require Source Configure Make Test Install} $args
}

#-------------------------------------------------------------------------------

proc kbs::distclean {args} {
  # Remove [Makedir] so everything will be rebuild again
  set myBody [info body ::config::Source];# save old body
  proc ::config::Source [info args ::config::Source] {
    set myDir [Makedir tcl]
    if {[file exist $myDir]} {
      puts "=== Distclean: $myDir"
      file delete -force $myDir
    }
  }
  ::config::init {Require Source} {Configure Make Test Install Clean} $args
  proc ::config::Source [info args ::config::Source] $myBody;# restore old body
}

#===============================================================================

namespace eval config {
#
# internal variables, at first because maindir is used later
#
##@variable maindir
## Internal variable containing top level script directory.
  variable maindir [file normalize [file dirname [info script]]]
##@variable packages
## Internal variable with package definitions from *.kbs files.
  variable packages
##@variable package
## Internal variable containing current package name.
  variable package
##@variable srcdir
## Internal variable containing current package source directory.
  variable srcdir
##@variable ready
## Internal variable containing list of already prepared packages.
  variable ready [list]
##@variable procs
## Internal variable containing list of available procedures in Package´s.
  variable procs [list Srcdir Makedir Builddir Run tclConfig tkConfig Kit Tcl Patch]
##@variable tclConfig
## Internal variable, set to 1 if tclConfig.sh was parsed.
  variable tclConfig 0
##@variable tkConfig
## Internal variable, set to 1 if tkConfig.sh was parsed.
  variable tkConfig  0
#
# configuration variables, can be overwritten on startup, no spaces inside
#
##@variable builddir
## Default building directory.
  variable builddir [file join $maindir build[string map {{ } {}} $::tcl_platform(os)]]
##@variable sourcedir
## Directory with all source distributions.
  variable sourcedir [file join $maindir sources]
##@variable ignore
## If set (-i or -ignore switch) then proceed in case of errors.
  variable ignore 0
##@variable recursive
## If set (-r or -recursive switch) then all Require packages are also used.
  variable recursive 0
##@variable verbose
## If set (-v or -verbose switch) then all stdout will be removed.
  variable verbose 0
##@variable pkgfile
## Used kbs package definition file.
  variable pkgfile {}

#
# configuration options, can be overwritten in Package definitions
#
##@variable _
## The array variable contain usefull information of the current building process.
  variable _
  if {[info exist ::env(CC)]} {
    set _(CC)	$::env(CC)
  } else {
    set _(CC)          {gcc};# used compiler
  }
  set _(STATIC)      {--disable-shared};# shared building
  set _(SHARED)      {--enable-shared};# static building
  set _(AQUA)        {--enable-aqua};# tcl
  set _(SYMBOLS)     {--disable-symbols};# build without debug symbols
  set _(THREADS)     {--enable-threads};# build with thread support
  set _(64BIT)       {--disable-64bit};# build without 64 bit support
  set _(TZDATA)      {--with-tzdata};# tcl
  set _(DIR) {unix};# configuration subdirectory
  if {$::tcl_platform(platform) == "windows"} {
    set _(DIR) {win}
  }

}

#-------------------------------------------------------------------------------
proc config::init {used unused list} {
  variable packages
  variable package
  variable ignore
  variable interp
  variable procs

  # reset to clean state
  variable ready	[list]
  variable tclConfig	0
  variable tkConfig	0
  variable _
  foreach myName [array names _] {;# clean used variables
    if {[lsearch -exact {CC STATIC SHARED AQUA SYMBOLS THREADS 64BIT TZDATA DIR} $myName] == -1} {
      unset _($myName)
    }
  }

  # create interpreter with available commands
  set interp [interp create]
  foreach myProc $procs {;# standard
    interp alias $interp $myProc {} ::config::$myProc {}
  }
  foreach myProc $used {;# available commands
    interp alias $interp $myProc {} ::config::$myProc
  }
  foreach myProc $unused {;# hidden commands
    $interp eval [list proc $myProc [info args ::config::$myProc] {}]
  }
  # now process command
  foreach myPattern $list {
    set myTargets [array names packages $myPattern]
    if {[llength $myTargets] == 0} {
      return -code error "no targets found for pattern: $myPattern"
    }
    foreach package $myTargets {
      puts "=== Package eval: $package"
      if {[catch {$interp eval $packages($package)} myMsg]} {
        if {$ignore == 0} {
          interp delete $interp
	  set interp {}
          return -code error "=== Package failed for: $package\n$myMsg"
        }
        puts "=== Package error: $myMsg"
      }
      puts "=== Package done: $package"
    }
  }
  interp delete $interp
  set interp {}
}

#-------------------------------------------------------------------------------
##@proc Package {name script}
## The "Package" command is available in definition files.
##@arg name   -- unique name of package
##@arg script -- contain definitions in the following order. For a detailed
## description look in the related commands.
## * Require
## * Source
## * Configure
## * Make
## * Install
## * Clean
proc config::Package {name script} {
  variable packages

  if {[info exist packages($name)]} {
    return -code error "package already exist: $name"}
  set packages($name) $script
}

#-------------------------------------------------------------------------------
##@proc config::Proc {name arglist body}
## The 'Proc' command define a procedure the same way as the 'proc' command.
## This procedure is then available in every 'Package' definition.
##@arg name    - name of the procedure
##@arg arglist - argument list of the procedure
##@arg body    - body of the procedure
proc config::Proc {name arglist body} {
  variable procs
  if {[string first : $name] != -1} {
    return -code error "wrong name of Proc: $name"
  }
  if {[lsearch -exact $procs $name] != -1} {
    return -code error "Proc already exists: $name"
  }
  proc ::config::$name $arglist $body
  lappend procs $name
}

#-------------------------------------------------------------------------------
##@proc Require {args}
## The given "Package"´s in args will be recursively called.
##@arg args - one or more "Package" names
proc config::Require {args} {
  variable recursive
  if {$recursive == 0} return

  variable packages
  variable ready
  variable package
  variable srcdir
  variable ignore
  variable interp
  puts "=== Require enter: $args"

  set myPackage $package
  set myTargets [list]
  foreach package $args {
    # already loaded
    if {[lsearch $ready $package] != -1} continue
    # single target name
    if {[info exist packages($package)]} {
      puts "=== Require eval: $package"
      set srcdir {???}
      if {[catch {$interp eval $packages($package)} myMsg]} {
        puts "=== Require error: $package\n$myMsg"
        if {$ignore == 0} {
          return -code error "Require failed for: $package"
        }
      }
      puts "=== Require done: $package"
      lappend ready $package
      continue
    }
    # nothing found
    return -code error "Require not found: $package"
  }
  set package $myPackage
  puts "=== Require leave: $args"
}

#-------------------------------------------------------------------------------
##@proc Source {type args}
## Procedure to build source tree of current "Package" definition.
##@arg pkg - name of package source dir under "-sourcedir"
##@arg type - describe action to get source tree of "Package"
## Available are:
##  cvs path ... - call 'cvs -d path ...'
##  svn path     - call 'svn co path'
##  fetch path   - call 'http get path', unpack *.tar.gz or *.tgz files
##  tgz file     - call 'tar xzf file'
##  link path	 - use sources from "path"
proc config::Source {type args} {
  variable sourcedir
  variable package
  variable srcdir
  variable maindir

  switch -- $type {
    script {
      cd $sourcedir
      set srcdir [file join $sourcedir [lindex $args 0]]
      if {![file exists $srcdir]} {
        eval [lindex $args 1]
      }
    } link {
      set srcdir [file join $sourcedir $args]
      if {![file exists $srcdir]} {
        cd $maindir
        puts "=== Source link: $args"
	if {[catch {
          exec [pwd]/kbs.tcl sources $args >@stdout 2>@stderr
        } myMsg]} {
          return -code error "missing link source: $args\n$myMsg"
        }
        if {![file exists $srcdir]} {
          return -code error "missing link source: $args"
        }
      }
    } cvs - svn - fetch - tgz {
      set srcdir [file join $sourcedir $package]
      if {![file exists $srcdir]} {
        puts "=== Source eval: $package"
        cd $sourcedir
        eval [linsert $args 0 src-$type]
      }
    } default {
      return -code error "wrong type \"$type\", should be link, csv, svn, fetch or tgz"
    }
  }
}

#-------------------------------------------------------------------------------
proc config::src-cvs {path args} {
  if {$args eq ""} { set args [file tail $path] }
  if {[string first @ $path] < 0} { set path :pserver:anonymous@$path }
  Run cvs -d $path -z3 co -P -d tmp {*}$args
  file rename tmp [Srcdir tcl]
}
    
#-------------------------------------------------------------------------------
proc config::src-svn {path} {
  Run svn co $path [Srcdir sys]
}
    
#-------------------------------------------------------------------------------
proc config::src-fetch {path} {
  variable sourcedir
  variable verbose

  set file [file join $sourcedir [file tail $path]]
  package require http
  if {$verbose} {puts "  fetching $file"}
  set fd [open $file w]
  set t [http::geturl $path -binary 1 -channel $fd]
  close $fd

  scan [http::code $t] {HTTP/%f %d} ver ncode
  if {$verbose} {puts [http::status $t]}
  http::cleanup $t

  if {$ncode != 200 || [file size $file] == 0} {
    file delete $file
    return -code error "fetch failed"
  }
  # unpack if necessary
  switch -glob $file {
    *.tgz - *.tar.gz {
      if {[catch {src-tgz $file} myMsg]} {
        file delete $file
        return -code error $myMsg
      }
      file delete $file
    } *.zip {
      if {[catch {src-zip $file} myMsg]} {
        file delete $file
        return -code error $myMsg
      }
      file delete $file
    } *.kit {
      if {$::tcl_platform(platform) eq "unix"} {
        file attributes $file -permissions u+x
      }
    }
  }
}

#-------------------------------------------------------------------------------
proc config::src-tgz {file} {
  file mkdir tmp
  cd tmp
  # use explicit gzip in case tar command doesn't understand the z flag
  set r [catch {exec gzip -dc [file normalize $file] | tar xf -} myMsg]
  cd ..
  if {$r} { 
    file delete -force tmp
    return -code error $myMsg\n$r
  }
  # cover both cases: untar to single dir and untar all into current dir
  set untarred [glob tmp/*]
  if {[llength $untarred] == 1 && [file isdir [lindex $untarred 0]]} {
    file rename [lindex $untarred 0] [Srcdir tcl]
    file delete tmp
  } else {
    file rename tmp [Srcdir tcl]
  }
}

#-------------------------------------------------------------------------------
proc config::src-zip {file} {
  file mkdir tmp
  cd tmp
  set r [catch {exec unzip [file normalize $file]} myMsg]
  cd ..
  if {$r} { 
    file delete -force tmp
    return -code error $myMsg
  }
  # cover both cases: unzip to single dir and unzip all into current dir
  set untarred [glob tmp/*]
  if {[llength $untarred] == 1 && [file isdir [lindex $untarred 0]]} {
    file rename [lindex $untarred 0] [Srcdir tcl]
    file delete tmp
  } else {
    file rename tmp [Srcdir tcl]
  }
}

#-------------------------------------------------------------------------------
##@proc Configure {script}
## If [Makedir] not exist create it and eval script.
##@arg script - tcl script to evaluate
proc config::Configure {script} {
  variable verbose

  set myDir [Makedir tcl]
  if {[file exist $myDir]} return
  puts "=== Configure $myDir"
  if {$verbose} {puts $script}
  file mkdir $myDir; cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------
##@proc Make {script}
## Eval script in [Makedir].
##@arg script - tcl script to evaluate
proc config::Make {script} {
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} {
    return -code error "missing make directory: $myDir"
  }
  puts "=== Make $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------
##@proc Install {script}
## Eval script in [Makedir].
##@arg script - tcl script to evaluate
proc config::Install {script} {
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} {
    return -code error "missing make directory: $myDir"
  }
  puts "=== Install $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------
##@proc Test {script}
## Eval script in [Makedir].
##@arg script - tcl script to evaluate
proc config::Test {script} {
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} return
  puts "=== Test $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------
##@proc Clean {script}
## Eval script in [Makedir].
##@arg script - tcl script to evaluate
proc config::Clean {script} {
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} return
  puts "=== Clean $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------
##@proc Srcdir {type}
## Return fully qualified path to current 'Package' source dir.
## The parent dir can be set on the command line with '-sourcedir'.
##@par type: one of "tcl" used in tcl commands and "sys" used in system commands
proc config::Srcdir {type} {
  variable srcdir

  if {$::tcl_platform(platform)=="windows" && $type == "sys" && [string index $srcdir 1]==":"} {
    return /[string tolower [string index $srcdir 0]][string range $srcdir 2 end]
  }
  return $srcdir
}
 
#-------------------------------------------------------------------------------
##@proc Makedir {type}
## Return fully qualified path to current 'Package' make dir.
## Path is in dir [Builddir].
##@par type: one of "tcl" used in tcl commands and 'sys' used in system commands
proc config::Makedir {type} {
    variable package

    return [file join [Builddir $type] $package]
}

#-------------------------------------------------------------------------------
##@proc Builddir {type}
## Return path of current building dir. This dir contain all [Makedir]
## and is used in the 'Install' target.
## The dir can be set on the command line with '-builddir'.
##@par type: one of 'tcl' used in tcl commands and 'sys' used in system commands
proc config::Builddir {type} {
  variable builddir
  if {$::tcl_platform(platform)=="windows" && $type == "sys" && [string index $builddir 1]==":"} {
    return "/[string tolower [string index $builddir 0]][string range $builddir 2 end]"
  }
  return $builddir
}


#-------------------------------------------------------------------------------
##@proc Run {args}
## The procedure call the args as external command with options.
## The procedure is available in all script arguments.
proc config::Run {args} {
  variable verbose
  if {$verbose} {
    puts $args
    exec {*}$args >@stdout 2>@stderr
  } else {
    if {$::tcl_platform(platform)=="windows"} {
      exec {*}$args >__dev__null__ 2>@stderr
    } else {
      exec {*}$args >/dev/null 2>@stderr
    }
  }
}

#-------------------------------------------------------------------------------
##@proc tclConfig {varname}
## The procedure return the content of TCL* variables of the tclConfig.sh file.
## The variables are also available in the '_' array.
## The procedure is intended for use in the 'Configure' target.
proc config::tclConfig {varname} {
  variable builddir
  variable tclConfig
  variable _

  if {$tclConfig == 0} {;# read and parse file, save variables in _ array
    set myScript ""
    set myFd [open [file join $builddir lib tclConfig.sh] r]
    while {[gets $myFd myLine] != -1} {
      if {[string range $myLine 0 2] == "TCL"} {
	set myNr [string first = $myLine]
	if {$myNr == -1} continue
	append myScript "set _([string range $myLine 0 [expr {$myNr - 1}]]) "
	incr myNr 1
	append myScript [list [string map {' {}} [string range $myLine $myNr end]]]\n
      }
    }
    close $myFd
    eval $myScript
    set tclConfig 1
  }
  return $_($varname)
}

#-------------------------------------------------------------------------------
##@proc tkConfig {varname}
## The procedure return the content of TK* variables of the tkConfig.sh file.
## The variables are also available in the '_' array.
## The procedure is intended for use in the 'Configure' target.
proc config::tkConfig {varname} {
  variable builddir
  variable tkConfig
  variable _

  if {$tkConfig == 0} {;# read and parse file, save variables in _ array
    set myScript ""
    set myFd [open [file join $builddir lib tkConfig.sh] r]
    while {[gets $myFd myLine] != -1} {
      if {[string range $myLine 0 1] == "TK"} {
	set myNr [string first = $myLine]
	if {$myNr == -1} continue
	append myScript "set _([string range $myLine 0 [expr {$myNr - 1}]]) "
	incr myNr 1
	append myScript [list [string map {' {}} [string range $myLine $myNr end]]]\n
      }
    }
    close $myFd
    eval $myScript
    set tkConfig 1
  }
  return $_($varname)
}

#-------------------------------------------------------------------------------
##@proc Kit {mode name args}
## The procedure links the 'name.vfs' in to the [Makedir] and create
## foreach name in 'args' a link from [Builddir]/lib in to 'name.vfs'/lib.
## The names in 'args' may subdirectories under [Builddir]/lib. In the
## 'name.vfs'/lib the leading directory parts are removed. The same goes for
## 'name.vfs'.
##@arg mode: make|install|clean|run what to do with kit
##  make: link all packages from 'args' in 'name.vfs'/lib
##  install: Wrap kit and move to [Builddir]/bin
##  clean: remove all links in 'name.vfs'/lib
##  run: Run 'name.kit' with 'args'
##@arg name: name of vfs directory (without extension) to use
##@arg args: additional args
##           - list of libraries in 'make' and 'clean' mode.
##           - kit command line arguments in 'run' mode.
proc config::Kit {mode name args} {
  switch -- $mode {
    make {
      set myName ${name}.vfs
      file delete -force $myName
      #does not work under "msys": file link $myName [Srcdir tcl]
      Run ln -s [Srcdir sys] $myName
      foreach myPath [glob -nocomplain $myName/lib/*] {;# remove all links
        if {[file type $myPath] == "link"} {
          file delete -force $myPath
        }
      }
      foreach myPath $args {
        set myDst $myName/lib/[file tail $myPath]
        file delete -force $myDst
        Run ln -s [Builddir sys]/lib/$myPath $myDst
      }
    }
    install {
      # use last/highest found kbskit
      set myTclkit [lindex [lsort [glob [Builddir tcl]/bin/kbskit*cli*]] end]
      Run $myTclkit [Builddir tcl]/bin/sdx.kit wrap $name
      file rename -force $name [Builddir tcl]/bin/${name}.kit
    }
    clean {
      foreach myFile [glob -nocomplain ${name}.vfs/lib/*] {
        if {[file type $myFile] == "link"} { 
          file delete -force $myFile
        }
      }
      file delete -force ${name}.vfs
    }
    run {
      set myTclkit [lindex [lsort [glob [Builddir tcl]/bin/kbskit*gui*]] end]
      Run $myTclkit [Builddir tcl]/bin/${name}.kit {*}$args

    }
    default { return -code error "wrong mode: $mode" }
  }
}

#-------------------------------------------------------------------------------
##@proc config::Tcl {{package {}}}
##@arg package: install name of package, if missing then build from [Srcdir tcl]
proc config::Tcl {{package {}}} {
  if {$package == {}} {
    set myDst [file join [Builddir tcl] lib [file tail [Srcdir tcl]]]
  } else {
    set myDst [file join [Builddir tcl] lib $package]
  }
  file delete -force $myDst
  file copy -force [Srcdir tcl] $myDst
  if {![file exists [file join $myDst pkgIndex.tcl]]} {
    foreach {myPkg myVer} [split [file tail $myDst] -] break;
    if {$myVer == {}} {set myVer 0.0}
    set myRet "package ifneeded $myPkg $myVer \"\n"
    foreach myFile [glob -tails -directory $myDst *.tcl] {
      append myRet "  source \[file join \$dir $myFile\]\n"
    }
    set myFd [open [file join $myDst pkgIndex.tcl] w]
    puts $myFd "$myRet  package provide $myPkg $myVer\""
    close $myFd
  }
}

#-------------------------------------------------------------------------------
##@proc config::Patch {file lineoffset oldtext newtext}
##@arg file: name of file to patch
##@arg lineoffset: start point of patch, first line is 1
##@arg oldtext: part of file to replace
##@arg newtext: replacement text
proc config::Patch {file lineoffset oldtext newtext} {
  variable verbose

  set myFd [open $file r]
  set myC [read $myFd]
  close $myFd
  # find oldtext
  set myIndex 0
  for {set myNr 1} {$myNr < $lineoffset} {incr myNr} {;# find line
    set myIndex [string first \n $myC $myIndex]
    if {$myIndex == -1} {
      puts "failed Patch: $file $lineoffset -> eof at line $myNr"
      return
    }
    incr myIndex
  }
  # set begin and rest of string
  set myTest [string range $myC $myIndex end]
  set myC [string range $myC 0 [incr myIndex -1]]
  # test for newtext; patch already applied
  set myIndex [string length $newtext]
  if {[string compare -length $myIndex $newtext $myTest] == 0} {
    if {$verbose} {puts "patch line $lineoffset exists"}
    return
  }
  # test for oldtext; patch todo
  set myIndex [string length $oldtext]
  if {[string compare -length $myIndex $oldtext $myTest] != 0} {
    puts "skip Patch: $file $lineoffset"
    if {$verbose} {puts "old version:\n$oldtext\nnew version:\n[string range $myTest 0 $myIndex]"}
    return -code error "patch failed"
  }
  # apply patch
  append myC $newtext[string range $myTest $myIndex end]
  set myFd [open $file w]
  puts $myFd $myC
  close $myFd
  if {$verbose} {puts "applied Patch: $file $lineoffset"}
}

#-------------------------------------------------------------------------------
##@proc config::configure {args}
##@arg args: option list
proc config::configure {args} {
  variable maindir
  variable builddir
  variable sourcedir
  variable pkgfile
  variable ignore
  variable recursive
  variable verbose
  variable _

  set myPkgfile {}
  set myIndex 0
  foreach myCmd $args {
    switch -glob -- $myCmd {
      -builddir=* {
	set myFile [file normalize [string range $myCmd 10 end]]
        set builddir $myFile
      } -sourcedir=* {
        set myFile [file normalize [string range $myCmd 11 end]]
        set sourcedir $myFile
      } -pkgfile=* {
        set myPkgfile [file normalize [string range $myCmd 9 end]]
      } -i - -ignore {
        set ignore 1
      } -r - -recursive {
        set recursive 1
      } -v - -verbose {
	set verbose 1
      } --CC=* {
        set _(CC) [string range $myCmd 5 end]
      } --enable-symbols - --disable-symbols {
        set _(SYMBOLS) $myCmd
      } --enable-64bit - --disable-64bit - --enable-64bit-vis {
        set _(64BIT) $myCmd
      } --enable-threads - --disable-threads {
        set _(THREADS) $myCmd
      } --enable-aqua - --disable-aqua {
        set _(AQUA) $myCmd
      } -* {
        return -code error "wrong option: $myCmd"
      } default {
        set args [lrange $args $myIndex end]
        break
      }
    }
    incr myIndex
  }
  file mkdir $builddir $sourcedir
  if {$myPkgfile == "" && $pkgfile == ""} {
    set myPkgfile [file join $maindir sources kbskit-0.1 kbskit.kbs]
  }
  if {$myPkgfile != ""} {
    puts "=== Read definitions from $myPkgfile"
    source $myPkgfile
    set pkgfile $myPkgfile
  }
  return $args
}

#-------------------------------------------------------------------------------
# now process the command line to call one of the '::kbs::*' procs
proc kbs_main {argv} {
  # parse options
  set argv [::config::configure {*}$argv]
  # try to execute command
  set cmd [lindex $argv 0]
  if {[info commands ::kbs::$cmd] ne ""} {
    if {[catch {::kbs::$cmd {*}[lrange $argv 1 end]} myMsg]} {
      puts stderr "Error in execution of \"$cmd [lrange $argv 1 end]\":\n$myMsg"
      exit 1
    }
  } elseif {$cmd eq ""} {
    ::kbs::help
  } else {
    set cmdlist {}
    foreach knowncmd [lsort [info commands ::kbs::*]] {
      lappend cmdlist [namespace tail $knowncmd]
    }
    puts stderr "'$cmd' not found, should be one of: [join $cmdlist {, }]"
    exit 1
  }
  exit 0
}

#===============================================================================

#===============================================================================
# start application
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
  kbs_main $argv
}
