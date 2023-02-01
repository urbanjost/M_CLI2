## GPF Changelog

The intent of this changelog is to keep everyone in the loop about
what's new in the M_CLI2 project. It is a curated, chronologically ordered
list of notable changes including records of change such as bug fixes,
new features, changes, and relevant notifications.
---
**2023-02-01**  ZUO Zhihua <https://github.com/zoziha>
### :green_circle: ADD:
   + add-meson-support
<!-- zuo.zhihua@qq.com -->
---
**2022-11-23**  John S. Urban  <https://github.com/urbanjost>
### :green_circle: ADD:
   + Developer debug mode can be invoked by setting the environment
     variable $CLI_DEBUG_MODE to TRUE.
### :red_circle: FIX:
   + The default response file on MSWindows in some environments 
     had to be named PROGRAM_NAME.exe.rsp instead of PROGRAM_NAME.rsp,
     contrary to the documentation. The ".exe" is, as intended, not
     used or required anymore.
---
**2022-11-15**  John S. Urban  <https://github.com/urbanjost>
### :red_circle: FIX:
   + locate_c did not calculate the correct number of tries to locate
     keywords in the dictionary on 32-bit platforms because INT() was
     being used instead of NINT().
---
**2020-08-03**  John S. Urban  <https://github.com/urbanjost>
### :green_circle: ADD:
   + initial commit on github
---
<!--
### :green_circle: ADD:
### :orange_circle: DIFF:
### :red_circle: FIX:
   - [x] manpage
   - [x] demo program
   - [ ] unit test
-->
