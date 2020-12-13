## RESPONSE FILES

M_CLI2 Response files are small files containing CLI (Command Line
Interface) arguments that are used when command lines are so long that
they would exceed line length limits or so complex that it is useful to
have a platform-independent method of creating an alias.

Examples of commands that support similar response files are the Clang
and Intel compilers, although there is no standard format for the files.

The file names must end with ".rsp".

Shell aliases and scripts are often used for similar purposes (and
allow for much more complex conditional execution, of course), but
they generally cannot be used to overcome line length limits and are
typically platform-specific.

That being said, if you want your program to support response files simply
add "response=.true." to your set_args(3f) call. Then add options of
the syntax "@NAME" as the **first** parameters on your program command
line calls.

The first resource file found that results in lines being processed
will be used and processing stops after that first match is found. If
no match is found an error occurs and the program is stopped.

A search for the response file always starts with the current directory.
The search then proceeds to look in any additional directories specified
with the colon-delimited environment variable CLI_RESPONSE_PATH.

Assuming the name @NAME was specified on the command line a file named
NAME.rsp will be searched for in all those search locations for a string
that starts with the string @OSTYPE if the environment variables $OS and
$OSTYPE are not blank.  OSTYPE is the value of the environment variable
OSTYPE unless it is unset, in which case the value of the variable OS
will be used.

Then, the same files will be searched for lines before any line
starting with "@". 

Then, a file name EXECUTABLE.rsp will be searched for in the same locations
where EXECUTABLE is the basename of the program being executed. This file
is always a "complex" response file that uses the format described below
to allow for multiple entries.

All the EXECUTABLE.rsp files will be searched for the string @OSTYPE@NAME.

The last search is to search all the EXCUTABLE.rsp files for the string
@NAME.

Sounds complicated but actually works quite intuitively. Make a file in
the current directory and put options in it and it will be used. If that
file ends up needing different cases for different platforms add a line
like "@Linux" to the file and some more lines and that will only be
executed if the environment variable OSTYPE or OS is "Linux". If no match
is found for named sections the lines at the top before any "@" lines
will be used as a default if not match is found.

If you end up using a lot of files like this you can combine them all
together and put them info a file called "program_name.rsp" and just 
put lines like @NAME or @OSTYPE@NAME at that top of each section.

Note that more than one response name may appear on a command line.

They are case-sensitive names.

As mentioned, they must be the first options on the command line.


## SPECIFICATION FOR RESPONSE FILES

### SIMPLE RESPONSE FILES

The first word of a line is special and has the following meanings:

 + **options|-** Command options following the rules of the SET_ARGS(3f) prototype.
                 So 
		  + It is preferred to specify a value for all options.
		  + double-quote strings. 
		  + give a blank string value as " ".
		  + use F|T for lists of logicals,
		  + lists of numbers should be comma-delimited.
 + **comment|#** Line is a comment line
 + **system|!**  System command.
                 System commands are executed as a simple call to
                 system (so a cd(1) or setting a shell variable 
		 would not effect subsequent lines, for example)
 + **print|>**   Message to screen
 + **stop**      display message and stop program.

So if a program that echoed its parameters has a call of the form 

```text
set_args('-x 10.0 -y 20.0 --title "my title",response=.true.)
```

And a file in the current directory called "a.rsp" contained

```text
# defaults for project A
options -x 1000 -y 9999
options --title "my new default title"

The program could be called with
```bash
# normal
$myprog
 X=10.0 Y=20.0 TITLE="my title"

# change defaults as specified in "a.rsp"
$myprog @a
 X=1000.0 Y=9999.0 TITLE="my new default title"

# change defaults but use any option as normal to override defaults
$myprog @a -y 1234
 X=1000.0 Y=1234.0 TITLE="my new default title"

### COMPOUND RESPONSE FILES

A compound response file has the same basename as the executable with a
".rsp" suffix added. So if your program is named "myprg" the filename
must be "myprg.rsp".

   Note that here `basename` means the basename of the
   name of the program as returned by the Fortran intrinsic
   GET_COMMAND_ARGUMENT(0,...) trimmed of anything after a period ("."),
   so it is a good idea not to use hidden files.

Unlike simple response files compound response files can contain multiple
setting names.

If the environment variable $OSTYPE (first) or $OS is set the search
will first be for a line of the form (no leading spaces should be used):

```text
   @OSTYPE@alias_name
```

If no match or if the environment variables $OSTYPE and $OS were not
set or a match is not found then a line of the form
```text
   @alias_name
```
is searched for. Subsequent lines will be ignored that start with "@"
until a line not starting with "@" is encountered.  Lines will then be
processed until another line starting with "@" is found or end-of-file
is encountered.


### COMPOUND RESPONSE FILE EXAMPLE
 An example compound file
```bash
   #################
   @if
   > RUNNING TESTS USING RELEASE VERSION AND ifort
   - test --release --compiler ifort 
   #################
   @gf
   > RUNNING TESTS USING RELEASE VERSION AND gfortran
   - test --release --compiler gfortran 
   #################
   @nv
   > RUNNING TESTS USING RELEASE VERSION AND nvfortran
   - test --release --compiler nvfortran 
   #################
   @nag
   > RUNNING TESTS USING RELEASE VERSION AND nagfor
   - test --release --compiler nagfor 
   #
   #################
   # OS-specific example:
   @Linux@install
   #
   # install executables in directory (assuming install(1) exists)
   #
   !mkdir -p ~/.local/bin
   - run --release T --compiler gfortran --runner "install -vbp -m 0711 -t ~/.local/bin"
   @install
   @STOP INSTALL NOT SUPPORTED ON THIS PLATFORM OR $OSTYPE NOT SET
   #
   #################
   @fpm@testall
   #
   !fpm test --compiler nvfortran
   !fpm test --compiler ifort
   !fpm test --compiler gfortran
   !fpm test --compiler nagfor
   STOP tests complete. Any additional parameters were ignored
   #################
```
 Would be used like

```bash
   fpm @install
   fpm @nag -- 
   fpm @testall
```

## NOTES

   The intel Fortran compiler now calls the response files "indirect
   files" and does not add the implied suffix ".rsp" to the files
   anymore. It also allows the `@NAME` syntax anywhere on the command
   line, not just at the beginning. --  20201212

<!-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ -->
<!--
<+ -varname DEFAULT_VALUE>this is the prompt
 These results would be pasted together. Must come before line with -
 would have to determine type using varname
-->

<!--
  Put options into environment variables so can be used in commands
-->

<!--
  Way to file files and just show print lines or to echo files might be useful
-->

<!--
##ALTERNATIVE
 us M_logic and M_calculator and make look a lot like a bashshell input file
allowing for variables and so on

 M_logic would provide conditional based on environment if/else/elseif/endif.
 Could use existing functions and syntax would look Unix-like.
-->
<!-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ -->
<!--
20201210
awvwgk opened this issue 2 days ago · 2 comments
Comments
@awvwgk
Contributor
awvwgk commented 2 days ago

I'm not entirely sure where this exactly originates and where to find a
good documentation on this, but some compilers and build tools support
a “response file.” Usually the syntax is

prog @file1.rsp @file2.rsp

where file1.rsp, file2.rsp, ... contain the command line arguments
separated by newlines and can be combined with normal command lines
arguments. Some implementations allow further references to other response
files in the response file. I did find some documentation for MSBuild.exe
on rsp-files and some notes at the ninja build manpage.

This might be an interesting feature for this library since it would allow
to store (maybe even load and/or dump) command lines as a file, which
makes it useful for testing or storing frequently needed (complicated)
command lines.  @awvwgk awvwgk mentioned this issue 2 days ago Add
--compiler switch fortran-lang/fpm#255
-->
<!-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ -->
