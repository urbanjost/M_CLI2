# M_CLI2.f90 and associated files
![M_CLI2](docs/images/M_CLI2.gif)
## Name
### M_CLI2 - parse Unix-like command line arguments from Fortran

## Description
   M_CLI2(3f) is a Fortran module that will crack the command line when
   given a prototype string that looks very much like an invocation of
   the program. Calls are then made for each parameter name to set the
   variables appropriately in the program. 

   One approach is to isolate all the parsing to the beginning of the
   program, which is generally just a few lines:
```fortran
   program compartmentalized
   use M_CLI2, only : set_args, get_args, s=>sget, r=>rget, i=>iget, l=>lget 
   implicit none
   !
   ! define command options and default values and parse command line
     call set_args('-x 1 -y 2.0 -i 11 --title:T "my title" -l F -L F')
   ! just like calling the command accept --title:T means to give it the long
   ! name "title" and the short name "T" and that to define a boolean you give
   ! it the unquoted value of F.
   !
   ! convert arguments to the desired types and call main program
     call main( x=r('x'), y=r('y'), title=s('title'), i=i('i'), l=l('l'), lbig=l('L'))
   contains 
   subroutine main(x,y,title,i,l,lbig)
   ! do something with the values, all the parsing is done
   real                          :: x,y     ;namelist /args/x,y
   logical                       :: l,lbig  ;namelist /args/l,lbig
   integer                       :: i       ;namelist /args/i
   character(len=:),allocatable  :: title   ;namelist /args/title
   write(*,nml=args)
   end subroutine main
   end program compartmentalized
```
## Example Program
This short program defines a command that can be called using
conventional Unix-style syntax for short and long parameters:

```bash
   # arrays can be allowed like for "-p":
   ./show -x 10 -y -20 -p 10,20,30 --title "plot of stuff" -L
   ./show -lL # in strict mode booleans may be concatenated
   ./show  --title="my new title" # --name=value or --name value is OK
   ./show  -T "my new title" # a short name for "title"
```
```fortran
   program show
   use M_CLI2, only : set_args, get_args, set_mode
   use M_CLI2, only : sget, rget, iget, lget 
   use M_CLI2, only : sgets, rgets, igets, lgets 
   implicit none
   real                          :: x,y,z
   logical                       :: l, lbig
   integer,allocatable           :: p(:)
   character(len=:),allocatable  :: title
   namelist /args/x,y,z,l,lbig,p,title ! just for printing
      call set_mode('strict')
      !
      ! Define command and default values and parse supplied command line options
      call set_args('-x 1 -y 2.0 -z 3.5e0 -p 11,-22,33 --title:T "my title" -l F -L F')
      ! use convenience functions for scalar values or allocatable arrays. 
      ! The functions are particularly useful in expressions and as arguments on
      ! procedure calls:
      x=rget('x')         ! float 
      y=rget('y') 
      z=rget('z') 
      title=sget('title') ! string 
      p=igets('p')        ! integer array
      l=lget('l')         ! logical
      lbig=lget('L')
      ! All ready to go, print it as a namelist so everything is labeled
      write(*,args)
      !
      ! Alternatively: use get_args directly instead of via the convenience routines:
      !
      ! multiple scalar non-allocatable values can be done in one call if desired
      call get_args('x',x,'y',y,'z',z,'l',l,'L',lbig)
      !
      ! allocatable arrays and allocatable string lengths need called by themselves
      call get_args('title',title)
      call get_args('p',p)
      !
      ! All ready to go, print it as a namelist so everything is labeled
      write(*,args)
   end program show
```
running with no options shows the defaults
```text
&ARGS
 X=  1.00000000    ,
 Y=  2.00000000    ,
 Z=  3.50000000    ,
 L=F,
 LBIG=F,
 P=11         ,-22        ,33         ,
 TITLE="my title",
 /
```
An arbitrary number of strings such as filenames may be passed in on
the end of commands; you can query whether an option was supplied; and
get_args(3f)-related routines can be used for refining options such as
requiring lists of a specified size.

These parameters are defined automatically
```bash
    --help
    --usage
    --verbose
    --version
```
You must supply text for the optional "--help" and "--version" keywords, as
described under SET_ARGS(3f).

![docs](docs/images/docs.gif)
## Documentation

![manpages](docs/images/manpages.gif)
### man-pages 
- HTML [man-pages](https://urbanjost.github.io/M_CLI2/man3.html) index of individual procedures
- HTML [book-form ](https://urbanjost.github.io/M_CLI2/BOOK_M_CLI2.html) of pages consolidated using JavaScript
+ [manpages.zip](https://urbanjost.github.io/M_CLI2/manpages.zip) for installing wherever the man(1) command is available
+ [manpages.tgz](https://urbanjost.github.io/M_CLI2/manpages.tgz) is an alternative tar(1) format archive

### developer documentation
- [doxygen(1) output](https://urbanjost.github.io/M_CLI2/doxygen_out/html/index.html).
- [ford(1) output](https://urbanjost.github.io/M_CLI2/fpm-ford/index.html).

### logs
- [CHANGELOG](docs/CHANGELOG.md)
- [STATUS](docs/STATUS.md) of most recent CI/CD runs

### standalone command-line documentation program
The
[3.2.0 release](https://github.com/urbanjost/M_CLI2/releases/tag/V3.2.0)
of the command-line parser module
[M_CLI2](https://github.com/urbanjost/M_CLI2)
has a [standalone program](https://raw.githubusercontent.com/urbanjost/index/main/bootstrap/fpm-m_cli2.f90)
available that will display the help text for the procedures as a
substitute for the man(1) pages.

If the program is placed in your search path you can enter
```text
fpm-m_cli2 --help
# if an fpm user
fpm m_cli2 --help
```
for a description of usage.
An example to build it on a typical Linux platform would be
```bash
# create a scratch directory for the build
mkdir temp
cd temp
# get the documentation program
curl https://raw.githubusercontent.com/urbanjost/index/main/bootstrap/fpm-m_cli2.f90
# compile the program
gfortran fpm-m_cli2.f90 -o fpm-m_cli2
# copy it to somewhere in your path
mv fpm-m_cli2 $HOME/.local/bin/
```

![gmake](docs/images/gnu.gif)
## Download and Build with Make(1)
   Compile the M_CLI2 module and build all the example programs.
```bash
   git clone https://github.com/urbanjost/M_CLI2.git
   cd M_CLI2/src
   # change Makefile if not using one of the listed compilers

   # for gfortran
   make clean
   make gfortran

   # for ifort
   make clean
   make ifort

   # for nvfortran
   make clean
   make nvfortran

   # display other options (test, run, doxygen, ford, ...)
   make help
```
   To install you then generally copy the *.mod file and *.a file to
   an appropriate directory.  Unfortunately, the specifics vary but in
   general if you have a directory $HOME/.local/lib and copy those files
   there then you can generally enter something like
```bash
     gfortran -L$HOME/.local/lib -lM_CLI2  myprogram.f90 -o myprogram
```
   There are different methods for adding the directory to your default
   load path, but frequently you can append the directory you have
   placed the files in into the colon-separated list of directories
   in the $LD_LIBRARY_PATH or $LIBRARY_PATH environment variable, and
   then the -L option will not be required (or it's equivalent in your
   programming environment).
```bash
       export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH
```
   **NOTE**: If you use multiple Fortran compilers you may need to create
   a different directory for each compiler. I would recommend it, such
   as $HOME/.local/lib/gfortran/.

### Creating a shared library

   If you desire a shared library as well, for gfortran you may enter
```bash
     make clean gfortran gfortran_install
```
   and everything needed by gfortran will be placed in libgfortran/ that
   you may add to an appropriate area, such as $HOME/.local/lib/gfortran/.
```bash
     make clean ifort ifort_install # same for ifort
```
   does the same for the ifort compiler and places the output in libifort/.
### Specifics may vary

   NOTE: The build instructions above are specific to a ULS (Unix-Like
   System) and may differ, especially for those wishing to generate shared
   libraries (which varies significantly depending on the programming
   environment). For some builds it is simpler to make a Makefile for
   each compiler, which might be required for a more comprehensive build
   unless you are very familiar with gmake(1).

   If you always use one compiler it is relatively simple, otherwise
   make sure you know what your system requires and change the Makefile
   as appropriate.

![parse](docs/images/fpm_logo.gif)
## Build with FPM
   Alternatively, fpm(1) users may download the github repository and build it with
   fpm ( as described at [Fortran Package Manager](https://github.com/fortran-lang/fpm) )
```bash
        git clone https://github.com/urbanjost/M_CLI2.git
        cd M_CLI2
        fpm test   # build and test the module
        fpm install # install the module (in the default location)
```
   or just list it as a dependency in your fpm.toml project file.
```toml
        [dependencies]
        M_CLI2        = { git = "https://github.com/urbanjost/M_CLI2.git" }
```

## Supports Meson
   Alternatively, meson(1) users may download the github repository and build it with
   meson ( as described at [Meson Build System](https://mesonbuild.com/) )
```bash
        git clone https://github.com/urbanjost/M_CLI2.git
        cd M_CLI2
        meson setup _build
        meson test -C _build  # build and test the module

        # install the module (in the <DIR> location)
        # --destdir is only on newer versions of meson
        meson install -C _build --destdir <DIR>
        # older method if --destdir is not available
        env DESTDIR=<DIR> meson install -C _build
```
   or just list it as a [subproject dependency](https://mesonbuild.com/Subprojects.html) in your meson.build project file.
```meson
        M_CLI2_dep = subproject('M_CLI2').get_variable('M_CLI2_dep')
```

## Functional Specification
**This is how the interface works --**

* Pass in a string to set_args(3f) that looks almost like the command
  you would use to execute the program except with all keywords and
  default values specified.

* you add calls to the get_args(3f) procedure or one of its variants.
  The alternative convenience procedures (rget(3f),sget(3f),iget(3f)
  ...) allow you to use a simple function-based interface model. There
  are special routines for when you want to use fixed length.  CHARACTER
  variables or fixed-size arrays instead of the allocatable variables
  best used with get_args(3f)).

  Now when you call the program all the values in the prototype should
  be updated using values from the command line and queried and ready
  to use in your program.

![demos](docs/images/demo.gif)
## Demo Programs
These demo programs provide templates for the most common usage:

* [demo3](example/demo3.f90)   Example of **basic** use
* [demo1](example/demo1.f90)   Using the convenience functions
* [demo9](example/demo9.f90)   Long and short names using --LONGNAME:SHORTNAME.
* [demo2](example/demo2.f90)   Putting everything including **help** and **version** information into a contained procedure.
* [demo17](example/demo17.f90) Using unnamed options as filenames or strings
* [demo16](example/demo16.f90) Using unnamed values as numbers

## Optional Modes
* [demo15](example/demo15.f90) Allowing bundling short Boolean keys using "strict" mode
* [demo14](example/demo14.f90) Case-insensitive long keys
* [demo12](example/demo12.f90) Enabling response files
* [demo13](example/demo13.f90) Equivalencing dash to underscore in keynames

## Niche examples
* [demo8](example/demo8.f90)   Parsing multiple keywords in a single call to get_args(3f)
* [demo4](example/demo4.f90)   _COMPLEX_ type values
* [demo7](example/demo7.f90)   Controlling array delimiter characters
* [demo6](example/demo6.f90)   How to create a command with subcommands
* [demo5](example/demo5.f90)   extended description of using _CHARACTER_ type values

## Response files
[Response files](response.md) are supported as described in the documentation for
[set_args](https://urbanjost.github.io/M_CLI2/set_args.3m_cli2.html).
They are a system-independent way to create short abbreviations for long
complex commands. This option is generally not needed by programs with
just a few options, but can be particularly useful for programs with
dozens of options where various values are frequently reused.

## Commit Tests ##

commit `598e44164eee383b8a0775aa75b7d1bb100481c3` was tested on 2020-11-22 with
 + GNU Fortran (GCC) 8.3.1 20191121 (Red Hat 8.3.1-5)
 + ifort (IFORT) 19.1.3.304 20200925
 + nvfortran 20.7-0 LLVM 64-bit target on x86-64 Linux


commit `8fe841d8c0c1867f88847e24009a76a98484b31a` was tested on 2021-09-29 with
 + GNU Fortran (Ubuntu 10.3.0-1ubuntu1~20.04) 10.3.0
 + ifort (IFORT) 2021.3.0 20210609
 + nvfortran 21.5-0 LLVM 64-bit target on x86-64 Linux -tp nehalem

commit `732bcadf95e753ccdf025cec2c08d776ea2534c2` was tested on 2023-02-10 with
 + ifort (IFORT) 2021.8.0 20221119
 + GNU Fortran (Ubuntu 11.1.0-1ubuntu1~20.04) 11.1.0
---
<!--
Last updated:   Wed Sep 29 17:34:52 2021 -0400
Last update: Sat 21 Jan 2023 11:10:53 PM EST
-->
Last update: Saturday, February 4th, 2023 1:12:54 AM UTC-05:00
