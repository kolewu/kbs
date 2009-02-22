#! /bin/sh
#***F* KBS/kbs.tcl
#
# NAME
#  Kitgen Build System
#
# FUNCTION
#  Launch as 'kbs.tcl' to get a brief help text.
#
# AUTHOR
#  <jcw@equi4.com> -- Initial ideas and kbskit sources
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
  if test ! -d sources/tcl8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tcl.cvs.sourceforge.net:/cvsroot/tcl -z3 co -r core-8-5-6 tcl && mv tcl tcl8.5 ) ;\
  fi ;\
  if test ! -d sources/tk8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -z3 co -r core-8-5-6 tk && mv tk tk8.5 ) ;\
  fi ;\
  mkdir -p ${PREFIX}/tcl ;\
  ( cd ${PREFIX}/tcl && ../../sources/tcl8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tcl ;\
  mkdir -p ${PREFIX}/tk ;\
  ( cd ${PREFIX}/tk && ../../sources/tk8.5/${DIR}/configure --enable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} --with-tcl=${PREFIX}/lib && make install-binaries install-libraries ) ;\
fi ;\
if test ! -d sources/kbskit0.3 ; then\
  ( cd sources && cvs -d :pserver:anonymous@kbskit.cvs.sourceforge.net:/cvsroot/kbskit -z3 co -r kbskit_0_3 kbskit && mv kbskit kbskit0.3) ;\
fi ;\
exec ${EXE} "$0" ${1+"$@"}
#===============================================================================
set ::kbs {0.3};# current version and version of used kbskit

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
#  This is also the default action if no command was given.
# EXAMPLE
#  ./kbs.tcl help
# SYNOPSIS
proc ::kbs::help {} {
# SOURCE
  puts "[::kbs::config::Get application]
kbs.tcl ?options? mode ?args?
options (configuration variables are available with \[Get ..\]):
  -pkgfile=?file?      contain used Package definitions
                       (default is 'sources/kbskit${::kbs}/kbskit.kbs')
  -builddir=?dir?      set used building directory containing all package
                       specific 'makedir' (default is './build\$tcl_platform(os)')
  -i -ignore           ignore errors and proceed (default is disabled)
  -r -recursive        recursive Require packages (default is disabled)
  -v -verbose          display running commands and command output
  -CC=?command?        set configuration variable 'CC'
                       (default is 'gcc' or existing environment variable 'CC')
  -bi=?package ..?     set configuration variable 'bi' (default is '')
                       to list of packages for use in batteries included builds
  --enable-symbols
  --disable-symbols    set configuration variable 'symbols'
  --enable-64bit
  --disable-64bit      set configuration variable '64bit'
  --enable-threads
  --disable-threads    set configuration variable 'threads'
  --enable-aqua
  --disable-aqua       set configuration variable 'aqua'
  Mk4tcl based 'tclkit' interpreter build options:
  -mk                  add 'mk-cli|dyn|gui' to variable 'kit'
  -mk-cli              add 'mk-cli' to variable 'kit'
  -mk-dyn              add 'mk-dyn' to variable 'kit'
  -mk-gui              add 'mk-gui' to variable 'kit'
  -mk-bi               add 'mk-bi' to variable 'kit'
  Vqtcl based 'tclkit lite' interpreter build options:
  -vq                  add 'vq-cli|dyn|gui' to variable 'kit'
  -vq-cli              add 'vq-cli' to variable 'kit'
  -vq-dyn              add 'vq-dyn' to variable 'kit'
  -vq-gui              add 'vq-gui' to variable 'kit'
  -vq-bi               add 'vq-bi' to variable 'kit'
  If no interpreter option is given '-vq' will be asumed.
Additional Variables for use with \[Get ..\]):
  application          name of application including version number
  builddir             common build dir (can be set with -builddir=..)
  makedir              package specific dir under 'builddir'
  srcdir               package specific source dir under './sources/'
  builddir-sys
  makedir-sys
  srcdir-sys           system specific version (p.e. windows C:\\.. -> /..)
  sys                  TEA specific platform subdir (win, unix)
  TCL*                 TCL* variables from tclConfig.sh, loaded on demand
  TK*                  TK* variables from tkConfig.sh, loaded on demand
mode:
  help                 this text
  doc                  create program documentation (./doc/kbs.html)
  gui                  start graphical user interface
  list ?pattern?       list packages matching pattern (default is *)
  require package ..   return call trace of packages
  sources package ..   get package source files (under sources/)
  configure package .. create 'makedir' (in 'builddir') and configure package
  make package ..      make package (in 'makedir')
  install package ..   install package (in 'builddir')
  test package ..      test package
  clean package ..     remove make targets
  distclean package .. remove 'makedir'
package is used for glob style matching against available packages
(Beware, you need to hide the special meaning of * like foo\*)

The following configuration variables can be used:"
  namespace eval ::kbs::config {parray _}
}

#-------------------------------------------------------------------------------

#***f* ::kbs/doc()
# FUNCTION
#  Create documentation from source file.
# EXAMPLE
#  * create public documentation:
#    ./kbs.tcl doc
#  * create documentation for everything:
#    ./kbs.tcl doc --internal --source_line_numbers
# INPUTS
#  * args -- additional arguments for the 'robodoc' call
#            see also <http://sourceforge.net/projects/robodoc/>
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
  --documenttitle \"[::kbs::config::Get application]\"
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
  ::kbs::config::Run [::kbs::config::Get builddir]/bin/robodoc --rc doc/kbs.rc {*}$args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/gui()
# FUNCTION
#  Start graphical user interface.
# EXAMPLE
#  * simple start with default options:
#    ./kbs.tcl gui
# INPUTS
#  * args -- currently not used
# SYNOPSIS
proc ::kbs::gui {args} {
# SOURCE
  ::kbs::gui::_init $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/list()
# FUNCTION
#  Print list of available packages.
# EXAMPLE
#  * list all packages starting with 'kbs'
#    ./kbs.tcl list kbs\*
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
#  * show dependencies of package:
#    ./kbs.tcl -r require kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::require {args} {
# SOURCE
  ::kbs::config::_init {Source Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/sources()
# FUNCTON
#  Call the 'Require' and 'Source' part of the package definition
#  to get the sources of packages. Sources are installed under './sources/'.
# EXAMPLE
#  * get the sources of a package:
#    ./kbs.tcl sources kbspkg8.5
#  * get the sources of a package and its dependencies:
#    ./kbs.tcl -r sources kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::sources {args} {
# SOURCE
  ::kbs::config::_init {Configure Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/configure()
# FUNCTION
#  Call the 'Require', 'Source' and 'Configure' part of the package definition.
#  The configuration is done in 'makedir'.
# EXAMPLE
#  * configure the package:
#    ./kbs.tcl configure kbspkg8.5
#  * configure the package and its dependencies:
#    ./kbs.tcl -r configure kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::configure {args} {
# SOURCE
  ::kbs::config::_init {Make Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/make()
# FUNCTION
#  Call the 'Require', 'Source', 'Configure' and 'Make' part of the package definition.
#  The build is done in 'makedir'.
# EXAMPLE
#  * make the package:
#    ./kbs.tcl make kbspkg8.5
#  * make the package and its dependencies:
#    ./kbs.tcl -r make kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::make {args} {
# SOURCE
  ::kbs::config::_init {Test Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/test()
# FUNCTION
#  Call the 'Require', 'Source' and 'Test' part of the package definition.
#  The testing starts in 'makedir'
# EXAMPLE
#  * test the package:
#    ./kbs.tcl test kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::test {args} {
# SOURCE
  ::kbs::config::_init {Configure Make Install Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/install()
# FUNCTION
#  Call the 'Require', 'Source', 'Configure', 'Make' and 'Install' part of the
#  package definition.
#  The install dir is 'builddir'.
# EXAMPLE
#  * install the package:
#    ./kbs.tcl install kbspkg8.5
#  * install the package and its dependencies:
#    ./kbs.tcl -r install kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::install {args} {
# SOURCE
  ::kbs::config::_init {Test Clean} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/clean()
# FUNCTION
#  Call the 'Clean' part of the package definition.
#  The clean starts in 'makedir'.
# EXAMPLE
#  * clean the package:
#    ./kbs.tcl clean kbspkg8.5
#  * clean the package and its dependencies:
#    ./kbs.tcl -r clean kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::clean {args} {
# SOURCE
  ::kbs::config::_init {Require Source Configure Make Test Install} $args
}

#-------------------------------------------------------------------------------

#***f* ::kbs/distclean()
# FUNCTION
#  Remove the 'makedir' of the package so everything can be rebuild again
#  This is necessary if there are problems in the configuration part of
#  the package.
# EXAMPLE
#  * remove the package:
#    ./kbs.tcl distclean kbspkg8.5
#  * remove the package and its dependencies:
#    ./kbs.tcl -r distclean kbspkg8.5
# INPUTS
#  * args -- list of packages
# SYNOPSIS
proc ::kbs::distclean {args} {
# SOURCE
  set myBody [info body ::kbs::config::Source];# save old body
  proc ::kbs::config::Source [info args ::kbs::config::Source] {
    set myDir [Get makedir]
    if {[file exist $myDir]} {
      puts "=== Distclean: $myDir"
      file delete -force $myDir
    }
  }
  ::kbs::config::_init {Configure Make Test Install Clean} $args
  proc ::kbs::config::Source [info args ::kbs::config::Source] $myBody;# restore old body
}

#===============================================================================

#***N* kbs.tcl/::kbs::config
# FUNCTION
#  Contain internally used functions and variables.
# SYNOPSIS
namespace eval ::kbs::config {
# SOURCE
  # public functions
  namespace export Run Get Require Source Configure Make Install Clean Test
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

#***iv* ::kbs::config/ready
# FUNCTION
#  Internal variable containing list of already prepared packages.
# SYNOPSIS
  variable ready [list]

#-------------------------------------------------------------------------------

#***v* ::kbs::config/ignore
# FUNCTION
#  If set (-i or -ignore switch) then proceed in case of errors.
# EXAMPLE
#  * try to build all given packages:
#    ./kbs.tcl -i install bwidget\* mentry\*
#    ./kbs.tcl -ignore install bwidget\* mentry\*
# SYNOPSIS
  variable ignore
# SOURCE
  set ignore 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/recursive
# FUNCTION
#  If set (-r or -recursive switch) then all packages under 'Require'
#  are also used.
# EXAMPLE
#  * build all packages recursively:
#    ./kbs.tcl -r install kbspkg8.5
#    ./kbs.tcl -recursive install kbspkg8.5
# SYNOPSIS
  variable recursive
# SOURCE
  set recursive 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/verbose
# FUNCTION
#  If set (-v or -verbose switch) then all stdout will be removed.
# EXAMPLE
#  * print additional information while processing:
#    ./kbs.tcl -v -r install bwidget\*
#    ./kbs.tcl -verbose -r install bwidget\*
# SYNOPSIS
  variable verbose
# SOURCE
  set verbose 0

#-------------------------------------------------------------------------------

#***v* ::kbs::config/pkgfile
# FUNCTION
#  Define startup kbs package definition file.
#  Default is './sources/kbskit${::kbs}/kbskit.kbs'.
# EXAMPLE
#  * start with own package definition file:
#    ./kbs.tcl -pkgfile=/my/package/file list
# SYNOPSIS
  variable pkgfile
# SOURCE
  set pkgfile {}

#-------------------------------------------------------------------------------

#***v* ::kbs::config/_
# FUNCTION
# The array variable contain usefull information of the current building process.
# The configuration options, can be set on startup.
# It is also possible to set values in the 'Package' definition file
# outside the 'Package definition (p.e. 'set ::kbs::config::_(CC) g++').
# EXAMPLE
#  * build debugging version:
#    ./kbs.tcl -CC=/my/cc --enable-symbols install tclx8.4
#  * create kbsmk8.5-[cli|dyn|gui] interpreter:
#    ./kbs.tcl -mk install kbskit8.5
#  * create kbsvq8.5-bi interpreter with packages:
#    ./kbs.tcl -vq-bi -bi="tclx8.4 tdom0.8.2" install kbskit8.5
#  * get list of available packages with:
#    ./kbs.tcl list
# SYNOPSIS
  variable _
# SOURCE
  if {[info exist ::env(CC)]} {;# used compiler
    set _(CC)		$::env(CC)
  } else {
    set _(CC)		{gcc}
  }
  set _(aqua)		{--enable-aqua};# tcl
  set _(symbols)	{--disable-symbols};# build without debug symbols
  set _(threads)	{--enable-threads};# build with thread support
  set _(64bit)		{--disable-64bit};# build without 64 bit support
  if {$::tcl_platform(platform) eq {windows}} {;# configuration system subdir
    set _(sys)		{win}
  } else {
    set _(sys)		{unix}
  }
  set _(kit)		[list];# list of interpreter builds
  set _(bi)		[list];# list of packages for batteries included interpreter builds
  set _(makedir)	{};# package specific build dir
  set _(makedir-sys)	{};# package and system specific build dir
  set _(srcdir)		{};# package specific source dir
  set _(srcdir-sys)	{};# package and system specific source dir
  set _(builddir)	[file join $maindir build[string map {{ } {}} $::tcl_platform(os)]]
  set _(builddir-sys)	$_(builddir)
  set _(application)	"Kitgen build system (${::kbs})";# application name
#-------------------------------------------------------------------------------
}

#***if* ::kbs::config/_sys()
# FUNCTION
#  Return platfrom specific file name p.e. windows C:\... -> /...
# INPUTS
#  file - file name to convert
# SYNOPSIS
proc ::kbs::config::_sys {file} {
# SOURCE
  if {$::tcl_platform(platform) eq {windows} && [string index $file 1] eq {:}} {
    return "/[string tolower [string index $file 0]][string range $file 2 end]"
  } else {
    return $file
  }
}

#-------------------------------------------------------------------------------

#***if* ::kbs::config/_init()
# FUNCTION
#  Initialize variables with respect to given configuration options
#  and command.
#  Process command in separate interpreter.
# INPUTS
#  * unused -- list of hidden or not available commands
#  * list -- list of packages
# SYNOPSIS
proc ::kbs::config::_init {unused list} {
# SOURCE
  variable packages
  variable package
  variable ignore
  variable interp

  # reset to clean state
  variable ready	[list]
  variable _
  array unset _ TCL_*
  array unset _ TK_*

  # create interpreter with commands
  set interp [interp create]
  foreach myProc [namespace export] {
    if {$myProc in $unused} {
      $interp eval [list proc $myProc [info args ::kbs::config::$myProc] {}]
    } else {
      interp alias $interp $myProc {} ::kbs::config::$myProc
    }
  }
  # now process command
  foreach myPattern $list {
    set myTargets [array names packages $myPattern]
    if {[llength $myTargets] == 0} {
      return -code error "no targets found for pattern: '$myPattern'"
    }
    foreach package $myTargets {
      set _(makedir) [file join $_(builddir) $package]
      set _(makedir-sys) [file join $_(builddir-sys) $package]
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

#***f* ::kbs::config/Package()
# FUNCTION
#  The 'Package' command is available in definition files.
#  All 'Package' definitions will be saved for further use.
# INPUTS
#  * name   -- unique name of package
#  * script -- contain definitions in the following order.
#              The common functions 'Run' and 'Get' can be used in every
#              'script'. For a detailed description and command specific
#              additional functions look in the related commands.
#    'Require script'   -- define dependencies
#    'Source script'    -- method to get sources
#    'Configure script' -- configure package
#    'Make script'      -- build package
#    'Install script'   -- install package
#    'Clean script'     -- clean package
# SYNOPSIS
proc ::kbs::config::Package {name script} {
# SOURCE
  variable packages

  if {[info exist packages($name)]} {
    return -code error "package already exist: '$name'"
  }
  set packages($name) $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Require()
# FUNCTION
#  Evaluate the given script. Add additional packages with the 'Use' function.
# INPUTS
#  * script - containing package dependencies.
#  Available functions are: 'Run', 'Get'
#    'Use ?package..?' -- see '::kbs::config/Require-Use'
# SYNOPSIS
proc ::kbs::config::Require {script} {
# SOURCE
  variable recursive
  if {$recursive == 0} return
  variable verbose
  variable interp
  variable package

  puts "=== Require $package"
  if {$verbose} {puts $script}
  interp alias $interp Use {} ::kbs::config::Require-Use
  $interp eval $script
  foreach my {Use} {interp alias $interp $my}
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Require-Use()
# FUNCTION
#  Define dependencies used with '-r' switch.
#  The given 'Package'´s in args will then be recursively called.
# INPUTS
#  * args - one or more 'Package' names
# SYNOPSIS
proc ::kbs::config::Require-Use {args} {
# SOURCE
  variable packages
  variable ready
  variable package
  variable ignore
  variable interp
  variable _
  puts "=== Require $args"

  set myPackage $package
  set myTargets [list]
  foreach package $args {
    # already loaded
    if {[lsearch $ready $package] != -1} continue
    # single target name
    if {[info exist packages($package)]} {
      set _(makedir) [file join $_(builddir) $package]
      set _(makedir-sys) [file join $_(builddir-sys) $package]
      puts "=== Require eval: $package"
      array set _ {srcdir {} srcdir-sys {}}
      if {[catch {$interp eval $packages($package)} myMsg]} {
        puts "=== Require error: $package\n$myMsg"
        if {$ignore == 0} {
          return -code error "Require failed for: $package"
        }
        foreach my {Link Cvs Svn Tgz Zip Http Script Patch Kit Tcl Libdir} {
          interp alias $interp $my;# clear specific procedures
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
  set _(makedir) [file join $_(builddir) $package]
  set _(makedir-sys) [file join $_(builddir-sys) $package]
  puts "=== Require leave: $args"
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Source()
# FUNCTION
#  Procedure to build source tree of current 'Package' definition.
# INPUTS
#  * script - one or more of the following functions to get the sources
#             of the current package. The sources should be placed under
#             './sources/'.
#  Available functions are: 'Run', 'Get'
#   'Cvs path ...' - call 'cvs -d path co -d 'srcdir' ...'
#   'Svn path'     - call 'svn co path 'srcdir''
#   'Http path'    - call 'http get path', unpack *.tar.gz or *.tgz files
#   'Tgz file'     - call 'tar xzf file'
#   'Zip file'     - call 'unzip file'
#   'Link package' - use sources from "package"
#   'Script text'  - eval 'text'
# SYNOPSIS
proc ::kbs::config::Source {script} {
# SOURCE
  variable interp
  variable package
  variable _

  ::kbs::gui::_state -running "" -package $package
  foreach my {Script Http Link Cvs Svn Tgz Zip} {
    interp alias $interp $my {} ::kbs::config::Source- $my
  }
  array set _ {srcdir {} srcdir-sys {}}
  $interp eval $script
  foreach my {Script Http Link Cvs Svn Tgz Zip} {
    interp alias $interp $my
  }
  if {$_(srcdir) eq {}} {
    return -code error "no sources"
  }
  set _(srcdir-sys) [_sys $_(srcdir)]
}

#-------------------------------------------------------------------------------

#***if* ::kbs::config/Source-()
# FUNCTION
#  Process internal 'Source' commands.
# INPUTS
#  * type - one of the valid source types, see function 'Source'.
#  * args - depending on the given 'type' 
# SYNOPSIS
proc ::kbs::config::Source- {type args} {
  variable maindir
  variable package
  variable verbose
  variable pkgfile
  variable _

  cd [file join $maindir sources]
  switch -- $type {
    Link {
      if {$args == $package} {return -code error "wrong link source: $args"}
      set myDir [file join $maindir sources $args]
      if {![file exists $myDir]} {
        puts "=== Source $type $package"
        cd $maindir
        if {[catch {
          #exec [pwd]/kbs.tcl sources $args >@stdout 2>@stderr
          if {$verbose} {
            Run [pwd]/kbs.tcl -pkgfile=$pkgfile -builddir=$_(builddir) -v sources $args
          } else {
            Run [pwd]/kbs.tcl -pkgfile=$pkgfile -builddir=$_(builddir) sources $args
          }
        } myMsg]} {
          file delete -force $myDir
          if {$verbose} {puts $myMsg}
        }
      }
    } Script {
      set myDir [file join $maindir sources $package]
      if {![file exists $myDir]} {
        puts "=== Source $type $package"
        if {[catch {eval $args} myMsg]} {
          file delete -force $myDir
          if {$verbose} {puts $myMsg}
        }
      }
    } Cvs {
      set myDir [file join $maindir sources $package]
      if {![file exists $myDir]} {
        set myPath [lindex $args 0]
        set args [lrange $args 1 end]
        if {$args eq {}} { set args [file tail $myPath] }
        if {[string first @ $myPath] < 0} {set myPath :pserver:anonymous@$myPath}
        puts "=== Source $type $package"
        if {[catch {Run cvs -d $myPath -z3 co -P -d $package {*}$args} myMsg]} {
          file delete -force $myDir
          if {$verbose} {puts $myMsg}
        }
      }
    } Svn {
      set myDir [file join $maindir sources $package]
        if {![file exists $myDir]} {
        puts "=== Source $type $package"
        if {[catch {Run svn co $args $package} myMsg]} {
          file delete -force $myDir
          if {$verbose} {puts $myMsg}
        }
      }
    } Http {
      set myDir [file join $maindir sources $package]
      if {![file exists $myDir]} {
        set myFile [file normalize ./[file tail $args]]
        puts "=== Source $type $package"
        if {[catch {
          package require http
          set fd [open $myFile w]
          set t [http::geturl $args -binary 1 -channel $fd]
          close $fd
          scan [http::code $t] {HTTP/%f %d} ver ncode
          #if {$_(-verbose)} {puts [http::status $t]}
          http::cleanup $t
          if {$ncode != 200 || [file size $myFile] == 0} {error "fetch failed"}
          # unpack if necessary
          switch -glob $myFile {
            *.tgz - *.tar.gz {
              Source- Tgz $myFile
              file delete $myFile
            } *.zip {
              Source- Zip $myFile
              file delete $myFile
            } *.kit {
              if {$::tcl_platform(platform) eq {unix}} {
                file attributes $myFile -permissions u+x
              }
              if {$myFile ne $myDir} {
                file mkdir $myDir
	        file rename $myFile $myDir
              }
            }
          }
        } myMsg]} {
          file delete -force $myDir $myFile
          if {$verbose} {puts $myMsg}
        }
      }
    } Tgz - Zip {
      set myDir [file join $maindir sources $package]
      if {![file exists $myDir]} {
        puts "=== Source $type $package"
        if {[catch {
          file delete -force $myDir.tmp
          file mkdir $myDir.tmp
          cd $myDir.tmp
          if {$type eq {Tgz}} {exec gzip -dc $args | tar xf -}
          if {$type eq {Zip}} {exec unzip $args}
          cd [file join $maindir sources]
          set myList [glob $myDir.tmp/*]
          if {[llength $myList] == 1 && [file isdir $myList]} {
            file rename $myList $myDir
            file delete $myDir.tmp
          } else {
            file rename $myDir.tmp $myDir
          }
        } myMsg]} {
          file delete -force $myDir.tmp $myDir
          if {$verbose} {puts $myMsg}
        }
      }
    } default {
      return -code error "wrong type '$type'"
    }
  }
  if {[file exists $myDir]} {
    set _(srcdir) $myDir
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Configure()
# FUNCTION
#  If 'makedir' not exist create it and eval script.
# INPUTS
#  * script - tcl script to evaluate with one or more of the following
#             functions to help configure the current package
#  Available functions are: 'Run', 'Get'
#    'Patch file lineoffset oldtext newtext' -- see '::kbs::config/Configure-Patch'
#    'Kit ?main.tcl? ?pkg..?'                -- see '::kbs::config/Configure-Kit'
#             
# SYNOPSIS
proc ::kbs::config::Configure {script} {
# SOURCE
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {[file exist $myDir]} return
  puts "=== Configure $myDir"
  if {$verbose} {puts $script}
  foreach my {Patch Kit} {
    interp alias $interp $my {} ::kbs::config::Configure-$my
  }
  file mkdir $myDir
  $interp eval [list cd $myDir]
  $interp eval $script
  foreach my {Patch Kit} {interp alias $interp $my}
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Configure-Patch()
# FUNCTION
#  Patch source files.
# EXAMPLE
#      Patch [Get srcdir]/Makefile.in 139\
#        {INCLUDES       = @PKG_INCLUDES@ @TCL_INCLUDES@}\
#        {INCLUDES       = @TCL_INCLUDES@}
# INPUTS
#  * file       -- name of file to patch
#  * lineoffset -- start point of patch, first line is 1
#  * oldtext    -- part of file to replace
#  * newtext    -- replacement text
# SYNOPSIS
proc ::kbs::config::Configure-Patch {file lineoffset oldtext newtext} {
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

#***f* ::kbs::config/Configure-Kit()
# FUNCTION
#  This function create a 'makedir'/main.tcl with:
#    * common startup code
#    * require statement for each package in 'args' argument
#    * application startup from 'maincode' argument
# EXAMPLE
#  Package tksqlite0.5.6 {
#    Require { Use kbskit8.5 sdx.kit tktable2.10 treectrl2.2.3 sqlite3.6.10 }
#    Source {Http http://reddog.s35.xrea.com/software/tksqlite-0.5.6.tar.gz}
#    Configure { Kit {source $::starkit::topdir/tksqlite.tcl} Tk }
#    Make { Kit tksqlite sqlite3.6.10 tktable2.10 treectrl2.2.3}
#    Install { Kit tksqlite -gui }
#    Clean { file delete -force tksqlite.vfs }
#    Test { Kit tksqlite }
#  }
# INPUTS
#  * maincode -- startup code
#  * args     -- additional args
# SYNOPSIS
proc ::kbs::config::Configure-Kit {maincode args} {
# SOURCE
  variable _

  if {[file exists [file join [Get srcdir-sys] main.tcl]]} {
    return -code error "'main.tcl' existing in '[Get srcdir-sys]'"
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

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Make()
# FUNCTION
#  Evaluate script in 'makedir'.
# INPUTS
#  * script - tcl script to evaluate with one or more of the following
#             functions to help building the current package
#  Available functions are: 'Run', 'Get'
#    'Kit name ?pkglibdir..?' -- see '::kbs::config::Make-Kit'
# SYNOPSIS
proc ::kbs::config::Make {script} {
# SOURCE
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {![file exist $myDir]} {
    return -code error "missing make directory: '$myDir'"
  }
  puts "=== Make $myDir"
  if {$verbose} {puts $script}
  interp alias $interp Kit {} ::kbs::config::Make-Kit
  $interp eval [list cd $myDir]
  $interp eval $script
  foreach my {Kit} {interp alias $interp $my}
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Make-Kit()
# FUNCTION
#  The procedure links the 'name.vfs' in to the 'makedir' and create
#  foreach name in 'args' a link from 'builddir'/lib in to 'name.vfs'/lib.
#  The names in 'args' may subdirectories under 'builddir'/lib. In the
#  'name.vfs'/lib the leading directory parts are removed. The same goes for
#  'name.vfs'.
#  * Kit name ?librarydir ..?
#    Start in 'makedir'. Create 'name.vfs/lib'.
#    When existing link 'main.tcl' to 'name.vfs'.
#    Link everything from [Srcdir] into 'name.vfs'.
#    Link all package library dirs in ''makedir'/name.vfs'/lib
# EXAMPLE
#  Package tksqlite0.5.6 {
#    Require { Use kbskit8.5 sdx.kit tktable2.10 treectrl2.2.3 sqlite3.6.10 }
#    Source {Http http://reddog.s35.xrea.com/software/tksqlite-0.5.6.tar.gz}
#    Configure { Kit {source $::starkit::topdir/tksqlite.tcl} Tk }
#    Make { Kit tksqlite sqlite3.6.10 tktable2.10 treectrl2.2.3}
#    Install { Kit tksqlite -gui }
#    Clean { file delete -force tksqlite.vfs }
#    Test { Kit tksqlite }
#  }
# INPUTS
#  * name -- name of vfs directory (without extension) to use
#  * args -- additional args
# SYNOPSIS
proc ::kbs::config::Make-Kit {name args} {
# SOURCE
  variable _

  #TODO 'file link ...' does not work under 'msys'
  set myVfs $name.vfs
  file delete -force $myVfs
  file mkdir [file join $myVfs lib]
  if {[file exists main.tcl]} {
    file copy main.tcl $myVfs
  }
  foreach myPath [glob -nocomplain -directory [Get srcdir] -tails *] {
    if {$myPath in {lib CVS}} continue
    Run ln -s [file join [Get srcdir-sys] $myPath] [file join $myVfs $myPath]
  }
  foreach myPath [glob -nocomplain -directory [Get srcdir] -tails lib/*] {
    Run ln -s [file join [Get srcdir-sys] $myPath] [file join $myVfs $myPath]
  }
  foreach myPath $args {
    Run ln -s [file join [Get builddir-sys] lib $myPath]\
	[file join $myVfs lib [file tail $myPath]]
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install()
# FUNCTION
#  Eval script in 'makedir'.
# INPUTS
#  * script - tcl script to evaluate with one or more of the following
#             functions to install the current package
#  Available functions are: 'Run', 'Get'
#    'Libdir dirname' -- see '::kbs::config::Install-Libdir'
#    'Kit name args'  -- see '::kbs::config::Install-Kit'
#    'Tcl ?package?'  -- see '::kbs::config::Install-Tcl'
# SYNOPSIS
proc ::kbs::config::Install {script} {
# SOURCE
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {![file exist $myDir]} {
    return -code error "missing make directory: '$myDir'"
  }
  puts "=== Install $myDir"
  if {$verbose} {puts $script}
  foreach my {Kit Tcl Libdir} {
    interp alias $interp $my {} ::kbs::config::Install-$my
  }
  $interp eval [list cd $myDir]
  $interp eval $script
  foreach my {Kit Tcl Libdir} {interp alias $interp $my}
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install-Libdir()
# FUNCTION
#  Move given 'dir' in 'builddir'tcl/lib to package name.
#  This function is necessary to install all packages with the same
#  naming convention (lower case name plus version number).
# INPUTS
#  dirname -- package library dir, not conforming lower case with version number
# SYNOPSIS
proc ::kbs::config::Install-Libdir {dirname} {
# SOURCE
  variable verbose
  variable package

  set mySrc [Get builddir]/lib/$dirname
  set myDst [Get builddir]/lib/$package
  if {[file exists $mySrc]} {
    if {$verbose} {puts "$mySrc -> $myDst"}
    file rename $mySrc $mySrc.Libdir;# because of windows
    file delete -force $myDst;# remove old version
    file rename $mySrc.Libdir $myDst
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install-Kit()
# FUNCTION
#    Without 'option' wrap kit and move to 'builddir'/bin otherwise with:
#    -mk-cli create starpack with 'kbsmk*-cli*' executable
#    -mk-dyn create starpack with 'kbsmk*-dyn*' executable
#    -mk-gui create starpack with 'kbsmk*-gui*' executable
#    -vq-cli create starpack with 'kbsvq*-cli*' executable
#    -vq-dyn create starpack with 'kbsvq*-dyn*' executable
#    -vq-gui create starpack with 'kbsvq*-gui*' executable
#    ... create starpack with given option as executable
# EXAMPLE
#  Package tksqlite0.5.6 {
#    Require { Use kbskit8.5 sdx.kit tktable2.10 treectrl2.2.3 sqlite3.6.10 }
#    Source {Http http://reddog.s35.xrea.com/software/tksqlite-0.5.6.tar.gz}
#    Configure { Kit {source $::starkit::topdir/tksqlite.tcl} Tk }
#    Make { Kit tksqlite sqlite3.6.10 tktable2.10 treectrl2.2.3}
#    Install { Kit tksqlite -gui }
#    Clean { file delete -force tksqlite.vfs }
#    Test { Kit tksqlite }
#  }
# INPUTS
#  * mode -- one of configure, make, install, clean or run
#  * name -- name of vfs directory (without extension) to use
#  * args -- additional args
# SYNOPSIS
proc ::kbs::config::Install-Kit {name args} {
# SOURCE
  variable _

  set myTmp [file join [Get builddir] bin]
  if {$args eq {-mk-cli}} {
    set myRun [glob $myTmp/kbsmk*-cli*]
  } elseif {$args eq {-mk-dyn}} {
    set myRun [glob $myTmp/kbsmk*-dyn*]
  } elseif {$args eq {-mk-gui}} {
    set myRun [glob $myTmp/kbsmk*-gui*]
  } elseif {$args eq {-vq-cli}} {
    set myRun [glob $myTmp/kbsvq*-cli*]
  } elseif {$args eq {-vq-dyn}} {
    set myRun [glob $myTmp/kbsvq*-dyn*]
  } elseif {$args eq {-vq-gui}} {
    set myRun [glob $myTmp/kbsvq*-gui*]
  } else {
    set myRun $args
  }
  set myExe {}
  foreach myExe [glob $myTmp/kbs*-cli* $myTmp/kbs*-dyn* $myTmp/kbs*-gui*] {
    if {$myExe ne $myRun} break
  }
  if {$myExe eq {}} { return -code error "no intepreter in '$myTmp'" }
  if {$myRun eq {}} {
    Run $myExe [file join [Get builddir] bin sdx.kit] wrap $name
    file rename -force $name [file join [Get builddir] bin $name.kit]
  } else {
    Run $myExe [file join [Get builddir] bin sdx.kit] wrap $name -runtime {*}$myRun
    if {$_(DIR) eq {win}} {
      file rename -force $name [file join [Get builddir] bin $name.exe]
    } else {
      file rename -force $name [file join [Get builddir] bin]
    }
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install-Tcl()
# FUNCTION
#  Command to install tcl only packages.
#  Used in 'Install' part of 'Package' definitions.
# EXAMPLE
#  Package mentry-3.1 {
#    Require { Use wcb-3.1 }
#    Source { Http http://www.nemethi.de/mentry/mentry3.1.tar.gz }
#    Configure {}
#    Install { Tcl }
#  }
# INPUTS
#  * package -- install name of package, if missing then build from [Get srcdir]
# SYNOPSIS
proc ::kbs::config::Install-Tcl {{pkgname {}}} {
# SOURCE
  if {$pkgname eq {}} {
    set myDst [file join [Get builddir] lib [file tail [Get srcdir]]]
  } else {
    set myDst [file join [Get builddir] lib $pkgname]
  }
  file delete -force $myDst
  file copy -force [Get srcdir] $myDst
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

#***f* ::kbs::config/Test()
# FUNCTION
#  Eval script in 'makedir'.
# INPUTS
#  * script - tcl script to evaluate with one or more of the following
#             functions to help testing the current package
#  Available functions are: 'Run', 'Get'
#    'Kit name args -- see '::kbs::config::Test-Kit'
# SYNOPSIS
proc ::kbs::config::Test {script} {
# SOURCE
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {![file exist $myDir]} return
  puts "=== Test $myDir"
  if {$verbose} {puts $script}
  interp alias $interp Kit {} ::kbs::config::Test-Kit
  $interp eval [list cd $myDir]
  $interp eval $script
  foreach my {Kit} {interp alias $interp $my}
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Test-Kit()
# FUNCTION
#    Run kit file with given command line 'args'
# EXAMPLE
#  Package tksqlite0.5.6 {
#    Require { Use kbskit8.5 sdx.kit tktable2.10 treectrl2.2.3 sqlite3.6.10 }
#    Source {Http http://reddog.s35.xrea.com/software/tksqlite-0.5.6.tar.gz}
#    Configure { Kit {source $::starkit::topdir/tksqlite.tcl} Tk }
#    Make { Kit tksqlite sqlite3.6.10 tktable2.10 treectrl2.2.3}
#    Install { Kit tksqlite -gui }
#    Clean { file delete -force tksqlite.vfs }
#    Test { Kit tksqlite }
#  }
# INPUTS
#  * name -- name of vfs directory (without extension) to use
#  * args -- additional args
# SYNOPSIS
proc ::kbs::config::Test-Kit {mode name args} {
# SOURCE
  variable _

  set myExe [file join [Get builddir] bin $name]
  if {[file exists $myExe]} {
    Run $myExe {*}$args
  } else {
    set myTmp [file join [Get builddir] bin]
    set myTmp [glob $myTmp/kbs*-gui* $myTmp/kbs*-dyn* $myTmp/kbs*-cli*]
    Run [lindex $myTmp 0] $myExe.kit {*}$args
  }
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Clean()
# FUNCTION
#  Eval script in 'makedir'.
# INPUTS
#  * script - tcl script to evaluate with one or more of the following
#             functions to help cleaning the current package
#  Available functions are: 'Run', 'Get'
# SYNOPSIS
proc ::kbs::config::Clean {script} {
# SOURCE
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {![file exist $myDir]} return
  puts "=== Clean $myDir"
  if {$verbose} {puts $script}
  $interp eval [list cd $myDir]
  $interp eval $script
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Get()
# FUNCTION
#  Return value of given variable name.
#  If 'var' starts with 'TCL_' tclConfig.sh will be parsed for TCL_* variables.
#  If 'var' starts with 'TK_' tkConfig.sh will be parsed for TK_* variables.
# INPUTS
#  * var: name of variable.
# SYNOPSIS
proc ::kbs::config::Get {var} {
# SOURCE
  variable _

  if {[string range $var 0 3] eq {TCL_} && ![info exists _(TCL_)]} {
    set myScript ""
    set myFd [open [file join $_(builddir) lib tclConfig.sh] r]
    set myC [read $myFd]
    close $myFd
    foreach myLine [split $myC \n] {
      if {[string range $myLine 0 3] ne {TCL_}} continue
      set myNr [string first = $myLine]
      if {$myNr == -1} continue
      append myScript "set _([string range $myLine 0 [expr {$myNr - 1}]]) "
      incr myNr 1
      append myScript [list [string map {' {}} [string range $myLine $myNr end]]]\n
    }
    eval $myScript
    set _(TCL_) 1
  }
  if {[string range $var 0 2] eq {TK_} && ![info exists _(TK_)]} {
    set myScript ""
    set myFd [open [file join $_(builddir) lib tkConfig.sh] r]
    set myC [read $myFd]
    close $myFd
    foreach myLine [split $myC \n] {
      if {[string range $myLine 0 2] ne {TK_}} continue
      set myNr [string first = $myLine]
      if {$myNr == -1} continue
      append myScript "set _([string range $myLine 0 [expr {$myNr - 1}]]) "
      incr myNr 1
      append myScript [list [string map {' {}} [string range $myLine $myNr end]]]\n
    }
    eval $myScript
    set tkConfig 1
  }
  return $_($var)
}

#-------------------------------------------------------------------------------

#***f* ::kbs::config/Run()
# FUNCTION
#  The procedure call the args as external command with options.
#  The procedure is available in all script arguments.
#  If the 'verbose' switch is on the 'args' will be printed.
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

#***if* ::kbs::config/_configure()
# FUNCTION
#  Configure application with given command line arguments.
# INPUTS
#  * args -- option list
# SYNOPSIS
proc ::kbs::config::_configure {args} {
# SOURCE
  variable maindir
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
        set _(builddir) $myFile
      } -bi=* {
        set _(bi) [string range $myCmd 4 end]
      } -CC=* {
        set _(CC) [string range $myCmd 4 end]
      } -i - -ignore {
        set ignore 1
      } -r - -recursive {
        set recursive 1
      } -v - -verbose {
	set verbose 1
      } --enable-symbols - --disable-symbols {
        set _(symbols) $myCmd
      } --enable-64bit - --disable-64bit {;#TODO --enable-64bit-vis
        set _(64bit) $myCmd
      } --enable-threads - --disable-threads {
        set _(threads) $myCmd
      } --enable-aqua - --disable-aqua {
        set _(aqua) $myCmd
      } -mk {
        lappend _(kit) mk-cli mk-dyn mk-gui
      } -mk-cli {
        lappend _(kit) mk-cli
      } -mk-dyn {
        lappend _(kit) mk-dyn
      } -mk-gui {
        lappend _(kit) mk-gui
      } -mk-bi {
        lappend _(kit) mk-bi
      } -vq {
        lappend _(kit) vq-cli vq-dyn vq-gui
      } -vq-cli {
        lappend _(kit) vq-cli
      } -vq-dyn {
        lappend _(kit) vq-dyn
      } -vq-gui {
        lappend _(kit) vq-gui
      } -vq-bi {
        lappend _(kit) vq-bi
      } -* {
        return -code error "wrong option: '$myCmd'"
      } default {
        set args [lrange $args $myIndex end]
        break
      }
    }
    incr myIndex
  }
  set _(builddir-sys) [_sys $_(builddir)]
  set _(kit) [lsort -unique $_(kit)];# all options only once
  if {$_(kit) eq {}} {set _(kit) vq};# default setting
  file mkdir $_(builddir) [file join $maindir sources]
  if {$myPkgfile eq {} && $pkgfile eq {}} {
    set myPkgfile [file join $maindir sources kbskit$::kbs kbskit.kbs]
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

#-------------------------------------------------------------------------------

#***iv* ::kbs::gui/_
# FUNCTION
#  Containing internal gui state values.
# SYNOPSIS
  variable _
# SOURCE
  set _(-command) {};# currently running command
  set _(-package) {};# current package 
  set _(-running) {};# currently executed command in 'Run'
  set _(widgets) [list];# list of widgets to disable if command is running
}

#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_init()
# FUNCTION
#  Build and initialize graphical user interface.
# INPUTS
#  * args -- currently ignored
# SYNOPSIS
proc ::kbs::gui::_init {args} {
# SOURCE
  variable _

  package require Tk

  grid rowconfigure . 5 -weight 1
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
  grid [::ttk::label $w.5 -anchor w -relief ridge -textvariable ::kbs::config::_(builddir)]\
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

  grid [::ttk::label $w.1 -text {-aqua=} -anchor e]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::checkbutton $w.2 -width 17 -onvalue --enable-aqua -offvalue --disable-aqua -variable ::kbs::config::_(aqua) -textvariable ::kbs::config::_(aqua)]\
	-row 2 -column 2 -sticky ew
  grid [::ttk::label $w.3 -text {-symbols=} -anchor e]\
	-row 2 -column 3 -sticky ew
  grid [::ttk::checkbutton $w.4 -width 17 -onvalue --enable-symbols -offvalue --disable-symbols -variable ::kbs::config::_(symbols) -textvariable ::kbs::config::_(symbols)]\
	-row 2 -column 4 -sticky ew
  grid [::ttk::label $w.5 -text {-64bit=} -anchor e]\
	-row 3 -column 1 -sticky ew
  grid [::ttk::checkbutton $w.6 -width 17 -onvalue --enable-64bit -offvalue --disable-64bit -variable ::kbs::config::_(64bit) -textvariable ::kbs::config::_(64bit)]\
	-row 3 -column 2 -sticky ew
  grid [::ttk::label $w.7 -text {-threads=} -anchor e]\
	-row 3 -column 3 -sticky ew
  grid [::ttk::checkbutton $w.8 -width 17 -onvalue --enable-threads -offvalue --disable-threads -variable ::kbs::config::_(threads) -textvariable ::kbs::config::_(threads)]\
	-row 3 -column 4 -sticky ew

  lappend _(widgets) $w.2 $w.4 $w.6 $w.8

  # kit build options
  set w .kit
  grid [::ttk::labelframe $w -text {Kit build options} -padding 3]\
	-row 4 -column 1 -sticky ew
  grid columnconfigure $w 2 -weight 1

  grid [::ttk::label $w.1 -text {'kit'} -anchor e]\
	-row 1 -column 1 -sticky ew
  grid [::ttk::combobox $w.2 -state readonly -textvariable ::kbs::config::_(kit) -values {mk-cli mk-dyn mk-gui mk-bi {mk-cli mk-dyn mk-gui} vq-cli vq-dyn vq-gui vq-bi {vq-cli vq-dyn vq-gui} {mk-cli mk-dyn mk-gui vq-cli vq-dyn vq-gui}}]\
	-row 1 -column 2 -sticky ew
  grid [::ttk::label $w.3 -text -bi= -anchor e]\
	-row 2 -column 1 -sticky ew
  grid [::ttk::entry $w.4 -textvariable ::kbs::config::_(bi)]\
	-row 2 -column 2 -sticky ew
  grid [::ttk::button $w.5 -text {set '-bi' with selected packages} -command {::kbs::gui::_set_bi} -padding 0]\
	-row 3 -column 2 -sticky ew

  # packages
  set w .pkg
  grid [::ttk::labelframe $w -text {Available Packages} -padding 3]\
	-row 5 -column 1 -sticky ew
  grid rowconfigure $w 1 -weight 1
  grid columnconfigure $w 1 -weight 1

  grid [::listbox $w.lb -yscrollcommand "$w.2 set" -selectmode extended]\
	-row 1 -column 1 -sticky nesw
  eval $w.lb insert end [lsort -dict [array names ::kbs::config::packages]]
  grid [::ttk::scrollbar $w.2 -orient vertical -command "$w.lb yview"]\
	-row 1 -column 2 -sticky ns

  # commands
  set w .cmd
  grid [::ttk::labelframe $w -text Commands -padding 3]\
	-row 6 -column 1 -sticky ew
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
	-row 7 -column 1 -sticky ew
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

  wm title . [::kbs::config::Get application]
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
	-initialdir $::kbs::config::_(builddir)]
  if {$myDir eq {}} return
  file mkdir $myDir
  set ::kbs::config::_(builddir) $myDir
  set ::kbs::config::_(builddir-sys) [::kbs::config::_sys $myDir]
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

#***if* ::kbs::gui/_set_bi()
# FUNCTION
#  Set configuration variable '::kbs::config::_(bi)'.
# SYNOPSIS
proc ::kbs::gui::_set_bi {} {
# SOURCE
  set my [list]
  foreach myNr [.pkg.lb curselection] {
    lappend my [.pkg.lb get $myNr]
  }
  set ::kbs::config::_(bi) $my
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
  set myCmd ::kbs::$cmd
  foreach myNr $mySelection {
    lappend myCmd [.pkg.lb get $myNr]
  }
  ::kbs::gui::_state -running "" -package "" -command "'$myCmd' ..."
  if {![catch {console show}]} {
    set myCmd "consoleinterp eval $myCmd"
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
  if {[catch {set argv [::kbs::config::_configure {*}$argv]} myMsg]} {
    puts stderr "Option error (try './kbs.tcl' to get brief help): $myMsg"
    exit 1
  }
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
