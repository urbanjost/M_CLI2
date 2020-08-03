program quick_and_dirty
!! COMPLEX VALUES
use M_CLI2,  only : commandline, check_commandline
implicit none
character(len=:),allocatable :: readme ! stores updated namelist
integer                      :: ios
character(len=256)           :: message
complex                      :: x, y, z; namelist /args/ x,y,z

   write(*,*)'the values are specified using NAMELIST input rules so'
   write(*,*)'demo4 -x 11.1,22.2 -y 333,444'
   write(*,*)"demo4 -x '(11.1,22.2)'"

   readme=commandline('-x (1,2) -y (10,20) -z (100,200)')
   read(readme,nml=args,iostat=ios,iomsg=message)
   call check_commandline(ios,message)
   write(*,*)x,y,z, x+y+z
end program quick_and_dirty
