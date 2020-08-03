program basic
!! QUICK PROTOTYPE: JUST THE BARE ESSENTIALS
use M_CLI2,  only : commandline, check_commandline
implicit none
character(len=:),allocatable :: readme ! stores updated namelist
character(len=256)           :: message
integer                      :: ios
integer                      :: x, y, z
namelist /args/ x,y,z
   readme=commandline('-x 1 -y 10 -z 100')
   read(readme,nml=args,iostat=ios,iomsg=message)
   call check_commandline(ios,message)
   write(*,'(*(g0,1x))')x,y,z, x+y+z
end program basic
