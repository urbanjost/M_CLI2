!VERSION 1.0 20200115
!VERSION 2.0 20200802
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!     M_CLI2(3fm) - [ARGUMENTS::M_CLI2] - command line argument parsing using a prototype command
!!     (LICENSE:PD)
!!##SYNOPSIS
!!
!!
!!     use M_CLI2, only : set_args, get_args, unnamed ! argument type conversion
!!
!!##DESCRIPTION
!!     Allow for command line parsing much like standard Unix command line
!!     parsing using a simple prototype.
!!
!!     In this method a call is made to obtain the value for each argument.
!!
!!##EXAMPLE
!!
!!
!! Sample program using type conversion routines
!!
!!     program demo_M_CLI2
!!     use M_CLI2,  only : filenames=>unnamed, set_args, get_args
!!     implicit none
!!     integer                      :: i
!!     integer,parameter            :: dp=kind(0.0d0)
!!     !
!!     ! DEFINE ARGS
!!     real                         :: x, y, z
!!     real                         :: p(3)
!!     real(kind=dp),allocatable    :: point(:)
!!     character(len=:),allocatable :: title
!!     character(len=40)            :: label
!!     logical                      :: l, lbig
!!     logical,allocatable          :: logicals(:)
!!     logical                      :: logi(3)
!!     !
!!     ! DEFINE AND PARSE (TO SET INITIAL VALUES) COMMAND LINE
!!     !   o only quote strings
!!     !   o set all logical values to F or T.
!!     call set_args('                         &
!!             & -x 1 -y 2 -z 3                &
!!             & -p -1 -2 -3                   &
!!             & --point 11.11, 22.22, 33.33e0 &
!!             & --title "my title" -l F -L F  &
!!             & --logicals  F F F F F         &
!!             & -logi F T F                   &
!!             ! note space between quotes is required
!!             & --label " " &
!!             & ')
!!     ! ASSIGN VALUES TO ELEMENTS
!!     call get_args('x',x)         ! SCALARS
!!     call get_args('y',y)
!!     call get_args('z',z)
!!     call get_args('l',l)
!!     call get_args('L',lbig)
!!     call get_args('title',title) ! ALLOCATABLE STRING
!!     call get_args('point',point) ! ALLOCATABLE ARRAYS
!!     call get_args('logicals',logicals)
!!     !
!!     ! for NON-ALLOCATABLE VARIABLES
!!     call get_args('label',label,len(label)) ! for non-allocatable string pass length
!!     call get_args('p',p,size(p))            ! for non-allocatable arrays pass size
!!     call get_args('logi',logi,size(logi))
!!     !
!!     ! USE VALUES
!!     write(*,*)'x=',x, 'y=',y, 'z=',z, x+y+z
!!     write(*,*)'p=',p
!!     write(*,*)'point=',point
!!     write(*,*)'title=',title
!!     write(*,*)'label=',label
!!     write(*,*)'l=',l
!!     write(*,*)'L=',lbig
!!     write(*,*)'logicals=',logicals
!!     write(*,*)'logi=',logi
!!     !
!!     ! unnamed strings
!!     !
!!     if(size(filenames).gt.0)then
!!        write(*,'(i6.6,3a)')(i,'[',filenames(i),']',i=1,size(filenames))
!!     endif
!!     !
!!     end program demo_M_CLI2
!!
!!##AUTHOR
!!     John S. Urban, 2019
!!##LICENSE
!!     Public Domain
!===================================================================================================================================
module M_CLI2
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT,stdin=>INPUT_UNIT    ! access computing environment
!use M_strings,                     only : isupper, upper, lower, quote, replace_str=>replace, unquote, split, string_to_value
!use M_list,                        only : insert, locate, remove, replace
!use M_args,                        only : longest_command_argument
!use M_journal,                     only : journal
implicit none
integer,parameter,private :: dp=kind(0.0d0)
private
!===================================================================================================================================
private                             :: commandline
private                             :: check_commandline
character(len=:),allocatable,public :: unnamed(:)
public                              :: set_args
public                              :: get_args

private :: wipe_dictionary
private :: prototype_to_dictionary
private :: update
private :: prototype_and_cmd_args_to_nlist
private :: get

type option
   character(:),allocatable :: shortname
   character(:),allocatable :: longname
   character(:),allocatable :: value
   integer                  :: length
   logical                  :: present_in
end type option
!===================================================================================================================================
character(len=:),allocatable   :: keywords(:)
character(len=:),allocatable   :: values(:)
integer,allocatable            :: counts(:)
logical,allocatable            :: present_in(:)

logical                        :: keyword_single=.true.
character(len=:),allocatable   :: passed_in
character(len=:),allocatable   :: namelist_name

logical                        :: return_all
!===================================================================================================================================
private dictionary

type dictionary
   character(len=:),allocatable :: key(:)
   character(len=:),allocatable :: value(:)
   integer,allocatable          :: count(:)
   contains
      procedure,private :: get => dict_get
      procedure,private :: set => dict_add    ! insert entry by name into a sorted allocatable character array if it is not present
      procedure,private :: del => dict_delete ! delete entry by name from a sorted allocatable character array if it is present
end type dictionary
!==================================================================================================================================
! return allocatable arrays
interface  get_args;  module  procedure  get_args_d;  end interface
interface  get_args;  module  procedure  get_args_i;  end interface
interface  get_args;  module  procedure  get_args_r;  end interface
interface  get_args;  module  procedure  get_args_c;  end interface
interface  get_args;  module  procedure  get_args_l;  end interface
! return scalars
interface  get_args;  module  procedure  get_arg_d;   end interface
interface  get_args;  module  procedure  get_arg_i;   end interface
interface  get_args;  module  procedure  get_arg_r;   end interface
interface  get_args;  module  procedure  get_arg_c;   end interface
interface  get_args;  module  procedure  get_arg_cx;  end interface
interface  get_args;  module  procedure  get_arg_l;   end interface
! return non-allocatable arrays
! said in conflict with get_args_*. Using class to get around that
interface   get_args;  module  procedure  get_args_class;  end interface
! that did not work either. Adding size parameter
!interface   get_args;  module  procedure  get_args_dd;   end interface
!interface   get_args;  module  procedure  get_args_ii;   end interface
!interface   get_args;  module  procedure  get_args_rr;   end interface
!interface   get_args;  module  procedure  get_args_cc;   end interface
!interface   get_args;  module  procedure  get_args_ll;   end interface
!===================================================================================================================================
! ident_1="@(#)M_msg::str(3f): {msg_scalar,msg_one}"

private str
interface str
   module procedure msg_scalar, msg_one
end interface str
!-----------------------------------------------------------------------------------------------------------------------------------

! ident_2="@(#)M_strings::string_to_value(3f): Generic subroutine converts numeric string to a number (a2d,a2r,a2i)"

interface string_to_value
   module procedure a2d, a2i
end interface
!-----------------------------------------------------------------------------------------------------------------------------------

! ident_3="@(#)M_strings::v2s(3f): Generic function returns string given REAL|INTEGER|DOUBLEPRECISION value(r2s,i2s)"

interface v2s
   module procedure i2s
end interface
!===================================================================================================================================

public locate        ! [M_list] find PLACE in sorted character array where value can be found or should be placed
   private locate_c
   private locate_d
   private locate_r
   private locate_i
public insert        ! [M_list] insert entry into a sorted allocatable array at specified position
   private insert_c
   private insert_d
   private insert_r
   private insert_i
   private insert_l
public replace       ! [M_list] replace entry by index from a sorted allocatable array if it is present
   private replace_c
   private replace_d
   private replace_r
   private replace_i
   private replace_l
public remove        ! [M_list] delete entry by index from a sorted allocatable array if it is present
   private remove_c
   private remove_d
   private remove_r
   private remove_i
   private remove_l

! ident_4="@(#)M_list::locate(3f): Generic subroutine locates where element is or should be in sorted allocatable array"
interface locate
   module procedure locate_c, locate_d, locate_r, locate_i
end interface

! ident_5="@(#)M_list::insert(3f): Generic subroutine inserts element into allocatable array at specified position"
interface insert
   module procedure insert_c, insert_d, insert_r, insert_i, insert_l
end interface

! ident_6="@(#)M_list::replace(3f): Generic subroutine replaces element from allocatable array at specified position"
interface replace
   module procedure replace_c, replace_d, replace_r, replace_i, replace_l
end interface

! ident_7="@(#)M_list::remove(3f): Generic subroutine deletes element from allocatable array at specified position"
interface remove
   module procedure remove_c, remove_d, remove_r, remove_i, remove_l
end interface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!     check_commandline(3f) - [ARGUMENTS:M_CLI2]check status from READ of NAMELIST group and process pre-defined options
!!
!!##SYNOPSIS
!!
!!
!!      subroutine check_commandline(ios,message,help_text,version_text)
!!
!!       integer,intent(in) :: ios
!!       character(len=*),intent(in) :: message
!!       character(len=:),allocatable,intent(in),allocatable,optional :: help_text(:)
!!       character(len=:),allocatable,intent(in),allocatable,optional :: version_text(:)
!!
!!##DESCRIPTION
!!     Checks the status of a READ(7f) of the NAMELIST after calling
!!     commandline(3f) and processes the implicit --help, --version,
!!     and --usage parameters.
!!
!!     If the optional text values are supplied they will be displayed by
!!     --help and --version command-line options, respectively.
!!
!!##OPTIONS
!!
!!     IOS           status from READ(7f) of NAMELIST after calling
!!                   commandline(3f)
!!
!!     MESSAGE       message from READ(7f) of NAMELIST after calling
!!                   commandline(3f)
!!
!!     HELP_TEXT     if present, will be displayed if program is called with
!!                   --help switch, and then the program will terminate. If
!!                   not supplied, the command line initialized string will be
!!                   shown when --help is used on the commandline.
!!
!!     VERSION_TEXT  if present, will be displayed if program is called with
!!                   --version switch, and then the program will terminate.
!!
!!        If the first four characters of each line are "@(#)" this prefix will
!!        not be displayed. This if for support of the SCCS what(1) command. If
!!        you do not have the what(1) command on GNU/Linux and Unix platforms
!!        you can probably see how it can be used to place metadata in a binary
!!        by entering:
!!
!!            strings demo_commandline|grep '@(#)'|tr '>' '\n'|sed -e 's/  */ /g'
!!
!!##EXAMPLE
!!
!!
!! Typical usage:
!!
!!      program demo_commandline
!!      use M_CLI2,  only : unnamed, commandline, check_commandline
!!      implicit none
!!      integer                      :: i
!!      character(len=255)           :: message ! use for I/O error messages
!!      character(len=:),allocatable :: readme  ! stores updated namelist
!!      character(len=:),allocatable :: version_text(:), help_text(:)
!!      integer                      :: ios
!!
!!      real               :: x, y, z
!!      logical            :: help, h
!!      equivalence       (help,h)
!!      namelist /args/ x,y,z,help,h
!!      character(len=*),parameter :: cmd='-x 1 -y 2 -z 3 --help F -h F'
!!
!!      ! initialize namelist from string and then update from command line
!!      readme=commandline(cmd)
!!      write (*,*)'README=',readme
!!      read(readme,nml=args,iostat=ios,iomsg=message)
!!      version_text=[character(len=80) :: "version 1.0","author: me"]
!!      help_text=[character(len=80) :: "wish I put instructions","here","I suppose?"]
!!      call check_commandline(ios,message,help_text,version_text)
!!
!!      ! all done cracking the command line
!!      ! use the values in your program.
!!      write (*,nml=args)
!!      ! the optional unnamed values on the command line are
!!      ! accumulated in the character array "UNNAMED"
!!      if(size(unnamed).gt.0)then
!!         write (*,'(a)')'files:'
!!         write (*,'(i6.6,3a)') (i,'[',unnamed(i),']',i=1,size(unnamed))
!!      endif
!!      end program demo_commandline
!===================================================================================================================================
subroutine check_commandline(ios,message,help_text,version_text)
integer                                          :: ios
character(len=*)                                 :: message ! use for I/O error messages
character(len=:),allocatable,intent(in),optional :: help_text(:)
character(len=:),allocatable,intent(in),optional :: version_text(:)
integer                                          :: i
integer                                          :: istart
integer                                          :: iback
   if(ios.ne.0)then
         call journal('sc',"ERROR IN COMMAND LINE VALUES:",ios,message)
      call print_dictionary('OPTIONS:')
      stop 1
   elseif(get('usage').eq.'T')then
      call print_dictionary('USAGE:',stop=.true.)
   endif
   if(present(help_text))then
      if(get('help').eq.'T')then
         do i=1,size(help_text)
            call journal('sc',help_text(i))
         enddo
         stop
      endif
   elseif(get('help').eq.'T')then
         DEFAULT_HELP: block
            character(len=:),allocatable :: cmd_name
            integer :: ilength
            call get_command_argument(number=0,length=ilength)
            allocate(character(len=ilength) :: cmd_name)
            call get_command_argument(number=0,value=cmd_name)
            passed_in=passed_in//repeat(' ',len(passed_in))
            call substitute(passed_in,' --',NEW_LINE('A')//' --')
            call journal('sc',cmd_name,passed_in) ! no help text, echo command and default options
            deallocate(cmd_name)
            stop
         endblock DEFAULT_HELP
   endif
   if(present(version_text))then
      if(get('version').eq.'T')then
         istart=1
         iback=0
         if(size(version_text).gt.0)then
            if(index(version_text(1),'@'//'(#)').eq.1)then ! allow for what(1) syntax
               istart=5
               iback=1
            endif
         endif
         do i=1,size(version_text)
            call journal('sc',version_text(i)(istart:len_trim(version_text(i))-iback))
         enddo
         stop
      endif
   elseif(get('version').eq.'T')then
         call journal('sc','*check_commandline* no version text')
         stop
   endif
end subroutine check_commandline
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!     commandline(3f) - [ARGUMENTS:M_CLI2] command line argument parsing
!!     (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!
!!
!!     function commandline(definition) result(string)
!!
!!      character(len=*),intent(in),optional  :: definition
!!      character(len=:),allocatable :: string
!!##DESCRIPTION
!!
!!     To use the routine first define a NAMELIST group called ARGS.
!!
!!     This routine leverages NAMELIST groups to do the conversion from
!!     strings to numeric values required by other command line parsers.
!!
!!     The example program shows how simple it is to use. Add a variable to
!!     the NAMELIST and the prototype and it automatically is available as
!!     a value in the program.
!!
!!     There is no need to convert from strings to numeric values in the
!!     source code. Even arrays and user-defined types can be used, complex
!!     values can be input ... just define the variable in the prototype
!!     and add it to the NAMELIST definition.
!!
!!     Note that since all the arguments are defined in a NAMELIST group that
!!     config files can easily be used for the same options. Just create
!!     a NAMELIST input file and read it.
!!
!!     NAMELIST syntax can vary between different programming environments.
!!     Currently, this routine has only been tested using gfortran 7.0.4;
!!     and requires at least Fortran 2003.
!!
!!     For example:
!!
!!         program show_commandline_unix_prototype
!!            use M_CLI2,  only : unnamed, commandline, check_commandline
!!            implicit none
!!            integer                      :: i
!!            character(len=255)           :: message ! for I/O error messages
!!            character(len=:),allocatable :: readme  ! stores updated namelist
!!            integer                      :: ios
!!
!!         ! declare a namelist
!!            real               :: x, y, z, point(3), p(3)
!!            character(len=80)  :: title
!!            logical            :: l, l_
!!            equivalence       (point,p)
!!            namelist /args/ x,y,z,point,p,title,l,l_
!!
!!         ! Define the prototype
!!         !  o All parameters must be listed with a default value.
!!         !  o logicals should be specified with a value of F or T.
!!         !  o string values  must be double-quoted.
!!         !  o lists must be comma-delimited. No spaces are allowed in lists.
!!         !  o all long names must be lowercase. An uppercase short name
!!         !    -A maps to variable A_
!!         !  o if variables are equivalenced only one should be used on
!!         !    the command line
!!            character(len=*),parameter  :: cmd='&
!!            & -x 1 -y 2 -z 3     &
!!            & --point -1,-2,-3   &
!!            & --title "my title" &
!!            & -l F -L F'
!!            ! reading in a NAMELIST definition defining the entire NAMELIST
!!            ! now get the values from the command prototype and command line as NAMELIST input
!!            readme=commandline(cmd)
!!            read(readme,nml=args,iostat=ios,iomsg=message)
!!            call check_commandline(ios,message)
!!            ! all done cracking the command line
!!
!!            ! use the values in your program.
!!            write (*,nml=args)
!!            ! the optional unnamed values on the command line are
!!            ! accumulated in the character array "UNNAMED"
!!            if(size(unnamed).gt.0)then
!!               write (*,'(a)')'files:'
!!               write (*,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
!!            endif
!!         end program show_commandline_unix_prototype
!!
!!##OPTIONS
!!
!!      DESCRIPTION   composed of all command arguments concatenated
!!                    into a Unix-like command prototype string.
!!
!!                    o all keywords get a value.
!!                    o logicals must be set to F or T.
!!                    o strings MUST be delimited with double-quotes and
!!                      must be at least one space. Internal
!!                      double-quotes are represented with two double-quotes
!!                    o lists of values should be comma-delimited.
!!                    o long names (--keyword) should be all lowercase
!!                    o short names (-letter) that are uppercase map to a
!!                      NAMELIST variable called "letter_", but lowercase
!!                      short names map to NAMELIST name "letter".
!!                    o the values follow the rules for NAMELIST values, so
!!                      "-p 2*0" for example would define two values.
!!
!!                    DESCRIPTION is pre-defined to act as if started with the reserved
!!                    options '--usage F --help F --version F'. The --usage
!!                    option is processed when the check_commandline(3f)
!!                    routine is called. The same is true for --help and --version
!!                    if the optional help_text and version_text options are
!!                    provided.
!!##RETURNS
!!
!!      STRING   The output is a NAMELIST string than can be read to update
!!               the NAMELIST "ARGS" with the keywords that were supplied on
!!               the command line.
!!
!!      When using one of the Unix-like command line forms note that
!!      (subject to change) the following variations from other common
!!      command-line parsers:
!!
!!         o long names do not take the --KEY=VALUE form, just
!!           --KEY VALUE; and long names should be all lowercase and
!!           always more than one character.
!!
!!         o duplicate keyword values are appended together with a space
!!           separator.
!!
!!         o numeric keywords are not allowed; but this allows
!!           negative numbers to be used as values.
!!
!!         o mapping of short names to long names is via an EQUIVALENCE.
!!           specifying both names of an equivalenced keyword will have
!!           undefined results (currently, their alphabetical order
!!           will define what the Fortran variable values become).
!!
!!         o short keywords cannot be combined. -a -b -c is required,
!!           not -abc even for Boolean keys.
!!
!!         o shuffling is not supported. Values must follow their
!!           keywords.
!!
!!         o if a parameter value of just "-" is supplied it is
!!           converted to the string "stdin".
!!
!!         o if the keyword "--" is encountered the rest of the
!!           command arguments go into the character array "UNUSED".
!!
!!         o values not matching a keyword go into the character
!!           array "UNUSED".
!!
!!         o short-name parameters of the form -LETTER VALUE
!!           map to a NAMELIST name of LETTER_ if uppercase
!!
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
function commandline(definition) result (readme)

! ident_8="@(#)M_CLI2::commandline(3f): return all command arguments as a NAMELIST(3f) string to read"

character(len=*),intent(in)          :: definition
character(len=:),allocatable         :: hold               ! stores command line argument
character(len=:),allocatable         :: readme             ! stores command line argument
integer                              :: ibig

   passed_in=''
   if(allocated(unnamed))then
       deallocate(unnamed)
   endif
   ibig=longest_command_argument() ! bug in gfortran. len=0 should be fine
   allocate(character(len=ibig) :: unnamed(0))

   call wipe_dictionary()
   hold='--usage F --help F --version F '//adjustl(definition)
   call prototype_and_cmd_args_to_nlist(hold,readme)

   if(.not.allocated(unnamed))then
       allocate(character(len=0) :: unnamed(0))
   endif


end function commandline
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine set_args(prototype,help_text,version_text)
character(len=*),intent(in)                      :: prototype
character(len=:),intent(in),allocatable,optional :: help_text(:)
character(len=:),intent(in),allocatable,optional :: version_text(:)
character(len=:),allocatable                     :: readme
character(len=255)                               :: message
   readme=commandline(prototype)
   call check_commandline(0,message,help_text,version_text) ! process --help, --version, --usage
end subroutine set_args
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      prototype_to_dictionary(3f) - [ARGUMENTS:M_CLI2] parse user command and store tokens into dictionary
!!      (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!
!!     subroutine prototype_to_dictionary(string)
!!
!!      character(len=*),intent(in)     ::  string
!!
!!##DESCRIPTION
!!      given a string of form
!!
!!        -var value -var value
!!
!!      define dictionary of form
!!
!!        keyword(i), value(i)
!!
!!      o  string values
!!
!!          o must be delimited with double quotes.
!!          o adjacent double quotes put one double quote into value
!!          o must not be null. A blank is specified as " ", not "".
!!
!!      o  logical values
!!
!!          o logical values must not have a value
!!
!!      o  leading and trailing blanks are removed from unquoted values
!!
!!
!!##OPTIONS
!!      STRING   string is character input string to define command
!!
!!##RETURNS
!!
!!##EXAMPLE
!!
!! sample program:
!!
!!     Results:
!!
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine prototype_to_dictionary(string)
implicit none

! ident_9="@(#)M_CLI2::prototype_to_dictionary(3f): parse user command and store tokens into dictionary"

character(len=*),intent(in)       :: string ! string is character input string of options and values

character(len=:),allocatable      :: dummy   ! working copy of string
character(len=:),allocatable      :: value
character(len=:),allocatable      :: keyword
character(len=3)                  :: delmt   ! flag if in a delimited string or not
character(len=1)                  :: currnt  ! current character being processed
character(len=1)                  :: prev    ! character to left of CURRNT
character(len=1)                  :: forwrd  ! character to right of CURRNT
integer,dimension(2)              :: ipnt
integer                           :: islen   ! number of characters in input string
integer                           :: ipoint
integer                           :: itype
integer                           :: ifwd
integer                           :: ibegin
integer                           :: iend

   islen=len_trim(string)                               ! find number of characters in input string
   if(islen  ==  0)then                                 ! if input string is blank, even default variable will not be changed
      return
   endif
   dummy=string//'  '

   keyword=""          ! initial variable name
   value=""            ! initial value of a string
   ipoint=0            ! ipoint is the current character pointer for (dummy)
   ipnt(2)=2           ! pointer to position in parameter name
   ipnt(1)=1           ! pointer to position in parameter value
   itype=1             ! itype=1 for value, itype=2 for variable

   delmt="off"
   prev=" "

   keyword_single=.true.
   do
      ipoint=ipoint+1               ! move current character pointer forward
      currnt=dummy(ipoint:ipoint)   ! store current character into currnt
      ifwd=min(ipoint+1,islen)
      forwrd=dummy(ifwd:ifwd)       ! next character (or duplicate if last)

      if((currnt=="-".and.prev==" ".and.delmt == "off".and.index("0123456789.",forwrd) == 0).or.ipoint > islen)then
         ! beginning of a parameter name
         if(forwrd.eq.'-')then                      ! change --var to -var so "long" syntax is supported
            dummy(ifwd:ifwd)='_'
            ipoint=ipoint+1                         ! ignore second - instead
            keyword_single=.false.
         else
            keyword_single=.true.
         endif
         if(ipnt(1)-1 >= 1)then
            ibegin=1
            iend=len_trim(value(:ipnt(1)-1))
            do
               if(iend  ==  0)then                  ! len_trim returned 0, parameter value is blank
                  iend=ibegin
                  exit
               elseif(value(ibegin:ibegin) == " ")then
                  ibegin=ibegin+1
               else
                  exit
               endif
            enddo
            if(keyword.ne.' ')then
               call update(keyword,value)         ! store name and its value
            else
               write(stderr,*)'*prototype_to_dictionary* warning: ignoring blank keyword ',trim(value)
            endif
         else
            if(keyword.ne.' ')then
               call update(keyword,'F')           ! store name and null value
            else
            endif
         endif
         itype=2                               ! change to filling a variable name
         value=""                              ! clear value for this variable
         keyword=""                            ! clear variable name
         ipnt(1)=1                             ! restart variable value
         ipnt(2)=1                             ! restart variable name

      else       ! currnt is not one of the special characters
         ! the space after a keyword before the value
         if(currnt == " ".and.itype  ==  2)then
            ! switch from building a keyword string to building a value string
            itype=1
            ! beginning of a delimited parameter value
         elseif(currnt  ==  """".and.itype  ==  1)then
            ! second of a double quote, put quote in
            if(prev  ==  """")then
               if(itype.eq.1)then
                  value=value//currnt
               else
                  keyword=keyword//currnt
               endif
               ipnt(itype)=ipnt(itype)+1
               delmt="on"
            elseif(delmt  ==  "on")then     ! first quote of a delimited string
               delmt="off"
            else
               delmt="on"
            endif
            if(prev /= """")then  ! leave quotes where found them
               if(itype.eq.1)then
                  value=value//currnt
               else
                  keyword=keyword//currnt
               endif
               ipnt(itype)=ipnt(itype)+1
            endif
         else     ! add character to current parameter name or parameter value
            if(itype.eq.1)then
               value=value//currnt
            else
               keyword=keyword//currnt
            endif
            ipnt(itype)=ipnt(itype)+1
         endif

      endif

      prev=currnt
      if(ipoint <= islen)then
         cycle
      endif
      exit
   enddo

end subroutine prototype_to_dictionary
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      update(3f) - [ARGUMENTS:M_CLI2] update internal dictionary given keyword and value
!!      (LICENSE:PD)
!!##SYNOPSIS
!!
!!
!!
!!     subroutine update(key,val)
!!
!!      character(len=*),intent(in)           :: key
!!      character(len=*),intent(in),optional  :: val
!!##DESCRIPTION
!!      Update internal dictionary in M_CLI2(3fm) module.
!!##OPTIONS
!!      key  name of keyword to add, replace, or delete from dictionary
!!      val  if present add or replace value associated with keyword. If not
!!           present remove keyword entry from dictionary.
!!
!!           If "present" is true, a value will be appended
!!##EXAMPLE
!!
!!
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine update(key,val)
character(len=*),intent(in)           :: key
character(len=*),intent(in),optional  :: val
integer                               :: place
integer                               :: ilen
character(len=:),allocatable          :: val_local
   if(present(val))then
      val_local=val
      ilen=len_trim(val_local)
      call locate(keywords,key,place)                   ! find where string is or should be
      if(place.lt.1)then                                ! if string was not found insert it
         call insert(keywords,key,iabs(place))
         call insert(values,val_local,iabs(place))
         call insert(counts,ilen,iabs(place))
         call insert(present_in,.true.,iabs(place))
      else
         if(present_in(place))then                      ! if multiple keywords append values with space between them
            if(values(place)(1:1).eq.'"')then
            ! UNDESIRABLE: will ignore previous blank entries
               val_local='"'//trim(unquote(values(place)))//' '//trim(unquote(val_local))//'"'
            else
               val_local=values(place)//' '//val_local
            endif
            ilen=len_trim(val_local)
         endif
         call replace(values,val_local,place)
         call replace(counts,ilen,place)
         call replace(present_in,.true.,place)
      endif
   else                                                 ! if no value is present remove the keyword and related values
      call locate(keywords,key,place)
      if(place.gt.0)then
         call remove(keywords,place)
         call remove(values,place)
         call remove(counts,place)
         call remove(present_in,place)
      endif
   endif
end subroutine update
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      wipe_dictionary(3fp) - [ARGUMENTS:M_CLI2] reset private M_CLI2(3fm) dictionary to empty
!!      (LICENSE:PD)
!!##SYNOPSIS
!!
!!
!!      subroutine wipe_dictionary()
!!##DESCRIPTION
!!      reset private M_CLI2(3fm) dictionary to empty
!!##EXAMPLE
!!
!! Sample program:
!!
!!      program demo_wipe_dictionary
!!      use M_CLI2, only : dictionary
!!         call wipe_dictionary()
!!      end program demo_wipe_dictionary
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine wipe_dictionary()
   if(allocated(keywords))deallocate(keywords)
   allocate(character(len=0) :: keywords(0))
   if(allocated(values))deallocate(values)
   allocate(character(len=0) :: values(0))
   if(allocated(counts))deallocate(counts)
   allocate(counts(0))
   if(allocated(present_in))deallocate(present_in)
   allocate(present_in(0))
end subroutine wipe_dictionary
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      get(3f) - [ARGUMENTS:M_CLI2] get dictionary value associated with key name in private M_CLI2(3fm) dictionary
!!##SYNOPSIS
!!
!!
!!##DESCRIPTION
!!      Get dictionary value associated with key name in private M_CLI2(3fm) dictionary.
!!##OPTIONS
!!##RETURNS
!!##EXAMPLE
!!
!===================================================================================================================================
function get(key) result(valout)
character(len=*),intent(in)   :: key
character(len=:),allocatable  :: valout
integer                       :: place
   ! find where string is or should be
   call locate(keywords,key,place)
   if(place.lt.1)then
      valout=''
   else
      valout=values(place)(:counts(place))
   endif
end function get
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      prototype_and_cmd_args_to_nlist(3f) - [ARGUMENTS:M_CLI2] convert Unix-like command arguments to namelist
!!      (LICENSE:PD)
!!##SYNOPSIS
!!
!!
!!
!!     subroutine prototype_and_cmd_args_to_nlist(prototype,nml)
!!
!!      character(len=*)             :: prototype
!!      character(len=:),allocatable :: nml
!!##DESCRIPTION
!!      create dictionary with character keywords, values, and value lengths using the routines for maintaining a list from
!!      command line arguments.
!!##OPTIONS
!!      prototype
!!##RETURNS
!!      nml
!!##EXAMPLE
!!
!!
!! Sample program
!!
!!      program demo_prototype_and_cmd_args_to_nlist
!!      use M_CLI2,  only : prototype_and_cmd_args_to_nlist, unnamed
!!      implicit none
!!      character(len=:),allocatable :: readme
!!      character(len=256)           :: message
!!      integer                      :: ios
!!      integer                      :: i
!!      doubleprecision              :: something
!!
!!      ! define namelist
!!      ! lowercase keywords
!!      logical            :: l,h,v
!!      real               :: p(2)
!!      complex            :: c
!!      doubleprecision    :: x,y,z
!!
!!      ! uppercase keywords get an underscore
!!      logical            :: l_,h_,v_
!!      character(len=256) :: a_,b_                  ! character variables must be long enough to hold returned value
!!      integer            :: c_(3)
!!      namelist /args/ l,h,v,p,c,x,y,z,a_,b_,c_,l_,h_,v_
!!
!!         ! give command template with default values
!!         ! all values except logicals get a value.
!!         ! strings must be delimited with double quotes
!!         ! A string has to have at least one character as for -A
!!         ! lists of numbers should be comma-delimited. No spaces are allowed in lists of numbers
!!         ! the values follow the rules for NAMELIST input, so  -p 2*0 would define two values.
!!         call prototype_and_cmd_args_to_nlist('&
!!         & -l -v -h -LVH -x 0 -y 0.0 -z 0.0d0 -p 0,0 &
!!         & -A " " -B "Value B" -C 10,20,30 -c (-123,-456)',readme)
!!         read(readme,nml=args,iostat=ios,iomsg=message)
!!         if(ios.ne.0)then
!!            write (*,*)'ERROR:',trim(message)
!!            write (*,'("INPUT WAS ",a)')readme
!!            write (*,args)
!!            stop 3
!!         else
!!            something=sqrt(x**2+y**2+z**2)
!!            write (*,*)something,x,y,z
!!            if(size(unnamed).gt.0)then
!!               write (*,'(a)')'files:'
!!               write (*,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
!!            endif
!!         endif
!!      end program demo_prototype_and_cmd_args_to_nlist
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine prototype_and_cmd_args_to_nlist(prototype,nml)
implicit none

! ident_10="@(#)M_CLI2::prototype_and_cmd_args_to_nlist: create dictionary from prototype (if not null) and update from command line arguments"

character(len=*),intent(in)              :: prototype
character(len=:),intent(out),allocatable :: nml
character(len=:),allocatable :: nml1
character(len=:),allocatable :: nml2
integer                      :: ibig

   passed_in=prototype ! make global copy for printing

   if(allocated(unnamed))deallocate(unnamed)
   ibig=longest_command_argument() ! bug in gfortran. len=0 should be fine
   ibig=max(ibig,1)
   allocate(character(len=ibig) ::unnamed(0))

   if(prototype.ne.'')then
      call prototype_to_dictionary(prototype)  ! build dictionary from prototype
      namelist_name='&ARGS'
      present_in=.false.  ! reset all values to false so everything gets written
      return_all=.true.   ! return everything in dictionary
      call dictionary_to_namelist(nml1)
      present_in=.false.  ! reset all values to false
   else
      nml1=''
   endif

   return_all=.false.   ! return values that were on command line
   call cmd_args_to_dictionary(check=.true.)

   call dictionary_to_namelist(nml2)

   nml=namelist_name//' '//nml1//','//nml2//' /' ! add defaults and values on command line
   ! show array

end subroutine prototype_and_cmd_args_to_nlist
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine cmd_args_to_dictionary(check)
! convert command line arguments to dictionary entries
! reading the namelist output will trap unknown option names so do not really need to trap them here
logical,intent(in),optional  :: check
logical                      :: check_local
integer                      :: pointer
character(len=:),allocatable :: lastkeyword
integer                      :: i
integer                      :: ilength, istatus, imax
character(len=:),allocatable :: current_argument
character(len=:),allocatable :: current_argument_padded
character(len=:),allocatable :: dummy
character(len=:),allocatable :: oldvalue
logical                      :: nomore
   if(present(check))then
      check_local=check
   else
      check_local=.false.
   endif
   nomore=.false.
   pointer=0
   lastkeyword=' '
   keyword_single=.true.
   GET_ARGS: do i=1, command_argument_count()                                                        ! insert and replace entries
      call get_command_argument(number=i,length=ilength,status=istatus)                              ! get next argument
      if(istatus /= 0) then                                                                          ! stop program on error
         write(stderr,*)'*prototype_and_cmd_args_to_nlist* error obtaining argument ',i,&
            &'status=',istatus,&
            &'length=',ilength
         exit GET_ARGS
      else
         if(allocated(current_argument))deallocate(current_argument)
         ilength=max(ilength,1)
         allocate(character(len=ilength) :: current_argument)
         call get_command_argument(number=i,value=current_argument,length=ilength,status=istatus)    ! get next argument
         if(istatus /= 0) then                                                                       ! stop program on error
            write(stderr,*)'*prototype_and_cmd_args_to_nlist* error obtaining argument ',i,&
               &'status=',istatus,&
               &'length=',ilength,&
               &'target length=',len(current_argument)
            exit GET_ARGS
          endif
      endif

      if(current_argument.eq.'-')then  ! sort of
         current_argument='"stdin"'
      endif
      if(current_argument.eq.'--')then ! everything after this goes into the unnamed array
         nomore=.true.
         pointer=0
         cycle
      endif
      dummy=current_argument//'   '
      current_argument_padded=current_argument//'   '
      if(.not.nomore.and.current_argument_padded(1:2).eq.'--'.and.index("0123456789.",dummy(3:3)).eq.0)then ! beginning of long word
         keyword_single=.false.
         if(lastkeyword.ne.'')then
            call ifnull()
         endif
         call locate(keywords,current_argument_padded(3:),pointer)
         if(pointer.le.0.and.check_local)then
            call print_dictionary('UNKNOWN LONG KEYWORD: '//current_argument)
            stop 1
         endif
         lastkeyword=trim(current_argument_padded(3:))
      elseif(.not.nomore.and.current_argument_padded(1:1).eq.'-'.and.index("0123456789.",dummy(2:2)).eq.0)then  ! short word
         keyword_single=.true.
         if(lastkeyword.ne.'')then
            call ifnull()
         endif
         call locate(keywords,current_argument_padded(2:),pointer)
         if(pointer.le.0.and.check_local)then
            call print_dictionary('UNKNOWN SHORT KEYWORD: '//current_argument)
            stop 2
         endif
         lastkeyword=trim(current_argument_padded(2:))
      elseif(pointer.eq.0)then                                                                           ! unnamed arguments
         imax=max(len(unnamed),len(current_argument))
         unnamed=[character(len=imax) :: unnamed,current_argument]
      else
         oldvalue=get(keywords(pointer))//' '
         if(oldvalue(1:1).eq.'"')then
            current_argument=quote(current_argument(:ilength))
         endif
         if(upper(oldvalue).eq.'F'.or.upper(oldvalue).eq.'T')then  ! assume boolean parameter
            if(current_argument.ne.' ')then
               imax=max(len(unnamed),len(current_argument))
               unnamed=[character(len=imax) :: unnamed,current_argument]
            endif
            current_argument='T'
         endif
         call update(keywords(pointer),current_argument)
         pointer=0
         lastkeyword=''
      endif
   enddo GET_ARGS
   if(lastkeyword.ne.'')then
      call ifnull()
   endif

contains
subroutine ifnull()
   oldvalue=get(lastkeyword)//' '
   if(upper(oldvalue).eq.'F'.or.upper(oldvalue).eq.'T')then
      call update(lastkeyword,'T')
   elseif(oldvalue(1:1).eq.'"')then
      call update(lastkeyword,'" "')
   else
      call update(lastkeyword,' ')
   endif
end subroutine ifnull

end subroutine cmd_args_to_dictionary
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine dictionary_to_namelist(nml)
character(len=:),allocatable,intent(out) :: nml
integer :: i
character(len=:),allocatable :: newkeyword
   ! build namelist string
   nml=' '
   if(return_all)then  ! if returning all first do keywords not present on command line so equivalences work
      do i=1,size(keywords)
         if(isupper(keywords(i)(1:1)))then
            newkeyword=trim(lower(keywords(i)))//'_'
         else
            newkeyword=trim(keywords(i))
         endif
         if(.not.present_in(i))then
            select case(newkeyword)
            case('usage','version','help')
            case default
             nml=nml//newkeyword//'='//trim(values(i))//' '
            endselect
         endif
      enddo
   endif

   do i=1,size(keywords)  ! now only do keywords present on command line
      if(isupper(keywords(i)(1:1)))then
         newkeyword=trim(lower(keywords(i)))//'_'
      else
         newkeyword=trim(keywords(i))
      endif
      if(present_in(i))then
         select case(newkeyword)
         case('usage','version','help')
         case default
          nml=nml//newkeyword//'='//trim(values(i))//' '
         endselect
      endif
   enddo

end subroutine dictionary_to_namelist
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!     print_dictionary(3f) - [ARGUMENTS:M_CLI2] print internal dictionary created by calls to commandline(3f)
!!     (LICENSE:PD)
!!##SYNOPSIS
!!
!!
!!
!!     subroutine print_dictionary(header)
!!
!!      character(len=*),intent(in),optional :: header
!!      logical,intent(in),optional          :: stop
!!##DESCRIPTION
!!     Print the internal dictionary created by calls to commandline(3f).
!!     This routine is intended to print the state of the argument list
!!     if an error occurs in using the commandline(3f) procedure..
!!##OPTIONS
!!     HEADER  label to print before printing the state of the command
!!             argument list.
!!     STOP    logical value that if true stops the program after displaying
!!             the dictionary.
!!##EXAMPLE
!!
!!
!!
!! Typical usage:
!!
!!       program demo_commandline
!!       use M_CLI2,  only : unnamed, commandline, print_dictionary
!!       implicit none
!!       integer                      :: i
!!       character(len=255)           :: message ! use for I/O error messages
!!       character(len=:),allocatable :: readme  ! stores updated namelist
!!       integer                      :: ios
!!       real               :: x, y, z
!!       logical            :: help, h
!!       equivalence       (help,h)
!!       namelist /args/ x,y,z,help,h
!!       character(len=*),parameter :: cmd='&ARGS X=1 Y=2 Z=3 HELP=F H=F /'
!!       ! initialize namelist from string and then update from command line
!!       readme=cmd
!!       read(readme,nml=args,iostat=ios,iomsg=message)
!!       if(ios.eq.0)then
!!          ! update cmd with options from command line
!!          readme=commandline(cmd)
!!          read(readme,nml=args,iostat=ios,iomsg=message)
!!       endif
!!       if(ios.ne.0)then
!!          write (*,'("ERROR:",i0,1x,a)')ios, trim(message)
!!          call print_dictionary('OPTIONS:')
!!          stop 1
!!       endif
!!       ! all done cracking the command line
!!       ! use the values in your program.
!!       write (*,nml=args)
!!       ! the optional unnamed values on the command line are
!!       ! accumulated in the character array "UNNAMED"
!!       if(size(unnamed).gt.0)then
!!          write (*,'(a)')'files:'
!!          write (*,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
!!       endif
!!       end program demo_commandline
!!
!!      Sample output
!!
!!      Calling the sample program with an unknown
!!      parameter produces the following:
!!
!!         $ ./print_dictionary -A
!!         UNKNOWN SHORT KEYWORD: -A
!!         KEYWORD             PRESENT  VALUE
!!         z                   F        [3]
!!         y                   F        [2]
!!         x                   F        [1]
!!         help                F        [F]
!!         h                   F        [F]
!!
!!         STOP 2
!!
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine print_dictionary(header,stop)
character(len=*),intent(in),optional :: header
logical,intent(in),optional          :: stop
integer          :: i
   if(present(header))then
      if(header.ne.'')then
         write(stderr,'(a)')header
      endif
   endif
   if(allocated(keywords))then
      if(size(keywords).gt.0)then
         write(stderr,'(*(a,t21,a,t30,a))')'KEYWORD','PRESENT','VALUE'
         write(stderr,'(*(a,t21,l1,t30,"[",a,"]",/))')(trim(keywords(i)),present_in(i),values(i)(:counts(i)),i=1,size(keywords))
      endif
   endif
   if(allocated(unnamed))then
      if(size(unnamed).gt.0)then
         write(stderr,'(a)')'UNNAMED'
         write(stderr,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
      endif
   endif
   if(present(stop))then
      if(stop) stop
   endif
end subroutine print_dictionary
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
FUNCTION strtok(source_string,itoken,token_start,token_end,delimiters) result(strtok_status)
! JSU- 20151030

! ident_11="@(#)M_CLI2::strtok(3f): Tokenize a string"

character(len=*),intent(in)  :: source_string    ! Source string to tokenize.
character(len=*),intent(in)  :: delimiters       ! list of separator characters. May change between calls
integer,intent(inout)        :: itoken           ! token count since started
logical                      :: strtok_status    ! returned value
integer,intent(out)          :: token_start      ! beginning of token found if function result is .true.
integer,intent(inout)        :: token_end        ! end of token found if function result is .true.
integer                      :: isource_len
!----------------------------------------------------------------------------------------------------------------------------
!  calculate where token_start should start for this pass
   if(itoken.le.0)then                           ! this is assumed to be the first call
      token_start=1
   else                                          ! increment start to previous end + 1
      token_start=token_end+1
   endif
!----------------------------------------------------------------------------------------------------------------------------
   isource_len=len(source_string)                ! length of input string
!----------------------------------------------------------------------------------------------------------------------------
   if(token_start.gt.isource_len)then            ! user input error or at end of string
      token_end=isource_len                      ! assume end of token is end of string until proven otherwise so it is set
      strtok_status=.false.
      return
   endif
!----------------------------------------------------------------------------------------------------------------------------
   ! find beginning of token
   do while (token_start .le. isource_len)       ! step thru each character to find next delimiter, if any
      if(index(delimiters,source_string(token_start:token_start)) .ne. 0) then
         token_start = token_start + 1
      else
         exit
      endif
   enddo
!----------------------------------------------------------------------------------------------------------------------------
   token_end=token_start
   do while (token_end .le. isource_len-1)       ! step thru each character to find next delimiter, if any
      if(index(delimiters,source_string(token_end+1:token_end+1)) .ne. 0) then  ! found a delimiter in next character
         exit
      endif
      token_end = token_end + 1
   enddo
!----------------------------------------------------------------------------------------------------------------------------
   if (token_start .gt. isource_len) then        ! determine if finished
      strtok_status=.false.                      ! flag that input string has been completely processed
   else
      itoken=itoken+1                            ! increment count of tokens found
      strtok_status=.true.                       ! flag more tokens may remain
   endif
!----------------------------------------------------------------------------------------------------------------------------
end function strtok
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!     set_args(3f) - [ARGUMENTS:M_CLI2] command line argument parsing
!!     (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!
!!
!!     subroutine set_args(definition,help_text,version_text)
!!
!!      character(len=*),intent(in),optional  :: definition
!!      character(len=:),intent(in),allocatable,intent(in) :: help_text
!!      character(len=:),intent(in),allocatable,intent(in) :: version_text
!!##DESCRIPTION
!!
!!     SET_ARGS(3f) requires a unix-like command prototype for defining
!!     arguments and default command-line options. Argument values are then
!!     read using GET_ARGS(3f).
!!
!!##OPTIONS
!!
!!      DESCRIPTION   composed of all command arguments concatenated
!!                    into a Unix-like command prototype string.
!!
!!                    o all keywords get a value.
!!                    o logicals must be set to F or T.
!!                    o strings MUST be delimited with double-quotes and
!!                      must be at least one space. Internal
!!                      double-quotes are represented with two double-quotes
!!                    o lists of values should be comma-delimited.
!!                    o long names (--keyword) should be all lowercase
!!
!!                    DESCRIPTION is pre-defined to act as if started with the
!!                    reserved options '--usage F --help F --version F'.
!!
!!                    The --help and --version options require the optional
!!                    help_text and version_text values to be provided.
!!
!!      HELP_TEXT     if present, will be displayed if program is called with
!!                    --help switch, and then the program will terminate. If
!!                    not supplied, the command line initialized string will be
!!                    shown when --help is used on the commandline.
!!
!!      VERSION_TEXT  if present, will be displayed if program is called with
!!                    --version switch, and then the program will terminate.
!!
!!##USAGE
!!      When using one of the Unix-like command line forms note that
!!      (subject to change) the following variations from other common
!!      command-line parsers:
!!
!!         o long names do not take the --KEY=VALUE form, just
!!           --KEY VALUE; and long names should be all lowercase and
!!           always more than one character.
!!
!!         o duplicate keywords are appended together with a space
!!           separator when a command line is executed.
!!
!!         o numeric keywords are not allowed; but this allows
!!           negative numbers to be used as values.
!!
!!         o mapping of short names to long names is via an EQUIVALENCE.
!!           Note that allocatable arrays cannot be EQUIVANENCEd.
!!
!!           Specifying both names of an equivalenced keyword on a command
!!           line will have undefined results (currently, their alphabetical
!!           order will define what the Fortran variable values become).
!!
!!         o short keywords cannot be combined. -a -b -c is required,
!!           not -abc even for Boolean keys.
!!
!!         o shuffling is not supported. Values should follow their
!!           keywords.
!!
!!         o if a parameter value of just "-" is supplied it is
!!           converted to the string "stdin".
!!
!!         o if the keyword "--" is encountered the rest of the
!!           command arguments go into the character array "UNUSED".
!!
!!         o values not matching a keyword go into the character
!!           array "UNUSED".
!!
!!##EXAMPLE
!!
!!
!! Sample program:
!!
!!     program demo_set_args
!!     use M_CLI2,  only : filenames=>unnamed, set_args, get_args, unnamed
!!     implicit none
!!     integer                      :: i
!!     integer,parameter            :: dp=kind(0.0d0)
!!     ! DEFINE ARGS
!!     real                         :: x, y, z
!!     real                         :: p(3)
!!     character(len=:),allocatable :: title
!!     logical                      :: l, lbig
!!     !  DEFINE AND PARSE (TO SET INITIAL VALUES) COMMAND LINE
!!     !   o only quote strings
!!     !   o set all logical values to F or T.
!!     call set_args(' -x 1 -y 2 -z 3 -p -1,-2,-3 --title "my title" &
!!             & -l F -L F &
!!             & --label " " &
!!             & ')
!!     ! ASSIGN VALUES TO ELEMENTS
!!     ! SCALARS
!!     call get_args('x',x)
!!     call get_args('y',y)
!!     call get_args('z',z)
!!     call get_args('l',l)
!!     call get_args('L',lbig)
!!     ! ALLOCATABLE STRING
!!     call get_args('title',title)
!!     ! NON-ALLOCATABLE ARRAYS
!!     ! for non-allocatable arrays pass size
!!     call get_args('p',p,size(p))
!!     ! USE VALUES
!!     write(*,*)'x=',x
!!     write(*,*)'y=',y
!!     write(*,*)'z=',z
!!     write(*,*)'p=',p
!!     write(*,*)'title=',title
!!     write(*,*)'l=',l
!!     write(*,*)'L=',lbig
!!     if(size(filenames).gt.0)then
!!        write(*,'(i6.6,3a)')(i,'[',filenames(i),']',i=1,size(filenames))
!!     endif
!!     end program demo_set_args
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!==================================================================================================================================!
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!==================================================================================================================================!
!>
!!##NAME
!!     get_args(3f) - [ARGUMENTS:M_CLI2] return keyword values when parsing command line arguments
!!     (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!
!!
!!     subroutine get_args(name,value,magnitude)
!!
!!      character(len=*),intent(in),optional  :: name
!!      real|integer|logical|character(len=*) :: value
!!      integer,intent(in) :: magnitude
!!
!!##DESCRIPTION
!!
!!     GET_ARGS(3f) returns the value of keywords after SET_ARGS(3f) has
!!     been called.
!!
!!##OPTIONS
!!
!!      NAME       name of commandline argument to obtain the value of
!!      VALUE      variable to hold returned value. The kind of the value
!!                 is used to determine the type of returned value
!!      MAGNITUDE  for non-allocatable arrays the size of the array. For
!!                 non-allocatable character variables the length of the
!!                 variable.
!!##EXAMPLE
!!
!!
!! Sample program:
!!
!!     program demo_get_args
!!     use M_CLI2,  only : filenames=>unnamed, set_args, get_args, unnamed
!!     implicit none
!!     integer                      :: i
!!     integer,parameter            :: dp=kind(0.0d0)
!!     ! DEFINE ARGS
!!     real                         :: x, y, z
!!     real                         :: p(3)
!!     character(len=:),allocatable :: title
!!     logical                      :: l, lbig
!!     ! DEFINE AND PARSE (TO SET INITIAL VALUES) COMMAND LINE
!!     !   o only quote strings
!!     !   o set all logical values to F or T.
!!     call set_args(' -x 1 -y 2 -z 3 -p -1,-2,-3 --title "my title" &
!!             & -l F -L F  &
!!             & --label " " &
!!             & ')
!!     ! ASSIGN VALUES TO ELEMENTS
!!     ! SCALARS
!!     call get_args('x',x)
!!     call get_args('y',y)
!!     call get_args('z',z)
!!     call get_args('l',l)
!!     call get_args('L',lbig)
!!     ! ALLOCATABLE STRING
!!     call get_args('title',title)
!!     ! NON-ALLOCATABLE ARRAYS
!!     ! for non-allocatable arrays pass size
!!     call get_args('p',p,size(p))
!!     ! USE VALUES
!!     write(*,*)'x=',x
!!     write(*,*)'y=',y
!!     write(*,*)'z=',z
!!     write(*,*)'p=',p
!!     write(*,*)'title=',title
!!     write(*,*)'l=',l
!!     write(*,*)'L=',lbig
!!     if(size(filenames).gt.0)then
!!        write(*,'(i6.6,3a)')(i,'[',filenames(i),']',i=1,size(filenames))
!!     endif
!!     if(size(unnamed).gt.0)then
!!        write (*,'(a)')'files:'
!!        write (*,'(i6.6,3a)') (i,'[',unnamed(i),']',i=1,size(unnamed))
!!     endif
!!     end program demo_get_args
!!##AUTHOR
!!      John S. Urban, 2019
!!##LICENSE
!!      Public Domain
!===================================================================================================================================
subroutine get_args_class(keyword,generic,bounds)
character(len=*),intent(in) :: keyword      ! keyword to retrieve value for from dictionary
class(*)                    :: generic(:)
integer                     :: bounds
   select type(generic)
    type is (character(len=*));  call get_args_cc(keyword,generic)
    type is (integer);           call get_args_ii(keyword,generic)
    type is (real);              call get_args_rr(keyword,generic)
    type is (real(kind=dp));     call get_args_dd(keyword,generic)
    type is (logical);           call get_args_ll(keyword,generic)
    class default
      stop '*get_args_class* crud -- procedure does not know about this type'
   end select
end subroutine get_args_class
!===================================================================================================================================
! return allocatable arrays
!===================================================================================================================================
subroutine get_args_l(keyword,larray)

! ident_12="@(#)M_CLI2::get_args_l(3f): given keyword fetch logical array from string in dictionary(F on err)"

character(len=*),intent(in)  :: keyword                    ! the dictionary keyword (in form VERB_KEYWORD) to retrieve
logical,allocatable          :: larray(:)                  ! convert value to an array
character(len=:),allocatable :: carray(:)                  ! convert value to an array
character(len=*),parameter   :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
character(len=:),allocatable :: val
integer                      :: i
integer                      :: place
integer                      :: ichar                      ! point to first character of word unless first character is "."
   call locate(keywords,keyword,place)                     ! find where string is or should be
   if(place.gt.0)then                                      ! if string was found
      val=values(place)(:counts(place))
      call split(adjustl(upper(val)),carray,delimiters=dlim)  ! convert value to uppercase, trimmed; then parse into array
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
   if(size(carray).gt.0)then                                  ! if not a null string
      allocate(larray(size(carray)))                          ! allocate output array
      do i=1,size(carray)
         larray(i)=.false.                                    ! initialize return value to .false.
         if(carray(i)(1:1).eq.'.')then                     ! looking for fortran logical syntax .STRING.
            ichar=2
         else
            ichar=1
         endif
         select case(carray(i)(ichar:ichar))               ! check word to see if true or false
         case('T','Y',' '); larray(i)=.true.               ! anything starting with "T" or "Y" or a blank is TRUE (true,yes,...)
         case('F','N');     larray(i)=.false.              ! assume this is false or no
         case default
            call journal('sc',"*get_args* bad logical expression for "//trim(keyword)//'='//carray(i))
         end select
      enddo
   else                                                       ! for a blank string return one T
      allocate(larray(1))                                     ! allocate output array
      larray(1)=.true.
   endif
end subroutine get_args_l
!===================================================================================================================================
subroutine get_args_d(keyword,darray)

! ident_13="@(#)M_CLI2::get_args_d(3f): given keyword fetch dble value array from Language Dictionary (0 on err)"

character(len=*),intent(in)           :: keyword      ! keyword to retrieve value for from dictionary
real(kind=dp),allocatable,intent(out) :: darray(:)    ! function type

character(len=:),allocatable          :: carray(:)    ! convert value to an array using split(3f)
integer                               :: i
integer                               :: place
integer                               :: ierr
character(len=:),allocatable          :: val
character(len=*),parameter            :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
!-----------------------------------------------------------------------------------------------------------------------------------
   call locate(keywords,keyword,place)                ! find where string is or should be
   if(place.gt.0)then                                 ! if string was found
      val=values(place)(:counts(place))
      call split(val,carray,delimiters=dlim)          ! find value associated with keyword and split it into an array
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
   allocate(darray(size(carray)))                     ! create the output array
   do i=1,size(carray)
      call string_to_value(carray(i), darray(i),ierr) ! convert the string to a numeric value
      if(ierr.ne.0)then
         call journal('sc','*get_args* unreadable value',carray(i),'for keyword',keyword)
         stop
      endif
   enddo
end subroutine get_args_d
!===================================================================================================================================
subroutine get_args_i(keyword,iarray)
character(len=*),intent(in)      :: keyword      ! keyword to retrieve value for from dictionary
integer,allocatable              :: iarray(:)
real(kind=dp),allocatable        :: darray(:)    ! function type
   call get_args_d(keyword,darray)
   iarray=nint(darray)
end subroutine get_args_i
!===================================================================================================================================
subroutine get_args_r(keyword,rarray)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
real,allocatable  :: rarray(:)
   real(kind=dp),allocatable     :: darray(:)    ! function type
   call get_args_d(keyword,darray)
rarray=real(darray)
end subroutine get_args_r
!===================================================================================================================================
subroutine get_args_c(keyword,strings)

! ident_14="@(#)M_kracken::get_args_cc(3f): Fetch strings value for specified KEYWORD from the lang. dictionary"

! Thmeis routine trusts that the desired keyword exists. A blank is returned if the keyword is not in the dictionary
character(len=*),parameter    :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
character(len=:),allocatable  :: strings(:)
character(len=*),intent(in)   :: keyword              ! name to look up in dictionary
integer                       :: place
character(len=:),allocatable  :: val
   call locate(keywords,keyword,place)                ! find where string is or should be
   if(place > 0)then                                  ! if index is valid return strings
      val=unquote(values(place)(:counts(place)))
      call split(val,strings,delimiters=dlim)         ! find value associated with keyword and split it into an array
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
end subroutine get_args_c
!===================================================================================================================================
! return non-allocatable arrays
!===================================================================================================================================
subroutine get_args_ii(keyword,iarray)
character(len=*),intent(in)      :: keyword      ! keyword to retrieve value for from dictionary
integer                          :: iarray(:)
real(kind=dp),allocatable        :: darray(:)    ! function type
   call get_args_d(keyword,darray)
   if(ubound(iarray,dim=1).eq.size(darray))then
      iarray=darray
   else
      call journal('sc','*get_args* wrong number of values for keyword',keyword,'got',size(darray),'expected',size(iarray))
      stop
   endif
end subroutine get_args_ii
!===================================================================================================================================
subroutine get_args_rr(keyword,rarray)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
real                          :: rarray(:)
real(kind=dp),allocatable     :: darray(:)    ! function type
   call get_args_d(keyword,darray)
   if(ubound(rarray,dim=1).eq.size(darray))then
      rarray=darray
   else
      call journal('sc','*get_args* wrong number of values for keyword',keyword,'got',size(darray),'expected',size(rarray))
      stop
   endif
end subroutine get_args_rr
!===================================================================================================================================
subroutine get_args_dd(keyword,darr)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
real(kind=dp)                 :: darr(:)
real(kind=dp),allocatable     :: darray(:)    ! function type
   call get_args_d(keyword,darray)
   if(ubound(darr,dim=1).eq.size(darray))then
      darr=darray
   else
      call journal('sc','*get_args* wrong number of values for keyword',keyword,'got',size(darray),'expected',size(darr))
      stop
   endif
end subroutine get_args_dd
!===================================================================================================================================
subroutine get_args_ll(keyword,larray)
character(len=*),intent(in)      :: keyword      ! keyword to retrieve value for from dictionary
logical                          :: larray(:)
logical,allocatable              :: darray(:)    ! function type
   call get_args_l(keyword,darray)
   if(ubound(larray,dim=1).eq.size(darray))then
      larray=darray
   else
      call journal('sc','*get_args* wrong number of values for keyword',keyword,'got',size(darray),'expected',size(larray))
      stop
   endif
end subroutine get_args_ll
!===================================================================================================================================
subroutine get_args_cc(keyword,strings)

! ident_15="@(#)M_kracken::get_args_cc(3f): Fetch strings value for specified KEYWORD from the lang. dictionary"

! This routine trusts that the desired keyword exists. A blank is returned if the keyword is not in the dictionary
character(len=*),parameter    :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
character(len=*)              :: strings(:)
character(len=:),allocatable  :: str(:)
character(len=*),intent(in)   :: keyword          ! name to look up in dictionary
integer                       :: place
character(len=:),allocatable  :: val
   call locate(keywords,keyword,place)            ! find where string is or should be
   if(place > 0)then                              ! if index is valid return strings
      val=unquote(values(place)(:counts(place)))
      call split(val,str,delimiters=dlim)         ! find value associated with keyword and split it into an array
      if(size(str)<=size(strings))then
         strings=''
         strings(:size(strings))=str
      else
         call journal('sc','*get_args* wrong number of values for keyword',keyword,'got',size(str),'expected at most',size(strings))
         stop
      endif
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
end subroutine get_args_cc
!===================================================================================================================================
! return scalars
!===================================================================================================================================
subroutine get_arg_d(keyword,d)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
real(kind=dp)                 :: d
real(kind=dp),allocatable     :: darray(:)    ! function type
   call get_args_d(keyword,darray)
   if(size(darray).eq.1)then
      d=darray(1)
   else
      call journal('sc','*get_args* incorrect number of values for keyword',keyword,'expected one found',size(darray))
      stop
   endif
end subroutine get_arg_d
!===================================================================================================================================
subroutine get_arg_r(keyword,r)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
real,intent(out)              :: r
real(kind=dp)                 :: d
   call get_arg_d(keyword,d)
   r=real(d)
end subroutine get_arg_r
!===================================================================================================================================
subroutine get_arg_i(keyword,i)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
integer,intent(out)           :: i
real(kind=dp)                 :: d
   call get_arg_d(keyword,d)
   i=nint(d)
end subroutine get_arg_i
!===================================================================================================================================
subroutine get_arg_c(keyword,strings)

! ident_16="@(#)M_kracken::get_arg_cc(3f): Fetch strings value for specified KEYWORD from the lang. dictionary"

! Thmeis routine trusts that the desired keyword exists. A blank is returned if the keyword is not in the dictionary
character(len=*),parameter    :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
character(len=:),allocatable  :: strings
character(len=*),intent(in)   :: keyword              ! name to look up in dictionary
integer                       :: place
   call locate(keywords,keyword,place)                ! find where string is or should be
   if(place > 0)then                                  ! if index is valid return strings
      strings=unquote(values(place)(:counts(place)))
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
end subroutine get_arg_c
!===================================================================================================================================
subroutine get_arg_cx(keyword,strings,length)

! ident_17="@(#)M_kracken::get_arg_cx(3f): Fetch strings value for specified KEYWORD from the lang. dictionary"

! Thmeis routine trusts that the desired keyword exists. A blank is returned if the keyword is not in the dictionary
character(len=*),parameter    :: dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)//',:'
character(len=*)              :: strings
character(len=*),intent(in)   :: keyword              ! name to look up in dictionary
integer                       :: place
integer                       :: length
   call locate(keywords,keyword,place)                ! find where string is or should be
   if(place > 0)then                                  ! if index is valid return strings
      strings=unquote(values(place)(:counts(place)))
   else
      call journal('sc','*get_args* unknown keyword ',keyword)
      stop
   endif
   if(counts(place)>len(strings))then
      call journal('sc','*get_args* value too long for',keyword,'allowed is',len(strings),&
      & 'input string [',values(place),'] is',counts(place))
      stop
   endif
end subroutine get_arg_cx
!===================================================================================================================================
subroutine get_arg_l(keyword,l)
character(len=*),intent(in)   :: keyword      ! keyword to retrieve value for from dictionary
logical                       :: l
logical,allocatable           :: larray(:)    ! function type
   call get_args_l(keyword,larray)
   if(size(larray).eq.1)then
      l=larray(1)
   else
      call journal('sc','*get_args* incorrect number of values for keyword',keyword,'expected one found',size(larray))
      stop
   endif
end subroutine get_arg_l
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!JSU
!use M_strings,                     only : ISUPPER, UPPER, LOWER, QUOTE, REPLACE_STR=>REPLACE, UNQUOTE, SPLIT, STRING_TO_VALUE
!use M_list,                        only : insert, locate, remove, replace
!use M_journal,                     only : JOURNAL

!use M_args,                        only : LONGEST_COMMAND_ARGUMENT
! routines extracted from other modules
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    longest_command_argument(3f) - [ARGUMENTS:M_args] length of longest argument on command line
!!    (LICENSE:PD)
!!##SYNOPSIS
!!
!!    function longest_command_argument() result(ilongest)
!!
!!     integer :: ilongest
!!
!!##DESCRIPTION
!!    length of longest argument on command line. Useful when allocating storage for holding arguments.
!!##RESULT
!!    longest_command_argument  length of longest command argument
!!##EXAMPLE
!!
!! Sample program
!!
!!      program demo_longest_command_argument
!!      use M_args, only : longest_command_argument
!!         write(*,*)'longest argument is ',longest_command_argument()
!!      end program demo_longest_command_argument
!!##AUTHOR
!!    John S. Urban, 2019
!!##LICENSE
!!    Public Domain
function longest_command_argument() result(ilongest)
integer :: i
integer :: ilength
integer :: istatus
integer :: ilongest
   ilength=0
   ilongest=0
   GET_LONGEST: do i=1,command_argument_count()                             ! loop throughout command line arguments to find longest
      call get_command_argument(number=i,length=ilength,status=istatus)     ! get next argument
      if(istatus /= 0) then                                                 ! stop program on error
         write(stderr,*)'*prototype_and_cmd_args_to_nlist* error obtaining length for argument ',i
         exit GET_LONGEST
      elseif(ilength.gt.0)then
         ilongest=max(ilongest,ilength)
      endif
   enddo GET_LONGEST
end function longest_command_argument
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
subroutine journal(where, g0, g1, g2, g3, g4, g5, g6, g7, g8, g9, nospace)
implicit none

! ident_18="@(#)M_journal::journal(3f): writes a message to a string composed of any standard scalar types"

character(len=*),intent(in)   :: where
class(*),intent(in)           :: g0
class(*),intent(in),optional  :: g1, g2, g3, g4, g5, g6, g7, g8 ,g9
logical,intent(in),optional   :: nospace
write(*,'(a)')str(g0, g1, g2, g3, g4, g5, g6, g7, g8, g9,nospace)
end subroutine journal
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    str(3f) - [M_msg] converts any standard scalar type to a string
!!    (LICENSE:PD)
!!##SYNOPSIS
!!
!!    function str(g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb,gc,gd,ge,gf,gg,gh,gi,gj,nospace)
!!
!!     class(*),intent(in),optional  :: g0,g1,g2,g3,g4,g5,g6,g7,g8,g9
!!     class(*),intent(in),optional  :: ga,gb,gc,gd,ge,gf,gg,gh,gi,gj
!!     logical,intent(in),optional   :: nospace
!!     character,len=(:),allocatable :: str
!!
!!##DESCRIPTION
!!    str(3f) builds a space-separated string from up to twenty scalar values.
!!
!!##OPTIONS
!!    g[0-9a-j]   optional value to print the value of after the message. May
!!                be of type INTEGER, LOGICAL, REAL, DOUBLEPRECISION,
!!                COMPLEX, or CHARACTER.
!!
!!                Optionally, all the generic values can be
!!                single-dimensioned arrays. Currently, mixing scalar
!!                arguments and array arguments is not supported.
!!
!!    nospace     if nospace=.true., then no spaces are added between values
!!##RETURNS
!!    str     description to print
!!##EXAMPLES
!!
!! Sample program:
!!
!!       program demo_msg
!!       use M_msg, only : str
!!       implicit none
!!       character(len=:),allocatable :: pr
!!       character(len=:),allocatable :: frmt
!!       integer                      :: biggest
!!
!!       pr=str('HUGE(3f) integers',huge(0),'and real',huge(0.0),'and double',huge(0.0d0))
!!       write(*,'(a)')pr
!!       pr=str('real            :',huge(0.0),0.0,12345.6789,tiny(0.0) )
!!       write(*,'(a)')pr
!!       pr=str('doubleprecision :',huge(0.0d0),0.0d0,12345.6789d0,tiny(0.0d0) )
!!       write(*,'(a)')pr
!!       pr=str('complex         :',cmplx(huge(0.0),tiny(0.0)) )
!!       write(*,'(a)')pr
!!
!!       ! create a format on the fly
!!       biggest=huge(0)
!!       frmt=str('(*(i',int(log10(real(biggest))),':,1x))',nospace=.true.)
!!       write(*,*)'format=',frmt
!!
!!       ! although it will often work, using str(3f) in an I/O statement is not recommended
!!       ! because if an error occurs str(3f) will try to write while part of an I/O statement
!!       ! which not all compilers can handle and is currently non-standard
!!       write(*,*)str('program will now stop')
!!
!!       end program demo_msg
!!
!!  Output
!!
!!     HUGE(3f) integers 2147483647 and real 3.40282347E+38 and double 1.7976931348623157E+308
!!     real            : 3.40282347E+38 0.00000000 12345.6787 1.17549435E-38
!!     doubleprecision : 1.7976931348623157E+308 0.0000000000000000 12345.678900000001 2.2250738585072014E-308
!!     complex         : (3.40282347E+38,1.17549435E-38)
!!      format=(*(i9:,1x))
!!      program will now stop
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function msg_scalar(generic0, generic1, generic2, generic3, generic4, generic5, generic6, generic7, generic8, generic9, &
                  & generica, genericb, genericc, genericd, generice, genericf, genericg, generich, generici, genericj, &
                  & nospace)
implicit none

! ident_19="@(#)M_msg::msg_scalar(3fp): writes a message to a string composed of any standard scalar types"

class(*),intent(in),optional  :: generic0, generic1, generic2, generic3, generic4
class(*),intent(in),optional  :: generic5, generic6, generic7, generic8, generic9
class(*),intent(in),optional  :: generica, genericb, genericc, genericd, generice
class(*),intent(in),optional  :: genericf, genericg, generich, generici, genericj
logical,intent(in),optional   :: nospace
character(len=:), allocatable :: msg_scalar
character(len=4096)           :: line
integer                       :: istart
integer                       :: increment
   if(present(nospace))then
      if(nospace)then
         increment=1
      else
         increment=2
      endif
   else
      increment=2
   endif

   istart=1
   line=''
   if(present(generic0))call print_generic(generic0)
   if(present(generic1))call print_generic(generic1)
   if(present(generic2))call print_generic(generic2)
   if(present(generic3))call print_generic(generic3)
   if(present(generic4))call print_generic(generic4)
   if(present(generic5))call print_generic(generic5)
   if(present(generic6))call print_generic(generic6)
   if(present(generic7))call print_generic(generic7)
   if(present(generic8))call print_generic(generic8)
   if(present(generic9))call print_generic(generic9)
   if(present(generica))call print_generic(generica)
   if(present(genericb))call print_generic(genericb)
   if(present(genericc))call print_generic(genericc)
   if(present(genericd))call print_generic(genericd)
   if(present(generice))call print_generic(generice)
   if(present(genericf))call print_generic(genericf)
   if(present(genericg))call print_generic(genericg)
   if(present(generich))call print_generic(generich)
   if(present(generici))call print_generic(generici)
   if(present(genericj))call print_generic(genericj)
   msg_scalar=trim(line)
contains
!===================================================================================================================================
subroutine print_generic(generic)
!use, intrinsic :: iso_fortran_env, only : int8, int16, int32, biggest=>int64, real32, real64, dp=>real128
use,intrinsic :: iso_fortran_env, only : int8, int16, int32, int64, real32, real64, real128
class(*),intent(in) :: generic
   select type(generic)
      type is (integer(kind=int8));     write(line(istart:),'(i0)') generic
      type is (integer(kind=int16));    write(line(istart:),'(i0)') generic
      type is (integer(kind=int32));    write(line(istart:),'(i0)') generic
      type is (integer(kind=int64));    write(line(istart:),'(i0)') generic
      type is (real(kind=real32));      write(line(istart:),'(1pg0)') generic
      type is (real(kind=real64));      write(line(istart:),'(1pg0)') generic
      type is (real(kind=real128));     write(line(istart:),'(1pg0)') generic
      type is (logical);                write(line(istart:),'(1l)') generic
      type is (character(len=*));       write(line(istart:),'(a)') trim(generic)
      type is (complex);                write(line(istart:),'("(",1pg0,",",1pg0,")")') generic
   end select
   istart=len_trim(line)+increment
end subroutine print_generic
!===================================================================================================================================
end function msg_scalar
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
function msg_one(generic0,generic1, generic2, generic3, generic4, generic5, generic6, generic7, generic8, generic9,nospace)
implicit none

! ident_20="@(#)M_msg::msg_one(3fp): writes a message to a string composed of any standard one dimensional types"

class(*),intent(in)           :: generic0(:)
class(*),intent(in),optional  :: generic1(:), generic2(:), generic3(:), generic4(:), generic5(:)
class(*),intent(in),optional  :: generic6(:), generic7(:), generic8(:), generic9(:)
logical,intent(in),optional   :: nospace
character(len=:), allocatable :: msg_one
character(len=4096)           :: line
integer                       :: istart
integer                       :: increment
   if(present(nospace))then
      if(nospace)then
         increment=1
      else
         increment=2
      endif
   else
      increment=2
   endif

   istart=1
   line=' '
   call print_generic(generic0)
   if(present(generic1))call print_generic(generic1)
   if(present(generic2))call print_generic(generic2)
   if(present(generic3))call print_generic(generic3)
   if(present(generic4))call print_generic(generic4)
   if(present(generic5))call print_generic(generic5)
   if(present(generic6))call print_generic(generic6)
   if(present(generic7))call print_generic(generic7)
   if(present(generic8))call print_generic(generic8)
   if(present(generic9))call print_generic(generic9)
   msg_one=trim(line)
contains
!===================================================================================================================================
subroutine print_generic(generic)
!use, intrinsic :: iso_fortran_env, only : int8, int16, int32, biggest=>int64, real32, real64, dp=>real128
use,intrinsic :: iso_fortran_env, only : int8, int16, int32, int64, real32, real64, real128
class(*),intent(in),optional :: generic(:)
integer :: i
   select type(generic)
      type is (integer(kind=int8));     write(line(istart:),'("[",*(i0,1x))') generic
      type is (integer(kind=int16));    write(line(istart:),'("[",*(i0,1x))') generic
      type is (integer(kind=int32));    write(line(istart:),'("[",*(i0,1x))') generic
      type is (integer(kind=int64));    write(line(istart:),'("[",*(i0,1x))') generic
      type is (real(kind=real32));      write(line(istart:),'("[",*(1pg0,1x))') generic
      type is (real(kind=real64));      write(line(istart:),'("[",*(1pg0,1x))') generic
      type is (real(kind=real128));     write(line(istart:),'("[",*(1pg0,1x))') generic
      !type is (real(kind=real256));     write(error_unit,'(1pg0)',advance='no') generic
      type is (logical);                write(line(istart:),'("[",*(1l,1x))') generic
      type is (character(len=*));       write(line(istart:),'("[",:*("""",a,"""",1x))') (trim(generic(i)),i=1,size(generic))
      type is (complex);                write(line(istart:),'("[",*("(",1pg0,",",1pg0,")",1x))') generic
      class default
         stop 'unknown type in *print_generic*'
   end select
   line=trim(line)//"]"
   istart=len_trim(line)+increment
end subroutine print_generic
!===================================================================================================================================
end function msg_one
!===================================================================================================================================
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!! upper(3f) - [M_strings:CASE] changes a string to uppercase
!! (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    elemental pure function upper(str,begin,end) result (string)
!!
!!     character(*), intent(in)    :: str
!!     integer,optional,intent(in) :: begin,end
!!     character(len(str))         :: string  ! output string
!!##DESCRIPTION
!!      upper(string) returns a copy of the input string with all characters
!!      converted in the optionally specified range to uppercase, assuming
!!      ASCII character sets are being used. If no range is specified the
!!      entire string is converted to uppercase.
!!
!!##OPTIONS
!!    str    string to convert to uppercase
!!    begin  optional starting position in "str" to begin converting to uppercase
!!    end    optional ending position in "str" to stop converting to uppercase
!!
!!##RESULTS
!!    upper  copy of the input string with all characters converted to uppercase
!!           over optionally specified range.
!!
!!##TRIVIA
!!    The terms "uppercase" and "lowercase" date back to the early days of
!!    the mechanical printing press. Individual metal alloy casts of each
!!    needed letter, or punctuation symbol, were meticulously added to a
!!    press block, by hand, before rolling out copies of a page. These
!!    metal casts were stored and organized in wooden cases. The more
!!    often needed miniscule letters were placed closer to hand, in the
!!    lower cases of the work bench. The less often needed, capitalized,
!!    majuscule letters, ended up in the harder to reach upper cases.
!!
!!##EXAMPLE
!!
!! Sample program:
!!
!!     program demo_upper
!!     use M_strings, only: upper
!!     implicit none
!!     character(len=:),allocatable  :: s
!!        s=' ABCDEFG abcdefg '
!!        write(*,*) 'mixed-case input string is ....',s
!!        write(*,*) 'upper-case output string is ...',upper(s)
!!        write(*,*) 'make first character uppercase  ... ',upper('this is a sentence.',1,1)
!!        write(*,'(1x,a,*(a:,"+"))') 'UPPER(3f) is elemental ==>',upper(["abc","def","ghi"])
!!     end program demo_upper
!!
!!    Expected output
!!
!!     mixed-case input string is .... ABCDEFG abcdefg
!!     upper-case output string is ... ABCDEFG ABCDEFG
!!     make first character uppercase  ... This is a sentence.
!!     UPPER(3f) is elemental ==>ABC+DEF+GHI
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
!===================================================================================================================================
! Timing
!
!    Several different methods have been proposed for changing case.
!    A simple program that copies a large file and converts it to
!    uppercase was timed and compared to a simple copy. This was used
!    to select the default function.
!
! NULL:    83.41user  9.25system 1:37.94elapsed 94%CPU
! upper:  101.44user 10.89system 1:58.36elapsed 94%CPU
! upper2: 105.04user 10.69system 2:04.17elapsed 93%CPU
! upper3: 267.21user 11.69system 4:49.21elapsed 96%CPU
elemental pure function upper(str,begin,end) result (string)

! ident_21="@(#)M_strings::upper(3f): Changes a string to uppercase"

character(*), intent(In)      :: str                 ! inpout string to convert to all uppercase
integer, intent(in), optional :: begin,end
character(len(str))           :: string              ! output string that contains no miniscule letters
integer                       :: i                   ! loop counter
integer                       :: ibegin,iend
   string = str                                      ! initialize output string to input string

   ibegin = 1
   if (present(begin))then
      ibegin = max(ibegin,begin)
   endif

   iend = len_trim(str)
   if (present(end))then
      iend= min(iend,end)
   endif

   do i = ibegin, iend                               ! step thru each letter in the string in specified range
       select case (str(i:i))
       case ('a':'z')                                ! located miniscule letter
          string(i:i) = char(iachar(str(i:i))-32)    ! change miniscule letter to uppercase
       end select
   end do

end function upper
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    lower(3f) - [M_strings:CASE] changes a string to lowercase over specified range
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    elemental pure function lower(str,begin,end) result (string)
!!
!!     character(*), intent(in) :: str
!!     integer,optional         :: begin, end
!!     character(len(str))      :: string  ! output string
!!##DESCRIPTION
!!      lower(string) returns a copy of the input string with all characters
!!      converted to miniscule over the specified range, assuming ASCII
!!      character sets are being used. If no range is specified the entire
!!      string is converted to miniscule.
!!
!!##OPTIONS
!!    str    string to convert to miniscule
!!    begin  optional starting position in "str" to begin converting to miniscule
!!    end    optional ending position in "str" to stop converting to miniscule
!!
!!##RESULTS
!!    lower  copy of the input string with all characters converted to miniscule
!!           over optionally specified range.
!!
!!##TRIVIA
!!    The terms "uppercase" and "lowercase" date back to the early days of
!!    the mechanical printing press. Individual metal alloy casts of each
!!    needed letter, or punctuation symbol, were meticulously added to a
!!    press block, by hand, before rolling out copies of a page. These
!!    metal casts were stored and organized in wooden cases. The more
!!    often needed miniscule letters were placed closer to hand, in the
!!    lower cases of the work bench. The less often needed, capitalized,
!!    majuscule letters, ended up in the harder to reach upper cases.
!!
!!##EXAMPLE
!!
!! Sample program:
!!
!!       program demo_lower
!!       use M_strings, only: lower
!!       implicit none
!!       character(len=:),allocatable  :: s
!!          s=' ABCDEFG abcdefg '
!!          write(*,*) 'mixed-case input string is ....',s
!!          write(*,*) 'lower-case output string is ...',lower(s)
!!       end program demo_lower
!!
!!    Expected output
!!
!!       mixed-case input string is .... ABCDEFG abcdefg
!!       lower-case output string is ... abcdefg abcdefg
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
elemental pure function lower(str,begin,end) result (string)

! ident_22="@(#)M_strings::lower(3f): Changes a string to lowercase over specified range"

character(*), intent(In)     :: str
character(len(str))          :: string
integer,intent(in),optional  :: begin, end
integer                      :: i
integer                      :: ibegin, iend
   string = str

   ibegin = 1
   if (present(begin))then
      ibegin = max(ibegin,begin)
   endif

   iend = len_trim(str)
   if (present(end))then
      iend= min(iend,end)
   endif

   do i = ibegin, iend                               ! step thru each letter in the string in specified range
      select case (str(i:i))
      case ('A':'Z')
         string(i:i) = char(iachar(str(i:i))+32)     ! change letter to miniscule
      case default
      end select
   end do

end function lower
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      string_to_value(3f) - [M_strings:NUMERIC] subroutine returns numeric value from string
!!      (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    subroutine string_to_value(chars,valu,ierr)
!!
!!     character(len=*),intent(in)              :: chars   ! input string
!!     integer|real|doubleprecision,intent(out) :: valu
!!     integer,intent(out)                      :: ierr
!!##DESCRIPTION
!!       returns a numeric value from a numeric character string.
!!
!!       works with any g-format input, including integer, real, and
!!       exponential. If the input string begins with "B", "Z", or "O"
!!       and otherwise represents a positive whole number it is assumed to
!!       be a binary, hexadecimal, or octal value. If the string contains
!!       commas they are removed. If the string is of the form NN:MMM... or
!!       NN#MMM then NN is assumed to be the base of the whole number.
!!
!!       if an error occurs in the READ, IOSTAT is returned in IERR and
!!       value is set to zero. if no error occurs, IERR=0.
!!##OPTIONS
!!       CHARS  input string to read numeric value from
!!##RETURNS
!!       VALU   numeric value returned. May be INTEGER, REAL, or DOUBLEPRECISION.
!!       IERR   error flag (0 == no error)
!!##EXAMPLE
!!
!! Sample Program:
!!
!!      program demo_string_to_value
!!      use M_strings, only: string_to_value
!!      character(len=80) :: string
!!         string=' -40.5e-2 '
!!         call string_to_value(string,value,ierr)
!!         write(*,*) 'value of string ['//trim(string)//'] is ',value
!!      end program demo_string_to_value
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
!----------------------------------------------------------------------------------------------------------------------------------
subroutine a2i(chars,valu,ierr)

! ident_23="@(#)M_strings::a2i(3fp): subroutine returns integer value from string"

character(len=*),intent(in) :: chars                      ! input string
integer,intent(out)         :: valu                       ! value read from input string
integer,intent(out)         :: ierr                       ! error flag (0 == no error)
doubleprecision             :: valu8
   valu8=0.0d0
   call a2d(chars,valu8,ierr,onerr=0.0d0)
   if(valu8.le.huge(valu))then
      if(valu8.le.huge(valu))then
         valu=int(valu8)
      else
         call journal('sc','*a2i*','- value too large',valu8,'>',huge(valu))
         valu=huge(valu)
         ierr=-1
      endif
   endif
end subroutine a2i
!----------------------------------------------------------------------------------------------------------------------------------
subroutine a2d(chars,valu,ierr,onerr)

! ident_24="@(#)M_strings::a2d(3fp): subroutine returns double value from string"

!     1989,2016 John S. Urban.
!
!  o  works with any g-format input, including integer, real, and exponential.
!  o  if an error occurs in the read, iostat is returned in ierr and value is set to zero.  if no error occurs, ierr=0.
!  o  if the string happens to be 'eod' no error message is produced so this string may be used to act as an end-of-data.
!     IERR will still be non-zero in this case.
!----------------------------------------------------------------------------------------------------------------------------------
character(len=*),intent(in)  :: chars                        ! input string
character(len=:),allocatable :: local_chars
doubleprecision,intent(out)  :: valu                         ! value read from input string
integer,intent(out)          :: ierr                         ! error flag (0 == no error)
class(*),optional,intent(in) :: onerr
!----------------------------------------------------------------------------------------------------------------------------------
character(len=*),parameter   :: fmt="('(bn,g',i5,'.0)')"     ! format used to build frmt
character(len=15)            :: frmt                         ! holds format built to read input string
character(len=256)           :: msg                          ! hold message from I/O errors
integer                      :: intg
integer                      :: pnd
integer                      :: basevalue, ivalu
character(len=3),save        :: nan_string='NaN'
!----------------------------------------------------------------------------------------------------------------------------------
   ierr=0                                                       ! initialize error flag to zero
   local_chars=chars
   msg=''
   if(len(local_chars).eq.0)local_chars=' '
   call substitute(local_chars,',','')                          ! remove any comma characters
   pnd=scan(local_chars,'#:')
   if(pnd.ne.0)then
      write(frmt,fmt)pnd-1                                      ! build format of form '(BN,Gn.0)'
      read(local_chars(:pnd-1),fmt=frmt,iostat=ierr,iomsg=msg)basevalue   ! try to read value from string
      if(decodebase(local_chars(pnd+1:),basevalue,ivalu))then
         valu=real(ivalu,kind=kind(0.0d0))
      else
         valu=0.0d0
         ierr=-1
      endif
   else
      select case(local_chars(1:1))
      case('z','Z','h','H')                                     ! assume hexadecimal
         frmt='(Z'//v2s(len(local_chars))//')'
         read(local_chars(2:),frmt,iostat=ierr,iomsg=msg)intg
         valu=dble(intg)
      case('b','B')                                             ! assume binary (base 2)
         frmt='(B'//v2s(len(local_chars))//')'
         read(local_chars(2:),frmt,iostat=ierr,iomsg=msg)intg
         valu=dble(intg)
      case('o','O')                                             ! assume octal
         frmt='(O'//v2s(len(local_chars))//')'
         read(local_chars(2:),frmt,iostat=ierr,iomsg=msg)intg
         valu=dble(intg)
      case default
         write(frmt,fmt)len(local_chars)                        ! build format of form '(BN,Gn.0)'
         read(local_chars,fmt=frmt,iostat=ierr,iomsg=msg)valu   ! try to read value from string
      end select
   endif
   if(ierr.ne.0)then                                            ! if an error occurred ierr will be non-zero.
      if(present(onerr))then
         select type(onerr)
         type is (integer)
            valu=onerr
         type is (real)
            valu=onerr
         type is (doubleprecision)
            valu=onerr
         end select
      else                                                      ! set return value to NaN
         read(nan_string,'(g3.3)')valu
      endif
      if(local_chars.ne.'eod')then                           ! print warning message except for special value "eod"
         call journal('sc','*a2d* - cannot produce number from string ['//trim(chars)//']')
         if(msg.ne.'')then
            call journal('sc','*a2d* - ['//trim(msg)//']')
         endif
      endif
   endif
end subroutine a2d
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
pure elemental function isupper(ch) result(res)

! ident_25="@(#)M_strings::isupper(3f): returns true if character is an uppercase letter (A-Z)"

character,intent(in) :: ch
logical              :: res
   select case(ch)
   case('A':'Z')
     res=.true.
   case default
     res=.false.
   end select
end function isupper
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    split(3f) - [M_strings:TOKENS] parse string into an array using specified delimiters
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    subroutine split(input_line,array,delimiters,order,nulls)
!!
!!     character(len=*),intent(in)              :: input_line
!!     character(len=:),allocatable,intent(out) :: array(:)
!!     character(len=*),optional,intent(in)     :: delimiters
!!     character(len=*),optional,intent(in)     :: order
!!     character(len=*),optional,intent(in)     :: nulls
!!##DESCRIPTION
!!     SPLIT(3f) parses a string using specified delimiter characters and
!!     store tokens into an allocatable array
!!
!!##OPTIONS
!!
!!    INPUT_LINE  Input string to tokenize
!!
!!    ARRAY       Output array of tokens
!!
!!    DELIMITERS  List of delimiter characters.
!!                The default delimiters are the "whitespace" characters
!!                (space, tab,new line, vertical tab, formfeed, carriage
!!                return, and null). You may specify an alternate set of
!!                delimiter characters.
!!
!!                Multi-character delimiters are not supported (Each
!!                character in the DELIMITERS list is considered to be
!!                a delimiter).
!!
!!                Quoting of delimiter characters is not supported.
!!
!!    ORDER SEQUENTIAL|REVERSE|RIGHT  Order of output array.
!!                By default ARRAY contains the tokens having parsed
!!                the INPUT_LINE from left to right. If ORDER='RIGHT'
!!                or ORDER='REVERSE' the parsing goes from right to left.
!!
!!    NULLS IGNORE|RETURN|IGNOREEND  Treatment of null fields.
!!                By default adjacent delimiters in the input string
!!                do not create an empty string in the output array. if
!!                NULLS='return' adjacent delimiters create an empty element
!!                in the output ARRAY. If NULLS='ignoreend' then only
!!                trailing delimiters at the right of the string are ignored.
!!
!!##EXAMPLES
!!
!! Sample program:
!!
!!     program demo_split
!!     use M_strings, only: split
!!     character(len=*),parameter     :: &
!!     & line='  aBcdef   ghijklmnop qrstuvwxyz  1:|:2     333|333 a B cc    '
!!     character(len=:),allocatable :: array(:) ! output array of tokens
!!        write(*,*)'INPUT LINE:['//LINE//']'
!!        write(*,'(80("="))')
!!        write(*,*)'typical call:'
!!        CALL split(line,array)
!!        write(*,'(i0," ==> ",a)')(i,trim(array(i)),i=1,size(array))
!!        write(*,*)'SIZE:',SIZE(array)
!!        write(*,'(80("-"))')
!!        write(*,*)'custom list of delimiters (colon and vertical line):'
!!        CALL split(line,array,delimiters=':|',order='sequential',nulls='ignore')
!!        write(*,'(i0," ==> ",a)')(i,trim(array(i)),i=1,size(array))
!!        write(*,*)'SIZE:',SIZE(array)
!!        write(*,'(80("-"))')
!!        write(*,*)&
!!      &'custom list of delimiters, reverse array order and count null fields:'
!!        CALL split(line,array,delimiters=':|',order='reverse',nulls='return')
!!        write(*,'(i0," ==> ",a)')(i,trim(array(i)),i=1,size(array))
!!        write(*,*)'SIZE:',SIZE(array)
!!        write(*,'(80("-"))')
!!        write(*,*)'INPUT LINE:['//LINE//']'
!!        write(*,*)&
!!        &'default delimiters and reverse array order and return null fields:'
!!        CALL split(line,array,delimiters='',order='reverse',nulls='return')
!!        write(*,'(i0," ==> ",a)')(i,trim(array(i)),i=1,size(array))
!!        write(*,*)'SIZE:',SIZE(array)
!!     end program demo_split
!!
!!   Output
!!
!!    > INPUT LINE:[  aBcdef   ghijklmnop qrstuvwxyz  1:|:2     333|333 a B cc    ]
!!    > ===========================================================================
!!    >  typical call:
!!    > 1 ==> aBcdef
!!    > 2 ==> ghijklmnop
!!    > 3 ==> qrstuvwxyz
!!    > 4 ==> 1:|:2
!!    > 5 ==> 333|333
!!    > 6 ==> a
!!    > 7 ==> B
!!    > 8 ==> cc
!!    >  SIZE:           8
!!    > --------------------------------------------------------------------------
!!    >  custom list of delimiters (colon and vertical line):
!!    > 1 ==>   aBcdef   ghijklmnop qrstuvwxyz  1
!!    > 2 ==> 2     333
!!    > 3 ==> 333 a B cc
!!    >  SIZE:           3
!!    > --------------------------------------------------------------------------
!!    >  custom list of delimiters, reverse array order and return null fields:
!!    > 1 ==> 333 a B cc
!!    > 2 ==> 2     333
!!    > 3 ==>
!!    > 4 ==>
!!    > 5 ==>   aBcdef   ghijklmnop qrstuvwxyz  1
!!    >  SIZE:           5
!!    > --------------------------------------------------------------------------
!!    >  INPUT LINE:[  aBcdef   ghijklmnop qrstuvwxyz  1:|:2     333|333 a B cc    ]
!!    >  default delimiters and reverse array order and count null fields:
!!    > 1 ==>
!!    > 2 ==>
!!    > 3 ==>
!!    > 4 ==> cc
!!    > 5 ==> B
!!    > 6 ==> a
!!    > 7 ==> 333|333
!!    > 8 ==>
!!    > 9 ==>
!!    > 10 ==>
!!    > 11 ==>
!!    > 12 ==> 1:|:2
!!    > 13 ==>
!!    > 14 ==> qrstuvwxyz
!!    > 15 ==> ghijklmnop
!!    > 16 ==>
!!    > 17 ==>
!!    > 18 ==> aBcdef
!!    > 19 ==>
!!    > 20 ==>
!!    >  SIZE:          20
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine split(input_line,array,delimiters,order,nulls)
!-----------------------------------------------------------------------------------------------------------------------------------

! ident_26="@(#)M_strings::split(3f): parse string on delimiter characters and store tokens into an allocatable array"

!  John S. Urban
!-----------------------------------------------------------------------------------------------------------------------------------
intrinsic index, min, present, len
!-----------------------------------------------------------------------------------------------------------------------------------
!  given a line of structure " par1 par2 par3 ... parn " store each par(n) into a separate variable in array.
!    o by default adjacent delimiters in the input string do not create an empty string in the output array
!    o no quoting of delimiters is supported
character(len=*),intent(in)              :: input_line  ! input string to tokenize
character(len=*),optional,intent(in)     :: delimiters  ! list of delimiter characters
character(len=*),optional,intent(in)     :: order       ! order of output array sequential|[reverse|right]
character(len=*),optional,intent(in)     :: nulls       ! return strings composed of delimiters or not ignore|return|ignoreend
character(len=:),allocatable,intent(out) :: array(:)    ! output array of tokens
!-----------------------------------------------------------------------------------------------------------------------------------
integer                       :: n                      ! max number of strings INPUT_LINE could split into if all delimiter
integer,allocatable           :: ibegin(:)              ! positions in input string where tokens start
integer,allocatable           :: iterm(:)               ! positions in input string where tokens end
character(len=:),allocatable  :: dlim                   ! string containing delimiter characters
character(len=:),allocatable  :: ordr                   ! string containing order keyword
character(len=:),allocatable  :: nlls                   ! string containing nulls keyword
integer                       :: ii,iiii                ! loop parameters used to control print order
integer                       :: icount                 ! number of tokens found
integer                       :: ilen                   ! length of input string with trailing spaces trimmed
integer                       :: i10,i20,i30            ! loop counters
integer                       :: icol                   ! pointer into input string as it is being parsed
integer                       :: idlim                  ! number of delimiter characters
integer                       :: ifound                 ! where next delimiter character is found in remaining input string data
integer                       :: inotnull               ! count strings not composed of delimiters
integer                       :: ireturn                ! number of tokens returned
integer                       :: imax                   ! length of longest token
!-----------------------------------------------------------------------------------------------------------------------------------
   ! decide on value for optional DELIMITERS parameter
   if (present(delimiters)) then                                     ! optional delimiter list was present
      if(delimiters.ne.'')then                                       ! if DELIMITERS was specified and not null use it
         dlim=delimiters
      else                                                           ! DELIMITERS was specified on call as empty string
         dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0) ! use default delimiter when not specified
      endif
   else                                                              ! no delimiter value was specified
      dlim=' '//char(9)//char(10)//char(11)//char(12)//char(13)//char(0)    ! use default delimiter when not specified
   endif
   idlim=len(dlim)                                                   ! dlim a lot of blanks on some machines if dlim is a big string
!-----------------------------------------------------------------------------------------------------------------------------------
   if(present(order))then; ordr=lower(adjustl(order)); else; ordr='sequential'; endif ! decide on value for optional ORDER parameter
   if(present(nulls))then; nlls=lower(adjustl(nulls)); else; nlls='ignore'    ; endif ! optional parameter
!-----------------------------------------------------------------------------------------------------------------------------------
   n=len(input_line)+1                        ! max number of strings INPUT_LINE could split into if all delimiter
   allocate(ibegin(n))                        ! allocate enough space to hold starting location of tokens if string all tokens
   allocate(iterm(n))                         ! allocate enough space to hold ending location of tokens if string all tokens
   ibegin(:)=1
   iterm(:)=1
!-----------------------------------------------------------------------------------------------------------------------------------
   ilen=len(input_line)                                           ! ILEN is the column position of the last non-blank character
   icount=0                                                       ! how many tokens found
   inotnull=0                                                     ! how many tokens found not composed of delimiters
   imax=0                                                         ! length of longest token found
!-----------------------------------------------------------------------------------------------------------------------------------
   select case (ilen)
!-----------------------------------------------------------------------------------------------------------------------------------
   case (:0)                                                      ! command was totally blank
!-----------------------------------------------------------------------------------------------------------------------------------
   case default                                                   ! there is at least one non-delimiter in INPUT_LINE if get here
      icol=1                                                      ! initialize pointer into input line
      INFINITE: do i30=1,ilen,1                                   ! store into each array element
         ibegin(i30)=icol                                         ! assume start new token on the character
         if(index(dlim(1:idlim),input_line(icol:icol)).eq.0)then  ! if current character is not a delimiter
            iterm(i30)=ilen                                       ! initially assume no more tokens
            do i10=1,idlim                                        ! search for next delimiter
               ifound=index(input_line(ibegin(i30):ilen),dlim(i10:i10))
               IF(ifound.gt.0)then
                  iterm(i30)=min(iterm(i30),ifound+ibegin(i30)-2)
               endif
            enddo
            icol=iterm(i30)+2                                     ! next place to look as found end of this token
            inotnull=inotnull+1                                   ! increment count of number of tokens not composed of delimiters
         else                                                     ! character is a delimiter for a null string
            iterm(i30)=icol-1                                     ! record assumed end of string. Will be less than beginning
            icol=icol+1                                           ! advance pointer into input string
         endif
         imax=max(imax,iterm(i30)-ibegin(i30)+1)
         icount=i30                                               ! increment count of number of tokens found
         if(icol.gt.ilen)then                                     ! no text left
            exit INFINITE
         endif
      enddo INFINITE
!-----------------------------------------------------------------------------------------------------------------------------------
   end select
!-----------------------------------------------------------------------------------------------------------------------------------
   select case (trim(adjustl(nlls)))
   case ('ignore','','ignoreend')
      ireturn=inotnull
   case default
      ireturn=icount
   end select
   allocate(character(len=imax) :: array(ireturn))                ! allocate the array to return
   !allocate(array(ireturn))                                       ! allocate the array to turn
!-----------------------------------------------------------------------------------------------------------------------------------
   select case (trim(adjustl(ordr)))                              ! decide which order to store tokens
   case ('reverse','right') ; ii=ireturn ; iiii=-1                ! last to first
   case default             ; ii=1       ; iiii=1                 ! first to last
   end select
!-----------------------------------------------------------------------------------------------------------------------------------
   do i20=1,icount                                                ! fill the array with the tokens that were found
      if(iterm(i20).lt.ibegin(i20))then
         select case (trim(adjustl(nlls)))
         case ('ignore','','ignoreend')
         case default
            array(ii)=' '
            ii=ii+iiii
         end select
      else
         array(ii)=input_line(ibegin(i20):iterm(i20))
         ii=ii+iiii
      endif
   enddo
!-----------------------------------------------------------------------------------------------------------------------------------
   end subroutine split
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    replace_str(3f) - [M_strings:EDITING] function globally replaces one substring for another in string
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    function replace_str(targetline[,old,new|cmd],range,ierr) result (newline)
!!
!!     character(len=*)                       :: targetline
!!     character(len=*),intent(in),optional   :: old
!!     character(len=*),intent(in),optional   :: new
!!     character(len=*),intent(in),optional   :: cmd
!!     integer,intent(in),optional            :: range(2)
!!     integer,intent(out),optional           :: ierr
!!     logical,intent(in),optional            :: clip
!!     character(len=:),allocatable           :: newline
!!##DESCRIPTION
!!    Globally replace one substring for another in string.
!!    Either CMD or OLD and NEW must be specified.
!!
!!##OPTIONS
!!     targetline  input line to be changed
!!     old         old substring to replace
!!     new         new substring
!!     cmd         alternate way to specify old and new string, in
!!                 the form c/old/new/; where "/" can be any character
!!                 not in "old" or "new"
!!     range       if present, only change range(1) to range(2) of occurrences of old string
!!     ierr        error code. iF ier = -1 bad directive, >= 0 then
!!                 count of changes made
!!     clip        whether to return trailing spaces or not. Defaults to .false.
!!##RETURNS
!!     newline     allocatable string returned
!!
!!##EXAMPLES
!!
!! Sample Program:
!!
!!       program demo_replace_str
!!       use M_strings, only : replace_str
!!       implicit none
!!       character(len=:),allocatable :: targetline
!!
!!       targetline='this is the input string'
!!
!!       call testit('th','TH','THis is THe input string')
!!
!!       ! a null old substring means "at beginning of line"
!!       call testit('','BEFORE:', 'BEFORE:THis is THe input string')
!!
!!       ! a null new string deletes occurrences of the old substring
!!       call testit('i','', 'BEFORE:THs s THe nput strng')
!!
!!       write(*,*)'Examples of the use of RANGE='
!!
!!       targetline=replace_str('a b ab baaa aaaa','a','A')
!!       write(*,*)'replace a with A ['//targetline//']'
!!
!!       targetline=replace_str('a b ab baaa aaaa','a','A',range=[3,5])
!!       write(*,*)'replace a with A instances 3 to 5 ['//targetline//']'
!!
!!       targetline=replace_str('a b ab baaa aaaa','a','',range=[3,5])
!!       write(*,*)'replace a with null instances 3 to 5 ['//targetline//']'
!!
!!       targetline=replace_str('a b ab baaa aaaa aa aa a a a aa aaaaaa','aa','CCCC',range=[3,5])
!!       write(*,*)'replace aa with CCCC instances 3 to 5 ['//targetline//']'
!!
!!       contains
!!       subroutine testit(old,new,expected)
!!       character(len=*),intent(in) :: old,new,expected
!!       write(*,*)repeat('=',79)
!!       write(*,*)':STARTED ['//targetline//']'
!!       write(*,*)':OLD['//old//']', ' NEW['//new//']'
!!       targetline=replace_str(targetline,old,new)
!!       write(*,*)':GOT     ['//targetline//']'
!!       write(*,*)':EXPECTED['//expected//']'
!!       write(*,*)':TEST    [',targetline.eq.expected,']'
!!       end subroutine testit
!!
!!       end program demo_replace_str
!!
!!   Expected output
!!
!!     ===============================================================================
!!     STARTED [this is the input string]
!!     OLD[th] NEW[TH]
!!     GOT     [THis is THe input string]
!!     EXPECTED[THis is THe input string]
!!     TEST    [ T ]
!!     ===============================================================================
!!     STARTED [THis is THe input string]
!!     OLD[] NEW[BEFORE:]
!!     GOT     [BEFORE:THis is THe input string]
!!     EXPECTED[BEFORE:THis is THe input string]
!!     TEST    [ T ]
!!     ===============================================================================
!!     STARTED [BEFORE:THis is THe input string]
!!     OLD[i] NEW[]
!!     GOT     [BEFORE:THs s THe nput strng]
!!     EXPECTED[BEFORE:THs s THe nput strng]
!!     TEST    [ T ]
!!     Examples of the use of RANGE=
!!     replace a with A [A b Ab bAAA AAAA]
!!     replace a with A instances 3 to 5 [a b ab bAAA aaaa]
!!     replace a with null instances 3 to 5 [a b ab b aaaa]
!!     replace aa with CCCC instances 3 to 5 [a b ab baaa aaCCCC CCCC CCCC a a a aa aaaaaa]
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine crack_cmd(cmd,old,new,ierr)
!-----------------------------------------------------------------------------------------------------------------------------------
character(len=*),intent(in)              :: cmd
character(len=:),allocatable,intent(out) :: old,new                ! scratch string buffers
integer                                  :: ierr
!-----------------------------------------------------------------------------------------------------------------------------------
character(len=1)                         :: delimiters
integer                                  :: itoken
integer,parameter                        :: id=2                   ! expected location of delimiter
logical                                  :: ifok
integer                                  :: lmax                   ! length of target string
integer                                  :: start_token,end_token
!-----------------------------------------------------------------------------------------------------------------------------------
   ierr=0
   old=''
   new=''
   lmax=len_trim(cmd)                       ! significant length of change directive

   if(lmax.ge.4)then                      ! strtok ignores blank tokens so look for special case where first token is really null
      delimiters=cmd(id:id)               ! find delimiter in expected location
      itoken=0                            ! initialize strtok(3f) procedure

      if(strtok(cmd(id:),itoken,start_token,end_token,delimiters)) then        ! find OLD string
         old=cmd(start_token+id-1:end_token+id-1)
      else
         old=''
      endif

      if(cmd(id:id).eq.cmd(id+1:id+1))then
         new=old
         old=''
      else                                                                     ! normal case
         ifok=strtok(cmd(id:),itoken,start_token,end_token,delimiters)         ! find NEW string
         if(end_token .eq. (len(cmd)-id+1) )end_token=len_trim(cmd(id:))       ! if missing ending delimiter
         new=cmd(start_token+id-1:min(end_token+id-1,lmax))
      endif
   else                                                                        ! command was two or less characters
      ierr=-1
      call journal('sc','*crack_cmd* incorrect change directive -too short')
   endif

end subroutine crack_cmd
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
function replace_str(targetline,old,new,ierr,cmd,range) result (newline)

! ident_27="@(#)M_strings::replace_str(3f): Globally replace one substring for another in string"

!-----------------------------------------------------------------------------------------------------------------------------------
! parameters
character(len=*),intent(in)            :: targetline   ! input line to be changed
character(len=*),intent(in),optional   :: old          ! old substring to replace
character(len=*),intent(in),optional   :: new          ! new substring
integer,intent(out),optional           :: ierr         ! error code. if ierr = -1 bad directive, >=0 then ierr changes made
character(len=*),intent(in),optional   :: cmd          ! contains the instructions changing the string
integer,intent(in),optional            :: range(2)     ! start and end of which changes to make
!-----------------------------------------------------------------------------------------------------------------------------------
! returns
character(len=:),allocatable  :: newline               ! output string buffer
!-----------------------------------------------------------------------------------------------------------------------------------
! local
character(len=:),allocatable  :: new_local, old_local
integer                       :: icount,ichange,ier2
integer                       :: original_input_length
integer                       :: len_old, len_new
integer                       :: ladd
integer                       :: left_margin, right_margin
integer                       :: ind
integer                       :: ic
integer                       :: ichar
integer                       :: range_local(2)
!-----------------------------------------------------------------------------------------------------------------------------------
!  get old_local and new_local from cmd or old and new
   if(present(cmd))then
      call crack_cmd(cmd,old_local,new_local,ier2)
      if(ier2.ne.0)then
         newline=targetline  ! if no changes are made return original string on error
         if(present(ierr))ierr=ier2
         return
      endif
   elseif(present(old).and.present(new))then
      old_local=old
      new_local=new
   else
      newline=targetline  ! if no changes are made return original string on error
      call journal('sc','*replace_str* must specify OLD and NEW or CMD')
      return
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   icount=0                                            ! initialize error flag/change count
   ichange=0                                           ! initialize error flag/change count
   original_input_length=len_trim(targetline)          ! get non-blank length of input line
   len_old=len(old_local)                              ! length of old substring to be replaced
   len_new=len(new_local)                              ! length of new substring to replace old substring
   left_margin=1                                       ! left_margin is left margin of window to change
   right_margin=len(targetline)                        ! right_margin is right margin of window to change
   newline=''                                          ! begin with a blank line as output string
!-----------------------------------------------------------------------------------------------------------------------------------
   if(present(range))then
      range_local=range
   else
      range_local=[1,original_input_length]
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   if(len_old.eq.0)then                                ! c//new/ means insert new at beginning of line (or left margin)
      ichar=len_new + original_input_length
      if(len_new.gt.0)then
         newline=new_local(:len_new)//targetline(left_margin:original_input_length)
      else
         newline=targetline(left_margin:original_input_length)
      endif
      ichange=1                                        ! made one change. actually, c/// should maybe return 0
      if(present(ierr))ierr=ichange
      return
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   ichar=left_margin                                   ! place to put characters into output string
   ic=left_margin                                      ! place looking at in input string
   loop: do
      ind=index(targetline(ic:),old_local(:len_old))+ic-1 ! try finding start of OLD in remaining part of input in change window
      if(ind.eq.ic-1.or.ind.gt.right_margin)then          ! did not find old string or found old string past edit window
         exit loop                                        ! no more changes left to make
      endif
      icount=icount+1                                  ! found an old string to change, so increment count of change candidates
      if(ind.gt.ic)then                                ! if found old string past at current position in input string copy unchanged
         ladd=ind-ic                                   ! find length of character range to copy as-is from input to output
         newline=newline(:ichar-1)//targetline(ic:ind-1)
         ichar=ichar+ladd
      endif
      if(icount.ge.range_local(1).and.icount.le.range_local(2))then    ! check if this is an instance to change or keep
         ichange=ichange+1
         if(len_new.ne.0)then                                          ! put in new string
            newline=newline(:ichar-1)//new_local(:len_new)
            ichar=ichar+len_new
         endif
      else
         if(len_old.ne.0)then                                          ! put in copy of old string
            newline=newline(:ichar-1)//old_local(:len_old)
            ichar=ichar+len_old
         endif
      endif
      ic=ind+len_old
   enddo loop
!-----------------------------------------------------------------------------------------------------------------------------------
   select case (ichange)
   case (0)                                            ! there were no changes made to the window
      newline=targetline                               ! if no changes made output should be input
   case default
      if(ic.le.len(targetline))then                    ! if there is more after last change on original line add it
         newline=newline(:ichar-1)//targetline(ic:max(ic,original_input_length))
      endif
   end select
   if(present(ierr))ierr=ichange
!-----------------------------------------------------------------------------------------------------------------------------------
end function replace_str
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!     quote(3f) - [M_strings:QUOTES] add quotes to string as if written with list-directed input
!!     (LICENSE:PD)
!!##SYNOPSIS
!!
!!   function quote(str,mode,clip) result (quoted_str)
!!
!!    character(len=*),intent(in)          :: str
!!    character(len=*),optional,intent(in) :: mode
!!    logical,optional,intent(in)          :: clip
!!    character(len=:),allocatable         :: quoted_str
!!##DESCRIPTION
!!    Add quotes to a CHARACTER variable as if it was written using
!!    list-directed input. This is particularly useful for processing
!!    strings to add to CSV files.
!!
!!##OPTIONS
!!    str         input string to add quotes to, using the rules of
!!                list-directed input (single quotes are replaced by two adjacent quotes)
!!    mode        alternate quoting methods are supported:
!!
!!                   DOUBLE   default. replace quote with double quotes
!!                   ESCAPE   replace quotes with backslash-quote instead of double quotes
!!
!!    clip        default is to trim leading and trailing spaces from the string. If CLIP
!!                is .FALSE. spaces are not trimmed
!!
!!##RESULT
!!    quoted_str  The output string, which is based on adding quotes to STR.
!!##EXAMPLE
!!
!! Sample program:
!!
!!     program demo_quote
!!     use M_strings, only : quote
!!     implicit none
!!     character(len=:),allocatable :: str
!!     character(len=1024)          :: msg
!!     integer                      :: ios
!!     character(len=80)            :: inline
!!        do
!!           write(*,'(a)',advance='no')'Enter test string:'
!!           read(*,'(a)',iostat=ios,iomsg=msg)inline
!!           if(ios.ne.0)then
!!              write(*,*)trim(inline)
!!              exit
!!           endif
!!
!!           ! the original string
!!           write(*,'(a)')'ORIGINAL     ['//trim(inline)//']'
!!
!!           ! the string processed by quote(3f)
!!           str=quote(inline)
!!           write(*,'(a)')'QUOTED     ['//str//']'
!!
!!           ! write the string list-directed to compare the results
!!           write(*,'(a)',iostat=ios,iomsg=msg) 'LIST DIRECTED:'
!!           write(*,*,iostat=ios,iomsg=msg,delim='none') inline
!!           write(*,*,iostat=ios,iomsg=msg,delim='quote') inline
!!           write(*,*,iostat=ios,iomsg=msg,delim='apostrophe') inline
!!        enddo
!!     end program demo_quote
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function quote(str,mode,clip) result (quoted_str)
character(len=*),intent(in)          :: str                ! the string to be quoted
character(len=*),optional,intent(in) :: mode
logical,optional,intent(in)          :: clip
character(len=:),allocatable         :: quoted_str

character(len=1),parameter           :: double_quote = '"'
character(len=20)                    :: local_mode
!-----------------------------------------------------------------------------------------------------------------------------------
   local_mode=merge_str(mode,'DOUBLE',present(mode))
   if(merge(clip,.false.,present(clip)))then
      quoted_str=adjustl(str)
   else
      quoted_str=str
   endif
   select case(lower(local_mode))
   case('double')
      quoted_str=double_quote//trim(replace_str(quoted_str,'"','""'))//double_quote
   case('escape')
      quoted_str=double_quote//trim(replace_str(quoted_str,'"','\"'))//double_quote
   case default
      call journal('sc','*quote* ERROR: unknown quote mode ',local_mode)
      quoted_str=str
   end select
!-----------------------------------------------------------------------------------------------------------------------------------
end function quote
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!     unquote(3f) - [M_strings:QUOTES] remove quotes from string as if read with list-directed input
!!     (LICENSE:PD)
!!##SYNOPSIS
!!
!!   function unquote(quoted_str,esc) result (unquoted_str)
!!
!!    character(len=*),intent(in)          :: quoted_str
!!    character(len=1),optional,intent(in) :: esc
!!    character(len=:),allocatable         :: unquoted_str
!!##DESCRIPTION
!!    Remove quotes from a CHARACTER variable as if it was read using
!!    list-directed input. This is particularly useful for processing
!!    tokens read from input such as CSV files.
!!
!!    Fortran can now read using list-directed input from an internal file,
!!    which should handle quoted strings, but list-directed input does not
!!    support escape characters, which UNQUOTE(3f) does.
!!##OPTIONS
!!    quoted_str  input string to remove quotes from, using the rules of
!!                list-directed input (two adjacent quotes inside a quoted
!!                region are replaced by a single quote, a single quote or
!!                double quote is selected as the delimiter based on which
!!                is encountered first going from left to right, ...)
!!    esc         optional character used to protect the next quote
!!                character from being processed as a quote, but simply as
!!                a plain character.
!!##RESULT
!!    unquoted_str  The output string, which is based on removing quotes from quoted_str.
!!##EXAMPLE
!!
!! Sample program:
!!
!!       program demo_unquote
!!       use M_strings, only : unquote
!!       implicit none
!!       character(len=128)           :: quoted_str
!!       character(len=:),allocatable :: unquoted_str
!!       character(len=1),parameter   :: esc='\'
!!       character(len=1024)          :: msg
!!       integer                      :: ios
!!       character(len=1024)          :: dummy
!!       do
!!          write(*,'(a)',advance='no')'Enter test string:'
!!          read(*,'(a)',iostat=ios,iomsg=msg)quoted_str
!!          if(ios.ne.0)then
!!             write(*,*)trim(msg)
!!             exit
!!          endif
!!
!!          ! the original string
!!          write(*,'(a)')'QUOTED       ['//trim(quoted_str)//']'
!!
!!          ! the string processed by unquote(3f)
!!          unquoted_str=unquote(trim(quoted_str),esc)
!!          write(*,'(a)')'UNQUOTED     ['//unquoted_str//']'
!!
!!          ! read the string list-directed to compare the results
!!          read(quoted_str,*,iostat=ios,iomsg=msg)dummy
!!          if(ios.ne.0)then
!!             write(*,*)trim(msg)
!!          else
!!             write(*,'(a)')'LIST DIRECTED['//trim(dummy)//']'
!!          endif
!!       enddo
!!       end program demo_unquote
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function unquote(quoted_str,esc) result (unquoted_str)
character(len=*),intent(in)          :: quoted_str              ! the string to be unquoted
character(len=1),optional,intent(in) :: esc                     ! escape character
character(len=:),allocatable         :: unquoted_str
integer                              :: inlen
character(len=1),parameter           :: single_quote = "'"
character(len=1),parameter           :: double_quote = '"'
integer                              :: quote                   ! whichever quote is to be used
integer                              :: before
integer                              :: current
integer                              :: iesc
integer                              :: iput
integer                              :: i
logical                              :: inside
!-----------------------------------------------------------------------------------------------------------------------------------
   if(present(esc))then                           ! select escape character as specified character or special value meaning not set
      iesc=ichar(esc)                             ! allow for an escape character
   else
      iesc=-1                                     ! set to value that matches no character
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   inlen=len(quoted_str)                          ! find length of input string
   allocate(character(len=inlen) :: unquoted_str) ! initially make output string length of input string
!-----------------------------------------------------------------------------------------------------------------------------------
   if(inlen.ge.1)then                             ! double_quote is the default quote unless the first character is single_quote
      if(quoted_str(1:1).eq.single_quote)then
         quote=ichar(single_quote)
      else
         quote=ichar(double_quote)
      endif
   else
      quote=ichar(double_quote)
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   before=-2                                      ! initially set previous character to impossible value
   unquoted_str(:)=''                             ! initialize output string to null string
   iput=1
   inside=.false.
   STEPTHROUGH: do i=1,inlen
      current=ichar(quoted_str(i:i))
      if(before.eq.iesc)then                      ! if previous character was escape use current character unconditionally
           iput=iput-1                            ! backup
           unquoted_str(iput:iput)=char(current)
           iput=iput+1
           before=-2                              ! this could be second esc or quote
      elseif(current.eq.quote)then                ! if current is a quote it depends on whether previous character was a quote
         if(before.eq.quote)then
           unquoted_str(iput:iput)=char(quote)    ! this is second quote so retain it
           iput=iput+1
           before=-2
         elseif(.not.inside.and.before.ne.iesc)then
            inside=.true.
         else                                     ! this is first quote so ignore it except remember it in case next is a quote
            before=current
         endif
      else
         unquoted_str(iput:iput)=char(current)
         iput=iput+1
         before=current
      endif
   enddo STEPTHROUGH
!-----------------------------------------------------------------------------------------------------------------------------------
   unquoted_str=unquoted_str(:iput-1)
!-----------------------------------------------------------------------------------------------------------------------------------
end function unquote
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      v2s(3f) - [M_strings:NUMERIC] return numeric string from a numeric value
!!      (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!       function v2s(value) result(outstr)
!!
!!        integer|real|doubleprecision|logical,intent(in ) :: value
!!        character(len=:),allocatable :: outstr
!!        character(len=*),optional,intent(in) :: fmt
!!
!!##DESCRIPTION
!!
!!    v2s(3f) returns a representation of a numeric value as a
!!    string when given a numeric value of type REAL, DOUBLEPRECISION,
!!    INTEGER or LOGICAL. It creates the strings using internal WRITE()
!!    statements. Trailing zeros are removed from non-zero values, and the
!!    string is left-justified.
!!
!!##OPTIONS
!!    VALUE   input value to be converted to a string
!!    FMT     format can be explicitly given, but is limited to
!!            generating a string of eighty or less characters.
!!
!!##RETURNS
!!    OUTSTR  returned string representing input value,
!!
!!##EXAMPLE
!!
!! Sample Program:
!!
!!     program demo_v2s
!!     use M_strings, only: v2s
!!     write(*,*) 'The value of 3.0/4.0 is ['//v2s(3.0/4.0)//']'
!!     write(*,*) 'The value of 1234    is ['//v2s(1234)//']'
!!     write(*,*) 'The value of 0d0     is ['//v2s(0d0)//']'
!!     write(*,*) 'The value of .false. is ['//v2s(.false.)//']'
!!     write(*,*) 'The value of .true. is  ['//v2s(.true.)//']'
!!     end program demo_v2s
!!
!!   Expected output
!!
!!     The value of 3.0/4.0 is [0.75]
!!     The value of 1234    is [1234]
!!     The value of 0d0     is [0]
!!     The value of .false. is [F]
!!     The value of .true. is  [T]
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
!===================================================================================================================================
function i2s(ivalue,fmt) result(outstr)

! ident_28="@(#)M_strings::i2s(3fp): private function returns string given integer value"

integer,intent(in)           :: ivalue                         ! input value to convert to a string
character(len=*),intent(in),optional :: fmt
character(len=:),allocatable :: outstr                         ! output string to generate
character(len=80)            :: string
   if(present(fmt))then
      call value_to_string(ivalue,string,fmt=fmt)
   else
      call value_to_string(ivalue,string)
   endif
   outstr=trim(string)
end function i2s
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    merge_str(3f) - [M_strings:LENGTH] pads strings to same length and then calls MERGE(3f)
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    function merge_str(str1,str2,expr) result(strout)
!!
!!     character(len=*),intent(in),optional :: str1
!!     character(len=*),intent(in),optional :: str2
!!     logical,intent(in)              :: expr
!!     character(len=:),allocatable    :: strout
!!##DESCRIPTION
!!    merge_str(3f) pads the shorter of str1 and str2 to the longest length
!!    of str1 and str2 and then calls MERGE(padded_str1,padded_str2,expr).
!!    It trims trailing spaces off the result and returns the trimmed
!!    string. This makes it easier to call MERGE(3f) with strings, as
!!    MERGE(3f) requires the strings to be the same length.
!!
!!    NOTE: STR1 and STR2 are always required even though declared optional.
!!          this is so the call "STR_MERGE(A,B,present(A))" is a valid call.
!!          The parameters STR1 and STR2 when they are optional parameters
!!          can be passed to a procedure if the options are optional on the
!!          called procedure.
!!
!!##OPTIONS
!!    STR1    string to return if the logical expression EXPR is true
!!    STR2    string to return if the logical expression EXPR is false
!!    EXPR    logical expression to evaluate to determine whether to return
!!            STR1 when true, and STR2 when false.
!!##RESULT
!!     MERGE_STR  a trimmed string is returned that is otherwise the value
!!                of STR1 or STR2, depending on the logical expression EXPR.
!!
!!##EXAMPLES
!!
!! Sample Program:
!!
!!     program demo_merge_str
!!     use M_strings, only : merge_str
!!     implicit none
!!     character(len=:), allocatable :: answer
!!        answer=merge_str('first string', 'second string is longer',10.eq.10)
!!        write(*,'("[",a,"]")') answer
!!        answer=merge_str('first string', 'second string is longer',10.ne.10)
!!        write(*,'("[",a,"]")') answer
!!     end program demo_merge_str
!!
!!   Expected output
!!
!!     [first string]
!!     [second string is longer]
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function merge_str(str1,str2,expr) result(strout)
! for some reason the MERGE(3f) intrinsic requires the strings it compares to be of equal length
! make an alias for MERGE(3f) that makes the lengths the same before doing the comparison by padding the shorter one with spaces

! ident_29="@(#)M_strings::merge_str(3f): pads first and second arguments to MERGE(3f) to same length"

character(len=*),intent(in),optional :: str1
character(len=*),intent(in),optional :: str2
character(len=:),allocatable         :: str1_local
character(len=:),allocatable         :: str2_local
logical,intent(in)                   :: expr
character(len=:),allocatable         :: strout
integer                              :: big
   if(present(str2))then
      str2_local=str2
   else
      str2_local=''
   endif
   if(present(str1))then
      str1_local=str1
   else
      str1_local=''
   endif
   big=max(len(str1_local),len(str2_local))
   ! note: perhaps it would be better to warn or fail if an optional value that is not present is returned, instead of returning ''
   strout=trim(merge(lenset(str1_local,big),lenset(str2_local,big),expr))
end function merge_str
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!
!!    decodebase(3f) - [M_strings:BASE] convert whole number string in base [2-36] to base 10 number
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   logical function decodebase(string,basein,out10)
!!
!!    character(len=*),intent(in)  :: string
!!    integer,intent(in)           :: basein
!!    integer,intent(out)          :: out10
!!##DESCRIPTION
!!
!!    Convert a numeric string representing a whole number in base BASEIN
!!    to base 10. The function returns FALSE if BASEIN is not in the range
!!    [2..36] or if string STRING contains invalid characters in base BASEIN
!!    or if result OUT10 is too big
!!
!!    The letters A,B,...,Z represent 10,11,...,36 in the base > 10.
!!
!!##OPTIONS
!!    string   input string. It represents a whole number in
!!             the base specified by BASEIN unless BASEIN is set
!!             to zero. When BASEIN is zero STRING is assumed to
!!             be of the form BASE#VALUE where BASE represents
!!             the function normally provided by BASEIN.
!!    basein   base of input string; either 0 or from 2 to 36.
!!    out10    output value in base 10
!!
!!##EXAMPLE
!!
!! Sample program:
!!
!!      program demo_decodebase
!!      use M_strings, only : codebase, decodebase
!!      implicit none
!!      integer           :: ba,bd
!!      character(len=40) :: x,y
!!      integer           :: r
!!
!!      print *,' BASE CONVERSION'
!!      write(*,'("Start   Base (2 to 36): ")',advance='no'); read *, bd
!!      write(*,'("Arrival Base (2 to 36): ")',advance='no'); read *, ba
!!      INFINITE: do
!!         print *,''
!!         write(*,'("Enter number in start base: ")',advance='no'); read *, x
!!         if(x.eq.'0') exit INFINITE
!!         if(decodebase(x,bd,r)) then
!!            if(codebase(r,ba,y)) then
!!              write(*,'("In base ",I2,": ",A20)')  ba, y
!!            else
!!              print *,'Error in coding number.'
!!            endif
!!         else
!!            print *,'Error in decoding number.'
!!         endif
!!      enddo INFINITE
!!
!!      end program demo_decodebase
!!
!!##AUTHOR
!!    John S. Urban
!!
!!       Ref.: "Math matiques en Turbo-Pascal by
!!              M. Ducamp and A. Reverchon (2),
!!              Eyrolles, Paris, 1988".
!!
!!    based on a F90 Version By J-P Moreau (www.jpmoreau.fr)
!!
!!##LICENSE
!!    Public Domain
logical function decodebase(string,basein,out_baseten)
implicit none

! ident_30="@(#)M_strings::decodebase(3f): convert whole number string in base [2-36] to base 10 number"

character(len=*),intent(in)  :: string
integer,intent(in)           :: basein
integer,intent(out)          :: out_baseten

character(len=len(string))   :: string_local
integer           :: long, i, j, k
real              :: y
real              :: mult
character(len=1)  :: ch
real,parameter    :: XMAXREAL=real(huge(1))
integer           :: out_sign
integer           :: basein_local
integer           :: ipound
integer           :: ierr

  string_local=upper(trim(adjustl(string)))
  decodebase=.false.

  ipound=index(string_local,'#')                                       ! determine if in form [-]base#whole
  if(basein.eq.0.and.ipound.gt.1)then                                  ! split string into two values
     call string_to_value(string_local(:ipound-1),basein_local,ierr)   ! get the decimal value of the base
     string_local=string_local(ipound+1:)                              ! now that base is known make string just the value
     if(basein_local.ge.0)then                                         ! allow for a negative sign prefix
        out_sign=1
     else
        out_sign=-1
     endif
     basein_local=abs(basein_local)
  else                                                                 ! assume string is a simple positive value
     basein_local=abs(basein)
     out_sign=1
  endif

  out_baseten=0
  y=0.0
  ALL: if(basein_local<2.or.basein_local>36) then
    print *,'(*decodebase* ERROR: Base must be between 2 and 36. base=',basein_local
  else ALL
     out_baseten=0;y=0.0; mult=1.0
     long=LEN_TRIM(string_local)
     do i=1, long
        k=long+1-i
        ch=string_local(k:k)
        if(ch.eq.'-'.and.k.eq.1)then
           out_sign=-1
           cycle
        endif
        if(ch<'0'.or.ch>'Z'.or.(ch>'9'.and.ch<'A'))then
           write(*,*)'*decodebase* ERROR: invalid character ',ch
           exit ALL
        endif
        if(ch<='9') then
              j=IACHAR(ch)-IACHAR('0')
        else
              j=IACHAR(ch)-IACHAR('A')+10
        endif
        if(j>=basein_local)then
           exit ALL
        endif
        y=y+mult*j
        if(mult>XMAXREAL/basein_local)then
           exit ALL
        endif
        mult=mult*basein_local
     enddo
     decodebase=.true.
     out_baseten=nint(out_sign*y)*sign(1,basein)
  endif ALL
end function decodebase
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    lenset(3f) - [M_strings:LENGTH] return string trimmed or padded to specified length
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    function lenset(str,length) result(strout)
!!
!!     character(len=*)                     :: str
!!     character(len=length)                :: strout
!!     integer,intent(in)                   :: length
!!##DESCRIPTION
!!    lenset(3f) truncates a string or pads it with spaces to the specified
!!    length.
!!##OPTIONS
!!    str     input string
!!    length  output string length
!!##RESULTS
!!    strout  output string
!!##EXAMPLE
!!
!! Sample Program:
!!
!!     program demo_lenset
!!      use M_strings, only : lenset
!!      implicit none
!!      character(len=10)            :: string='abcdefghij'
!!      character(len=:),allocatable :: answer
!!         answer=lenset(string,5)
!!         write(*,'("[",a,"]")') answer
!!         answer=lenset(string,20)
!!         write(*,'("[",a,"]")') answer
!!     end program demo_lenset
!!
!!    Expected output:
!!
!!     [abcde]
!!     [abcdefghij          ]
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function lenset(line,length) result(strout)

! ident_31="@(#)M_strings::lenset(3f): return string trimmed or padded to specified length"

character(len=*),intent(in)  ::  line
integer,intent(in)           ::  length
character(len=length)        ::  strout
   strout=line
end function lenset
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!      value_to_string(3f) - [M_strings:NUMERIC] return numeric string from a numeric value
!!      (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    subroutine value_to_string(value,chars[,ilen,ierr,fmt,trimz])
!!
!!     character(len=*) :: chars  ! minimum of 23 characters required
!!     !--------
!!     ! VALUE may be any <em>one</em> of the following types:
!!     doubleprecision,intent(in)               :: value
!!     real,intent(in)                          :: value
!!     integer,intent(in)                       :: value
!!     logical,intent(in)                       :: value
!!     !--------
!!     character(len=*),intent(out)             :: chars
!!     integer,intent(out),optional             :: ilen
!!     integer,optional                         :: ierr
!!     character(len=*),intent(in),optional     :: fmt
!!     logical,intent(in)                       :: trimz
!!##DESCRIPTION
!!
!!    value_to_string(3f) returns a numeric representation of a numeric
!!    value in a string given a numeric value of type REAL, DOUBLEPRECISION,
!!    INTEGER or LOGICAL. It creates the string using internal writes. It
!!    then removes trailing zeros from non-zero values, and left-justifies
!!    the string.
!!
!!##OPTIONS
!!       VALUE   input value to be converted to a string
!!       FMT     You may specify a specific format that produces a string
!!               up to the length of CHARS; optional.
!!       TRIMZ   If a format is supplied the default is not to try to trim
!!               trailing zeros. Set TRIMZ to .true. to trim zeros from a
!!               string assumed to represent a simple numeric value.
!!
!!##RETURNS
!!       CHARS   returned string representing input value, must be at least
!!               23 characters long; or what is required by optional FMT if longer.
!!       ILEN    position of last non-blank character in returned string; optional.
!!       IERR    If not zero, error occurred; optional.
!!##EXAMPLE
!!
!! Sample program:
!!
!!      program demo_value_to_string
!!      use M_strings, only: value_to_string
!!      implicit none
!!      character(len=80) :: string
!!      integer           :: ilen
!!         call value_to_string(3.0/4.0,string,ilen)
!!         write(*,*) 'The value is [',string(:ilen),']'
!!
!!         call value_to_string(3.0/4.0,string,ilen,fmt='')
!!         write(*,*) 'The value is [',string(:ilen),']'
!!
!!         call value_to_string(3.0/4.0,string,ilen,fmt='("THE VALUE IS ",g0)')
!!         write(*,*) 'The value is [',string(:ilen),']'
!!
!!         call value_to_string(1234,string,ilen)
!!         write(*,*) 'The value is [',string(:ilen),']'
!!
!!         call value_to_string(1.0d0/3.0d0,string,ilen)
!!         write(*,*) 'The value is [',string(:ilen),']'
!!
!!      end program demo_value_to_string
!!
!!    Expected output
!!
!!     The value is [0.75]
!!     The value is [      0.7500000000]
!!     The value is [THE VALUE IS .750000000]
!!     The value is [1234]
!!     The value is [0.33333333333333331]
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine value_to_string(gval,chars,length,err,fmt,trimz)

character(len=*),parameter::ident_40="@(#)M_strings::value_to_string(3fp): subroutine returns a string from a value"

class(*),intent(in)                      :: gval
character(len=*),intent(out)             :: chars
integer,intent(out),optional             :: length
integer,optional                         :: err
integer                                  :: err_local
character(len=*),optional,intent(in)     :: fmt         ! format to write value with
logical,intent(in),optional              :: trimz
character(len=:),allocatable             :: fmt_local
character(len=1024)                      :: msg

!  Notice that the value GVAL can be any of several types ( INTEGER,REAL,DOUBLEPRECISION,LOGICAL)

   if (present(fmt)) then
      select type(gval)
      type is (integer)
         fmt_local='(i0)'
         if(fmt.ne.'') fmt_local=fmt
         write(chars,fmt_local,iostat=err_local,iomsg=msg)gval
      type is (real)
         fmt_local='(bz,g23.10e3)'
         fmt_local='(bz,g0.8)'
         if(fmt.ne.'') fmt_local=fmt
         write(chars,fmt_local,iostat=err_local,iomsg=msg)gval
      type is (doubleprecision)
         fmt_local='(bz,g0)'
         if(fmt.ne.'') fmt_local=fmt
         write(chars,fmt_local,iostat=err_local,iomsg=msg)gval
      type is (logical)
         fmt_local='(l1)'
         if(fmt.ne.'') fmt_local=fmt
         write(chars,fmt_local,iostat=err_local,iomsg=msg)gval
      class default
         call journal('sc','*value_to_string* UNKNOWN TYPE')
         chars=' '
      end select
      if(fmt.eq.'') then
         chars=adjustl(chars)
         call trimzeros_(chars)
      endif
   else                                                  ! no explicit format option present
      err_local=-1
      select type(gval)
      type is (integer)
         write(chars,*,iostat=err_local,iomsg=msg)gval
      type is (real)
         write(chars,*,iostat=err_local,iomsg=msg)gval
      type is (doubleprecision)
         write(chars,*,iostat=err_local,iomsg=msg)gval
      type is (logical)
         write(chars,*,iostat=err_local,iomsg=msg)gval
      class default
         chars=''
      end select
      chars=adjustl(chars)
      if(index(chars,'.').ne.0) call trimzeros_(chars)
   endif
   if(present(trimz))then
      if(trimz)then
         chars=adjustl(chars)
         call trimzeros_(chars)
      endif
   endif

   if(present(length)) then
      length=len_trim(chars)
   endif

   if(present(err)) then
      err=err_local
   elseif(err_local.ne.0)then
      !-! cannot currently do I/O from a function being called from I/O
      !-!write(ERROR_UNIT,'(a)')'*value_to_string* WARNING:['//trim(msg)//']'
      chars=chars//' *value_to_string* WARNING:['//trim(msg)//']'
   endif

end subroutine value_to_string
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    trimzeros_(3fp) - [M_strings:NUMERIC] Delete trailing zeros from numeric decimal string
!!    (LICENSE:PD)
!!##SYNOPSIS
!!
!!    subroutine trimzeros_(str)
!!
!!     character(len=*)  :: str
!!##DESCRIPTION
!!    TRIMZEROS_(3f) deletes trailing zeros from a string representing a
!!    number. If the resulting string would end in a decimal point, one
!!    trailing zero is added.
!!##OPTIONS
!!    str   input string will be assumed to be a numeric value and have trailing
!!          zeros removed
!!##EXAMPLES
!!
!! Sample program:
!!
!!       program demo_trimzeros_
!!       use M_strings, only : trimzeros_
!!       character(len=:),allocatable :: string
!!          write(*,*)trimzeros_('123.450000000000')
!!          write(*,*)trimzeros_('12345')
!!          write(*,*)trimzeros_('12345.')
!!          write(*,*)trimzeros_('12345.00e3')
!!       end program demo_trimzeros_
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine trimzeros_(string)

! ident_32="@(#)M_strings::trimzeros_(3fp): Delete trailing zeros from numeric decimal string"

! if zero needs added at end assumes input string has room
character(len=*)             :: string
character(len=len(string)+2) :: str
character(len=len(string))   :: exp          ! the exponent string if present
integer                      :: ipos         ! where exponent letter appears if present
integer                      :: i, ii
   str=string                                ! working copy of string
   ipos=scan(str,'eEdD')                     ! find end of real number if string uses exponent notation
   if(ipos>0) then                           ! letter was found
      exp=str(ipos:)                         ! keep exponent string so it can be added back as a suffix
      str=str(1:ipos-1)                      ! just the real part, exponent removed will not have trailing zeros removed
   endif
   if(index(str,'.').eq.0)then               ! if no decimal character in original string add one to end of string
      ii=len_trim(str)
      str(ii+1:ii+1)='.'                     ! add decimal to end of string
   endif
   do i=len_trim(str),1,-1                   ! scanning from end find a non-zero character
      select case(str(i:i))
      case('0')                              ! found a trailing zero so keep trimming
         cycle
      case('.')                              ! found a decimal character at end of remaining string
         if(i.le.1)then
            str='0'
         else
            str=str(1:i-1)
         endif
         exit
      case default
         str=str(1:i)                        ! found a non-zero character so trim string and exit
         exit
      end select
   end do
   if(ipos>0)then                            ! if originally had an exponent place it back on
      string=trim(str)//trim(exp)
   else
      string=str
   endif
end subroutine trimzeros_
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
!>
!!##NAME
!!    substitute(3f) - [M_strings:EDITING] subroutine globally substitutes one substring for another in string
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!    subroutine substitute(targetline,old,new,ierr,start,end)
!!
!!     character(len=*)              :: targetline
!!     character(len=*),intent(in)   :: old
!!     character(len=*),intent(in)   :: new
!!     integer,intent(out),optional  :: ierr
!!     integer,intent(in),optional   :: start
!!     integer,intent(in),optional   :: end
!!##DESCRIPTION
!!    Globally substitute one substring for another in string.
!!
!!##OPTIONS
!!     TARGETLINE  input line to be changed. Must be long enough to
!!                 hold altered output.
!!     OLD         substring to find and replace
!!     NEW         replacement for OLD substring
!!     IERR        error code. If IER = -1 bad directive, >= 0 then
!!                 count of changes made.
!!     START       sets the left margin to be scanned for OLD in
!!                 TARGETLINE.
!!     END         sets the right margin to be scanned for OLD in
!!                 TARGETLINE.
!!
!!##EXAMPLES
!!
!! Sample Program:
!!
!!     program demo_substitute
!!     use M_strings, only : substitute
!!     implicit none
!!     ! must be long enough to hold changed line
!!     character(len=80) :: targetline
!!
!!     targetline='this is the input string'
!!     write(*,*)'ORIGINAL    : '//trim(targetline)
!!
!!     ! changes the input to 'THis is THe input string'
!!     call substitute(targetline,'th','TH')
!!     write(*,*)'th => TH    : '//trim(targetline)
!!
!!     ! a null old substring means "at beginning of line"
!!     ! changes the input to 'BEFORE:this is the input string'
!!     call substitute(targetline,'','BEFORE:')
!!     write(*,*)'"" => BEFORE: '//trim(targetline)
!!
!!     ! a null new string deletes occurrences of the old substring
!!     ! changes the input to 'ths s the nput strng'
!!     call substitute(targetline,'i','')
!!     write(*,*)'i => ""     : '//trim(targetline)
!!
!!     end program demo_substitute
!!
!!   Expected output
!!
!!     ORIGINAL    : this is the input string
!!     th => TH    : THis is THe input string
!!     "" => BEFORE: BEFORE:THis is THe input string
!!     i => ""     : BEFORE:THs s THe nput strng
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine substitute(targetline,old,new,ierr,start,end)

! ident_33="@(#)M_strings::substitute(3f): Globally substitute one substring for another in string"

!-----------------------------------------------------------------------------------------------------------------------------------
character(len=*)               :: targetline         ! input line to be changed
character(len=*),intent(in)    :: old                ! old substring to replace
character(len=*),intent(in)    :: new                ! new substring
integer,intent(out),optional   :: ierr               ! error code. if ierr = -1 bad directive, >=0 then ierr changes made
integer,intent(in),optional    :: start              ! start sets the left margin
integer,intent(in),optional    :: end                ! end sets the right margin
!-----------------------------------------------------------------------------------------------------------------------------------
character(len=len(targetline)) :: dum1               ! scratch string buffers
integer                        :: ml, mr, ier1
integer                        :: maxlengthout       ! MAXIMUM LENGTH ALLOWED FOR NEW STRING
integer                        :: original_input_length
integer                        :: len_old, len_new
integer                        :: ladd
integer                        :: ir
integer                        :: ind
integer                        :: il
integer                        :: id
integer                        :: ic
integer                        :: ichar
!-----------------------------------------------------------------------------------------------------------------------------------
   if (present(start)) then                            ! optional starting column
      ml=start
   else
      ml=1
   endif
   if (present(end)) then                              ! optional ending column
      mr=end
   else
      mr=len(targetline)
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   ier1=0                                              ! initialize error flag/change count
   maxlengthout=len(targetline)                        ! max length of output string
   original_input_length=len_trim(targetline)          ! get non-blank length of input line
   dum1(:)=' '                                         ! initialize string to build output in
   id=mr-ml                                            ! check for window option !-! change to optional parameter(s)
!-----------------------------------------------------------------------------------------------------------------------------------
   len_old=len(old)                                    ! length of old substring to be replaced
   len_new=len(new)                                    ! length of new substring to replace old substring
   if(id.le.0)then                                     ! no window so change entire input string
      il=1                                             ! il is left margin of window to change
      ir=maxlengthout                                  ! ir is right margin of window to change
      dum1(:)=' '                                      ! begin with a blank line
   else                                                ! if window is set
      il=ml                                            ! use left margin
      ir=min0(mr,maxlengthout)                         ! use right margin or rightmost
      dum1=targetline(:il-1)                           ! begin with what's below margin
   endif                                               ! end of window settings
!-----------------------------------------------------------------------------------------------------------------------------------
   if(len_old.eq.0)then                                ! c//new/ means insert new at beginning of line (or left margin)
      ichar=len_new + original_input_length
      if(ichar.gt.maxlengthout)then
         call journal('sc','*substitute* new line will be too long')
         ier1=-1
         if (present(ierr))ierr=ier1
         return
      endif
      if(len_new.gt.0)then
         dum1(il:)=new(:len_new)//targetline(il:original_input_length)
      else
         dum1(il:)=targetline(il:original_input_length)
      endif
      targetline(1:maxlengthout)=dum1(:maxlengthout)
      ier1=1                                           ! made one change. actually, c/// should maybe return 0
      if(present(ierr))ierr=ier1
      return
   endif
!-----------------------------------------------------------------------------------------------------------------------------------
   ichar=il                                            ! place to put characters into output string
   ic=il                                               ! place looking at in input string
   loop: do
      ind=index(targetline(ic:),old(:len_old))+ic-1    ! try to find start of old string in remaining part of input in change window
      if(ind.eq.ic-1.or.ind.gt.ir)then                 ! did not find old string or found old string past edit window
         exit loop                                     ! no more changes left to make
      endif
      ier1=ier1+1                                      ! found an old string to change, so increment count of changes
      if(ind.gt.ic)then                                ! if found old string past at current position in input string copy unchanged
         ladd=ind-ic                                   ! find length of character range to copy as-is from input to output
         if(ichar-1+ladd.gt.maxlengthout)then
            ier1=-1
            exit loop
         endif
         dum1(ichar:)=targetline(ic:ind-1)
         ichar=ichar+ladd
      endif
      if(ichar-1+len_new.gt.maxlengthout)then
         ier1=-2
         exit loop
      endif
      if(len_new.ne.0)then
         dum1(ichar:)=new(:len_new)
         ichar=ichar+len_new
      endif
      ic=ind+len_old
   enddo loop
!-----------------------------------------------------------------------------------------------------------------------------------
   select case (ier1)
   case (:-1)
      call journal('sc','*substitute* new line will be too long')
   case (0)                                                ! there were no changes made to the window
   case default
      ladd=original_input_length-ic
      if(ichar+ladd.gt.maxlengthout)then
         call journal('sc','*substitute* new line will be too long')
         ier1=-1
         if(present(ierr))ierr=ier1
         return
      endif
      if(ic.lt.len(targetline))then
         dum1(ichar:)=targetline(ic:max(ic,original_input_length))
      endif
      targetline=dum1(:maxlengthout)
   end select
   if(present(ierr))ierr=ier1
!-----------------------------------------------------------------------------------------------------------------------------------
end subroutine substitute
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    locate(3f) - [M_list] finds the index where a string is found or should be in a sorted array
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine locate(list,value,place,ier,errmsg)
!!
!!    character(len=:)|doubleprecision|real|integer,allocatable :: list(:)
!!    character(len=*)|doubleprecision|real|integer,intent(in)  :: value
!!    integer, intent(out)                  :: PLACE
!!
!!    integer, intent(out),optional         :: IER
!!    character(len=*),intent(out),optional :: ERRMSG
!!
!!##DESCRIPTION
!!
!!    LOCATE(3f) finds the index where the VALUE is found or should
!!    be found in an array. The array must be sorted in descending
!!    order (highest at top). If VALUE is not found it returns the index
!!    where the name should be placed at with a negative sign.
!!
!!    The array and list must be of the same type (CHARACTER, DOUBLEPRECISION,
!!    REAL,INTEGER)
!!
!!##OPTIONS
!!
!!    VALUE         the value to locate in the list.
!!    LIST          is the list array.
!!
!!##RETURNS
!!    PLACE         is the subscript that the entry was found at if it is
!!                  greater than zero(0).
!!
!!                  If PLACE is negative, the absolute value of
!!                  PLACE indicates the subscript value where the
!!                  new entry should be placed in order to keep the
!!                  list alphabetized.
!!
!!    IER           is zero(0) if no error occurs.
!!                  If an error occurs and IER is not
!!                  present, the program is stopped.
!!
!!    ERRMSG        description of any error
!!
!!##EXAMPLES
!!
!!
!! Find if a string is in a sorted array, and insert the string into
!! the list if it is not present ...
!!
!!     program demo_locate
!!     use M_sort, only : sort_shell
!!     use M_list, only : locate
!!     implicit none
!!     character(len=:),allocatable  :: arr(:)
!!     integer                       :: i
!!
!!     arr=[character(len=20) :: '', 'ZZZ', 'aaa', 'b', 'xxx' ]
!!     ! make sure sorted in descending order
!!     call sort_shell(arr,order='d')
!!
!!     call update(arr,'b')
!!     call update(arr,'[')
!!     call update(arr,'c')
!!     call update(arr,'ZZ')
!!     call update(arr,'ZZZZ')
!!     call update(arr,'z')
!!
!!     contains
!!     subroutine update(arr,string)
!!     character(len=:),allocatable :: arr(:)
!!     character(len=*)             :: string
!!     integer                      :: place, plus, ii, end
!!     ! find where string is or should be
!!     call locate(arr,string,place)
!!     write(*,*)'for "'//string//'" index is ',place, size(arr)
!!     ! if string was not found insert it
!!     if(place.lt.1)then
!!        plus=abs(place)
!!        ii=len(arr)
!!        end=size(arr)
!!        ! empty array
!!        if(end.eq.0)then
!!           arr=[character(len=ii) :: string ]
!!        ! put in front of array
!!        elseif(plus.eq.1)then
!!           arr=[character(len=ii) :: string, arr]
!!        ! put at end of array
!!        elseif(plus.eq.end)then
!!           arr=[character(len=ii) :: arr, string ]
!!        ! put in middle of array
!!        else
!!           arr=[character(len=ii) :: arr(:plus-1), string,arr(plus:) ]
!!        endif
!!        ! show array
!!        write(*,'("SIZE=",i0,1x,*(a,","))')end,(trim(arr(i)),i=1,end)
!!     endif
!!     end subroutine update
!!     end program demo_locate
!!
!!   Results:
!!
!!     for "b" index is            2           5
!!     for "[" index is           -4           5
!!    SIZE=5 xxx,b,aaa,[,ZZZ,
!!     for "c" index is           -2           6
!!    SIZE=6 xxx,c,b,aaa,[,ZZZ,
!!     for "ZZ" index is           -7           7
!!    SIZE=7 xxx,c,b,aaa,[,ZZZ,,
!!     for "ZZZZ" index is           -6           8
!!    SIZE=8 xxx,c,b,aaa,[,ZZZZ,ZZZ,,
!!     for "z" index is           -1           9
!!    SIZE=9 z,xxx,c,b,aaa,[,ZZZZ,ZZZ,,
!!
!!##AUTHOR
!!    1989,2017 John S. Urban
!!##LICENSE
!!    Public Domain
subroutine locate_c(list,value,place,ier,errmsg)

! ident_34="@(#)M_list::locate_c(3f): find PLACE in sorted character array where VALUE can be found or should be placed"

character(len=*),intent(in)             :: value
integer,intent(out)                     :: place
character(len=:),allocatable            :: list(:)
integer,intent(out),optional            :: ier
character(len=*),intent(out),optional   :: errmsg
integer                                 :: i
character(len=:),allocatable            :: message
integer                                 :: arraysize
integer                                 :: maxtry
integer                                 :: imin, imax
integer                                 :: error
   if(.not.allocated(list))then
      list=[character(len=max(len_trim(value),2)) :: ]
   endif
   arraysize=size(list)

   error=0
   if(arraysize.eq.0)then
      maxtry=0
      place=-1
   else
      maxtry=int(log(float(arraysize))/log(2.0)+1.0)
      place=(arraysize+1)/2
   endif
   imin=1
   imax=arraysize
   message=''

   LOOP: block
   do i=1,maxtry

      if(value.eq.list(PLACE))then
         exit LOOP
      else if(value.gt.list(place))then
         imax=place-1
      else
         imin=place+1
      endif

      if(imin.gt.imax)then
         place=-imin
         if(iabs(place).gt.arraysize)then ! ran off end of list. Where new value should go or an unsorted input array'
            exit LOOP
         endif
         exit LOOP
      endif

      place=(imax+imin)/2

      if(place.gt.arraysize.or.place.le.0)then
         message='*locate* error: search is out of bounds of list. Probably an unsorted input array'
         error=-1
         exit LOOP
      endif

   enddo
   message='*locate* exceeded allowed tries. Probably an unsorted input array'
   endblock LOOP
   if(present(ier))then
      ier=error
   else if(error.ne.0)then
      write(stderr,*)message//' VALUE=',trim(value)//' PLACE=',place
      stop 1
   endif
   if(present(errmsg))then
      errmsg=message
   endif
end subroutine locate_c
subroutine locate_d(list,value,place,ier,errmsg)

! ident_35="@(#)M_list::locate_d(3f): find PLACE in sorted doubleprecision array where VALUE can be found or should be placed"

! Assuming an array sorted in descending order
!
!  1. If it is not found report where it should be placed as a NEGATIVE index number.

doubleprecision,allocatable            :: list(:)
doubleprecision,intent(in)             :: value
integer,intent(out)                    :: place
integer,intent(out),optional           :: ier
character(len=*),intent(out),optional  :: errmsg

integer                                :: i
character(len=:),allocatable           :: message
integer                                :: arraysize
integer                                :: maxtry
integer                                :: imin, imax
integer                                :: error

   if(.not.allocated(list))then
      list=[doubleprecision :: ]
   endif
   arraysize=size(list)

   error=0
   if(arraysize.eq.0)then
      maxtry=0
      place=-1
   else
      maxtry=int(log(float(arraysize))/log(2.0)+1.0)
      place=(arraysize+1)/2
   endif
   imin=1
   imax=arraysize
   message=''

   LOOP: block
   do i=1,maxtry

      if(value.eq.list(PLACE))then
         exit LOOP
      else if(value.gt.list(place))then
         imax=place-1
      else
         imin=place+1
      endif

      if(imin.gt.imax)then
         place=-imin
         if(iabs(place).gt.arraysize)then ! ran off end of list. Where new value should go or an unsorted input array'
            exit LOOP
         endif
         exit LOOP
      endif

      place=(imax+imin)/2

      if(place.gt.arraysize.or.place.le.0)then
         message='*locate* error: search is out of bounds of list. Probably an unsorted input array'
         error=-1
         exit LOOP
      endif

   enddo
   message='*locate* exceeded allowed tries. Probably an unsorted input array'
   endblock LOOP
   if(present(ier))then
      ier=error
   else if(error.ne.0)then
      write(stderr,*)message//' VALUE=',value,' PLACE=',place
      stop 1
   endif
   if(present(errmsg))then
      errmsg=message
   endif
end subroutine locate_d
subroutine locate_r(list,value,place,ier,errmsg)

! ident_36="@(#)M_list::locate_r(3f): find PLACE in sorted real array where VALUE can be found or should be placed"

! Assuming an array sorted in descending order
!
!  1. If it is not found report where it should be placed as a NEGATIVE index number.

real,allocatable                       :: list(:)
real,intent(in)                        :: value
integer,intent(out)                    :: place
integer,intent(out),optional           :: ier
character(len=*),intent(out),optional  :: errmsg

integer                                :: i
character(len=:),allocatable           :: message
integer                                :: arraysize
integer                                :: maxtry
integer                                :: imin, imax
integer                                :: error

   if(.not.allocated(list))then
      list=[real :: ]
   endif
   arraysize=size(list)

   error=0
   if(arraysize.eq.0)then
      maxtry=0
      place=-1
   else
      maxtry=int(log(float(arraysize))/log(2.0)+1.0)
      place=(arraysize+1)/2
   endif
   imin=1
   imax=arraysize
   message=''

   LOOP: block
   do i=1,maxtry

      if(value.eq.list(PLACE))then
         exit LOOP
      else if(value.gt.list(place))then
         imax=place-1
      else
         imin=place+1
      endif

      if(imin.gt.imax)then
         place=-imin
         if(iabs(place).gt.arraysize)then ! ran off end of list. Where new value should go or an unsorted input array'
            exit LOOP
         endif
         exit LOOP
      endif

      place=(imax+imin)/2

      if(place.gt.arraysize.or.place.le.0)then
         message='*locate* error: search is out of bounds of list. Probably an unsorted input array'
         error=-1
         exit LOOP
      endif

   enddo
   message='*locate* exceeded allowed tries. Probably an unsorted input array'
   endblock LOOP
   if(present(ier))then
      ier=error
   else if(error.ne.0)then
      write(stderr,*)message//' VALUE=',value,' PLACE=',place
      stop 1
   endif
   if(present(errmsg))then
      errmsg=message
   endif
end subroutine locate_r
subroutine locate_i(list,value,place,ier,errmsg)

! ident_37="@(#)M_list::locate_i(3f): find PLACE in sorted integer array where VALUE can be found or should be placed"

! Assuming an array sorted in descending order
!
!  1. If it is not found report where it should be placed as a NEGATIVE index number.

integer,allocatable                    :: list(:)
integer,intent(in)                     :: value
integer,intent(out)                    :: place
integer,intent(out),optional           :: ier
character(len=*),intent(out),optional  :: errmsg

integer                                :: i
character(len=:),allocatable           :: message
integer                                :: arraysize
integer                                :: maxtry
integer                                :: imin, imax
integer                                :: error

   if(.not.allocated(list))then
      list=[integer :: ]
   endif
   arraysize=size(list)

   error=0
   if(arraysize.eq.0)then
      maxtry=0
      place=-1
   else
      maxtry=int(log(float(arraysize))/log(2.0)+1.0)
      place=(arraysize+1)/2
   endif
   imin=1
   imax=arraysize
   message=''

   LOOP: block
   do i=1,maxtry

      if(value.eq.list(PLACE))then
         exit LOOP
      else if(value.gt.list(place))then
         imax=place-1
      else
         imin=place+1
      endif

      if(imin.gt.imax)then
         place=-imin
         if(iabs(place).gt.arraysize)then ! ran off end of list. Where new value should go or an unsorted input array'
            exit LOOP
         endif
         exit LOOP
      endif

      place=(imax+imin)/2

      if(place.gt.arraysize.or.place.le.0)then
         message='*locate* error: search is out of bounds of list. Probably an unsorted input array'
         error=-1
         exit LOOP
      endif

   enddo
   message='*locate* exceeded allowed tries. Probably an unsorted input array'
   endblock LOOP
   if(present(ier))then
      ier=error
   else if(error.ne.0)then
      write(stderr,*)message//' VALUE=',value,' PLACE=',place
      stop 1
   endif
   if(present(errmsg))then
      errmsg=message
   endif
end subroutine locate_i
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    remove(3f) - [M_list] remove entry from an allocatable array at specified position
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine remove(list,place)
!!
!!    character(len=:)|doubleprecision|real|integer,intent(inout) :: list(:)
!!    integer, intent(out) :: PLACE
!!
!!##DESCRIPTION
!!
!!    Remove a value from an allocatable array at the specified index.
!!    The array is assumed to be sorted in descending order. It may be of
!!    type CHARACTER, DOUBLEPRECISION, REAL, or INTEGER.
!!
!!##OPTIONS
!!
!!    list    is the list array.
!!    PLACE   is the subscript for the entry that should be removed
!!
!!##EXAMPLES
!!
!!
!! Sample program
!!
!!     program demo_remove
!!     use M_sort, only : sort_shell
!!     use M_list, only : locate, remove
!!     implicit none
!!     character(len=:),allocatable :: arr(:)
!!     integer                       :: i
!!     integer                       :: end
!!
!!     arr=[character(len=20) :: '', 'ZZZ', 'Z', 'aaa', 'b', 'b', 'ab', 'bb', 'xxx' ]
!!     ! make sure sorted in descending order
!!     call sort_shell(arr,order='d')
!!
!!     end=size(arr)
!!     write(*,'("SIZE=",i0,1x,*(a,","))')end,(trim(arr(i)),i=1,end)
!!     call remove(arr,1)
!!     end=size(arr)
!!     write(*,'("SIZE=",i0,1x,*(a,","))')end,(trim(arr(i)),i=1,end)
!!     call remove(arr,4)
!!     end=size(arr)
!!     write(*,'("SIZE=",i0,1x,*(a,","))')end,(trim(arr(i)),i=1,end)
!!
!!     end program demo_remove
!!
!!   Results:
!!
!!    Expected output
!!
!!     SIZE=9 xxx,bb,b,b,ab,aaa,ZZZ,Z,,
!!     SIZE=8 bb,b,b,ab,aaa,ZZZ,Z,,
!!     SIZE=7 bb,b,b,aaa,ZZZ,Z,,
!!
!!##AUTHOR
!!    1989,2017 John S. Urban
!!##LICENSE
!!    Public Domain
subroutine remove_c(list,place)

! ident_38="@(#)M_list::remove_c(3fp): remove string from allocatable string array at specified position"

character(len=:),allocatable :: list(:)
integer,intent(in)           :: place
integer                      :: ii, end
   if(.not.allocated(list))then
      list=[character(len=2) :: ]
   endif
   ii=len(list)
   end=size(list)
   if(place.le.0.or.place.gt.end)then                       ! index out of bounds of array
   elseif(place.eq.end)then                                 ! remove from array
      list=[character(len=ii) :: list(:place-1) ]
   else
      list=[character(len=ii) :: list(:place-1), list(place+1:) ]
   endif
end subroutine remove_c
subroutine remove_d(list,place)

! ident_39="@(#)M_list::remove_d(3fp): remove doubleprecision value from allocatable array at specified position"

doubleprecision,allocatable  :: list(:)
integer,intent(in)           :: place
integer                      :: end
   if(.not.allocated(list))then
           list=[doubleprecision :: ]
   endif
   end=size(list)
   if(place.le.0.or.place.gt.end)then                       ! index out of bounds of array
   elseif(place.eq.end)then                                 ! remove from array
      list=[ list(:place-1)]
   else
      list=[ list(:place-1), list(place+1:) ]
   endif

end subroutine remove_d
subroutine remove_r(list,place)

! ident_40="@(#)M_list::remove_r(3fp): remove value from allocatable array at specified position"

real,allocatable    :: list(:)
integer,intent(in)  :: place
integer             :: end
   if(.not.allocated(list))then
      list=[real :: ]
   endif
   end=size(list)
   if(place.le.0.or.place.gt.end)then                       ! index out of bounds of array
   elseif(place.eq.end)then                                 ! remove from array
      list=[ list(:place-1)]
   else
      list=[ list(:place-1), list(place+1:) ]
   endif

end subroutine remove_r
subroutine remove_l(list,place)

! ident_41="@(#)M_list::remove_l(3fp): remove value from allocatable array at specified position"

logical,allocatable    :: list(:)
integer,intent(in)     :: place
integer                :: end

   if(.not.allocated(list))then
      list=[logical :: ]
   endif
   end=size(list)
   if(place.le.0.or.place.gt.end)then                       ! index out of bounds of array
   elseif(place.eq.end)then                                 ! remove from array
      list=[ list(:place-1)]
   else
      list=[ list(:place-1), list(place+1:) ]
   endif

end subroutine remove_l
subroutine remove_i(list,place)

! ident_42="@(#)M_list::remove_i(3fp): remove value from allocatable array at specified position"
integer,allocatable    :: list(:)
integer,intent(in)     :: place
integer                :: end

   if(.not.allocated(list))then
      list=[integer :: ]
   endif
   end=size(list)
   if(place.le.0.or.place.gt.end)then                       ! index out of bounds of array
   elseif(place.eq.end)then                                 ! remove from array
      list=[ list(:place-1)]
   else
      list=[ list(:place-1), list(place+1:) ]
   endif

end subroutine remove_i
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    replace(3f) - [M_list] replace entry in a string array at specified position
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine replace(list,value,place)
!!
!!    character(len=*)|doubleprecision|real|integer,intent(in) :: value
!!    character(len=:)|doubleprecision|real|integer,intent(in) :: list(:)
!!    integer, intent(out)          :: PLACE
!!
!!##DESCRIPTION
!!
!!    replace a value in an allocatable array at the specified index. Unless the
!!    array needs the string length to increase this is merely an assign of a value
!!    to an array element.
!!
!!    The array may be of type CHARACTER, DOUBLEPRECISION, REAL, or INTEGER>
!!    It is assumed to be sorted in descending order without duplicate values.
!!
!!    The value and list must be of the same type.
!!
!!##OPTIONS
!!
!!    VALUE         the value to place in the array
!!    LIST          is the array.
!!    PLACE         is the subscript that the entry should be placed at
!!
!!##EXAMPLES
!!
!!
!! Replace key-value pairs in a dictionary
!!
!!     program demo_replace
!!     use M_list, only  : insert, locate, replace
!!     ! Find if a key is in a list and insert it
!!     ! into the key list and value list if it is not present
!!     ! or replace the associated value if the key existed
!!     implicit none
!!     character(len=20)            :: key
!!     character(len=100)           :: val
!!     character(len=:),allocatable :: keywords(:)
!!     character(len=:),allocatable :: values(:)
!!     integer                      :: i
!!     integer                      :: place
!!     call update('b','value of b')
!!     call update('a','value of a')
!!     call update('c','value of c')
!!     call update('c','value of c again')
!!     call update('d','value of d')
!!     call update('a','value of a again')
!!     ! show array
!!     write(*,'(*(a,"==>",a,/))')(trim(keywords(i)),trim(values(i)),i=1,size(keywords))
!!
!!     call locate(keywords,'a',place)
!!     if(place.gt.0)then
!!        write(*,*)'The value of "a" is',trim(values(place))
!!     else
!!        write(*,*)'"a" not found'
!!     endif
!!
!!     contains
!!     subroutine update(key,val)
!!     character(len=*),intent(in)  :: key
!!     character(len=*),intent(in)  :: val
!!     integer                      :: place
!!
!!     ! find where string is or should be
!!     call locate(keywords,key,place)
!!     ! if string was not found insert it
!!     if(place.lt.1)then
!!        call insert(keywords,key,abs(place))
!!        call insert(values,val,abs(place))
!!     else ! replace
!!        call replace(values,val,place)
!!     endif
!!
!!     end subroutine update
!!    end program demo_replace
!!
!!   Expected output
!!
!!    d==>value of d
!!    c==>value of c again
!!    b==>value of b
!!    a==>value of a again
!!
!!##AUTHOR
!!    1989,2017 John S. Urban
!!##LICENSE
!!    Public Domain
subroutine replace_c(list,value,place)

! ident_43="@(#)M_list::replace_c(3fp): replace string in allocatable string array at specified position"

character(len=*),intent(in)  :: value
character(len=:),allocatable :: list(:)
character(len=:),allocatable :: kludge(:)
integer,intent(in)           :: place
integer                      :: ii
integer                      :: tlen
integer                      :: end
   if(.not.allocated(list))then
      list=[character(len=max(len_trim(value),2)) :: ]
   endif
   tlen=len_trim(value)
   end=size(list)
   if(place.lt.0.or.place.gt.end)then
           write(stderr,*)'*replace_c* error: index out of range. end=',end,' index=',place
   elseif(len_trim(value).le.len(list))then
      list(place)=value
   else  ! increase length of variable
      ii=max(tlen,len(list))
      kludge=[character(len=ii) :: list ]
      list=kludge
      list(place)=value
   endif
end subroutine replace_c
subroutine replace_d(list,value,place)

! ident_44="@(#)M_list::replace_d(3fp): place doubleprecision value into allocatable array at specified position"

doubleprecision,intent(in)   :: value
doubleprecision,allocatable  :: list(:)
integer,intent(in)           :: place
integer                      :: end
   if(.not.allocated(list))then
           list=[doubleprecision :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.gt.0.and.place.le.end)then
      list(place)=value
   else                                                      ! put in middle of array
      write(stderr,*)'*replace_d* error: index out of range. end=',end,' index=',place
   endif
end subroutine replace_d
subroutine replace_r(list,value,place)

! ident_45="@(#)M_list::replace_r(3fp): place value into allocatable array at specified position"

real,intent(in)       :: value
real,allocatable      :: list(:)
integer,intent(in)    :: place
integer               :: end
   if(.not.allocated(list))then
      list=[real :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.gt.0.and.place.le.end)then
      list(place)=value
   else                                                      ! put in middle of array
      write(stderr,*)'*replace_r* error: index out of range. end=',end,' index=',place
   endif
end subroutine replace_r
subroutine replace_l(list,value,place)

! ident_46="@(#)M_list::replace_l(3fp): place value into allocatable array at specified position"

logical,allocatable   :: list(:)
logical,intent(in)    :: value
integer,intent(in)    :: place
integer               :: end
   if(.not.allocated(list))then
      list=[logical :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.gt.0.and.place.le.end)then
      list(place)=value
   else                                                      ! put in middle of array
      write(stderr,*)'*replace_l* error: index out of range. end=',end,' index=',place
   endif
end subroutine replace_l
subroutine replace_i(list,value,place)

! ident_47="@(#)M_list::replace_i(3fp): place value into allocatable array at specified position"

integer,intent(in)    :: value
integer,allocatable   :: list(:)
integer,intent(in)    :: place
integer               :: end
   if(.not.allocated(list))then
      list=[integer :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.gt.0.and.place.le.end)then
      list(place)=value
   else                                                      ! put in middle of array
      write(stderr,*)'*replace_i* error: index out of range. end=',end,' index=',place
   endif
end subroutine replace_i
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    insert(3f) - [M_list] insert entry into a string array at specified position
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine insert(list,value,place)
!!
!!    character(len=*)|doubleprecision|real|integer,intent(in) :: value
!!    character(len=:)|doubleprecision|real|integer,intent(in) :: list(:)
!!    integer,intent(in)    :: place
!!
!!##DESCRIPTION
!!
!!    Insert a value into an allocatable array at the specified index.
!!    The list and value must be of the same type (CHARACTER, DOUBLEPRECISION,
!!    REAL, or INTEGER)
!!
!!##OPTIONS
!!
!!    list    is the list array. Must be sorted in descending order.
!!    value   the value to place in the array
!!    PLACE   is the subscript that the entry should be placed at
!!
!!##EXAMPLES
!!
!!
!! Find if a string is in a sorted array, and insert the string into
!! the list if it is not present ...
!!
!!     program demo_insert
!!     use M_sort, only : sort_shell
!!     use M_list, only : locate, insert
!!     implicit none
!!     character(len=:),allocatable :: arr(:)
!!     integer                       :: i
!!
!!     arr=[character(len=20) :: '', 'ZZZ', 'aaa', 'b', 'xxx' ]
!!     ! make sure sorted in descending order
!!     call sort_shell(arr,order='d')
!!     ! add or replace values
!!     call update(arr,'b')
!!     call update(arr,'[')
!!     call update(arr,'c')
!!     call update(arr,'ZZ')
!!     call update(arr,'ZZZ')
!!     call update(arr,'ZZZZ')
!!     call update(arr,'')
!!     call update(arr,'z')
!!
!!     contains
!!     subroutine update(arr,string)
!!     character(len=:),allocatable :: arr(:)
!!     character(len=*)             :: string
!!     integer                      :: place, end
!!
!!     end=size(arr)
!!     ! find where string is or should be
!!     call locate(arr,string,place)
!!     ! if string was not found insert it
!!     if(place.lt.1)then
!!        call insert(arr,string,abs(place))
!!     endif
!!     ! show array
!!     end=size(arr)
!!     write(*,'("array is now SIZE=",i0,1x,*(a,","))')end,(trim(arr(i)),i=1,end)
!!
!!     end subroutine update
!!     end program demo_insert
!!
!!   Results:
!!
!!     array is now SIZE=5 xxx,b,aaa,ZZZ,,
!!     array is now SIZE=6 xxx,b,aaa,[,ZZZ,,
!!     array is now SIZE=7 xxx,c,b,aaa,[,ZZZ,,
!!     array is now SIZE=8 xxx,c,b,aaa,[,ZZZ,ZZ,,
!!     array is now SIZE=9 xxx,c,b,aaa,[,ZZZZ,ZZZ,ZZ,,
!!     array is now SIZE=10 z,xxx,c,b,aaa,[,ZZZZ,ZZZ,ZZ,,
!!
!!##AUTHOR
!!    1989,2017 John S. Urban
!!##LICENSE
!!    Public Domain
subroutine insert_c(list,value,place)

! ident_48="@(#)M_list::insert_c(3fp): place string into allocatable string array at specified position"

character(len=*),intent(in)  :: value
character(len=:),allocatable :: list(:)
character(len=:),allocatable :: kludge(:)
integer,intent(in)           :: place
integer                      :: ii
integer                      :: end

   if(.not.allocated(list))then
      list=[character(len=max(len_trim(value),2)) :: ]
   endif

   ii=max(len_trim(value),len(list),2)
   end=size(list)

   if(end.eq.0)then                                          ! empty array
      list=[character(len=ii) :: value ]
   elseif(place.eq.1)then                                    ! put in front of array
      kludge=[character(len=ii) :: value, list]
      list=kludge
   elseif(place.gt.end)then                                  ! put at end of array
      kludge=[character(len=ii) :: list, value ]
      list=kludge
   elseif(place.ge.2.and.place.le.end)then                 ! put in middle of array
      kludge=[character(len=ii) :: list(:place-1), value,list(place:) ]
      list=kludge
   else                                                      ! index out of range
      write(stderr,*)'*insert_c* error: index out of range. end=',end,' index=',place,' value=',value
   endif

end subroutine insert_c
subroutine insert_r(list,value,place)

! ident_49="@(#)M_list::insert_r(3fp): place real value into allocatable array at specified position"

real,intent(in)       :: value
real,allocatable      :: list(:)
integer,intent(in)    :: place
integer               :: end

   if(.not.allocated(list))then
      list=[real :: ]
   endif

   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.eq.1)then                                    ! put in front of array
      list=[value, list]
   elseif(place.gt.end)then                                  ! put at end of array
      list=[list, value ]
   elseif(place.ge.2.and.place.le.end)then                   ! put in middle of array
      list=[list(:place-1), value,list(place:) ]
   else                                                      ! index out of range
      write(stderr,*)'*insert_r* error: index out of range. end=',end,' index=',place,' value=',value
   endif

end subroutine insert_r
subroutine insert_d(list,value,place)

! ident_50="@(#)M_list::insert_d(3fp): place doubleprecision value into allocatable array at specified position"

doubleprecision,intent(in)       :: value
doubleprecision,allocatable      :: list(:)
integer,intent(in)               :: place
integer                          :: end
   if(.not.allocated(list))then
      list=[doubleprecision :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.eq.1)then                                    ! put in front of array
      list=[value, list]
   elseif(place.gt.end)then                                  ! put at end of array
      list=[list, value ]
   elseif(place.ge.2.and.place.le.end)then                 ! put in middle of array
      list=[list(:place-1), value,list(place:) ]
   else                                                      ! index out of range
      write(stderr,*)'*insert_d* error: index out of range. end=',end,' index=',place,' value=',value
   endif
end subroutine insert_d
subroutine insert_l(list,value,place)

! ident_51="@(#)M_list::insert_l(3fp): place value into allocatable array at specified position"

logical,allocatable   :: list(:)
logical,intent(in)    :: value
integer,intent(in)    :: place
integer               :: end
   if(.not.allocated(list))then
      list=[logical :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.eq.1)then                                    ! put in front of array
      list=[value, list]
   elseif(place.gt.end)then                                  ! put at end of array
      list=[list, value ]
   elseif(place.ge.2.and.place.le.end)then                 ! put in middle of array
      list=[list(:place-1), value,list(place:) ]
   else                                                      ! index out of range
      write(stderr,*)'*insert_l* error: index out of range. end=',end,' index=',place,' value=',value
   endif

end subroutine insert_l
subroutine insert_i(list,value,place)

! ident_52="@(#)M_list::insert_i(3fp): place value into allocatable array at specified position"

integer,allocatable   :: list(:)
integer,intent(in)    :: value
integer,intent(in)    :: place
integer               :: end
   if(.not.allocated(list))then
      list=[integer :: ]
   endif
   end=size(list)
   if(end.eq.0)then                                          ! empty array
      list=[value]
   elseif(place.eq.1)then                                    ! put in front of array
      list=[value, list]
   elseif(place.gt.end)then                                  ! put at end of array
      list=[list, value ]
   elseif(place.ge.2.and.place.le.end)then                 ! put in middle of array
      list=[list(:place-1), value,list(place:) ]
   else                                                      ! index out of range
      write(stderr,*)'*insert_i* error: index out of range. end=',end,' index=',place,' value=',value
   endif

end subroutine insert_i
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    dict_delete(3f) - [M_list] delete entry by name from an allocatable sorted string array if it is present
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine dict_delete(key,dict)
!!
!!    character(len=*),intent(in) :: key
!!    type(dictionary)            :: dict
!!
!!##DESCRIPTION
!!
!!    Find if a string is in a sorted array, and delete the string
!!    from the dictionary if it is present.
!!
!!##OPTIONS
!!
!!    KEY           the key name to find and delete from the dictionary.
!!    DICTIONARY    the dictionary.
!!
!!##EXAMPLES
!!
!!
!! delete a key from a dictionary by name.
!!
!!     program demo_dict_delete
!!     use M_list, only : dictionary
!!     implicit none
!!     type(dictionary) :: caps
!!     integer                       :: i
!!     call caps%set(caps,'A','aye')
!!     call caps%set(caps,'B','bee')
!!     call caps%set(caps,'C','see')
!!     call caps%set(caps,'D','dee')
!!
!!     write(*,101)(trim(arr(i)),i=1,size(caps%keys)) ! show array
!!     call  caps%del(caps,'A')
!!     call  caps%del(caps,'C')
!!     call  caps%del(caps,'z')
!!     write(*,101)(trim(arr(i)),i=1,size(arr)) ! show array
!!     101 format (1x,*("[",a,"]",:,","))
!!     end program demo_dict_delete
!!
!!    Results:
!!
!!     [z],[xxx],[c],[b],[b],[aaa],[ZZZ],[ZZ]
!!     [z],[xxx],[b],[b],[aaa],[ZZZ],[ZZ]
!!     [z],[xxx],[b],[b],[aaa],[ZZZ],[ZZ]
!!     [z],[xxx],[b],[b],[aaa],[ZZZ],[ZZ]
!!     [z],[xxx],[aaa],[ZZZ],[ZZ]
!!     [z],[xxx],[aaa],[ZZZ]
!!     [z],[xxx],[aaa],[ZZZ]
!!     [xxx],[aaa],[ZZZ]
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine dict_delete(self,key)

! ident_53="@(#)M_list::dict_delete(3f): remove string from sorted allocatable string array if present"

class(dictionary),intent(inout) :: self
character(len=*),intent(in)     :: key
integer                         :: place

   call locate(self%key,key,place)
   if(place.ge.1)then
      call remove(self%key,place)
      call remove(self%value,place)
      call remove(self%count,place)
   endif

end subroutine dict_delete
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    dict_get(3f) - [M_list] get value of key-value pair in a dictionary given key
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine dict_get(dict,key,value)
!!
!!    type(dictionary)            :: dict
!!    character(len=*),intent(in) :: key
!!    character(len=*),intent(in) :: VALUE
!!
!!##DESCRIPTION
!!
!!    get a value given a key from a key-value dictionary
!!
!!    If key is not found in dictionary , return a blank
!!
!!##OPTIONS
!!
!!    DICT     is the dictionary.
!!    KEY      key name
!!    VALUE    value associated with key
!!
!!##EXAMPLES
!!
!!
!! Sample program
!!
!!     program demo_locate
!!     use M_list, only : dictionary
!!     implicit none
!!     type(dictionary)             :: table
!!     integer          :: i
!!
!!     call table%set('A','value for A')
!!     call table%set('B','value for B')
!!     call table%set('C','value for C')
!!     call table%set('D','value for D')
!!     call table%set('E','value for E')
!!     call table%set('F','value for F')
!!     call table%set('G','value for G')
!!     write(*,*)table%get('A')
!!     write(*,*)table%get('B')
!!     write(*,*)table%get('C')
!!     write(*,*)table%get('D')
!!     write(*,*)table%get('E')
!!     write(*,*)table%get('F')
!!     write(*,*)table%get('G')
!!     write(*,*)table%get('H')
!!     end program demo_locate
!!
!!    Results:
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
function dict_get(self,key) result(value)

! ident_54="@(#)M_list::dict_get(3f): get value of key-value pair in dictionary, given key"

!-!class(dictionary),intent(inout) :: self
class(dictionary)               :: self
character(len=*),intent(in)     :: key
character(len=:),allocatable    :: value
integer                         :: place
   call locate(self%key,key,place)
   if(place.lt.1)then
      value=''
   else
      value=self%value(place)(:self%count(place))
   endif
end function dict_get
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!>
!!##NAME
!!    dict_add(3f) - [M_list] add or replace a key-value pair in a dictionary
!!    (LICENSE:PD)
!!
!!##SYNOPSIS
!!
!!   subroutine dict_add(dict,key,value)
!!
!!    type(dictionary)            :: dict
!!    character(len=*),intent(in) :: key
!!    character(len=*),intent(in) :: VALUE
!!
!!##DESCRIPTION
!!    Add or replace a key-value pair in a dictionary.
!!
!!##OPTIONS
!!    DICT     is the dictionary.
!!    key      key name
!!    VALUE    value associated with key
!!
!!##EXAMPLES
!!
!! If string is not found in a sorted array, insert the string
!!
!!     program demo_add
!!     use M_list, only : dictionary
!!     implicit none
!!     type(dictionary) :: dict
!!     integer          :: i
!!
!!     call dict%set('A','b')
!!     call dict%set('B','^')
!!     call dict%set('C',' ')
!!     call dict%set('D','c')
!!     call dict%set('E','ZZ')
!!     call dict%set('F','ZZZZ')
!!     call dict%set('G','z')
!!     call dict%set('A','new value for A')
!!     write(*,'(*(a,"==>","[",a,"]",/))')(trim(dict%key(i)),dict%value(i)(:dict%count(i)),i=1,size(dict%key))
!!     end program demo_add
!!
!!    Results:
!!
!!##AUTHOR
!!    John S. Urban
!!##LICENSE
!!    Public Domain
subroutine dict_add(self,key,value)

! ident_55="@(#)M_list::dict_add(3f): place key-value pair into dictionary, adding the key if required"

class(dictionary),intent(inout) :: self
character(len=*),intent(in)     :: key
character(len=*),intent(in)     :: value
integer                         :: place
integer                         :: place2
   call locate(self%key,key,place)
   if(place.lt.1)then
      place2=iabs(place)
      call insert( self%key,   key,             place2 )
      call insert( self%value, value,           place2 )
      call insert( self%count, len_trim(value), place2 )
   elseif(place.gt.0)then  ! replace instead of insert
      call insert( self%value, value,           place )
      call insert( self%count, len_trim(value), place )
   endif
end subroutine dict_add
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()=
!===================================================================================================================================
end module M_CLI2
!===================================================================================================================================
!()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()()!
!===================================================================================================================================
