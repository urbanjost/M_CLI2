module command_line
   use environment, only : get_os_type, OS_LINUX, OS_MACOS, OS_WINDOWS
   use M_CLI2,      only : set_args
   use,intrinsic :: iso_fortran_env, only : stdin=>input_unit, stdout=>output_unit, stderr=>error_unit

   implicit none
   private

   type, public, abstract :: fpm_cmd_settings; end type
   type, public, extends(fpm_cmd_settings)  ::  fpm_new_settings;      end  type
   type, public, extends(fpm_cmd_settings)  ::  fpm_build_settings;    end  type
   type, public, extends(fpm_cmd_settings)  ::  fpm_run_settings;      end  type
   type, public, extends(fpm_cmd_settings)  ::  fpm_test_settings;     end  type
   type, public, extends(fpm_cmd_settings)  ::  fpm_install_settings;  end  type

   public :: get_command_line_settings

   integer :: i
contains
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
    subroutine get_command_line_settings(cmd_settings)
        class(fpm_cmd_settings), allocatable, intent(out) :: cmd_settings

        character(len=100) :: cmdarg                                    ! the subcommand name
        character(len=:),allocatable :: help_text(:), version_text(:)
        version_text=[character(len=132) :: &
            &  'VERSION:     1.0.0', &
            &  'PROGRAM:     fpm(1) ', &
            &  'DESCRIPTION: A Fortran package manager and build system', &
            &  'HOME PAGE:   https://github.com/fortran-lang/fpm', &
            &  'LICENSE:     MIT', &
            &  '']
   ! assume first unnamed argument is always the subcommand keyword
   cmdarg=''
   do i=1, command_argument_count()
      call get_command_argument(1, cmdarg)
      if(adjustl(cmdarg(1:1)).ne.'-')exit
   enddo
   ! now process the subcommand
   select case(cmdarg) ! set help text and get command arguments and then call subcommand
   !============================================================================
   case('run')
    help_text=[character(len=132) :: &
     ' fpm(1) subcommand "run"          ', &
     '                                  ', &
     ' ??? NOT IMPLEMENTED              ', &
     '' ]
    call set_args('--args " " --release F ',help_text,version_text)
    allocate(fpm_run_settings :: cmd_settings)
   !============================================================================
   case('build')
    help_text=[character(len=132) :: &
     ' fpm(1) subcommand "build"         ', &
     '                                   ', &
     ' Usage: fpm [--release] build      ', &
     '' ]
    call set_args('--args " " -release F ',help_text,version_text)
    allocate(fpm_build_settings :: cmd_settings)
   !============================================================================
   case('new')
    help_text=[character(len=132) ::                           &
     ' fpm(1) subcommand "new"                              ', &
     '                                                      ', &
     ' Usage: fpm new NAME [--with-executable] [--with-test]', &
     ' Create a new project in a new directory              ', &
     '' ]
    call set_args(' --with-executable F --with-test F ',help_text,version_text)
    allocate(fpm_new_settings :: cmd_settings)
   !============================================================================
   case('install')
    help_text=[character(len=132) :: &
     ' fpm(1) subcommand "install"      ', &
     '                                  ', &
     ' ??? NOT IMPLEMENTED              ', &
     '' ]
    call set_args('--args " " -release F ',help_text,version_text)
    allocate(fpm_install_settings :: cmd_settings)
   !============================================================================
   case('test')
    help_text=[character(len=132) :: &
     ' fpm(1) subcommand "test"         ', &
     '                                  ', &
     ' ??? NOT IMPLEMENTED              ', &
     '' ]
    call set_args('--args " " -release F ',help_text,version_text)
    allocate(fpm_test_settings :: cmd_settings)
   !============================================================================
   case default
      help_text=[character(len=132) :: &
       & 'NAME', &
       & '   fpm(1) - A Fortran package manager and build system', &
       & 'OS TYPE' ]
       select case (get_os_type())
          case (OS_LINUX);   help_text=[character(len=132) :: help_text, "    Linux"   ]
          case (OS_MACOS);   help_text=[character(len=132) :: help_text, "    macOS"   ]
          case (OS_WINDOWS); help_text=[character(len=132) :: help_text, "    Windows" ]
       end select
      help_text=[character(len=132) :: help_text, &
       &  'SYNTAX', &
       &  '    fpm [COMMAND [[--release] [--args ARGS]]|[--help|--version|--usage]     ', &
       &  '                                                                            ', &
       &  'DESCRIPTION                                                                 ', &
       &  '   A package manager that helps you create Fortran projects that are        ', &
       &  '   optionally dependent on multiple files and other fpm(1) packages.        ', &
       &  '                                                                            ', &
       &  'OPTIONS                                                                     ', &
       &  '                                                                            ', &
       &  '   COMMAND  Valid fpm commands are:                                         ', &
       &  '            build             Compile the current package                   ', &
       &  '            install           Install a Fortran binary or library           ', &
       &  '            uninstall         Uninstall a Fortran binary or library         ', &
       &  '            new NAME [--with-executable] [--with-test]  Create a new        ', &
       &  '                              Fortran package                               ', &
       &  '            run [NAME]        Run a binary of the local package             ', &
       &  '            test [NAME(s)]    Run the tests (not implemented)               ', &
       &  '            search [NAME(s)]  search for registered packages                ', &
       &  '   --release                  Build in release mode (versus debug mode)     ', &
       &  '   --args ARGS                Arguments to pass to executables/tests        ', &
       &  '   --help                     Show this help text and exit                  ', &
       &  '   --version                  Show version information and exit             ', &
       &  'EXAMPLES                                                                    ', &
       &  '    fpm build                                                               ', &
       &  '    fpm new mypackage                                                       ', &
       &  '']
      call set_args('--release F --args "" ',help_text,version_text)
      ! will not get here if --version or --usage or --help is present on commandline
      write(stderr,'(*(a))')'*fpm* error: unknown or missing subcommand [',trim(cmdarg),']'
      do i=1,size(help_text)
         if(help_text(i).eq.'DESCRIPTION')exit
         write(stderr,'(g0)')trim(help_text(i))
      enddo
      stop 1
   !============================================================================
   end select
   end subroutine get_command_line_settings
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
end module command_line
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
