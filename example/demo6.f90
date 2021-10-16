program demo6
! SUBCOMMANDS
!
! For a command with subcommands like git(1) you can call this program
! which has two subcommands (run, test), like this:
!
!    demo6 --help
!    demo6 run -x -y -z -title -l -L
!    demo6 test -title -l -L -testname
!    demo6 run --help
!
use M_CLI2, only : set_args, get_args, get_args_fixed_length, get_subcommand
use M_CLI2, only : rget,sget,lget
use M_CLI2, only : CLI_RESPONSE_FILE
implicit none
character(len=:),allocatable   :: name    ! the subcommand name
character(len=:),allocatable   :: version_text(:), help_text(:)
! define some values to use as arguments 
character(len=80)  :: title, testname
logical            :: l, l_

   version_text=[character(len=80) :: &
   '@(#)PROGRAM:     demo6            >', &
   '@(#)DESCRIPTION: My demo program  >', &
   '@(#)VERSION:     1.0 20200715     >', &
   '@(#)AUTHOR:      me, myself, and I>', &
   '@(#)LICENSE:     Public Domain    >', &
   '' ]
   CLI_RESPONSE_FILE=.true.
   ! find the subcommand name by looking for first word on command
   ! not starting with dash
   name = get_subcommand()

   ! define commands and parse command line and set help text and process command
   select case(name) 

   case('run')
      help_text=[character(len=80) :: &
       '                                  ', &
       ' Help for subcommand "run"        ', &
       '                                  ', &
       '' ]
      call set_args('-x 1 -y 2 -z 3 --title "my title" -l F -L F',help_text,version_text)
      ! example using convenience functions to retrieve values and pass them
      ! to a routine
      call my_run(rget('x'),rget('y'),rget('z'),sget('title'),lget('l'),lget('L'))

   case('test')
      help_text=[character(len=80) :: &
       '                                  ', &
       ' Help for subcommand "test"       ', &
       '                                  ', &
       '' ]
      call set_args('--title "my title" -l F -L F --testname "Test"',help_text,version_text)
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

   case('')
      ! general help for "demo6 --help"
      help_text=[character(len=80) :: &
       ' General help describing the       ', &
       ' program.                          ', &
       '' ]
      call set_args(' ',help_text,version_text) ! process help and version

   case default
      call set_args(' ',help_text,version_text) ! process help and version
      write(*,'(*(a))')'unknown or missing subcommand [',trim(name),']'

   end select

contains

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
