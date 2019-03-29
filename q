[33mcommit 5bb9e2be2880295c1a6fd48dd67df8070a1110f3[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 27 20:50:47 2019 +0100

    all emit_*_def coded, debugging syntax WIP

 lib/md0/scanner/manual_macro.ex | 153 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m---[m
 1 file changed, 150 insertions(+), 3 deletions(-)

[33mcommit ec02655b94a3e8daa14fa17018d5f5f173aefcd2[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 27 19:01:11 2019 +0100

    WIP working on emit_*_def; emit_halt_state_def finished

 lib/md0/scanner/manual_macro.ex | 222 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m----------------------------------------[m
 1 file changed, 153 insertions(+), 69 deletions(-)

[33mcommit 0e07569473ad8337500b482d8a2ce345017e59d8[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Thu Mar 7 22:02:29 2019 +0100

    WIP
    
    deciding on syntax for actions
            emit: state, collect: true|before|after

 lib/md0/scanner/manual_macro.ex | 79 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m--[m
 1 file changed, 77 insertions(+), 2 deletions(-)

[33mcommit 8f19d549043f53e3e768d9dbeb793d7142f24ab1[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 6 22:48:56 2019 +0100

    Promising way to create the `def scan(...` definitions

 lib/md0/scanner/manual_macro.ex | 135 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m---------------------------------[m
 lib/md0/toy_macro_scanner.ex    |  59 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/md0/toy_scanner.ex          |  31 [32m++++++++++++++++++++++++++++[m[31m--[m
 test/toy_test.exs               |  12 [32m++++++[m[31m------[m
 4 files changed, 194 insertions(+), 43 deletions(-)

[33mcommit 7e95bd22937842465499d5c1a54181fbc07b3c30[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 6 18:33:04 2019 +0100

    Toy example to sketch out the manual macro

 lib/md0/scanner/manual_macro.ex | 38 [32m++++++++++++++++++++++++++++++++++++++[m
 lib/md0/toy_scanner.ex          | 36 [32m++++++++++++++++++++++++++++++++++++[m
 test/toy_test.exs               | 37 [32m+++++++++++++++++++++++++++++++++++++[m
 3 files changed, 111 insertions(+)

[33mcommit 92a9c9b775d2244dfd7e54fb8663352c92c06aa5[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 6 08:49:03 2019 +0100

    manual macro scanner dev started

 lib/md0/manual_macro_scanner.ex | 86 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/mix/tasks/bench.ex          |  2 [32m+[m[31m-[m
 2 files changed, 87 insertions(+), 1 deletion(-)

[33mcommit 7737b49aab329f3c747aa402729f8439f0705f37[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 6 08:32:43 2019 +0100

    Removed all compilation warnings

 lib/md0/macro_scanner.ex                      | 82 [32m+++++++++++++++++++++++++++++++++++++++++[m[31m-----------------------------------------[m
 lib/md0/scanner/table_scanner/helper.ex       |  4 [32m++[m[31m--[m
 lib/mix/tasks/bench.ex                        |  7 [32m+[m[31m------[m
 test/table_scanner/accu_table_to_map_test.exs |  6 [32m+++[m[31m---[m
 4 files changed, 47 insertions(+), 52 deletions(-)

[33mcommit b8f7f7448916909baf4714f77bfc395dcf2cf033[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Wed Mar 6 08:30:12 2019 +0100

    scoped transition macro does work

 lib/md0/macro_scanner.ex         | 112 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m------------------------------------------------[m
 lib/md0/scanner/table_scanner.ex |  21 [32m+++++++++++++++++[m[31m----[m
 mix.exs                          |   1 [32m+[m
 3 files changed, 82 insertions(+), 52 deletions(-)

[33mcommit c80f4f38dedceeb40fa418d07905860217e650fd[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Tue Mar 5 22:54:51 2019 +0100

    Simple deftransition macro does work now

 lib/md0/macro_scanner.ex                      | 107 [32m++++++++++++++++++++++++++++++++++++++++++++++++[m[31m-----------------------------------------------------------[m
 lib/md0/scanner/table_scanner.ex              |   1 [32m+[m
 lib/md0/scanner/table_scanner/helper.ex       |  11 [32m+++++++++[m[31m--[m
 test/accu_test.exs                            |   9 [31m---------[m
 test/table_scanner/accu_table_to_map_test.exs |  35 [32m+++++++++++++++++++++++++[m[31m----------[m
 5 files changed, 83 insertions(+), 80 deletions(-)

[33mcommit 4609f638e32748dd0b803f7bcca48237add423b0[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Tue Mar 5 21:38:20 2019 +0100

    put_deep

 lib/accu.ex                                   | 24 [32m++++++++++++++++++++++++[m
 lib/accu_tester.ex                            |  5 [32m+++++[m
 lib/md0/lex_scanner.ex                        | 25 [31m-------------------------[m
 lib/md0/scanner/table_macros.ex               | 84 [31m------------------------------------------------------------------------------------[m
 lib/md0/scanner/table_scanner.ex              | 14 [32m+++++++++++++[m[31m-[m
 lib/md0/scanner/table_scanner/helper.ex       | 52 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/md0/tools/map.ex                          | 20 [32m++++++++++++++++++++[m
 mix.exs                                       |  2 [32m++[m
 test/accu_test.exs                            |  9 [32m+++++++++[m
 test/support/accu_tester.ex                   |  5 [32m+++++[m
 test/table_scanner/accu_table_to_map_test.exs | 24 [32m++++++++++++++++++++++++[m
 test/tools/put_deep_test.exs                  | 33 [32m+++++++++++++++++++++++++++++++++[m
 12 files changed, 187 insertions(+), 110 deletions(-)

[33mcommit 4293171b3c3b658f879e353d77cc782fd7365221[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Sun Mar 3 16:12:47 2019 +0100

    Working on macros for table scanner

 lib/att_inject.ex                     | 33 [31m---------------------------------[m
 lib/injected.ex                       |  7 [31m-------[m
 lib/md0.ex                            | 18 [31m------------------[m
 lib/md0/lex_scanner.ex                | 25 [32m+++++++++++++++++++++++++[m
 lib/md0/macro_scanner.ex              | 70 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m[31m---[m
 lib/md0/scanner/table_scanner.ex      | 21 [32m+++++++++++++++++++++[m
 lib/md0/scanner/table_scanner_impl.ex | 57 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/mix/tasks/bench.ex                | 16 [32m++++++++++++[m[31m----[m
 test/md0_test.exs                     | 17 [32m+++++++++[m[31m--------[m
 xxx                                   |  1 [31m-[m
 10 files changed, 191 insertions(+), 74 deletions(-)

[33mcommit 288c6528a3b8a36febfe9a2aa79b3f10a1824b6e[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Thu Jan 3 18:26:58 2019 +0100

    Working on Macro for table scanner

 lib/att_inject.ex               | 33 [32m+++++++++++++++++++++++++++++++++[m
 lib/injected.ex                 |  7 [32m+++++++[m
 lib/md0/injected_fns.ex         | 12 [32m++++++++++++[m
 lib/md0/macro_scanner.ex        |  7 [32m+++++++[m
 lib/md0/rgx_scanner.ex          |  2 [32m+[m[31m-[m
 lib/md0/scanner/macros.ex       | 33 [31m---------------------------------[m
 lib/md0/scanner/rgx_macros.ex   | 33 [32m+++++++++++++++++++++++++++++++++[m
 lib/md0/scanner/table_macros.ex | 84 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/mix/tasks/bench.ex          |  4 [32m++[m[31m--[m
 test/md0_test.exs               | 14 [32m++++++++[m[31m------[m
 10 files changed, 187 insertions(+), 42 deletions(-)

[33mcommit 3549ec38e8fe7e436cf17145e54a060a22d9ccc2[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Sat Dec 29 21:30:21 2018 +0100

    Table Scanner, Rgx Scanner && Table Scanner

 data/Syntax.md           | 888 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/md0/table_scanner.ex | 155 [32m+++++++++++++++[m[31m---------[m
 lib/mix/tasks/bench.ex   |  88 [32m++++++++++++++[m
 mix.exs                  |   6 [32m+[m
 test/md0_test.exs        |  14 [32m+++[m
 xxx                      |   1 [32m+[m
 6 files changed, 1097 insertions(+), 55 deletions(-)

[33mcommit ff798cb4f168cc91fd4f2c2441741d7daaefe9a7[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Sat Dec 29 13:49:35 2018 +0100

    MD0 scanners implemented: Regex and Manual

 lib/md0/manual_scanner.ex | 86 [32m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/md0/rgx_scanner.ex    | 45 [32m++++++++++++++++++++[m[31m-------------------------[m
 lib/md0/table_scanner.ex  | 77 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 mix.exs                   |  1 [32m+[m
 mix.lock                  |  4 [32m++++[m
 test/md0_test.exs         | 38 [32m+++++++++++++++++++++++++++++++[m[31m-------[m
 6 files changed, 219 insertions(+), 32 deletions(-)

[33mcommit 6c659dc4081f8ddb91a1d4f7e41cfd62a9807259[m
Author: RobertDober <robert.dober@gmail.com>
Date:   Thu Dec 27 21:59:45 2018 +0100

    initial commit

 .formatter.exs            |  4 [32m++++[m
 .gitignore                | 27 [32m+++++++++++++++++++++[m[31m------[m
 README.md                 | 21 [32m+++++++++++++++++++++[m
 config/config.exs         | 30 [32m++++++++++++++++++++++++++++++[m
 lib/md0.ex                | 18 [32m++++++++++++++++++[m
 lib/md0/rgx_scanner.ex    | 71 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 lib/md0/scanner/macros.ex | 33 [32m+++++++++++++++++++++++++++++++++[m
 mix.exs                   | 28 [32m++++++++++++++++++++++++++++[m
 test/md0_test.exs         | 34 [32m++++++++++++++++++++++++++++++++++[m
 test/test_helper.exs      |  1 [32m+[m
 10 files changed, 261 insertions(+), 6 deletions(-)

[33mcommit 9dbd35fde6be3214076d1b3a0eccb078ca986854[m
Author: Robert Dober <robert.dober@gmail.com>
Date:   Sat Dec 29 13:51:01 2018 +0100

    Initial commit

 .gitignore |   9 [32m+++++++[m
 LICENSE    | 201 [32m+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++[m
 2 files changed, 210 insertions(+)
