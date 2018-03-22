#ifndef TEST_COMMON_H
#define TEST_COMMON_H


#define col_ltgray "\033[37m";
#define col_purple "\033[35m";
#define col_green  "\033[32m";
#define col_cyan   "\033[36m";
#define col_brown  "\033[33m";
#define col_norm   "\033[00m";
#define col_background  "\033[07m";
#define col_brighten "\033[01m";
#define col_underline "\033[04m";
#define col_blink "\033[05m";
#define col_red "\033[31m";

#define PRINT_TEST_GROUP(a) doLog(0,"%s%s%s", "\033[32m", (a), "\033[00m");
#define PRINT_TEST(a) doLog(0,"%s%s%s", "\033[33m", (a), "\033[00m");

#endif
