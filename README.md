# M_CLI2.f90 and associated files
<!--
![parse](docs/images/parse.png)
-->
## NAME
### M_CLI2 - parse Unix-like command line arguments from Fortran

## DESCRIPTION
   M_CLI2(3f) is a Fortran module that will crack the command line when
   given a prototype string that looks very much like an invocation of
   the program. A call to get_args(3f) or one of its variants is then
   made for each parameter name to set the variables appropriately in
   the program.

## EXAMPLE PROGRAM
This short program defines a command that can be called like

```bash
   ./show -x 10 -y -20 -p 10,20,30 --title 'plot of stuff' -L
   # these parameters are defined automatically 
   ./show --usage 
   ./show --help
   ./show --version
   # you must supply text for "help" and "version" if desired.
```
```fortran
   program show
   use M_CLI2, only : set_args, lget, rget, sget, igets
   implicit none
   real                          :: sum
   integer,allocatable           :: p(:)
   character(len=:),allocatable  :: title
   logical                       :: l, lbig
      !
      ! Define command and default values and parse supplied command line options
      !
      call set_args('-x 1 -y 2.0 -z 3.5e0 -p 11,-22,33 --title "my title" -l F -L F')
      !
      ! Get values using convenience functions
      !
      sum=rget('x') + rget('y') + rget('z')
      title=sget('title')
      p=igets('p')
      l=lget('l')
      lbig=lget('L')
      !
      ! All ready to go
      !
      write(*,*)sum,l,lbig,p,title
   end program show
```
An arbitrary number of strings such as filenames may be passed in on
the end of commands, you can query whether an option was supplied, and
get_args(3f)-related routines can be used for refining options such as
requiring lists of a specified size. Passing in some character arrays
allows you to automatically have a --help and --version switch as well,
as explained below.

## DEMO PROGRAMS![demos](docs/images/demo.gif)
These demo programs provide templates for the most common usage:

* [demo1B](example/demo1.f90)  basic with help and version, using the convenience functions
* [demo1](example/demo1.f90)   using the convenience functions
* [demo2](example/demo2.f90)   putting everything including **help** and **version** information into a contained procedure.
* [demo3](example/demo3.f90)   example of **basic** use
* [demo4](example/demo4.f90)   _COMPLEX_ type values
* [demo5](example/demo5.f90)   _CHARACTER_ type values
* [demo6](example/demo6.f90)   a complicated example showing how to create a command with subcommands
* [demo7](example/demo7.f90)   controlling array delimiter characters
* [demo8](example/demo8.f90)   multiple keyword and variable pairs on get_args(3f) for limited cases
* [demo9](example/demo9.f90)   long and short names using  --LONGNAME:SHORTNAME
* [demo10](example/demo10.f90) full usage and even equivalencing

## DOWNLOAD AND BUILD WITH make(1)![gmake](docs/images/gnu.gif)
   Compile the M_CLI2 module and build all the example programs.
   ```bash
       git clone https://github.com/urbanjost/M_CLI2.git
       cd M_CLI2/src
       # change Makefile if not using one of the listed compilers
     
       # for gfortran
       make clean
       make F90=gfortran gfortran
     
       # for ifort
       make clean
       make F90=ifort ifort

       # for nvfortran
       make clean
       make F90=nvfortran nvfortran

       # display other options (test, run, doxygen, ford, ...)
       make help 
   ```

## SUPPORTS FPM ![parse](docs/images/fpm_logo.gif) 
   Alternatively, download the github repository and build it with
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

## FUNCTIONAL SPECIFICATION
**This is how the interface works --**

* Pass in a string to set_args(3f) that looks almost like the command
  you would use to execute the program except with all keywords and
  default values specified.

* you add calls to the get_args(3f) procedure or one of its variants (
  The alternatives allow you to use a simple function-based interface
  model. There are special routines for when you want to use fixed length.
  CHARACTER variables or fixed-size arrays instead of the allocatable
  variables best used with get_args(3f)).

  Now when you call the program all the values in the prototype should
  be updated using values from the command line and queried and ready
  to use in your program.

## RESPONSE FILES
[Response files](response.md) are supported as described in the documentation for
[set_args](https://urbanjost.github.io/M_CLI2/set_args.3m_cli2.html).
They are a system-independent way to create short abbreviations for long
complex commands. This option is generally not needed by programs with
just a few options, but can be particularly useful for programs with
dozens of options where various values are frequently reused.

## DOCUMENTATION   ![docs](docs/images/docs.gif)
### man-pages as HTML
- [man-pages](https://urbanjost.github.io/M_CLI2/man3.html) -- man-pages index of individual procedures
- [BOOK_M_CLI2](https://urbanjost.github.io/M_CLI2/BOOK_M_CLI2.html) -- All man-pages consolidated using JavaScript
<!--
   + [M_CLI2](https://urbanjost.github.io/M_CLI2/M_CLI2.3m_cli2.html) --
     An overview of the M_CLI2 module
   + [set_args](https://urbanjost.github.io/M_CLI2/set_args.3m_cli2.html) --
     parses the command line options
   + [get_args](https://urbanjost.github.io/M_CLI2/get_args.3m_cli2.html) --
     obtain parameter values for allocatable arrays and scalars.
     This also documents the functions iget,igets,rget,rgets,sget,sgets,lget,lgets, ... .

     **less frequently used**
   + [get_args_fixed_length](https://urbanjost.github.io/M_CLI2/get_args_fixed_length.3m_cli2.html) --
     obtain parameter values for fixed-length character variable
   + [get_args_fixed_size](https://urbanjost.github.io/M_CLI2/get_args_fixed_size.3m_cli2.html) --
     obtain parameter values for fixed-size arrays
   + [specified](https://urbanjost.github.io/M_CLI2/specified.3m_cli2.html) --
     query whether an option was used on the commandline
-->
### real man-pages ![gmake](docs/images/manpages.gif)
   + [manpages.zip](https://urbanjost.github.io/M_CLI2/manpages.zip)
   + [manpages.tgz](https://urbanjost.github.io/M_CLI2/manpages.tgz)

### developer documentation  
- [doxygen(1) output](https://urbanjost.github.io/M_CLI2/doxygen_out/html/index.html).
- [ford(1) output](https://urbanjost.github.io/M_CLI2/fpm-ford/index.html).

### logs
- [CHANGELOG](docs/CHANGELOG.md)
- [STATUS](docs/STATUS.md) of most recent CI/CD runs

## COMMIT TESTS ##

commit `598e44164eee383b8a0775aa75b7d1bb100481c3` was tested on 2020-11-22 with
 + GNU Fortran (GCC) 8.3.1 20191121 (Red Hat 8.3.1-5)
 + ifort (IFORT) 19.1.3.304 20200925
 + nvfortran 20.7-0 LLVM 64-bit target on x86-64 Linux

commit `8fe841d8c0c1867f88847e24009a76a98484b31a` was tested on 2021-09-29 with
 + GNU Fortran (Ubuntu 10.3.0-1ubuntu1~20.04) 10.3.0
 + ifort (IFORT) 2021.3.0 20210609
 + nvfortran 21.5-0 LLVM 64-bit target on x86-64 Linux -tp nehalem 
---
Last updated:   Wed Sep 29 17:34:52 2021 -0400
