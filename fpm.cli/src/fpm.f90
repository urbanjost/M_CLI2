module fpm
use,intrinsic :: iso_fortran_env, only : stdin=>input_unit, stdout=>output_unit, stderr=>error_unit
use environment, only : get_os_type, OS_LINUX, OS_MACOS, OS_WINDOWS
use environment, only : filewrite
use M_CLI2,      only : get_args, words=>unnamed, remaining
implicit none
private
public :: cmd_build, cmd_install, cmd_new, cmd_run, cmd_test

type string_t
    character(len=:), allocatable :: s
end type

contains
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
integer function number_of_rows(s) result(nrows)
! determine number or rows
integer,intent(in)::s
integer :: ios
character(len=100) :: r
rewind(s)
nrows = 0
do
    read(s, *, iostat=ios) r
    if (ios /= 0) exit
    nrows = nrows + 1
end do
rewind(s)
end function
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine list_files(dir, files)
character(len=*), intent(in) :: dir
type(string_t), allocatable, intent(out) :: files(:)
character(len=100) :: filename
integer :: stat, u, i
! Using `inquire` / exists on directories works with gfortran, but not ifort
if (.not. exists(dir)) then
    allocate(files(0))
    return
end if
select case (get_os_type())
    case (OS_LINUX)
        call execute_command_line("ls " // dir // " > fpm_ls.out", exitstat=stat)
    case (OS_MACOS)
        call execute_command_line("ls " // dir // " > fpm_ls.out", exitstat=stat)
    case (OS_WINDOWS)
        call execute_command_line("dir /b " // dir // " > fpm_ls.out", exitstat=stat)
end select
if (stat /= 0) then
    print *, "execute_command_line() failed"
    error stop 2
end if
open(newunit=u, file="fpm_ls.out", status="old")
allocate(files(number_of_rows(u)))
do i = 1, size(files)
    read(u, *) filename
    files(i)%s = trim(filename)
end do
close(u)
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine run(cmd)
character(len=*), intent(in) :: cmd
integer :: stat
print *, "+ ", cmd
call execute_command_line(cmd, exitstat=stat)
if (stat /= 0) then
    print *, "Command failed"
    error stop 3
end if
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
logical function exists(filename) result(r)
character(len=*), intent(in) :: filename
inquire(file=filename, exist=r)
end function
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
logical function str_ends_with(s, e) result(r)
character(*), intent(in) :: s, e
integer :: n1, n2
n1 = len(s)-len(e)+1
n2 = len(s)
if (n1 < 1) then
    r = .false.
else
    r = (s(n1:n2) == e)
end if
end function
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine package_name(name)
character(:), allocatable, intent(out) :: name
! Currrently a heuristic. We should update this to read the name from fpm.toml
if (exists("src/fpm.f90")) then
    name = "fpm"
else
    name = "hello_world"
end if
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine cmd_build()
type(string_t), allocatable :: files(:)
character(:), allocatable   :: basename, pkg_name, linking
integer                     :: i, n
logical                     :: release
character(:), allocatable   :: release_name
print *, "# Building project"
call list_files("src", files)
linking = ""
do i = 1, size(files)
    if (str_ends_with(files(i)%s, ".f90")) then
        n = len(files(i)%s)
        basename = files(i)%s(1:n-4)
        call run("gfortran -c src/" // basename // ".f90 -o " // basename // ".o")
        linking = linking // " " // basename // ".o"
    end if
end do
call run("gfortran -c app/main.f90 -o main.o")
call package_name(pkg_name)
call get_args('release',release)
if(release)then
   release_name='gfortran_release'
else
   release_name='gfortran_debug'
endif
write(*,*)'???RELEASE NAME=',release_name,'RELEASE=',release
call run("gfortran main.o " // linking // " -o " // pkg_name)
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine cmd_install()
    print *, "fpm error: 'fpm install' not implemented."
    error stop 1
end subroutine
!===================================================================================================================================
subroutine cmd_new() ! --with-executable F --with-test F '
use environment, only : system_perror
use environment, only : system_mkdir, system_chdir
use environment, only : R_GRP,R_OTH,R_USR,RWX_G,RWX_O
use environment, only : RWX_U,W_GRP,W_OTH,W_USR,X_GRP,X_OTH,X_USR
integer :: ierr
character(len=:),allocatable :: dirname
character(len=:),allocatable :: writethis(:)
character(len=4096)          :: what_happened
character(len=:),allocatable :: message(:)
character(len=:),allocatable :: littlefile(:)
logical                      :: with_executable
logical                      :: with_test
    call get_args('with-executable',with_executable)
    call get_args('with-test',with_test)
    ! assume everything unclaimed are command arguments for new command
    if(size(words).ge.2.and.len(words).gt.0)then
       dirname=trim(words(2))
    else
      write(stderr,'(a)') '*fpm* error: missing directory name'
      write(stderr,'(a)') '      usage: fpm DIRECTORY_NAME --with-executable --with-test'
      stop
    endif
   if( system_mkdir(dirname, IANY([R_USR, W_USR, X_USR]) ) .ne. 0)then       ! make new directory or stop
      call system_perror('error: *fpm::system_mkdir*:')
      stop
   endif
   call system_chdir(dirname,ierr)
   if( ierr .ne. 0 )then                                                     ! change to new directory
      call system_perror('error: *fpm::system_chdir*:')
      stop
   endif
   if( system_mkdir('src', IANY([R_USR, W_USR, X_USR]) ) .ne. 0)then         ! make new directory or stop
      call system_perror('error: *fpm::system_mkdir*:')
      stop
   endif
   littlefile=[character(len=80) :: &
    &'module '//dirname, &
    &'  implicit none', &
    &'  private', &
    &'', &
    &'  public :: say_hello', &
    &'contains', &
    &'  subroutine say_hello', &
    &'    print *, "Hello, '//dirname//'!"', &
    &'  end subroutine say_hello', &
    &'end module '//dirname]
    !! hit some weird gfortran bug when littlefile data was an argument
   call filewrite('src/'//dirname//'.f90',littlefile)
   call filewrite('.gitignore',[character(len=80) :: 'build/*'])

!!   weird gfortran bug?? lines truncated to concatenated string length, not 80
!!   call filewrite('README.md',[character(len=80) :: &
!!    & '# '//dirname, &
!!    & 'My cool new project!'])

   littlefile=[character(len=80) :: '# '//dirname, 'My cool new project!']
   call filewrite('README.md',littlefile)

   message=[character(len=80) :: &                                           ! create fpm.toml
    &'name = "'//dirname//'"               ', &
    &'version = "0.1.0"                    ', &
    &'license = "license"                  ', &
    &'author = "Jane Doe"                  ', &
    &'maintainer = "jane.doe@example.com"  ', &
    &'copyright = "2020 Jane Doe"          ', &
    &'                                     ', &
    &'[library]                            ', &
    &'source-dir="src"                     ', &
    &'']

   if(with_test)then
      message=[character(len=80) ::  message,   &                               ! create next section of fpm.toml
       &'[[test]]                             ', &
       &'name="runTests"                      ', &
       &'source-dir="test"                    ', &
       &'main="main.f90"                      ', &
       &'']
      if( system_mkdir('test', IANY([R_USR, W_USR, X_USR]) ) .ne. 0)then       ! make new directory or stop
         call system_perror('error: *fpm::system_mkdir*:')
         stop
      endif
      littlefile=[character(len=80) :: &
       &'program main', &
       &'implicit none', &
       &'', &
       &'print *, "Put some tests in here!"', &
       &'end program main']
      call filewrite('test/main.f90',littlefile)
   endif

   if(with_executable)then
      message=[character(len=80) ::  message,   &                               ! create next section of fpm.toml
       &'[[executable]]                       ', &
       &'name="'//dirname//'"                 ', &
       &'source-dir="app"                     ', &
       &'main="'//dirname//'.f90"             ', &
       &'']
      if( system_mkdir('app', IANY([R_USR, W_USR, X_USR]) ) .ne. 0)then       ! make new directory or stop
         call system_perror('error: *fpm::system_mkdir*:')
         stop
      endif
      littlefile=[character(len=80) :: &
       &'program main', &
       &'  use SAMPLE, only: say_hello', &
       &'', &
       &'  implicit none', &
       &'', &
       &'  call say_hello', &
       &'end program main']
      call filewrite('app/main.f90',littlefile)
   endif

   call filewrite('fpm.toml',message)

   call run('git init')                                                      ! assumes git(1) is installed and in command path
   !!call run('git add .')
   !!call run('git commit -m "initialized repo"')
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine cmd_run()
character(len=:),allocatable :: release_name
logical                      :: release
character(len=:),allocatable :: args
integer                      :: i
    call get_args('args',args)
    args=args//remaining
    call get_args('release',release)
    release_name=trim(merge('gfortran_release','gfortran_debug  ',release))
    write(*,*)'RELEASE_NAME=',release_name,' ARGS=',args
    write(*,*)'SPECIFICALLY NAMED'
    do i=2,size(words)
       write(*,*)words(i)
    enddo
    print *, "fpm error: 'fpm run' not implemented."
    error stop 1
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine cmd_test()
character(len=:),allocatable :: release_name
logical                      :: release
character(len=:),allocatable :: args
integer                      :: i
    call get_args('args',args)
    args=args//remaining
    call get_args('release',release)
    release_name=trim(merge('gfortran_release','gfortran_debug  ',release))
    write(*,*)'RELEASE_NAME=',release_name,' ARGS=',args
    write(*,*)'SPECIFICALLY NAMED'
    do i=2,size(words)
       write(*,*)words(i)
    enddo
    print *, "fpm error: 'fpm test' not implemented."
    error stop 1
end subroutine
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
end module fpm
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
