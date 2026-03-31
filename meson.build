project(
    'M_CLI2',
    'fortran',
    version : '3.2.0',
    license : 'UNLICENSE',
    default_options : [
        'buildtype=debugoptimized',
        'fortran_std=f2008',
        'default_library=both',
    ]
)

M_CLI2_src = files(
    'src/M_CLI2.F90'
)

M_CLI2_lib = library(
    meson.project_name(),
    sources : M_CLI2_src,
    version : meson.project_version(),
    install : true,
)

M_CLI2_inc = M_CLI2_lib.private_dir_include()
M_CLI2_dep = declare_dependency(
    link_with : M_CLI2_lib,
    include_directories : M_CLI2_inc,
)

test(
    'runTests',
    executable(
        'runTests',
        'test/test_suite_M_CLI2.f90',
        dependencies : M_CLI2_dep,
    ),
)

M_CLI2_lic = files(
    'LICENSE',
)
install_data(
    M_CLI2_lic,
    install_dir : join_paths(get_option('prefix'), 'share', 'licenses', meson.project_name()),
)

if host_machine.system() == 'windows'
    symbols_file = 'lib'+meson.project_name()+'-'+meson.project_version().split('.')[0]+'.dll.symbols'
    obj_file = 'src_M_CLI2.F90.obj'
else
    symbols_file = 'lib'+meson.project_name()+'.so.'+meson.project_version()+'.symbols'
    obj_file = 'src_M_CLI2.F90.o'
endif
install_subdir(M_CLI2_lib.path()+'.p',
    install_dir: 'include'/meson.project_name(),
    strip_directory: true,
    exclude_files: [
        'depscan.dd',
        meson.project_name()+'-deps.json',
        meson.project_name()+'.dat',
        symbols_file,
        obj_file,
    ]
)

pkg = import('pkgconfig')
pkg.generate(
    name : meson.project_name(),
    description : 'Fortran commandline-interface using a simple prototype command',
    version : meson.project_version(),
    libraries : M_CLI2_lib,
    subdirs : meson.project_name(),
)
