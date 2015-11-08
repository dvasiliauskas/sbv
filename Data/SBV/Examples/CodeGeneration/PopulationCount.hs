-----------------------------------------------------------------------------
-- |
-- Module      :  Data.SBV.Examples.CodeGeneration.PopulationCount
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- Computing population-counts (number of set bits) and autimatically
-- generating C code.
-----------------------------------------------------------------------------

module Data.SBV.Examples.CodeGeneration.PopulationCount where

import Data.SBV

-----------------------------------------------------------------------------
-- * Reference: Slow but /obviously/ correct
-----------------------------------------------------------------------------

-- | Given a 64-bit quantity, the simplest (and obvious) way to count the
-- number of bits that are set in it is to simply walk through all the bits
-- and add 1 to a running count. This is slow, as it requires 64 iterations,
-- but is simple and easy to convince yourself that it is correct. For instance:
--
-- >>> popCountSlow 0x0123456789ABCDEF
-- 32 :: SWord8
popCountSlow :: SWord64 -> SWord8
popCountSlow inp = go inp 0 0
  where go :: SWord64 -> Int -> SWord8 -> SWord8
        go _ 64 c = c
        go x i  c = go (x `shiftR` 1) (i+1) (ite (x .&. 1 .== 1) (c+1) c)

-----------------------------------------------------------------------------
-- * Faster: Using a look-up table
-----------------------------------------------------------------------------

-- | Faster version. This is essentially the same algorithm, except we
-- go 8 bits at a time instead of one by one, by using a precomputed table
-- of population-count values for each byte. This algorithm /loops/ only
-- 8 times, and hence is at least 8 times more efficient.
popCountFast :: SWord64 -> SWord8
popCountFast inp = go inp 0 0
  where go :: SWord64 -> Int -> SWord8 -> SWord8
        go _ 8 c = c
        go x i c = go (x `shiftR` 8) (i+1) (c + select pop8 0 (x .&. 0xff))

-- | Look-up table, containing population counts for all possible 8-bit
-- value, from 0 to 255. Note that we do not \"hard-code\" the values, but
-- merely use the slow version to compute them.
pop8 :: [SWord8]
pop8 = map popCountSlow [0 .. 255]

-----------------------------------------------------------------------------
-- * Verification
-----------------------------------------------------------------------------

{- $VerificationIntro
We prove that `popCountFast` and `popCountSlow` are functionally equivalent.
This is essential as we will automatically generate C code from `popCountFast`,
and we would like to make sure that the fast version is correct with
respect to the slower reference version.
-}

-- | States the correctness of faster population-count algorithm, with respect
-- to the reference slow version. (We use yices here as it's quite fast for
-- this problem. Z3 seems to take much longer.) We have:
--
-- >>> proveWith yices fastPopCountIsCorrect
-- Q.E.D.
fastPopCountIsCorrect :: SWord64 -> SBool
fastPopCountIsCorrect x = popCountFast x .== popCountSlow x

-----------------------------------------------------------------------------
-- * Code generation
-----------------------------------------------------------------------------

-- | Not only we can prove that faster version is correct, but we can also automatically
-- generate C code to compute population-counts for us. This action will generate all the
-- C files that you will need, including a driver program for test purposes.
--
-- Below is the generated header file for `popCountFast`:
--
-- >>> genPopCountInC
-- == BEGIN: "Makefile" ================
-- # Makefile for popCount. Automatically generated by SBV. Do not edit!
-- <BLANKLINE>
-- # include any user-defined .mk file in the current directory.
-- -include *.mk
-- <BLANKLINE>
-- CC?=gcc
-- CCFLAGS?=-Wall -O3 -DNDEBUG -fomit-frame-pointer
-- <BLANKLINE>
-- all: popCount_driver
-- <BLANKLINE>
-- popCount.o: popCount.c popCount.h
-- 	${CC} ${CCFLAGS} -c $< -o $@
-- <BLANKLINE>
-- popCount_driver.o: popCount_driver.c
-- 	${CC} ${CCFLAGS} -c $< -o $@
-- <BLANKLINE>
-- popCount_driver: popCount.o popCount_driver.o
-- 	${CC} ${CCFLAGS} $^ -o $@
-- <BLANKLINE>
-- clean:
-- 	rm -f *.o
-- <BLANKLINE>
-- veryclean: clean
-- 	rm -f popCount_driver
-- == END: "Makefile" ==================
-- == BEGIN: "popCount.h" ================
-- /* Header file for popCount. Automatically generated by SBV. Do not edit! */
-- <BLANKLINE>
-- #ifndef __popCount__HEADER_INCLUDED__
-- #define __popCount__HEADER_INCLUDED__
-- <BLANKLINE>
-- #include <stdio.h>
-- #include <stdlib.h>
-- #include <inttypes.h>
-- #include <stdint.h>
-- #include <stdbool.h>
-- #include <string.h>
-- #include <math.h>
-- <BLANKLINE>
-- /* The boolean type */
-- typedef bool SBool;
-- <BLANKLINE>
-- /* The float type */
-- typedef float SFloat;
-- <BLANKLINE>
-- /* The double type */
-- typedef double SDouble;
-- <BLANKLINE>
-- /* Unsigned bit-vectors */
-- typedef uint8_t  SWord8 ;
-- typedef uint16_t SWord16;
-- typedef uint32_t SWord32;
-- typedef uint64_t SWord64;
-- <BLANKLINE>
-- /* Signed bit-vectors */
-- typedef int8_t  SInt8 ;
-- typedef int16_t SInt16;
-- typedef int32_t SInt32;
-- typedef int64_t SInt64;
-- <BLANKLINE>
-- /* Entry point prototype: */
-- SWord8 popCount(const SWord64 x);
-- <BLANKLINE>
-- #endif /* __popCount__HEADER_INCLUDED__ */
-- == END: "popCount.h" ==================
-- == BEGIN: "popCount_driver.c" ================
-- /* Example driver program for popCount. */
-- /* Automatically generated by SBV. Edit as you see fit! */
-- <BLANKLINE>
-- #include <stdio.h>
-- #include "popCount.h"
-- <BLANKLINE>
-- int main(void)
-- {
--   const SWord8 __result = popCount(0x1b02e143e4f0e0e5ULL);
-- <BLANKLINE>
--   printf("popCount(0x1b02e143e4f0e0e5ULL) = %"PRIu8"\n", __result);
-- <BLANKLINE>
--   return 0;
-- }
-- == END: "popCount_driver.c" ==================
-- == BEGIN: "popCount.c" ================
-- /* File: "popCount.c". Automatically generated by SBV. Do not edit! */
-- <BLANKLINE>
-- #include "popCount.h"
-- <BLANKLINE>
-- SWord8 popCount(const SWord64 x)
-- {
--   const SWord64 s0 = x;
--   static const SWord8 table0[] = {
--       0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3,
--       3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4,
--       3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2,
--       2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5,
--       3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5,
--       5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3,
--       2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4,
--       4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
--       3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4,
--       4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6,
--       5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5,
--       5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
--   };
--   const SWord64 s11 = s0 & 0x00000000000000ffULL;
--   const SWord8  s12 = table0[s11];
--   const SWord64 s13 = s0 >> 8;
--   const SWord64 s14 = 0x00000000000000ffULL & s13;
--   const SWord8  s15 = table0[s14];
--   const SWord8  s16 = s12 + s15;
--   const SWord64 s17 = s13 >> 8;
--   const SWord64 s18 = 0x00000000000000ffULL & s17;
--   const SWord8  s19 = table0[s18];
--   const SWord8  s20 = s16 + s19;
--   const SWord64 s21 = s17 >> 8;
--   const SWord64 s22 = 0x00000000000000ffULL & s21;
--   const SWord8  s23 = table0[s22];
--   const SWord8  s24 = s20 + s23;
--   const SWord64 s25 = s21 >> 8;
--   const SWord64 s26 = 0x00000000000000ffULL & s25;
--   const SWord8  s27 = table0[s26];
--   const SWord8  s28 = s24 + s27;
--   const SWord64 s29 = s25 >> 8;
--   const SWord64 s30 = 0x00000000000000ffULL & s29;
--   const SWord8  s31 = table0[s30];
--   const SWord8  s32 = s28 + s31;
--   const SWord64 s33 = s29 >> 8;
--   const SWord64 s34 = 0x00000000000000ffULL & s33;
--   const SWord8  s35 = table0[s34];
--   const SWord8  s36 = s32 + s35;
--   const SWord64 s37 = s33 >> 8;
--   const SWord64 s38 = 0x00000000000000ffULL & s37;
--   const SWord8  s39 = table0[s38];
--   const SWord8  s40 = s36 + s39;
-- <BLANKLINE>
--   return s40;
-- }
-- == END: "popCount.c" ==================
genPopCountInC :: IO ()
genPopCountInC = compileToC Nothing "popCount" $ do
        cgSetDriverValues [0x1b02e143e4f0e0e5]  -- remove this line to get a random test value
        x <- cgInput "x"
        cgReturn $ popCountFast x
