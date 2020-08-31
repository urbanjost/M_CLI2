module environment
use,intrinsic     :: iso_c_binding,   only : c_null_char, c_int
use,intrinsic     :: iso_c_binding,   only : c_char
use,intrinsic     :: iso_fortran_env, only : int8, int16, int32, int64, real32, real64, real128
implicit none
private

integer, parameter, public :: OS_LINUX = 1
integer, parameter, public :: OS_MACOS = 2
integer, parameter, public :: OS_WINDOWS = 3

public :: get_os_type

public :: system_mkdir
public :: system_chdir
public :: system_perror
public :: R_GRP, R_OTH, R_USR, RWX_G, RWX_O, RWX_U, W_GRP, W_OTH, W_USR, X_GRP, X_OTH, X_USR

integer,parameter,public :: mode_t=int32
!integer(kind=mode_t),bind(c,name="S_IRGRP") :: R_GRP
!integer(kind=mode_t),bind(c,name="S_IROTH") :: R_OTH
!integer(kind=mode_t),bind(c,name="S_IRUSR") :: R_USR
!integer(kind=mode_t),bind(c,name="S_IRWXG") :: RWX_G
!integer(kind=mode_t),bind(c,name="S_IRWXO") :: RWX_O
!integer(kind=mode_t),bind(c,name="S_IRWXU") :: RWX_U
!integer(kind=mode_t),bind(c,name="S_IWGRP") :: W_GRP
!integer(kind=mode_t),bind(c,name="S_IWOTH") :: W_OTH
!integer(kind=mode_t),bind(c,name="S_IWUSR") :: W_USR
!integer(kind=mode_t),bind(c,name="S_IXGRP") :: X_GRP
!integer(kind=mode_t),bind(c,name="S_IXOTH") :: X_OTH
!integer(kind=mode_t),bind(c,name="S_IXUSR") :: X_USR

integer(kind=mode_t),parameter :: R_GRP=32_mode_t
integer(kind=mode_t),parameter :: R_OTH=4_mode_t
integer(kind=mode_t),parameter :: R_USR=256_mode_t
integer(kind=mode_t),parameter :: RWX_G=56_mode_t
integer(kind=mode_t),parameter :: RWX_O=7 _mode_t
integer(kind=mode_t),parameter :: RWX_U=448_mode_t
integer(kind=mode_t),parameter :: W_GRP=16_mode_t
integer(kind=mode_t),parameter :: W_OTH=2 _mode_t
integer(kind=mode_t),parameter :: W_USR=128_mode_t
integer(kind=mode_t),parameter :: X_GRP=8 _mode_t
integer(kind=mode_t),parameter :: X_OTH=1 _mode_t
integer(kind=mode_t),parameter :: X_USR=64 _mode_t

public :: filewrite
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
contains
    integer function get_os_type() result(r)
    ! Determine the OS type
    !
    ! Returns one of OS_LINUX, OS_MACOS, OS_WINDOWS.
    !
    ! Currently we use the $HOME and $HOMEPATH environment variables to determine
    ! the OS type. That is not 100% accurate in all cases, but it seems to be good
    ! enough for now. See the following issue for a more robust solution:
    !
    ! https://github.com/fortran-lang/fpm/issues/144
    !
    character(len=100) :: val
    integer stat
    ! Only Windows define $HOMEPATH by default and we test its value to improve the
    ! chances of it working even if a user defines $HOMEPATH on Linux or macOS.
    call get_environment_variable("HOMEPATH", val, status=stat)
    if (stat == 0 .and. val(1:7) == "\Users\") then
        r = OS_WINDOWS
        return
    end if

    ! We assume that $HOME=/home/... is Linux, $HOME=/Users/... is macOS, otherwise
    ! we assume Linux. This is only a heuristic and can easily fail.
    call get_environment_variable("HOME", val, status=stat)
    if (stat == 1) then
        print *, "$HOME does not exist"
        error stop
    end if
    if (stat /= 0) then
        print *, "get_environment_variable() failed"
        error stop
    end if
    if (val(1:6) == "/home/") then
        r = OS_LINUX
    else if (val(1:7) == "/Users/") then
        r = OS_MACOS
    else
        ! This will happen on HPC systems that typically do not use either /home nor
        ! /Users for $HOME. Those systems are typically Linux, so for now we simply
        ! set Linux here.
        r = OS_LINUX
    end if
    end function
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
function system_mkdir(dirname,mode) result(ierr)

! @(#) M_system::system_mkdir(3f): call mkdir(3c) to create empty directory

character(len=*),intent(in)       :: dirname
integer,intent(in)                :: mode
   integer                        :: c_mode
   integer(kind=c_int)            :: err
   integer                        :: ierr

interface
   function c_mkdir(c_path,c_mode) bind(c,name="mkdir") result(c_err)
      import c_char, c_int
      character(len=1,kind=c_char),intent(in) :: c_path(*)
      integer(c_int),intent(in),value         :: c_mode
      integer(c_int)                          :: c_err
   end function c_mkdir
end interface

   c_mode=mode
      err= c_mkdir(str2arr(trim(dirname)),c_mode)
   ierr=err                                          ! c_int to default integer kind
end function system_mkdir
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
pure function str2arr(string) result (array)

!character(len=*),parameter::ident_32="@(#)M_system::str2arr(3fp): function copies string to null terminated char array"

character(len=*),intent(in)     :: string
character(len=1,kind=c_char)    :: array(len(string)+1)
   integer                      :: i

   do i = 1,len_trim(string)
      array(i) = string(i:i)
   enddo
   array(i:i)=c_null_char

end function str2arr
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine system_chdir(path, err)

!character(len=*),parameter::ident_15="@(#)M_system::system_chdir(3f): call chdir(3c)"

character(len=*)               :: path
integer, optional, intent(out) :: err

interface
   integer(kind=c_int)  function c_chdir(c_path) bind(C,name="chdir")
      import c_char, c_int
      character(kind=c_char)   :: c_path(*)
   end function
end interface
   integer                     :: loc_err

   loc_err=c_chdir(str2arr(trim(path)))
   if(present(err))then
      err=loc_err
   endif
end subroutine system_chdir
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine system_perror(prefix)
use, intrinsic :: iso_fortran_env, only : ERROR_UNIT, INPUT_UNIT, OUTPUT_UNIT     ! access computing environment

! @(#) M_system::system_perror(3f): call perror(3c) to display error message

character(len=*),intent(in) :: prefix
   integer                  :: ios

interface
  subroutine c_perror(c_prefix) bind (C,name="perror")
  import c_char
  character(kind=c_char) :: c_prefix(*)
  end subroutine c_perror
end interface

   flush(unit=ERROR_UNIT,iostat=ios)
   flush(unit=OUTPUT_UNIT,iostat=ios)
   flush(unit=INPUT_UNIT,iostat=ios)
   call c_perror(str2arr((trim(prefix))))
   !!call c_flush()

end subroutine system_perror
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine filewrite(filename,filedata)
use,intrinsic :: iso_fortran_env, only : stdin=>input_unit, stdout=>output_unit, stderr=>error_unit
! write filedata to file filename
character(len=*),intent(in)           :: filename
character(len=*),intent(in)           :: filedata(:)
integer                               :: lun, i, ios
character(len=256)                    :: message
   message=' '
   ios=0
   if(filename.ne.' ')then
    open(file=filename, &
    & newunit=lun, &
    & form='formatted', &      !  FORM      =  FORMATTED   |  UNFORMATTED
    & access='sequential', &   !  ACCESS    =  SEQUENTIAL  |  DIRECT       |  STREAM
    & action='write', &        !  ACTION    =  READ|WRITE  |  READWRITE
    & position='rewind', &     !  POSITION  =  ASIS        |  REWIND       |  APPEND
    & status='new', &          !  STATUS    =  NEW         |  REPLACE      |  OLD     |  SCRATCH   | UNKNOWN
    & iostat=ios, &
    & iomsg=message)
   else
      lun=stdout
      ios=0
   endif
   if(ios.ne.0)then
      write(stderr,'(*(a,1x))')'*filewrite* error:',filename,trim(message)
      error stop 1
   endif
   do i=1,size(filedata)                                                    ! write file
      write(lun,'(a)',iostat=ios,iomsg=message)trim(filedata(i))
      if(ios.ne.0)then
         write(stderr,'(*(a,1x))')'*filewrite* error:',filename,trim(message)
         stop 4
      endif
   enddo
   close(unit=lun,iostat=ios,iomsg=message)                                 ! close file
   if(ios.ne.0)then
      write(stderr,'(*(a,1x))')'*filewrite* error:',trim(message)
      error stop 2
   endif
end subroutine filewrite
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
end module environment
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
