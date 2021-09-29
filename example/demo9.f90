program demo9
!!  long and short names using  --LONGNAME:SHORTNAME
use M_CLI2,  only : set_args, get_args, sget, rget, iget, lget
implicit none
   call set_args('--length:l 1 --height:h 10 --size:s 12.34567  --switch:X F --title:T "my title"')
   write(*,*)'--length or -l is ',rget('length')
   write(*,*)'--height or -h is ',rget('height')
   write(*,*)'--size or -s is   ',rget('size')
   write(*,*)'--switch or -X is ',lget('switch')
   write(*,*)'--title or -T is  ',sget('title')
end program demo9
