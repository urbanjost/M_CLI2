program demo6
!! SUBCOMMANDS
!! For a command with subcommands like git(1)
!! you can make seperate namelists for each subcommand.
!! You can call this program which has two subcommands (run, test),
!! like this:
!!    demo6 --help
!!    demo6 run -x -y -z -title -l -L
!!    demo6 test -title -l -L -testname
!!    demo6 run --help

   implicit none
!! DEFINE VALUES TO USE AS ARGUMENTS WITH INITIAL VALUES
   real               :: x,y,z
   character(len=80)  :: title
   logical            :: l
   logical            :: l_
   character(len=80)  :: testname

   call parse() !! DEFINE AND PARSE COMMAND LINE

   !! ALL DONE CRACKING THE COMMAND LINE. USE THE VALUES IN YOUR PROGRAM.
   write(*,*)x,y,z,x+y+z
   write(*,*)'TITLE=',title
   write(*,*)l,l_
   write(*,*)'TESTNAME=',testname

contains

subroutine parse()
!! PUT EVERYTHING TO DO WITH COMMAND PARSING HERE FOR CLARITY
use M_CLI2, only : set_args, get_args, get_args_fixed_length, unnamed
character(len=20)             :: name    ! the subcommand name
character(len=:),allocatable  :: help_text(:), version_text(:)

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
     ' allowed subcommands are          ', &
     '   * run  -l -L -title -x -y -z   ', &
     '   * test -l -L -title            ', &
     '' ]

   ! assume first argument is always the subcommand keyword
   ! process command with all option names to look for --help|--usage|--version and get subcommand name
   call set_args('-x 1 -y 2 -z 3 --title "my title" -l F -L F --testname "TEST"',help_text,version_text)
   if(size(unnamed).gt.0)then
      name=unnamed(1)
   else
      name=''
   endif
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)
   call get_args_fixed_length('title',title)
   call get_args('l',l)
   call get_args('L',l_)
   call get_args_fixed_length('testname',testname)
   ! now process the subcommand
   select case(name)
   !============================================================================
   case('run')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "run"        ', &
     '                                  ', &
     '' ]
    call set_args('-x 1 -y 2 -z 3 --title "my title" -l F -L F',help_text,version_text)
    call get_args('x',x)
    call get_args('y',y)
    call get_args('z',z)
    call get_args_fixed_length('title',title)
    call get_args('l',l)
    call get_args('L',l_)
   !============================================================================
   case('test')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "test"       ', &
     '                                  ', &
     '' ]
    call set_args('--title "my title" -l F -L F --testname "Test"',help_text,version_text)
    call get_args_fixed_length('title',title)
    call get_args('l',l)
    call get_args('L',l_)
    call get_args_fixed_length('testname',testname)
   !============================================================================
   case default

      write(*,'(*(a))')'unknown or missing subcommand [',trim(name),']'
      write(*,'(a)')[character(len=80) ::  &
     ' allowed subcommands are          ', &
     '   * run  -l -L -title -x -y -z   ', &
     '   * test -l -L -title            ', &
     '' ]
     stop
   !============================================================================
   end select
   !============================================================================
end subroutine parse

end program demo6
