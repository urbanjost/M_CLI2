program demo5
!!  _CHARACTER_ type values
!! character variables have a length, unlike number variables
use M_CLI2, only : set_args, get_args
use M_CLI2, only : get_args_fixed_size, get_args_fixed_length
use M_CLI2, only : sget, sgets
implicit none

character(len=*),parameter   :: fmt='(*("[",g0,"]":,1x))'
   call set_args(' &
   & --alloc_len_scalar " " --fx_len_scalar " " &
   & --alloc_array "A,B,C" &
   & --fx_size_fx_len "A,B,C" &
   & --fx_len_alloc_array "A,B,C" &
   & ')

   block
   ! you just need get_args(3f) for general scalars or arrays
   ! variable length scalar
   character(len=:),allocatable  :: alloc_len_scalar 
   ! variable array size and variable length
   character(len=:),allocatable  :: alloc_array(:) 
   call get_args('alloc_len_scalar',        alloc_len_scalar)
   write(*,fmt)'allocatable length scalar=',alloc_len_scalar,&
   & len(alloc_len_scalar)

   call get_args('alloc_array',             alloc_array) 
   write(*,fmt)'allocatable array=        ',alloc_array
   endblock

   ! less commonly, if length or size is fixed, use a special function

   block
   character(len=19),allocatable                 :: fx_len_alloc_array(:) 
   call get_args_fixed_length('fx_len_alloc_array', fx_len_alloc_array)
   write(*,fmt)'fixed length allocatable array=',   fx_len_alloc_array
   endblock

   block
   character(len=19)                        :: fx_len_scalar   
   call get_args_fixed_length('fx_len_scalar', fx_len_scalar)
   write(*,fmt)'fixed length scalar=        ', fx_len_scalar
   endblock

   block
   character(len=19)                        :: fx_size_fx_len(3) 
   call get_args_fixed_size('fx_size_fx_len',  fx_size_fx_len) 
   write(*,fmt)'fixed size fixed length=    ', fx_size_fx_len
   endblock

   block
   ! or (recommended) set to an allocatable array and check size and
   ! length returned
   character(len=:),allocatable  :: a        ! variable length scalar
   character(len=:),allocatable  :: arr(:)   ! variable array size and variable length
   call get_args('fx_size_fx_len',arr)
   ! or
   arr=sgets('fx_size_fx_len')
   if(size(arr).ne.3)write(*,*)'not right size'
   if(len(arr).gt.19)write(*,*)'longer than wanted'

   call get_args('fx_len_scalar',a)
   !or
   a=sget('fx_len_scalar')
   if(len(a).gt.19)write(*,*)'too long'
   write(*,*)a,len(a)
   write(*,*)arr,len(arr),size(arr)

   endblock

end program demo5
