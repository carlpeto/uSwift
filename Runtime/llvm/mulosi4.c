/*===-- mulosi4.c - Implement __mulosi4 -----------------------------------===
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is dual licensed under the MIT and the University of Illinois Open
 * Source Licenses. See LICENSE.TXT for details.
 *
 * ===----------------------------------------------------------------------===
 *
 * This file implements __mulosi4 for the compiler_rt library.
 *
 * ===----------------------------------------------------------------------===
 */

// #include "int_lib.h"

#ifndef CHAR_BIT
#define CHAR_BIT 8
#endif

#ifndef si_int
#define si_int int
#endif


/* Returns: a * b */

/* Effects: sets *overflow to 1  if a * b overflows */

int
__mulosi4(int a, int b, int* overflow)
{
    const int N = (int)(sizeof(int) * CHAR_BIT);
    const int MIN = (int)1 << (N-1);
    const int MAX = ~MIN;
    *overflow = 0; 
    si_int result = a * b;
    if (a == MIN)
    {
        if (b != 0 && b != 1)
	    *overflow = 1;
	return result;
    }
    if (b == MIN)
    {
        if (a != 0 && a != 1)
	    *overflow = 1;
        return result;
    }
    int sa = a >> (N - 1);
    int abs_a = (a ^ sa) - sa;
    int sb = b >> (N - 1);
    int abs_b = (b ^ sb) - sb;
    if (abs_a < 2 || abs_b < 2)
        return result;
    if (sa == sb)
    {
        if (abs_a > MAX / abs_b)
            *overflow = 1;
    }
    else
    {
        if (abs_a > MIN / -abs_b)
            *overflow = 1;
    }
    return result;
}
