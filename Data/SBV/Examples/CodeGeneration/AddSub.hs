-----------------------------------------------------------------------------
-- |
-- Module      :  Data.SBV.Examples.CodeGeneration.AddSub
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- Simple code generation example.
-----------------------------------------------------------------------------

module Data.SBV.Examples.CodeGeneration.AddSub where

import Data.SBV

-- | Simple function that returns add/sum of args
addSub :: SWord8 -> SWord8 -> (SWord8, SWord8)
addSub x y = (x+y, x-y)

-- | Generate C code for addSub. Here's the output showing the generated C code:
--
-- >>> genAddSub
-- == BEGIN: "Makefile" ================
-- # Makefile for addSub. Automatically generated by SBV. Do not edit!
-- <BLANKLINE>
-- # include any user-defined .mk file in the current directory.
-- -include *.mk
-- <BLANKLINE>
-- CC?=gcc
-- CCFLAGS?=-Wall -O3 -DNDEBUG -fomit-frame-pointer
-- <BLANKLINE>
-- all: addSub_driver
-- <BLANKLINE>
-- addSub.o: addSub.c addSub.h
-- 	${CC} ${CCFLAGS} -c $< -o $@
-- <BLANKLINE>
-- addSub_driver.o: addSub_driver.c
-- 	${CC} ${CCFLAGS} -c $< -o $@
-- <BLANKLINE>
-- addSub_driver: addSub.o addSub_driver.o
-- 	${CC} ${CCFLAGS} $^ -o $@
-- <BLANKLINE>
-- clean:
-- 	rm -f *.o
-- <BLANKLINE>
-- veryclean: clean
-- 	rm -f addSub_driver
-- == END: "Makefile" ==================
-- == BEGIN: "addSub.h" ================
-- /* Header file for addSub. Automatically generated by SBV. Do not edit! */
-- <BLANKLINE>
-- #ifndef __addSub__HEADER_INCLUDED__
-- #define __addSub__HEADER_INCLUDED__
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
-- void addSub(const SWord8 x, const SWord8 y, SWord8 *sum,
--             SWord8 *dif);
-- <BLANKLINE>
-- #endif /* __addSub__HEADER_INCLUDED__ */
-- == END: "addSub.h" ==================
-- == BEGIN: "addSub_driver.c" ================
-- /* Example driver program for addSub. */
-- /* Automatically generated by SBV. Edit as you see fit! */
-- <BLANKLINE>
-- #include <stdio.h>
-- #include "addSub.h"
-- <BLANKLINE>
-- int main(void)
-- {
--   SWord8 sum;
--   SWord8 dif;
-- <BLANKLINE>
--   addSub(132, 241, &sum, &dif);
-- <BLANKLINE>
--   printf("addSub(132, 241, &sum, &dif) ->\n");
--   printf("  sum = %"PRIu8"\n", sum);
--   printf("  dif = %"PRIu8"\n", dif);
-- <BLANKLINE>
--   return 0;
-- }
-- == END: "addSub_driver.c" ==================
-- == BEGIN: "addSub.c" ================
-- /* File: "addSub.c". Automatically generated by SBV. Do not edit! */
-- <BLANKLINE>
-- #include "addSub.h"
-- <BLANKLINE>
-- void addSub(const SWord8 x, const SWord8 y, SWord8 *sum,
--             SWord8 *dif)
-- {
--   const SWord8 s0 = x;
--   const SWord8 s1 = y;
--   const SWord8 s2 = s0 + s1;
--   const SWord8 s3 = s0 - s1;
-- <BLANKLINE>
--   *sum = s2;
--   *dif = s3;
-- }
-- == END: "addSub.c" ==================
--
genAddSub :: IO ()
genAddSub = compileToC outDir "addSub" $ do
        x <- cgInput "x"
        y <- cgInput "y"
        -- leave the cgDriverVals call out for generating a driver with random values
        cgSetDriverValues [132, 241]
        let (s, d) = addSub x y
        cgOutput "sum" s
        cgOutput "dif" d
 where -- use Just "dirName" for putting the output to the named directory
       -- otherwise, it'll go to standard output
       outDir = Nothing
