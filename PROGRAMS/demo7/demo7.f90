program demo4
use M_CLI2,  only : set_args, get_args, get_args_fixed_length, get_args_fixed_size, unnamed
implicit none

character(len=10)              :: x, y      ! fixed-length scalars
character(len=:),allocatable   :: z         ! allocatable scalars

character(len=:),allocatable   :: alloc(:)  ! allocatable array with allocatable length
character(len=20),allocatable  :: flen(:)   ! allocatable array with fixed length
character(len=4)               :: fixed(2)  ! fixed-size array wih fixed length
integer                        :: i
   ! CHARACTER VALUES
   !
   !  o if a fixed size ! array is used the size must be passed and all values must be specified
   !
   !  o default delimiters are whitespace, comma and colon. Note that whitespace delimiters should
   !    not be used in the definition, but are OK on command input if the entire parameter value
   !    is quoted. You can change the delimiters for input values.
   !  o unnamed variables are always parsed on whitespace
   call set_args('-x "A" -y "BBBBBBB" -z "C" -alloc "a,b,ccccccccccccc,d" -flen "aa,bbbbbbbbb" -fixed "one,two"')

!-interface  get_args;  module  procedure  get_scalar_anylength_c;  end  interface ! any length
   call get_args('z',z)
   call get_args('alloc',alloc)
   call get_args_fixed_length('x',x)       ! fixed length scalar
   call get_args_fixed_length('y',y)       ! fixed length scalar
   call get_args_fixed_size('flen',flen)   ! fixed length array
   call get_args_fixed_size('fixed',fixed) ! fixed length and fixed size array

   write(*,*)'x=',x
   write(*,*)'y=',y
   write(*,*)'z=',z
   write(*,'(a,*("[",a,"]":,1x))')'alloc=',alloc
   write(*,*)'flen=',flen
   write(*,'(a,*("[",a,"]":,1x))')'fixed=',fixed
   do i=1,size(unnamed)
      write(*,*)i,unnamed(i)
   enddo
end program demo4
!==================================================================================================================================
!-! return allocatable arrays
!-interface get_args; module procedure get_anyarray_d; end interface ! any size array
!-interface get_args; module procedure get_anyarray_i; end interface ! any size array
!-interface get_args; module procedure get_anyarray_r; end interface ! any size array
!-interface get_args; module procedure get_anyarray_x; end interface ! any size array
!-interface get_args; module procedure get_anyarray_c; end interface ! any size array and any length
!-interface get_args; module procedure get_anyarray_l; end interface ! any size array
!-! return scalar
!-interface get_args; module procedure get_scalar_d;       end interface
!-interface get_args; module procedure get_scalar_i;       end interface
!-interface get_args; module procedure get_scalar_real;    end interface
!-interface get_args; module procedure get_scalar_complex; end interface
!-interface get_args; module procedure get_scalar_logical; end interface
!-! return non-allocatable arrays
!-! said in conflict with get_args_*. Using class to get around that
!-! that did not work either. Adding size parameter
!-interface get_args_fixed_size; module procedure get_fixedarray_class;  end interface !any length string, fixed size array
!-!interface get_args; module procedure get_fixedarray_d; end interface
!-!interface get_args; module procedure get_fixedarray_i; end interface
!-!interface get_args; module procedure get_fixedarray_r; end interface
!-!interface get_args; module procedure get_fixedarray_l; end interface
!-!interface get_args; module procedure get_fixedarray_fixed_length_c;   end interface
!-interface get_args_fixed_length; module procedure get_fixed_length_any_size_cxxxx; end interface ! fixed length any size array
!-!interface get_args_fixed_length; module procedure get_scalar_fixed_length_c;  end interface  ! fixed length and size array
