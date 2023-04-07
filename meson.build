project(
    'M_CLI2',
    'fortran',
    version : '3.2.0',
    license : 'UNLICENSE',
    default_options : [
        'buildtype=debugoptimized',
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
