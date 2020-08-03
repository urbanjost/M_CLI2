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
   integer            :: i
!! DEFINE VALUES TO PUT IN NAMELISTS/USE AS ARGUMENTS WITH INITIAL VALUES
   real               :: x=-1,y=-1,z=-1
   character(len=80)  :: title=''
   logical            :: l=.false.
   logical            :: l_=.false.
   character(len=80)  :: testname='TEST'

   call parse() !! DEFINE AND PARSE COMMAND LINE

   !! ALL DONE CRACKING THE COMMAND LINE. USE THE VALUES IN YOUR PROGRAM.
   write(*,*)x+y+z
   write(*,*)title
   write(*,*)l,l_

contains

subroutine parse()
!! PUT EVERYTHING TO DO WITH COMMAND PARSING HERE FOR CLARITY
use M_CLI2, only : commandline, check_commandline, unnamed
character(len=20)             :: name    ! the subcommand name
character(len=255)            :: message ! use for I/O error messages
character(len=:),allocatable  :: readme  ! stores updated namelist
character(len=:),allocatable  :: help_text(:), version_text(:)
integer                       :: ios

! list all possible arguments in this NAMELIST so can get keyword and process simple -help|-version|-usage
! when user does not supply a subcommand
namelist /args/ x,y,z,title,l,l_,testname

! define a namelist for each subcommand. Note that variables can appear in multiple namelists
namelist /run/  x,y,z,title,l,l_
namelist /test/ title,l,l_,testname

! optionally define version text
   version_text=[character(len=80) :: &
      '@(#)PROGRAM:     demo6            >', &
      '@(#)DESCRIPTION: My demo program  >', &
      '@(#)VERSION:     1.0 20200715     >', &
      '@(#)AUTHOR:      me, myself, and I>', &
      '@(#)LICENSE:     Public Domain    >', &
      '' ]

   ! call with all options just to get unused name or to process --help|--version|--usage when subcommand not given
    readme=commandline('-x 1 -y 2 -z 3 --title "my title" -l F -L F --testname "TEST"',name='args')

   ! assume first argument is always the subcommand keyword
   name=''
   if(size(unnamed).gt.0)then
      name=unnamed(1)
   endif
   ! now process the subcommand
   select case(name)
   !============================================================================
   case('run')
    readme=commandline('-x 1 -y 2 -z 3 --title "my title" -l F -L F',name='run')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "run"        ', &
     '                                  ', &
     '' ]
      read(readme,nml=run,iostat=ios,iomsg=message)
   !============================================================================
   case('test')
    readme=commandline('--title "my title" -l F -L F --testname "Test"',name='test')
    help_text=[character(len=80) :: &
     '                                  ', &
     ' Help for subcommand "test"       ', &
     '                                  ', &
     '' ]
      read(readme,nml=test,iostat=ios,iomsg=message)
   !============================================================================
   case default
    ! general help for "demo6 --help"
    help_text=[character(len=80) :: &
     ' allowed subcommands are          ', &
     '   * run  -l -L -title -x -y -z   ', &
     '   * test -l -L -title            ', &
     '' ]
     ! see if -help|-usage|-version were used
     read(readme,nml=run,iostat=ios,iomsg=message)
     call check_commandline(ios,message,help_text,version_text)
     ! bad or missing subcommand
      write(*,'(*(a))')'unknown or missing subcommand [',trim(name),']'
      write(*,'(a)')[character(len=80) ::  &
     ' allowed subcommands are          ', &
     '   * run  -l -L -title -x -y -z   ', &
     '   * test -l -L -title            ', &
     '' ]
     stop
   !============================================================================
   end select

   call check_commandline(ios,message,help_text,version_text)

end subroutine parse

end program demo6
