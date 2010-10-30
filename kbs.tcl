#! /bin/sh
#***F* KBS/kbs.tcl
#
# NAME
#	Kitgen Build System
#
# SYNOPSIS
#	kbs.tcl ?-option? .. ?command? ..
#
#	For available options and commands see help()
#	or type './kbs.tcl help'.
#
#	The following common commands are supported:
#	* help -- see help()
#	* doc -- see doc()
#	* license -- see license()
#	* config -- see config()
#	* gui -- see gui()
#	The following package related commands are supported:
#	* require -- see require()
#	* sources -- see sources()
#	* make -- see make()
#	* install -- see install()
#	* clean -- see clean()
#	* test -- see test()
#	* distclean -- see distclean()
#
# DESCRIPTION
#	Tcl/Tk software building environment.
#	Build of starpacks, starkits, binary extensions and other software.
#	Already existing package definitions can be found under Package.
#
# EXAMPLE
#	get brief help text
#	  ./kbs.tcl
#	  tclsh kbs.tcl
#	get full documentation in ./doc/kbs.html
#	  ./kbs.tcl doc
#	start in graphical mode
#	  ./kbs.tcl gui
#	build batteries included kbskit interpreter
#	  ./kbs.tcl -r -vq-bi install kbskit8.5 
#
# AUTHOR
#	<jcw@equi4.com> -- Initial ideas and kbskit sources
#
#	<r.zaumseil@freenet.de> -- kbskit TEA extension and development
#
# COPYRIGHT
#	Call './kbs.tcl license' or search for 'set ::kbs(license)' in this file
#	for information on usage and redistribution of this file,
#	and for a DISCLAIMER OF ALL WARRANTIES.
#
# VERSION
#	$Id$
#===============================================================================
# check startup dir containing current file\
if test ! -r ./kbs.tcl ; then \
  echo "Please start from directory containing the file 'kbs.tcl'"; exit 1 ;\
fi;
# bootstrap for building wish.. \
PREFIX=`pwd`/`uname` ;\
case `uname` in \
  MINGW*) DIR="win"; EXE="${PREFIX}/bin/tclsh85s.exe" ;; \
  *) DIR="unix"; EXE="${PREFIX}/bin/tclsh8.5" ;; \
esac ;\
if test ! -d sources ; then mkdir sources; fi;\
if test ! -x ${EXE} ; then \
  if test ! -d sources/tcl8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tcl.cvs.sourceforge.net:/cvsroot/tcl -z3 co -r core-8-5-9 tcl && mv tcl tcl8.5 ) ;\
  fi ;\
  if test ! -d sources/tk8.5 ; then \
    ( cd sources && cvs -d :pserver:anonymous@tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -z3 co -r core-8-5-9 tk && mv tk tk8.5 ) ;\
  fi ;\
  mkdir -p ${PREFIX}/tcl ;\
  ( cd ${PREFIX}/tcl && ../../sources/tcl8.5/${DIR}/configure --disable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} && make install-binaries install-libraries ) ;\
  rm -rf ${PREFIX}/tcl ;\
  mkdir -p ${PREFIX}/tk ;\
  ( cd ${PREFIX}/tk && ../../sources/tk8.5/${DIR}/configure --enable-shared --prefix=${PREFIX} --exec-prefix=${PREFIX} --with-tcl=${PREFIX}/lib && make install-binaries install-libraries ) ;\
fi ;\
exec ${EXE} "$0" ${1+"$@"}
#===============================================================================

#***N* KBS/::
# SOURCE
catch {wm withdraw .};# do not show toplevel in command line mode
#-------------------------------------------------------------------------------

#***v* ::/$::kbs
# DESCRIPTION
#	Array variable with static informations.
# SOURCE
set ::kbs(version) {0.4.1};# current version and version of used kbskit
set ::kbs(license) {
This software is copyrighted by Rene Zaumseil (the maintainer).
The following terms apply to all files associated with the software
unless explicitly disclaimed in individual files.

This software is copyrighted by the Regents of the University of
California, Sun Microsystems, Inc., Scriptics Corporation, ActiveState
Corporation and other parties.  The following terms apply to all files
associated with the software unless explicitly disclaimed in
individual files.

The author hereby grant permission to use, copy, modify, distribute,
and license this software and its documentation for any purpose, provided
that existing copyright notices are retained in all copies and that this
notice is included verbatim in any distributions. No written agreement,
license, or royalty fee is required for any of the authorized uses.
Modifications to this software may be copyrighted by their authors
and need not follow the licensing terms described here, provided that
the new terms are clearly indicated on the first page of each file where
they apply.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
MODIFICATIONS.}
#-------------------------------------------------------------------------------

#***N* KBS/::kbs
# DESCRIPTION
#	The namespace contain the external callable functions.
namespace eval ::kbs {
# SOURCE
  namespace export help version kbs list info gui
  namespace export require source configure make install clean distclean
#-------------------------------------------------------------------------------
}

#***f* ::kbs/help()
# DESCRIPTION
#	Display usage help message.
#	This is also the default action if no command was given.
# EXAMPLE
#  ./kbs.tcl help
# SOURCE
proc ::kbs::help {} {
  puts "[::kbs::config::Get application]
Usage: kbs.tcl ?options? command ?args?

options (configuration variables are available with \[Get ..\]):
  -pkgfile=?file?   contain used Package definitions
                    (default is empty and use only internal definitions)
  -builddir=?dir?   set used building directory containing all package
                    specific 'makedir' (default is './build\$tcl_platform(os)')
  -i -ignore        ignore errors and proceed (default is disabled)
  -r -recursive     recursive Require packages (default is disabled)
  -v -verbose       display running commands and command output
  -CC=?command?     set configuration variable 'CC'
                    (default is 'gcc' or existing environment variable 'CC')
  -bi=?package ..?  set configuration variable 'bi' (default is '')
                    to list of packages for use in batteries included builds
  --enable-symbols
  --disable-symbols set configuration variable 'symbols'
  --enable-64bit
  --disable-64bit   set configuration variable '64bit'
  --enable-threads
  --disable-threads set configuration variable 'threads'
  --enable-aqua
  --disable-aqua    set configuration variable 'aqua'
  Used external programs (default values are found with 'auto_execok'):
  -make=?command?   set configuration variable 'exec-make'
                    (default is first found 'gmake' or 'make')
  -cvs=?command?    set configuration variable 'exec-cvs' (default is 'cvs')
  -svn=?command?    set configuration variable 'exec-svn' (default is 'svn')
  -tar=?command?    set configuration variable 'exec-tar' (default is 'tar')
  -gzip=?command?   set configuration variable 'exec-gzip' (default is 'gzip')
  -unzip=?command?  set configuration variable 'exec-unzip' (default is 'unzip')
  Used interpreter in package scripts (default first found in '[::kbs::config::Get builddir]/bin')
  -kitcli=?command? set configuration variable 'kitcli' (default 'kbs*cli*')
  -kitdyn=?command? set configuration variable 'kitdyn' (default 'kbs*dyn*')
  -kitgui=?command? set configuration variable 'kitgui' (default 'kbs*gui*')
  Mk4tcl based 'tclkit' interpreter build options:
  -mk               add 'mk-cli|dyn|gui' to variable 'kit'
  -mk-cli           add 'mk-cli' to variable 'kit'
  -mk-dyn           add 'mk-dyn' to variable 'kit'
  -mk-gui           add 'mk-gui' to variable 'kit'
  -mk-bi            add 'mk-bi' to variable 'kit'
  Vqtcl based 'tclkit lite' interpreter build options:
  -vq               add 'vq-cli|dyn|gui' to variable 'kit'
  -vq-cli           add 'vq-cli' to variable 'kit'
  -vq-dyn           add 'vq-dyn' to variable 'kit'
  -vq-gui           add 'vq-gui' to variable 'kit'
  -vq-bi            add 'vq-bi' to variable 'kit'
  If no interpreter option is given '-vq' will be asumed.

additional variables for use with \[Get ..\]):
  application       name of application including version number
  builddir          common build dir (can be set with -builddir=..)
  makedir           package specific dir under 'builddir'
  srcdir            package specific source dir under './sources/'
  builddir-sys
  makedir-sys
  srcdir-sys        system specific version (p.e. windows C:\\.. -> /..)
  sys               TEA specific platform subdir (win, unix)
  TCL*              TCL* variables from tclConfig.sh, loaded on demand
  TK*               TK* variables from tkConfig.sh, loaded on demand

command:
  help              this text
  doc               create program documentation (./doc/kbs.html)
  license           display license information
  config            display used values of configuration variables
  gui               start graphical user interface
  list ?pattern? .. list packages matching pattern (default is *)
                    Trailing words print these parts of the definition too.
  require pkg ..    return call trace of packages
  sources pkg ..    get package source files (under sources/)
  configure pkg ..  create 'makedir' (in 'builddir') and configure package
  make pkg ..       make package (in 'makedir')
  install pkg ..    install package (in 'builddir')
  test pkg ..       test package
  clean pkg ..      remove make targets
  distclean pkg ..  remove 'makedir'
'pkg' is used for glob style matching against available packages
(Beware, you need to hide the special meaning of * like foo\\*)

Startup configuration:
  Read files '\$(HOME)/.kbsrc' and './kbsrc'. Lines starting with '#' are
  treated as comments and removed. All other lines are concatenated and
  used as command line arguments.
  Read environment variable 'KBSRC'. The contents of this variable is used
  as command line arguments.

The following external programs are needed:
  * C-compiler, C++ compiler for metakit based programs (see -CC=)
  * make with handling of VPATH variables (gmake) (see -make=)
  * cvs, svn, tar, gzip, unzip to get and extract sources
    (see -cvs= -svn= -tar= -gzip= and -unzip= options)
  * msys (http://sourceforge.net/project/showfiles.php?group_id=10894) is
    used to build under Windows. You need to put the kbs-sources inside
    the msys tree (/home/..).
"
}
#-------------------------------------------------------------------------------

#***f* ::kbs/doc()
# DESCRIPTION
#	Create documentation from source file.
# EXAMPLE
#	create public documentation:
#	  ./kbs.tcl doc
#	create documentation for everything:
#	  ./kbs.tcl doc --internal --source_line_numbers
# INPUTS
# * args
#	additional arguments for the 'robodoc' call
#	see also <http://sourceforge.net/projects/robodoc/>
# SOURCE
proc ::kbs::doc {args} {
  set myPwd [pwd]
  if {![file readable kbs.tcl]} {error "missing file ./kbs.tcl"}
  file mkdir doc
  set myFd [open [file join doc kbs.rc] w]
  puts $myFd "
items:
  NAME
  AUTHOR
  COPYRIGHT
  VERSION
  SYNOPSIS
  INPUTS
  OUTPUTS
  RETURN
  DESCRIPTION
  EXAMPLE
  SOURCE
item order:
  NAME
  AUTHOR
  COPYRIGHT
  VERSION
  SYNOPSIS
  INPUTS
  OUTPUTS
  RETURN
  DESCRIPTION
  EXAMPLE
  SOURCE
source items:
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
  --nopre
headertypes:
  F  Files             robo_files       3
  N  Namespace         robo_namespace   2
  P  Package           robo_package     1
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

#***f* ::kbs/license()
# DESCRIPTION
#	Display license information.
# EXAMPLE
#	display license information:
#	  ./kbs.tcl license
# SOURCE
proc ::kbs::license {} {
  puts $::kbs(license)
}
#-------------------------------------------------------------------------------

#***f* ::kbs/config()
# DESCRIPTION
#	Display names and values of configuration variables useable with 'Get'.
# EXAMPLE
#	display used values:
#	  ./kbs.tcl config
# SOURCE
proc ::kbs::config {} {
  foreach myName [lsort [array names ::kbs::config::_]] {
    puts [format {%-20s = %s} "\[Get $myName\]" [::kbs::config::Get $myName]]
  }
}
#-------------------------------------------------------------------------------

#***f* ::kbs/gui()
# DESCRIPTION
#	Start graphical user interface.
# EXAMPLE
#	simple start with default options:
#    ./kbs.tcl gui
# INPUTS
#	* args	currently not used
# SOURCE
proc ::kbs::gui {args} {
  ::kbs::gui::_init $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/list()
# DESCRIPTION
#	Print available packages.
# EXAMPLE
#	list all packages starting with 'kbs'
#	  ./kbs.tcl list kbs\*
#	list all definitions of packages starting with 'kbs'
#	  ./kbs.tcl list kbs\* Package
#	list specific definition parts of packages starting with 'kbs'
#	  ./kbs.tcl list kbs\* Require Source
# INPUTS
# * pattern -- global search pattern for packages (default '*')
# * list    -- which part should be printed too (default '')
# SOURCE
proc ::kbs::list {{pattern *} args} {
  if {$args eq {}} {
    puts [lsort -dict [array names ::kbs::config::packagescript $pattern]]
  } else {
    foreach myPkg [lsort -dict [array names ::kbs::config::packagescript $pattern]] {
      puts "#***v* Package/$myPkg\n# SOURCE"
      puts "Package $myPkg {"
      foreach {myCmd myScript} $::kbs::config::packagescript($myPkg) {
        if {$args eq {Package} || [lsearch $args $myCmd] >= 0} {
          puts "  $myCmd {$myScript}"
        }
      }
      puts "}\n#-------------------------------------------------------------------------------"
    }
  }
}
#-------------------------------------------------------------------------------

#***f* ::kbs/require()
# DESCRIPTION
#	Call the 'Require' part of the package definition.
#	Can be used to show dependencies of packages.
# EXAMPLE
#	show dependencies of package:
#	  ./kbs.tcl -r require kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::require {args} {
  ::kbs::config::_init {Require} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/sources()
# FUNCTON
#	Call the 'Require' and 'Source' part of the package definition
#	to get the sources of packages.
#	Sources are installed under './sources/'.
# EXAMPLE
#	get the sources of a package:
#	  ./kbs.tcl sources kbskit8.5
#	get the sources of a package and its dependencies:
#	  ./kbs.tcl -r sources kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::sources {args} {
  ::kbs::config::_init {Require Source} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/configure()
# DESCRIPTION
#	Call the 'Require', 'Source' and 'Configure' part of the package
#	definition. The configuration is done in 'makedir'.
# EXAMPLE
#	configure the package:
#	  ./kbs.tcl configure kbskit8.5
#	configure the package and its dependencies:
#	  ./kbs.tcl -r configure kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::configure {args} {
  ::kbs::config::_init {Require Source Configure} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/make()
# DESCRIPTION
#	Call the 'Require', 'Source', 'Configure' and 'Make' part of the
#	package definition. The build is done in 'makedir'.
# EXAMPLE
#	make the package:
#	  ./kbs.tcl make kbskit8.5
#	make the package and its dependencies:
#	  ./kbs.tcl -r make kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::make {args} {
  ::kbs::config::_init {Require Source Configure Make} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/test()
# DESCRIPTION
#	Call the 'Require', 'Source', 'Make' and 'Test' part of the package
#	definition. The testing starts in 'makedir'
# EXAMPLE
#	test the package:
#	  ./kbs.tcl test kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::test {args} {
  ::kbs::config::_init {Require Source Make Test} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/install()
# DESCRIPTION
#	Call the 'Require', 'Source', 'Configure', 'Make' and 'Install' part of
#	the package definition. The install dir is 'builddir'.
# EXAMPLE
#	install the package:
#	  ./kbs.tcl install kbskit8.5
#	install the package and its dependencies:
#	  ./kbs.tcl -r install kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::install {args} {
  ::kbs::config::_init {Require Source Configure Make Install} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/clean()
# DESCRIPTION
#	Call the 'Clean' part of the package definition.
#	The clean starts in 'makedir'.
# EXAMPLE
#	clean the package:
#	  ./kbs.tcl clean kbskit8.5
#	clean the package and its dependencies:
#	  ./kbs.tcl -r clean kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::clean {args} {
  ::kbs::config::_init {Clean} $args
}
#-------------------------------------------------------------------------------

#***f* ::kbs/distclean()
# DESCRIPTION
#	Remove the 'makedir' of the package so everything can be rebuild again
#	This is necessary if there are problems in the configuration part of
#	the package.
# EXAMPLE
#	remove the package:
#	  ./kbs.tcl distclean kbskit8.5
#	remove the package and its dependencies:
#	  ./kbs.tcl -r distclean kbskit8.5
# INPUTS
# * args -- list of packages
# SOURCE
proc ::kbs::distclean {args} {
  set myBody [info body ::kbs::config::Source];# save old body
  proc ::kbs::config::Source [info args ::kbs::config::Source] {
    set myDir [Get makedir]
    if {[file exist $myDir]} {
      puts "=== Distclean: $myDir"
      file delete -force $myDir
    }
  }
  ::kbs::config::_init {Require Source} $args
  proc ::kbs::config::Source [info args ::kbs::config::Source] $myBody;# restore old body
}
#-------------------------------------------------------------------------------
#===============================================================================

#***N* KBS/::kbs::config
# DESCRIPTION
#	Contain internally used functions and variables.
namespace eval ::kbs::config {
# SOURCE
  namespace export Run Get Patch Require Source Configure Make Install Clean Test
#-------------------------------------------------------------------------------

#***iv* ::kbs::config/$maindir
# DESCRIPTION
#	Internal variable containing top level script directory.
# SOURCE
  variable maindir [file normalize [file dirname [info script]]]
#-------------------------------------------------------------------------------

#***iv* ::kbs::config/$packages
# DESCRIPTION
#	Internal variable with parsed package definitions from *.kbs files.
#       'Inlude' parts are resolved.
# SOURCE
  variable packages

#-------------------------------------------------------------------------------
#***iv* ::kbs::config/$packagescript
# DESCRIPTION
#	Internal variable with original package definitions from *.kbs files.
# SOURCE
  variable packagescript
#-------------------------------------------------------------------------------

#***iv* ::kbs::config/$package
# DESCRIPTION
#	Internal variable containing current package name.
# SOURCE
  variable package
#-------------------------------------------------------------------------------

#***iv* ::kbs::config/$ready
# DESCRIPTION
#	Internal variable containing list of already prepared packages.
# SOURCE
  variable ready [list]
#-------------------------------------------------------------------------------

#***v* ::kbs::config/$ignore
# DESCRIPTION
#	If set (-i or -ignore switch) then proceed in case of errors.
# EXAMPLE
#	try to build all given packages:
#	  ./kbs.tcl -i install bwidget\* mentry\*
#	  ./kbs.tcl -ignore install bwidget\* mentry\*
# SOURCE
  variable ignore
  set ignore 0
#-------------------------------------------------------------------------------

#***v* ::kbs::config/$recursive
# DESCRIPTION
#	If set (-r or -recursive switch) then all packages under 'Require'
#	are also used.
# EXAMPLE
#	build all packages recursively:
#	  ./kbs.tcl -r install kbskit8.5
#	  ./kbs.tcl -recursive install kbskit8.5
# SOURCE
  variable recursive
  set recursive 0
#-------------------------------------------------------------------------------

#***v* ::kbs::config/$verbose
# DESCRIPTION
#	If set (-v or -verbose switch) then all stdout will be removed.
# EXAMPLE
#	print additional information while processing:
#	  ./kbs.tcl -v -r install bwidget\*
#	  ./kbs.tcl -verbose -r install bwidget\*
# SOURCE
  variable verbose
  set verbose 0
#-------------------------------------------------------------------------------

#***v* ::kbs::config/$pkgfile
# DESCRIPTION
#	Define startup kbs package definition file.
#	Default is empty and use only internal definitions.
# EXAMPLE
#	start with own package definition file:
#	  ./kbs.tcl -pkgfile=/my/package/file list
# SOURCE
  variable pkgfile
  set pkgfile {}
#-------------------------------------------------------------------------------

#***v* ::kbs::config/$_
# DESCRIPTION
#	The array variable contain usefull information of the current building
#	process. All variables are provided with default values.
#	Changing of the default values can be done in the following order:
#	* file '$(HOME)/.kbsrc' and file './kbsrc' -- Lines starting with '#'
#	  are treated as comments and removed. All other lines are concatenated
#	  and used as command line arguments.
#	* environment variable 'KBSRC' -- The contents of this variable is used
#	  as command line arguments.
#	* command line 
#	It is also possible to set values in the 'Package' definition file
#	outside the 'Package' definition (p.e. 'set ::kbs::config::_(CC) g++').
# EXAMPLE
#	build debugging version:
#	  ./kbs.tcl -CC=/my/cc --enable-symbols install tclx8.4
#	create kbsmk8.5-[cli|dyn|gui] interpreter:
#	  ./kbs.tcl -mk install kbskit8.5
#	create kbsvq8.5-bi interpreter with packages:
#	  ./kbs.tcl -vq-bi -bi="tclx8.4 tdom0.8.2" install kbskit8.5
#	get list of available packages with:
#	  ./kbs.tcl list
# SOURCE
  variable _
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
  set _(exec-make)	[lindex "[auto_execok gmake] [auto_execok make] make" 0]
  set _(exec-cvs)	[lindex "[auto_execok cvs] cvs" 0]
  set _(exec-svn)	[lindex "[auto_execok svn] svn" 0]
  set _(exec-tar)	[lindex "[auto_execok tar] tar" 0]
  set _(exec-gzip)	[lindex "[auto_execok gzip] gzip" 0]
  set _(exec-unzip)	[lindex "[auto_execok unzip] unzip" 0]
  set _(kitcli)		{}
  set _(kitdyn)		{}
  set _(kitgui)         {}
  set _(kit)		[list];# list of interpreter builds
  set _(bi)		[list];# list of packages for batteries included interpreter builds
  set _(makedir)	{};# package specific build dir
  set _(makedir-sys)	{};# package and system specific build dir
  set _(srcdir)		{};# package specific source dir
  set _(srcdir-sys)	{};# package and system specific source dir
  set _(builddir)	[file join $maindir build[string map {{ } {}} $::tcl_platform(os)]]
  set _(builddir-sys)	$_(builddir)
  set _(application)	"Kitgen build system ($::kbs(version))";# application name
#-------------------------------------------------------------------------------
};# end of ::kbs::config

#***if* ::kbs::config/_sys()
# DESCRIPTION
#	Return platfrom specific file name p.e. windows C:\... -> /...
# INPUTS
# * file -- file name to convert
# SOURCE
proc ::kbs::config::_sys {file} {
  if {$::tcl_platform(platform) eq {windows} && [string index $file 1] eq {:}} {
    return "/[string tolower [string index $file 0]][string range $file 2 end]"
  } else {
    return $file
  }
}
#-------------------------------------------------------------------------------

#***if* ::kbs::config/_init()
# DESCRIPTION
#	Initialize variables with respect to given configuration options
#	and command.
#	Process command in separate interpreter.
# INPUTS
# * used -- list of available commands
# * list -- list of packages
# SOURCE
proc ::kbs::config::_init {used list} {
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
  lappend used Run Get Patch
  set interp [interp create]
  foreach myProc [namespace export] {
    if {$myProc in $used} {
      interp alias $interp $myProc {} ::kbs::config::$myProc
    } else {
      $interp eval [list proc $myProc [info args ::kbs::config::$myProc] {}]
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
# SYNOPSIS
#	Package name script
# DESCRIPTION
#	The 'Package' command is available in definition files.
#	All 'Package' definitions will be saved for further use.
# INPUTS
# * name   -- unique name of package
# * script --	contain one or more of the following definitions.
#		The common functions 'Run', 'Get' and 'Patch' can be used in
#		every 'script'. For a detailed description and command specific
#		additional functions look in the related commands.
#	'Require script'   -- define dependencies
#	'Source script'    -- method to get sources
#	'Configure script' -- configure package
#	'Make script'      -- build package
#	'Install script'   -- install package
#	'Clean script'     -- clean package
#	Special commands:
#	'Include package'  -- include current 'package' script. The command
#	use the current definitions (snapshot semantic).
# SOURCE
proc ::kbs::config::Package {name script} {
  variable packages
  variable packagescript

  set packagescript($name) $script
  array set myTmp $script
  if {[info exists myTmp(Include)]} {
    array set myScript $packages($myTmp(Include))
  }
  if {[info exist packages($name)]} {
    array set myScript $packages($name)
  }
  array set myScript $script
  set packages($name) {}
  foreach myCmd {Require Source Configure Make Install Clean Test} {
    if {[info exists myScript($myCmd)]} {
      append packages($name) [list $myCmd $myScript($myCmd)]\n
    }
  }
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Require()
# SYNOPSIS
#	Require script
# DESCRIPTION
#	Evaluate the given script.
#	Add additional packages with the 'Use' function.
# INPUTS
#  * script --	containing package dependencies.
#	Available functions are: 'Run', 'Get', 'Patch'
#	'Use ?package..?' -- see Require-Use()
# SOURCE
proc ::kbs::config::Require {script} {
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
# SYNOPSIS
#	Use ?package? ..
# DESCRIPTION
#	Define dependencies used with '-r' switch.
#	The given 'Package's in args will then be recursively called.
# INPUTS
# * args - one or more 'Package' names
# SOURCE
proc ::kbs::config::Require-Use {args} {
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
        foreach my {Link Cvs Svn Tgz Zip Http Script Kit Tcl Libdir} {
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
# SYNOPSIS
#	Source script
# DESCRIPTION
#	Procedure to build source tree of current 'Package' definition.
# INPUTS
# * script --	one or more of the following functions to get the sources
#		of the current package. The sources should be placed under
#		'./sources/'.
#	Available functions are: 'Run', 'Get', 'Patch'
#	'Cvs path ...' - call 'cvs -d path co -d 'srcdir' ...'
#	'Svn path'     - call 'svn co path 'srcdir''
#	'Http path'    - call 'http get path', unpack *.tar.gz or *.tgz files
#	'Tgz file'     - call 'tar xzf file'
#	'Zip file'     - call 'unzip file'
#	'Link package' - use sources from "package"
#	'Script text'  - eval 'text'
# SOURCE
proc ::kbs::config::Source {script} {
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
    return -code error "missing sources of package '$package'"
  }
  set _(srcdir-sys) [_sys $_(srcdir)]
}
#-------------------------------------------------------------------------------

#***if* ::kbs::config/Source-()
# SYNOPSIS
#	Link dir
#	Script tcl-script
#	Cvs path args
#	Svn args
#	Http url
#	Tgz file
#	Zip file
# DESCRIPTION
#	Process internal 'Source' commands.
# INPUTS
# * type - one of the valid source types, see Source().
# * args - depending on the given 'type' 
# SOURCE
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
            Run [info nameofexecutable] [pwd]/kbs.tcl -pkgfile=$pkgfile -builddir=$_(builddir) -v sources $args
          } else {
            Run [info nameofexecutable] [pwd]/kbs.tcl -pkgfile=$pkgfile -builddir=$_(builddir) sources $args
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
        if {[catch {Run svn co {*}$args $package} myMsg]} {
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
          if {$type eq {Tgz}} {exec $_(exec-gzip) -dc $args | $_(exec-tar) xf -}
          if {$type eq {Zip}} {exec $_(exec-unzip) $args}
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
# SYNOPSIS
#	Configure script
# DESCRIPTION
#	If 'makedir' not exist create it and eval script.
# INPUTS
#  * script --	tcl script to evaluate with one or more of the following
#		functions to help configure the current package
#	Available functions are: 'Run', 'Get', 'Patch'
#	'Kit ?main.tcl? ?pkg..?' -- see Configure-Kit()
# SOURCE
proc ::kbs::config::Configure {script} {
  variable verbose
  variable interp

  set myDir [Get makedir]
  if {[file exist $myDir]} return
  puts "=== Configure $myDir"
  if {$verbose} {puts $script}
  foreach my {Kit} {
    interp alias $interp $my {} ::kbs::config::Configure-$my
  }
  file mkdir $myDir
  $interp eval [list cd $myDir]
  $interp eval $script
  foreach my {Kit} {interp alias $interp $my}
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Configure-Kit()
# SYNOPSIS
#	Kit maincode args
# DESCRIPTION
#	This function create a 'makedir'/main.tcl with:
#	* common startup code
#	* require statement for each package in 'args' argument
#	* application startup from 'maincode' argument
# EXAMPLE
#	Package tksqlite0.5.8 ..
# INPUTS
# * maincode -- startup code
# * args     -- additional args
# SOURCE
proc ::kbs::config::Configure-Kit {maincode args} {
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
  foreach myPkg $args {
    puts $myFd "package require $myPkg"
  }
  puts $myFd "# start application\n$maincode"
  close $myFd
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Make()
# SYNOPSIS
#	Make script
# DESCRIPTION
#	Evaluate script in 'makedir'.
# INPUTS
# * script --	tcl script to evaluate with one or more of the following
#		functions to help building the current package
#	Available functions are: 'Run', 'Get', 'Patch'
#	'Kit name ?pkglibdir..?' -- see Make-Kit()
# SOURCE
proc ::kbs::config::Make {script} {
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
# SYNOPSIS
#	Kit name args
# DESCRIPTION
#	The procedure links the 'name.vfs' in to the 'makedir' and create
#	foreach name in 'args' a link from 'builddir'/lib in to 'name.vfs'/lib.
#	The names in 'args' may subdirectories under 'builddir'/lib. In the
#	'name.vfs'/lib the leading directory parts are removed.
#	The same goes for 'name.vfs'.
#	* Kit name ?librarydir ..?
#	  Start in 'makedir'. Create 'name.vfs/lib'.
#	  When existing link 'main.tcl' to 'name.vfs'.
#	  Link everything from [Srcdir] into 'name.vfs'.
#	  Link all package library dirs in ''makedir'/name.vfs'/lib
# EXAMPLE
#	Package tksqlite0.5.8 ..
# INPUTS
# * name -- name of vfs directory (without extension) to use
# * args -- additional args
# SOURCE
proc ::kbs::config::Make-Kit {name args} {
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
# SYNOPSIS
#	Install script
# DESCRIPTION
#	Eval script in 'makedir'.
# INPUTS
# * script --	tcl script to evaluate with one or more of the following
#		functions to install the current package.
#	Available functions are: 'Run', 'Get', 'Patch'
#	'Libdir dirname' -- see Install-Libdir()
#	'Kit name args'  -- see Install-Kit()
#	'Tcl ?package?'  -- see Install-Tcl()
# SOURCE
proc ::kbs::config::Install {script} {
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
# SYNOPSIS
#	Libdir dirname
# DESCRIPTION
#	Move given 'dir' in 'builddir'tcl/lib to package name.
#	This function is necessary to install all packages with the same
#	naming convention (lower case name plus version number).
# INPUTS
# * dirname --	original package library dir,
#		not conforming lower case with version number
# SOURCE
proc ::kbs::config::Install-Libdir {dirname} {
  variable verbose
  variable package

  set myLib [Get builddir]/lib
  if {[file exists $myLib/$dirname]} {
    if {$verbose} {puts "$myLib/$dirname -> $package"}
    # two steps to distinguish under windows lower and upper case names
    file delete -force $myLib/$dirname.Libdir
    file rename $myLib/$dirname $myLib/$dirname.Libdir
    file delete -force $myLib/$package
    file rename $myLib/$dirname.Libdir $myLib/$package
  } else {
    if {$verbose} {puts "skipping: $myLib/$dirname -> $package"}
  }
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install-Kit()
# SYNOPSIS
#	Kit name args
# DESCRIPTION
#	Without 'option' wrap kit and move to 'builddir'/bin otherwise with:
#	-mk-cli create starpack with 'kbsmk*-cli*' executable
#	-mk-dyn create starpack with 'kbsmk*-dyn*' executable
#	-mk-gui create starpack with 'kbsmk*-gui*' executable
#	-vq-cli create starpack with 'kbsvq*-cli*' executable
#	-vq-dyn create starpack with 'kbsvq*-dyn*' executable
#	-vq-gui create starpack with 'kbsvq*-gui*' executable
#	... create starpack with given option as executable
# EXAMPLE
#	Package tksqlite0.5.8 ..
# INPUTS
# * mode -- one of configure, make, install, clean or run
# * name -- name of vfs directory (without extension) to use
# * args -- additional args
# SOURCE
proc ::kbs::config::Install-Kit {name args} {
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
    if {$_(sys) eq {win}} {
      file rename -force $name [file join [Get builddir] bin $name.exe]
    } else {
      file rename -force $name [file join [Get builddir] bin]
    }
  }
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Install-Tcl()
# SYNOPSIS
#	Tcl ?pkgname?
# DESCRIPTION
#	Command to install tcl only packages.
#	Used in 'Install' part of 'Package' definitions.
# EXAMPLE
#	Package mentry-3.1 ..
# INPUTS
# * package -- install name of package, if missing then build from [Get srcdir]
# SOURCE
proc ::kbs::config::Install-Tcl {{pkgname {}}} {
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
# SYNOPSIS
#	Test script
# DESCRIPTION
#	Eval script in 'makedir'.
# INPUTS
# * script --	tcl script to evaluate with one or more of the following
#		functions to help testing the current package
#		Available functions are: 'Run', 'Get', 'Patch'
#		'Kit name args' -- see Test-Kit()
# SOURCE
proc ::kbs::config::Test {script} {
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
# SYNOPSIS
#	Kit mode name args
# DESCRIPTION
#	Run kit file with given command line 'args'
# EXAMPLE
#	Package tksqlite0.5.8 ..
# INPUTS
# * name -- name of vfs directory (without extension) to use
# * args -- additional args
# SOURCE
proc ::kbs::config::Test-Kit {name args} {
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
# SYNOPSIS
#	Clean script
# DESCRIPTION
#	Eval script in 'makedir'.
# INPUTS
# * script --	tcl script to evaluate with one or more of the following
#		functions to help cleaning the current package.
#		Available functions are: 'Run', 'Get', 'Patch'
# SOURCE
proc ::kbs::config::Clean {script} {
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
# SYNOPSIS
#	Get var
# DESCRIPTION
#	Return value of given variable name.
#	If 'var' starts with 'TCL_' tclConfig.sh will be parsed for TCL_*
#	variables. If 'var' starts with 'TK_' tkConfig.sh will be parsed for
#	TK_* variables.
# INPUTS
# * var: name of variable.
# SOURCE
proc ::kbs::config::Get {var} {
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

#***f* ::kbs::config/Patch()
# SYNOPSIS
#	Patch file lineoffste oldtext newtext
# DESCRIPTION
#	Patch files.
# EXAMPLE
#	Patch [Get srcdir]/Makefile.in 139\
#        {INCLUDES       = @PKG_INCLUDES@ @TCL_INCLUDES@}\
#        {INCLUDES       = @TCL_INCLUDES@}
# INPUTS
# * file       -- name of file to patch
# * lineoffset -- start point of patch, first line is 1
# * oldtext    -- part of file to replace
# * newtext    -- replacement text
# SOURCE
proc ::kbs::config::Patch {file lineoffset oldtext newtext} {
  variable verbose

  set myFd [open $file r]
  set myC [read $myFd]
  close $myFd
  # find oldtext
  set myIndex 0
  for {set myNr 1} {$myNr < $lineoffset} {incr myNr} {;# find line
    set myIndex [string first \n $myC $myIndex]
    if {$myIndex == -1} {
      return -code error "failed Patch: '$file' at $lineoffset -> eof at line $myNr"
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
    if {$verbose} {puts "---old version---:\n$oldtext\n---new version---:\n[string range $myTest 0 $myIndex]"}
    return -code error "failed Patch: '$file' at $lineoffset"
  }
  # apply patch
  append myC $newtext[string range $myTest $myIndex end]
  set myFd [open $file w]
  puts $myFd $myC
  close $myFd
  if {$verbose} {puts "applied Patch: '$file' at $lineoffset"}
}
#-------------------------------------------------------------------------------

#***f* ::kbs::config/Run()
# SYNOPSIS
#	Run args
# DESCRIPTION
#	The procedure call the args as external command with options.
#	The procedure is available in all script arguments.
#	If the 'verbose' switch is on the 'args' will be printed.
# INPUTS
# * args -- containing external command
# SOURCE
proc ::kbs::config::Run {args} {
  variable _
  variable verbose
  if {[info exists _(exec-[lindex $args 0])]} {
    set args [lreplace $args 0 0 $_(exec-[lindex $args 0])]
  }

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
# DESCRIPTION
#	Configure application with given command line arguments.
# INPUTS
# * args -- option list
# SOURCE
proc ::kbs::config::_configure {args} {
  variable maindir
  variable pkgfile
  variable ignore
  variable recursive
  variable verbose
  variable _

  set myOpts {}
  # read configuration files
  foreach myFile [list [file join $::env(HOME) .kbsrc] [file join $maindir kbsrc]] {
    if {[file readable $myFile]} {
      puts "=== Read configuration file '$myFile'"
      set myFd [open $myFile r]
      append myOpts [read $myFd]\n
      close $myFd
    }
  }
  # read configuration variable
  if {[info exists ::env(KBSRC)]} {
    puts "=== Read configuration variable 'KBSRC'"
    append myOpts $::env(KBSRC)
  }
  # add all found configuration options to command line
  foreach myLine [split $myOpts \n] {
    set myLine [string trim $myLine]
    if {$myLine eq {} || [string index $myLine 0] eq {#}} continue
    set args "$myLine $args"
  }
  # start command line parsing
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
      } -make=* {
        set _(exec-make) [string range $myCmd 6 end]
      } -cvs=* {
        set _(exec-cvs) [string range $myCmd 5 end]
      } -svn=* {
        set _(exec-svn) [string range $myCmd 5 end]
      } -tar=* {
        set _(exec-tar) [string range $myCmd 5 end]
      } -gzip=* {
        set _(exec-gzip) [string range $myCmd 6 end]
      } -unzip=* {
        set _(exec-unzip) [string range $myCmd 7 end]
      } -kitcli=* {
        set _(kitcli) [string range $myCmd 8 end]
      } -kitdyn=* {
        set _(kitdyn) [string range $myCmd 8 end]
      } -kitgui=* {
        set _(kitgui) [string range $myCmd 8 end]
      } -kitgui=* {
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
  foreach my {cli dyn gui} {;# default settings
    if {$_(kit$my) eq {}} {
      set _(kit$my) [lindex [lsort [glob -nocomplain [file join $_(builddir) bin kbs*${my}*]]] 0]
    }
  }
  file mkdir [file join $_(builddir) bin] [file join $maindir sources]
  # read kbs configuration file
  if {$myPkgfile ne {}} {
    puts "=== Read definitions from '$myPkgfile'"
    source $myPkgfile
    set pkgfile $myPkgfile
  }
  return $args
}
#-------------------------------------------------------------------------------

#===============================================================================

#***iN* KBS/::kbs::gui
# DESCRIPTION
#	Contain variables and function of the graphical user interface.
namespace eval ::kbs::gui {
# SOURCE
#-------------------------------------------------------------------------------

#***iv* ::kbs::gui/$_
# DESCRIPTION
#	Containing internal gui state values.
# SOURCE
  variable _
  set _(-command) {};# currently running command
  set _(-package) {};# current package 
  set _(-running) {};# currently executed command in 'Run'
  set _(widgets) [list];# list of widgets to disable if command is running
#-------------------------------------------------------------------------------
};# end of ::kbs::gui

#***if* ::kbs::gui/_init()
# DESCRIPTION
#	Build and initialize graphical user interface.
# INPUTS
# * args -- currently ignored
# SOURCE
proc ::kbs::gui::_init {args} {
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
  grid [::ttk::button $w.9 -width 3 -text {...} -command {::kbs::gui::_set_exec CC {Select C-compiler}} -padding 0]\
	-row 3 -column 3 -sticky ew
  lappend _(widgets) $w.6 $w.8 $w.9

  set myRow 3
  set myW 9
  foreach myCmd {make cvs svn tar gzip unzip} {
    incr myRow
    grid [::ttk::label $w.[incr myW] -anchor e -text "-${myCmd}="]\
	-row $myRow -column 1 -sticky ew
    grid [::ttk::entry $w.[incr myW] -textvariable ::kbs::config::_(exec-$myCmd)]\
	-row $myRow -column 2 -sticky ew
    lappend _(widgets) $w.$myW
    grid [::ttk::button $w.[incr myW] -width 3 -text {...} -command "::kbs::gui::_set_exec exec-${myCmd} {Select '${myCmd}' program}" -padding 0]\
	-row $myRow -column 3 -sticky ew
    lappend _(widgets) $w.$myW
  }

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
# DESCRIPTION
#	Set configuration variable '::kbs::config::builddir'.
# SOURCE
proc ::kbs::gui::_set_builddir {} {
  set myDir [tk_chooseDirectory -parent . -title "Select 'builddir'"\
	-initialdir $::kbs::config::_(builddir)]
  if {$myDir eq {}} return
  file mkdir [file join $myDir bin]
  set ::kbs::config::_(builddir) $myDir
  set ::kbs::config::_(builddir-sys) [::kbs::config::_sys $myDir]
}
#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_set_exec()
# DESCRIPTION
#	Set configuration variable 'varname'.
# INPUTS
# * varname -- name of configuration variable to set
# * title -- text to display as title of selection window
# SOURCE
proc ::kbs::gui::_set_exec {varname title} {
  set myFile [tk_getOpenFile -parent . -title $title\
	-initialdir [file dirname $::kbs::config::_($varname)]]
  if {$myFile eq {}} return
  set ::kbs::config::_($varname) $myFile
}
#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_set_bi()
# DESCRIPTION
#	Set configuration variable '::kbs::config::_(bi)'.
# SOURCE
proc ::kbs::gui::_set_bi {} {
  set my [list]
  foreach myNr [.pkg.lb curselection] {
    lappend my [.pkg.lb get $myNr]
  }
  set ::kbs::config::_(bi) $my
}
#-------------------------------------------------------------------------------

#***if* ::kbs::gui/_command()
# DESCRIPTION
#	Function to process currently selected packages and provide
#	feeedback results.
# INPUTS
# * cmd -- selected command from gui
# SOURCE
proc ::kbs::gui::_command {cmd} {
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
# DESCRIPTION
#	Change displayed state informations and update application.
# INPUTS
# * args -- list of option-value pairs with:
#   -running 'text' - text to display in the 'Running:' state
#   -package 'text' - text to display in the 'Package:' state
#   -command 'text' - text to display in the 'Command:' state
# SOURCE
proc ::kbs::gui::_state {args} {
  variable _

  array set _ $args
  update
}
#-------------------------------------------------------------------------------

#===============================================================================

#***f* ::/::kbs_main()
# DESCRIPTION
#	Parse the command line in search of options.
#
#	Process the command line to call one of the '::kbs::*' functions
# INPUTS
# * argv -- list of provided command line arguments
# SOURCE
proc ::kbs_main {argv} {
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
#===============================================================================

# begin of DB
namespace eval ::kbs::config {
#-------------------------------------------------------------------------------
#***P* KBS/Package
# DESCRIPTION
#	To get the complete formatted list try:
#	  './kbs.tcl list \* Package'
#-------------------------------------------------------------------------------
#***v* Package/__
# SOURCE
Package tt {
  Source {
    Link ../sf.net
  }
  Configure {}
  Make {
    # do everything from the main directory
    cd ../..
    puts "+++ [clock format [clock seconds] -format %T] save 'sf.net/'"
    set myPrefix "sf.net/[string map {{ } {}} $::tcl_platform(os)]_"
    foreach myFile [glob sf*/bin/kbs* sf85/bin/tksqlite*] {
      file copy -force $myFile $myPrefix[file tail $myFile]
    }
    if {![file exists sf.net/kbs.tgz]} {
      puts "+++ [clock format [clock seconds] -format %T] kbs.tgz"
      Run tar czf sf.net/kbs.tgz kbs.tcl sources
    }
  }
}
Package __ {
  Source {
    if {![file exists sf.net]} { file mkdir sf.net }
    Link ../sf.net
  }
  Configure {}
  Make {
    # do everything from the main directory
    cd ../..
    if {$::tcl_platform(platform) == "windows"} {
      set MYEXE "./MINGW32_NT-5.1/bin/tclsh85s.exe kbs.tcl"
    } else {
      set MYEXE {./kbs.tcl}
    }
    puts "+++ [clock format [clock seconds] -format %T] 8.5 -vq -mk"
    Run {*}$MYEXE -builddir=sf85 -r -vq -mk install kbskit8.5
    puts "+++ [clock format [clock seconds] -format %T] 8.5 -vq-bi"
    set my [list bwidget1.8.0 gridplus2.5 icons1.2 img1.4 itcl3.4 itk3.4 iwidgets4.0.2 memchan2.2.1 mentry3.3 ral0.9.1 rbc0.1 sqlite3.7.2 tablelist5.2 tcllib1.12 tclx8.4 thread2.6.5 tkcon tklib0.5 tktable2.10 treectrl2.2.9 trofs0.4.4 udp1.0.8 wcb3.2 xotcl1.6.6]
    Run {*}$MYEXE -builddir=sf85 -r -vq-bi -bi=$my install kbskit8.5
    puts "+++ [clock format [clock seconds] -format %T] 8.5 tksqlite"
    Run {*}$MYEXE -builddir=sf85 -r install tksqlite0.5.8
    puts "+++ [clock format [clock seconds] -format %T] 8.6 -vq -mk"
    Run {*}$MYEXE -builddir=sf86 -r -vq -mk install kbskit8.6
    puts "+++ [clock format [clock seconds] -format %T] save 'sf.net/'"
    set myPrefix "sf.net/[string map {{ } {}} $::tcl_platform(os)]_"
    foreach myFile [glob sf*/bin/kbs* sf85/bin/tksqlite*] {
      file copy -force $myFile $myPrefix[file tail $myFile]
    }
    if {![file exists sf.net/kbs.tgz]} {
      puts "+++ [clock format [clock seconds] -format %T] kbs.tgz"
      Run tar czf sf.net/kbs.tgz kbs.tcl sources
    }
  }
}
#-------------------------------------------------------------------------------
#***v* Package/_TODO_blt
# SOURCE
Package _TODO_blt {
  Source {Cvs blt.cvs.sourceforge.net:/cvsroot/blt}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] blt_with_ft2_include_dir=no blt_with_ft2_lib_dir=no
  }
  Make {Run make}
}
#-------------------------------------------------------------------------------
#***v* Package/_TODO_fossil
# SOURCE
Package _TODO_fossil {
  Source {Link fossil}
  Configure {}
  Make {
    set ::MYLIB "-lz [Get TCL_LIBS]"
    Run env SRCDIR=[Get srcdir]/src BCC=[Get CC] TCC=[Get CC] LIB=$MYLIB make -f
 [Get srcdir]/src/main.mk
  }
  Install {file copy -force [Get builddir]/_TODO_fossil/fossil [Get builddir]/bin/fossil}
}
#-------------------------------------------------------------------------------
#***v* Package/_TODO_nap6.3.1
# SOURCE
Package _TODO_nap6.3.1 {
  Source {Cvs tcl-nap.cvs.sourceforge.net:/cvsroot/tcl-nap -r nap-6-3-1 tcl-nap}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/_TODO_tensor4.0
# SOURCE
Package _TODO_tensor4.0 {
  Source {Http http://www.eecs.umich.edu/~mckay/computer/tensor4.0a1.tar.gz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys]
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean }
  Test {Run make check}
}
#-------------------------------------------------------------------------------
#***v* Package/_TODO_tkpath0.3
# SOURCE
Package _TODO_tkpath0.3 {
  Source {Cvs tclbitprint.cvs.sourceforge.net:/cvsroot/tclbitprint tkpath}
  Configure {
# Only works with additional libraries p.e. cairo
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-lib-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/bwidget1.8.0
# SOURCE
Package bwidget1.8.0 {
  Source {Cvs tcllib.cvs.sourceforge.net:/cvsroot/tcllib -r bwidget-1_8_0 bwidget}
  Configure {}
  Install {
    file delete -force [Get builddir]/lib/[file tail [Get srcdir]]
    file copy -force [Get srcdir] [Get builddir]/lib
  }
  Test {
    cd [Get builddir]/lib/bwidget1.8.0/demo
    Run [Get kitgui] demo.tcl
  }
}
#-------------------------------------------------------------------------------
#***v* Package/bwidget1.9.2
# SOURCE
Package bwidget1.9.2 {
  Source {Cvs tcllib.cvs.sourceforge.net:/cvsroot/tcllib -r bwidget-1_9_2 bwidget}
  Configure {}
  Install {
    file delete -force [Get builddir]/lib/[file tail [Get srcdir]]
    file copy -force [Get srcdir] [Get builddir]/lib
  }
  Test {
    cd [Get builddir]/lib/bwidget1.8.0/demo
    Run [Get kitgui] demo.tcl
  }
}
#-------------------------------------------------------------------------------
#***v* Package/expect5.44
# SOURCE
Package expect5.44 {
  Source {Cvs expect.cvs.sourceforge.net:/cvsroot/expect -D 2010-10-28 expect}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib --with-tclinclude=[Get builddir-sys]/include --with-tkinclude=[Get builddir-sys]/include [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/gridplus2.5
# SOURCE
Package gridplus2.5 {
  Require {Use icons1.2 tablelist5.2}
  Source {Http http://www.satisoft.com/tcltk/gridplus2/download/gridplus.zip}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/icons1.2
# SOURCE
Package icons1.2 {
  Source {Http http://www.satisoft.com/tcltk/icons/icons.tgz}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/img1.4
# SOURCE
Package img1.4 {
  Source {Svn https://tkimg.svn.sourceforge.net:/svnroot/tkimg/trunk -r 306}
  Configure {
    #bug #3098106 install failed because of missing dtplite
    Patch [Get srcdir]/Makefile.in 149\
{install: collate install-man
} {install: collate
}
    #bug # double definition boolean under windows
    Patch [Get srcdir]/compat/libjpeg/jconfig.cfg 23\
{typedef unsigned char boolean;} {#ifndef __TKIMG_H__
typedef unsigned char boolean;
#endif
}
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib
  }
  Make {Run make}
  Install {
    Run make install
    Libdir Img1.4;#TEST
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/itcl3.4
# SOURCE
Package itcl3.4 {
  Source {Cvs incrtcl.cvs.sourceforge.net:/cvsroot/incrtcl -D 2010-10-28 incrTcl}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/itcl/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-doc}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/itcl4.0b5
# SOURCE
Package itcl4.0b5 {
  Require {Use tcl8.6}
  Source {Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -r itcl-4-0b5 itcl}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/itk3.4
# SOURCE
Package itk3.4 {
  Require {Use itcl3.4}
  Source {Link itcl3.4}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/itk/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/iwidgets4.0.2
# SOURCE
Package iwidgets4.0.2 {
  Require {Use itk3.4}
  Source {
    Cvs incrtcl.cvs.sourceforge.net:/cvsroot/incrtcl -D 2010-10-28 iwidgets 
    Patch [Get srcdir]/Makefile.in 72 {		  @LD_LIBRARY_PATH_VAR@="$(EXTRA_PATH):$(@LD_LIBRARY_PATH_VAR@)"}  {		  LD_LIBRARY_PATH="$(EXTRA_PATH):$(@LD_LIBRARY_PATH_VAR@)"}
  }
  Configure {
    Run env CC=[Get CC] TCLSH_PROG=[Get builddir-sys]/bin/tclsh85 WISH_PROG=[Get builddir-sys]/bin/wish [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-itcl=[Get srcdir-sys]/../itcl3.4
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/kbskit0.4
# SOURCE
Package kbskit0.4 {
  Source {Cvs kbskit.cvs.sourceforge.net:/cvsroot/kbskit -r kbskit_0_4 kbskit}
}
#-------------------------------------------------------------------------------
#***v* Package/kbskit8.5
# SOURCE
Package kbskit8.5 {
  Require {
    Use kbskit0.4 sdx.kit
    Use tk8.5-static tk8.5 vfs1.4-static zlib1.2.3-static thread2.6.5 {*}[Get bi]
    if {[lsearch -glob [Get kit] {vq*}] != -1} { Use vqtcl4.1-static }
    if {[lsearch -glob [Get kit] {mk*}] != -1} { Use mk4tcl2.4.9.7-static itcl3.4 }
  }
  Source {Link kbskit0.4}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {
    if {$::tcl_platform(platform) == "windows"} {
      set MYCLI "[Get builddir-sys]/lib/libtcl85s.a"
      append MYCLI " [Get builddir-sys]/lib/libz.a"
      append MYCLI " [Get builddir-sys]/lib/vfs1.4.1/vfs141.a"
      set MYGUI "[Get builddir-sys]/lib/libtk85s.a"
      set MYVQ "[Get builddir-sys]/lib/vqtcl4.1/vqtcl41.a"
      set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a -lstdc++"
    } else {
      set MYCLI "[Get builddir-sys]/lib/libtcl8.5.a"
      append MYCLI " [Get builddir-sys]/lib/libz.a"
      append MYCLI " [Get builddir-sys]/lib/vfs1.4.1/libvfs1.4.1.a"
      set MYGUI "[Get builddir-sys]/lib/libtk8.5.a"
      set MYVQ "[Get builddir-sys]/lib/vqtcl4.1/libvqtcl4.1.a"
      if {$::tcl_platform(os) == "SunOS" && [Get CC] == "cc"} {
        set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a -lCstd -lCrun"
      } else {
        set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a -lstdc++"
      }
    }
    if {[string equal [Get threads] {--enable-threads}]} {
      set MYKITVQ "thread2.6.5"
      set MYKITMK "thread2.6.5 itcl3.4"
    } else {
      set MYKITVQ ""
      set MYKITMK "itcl3.4"
    }
    if {$::tcl_platform(os) == "Linux"} {
      set MYXFT "-lXft"
    } else {
      set MYXFT ""
    }
    foreach my [Get kit] {
      Run make MYCLI=$MYCLI MYGUI=$MYGUI MYXFT=$MYXFT MYVQ=$MYVQ MYKITVQ=$MYKITVQ MYMK=$MYMK MYKITMK=$MYKITMK MYKITBI=[Get bi] all-$my
    }
  }
  Install {foreach my [Get kit] {Run make install-$my}}
  Test {;# start program and paste following commands:
# catch {package req x}; foreach p [lsort [package names]] {puts "$p=[catch {package req $p}]"}
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/kbskit8.6
# SOURCE
Package kbskit8.6 {
  Require {
    Use kbskit0.4 sdx.kit
    Use tk8.6-static tk8.6 vfs1.4-static zlib1.2.3-static {*}[Get bi]
    if {[lsearch -glob [Get kit] {vq*}] != -1} {Use vqtcl4.1-static}
    if {[lsearch -glob [Get kit] {mk*}] != -1} {Use mk4tcl2.4.9.7-static}
  }
  Source {Link kbskit0.4}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {
    if {$::tcl_platform(platform) == "windows"} {
      set MYCLI "[Get builddir-sys]/lib/libtcl86ss.a"
      append MYCLI " [Get builddir-sys]/lib/libz.a"
      append MYCLI " [Get builddir-sys]/lib/vfs1.4.1/vfs141.a"
      set MYGUI "[Get builddir-sys]/lib/libtk86s.a"
      set MYVQ "[Get builddir-sys]/lib/vqtcl4.1/vqtcl41.a [Get builddir-sys]/lib/libtclstub86s.a"
      set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a [Get builddir-sys]/lib/libtclstub86s.a -lstdc++"
    } else {
      set MYCLI "[Get builddir-sys]/lib/libtcl8.6.a"
      append MYCLI " [Get builddir-sys]/lib/libz.a"
      append MYCLI " [Get builddir-sys]/lib/vfs1.4.1/libvfs1.4.1.a"
      set MYGUI "[Get builddir-sys]/lib/libtk8.6.a"
      set MYVQ "[Get builddir-sys]/lib/vqtcl4.1/libvqtcl4.1.a [Get builddir-sys]/lib/libtclstub8.6.a"
      if {$::tcl_platform(os) == "SunOS" && [Get CC] == "cc"} {
        set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a -lCstd -lCrun"
      } else {
        set MYMK "[Get builddir-sys]/lib/mk4tcl2.4.9.7-static/Mk4tcl.a -lstdc++"
      }
    }
    if {[string equal [Get threads] {--enable-threads}]} {
      set MYKITVQ "thread2.6.6 tdbc1.0b16 itcl4.0b5"
      set MYKITMK "thread2.6.6 tdbc1.0b16 itcl4.0b5"
    } else {
      set MYKITVQ "tdbc1.0b16 itcl4.0b5"
      set MYKITMK "tdbc1.0b16 itcl4.0b5"
    }
    if {$::tcl_platform(os) == "Linux"} {
      set MYXFT "-lXft"
    } else {
      set MYXFT ""
    }
    foreach my [Get kit] {
      Run make MYCLI=$MYCLI MYGUI=$MYGUI MYXFT=$MYXFT MYVQ=$MYVQ MYKITVQ=$MYKITVQ MYMK=$MYMK MYKITMK=$MYKITMK MYKITBI=[Get bi] all-$my
    }
  }
  Install {foreach my [Get kit] {Run make install-$my}}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/memchan2.2.1
# SOURCE
Package memchan2.2.1 {
  Source {Cvs memchan.cvs.sourceforge.net:/cvsroot/memchan -D 2010-10-28 memchan}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get symbols] [Get 64bit] [Get threads]
  }
  Make {Run make binaries}
  Install {
    Run make install-binaries
    Libdir Memchan2.2.1
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/mentry3.3
# SOURCE
Package mentry3.3 {
  Require {Use wcb3.2}
  Source {Http http://www.nemethi.de/mentry/mentry3.3.tar.gz}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/mk4tcl2.4.9.7
# SOURCE
Package mk4tcl2.4.9.7 {
  Source {Svn svn://svn.equi4.com/metakit/trunk -r 4720}
}
#-------------------------------------------------------------------------------
#***v* Package/mk4tcl2.4.9.7-static
# SOURCE
Package mk4tcl2.4.9.7-static {
  Source {Link mk4tcl2.4.9.7}
  Configure {
    #TODO bug report
    Patch [Get srcdir]/unix/Makefile.in 46 {CXXFLAGS = $(CXX_FLAGS)} {CXXFLAGS = -DSTATIC_BUILD $(CXX_FLAGS)}
    #TODO INCLUDE SunOS cc with problems on wide int
    if {$::tcl_platform(os) == "SunOS" && [Get CC] == "cc"} {
      Patch [Get srcdir]/../sources/mk4tcl2.4.9.7/tcl/mk4tcl.h 9 "#include <tcl.h>\n\n" "#include <tcl.h>\n#undef TCL_WIDE_INT_TYPE\n"
    }
    Run env CC=[Get CC] [Get srcdir-sys]/unix/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/include [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make tcl}
  Install {
    Run make install
    Libdir Mk4tcl
  }
}
#-------------------------------------------------------------------------------
#***v* Package/ral0.9.1
# SOURCE
Package ral0.9.1 {
  Source {Cvs tclral.cvs.sourceforge.net:/cvsroot/tclral -r VERSION_0_9_1 .}
  Configure {
    if {[Get sys] eq {unix}} {
      file attributes [Get srcdir]/tclconfig/install-sh -permissions u+x
    }
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make CPPFLAGS=-I[Get srcdir-sys]/../tcl8.5/libtommath binaries}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/rbc0.1
# SOURCE
Package rbc0.1 {
  Source {Svn https://rbctoolkit.svn.sourceforge.net/svnroot/rbctoolkit/trunk/rbc -r 48}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] [Get aqua]
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/robodoc4.99.36
# SOURCE
Package robodoc4.99.36 {
  Source {Http http://www.xs4all.nl/~rfsber/Robo/DistSource/robodoc-4.99.36.tar.gz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys]
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
  Test {Run make check}
}
#-------------------------------------------------------------------------------
#***v* Package/sdx.kit
# SOURCE
Package sdx.kit {
  Source {Http http://www.equi4.com/pub/sk/sdx.kit}
  Configure {}
  Install {file copy -force [Get srcdir] [Get builddir]/bin}
}
#-------------------------------------------------------------------------------
#***v* Package/sdx0.0
# SOURCE
Package sdx0.0 {
  Source {Svn svn://svn.equi4.com/sdx/trunk}
  Configure {}
  Make {Kit sdx}
  Install {Kit sdx}
  Clean {file delete -force sdx.vfs}
  Test {Kit sdx}
}
#-------------------------------------------------------------------------------
#***v* Package/snack2.2
# SOURCE
Package snack2.2 {
  Source {Http http://www.speech.kth.se/snack/dist/snack2.2.10.tar.gz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] -libdir=[Get builddir-sys]/lib --includedir=[Get builddir-sys]/include --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib}
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/sqlite3.7.2
# SOURCE
Package sqlite3.7.2 {
  Source {Http http://www.sqlite.org/sqlite-3_7_2-tea.tar.gz}
  Configure {
    if {[Get sys] eq {unix}} {
      file attributes [Get srcdir]/configure -permissions u+x
      file attributes [Get srcdir]/tclconfig/install-sh -permissions u+x
    }
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/tablelist5.2
# SOURCE
Package tablelist5.2 {
  Source {Http http://www.nemethi.de/tablelist/tablelist5.2.tar.gz}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/tcl8.5
# SOURCE
Package tcl8.5 {
  Source {
    Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -r core-8-5-9 tcl 
    # because of IRIX mkstemp() bug -> fixed in 8.6
    # sourceforge.net/projects/tcl -> Tracker -> ID: 878333
    if {$::tcl_platform(os) eq {IRIX64}} {
    Patch [Get srcdir]/[Get sys]/tclUnixPipe.c 48 {
/*
 * Declarations for local functions defined in this file:
 */
} {static int PipeNr=0;
/*
 * Declarations for local functions defined in this file:
 */
}
    Patch [Get srcdir]/[Get sys]/tclUnixPipe.c 194 {    char fileName[L_tmpnam + 9];} {    char fileName[L_tmpnam + 18];}
    Patch [Get srcdir]/[Get sys]/tclUnixPipe.c 202 {
    strcpy(fileName, P_tmpdir);				/* INTL: Native. */
    if (fileName[strlen(fileName) - 1] != '/') {
	strcat(fileName, "/");				/* INTL: Native. */
    }
    strcat(fileName, "tclXXXXXX");
} {
    if (P_tmpdir[strlen(P_tmpdir) - 1] != '/') {
      snprintf(fileName,L_tmpnam+18,"%s/tcl%.9dXXXXXX",P_tmpdir,PipeNr++);
    } else {
      snprintf(fileName,L_tmpnam+18,"%stcl%.9dXXXXXX",P_tmpdir,PipeNr++);
    }
}
    Patch [Get srcdir]/[Get sys]/tclUnixPipe.c 247 {    char fileName[L_tmpnam + 9];} {    char fileName[L_tmpnam + 18];}
    Patch [Get srcdir]/[Get sys]/tclUnixPipe.c 254 {
    strcpy(fileName, P_tmpdir);		/* INTL: Native. */
    if (fileName[strlen(fileName) - 1] != '/') {
	strcat(fileName, "/");		/* INTL: Native. */
    }
    strcat(fileName, "tclXXXXXX");
} {
    if (P_tmpdir[strlen(P_tmpdir) - 1] != '/') {
      snprintf(fileName,L_tmpnam+18,"%s/tcl%.9dXXXXXX",P_tmpdir,PipeNr++);
    } else {
      snprintf(fileName,L_tmpnam+18,"%stcl%.9dXXXXXX",P_tmpdir,PipeNr++);
    }
}
    }
  }
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tcl8.5-static
# SOURCE
Package tcl8.5-static {
  Source {Link tcl8.5}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tcl8.6
# SOURCE
#  Source {Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -r core-8-6-b1 tcl}
Package tcl8.6 {
  Source {Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -D 2010-10-28 tcl}
  Configure {
    Patch [Get srcdir]/win/Makefile.in 777 {	          $$i/configure --with-tcl=$(PWD)} {	          $$i/configure --with-tcl=$(LIB_INSTALL_DIR)}
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {
    Run make install-binaries install-libraries install-private-headers install-packages
    if {[Get sys] eq {win}} {
      if {![file exists [Get builddir]/lib/libtclstub86s.a]} {
        file copy [Get builddir]/lib/libtclstub86.a [Get builddir]/lib/libtclstub86s.a
      }
      if {[file exists [Get builddir]/lib/libtcl86ss.a]} {
        file copy -force [Get builddir]/lib/libtcl86ss.a [Get builddir]/lib/libtcl86s.a
      }
    }
  }
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tcl8.6-static
# SOURCE
Package tcl8.6-static {
  Source {Link tcl8.6}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tcllib1.12
# SOURCE
Package tcllib1.12 {
  Source {Cvs tcllib.cvs.sourceforge.net:/cvsroot/tcllib -r tcllib-1-12 tcllib}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys]
  }
  Make {}
  Install {Run make install-libraries}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tcloo0.6
# SOURCE
Package tcloo0.6 {
  Source {Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -r release-0-6 oocore}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
#    file copy -force [file join [Get srcdir] TclOO.rc] [Get makedir]
  }
  Make {Run make}
  Install {
    Run make install install-private-headers
    Libdir TclOO0.6
  }
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tclx8.4
# SOURCE
Package tclx8.4 {
  Source {Cvs tclx.cvs.sourceforge.net:/cvsroot/tclx -D 2010-10-28 tclx}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/tdom0.8.2
# SOURCE
Package tdom0.8.2 {
  Source {Http http://www.tdom.org/files/tDOM-0.8.2.tgz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/thread2.6.5
# SOURCE
Package thread2.6.5 {
  Source {Cvs tcl.cvs.sourceforge.net:/cvsroot/tcl -D 2010-10-28 thread}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/thread2.6.5-static
# SOURCE
Package thread2.6.5-static {
  Source {Link thread2.6.5}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/tk8.5
# SOURCE
Package tk8.5 {
  Require {Use tcl8.5}
  Source {Cvs tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -r core-8-5-9 tk}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] [Get aqua]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tk8.5-static
# SOURCE
Package tk8.5-static {
  Require {Use tcl8.5-static}
  Source {Link tk8.5}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] [Get aqua]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tk8.6
# SOURCE
#  Source {Cvs tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -r core-8-6-b1 tk}
Package tk8.6 {
  Require {Use tcl8.6}
  Source {Cvs tktoolkit.cvs.sourceforge.net:/cvsroot/tktoolkit -D 2010-10-28 tk}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] [Get aqua]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tk8.6-static
# SOURCE
Package tk8.6-static {
  Require {Use tcl8.6 tcl8.6-static}
  Source {Link tk8.6}
  Configure {
    if {[Get sys] eq {win1}} {;#TEST
      Patch [Get srcdir]/[Get sys]/Makefile.in 601 {	$(CC) $(CFLAGS) $(WISH_OBJS) $(TCL_LIB_FILE) $(TK_LIB_FILE) $(LIBS) } {	$(CC) $(CFLAGS) $(WISH_OBJS) $(TCL_LIB_FILE) $(TK_LIB_FILE) $(TCL_STUB_LIB_FILE) $(LIBS) }
    }
    Run env CC=[Get CC] [Get srcdir-sys]/[Get sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols] [Get aqua]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries install-private-headers}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tkcon
# SOURCE
Package tkcon {
  Source {Cvs tkcon.cvs.sourceforge.net:/cvsroot/tkcon -D 2010-10-28 tkcon}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/tklib0.5
# SOURCE
Package tklib0.5 {
  Source {Cvs tcllib.cvs.sourceforge.net:/cvsroot/tcllib -r tklib-0-5 tklib}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys]
  }
  Make {}
  Install {Run make install-libraries}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/tksqlite0.5.8
# SOURCE
Package tksqlite0.5.8 {
  Require {Use kbskit8.5 sdx.kit tktable2.10 treectrl2.2.9 sqlite3.7.2}
  Source {Http http://reddog.s35.xrea.com/software/tksqlite-0.5.8.tar.gz}
  Configure {Kit {source $::starkit::topdir/tksqlite.tcl} Tk}
  Make {Kit tksqlite sqlite3.7.2 tktable2.10 treectrl2.2.9}
  Install {Kit tksqlite -vq-gui}
  Clean {file delete -force tksqlite.vfs}
  Test {Kit tksqlite}
}
#-------------------------------------------------------------------------------
#***v* Package/tktable2.10
# SOURCE
Package tktable2.10 {
  Source {Cvs tktable.cvs.sourceforge.net:/cvsroot/tktable -r tktable-2-10-0 tktable}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries}
  Install {
    Run make install-binaries
    Libdir Tktable2.10
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/tls1.6
# SOURCE
Package tls1.6 {
  Source {Cvs tls.cvs.sourceforge.net:/cvsroot/tls -r tls-1-6-0 tls}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install}
  Clean {Run make clean}
  Test {Run make test}
}
#-------------------------------------------------------------------------------
#***v* Package/treectrl2.2.9
# SOURCE
Package treectrl2.2.9 {
  Source {Cvs tktreectrl.cvs.sourceforge.net:/cvsroot/tktreectrl -r VERSION2_2_9 tktreectrl}
  Configure {
    if {[Get sys] eq {unix}} {
      file attributes [Get srcdir]/configure -permissions u+x
      file attributes [Get srcdir]/tclconfig/install-sh -permissions u+x
    }
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make}
  Install {Run make install-binaries install-libraries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/trofs0.4.4
# SOURCE
Package trofs0.4.4 {
  Source {Http http://math.nist.gov/~DPorter/tcltk/trofs/trofs0.4.4.tar.gz}
  Configure {
    Run env CC=[Get CC] TCLSH_PROG=[Get builddir-sys]/bin/tclsh85.exe [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/udp1.0.8
# SOURCE
Package udp1.0.8 {
  Source {Cvs tcludp.cvs.sourceforge.net:/cvsroot/tcludp -r tcludp-1_0_8 tcludp}
  Configure {
    if {[Get sys] eq {unix}} {
      file attributes [Get srcdir]/tclconfig/install-sh -permissions u+x
    }
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {
    # because of IRIX64
    set MYFLAGS "[lsearch -glob -inline [Get TCL_DEFS] -Dsocklen_t=*]"
    Run make PKG_CFLAGS=$MYFLAGS binaries
  }
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/vfs1.4
# SOURCE
Package vfs1.4 {
  Source {Cvs tclvfs.cvs.sourceforge.net:/cvsroot/tclvfs -D 2010-10-28 tclvfs}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/vfs1.4-static
# SOURCE
Package vfs1.4-static {
  Source {Link vfs1.4}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {Run make}
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/vqtcl4.1
# SOURCE
Package vqtcl4.1 {
  Source {Svn svn://svn.equi4.com/vlerq/branches/v4/tcl -r 4720}
}
#-------------------------------------------------------------------------------
#***v* Package/vqtcl4.1-static
# SOURCE
Package vqtcl4.1-static {
  Source {Link vqtcl4.1}
  Configure {
#TODO bug report
    Patch [Get srcdir]/generic/vlerq.c 42 {#if !defined(_BIG_ENDIAN) && defined(WORDS_BIGENDIAN)} {#if defined(WORDS_BIGENDIAN)}
    Run env CC=[Get CC] [Get srcdir-sys]/configure --disable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib [Get 64bit] [Get threads] [Get symbols]
  }
  Make {
    set MYFLAGS "-D__[exec uname -p]__"
    Run make PKG_CFLAGS=$MYFLAGS
  }
  Install {Run make install-binaries}
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/wcb3.2
# SOURCE
Package wcb3.2 {
  Source {Http http://www.nemethi.de/wcb/wcb3.2.tar.gz}
  Configure {}
  Install {Tcl}
}
#-------------------------------------------------------------------------------
#***v* Package/wikit.tkd
# SOURCE
Package wikit.tkd {
  Source {;#TODO how to get files from sourceforge?
    Http http://garr.dl.sourceforge.net/sourceforge/tclerswikidata/wikit-20090210.tkd
  }
}
#-------------------------------------------------------------------------------
#***v* Package/wubwikit.kit
# SOURCE
Package wubwikit.kit {
  Source {Http http://wubwikit.googlecode.com/files/wubwikit20090218.kit}
}
#-------------------------------------------------------------------------------
#***v* Package/xotcl1.6.5
# SOURCE
Package xotcl1.6.5 {
  Source {Http http://media.wu-wien.ac.at/download/xotcl-1.6.5.tar.gz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries libraries}
  Install {
#TODO    file mkdir [file join [Get builddir] lib xotcl1.6.5 apps]
    Run make install-binaries install-libraries
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/xotcl1.6.6
# SOURCE
Package xotcl1.6.6 {
  Source {Http http://media.wu-wien.ac.at/download/xotcl-1.6.6.tar.gz}
  Configure {
    Run env CC=[Get CC] [Get srcdir-sys]/configure --enable-shared --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys] --with-tcl=[Get builddir-sys]/lib --with-tk=[Get builddir-sys]/lib [Get symbols] [Get threads] [Get 64bit]
  }
  Make {Run make binaries libraries}
  Install {
#TODO    file mkdir [file join [Get builddir] lib xotcl1.6.6 apps]
    Run make install-binaries install-libraries
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
#***v* Package/zlib1.2.3
# SOURCE
Package zlib1.2.3 {
  Source {Http http://www.equi4.com/pub/tk/tars/zlib.tar.gz}
}
#-------------------------------------------------------------------------------
#***v* Package/zlib1.2.3-static
# SOURCE
Package zlib1.2.3-static {
  Source {Link zlib1.2.3}
  Configure {
    eval file copy [glob [Get srcdir]/*] .
    set MYFLAGS "[Get TCL_EXTRA_CFLAGS] [Get TCL_CFLAGS_OPTIMIZE]"
    Run env CC=[Get CC] CFLAGS=$MYFLAGS ./configure --prefix=[Get builddir-sys] --exec-prefix=[Get builddir-sys]
  }
  Make {Run make}
  Install {
    file mkdir [file join [Get builddir]/share/man]
    Run make install
  }
  Clean {Run make clean}
}
#-------------------------------------------------------------------------------
};# end of DB

#===============================================================================

# start application
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
  ::kbs_main $argv
}
#===============================================================================
# vim: set syntax=tcl
