program demo6
use M_CLI2, only : set_args, get_args, get_args_fixed_length, rget,sget,lget
! SUBCOMMANDS
! For a command with subcommands like git(1) you can call this program
! which has two subcommands (run, test), like this:
!    demo6 --help
!    demo6 run -x -y -z -title -l -L
!    demo6 test -title -l -L -testname
!    demo6 run --help
implicit none
! define values to use as arguments with initial values
character(len=80)  :: title, testname
character(len=20)  :: name
logical            :: l, l_

   call parse(name) ! define help text and parse command line
   select case(name) ! use values from command line
   case('run')
      ! example using convenience functions to retrieve values and pass them
      ! to a routine
      call my_run(rget('x'),rget('y'),rget('z'),sget('title'),lget('l'),lget('L'))
   case('test')
      ! use get_args(3f) to extract values and use them
      call get_args_fixed_length('title',title)
      call get_args('l',l)
      call get_args('L',l_)
      call get_args_fixed_length('testname',testname)
      ! all done cracking the command line. use the values in your program.
      write(*,*)'command was ',name
      write(*,*)'title .... ',trim(title)
      write(*,*)'l,l_ ..... ',l,l_
      write(*,*)'testname . ',trim(testname)
   case default
   end select

contains

subroutine parse(name)
! put everything to do with command parsing here for clarity
use M_CLI2, only : set_args, get_args, get_args_fixed_length
use M_CLI2, only : get_subcommand
use M_CLI2, only : CLI_RESPONSE_FILE
character(len=*)              :: name    ! the subcommand name
character(len=:),allocatable  :: help_text(:), version_text(:)
   CLI_RESPONSE_FILE=.true.

! define version text
   version_text=[character(len=80) :: &
      '@(#)PROGRAM:     demo6            >', &
      '@(#)DESCRIPTION: My demo program  >', &
      '@(#)VERSION:     1.0 20200715     >', &
      '@(#)AUTHOR:      me, myself, and I>', &
      '@(#)LICENSE:     Public Domain    >', &
      '' ]
    ! general help for "demo6 --help"
    help_text=[character(len=80) :: &
     ' General help describing the       ', &
     ' program.                          ', &
     '' ]
   ! find the subcommand name by looking for first word on command
   ! not starting with dash
   name = get_subcommand()
   ! define commands and parse command line and set help text
   select case(name)
   case('run')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "run"        ', &
     '                                  ', &
     '' ]
    call set_args('-x 1 -y 2 -z 3 --title "my title" -l F -L F',help_text,version_text)
    ! use convenience routines to extract values
   case('test')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "test"       ', &
     '                                  ', &
     '' ]
    call set_args('--title "my title" -l F -L F --testname "Test"',help_text,version_text)

   case default
      call set_args(' ',help_text,version_text) ! process help and version

      write(*,'(*(a))')'unknown or missing subcommand [',trim(name),']'
      write(*,'(a)')[character(len=80) ::   &
     ' allowed subcommands are           ', &
     '   * run                           ', &
     '   * test                          ', &
     '' ]
     stop

   end select

end subroutine parse

subroutine my_run(x,y,z,title,l,l_)
! nothing about commandline parsing here!
real,intent(in)              :: x,y,z
character(len=*),intent(in)  :: title
logical,intent(in)           :: l
logical,intent(in)           :: l_
   write(*,*)'MY_RUN'
   write(*,*)'x,y,z .....',x,y,z
   write(*,*)'title .... ',title
   write(*,*)'l,l_ ..... ',l,l_
end subroutine my_run

end program demo6
