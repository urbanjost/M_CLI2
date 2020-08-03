# M_CLI2.f90 and associated files

![parse](docs/images/parse.png)

## NAME

### M_CLI2 - parse Unix-like command line arguments from Fortran

## DESCRIPTION

   M_CLI2(3f) is a Fortran module that will crack the command line when
   given a prototype string that looks very much like an
   invocation of the program. 

## DOWNLOAD
   ```bash
       git clone https://github.com/urbanjost/M_CLI2.git
       cd M_CLI2/src
       # change Makefile if not using gfortran(1)
       make
   ```
   This will compile the M_CLI2 module and build all the example programs.

## SUPPORTS FPM

   Alternatively, download the github repository and build it with 
   fpm ( as described at [Fortran Package Manager](https://github.com/fortran-lang/fpm) )
   
   ```bash
        git clone https://github.com/urbanjost/M_CLI2.git
        cd M_CLI2
        fpm build
        fpm test
   ```
   
   or just list it as a dependency in your fpm.toml project file.
   
        [dependencies]
        M_CLI2        = { git = "https://github.com/urbanjost/M_CLI2.git" }

## FUNCTIONAL SPECIFICATION

**This is how the interface works --**
   
* Pass in a string that looks like the command you would use to execute the program with all values specified.
  Now all the values in the prototype should be updated using values from the command line and ready to use.
* you read the results with the get_args(3f) procedure
   

## DOCUMENTATION
These demo programs provide templates for the most common usage:
   
- [demo1](PROGRAMS/demo1/demo1.f90) full usage 
- [demo2](PROGRAMS/demo2/demo2.f90) shows putting everything including **help** and **version** information into a contained procedure.
- [demo3](PROGRAMS/demo3/demo3.f90) example of **basic** use 
- [demo4](PROGRAMS/demo4/demo4.f90) using  **COMPLEX** values!
- [demo5](PROGRAMS/demo5/demo5.f90) demo2 with added example code for **interactively editing the NAMELIST group**
- [demo6](PROGRAMS/demo6/demo6.f90) a more complex example showing how to create a command with subcommands
- [demo7](PROGRAMS/demo7/demo7.f90) problems with CHARACTER arrays and quotes

### manpages
   
- [M_CLI2](https://urbanjost.github.io/M_CLI2/M_CLI2.3m_cli2.html)  -- An overview of the M_CLI2 module

- [set_args](https://urbanjost.github.io/M_CLI2/set_args.3m_cli2.html)  -- parses the command line options
   
- [get_args](https://urbanjost.github.io/M_CLI2/get_args.3m_cli2.html)  -- obtain parameter values

- [BOOK_M_CLI2](https://urbanjost.github.io/M_CLI2/BOOK_M_CLI2.html) -- All manpages consolidated using JavaScript

### doxygen

- [doxygen(1) output](https://urbanjost.github.io/M_CLI2/doxygen_out/html/index.html).

## EXAMPLE PROGRAM
   
This short program defines a command that can be called like
   
```bash
   ./show -x 10 -y -20 --point 10,20,30 --title 'plot of stuff' *.in
   ./show -x 10 -y -20 --point 10,20,30 --title 'plot of stuff' *.in
   ./show -z 300
   ./show *.in
   ./show --usage
   ./show --help
   ./show --version
```

```fortran
   program show
   use M_CLI2, only : set_args, get_args, files=>unnamed
   implicit none
   integer :: i
   
   !! DEFINE NAMELIST
   real               :: x, y, z  
   real               :: point(3) 
   character(len=:),allocatable  :: title   
   logical            :: l , lbig
   
   !! DEFINE COMMAND
   call set_args('-x 1 -y 2.0 -z 3.5e0 --point -1,-2,-3 --title "my title" -l F ')
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)
   call get_args('point',point)
   call get_args('p',p)
   call get_args('title',title)
   call get_args('l',l)
   call get_args('L',lbig)
   
   !! USE THE VALUES IN YOUR PROGRAM.
   
   !! OPTIONAL UNNAMED VALUES FROM COMMAND LINE
      if(size(files).gt.0)then
         write(*,'(a)')'files:'
         write(*,'(i6.6,3a)')(i,'[',files(i),']',i=1,size(files))
      endif
   
   end program show
```

-------
## FEEDBACK
   
   Please provide feedback on the
   [wiki](https://github.com/urbanjost/M_CLI2/wiki) or in the
   [__issues__](https://github.com/urbanjost/M_CLI2/issues)
   section or star the repository if you use the module (or let me know
   why not and let others know what you did use!).
-------
