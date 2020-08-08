program demo5
!! CHARACTER VARIABLES
use M_CLI2,  only : set_args, get_args, get_args_fixed_size,get_args_fixed_length
implicit none
character(len=:),allocatable  :: ax       ! variable length scalar
character(len=19)             :: fy       ! fixed length scalar
character(len=:),allocatable  :: vvarr(:) ! variable array size and variable length
character(len=19)             :: ffarr(3) ! fixed array size and fixed length
character(len=19),allocatable :: vfarr(:) ! fixed array size and variable length

character(len=*),parameter   :: fmt='(*("[",g0,"]":,1x))'
   call set_args(' &
   & --ax " " --fy " " &
   & --vvarr "vvarrA,vvarrB,vvarrC" &
   & --ffarr "ffarrA,ffarrB,ffarrC" &
   & --vfarr "vfarrA,vfarrB,vfarrC" &
   & ')

   call get_args('ax',ax)              ! allocatable scalar
   call get_args('vvarr',vvarr)        ! allocatable array
   ! less commonly
   call get_args_fixed_length('fy',fy)       ! fixed-length scalar
   call get_args_fixed_length('vfarr',vfarr) ! fixed-length allocatable array
   call get_args_fixed_size('ffarr',ffarr)   ! fixed-size fixed-length array

   write(*,fmt)'ax=',ax, len(ax)
   write(*,fmt)'fy=',fy
   write(*,fmt)'vvarr=',vvarr
   write(*,fmt)'ffarr=',ffarr
   write(*,fmt)'vfarr=',vfarr
end program demo5
