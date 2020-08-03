program basic
!! QUICK PROTOTYPE: JUST THE BARE ESSENTIALS
use M_CLI2,  only : set_args, get_args
implicit none

integer            ::  x,y,z      
integer            ::  casen      
integer            ::  ints(4)=0  
character(len=20)  ::  string     

character(len=:),allocatable :: command
character(len=4096)          :: cmd
logical                      :: nq=.false.
integer                      :: e

   command=repeat(' ',4096)
   call get_command(command)
   command=trim(command)//' '
   write(*,'(*(g0,1x))')'COMMAND=',command

   call get_command_argument(0,cmd)
   e=len_trim(cmd)+1
   command='-x 10 -y 20 -z 30 -ints 11,22,33 -casen 0 -string "My string,""again"""'
   call readcli()
   
   select case(casen)
   case(0)
      call printit(all([x,y,z,ints].eq.[10,20,30,11,22,33,0]))
      call execute_command_line(cmd(:e)//'-x 4 -y 5 -z 6 -casen 1')
   case(1)
      call printit(all([x,y,z].eq.[4,5,6]))
      call execute_command_line(cmd(:e)//'-x 40 -y 50 -z 60 -casen 2')
   case(2)
      call printit(all([x,y,z].eq.[40,50,60]))
      call execute_command_line(cmd(:e)//'-x 400 -y 500 -z 600 -ints -1,-2,-3 -casen 3')
   case(3)
      call printit(all([x,y,z,ints].eq.[400,500,600,-1,-2,-3,0]))
      call execute_command_line(cmd(:e)//'-x 400 -y 500 -z 600 -ints -1,-2,-3 -casen 900')
   case(900)
      write(*,*)'USAGE'
      call execute_command_line(cmd(:e)//'--casen 901 --usage')
      call execute_command_line(cmd(:e)//'--casen 901')
   case(901)
      write(*,*)'HELP'
      call execute_command_line(cmd(:e)//'--casen 902 --help')
      call execute_command_line(cmd(:e)//'--casen 902')
   case(902)
      write(*,*)'VERSION'
      call execute_command_line(cmd(:e)//'--casen 999 --version')
      call execute_command_line(cmd(:e)//'--casen 999')
   case(7)
   case(8)
   case(9)
   case(999)
   case default
      write(*,'(a)')'default - should not get here'
      stop
   end select

contains

subroutine printit(testit)
logical testit
   write(*,'(*(g0,1x))',advance='no')merge('PASSED:','FAILED:',testit)
   write(*,nml=args)
   write(*,'(/,a)')repeat('=',132)
end subroutine printit

subroutine readcli()
character(len=:),allocatable :: readme ! stores updated namelist
character(len=256)           :: message
integer                      :: ios
   !!write(*,'(*(g0,1x))')'SET DEFAULTS',trim(command)
   readme=commandline(command,noquote=nq)
   !!write(*,'(*(g0,1x))')'NAMELIST STRING=',trim(readme)
   read(readme,nml=args,iostat=ios,iomsg=message)
   call check_commandline(ios,message)
end subroutine readcli

end program basic
