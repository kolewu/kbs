#! /bin/sh
#***F* KBS/kbs.tcl
#
# NAME
#  Kitgen Build System
#
# FUNCTION
#  Launch as 'kbs.tcl' to get a brief help text
#
# AUTHOR
#  <jcw@equi4.com> -- Initial ideas and kbskit sources
#
#  <r.zaumseil@freenet.de> -- kbskit TEA extension and development
#
# COPYRIGHT
#  See the file 'license.terms' for information on usage and redistribution of
#  this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# VERSION
#  $Id$
#===============================================================================
# bootstrap for building wish.. \
PREFIX=`pwd`/`uname` ;\
case `uname` in \
  MINGW*) DIR="win"; EXE="${PREFIX}/bin/tclsh85s.exe" ;; \
  *) DIR="unix"; EXE="${PREFIX}/bin/tclsh8.5" ;; \
esac ;\
if test ! -d sources ; then mkdir sources; fi;\
if test ! -x ${EXE} ; then \
  if test ! -d sources/tcl-8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tcl.cvs.sourceforge.net:/cvsroot/tcl -z3 co -r core-8-5-3 tcl && mv tcl tcl-8.5 ) ;\
  fi ;\
  if test ! -d sources/tk-8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -z3 co -r core-8-5-3 tk && mv tk tk-8.5 ) ;\
  fi ;\
  mkdir -p ${PREFIX}/tcl ;\
  ( cd ${PREFIX}/tcl && ../../sources/tcl-8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tcl ;\
  mkdir -p ${PREFIX}/tk ;\
  ( cd ${PREFIX}/tk && ../../sources/tk-8.5/${DIR}/configure --enable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} --with-tcl=${PREFIX}/lib && make install-binaries install-libraries ) ;\
fi ;\
if test ! -d sources/kbskit-8.5 ; then\
  ( cd sources && cvs -d :pserver:anonymous@kbskit.cvs.sourceforge.net:/cvsroot/kbskit -z3 co -r kbskit_0_2_3 kbskit && mv kbskit kbskit-8.5) ;\
fi ;\
exec ${EXE} "$0" ${1+"$@"}
#===============================================================================

catch {wm withdraw .};# do not show toplevel in command line mode

#***N* kbs.tcl/::kbs
# FUNCTION
#  The namespace contain the external callable functions.
# SYNOPSIS
namespace eval ::kbs {
# SOURCE
  namespace export help version kbs gui list require
  namespace export source configure make install clean distclean
#-------------------------------------------------------------------------------
}

#***f* ::kbs/help()
# FUNCTION
#  Display usage help message.
#  This is also the dafault action if no command was given.
# EXAMPLE
#  ./kbs.tcl help
# SYNOPSIS
proc ::kbs::help {} {
# SOURCE
  puts "Kitgen Build System ([version 0])"
  puts {kbs.tcl ?options? mode ?args?
options:
  -pkgfile=?file?      contain used Package definitions
                       (default is 'sources/kbskit-8.5/kbskit.kbs')
  -builddir=?dir?      build directory, used with [Builddir]
                       (default is './build$tcl_platform(os)')
  -CC=?command?        set configuration variable _(CC)
                       (default is 'gcc' or existing environment variable 'CC')
  -i -ignore           ignore errors and proceed (default is disabled)
  -r -recursive        recursive Require packages (default is disabled)
  -v -verbose          display running commands and command output
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
  version              return current version
  doc                  create documentation
  gui                  start graphical user interface
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
  namespace eval ::kbs::config {parray _}
}

#-------------------------------------------------------------------------------

#***f* ::kbs/version()
# FUNCTION
#  Return current version string of application.
#  The version string contain the '$Revision$' part of the repository.
# EXAMPLE
#  ./kbs.tcl version
# INPUTS
#  * print -- if true then also print versioin information on stdout (default '1')
# SYNOPSIS
proc ::kbs::version {{print 1}} {
# SOURCE
  set myVersion "0.2.3 [string trim {$Revision$} \$]"
  if {$print || $::kbs::config::verbose} {puts "Version: $myVersion"}
  return $myVersion
}

#-------------------------------------------------------------------------------

#***f* ::kbs/doc()
# FUNCTION
#  Create documentation from source file.
# EXAMPLE
#  ./kbs.tcl doc
#  ./kbs.tcl doc --internal --source_line_numbers
# INPUTS
#  * args -- additional arguments for the 'robodoc' call
# SYNOPSIS
proc ::kbs::doc {args} {
# SOURCE
  set myPwd [pwd]
  if {![file readable kbs.tcl]} {error "missing file ./kbs.tcl"}
  file mkdir doc
  set myFd [open [file join doc kbs.rc] w]
  puts $myFd "
source items:
  SYNOPSIS
  SOURCE
options:
  --src .
  --doc ./doc/kbs
  --singledoc
  --cmode
  --toc
  --index
  --sections
  --documenttitle \"Kitgen build system (Version [version])\"
  --html
headertypes:
  F  Files             robo_files       2
  N  Namespace         robo_namespace   1
ignore files:
  build*
  sources
  CVS
accept files:
  kbs.tcl
header markers:
  #***
end markers:
  #===
  #---
"
  close $myFd
  install robodoc\*
  cd $myPwd
  ::kbs::config::Run [::kbs::config::Builddir tcl]/bin/robodoc --rc doc/kbs.rc {*}$args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/gui()
# FUNCTION
#  Start graphical user interface.
# EXAMPLE
#  ./kbs.tcl gui
# INPUTS
#  * args -- currently not used
# SYNOPSIS
proc ::kbs::gui {args} {
# SOURCE
  ::kbs::gui::init $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/list()
# FUNCTION
#  Print list of available packages.
# EXAMPLE
#  ./kbs.tcl list kbspkg\*
# INPUTS
#  * pattern -- global search pattern for packages (default '*')
# SYNOPSIS
proc ::kbs::list {{pattern *}} {
# SOURCE
  puts [lsort -dict [array names ::kbs::config::packages $pattern]]
}

#-------------------------------------------------------------------------------

#***f* ::kbs/require()
# FUNCTION
#  Call the 'Require' part of the package definition.
#  Can be used to show dependencies of packages.
# EXAMPLE
#  ./kbs.tcl -r require kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::require {args} {
# SOURCE
  ::kbs::config::_init {Require} {Source Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/sources()
# FUNCTON
#  Call the 'Require' and 'Source' part of the package definition
#  to get the sources of packages.
# EXAMPLE
#  Get the sources of a package:
#    ./kbs.tcl sources kbspkg-8.5
#  Get the sources of a package and its dependencies:
#    ./kbs.tcl -r sources kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::sources {args} {
# SOURCE
  ::kbs::config::_init {Require Source} {Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/configure()
# FUNCTION
#  Call the 'Require', 'Source' and 'Configure' part of the package definition.
# EXAMPLE
#  Configure the package:
#    ./kbs.tcl configure kbspkg-8.5
#  Configure the package and its dependencies:
#    ./kbs.tcl -r configure kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::configure {args} {
# SOURCE
  ::kbs::config::_init {Require Source Configure} {Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/make()
# FUNCTION
#  Call the 'Require', 'Source', 'Configure' and 'Make' part of the package definition.
# EXAMPLE
#  Make the package:
#    ./kbs.tcl make kbspkg-8.5
#  Make the package and its dependencies:
#    ./kbs.tcl -r make kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::make {args} {
# SOURCE
  ::kbs::config::_init {Require Source Configure Make} {Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/test()
# FUNCTION
#  Call the 'Require', 'Source' and 'Test' part of the package definition.
#  Create the 'Builddir' and configure the package.
# EXAMPLE
#  Test the package:
#    ./kbs.tcl test kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::test {args} {
# SOURCE
  ::kbs::config::_init {Require Source Test} {Configure Make Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/install()
# FUNCTION
#  Call the 'Require', 'Source', 'Configure', 'Make' and 'Install' part of the
#  package definition.
# EXAMPLE
#  Install the package:
#    ./kbs.tcl install kbspkg-8.5
#  Install the package and its dependencies:
#    ./kbs.tcl -r install kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::install {args} {
# SOURCE
  ::kbs::config::_init {Require Source Configure Make Install} {Test Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/clean()
# FUNCTION
#  Call the 'Clean' part of the package definition.
# EXAMPLE
#  Clean the package:
#    ./kbs.tcl clean kbspkg-8.5
#  Clean the package and its dependencies:
#    ./kbs.tcl -r clean kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::clean {args} {
# SOURCE
  ::kbs::config::_init {Clean} {Require Source Configure Make Test Install} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/distclean()
# FUNCTION
#  Remove recursively the 'Makedir' of the package.
# EXAMPLE
#  Remove the package:
#    ./kbs.tcl distclean kbspkg-8.5
#  Remove the package and its dependencies:
#    ./kbs.tcl -r distclean kbspkg-8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::distclean {args} {
# SOURCE
  # Remove [Makedir] so everything will be rebuild again
  set myBody [info body ::kbs::config::Source];# save old body
  proc ::kbs::config::Source [info args ::kbs::config::Source] {
    set myDir [Makedir tcl]
    if {[file exist $myDir]} {
      puts "=== Distclean: $myDir"
      file delete -force $myDir
    }
  }
  ::kbs::config::_init {Require Source} {Configure Make Test Install Clean} $args
  proc ::kbs::config::Source [info args ::kbs::config::Source] $myBody;# restore old body
}

#===============================================================================

#***N* kbs.tcl/::kbs::config
# FUNCTION
#  Contain internally used functions and variables.
# SYNOPSIS
namespace eval ::kbs::config {
# SOURCE
  namespace export Srcdir Makedir Builddir Run tclConfig tkConfig Kit Tcl Patch
#-------------------------------------------------------------------------------

#***iv* ::kbs::config/maindir
# FUNCTION
#  Internal variable containing top level script directory.
# SYNOPSIS
  variable maindir [file normalize [file dirname [info script]]]

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/packages
# FUNCTION
#  Internal variable with package definitions from *.kbs files.
# SYNOPSIS
  variable packages

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/package
# FUNCTION
#  Internal variable containing current package name.
# SYNOPSIS
  variable package

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/srcdir
# FUNCTION
#  Internal variable containing current package source directory.
# SYNOPSIS
  variable srcdir

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/ready
# FUNCTION
#  Internal variable containing list of already prepared packages.
# SYNOPSIS
  variable ready [list]

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/proclist
# FUNCTION
#  Internal variable containing list of available procedures in Package´s.
# SYNOPSIS
  variable proclist
# SOURCE
  set proclist [list Srcdir Makedir Builddir Run tclConfig tkConfig Kit Tcl Patch]

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/tclConfig
# FUNCTION
#  Internal variable, set to 1 if tclConfig.sh was parsed.
# SYNOPSIS
  variable tclConfig
# SOURCE
  set tclConfig 0

#-------------------------------------------------------------------------------

#***iv* ::kbs::config/tkConfig
# FUNCTION
#  Internal variable, set to 1 if tkConfig.sh was parsed.
# SYNOPSIS
  variable tkConfig
# SOURCE
  set tkConfig 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/builddir
# FUNCTION
#  Default building directory.
#  Can be set with option '-builddir=..'
# EXAMPLE
#  .kbs.tcl -builddir=/my/build/dir install kbspkg-8.5
# SYNOPSIS
  variable builddir
# SOURCE
  set builddir [file join $maindir build[string map {{ } {}} $::tcl_platform(os)]]

#-------------------------------------------------------------------------------

#***v* ::kbs::config/ignore
# FUNCTION
#  If set (-i or -ignore switch) then proceed in case of errors.
# EXAMPLE
#  .kbs.tcl -i install kbspkg-8.5
#  .kbs.tcl -ignore install kbspkg-8.5
# SYNOPSIS
  variable ignore
# SOURCE
  set ignore 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/recursive
# FUNCTION
#  If set (-r or -recursive switch) then all Require packages are also used.
# EXAMPLE
#  .kbs.tcl -r install kbspkg-8.5
#  .kbs.tcl -recursive install kbspkg-8.5
# SYNOPSIS
  variable recursive
# SOURCE
  set recursive 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/verbose
# FUNCTION
#  If set (-v or -verbose switch) then all stdout will be removed.
# EXAMPLE
#  .kbs.tcl -v -r install kbspkg-8.5
#  .kbs.tcl -verbose -r install kbspkg-8.5
# SYNOPSIS
  variable verbose
# SOURCE
  set verbose 0

#-------------------------------------------------------------------------------

#----v* ::kbs::config/pkgfile --------------------------------------------------
# FUNCTION
#  Define startup kbs package definition file.
#  You can always 'source' the standard package definition file from
#  'sources/kbskit-8.5/kbskit.kbs'.
# EXAMPLE
#  ./kbs.tcl -pkgfile=/my/package/file list
# SYNOPSIS
  variable pkgfile
# SOURCE
  set pkgfile {}

#-------------------------------------------------------------------------------

#***v* ::kbs::config/_
# FUNCTION
# The array variable contain usefull information of the current building process.
# The configuration options, can be overwritten in Package definitions
# EXAMPLE
#  ./kbs.tcl -CC=/my/cc --disable-symbols 
# SYNOPSIS
  variable _
# SOURCE
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
  if {$::tcl_platform(platform) eq {windows}} {
    set _(DIR) {win}
  }

#-------------------------------------------------------------------------------
}

#***if* ::kbs::config/_init()
# FUNCTION
#  Initialize variables with respect to given configuration options
#  and command.
#  Process command in separate interpreter.
# INPUTS
#  * used -- list of available commands
#  * unused -- list of hidden or not available commands
#  * list -- list of packages
# SYNOPSIS
proc ::kbs::config::_init {used unused list} {
# SOURCE
  variable packages
  variable package
  variable ignore
  variable interp
  variable proclist

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
  foreach myProc $proclist {;# standard
    interp alias $interp $myProc {} ::kbs::config::$myProc {}
  }
  foreach myProc $used {;# available commands
    interp alias $interp $myProc {} ::kbs::config::$myProc
  }
  foreach myProc $unused {;# hidden commands
    $interp eval [list proc $myProc [info args ::kbs::config::$myProc] {}]
  }
  # now process command
  foreach myPattern $list {
    set myTargets [array names packages $myPattern]
    if {[llength $myTargets] == 0} {
      return -code error "no targets found for pattern: '$myPattern'"
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

#***f* ::kbs::config/Proc()
# FUNCTION
#  The 'Proc' command define a procedure the same way as the 'proc' command.
#  This procedure is then available in every 'Package' definition.
# INPUTS
#  * name    - name of the procedure
#  * arglist - argument list of the procedure
#  * body    - body of the procedure
# SYNOPSIS
proc ::kbs::config::Proc {name arglist body} {
# SOURCE
  variable proclist
  if {[string first : $name] != -1} {
    return -code error "wrong name of Proc: '$name'"
  }
  if {[lsearch -exact $proclist $name] != -1} {
    return -code error "Proc already exists: '$name'"
  }
  proc ::kbs::config::$name $arglist $body
  lappend proclist $name
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Package()
# FUNCTION
#  The 'Package' command is available in definition files.
# INPUTS
#  * name   -- unique name of package
#  * script -- contain definitions in the following order. For a detailed
#  description look in the related commands.
#    * Require
#    * Source
#    * Configure
#    * Make
#    * Install
#    * Clean
# SYNOPSIS
proc ::kbs::config::Package {name script} {
# SOURCE
  variable packages

  if {[info exist packages($name)]} {
    return -code error "package already exist: '$name'"}
  set packages($name) $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Require()
# FUNCTION
#  The given 'Package'´s in args will be recursively called.
# INPUTS
#  * args - one or more 'Package' names
# SYNOPSIS
proc ::kbs::config::Require {args} {
# SOURCE
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

#***f* ::kbs::config/Source()
# FUNCTION
#  Procedure to build source tree of current 'Package' definition.
# INPUTS
#  * pkg - name of package source dir under 'sources/'
#  * type - describe action to get source tree of 'Package'
#
#  Available are:
#   cvs path ... - call 'cvs -d path ...'
#   svn path     - call 'svn co path'
#   fetch path   - call 'http get path', unpack *.tar.gz or *.tgz files
#   tgz file     - call 'tar xzf file'
#   link path	 - use sources from "path"
# SYNOPSIS
proc ::kbs::config::Source {type args} {
# SOURCE
  variable package
  variable srcdir
  variable maindir

  set myDir [file join $maindir sources]
  ::kbs::gui::_state -running "" -package $package
  switch -- $type {
    script {
      cd $myDir
      set srcdir [file join $myDir [lindex $args 0]]
      if {![file exists $srcdir]} {
        eval [lindex $args 1]
      }
    } link {
      set srcdir [file join $myDir $args]
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
      set srcdir [file join $myDir $package]
      if {![file exists $srcdir]} {
        puts "=== Source eval: $package"
        cd $myDir
        eval [linsert $args 0 _src_$type]
      }
    } default {
      return -code error "wrong type '$type', should be link, cvs, svn, fetch or tgz"
    }
  }
}

#-------------------------------------------------------------------------------

#***if* ::kbs::config/_src_cvs()
# SYNOPSIS
proc ::kbs::config::_src_cvs {path args} {
# SOURCE
  if {$args eq {}} { set args [file tail $path] }
  if {[string first @ $path] < 0} { set path :pserver:anonymous@$path }
  Run cvs -d $path -z3 co -P -d tmp {*}$args
  file rename tmp [Srcdir tcl]
}

#-------------------------------------------------------------------------------
    
#***if* ::kbs::config/_src_svn()
# SYNOPSIS
proc ::kbs::config::_src_svn {path} {
# SOURCE
  Run svn co $path [Srcdir sys]
}

#-------------------------------------------------------------------------------
    
#***if* ::kbs::config/_src_fetch()
# SYNOPSIS
proc ::kbs::config::_src_fetch {path} {
# SOURCE
  variable verbose
  variable maindir

  set file [file join $maindir sources [file tail $path]]
  package require http
  if {$verbose} {puts "  fetching '$file'"}
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
      if {[catch {_src_tgz $file} myMsg]} {
        file delete $file
        return -code error $myMsg
      }
      file delete $file
    } *.zip {
      if {[catch {_src_zip $file} myMsg]} {
        file delete $file
        return -code error $myMsg
      }
      file delete $file
    } *.kit {
      if {$::tcl_platform(platform) eq {unix}} {
        file attributes $file -permissions u+x
      }
    }
  }
}

#-------------------------------------------------------------------------------

#***if* ::kbs::config/_src_tgz()
# SYNOPSIS
proc ::kbs::config::_src_tgz {file} {
# SOURCE
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

#***if* ::kbs::config/_src_zip()
# SYNOPSIS
proc ::kbs::config::_src_zip {file} {
# SOURCE
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

#***f* ::kbs::config/Configure()
# FUNCTION
#  If [Makedir] not exist create it and eval script.
# INPUTS
#  * script - tcl script to evaluate
# SYNOPSIS
proc ::kbs::config::Configure {script} {
# SOURCE
  variable verbose

  set myDir [Makedir tcl]
  if {[file exist $myDir]} return
  puts "=== Configure $myDir"
  if {$verbose} {puts $script}
  file mkdir $myDir; cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Make()
# FUNCTION
#  Eval script in [Makedir].
# INPUTS
#  * script - tcl script to evaluate
# SYNOPSIS
proc ::kbs::config::Make {script} {
# SOURCE
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} {
    return -code error "missing make directory: '$myDir'"
  }
  puts "=== Make $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install()
# FUNCTION
#  Eval script in [Makedir].
# INPUTS
#  * script - tcl script to evaluate
# SYNOPSIS
proc ::kbs::config::Install {script} {
# SOURCE
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} {
    return -code error "missing make directory: '$myDir'"
  }
  puts "=== Install $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Test()
# FUNCTION
#  Eval script in [Makedir].
# INPUTS
#  * script - tcl script to evaluate
# SYNOPSIS
proc ::kbs::config::Test {script} {
# SOURCE
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} return
  puts "=== Test $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Clean()
# FUNCTION
#  Eval script in [Makedir].
# INPUTS
#  * script - tcl script to evaluate
# SYNOPSIS
proc ::kbs::config::Clean {script} {
# SOURCE
  variable verbose

  set myDir [Makedir tcl]
  if {![file exist $myDir]} return
  puts "=== Clean $myDir"
  if {$verbose} {puts $script}
  cd $myDir; variable _; eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Srcdir()
# FUNCTION
#  Return fully qualified path to current 'Package' source dir.
# INPUTS
#  * type: one of 'tcl' used in tcl commands and 'sys' used in system commands
# SYNOPSIS
proc ::kbs::config::Srcdir {type} {
# SOURCE
  variable srcdir

  if {$::tcl_platform(platform) eq {windows} && $type eq {sys} && [string index $srcdir 1] eq {:}} {
    return /[string tolower [string index $srcdir 0]][string range $srcdir 2 end]
  }
  return $srcdir
}

#-------------------------------------------------------------------------------
 
#***f* ::kbs::config/Makedir()
# FUNCTION
#  Return fully qualified path to current 'Package' make dir.
#  Path is in dir [Builddir].
# INPUTS
#  * type: one of "tcl" used in tcl commands and 'sys' used in system commands
# SYNOPSIS
proc ::kbs::config::Makedir {type} {
# SOURCE
    variable package

    return [file join [Builddir $type] $package]
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Builddir()
# FUNCTION
#  Return path of current building dir. This dir contain all [Makedir]
#  and is used in the 'Install' target.
#  The dir can be set on the command line with '-builddir'.
# INPUTS
#  * type: one of 'tcl' used in tcl commands and 'sys' used in system commands
# SYNOPSIS
proc ::kbs::config::Builddir {type} {
# SOURCE
  variable builddir
  if {$::tcl_platform(platform) eq {windows} && $type eq {sys} && [string index $builddir 1] eq {:}} {
    return "/[string tolower [string index $builddir 0]][string range $builddir 2 end]"
  }
  return $builddir
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Run()
# FUNCTION
#  The procedure call the args as external command with options.
#  The procedure is available in all script arguments.
# INPUTS
#  * args -- containing external command
# SYNOPSIS
proc ::kbs::config::Run {args} {
# SOURCE
  variable verbose

  if {$verbose} {
    ::kbs::gui::_state -running $args
    puts $args
    exec {*}$args >@stdout 2>@stderr
  } else {
    ::kbs::gui::_state;# keep gui alive
    if {$::tcl_platform(platform) eq {windows}} {
      exec {*}$args >__dev__null__ 2>@stderr
    } else {
      exec {*}$args >/dev/null 2>@stderr
    }
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/tclConfig()
# FUNCTION
#  The procedure return the content of TCL* variables of the tclConfig.sh file.
#  The variables are also available in the '_' array.
#  The procedure is intended for use in the 'Configure' target.
# INPUTS
#  * varname -- name of variable to return
# SYNOPSIS
proc ::kbs::config::tclConfig {varname} {
# SOURCE
  variable builddir
  variable tclConfig
  variable _

  if {$tclConfig == 0} {;# read and parse file, save variables in _ array
    set myScript ""
    set myFd [open [file join $builddir lib tclConfig.sh] r]
    while {[gets $myFd myLine] != -1} {
      if {[string range $myLine 0 2] eq {TCL}} {
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

#***f* ::kbs::config/tkConfig()
# FUNCTION
#  The procedure return the content of TK* variables of the tkConfig.sh file.
#  The variables are also available in the '_' array.
#  The procedure is intended for use in the 'Configure' target.
# INPUTS
#  * varname -- name of variable to return
# SYNOPSIS
proc ::kbs::config::tkConfig {varname} {
# SOURCE
  variable builddir
  variable tkConfig
  variable _

  if {$tkConfig == 0} {;# read and parse file, save variables in _ array
    set myScript ""
    set myFd [open [file join $builddir lib tkConfig.sh] r]
    while {[gets $myFd myLine] != -1} {
      if {[string range $myLine 0 1] eq {TK}} {
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

#***f* ::kbs::config/Kit()
# FUNCTION
#  The procedure links the 'name.vfs' in to the [Makedir] and create
#  foreach name in 'args' a link from [Builddir]/lib in to 'name.vfs'/lib.
#  The names in 'args' may subdirectories under [Builddir]/lib. In the
#  'name.vfs'/lib the leading directory parts are removed. The same goes for
#  'name.vfs'.
#  * Kit configure name script ?package ..?
#    Create '[Makedir]/main.tcl' with:
#     - common startup code
#     - require statement for each package in 'packages' argument
#     - application startup from 'script' argument
#  * Kit make name ?librarydir ..?
#    Start in [Makedir]. Create 'name.vfs/lib'.
#    When existing link 'main.tcl' to 'name.vfs'.
#    Link everything from [Srcdir] into 'name.vfs'.
#    Link all package library dirs in '[Makedir]/name.vfs'/lib
#  * Kit install name ?option?
#    Without 'option' wrap kit and move to '[Builddir]/bin' otherwise with:
#    -cli create starpack with 'kbskit*cli*' executable
#    -gui create starpack with 'kbskit*gui*' executable
#    -dyn create starpack with 'kbskit*dyn*' executable
#    ... create starpack with given option as executable
#  * Kit clean name
#    Remove [Makedir]/'name.vfs'
#  * Kit run name ?args?
#    Run kit file with given command line 'args'
# EXAMPLE
#  Package tksqlite-0.5.6 {
#    Require kbskit-8.5 sdx.kit tktable-2.9 tktreectrl-2.2.3 sqlite-3.5.7
#    Source fetch http://reddog.s35.xrea.com/software/tksqlite-0.5.6.tar.gz
#    Configure { Kit configure tksqlite {source $::starkit::topdir/tksqlite.tcl} Tk }
#    Make { Kit make tksqlite sqlite3.5.7 Tktable2.9 treectrl2.2.3}
#    Install { Kit install tksqlite -gui }
#    Clean { Kit clean tksqlite }
#    Test { Kit run tksqlite }
#  }
# INPUTS
#  * mode -- one of configure, make, install, clean or run
#  * name -- name of vfs directory (without extension) to use
#  * args -- additional args
# SYNOPSIS
proc ::kbs::config::Kit {mode name args} {
# SOURCE
  switch -- $mode {
    configure {
      if {[file exists [file join [Srcdir sys] main.tcl]]} {
	return -code error "'main.tcl' existing in '[Srcdir sys]'"
      }
      # build standard 'main.tcl'
      set myFd [open main.tcl w]
      puts $myFd {#!/usr/bin/env tclkit
# startup
if {[catch {
  package require starkit
  if {[starkit::startup] eq "sourced"} return
}]} {
  namespace eval ::starkit { variable topdir [file dirname [info script]] }
  set auto_path [linsert $auto_path 0 [file join $::starkit::topdir lib]]
}
# used packages};# end of puts
      foreach myPkg [lrange $args 1 end] {
        puts $myFd "package require $myPkg"
      }
      puts $myFd "# start application\n[lindex $args 0]"
      close $myFd
    }
    make {
      #TODO 'file link ...' does not work under 'msys'
      set myVfs $name.vfs
      file delete -force $myVfs
      file mkdir [file join $myVfs lib]
      if {[file exists main.tcl]} {
        file copy main.tcl $myVfs
      }
      foreach myPath [glob -nocomplain [file join [Srcdir sys] *]] {
        if {[file tail $myPath] eq {lib}} continue
        Run ln -s $myPath [file join $myVfs [file tail $myPath]]
      }
      foreach myPath [glob -nocomplain [file join [Srcdir sys] lib *]] {
        Run ln -s $myPath [file join $myVfs lib [file tail $myPath]]
      }
      foreach myPath $args {
        Run ln -s [file join [Builddir sys] lib $myPath]\
		[file join $myVfs lib [file tail $myPath]]
      }
    }
    install {
      set myCli [glob [file join [Builddir tcl] bin kbskit8*cli*]]
      set myDyn [glob [file join [Builddir tcl] bin kbskit8*dyn*]]
      set myGui [glob [file join [Builddir tcl] bin kbskit8*gui*]]
      set mySdx [glob [file join [Builddir tcl] bin sdx.kit]]
      if {$args eq {}} {
        Run $myCli $mySdx wrap $name
        file rename -force $name [file join [Builddir tcl] bin $name.kit]
      } elseif {$args eq {-cli}} {
        Run $myDyn $mySdx wrap $name -runtime $myCli
        file rename -force $name [file join [Builddir tcl] bin]
      } elseif {$args eq {-dyn}} {
        Run $myCli $mySdx wrap $name -runtime $myDyn
        file rename -force $name [file join [Builddir tcl] bin]
      } elseif {$args eq {-gui}} {
        Run $myCli $mySdx wrap $name -runtime $myGui
        file rename -force $name [file join [Builddir tcl] bin]
      } else {
        Run $myCli $mySdx wrap $name -runtime {*}$args
        file rename -force $name [file join [Builddir tcl] bin]
      }
    }
    clean {
      file delete -force $name.vfs
    }
    run {
      set myExe [file join [Builddir tcl] bin $name]
      if {[file exists $myExe]} {
        Run $myExe {*}$args
      } else {
        Run [glob [file join [Builddir tcl] bin kbskit8*gui*]] $myExe.kit {*}$args
      }
    }
    default { return -code error "wrong mode: '$mode'" }
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Tcl()
# FUNCTION
#  Command to install tcl only packages.
#  Used in 'Install' part of 'Package' definitions.
# EXAMPLE
#  Package mentry-3.1 {
#    Require wcb-3.1
#    Source fetch http://www.nemethi.de/mentry/mentry3.1.tar.gz
#    Configure {}
#    Install { Tcl }
#  }
# INPUTS
#  * package -- install name of package, if missing then build from [Srcdir tcl]
# SYNOPSIS
proc ::kbs::config::Tcl {{package {}}} {
# SOURCE
  if {$package eq {}} {
    set myDst [file join [Builddir tcl] lib [file tail [Srcdir tcl]]]
  } else {
    set myDst [file join [Builddir tcl] lib $package]
  }
  file delete -force $myDst
  file copy -force [Srcdir tcl] $myDst
  if {![file exists [file join $myDst pkgIndex.tcl]]} {
    foreach {myPkg myVer} [split [file tail $myDst] -] break;
    if {$myVer eq {}} {set myVer 0.0}
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

#***f* ::kbs::config/Patch()
# FUNCTION
#  Patch source files.
# EXAMPLE
#      Patch [Srcdir tcl]/Makefile.in 139\
#        {INCLUDES       = @PKG_INCLUDES@ @TCL_INCLUDES@}\
#        {INCLUDES       = @TCL_INCLUDES@}
# INPUTS
#  * file -- name of file to patch
#  * lineoffset -- start point of patch, first line is 1
#  * oldtext -- part of file to replace
#  * newtext -- replacement text
# SYNOPSIS
proc ::kbs::config::Patch {file lineoffset oldtext newtext} {
# SOURCE
  variable verbose

  set myFd [open $file r]
  set myC [read $myFd]
  close $myFd
  # find oldtext
  set myIndex 0
  for {set myNr 1} {$myNr < $lineoffset} {incr myNr} {;# find line
    set myIndex [string first \n $myC $myIndex]
    if {$myIndex == -1} {
      puts "failed Patch: '$file' at $lineoffset -> eof at line $myNr"
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
    puts "skip Patch: '$file' at $lineoffset"
    if {$verbose} {puts "old version:\n$oldtext\nnew version:\n[string range $myTest 0 $myIndex]"}
    return -code error "patch failed"
  }
  # apply patch
  append myC $newtext[string range $myTest $myIndex end]
  set myFd [open $file w]
  puts $myFd $myC
  close $myFd
  if {$verbose} {puts "applied Patch: '$file' at $lineoffset"}
}

#-------------------------------------------------------------------------------

#***if* ::kbs::config/_configure()
# FUNCTION
#  Configure application with given command line arguments.
# INPUTS
#  * args -- option list
# SYNOPSIS
proc ::kbs::config::_configure {args} {
# SOURCE
  variable maindir
  variable builddir
  variable pkgfile
  variable ignore
  variable recursive
  variable verbose
  variable _

  set myPkgfile {}
  set myIndex 0
  foreach myCmd $args {
    switch -glob -- $myCmd {
      -pkgfile=* {
        set myPkgfile [file normalize [string range $myCmd 9 end]]
      } -builddir=* {
	set myFile [file normalize [string range $myCmd 10 end]]
        set builddir $myFile
      } -CC=* {
        set _(CC) [string range $myCmd 4 end]
      } -i - -ignore {
        set ignore 1
      } -r - -recursive {
        set recursive 1
      } -v - -verbose {
	set verbose 1
      } --enable-symbols - --disable-symbols {
        set _(SYMBOLS) $myCmd
      } --enable-64bit - --disable-64bit {;#TODO --enable-64bit-vis
        set _(64BIT) $myCmd
      } --enable-threads - --disable-threads {
        set _(THREADS) $myCmd
      } --enable-aqua - --disable-aqua {
        set _(AQUA) $myCmd
      } -* {
        return -code error "wrong option: '$myCmd'"
      } default {
        set args [lrange $args $myIndex end]
        break
      }
    }
    incr myIndex
  }
  file mkdir $builddir [file join $maindir sources]
  if {$myPkgfile eq {} && $pkgfile eq {}} {
    set myPkgfile [file join $maindir sources kbskit-8.5 kbskit.kbs]
  }
  if {$myPkgfile != ""} {
    puts "=== Read definitions from $myPkgfile"
    source $myPkgfile
    set pkgfile $myPkgfile
  }
  return $args
}

#===============================================================================

#***N* kbs.tcl/::kbs::gui
# FUNCTION
#  Contain variables and function of the graphical user interface.
# SYNOPSIS
namespace eval ::kbs::gui {
# SOURCE
  namespace export init

#-------------------------------------------------------------------------------

#***iv* ::kbs::gui/_
# SYNOPSIS
  variable _
# SOURCE
  set _(-command) {};# currently running command
  set _(-package) {};# current package 
  set _(-running) {};# currently executed command in 'Run'
  set _(widgets) [list];# list of widgets to disable if command is running
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/init()
# FUNCTION
#  Build and initialize graphical user interface.
# INPUTS
#  * args -- currently ignored
# SYNOPSIS
proc ::kbs::gui::init {args} {
# SOURCE
  variable _

  package require Tk

  grid rowconfigure . 4 -weight 1
  grid columnconfigure . 1 -weight 1

  # variables
  set w .var
  grid [::ttk::labelframe $w -text {Option variables} -padding 3]\
	-row 1 -column 1 -sticky ew
  grid columnconfigure $w 2 -weight 1

  grid [::ttk::label $w.1 -anchor e -text {-pkgfile=}]\
	-row 1 -column 1 -sticky ew
  grid [::ttk::label $w.2 -anchor w -relief ridge -textvariable ::kbs::config::pkgfile]\
	-row 1 -column 2 -sticky ew

  grid [::ttk::label $w.4 -anchor e -text {-builddir=}]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::label $w.5 -anchor w -relief ridge -textvariable ::kbs::config::builddir]\
	-row 2 -column 2 -sticky ew
  grid [::ttk::button $w.6 -width 3 -text {...} -command {::kbs::gui::_set_builddir} -padding 0]\
	-row 2 -column 3 -sticky ew

  grid [::ttk::label $w.7 -anchor e -text {-CC=}]\
	-row 3 -column 1 -sticky ew
  grid [::ttk::entry $w.8 -textvariable ::kbs::config::_(CC)]\
	-row 3 -column 2 -sticky ew
  grid [::ttk::button $w.9 -width 3 -text {...} -command {::kbs::gui::_set_cc} -padding 0]\
	-row 3 -column 3 -sticky ew

  lappend _(widgets) $w.6 $w.8 $w.9

  # select options
  set w .sel
  grid [::ttk::labelframe $w -text {Select options} -padding 3]\
	-row 2 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 3 -weight 1

  grid [::ttk::checkbutton $w.1 -text -ignore -onvalue 1 -offvalue 0 -variable ::kbs::config::ignore]\
	-row 1 -column 1 -sticky ew
  grid [::ttk::checkbutton $w.2 -text -recursive -onvalue 1 -offvalue 0 -variable ::kbs::config::recursive]\
	-row 1 -column 2 -sticky ew
  grid [::ttk::checkbutton $w.3 -text -verbose -onvalue 1 -offvalue 0 -variable ::kbs::config::verbose]\
	-row 1 -column 3 -sticky ew

  lappend _(widgets) $w.1 $w.2 $w.3

  # toggle options
  set w .tgl
  grid [::ttk::labelframe $w -text {Toggle options} -padding 3]\
	-row 3 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 3 -weight 1

  grid [::ttk::label $w.1 -text AQUA= -anchor e]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::checkbutton $w.2 -width 17 -onvalue --enable-aqua -offvalue --disable-aqua -variable ::kbs::config::_(AQUA) -textvariable ::kbs::config::_(AQUA)]\
	-row 2 -column 2 -sticky ew
  grid [::ttk::label $w.3 -text SYMBOLS= -anchor e]\
	-row 2 -column 3 -sticky ew
  grid [::ttk::checkbutton $w.4 -width 17 -onvalue --enable-symbols -offvalue --disable-symbols -variable ::kbs::config::_(SYMBOLS) -textvariable ::kbs::config::_(SYMBOLS)]\
	-row 2 -column 4 -sticky ew
  grid [::ttk::label $w.5 -text 64BIT= -anchor e]\
	-row 3 -column 1 -sticky ew
  grid [::ttk::checkbutton $w.6 -width 17 -onvalue --enable-64bit -offvalue --disable-64bit -variable ::kbs::config::_(64BIT) -textvariable ::kbs::config::_(64BIT)]\
	-row 3 -column 2 -sticky ew
  grid [::ttk::label $w.7 -text THREADS= -anchor e]\
	-row 3 -column 3 -sticky ew
  grid [::ttk::checkbutton $w.8 -width 17 -onvalue --enable-threads -offvalue --disable-threads -variable ::kbs::config::_(THREADS) -textvariable ::kbs::config::_(THREADS)]\
	-row 3 -column 4 -sticky ew

  lappend _(widgets) $w.2 $w.4 $w.6 $w.8

  # packages
  set w .pkg
  grid [::ttk::labelframe $w -text {Available Packages} -padding 3]\
	-row 4 -column 1 -sticky ew
  grid rowconfigure $w 1 -weight 1
  grid columnconfigure $w 1 -weight 1

  grid [::listbox $w.lb -yscrollcommand "$w.2 set" -selectmode single]\
	-row 1 -column 1 -sticky nesw
  eval $w.lb insert end [lsort -dict [array names ::kbs::config::packages]]
  grid [::ttk::scrollbar $w.2 -orient vertical -command "$w.lb yview"]\
	-row 1 -column 2 -sticky ns

  # commands
  set w .cmd
  grid [::ttk::labelframe $w -text Commands -padding 3]\
	-row 5 -column 1 -sticky ew
  grid columnconfigure $w 1 -weight 1
  grid columnconfigure $w 2 -weight 1
  grid columnconfigure $w 3 -weight 1
  grid columnconfigure $w 4 -weight 1
  grid [::ttk::button $w.1 -text sources -command {::kbs::gui::_command sources}]\
	-row 1 -column 1 -sticky ew
  grid [::ttk::button $w.2 -text configure -command {::kbs::gui::_command configure}]\
	-row 1 -column 2 -sticky ew
  grid [::ttk::button $w.3 -text make -command {::kbs::gui::_command make}]\
	-row 1 -column 3 -sticky ew
  grid [::ttk::button $w.4 -text install -command {::kbs::gui::_command install}]\
	-row 1 -column 4 -sticky ew
  grid [::ttk::button $w.5 -text test -command {::kbs::gui::_command test}]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::button $w.6 -text clean -command {::kbs::gui::_command clean}]\
	-row 2 -column 2 -sticky ew
  grid [::ttk::button $w.7 -text distclean -command {::kbs::gui::_command distclean}]\
	-row 2 -column 3 -sticky ew
  grid [::ttk::button $w.8 -text EXIT -command {exit}]\
	-row 2 -column 4 -sticky ew

  lappend _(widgets) $w.1 $w.2 $w.3 $w.4 $w.5 $w.6 $w.7 $w.8

  # status
  set w .state
  grid [::ttk::labelframe $w -text {Status messages} -padding 3]\
	-row 6 -column 1 -sticky ew
  grid columnconfigure $w 2 -weight 1

  grid [::ttk::label $w.1_1 -anchor w -text Command:]\
	-row 1 -column 1 -sticky ew
  grid [::ttk::label $w.1_2 -anchor w -relief sunken -textvariable ::kbs::gui::_(-command)]\
	-row 1 -column 2 -sticky ew
  grid [::ttk::label $w.2_1 -anchor w -text Package:]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::label $w.2_2 -anchor w -relief sunken -textvariable ::kbs::gui::_(-package)]\
	-row 2 -column 2 -sticky nesw
  grid [::ttk::label $w.3_1 -anchor w -text Running:]\
	-row 3 -column 1 -sticky ew
  grid [::ttk::label $w.3_2 -anchor w -relief sunken -textvariable ::kbs::gui::_(-running) -wraplength 300]\
	-row 3 -column 2 -sticky ew

  wm title . "Kitgen build system ([::kbs::version])"
  wm protocol . WM_DELETE_WINDOW {exit}
  wm deiconify .
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_set_builddir()
# FUNCTION
#  Set configuration variable '::kbs::config::builddir'.
# SYNOPSIS
proc ::kbs::gui::_set_builddir {} {
# SOURCE
  set myDir [tk_chooseDirectory -parent . -title "Select 'builddir'"\
	-initialdir $::kbs::config::builddir]
  if {$myDir eq {}} return
  file mkdir $myDir
  set ::kbs::config::builddir $myDir
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_set_cc()
# FUNCTION
#  Set configuration variable '::kbs::config::_(CC)'.
# SYNOPSIS
proc ::kbs::gui::_set_cc {} {
# SOURCE
  set myFile [tk_getOpenFile -parent . -title "Select C-compiler"\
	-initialdir [file dirname $::kbs::config::_(CC)]]
  if {$myFile eq {}} return
  set ::kbs::config::_(CC) $myFile
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_command()
# FUNCTION
#  Function to process currently selected packages and provide
#  feeedback results.
# INPUTS
#  * cmd -- selected command from gui
# SYNOPSIS
proc ::kbs::gui::_command {cmd} {
# SOURCE
  variable _

  set mySelection [.pkg.lb curselection]
  if {[llength $mySelection] == 0} {
    tk_messageBox -parent . -type ok -title {No selection} -message {Please select at least one package from the list.}
    return
  }
  foreach myW $_(widgets) { $myW configure -state disabled }
  set myTarget [.pkg.lb get $mySelection]
  ::kbs::gui::_state -running "" -package "" -command "'$cmd $myTarget' ..."
  if {[catch {console show}]} {
    set myCmd "::kbs::$cmd $myTarget"
  } else {
    set myCmd "consoleinterp eval ::kbs::$cmd $myTarget"
  }
  if {[catch {{*}$myCmd} myMsg]} {
    tk_messageBox -parent . -type ok -title {Execution failed} -message "'$cmd $myTarget' failed!\n$myMsg" -icon error
    ::kbs::gui::_state -command "'$cmd $myTarget' failed!"
  } else {
    tk_messageBox -parent . -type ok -title {Execution finished} -message "'$cmd $myTarget' successfull." -icon info
    ::kbs::gui::_state -running "" -package "" -command "'$cmd $myTarget' done."
  }
  foreach myW $_(widgets) { $myW configure -state normal }
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_state()
# FUNCTION
#  Change displayed state informations and update application.
# INPUTS
#  args -- list of option-value pairs with:
#   -running 'text' - text to display in the 'Running:' state
#   -package 'text' - text to display in the 'Package:' state
#   -command 'text' - text to display in the 'Command:' state
# SYNOPSIS
proc ::kbs::gui::_state {args} {
# SOURCE
  variable _

  array set _ $args
  update
}

#===============================================================================

#***f* ::/kbs_main()
# FUNCTION
#  Process the command line to call one of the '::kbs::*' functions
# INPUTS
#  * argv -- list of provided command line arguments
# SYNOPSIS
proc ::kbs_main {argv} {
# SOURCE
  # parse options
  set argv [::kbs::config::_configure {*}$argv]
  # try to execute command
  set myCmd [lindex $argv 0]
  if {[info commands ::kbs::$myCmd] ne ""} {
    if {[catch {::kbs::$myCmd {*}[lrange $argv 1 end]} myMsg]} {
      puts stderr "Error in execution of '$myCmd [lrange $argv 1 end]':\n$myMsg"
      exit 1
    }
    if {$myCmd != "gui"} {
      exit 0
    }
  } elseif {$myCmd eq {}} {
    ::kbs::help
    exit 0
  } else {
    set myList {}
    foreach myKnownCmd [lsort [info commands ::kbs::*]] {
      lappend myList [namespace tail $myKnownCmd]
    }
    puts stderr "'$myCmd' not found, should be one of: [join $myList {, }]"
    exit 1
  }
}

#-------------------------------------------------------------------------------

# start application
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
  ::kbs_main $argv
}
