program demo3
!! QUICK PROTOTYPE: JUST THE BARE ESSENTIALS
use M_CLI2,  only : set_args, get_args
implicit none
integer                      :: x, y
logical                      :: l
real                         :: size
character(len=:),allocatable :: title
   call set_args('-x 1 -y 10 --size 12.34567  -l F --title "my titie"')
   call get_args('x',x)
   call get_args('y',y)
   call get_args('l',l)
   call get_args('size',size)
   call get_args('title',title)
   write(*,'(*("[",g0,"]":,1x))')x,y,size,l,title
end program demo3
