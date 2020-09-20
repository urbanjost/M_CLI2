program demo9
!! QUICK PROTOTYPE: JUST THE BARE ESSENTIALS
use M_CLI2,  only : set_args, get_args
use M_CLI2,  only : sget, rget, iget, lget
use M_CLI2,  only : sgets, rgets, igets, lgets
implicit none
   call set_args('-x 1 -y 10 --size 12.34567  -l F --title "my title"')
   !write(*,'(*("[",g0,"]":,1x))')iget('x'),iget('y'),rget('size'),lget('l'),sget('title')
   write(*,'(*("[",g0,"]":,1x))')igets('x'),igets('y'),rgets('size'),lgets('l'),sgets('title')
end program demo9
