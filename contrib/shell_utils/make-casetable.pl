#!/usr/bin/perl
#
# usage: make-casetable.pl <infile> <outfile1> <outfile2>
#        make-casetable.pl UnicodeData.txt utf16_casetable.h utf16_case.c
#
# (c) 2011 by HAT <hat@fa2.so-net.ne.jp>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#

# See
# http://www.unicode.org/reports/tr44/
# http://www.unicode.org/Public/UNIDATA/UnicodeData.txt

# One block has 64 chars.
#
# BMP
# block    0 = dummy
# block    1 = U+0000 - U+003F
# block    2 = U+0040 - U+007F
# .....
# block 1024 = U+FFC0 - U+FFFF
# block 1025 = dummy
#
# Surrogate Pair
# block  1024 = dummy
# block  1025 = U+010000 - U+01003F
# block  1026 = U+010040 - U+01007F
# .....
# block 17408 = U+10FFC0 - U+10FFFF
# block 17409 = dummy
#
# Dummy block is for edge detection.
# If block include upper/lower chars, block_enable[]=1.

use strict;
use warnings;

our $code0;
our $Name1;
our $General_Category2;
our $Canonical_Combining_Class3;
our $Bidi_Class4;
our $Decomposition_Mapping5;
our $Numeric_Value6;
our $Numeric_Value7;
our $Numeric_Value8;
our $Bidi_Mirrored9;
our $Unicode_1_Name10;
our $ISO_Comment11;
our $Simple_Uppercase_Mapping12;
our $Simple_Lowercase_Mapping13;
our $Simple_Titlecase_Mapping14;

our $hex_code0;
our $Mapping;
our $hex_Mapping;

our $char;
our $sp;
our $block;

our @table;
our @table_sp;

our @block_enable;
our @block_enable_sp;

our $table_no;
our $block_start;
our $block_end;
our $char_start;
our $char_end;

open(CHEADER, ">$ARGV[1]");
open(CSOURCE, ">$ARGV[2]");

printf (CHEADER "\/\*\n");
printf (CHEADER "DO NOT EDIT BY HAND\!\!\!\n");
printf (CHEADER "\n");
printf (CHEADER "This file is generated by\n");
printf (CHEADER " contrib/shell_utils/make-casetable.pl %s %s %s\n", $ARGV[0], $ARGV[1], $ARGV[2]);
printf (CHEADER "\n");
printf (CHEADER "%s is got from\n", $ARGV[0]);
printf (CHEADER "http\:\/\/www.unicode.org\/Public\/UNIDATA\/UnicodeData.txt\n");
printf (CHEADER "\*\/\n");
printf (CHEADER "\n");

printf (CSOURCE "\/\*\n");
printf (CSOURCE "DO NOT EDIT BY HAND\!\!\!\n");
printf (CSOURCE "\n");
printf (CSOURCE "This file is generated by\n");
printf (CSOURCE " contrib/shell_utils/make-casetable.pl %s %s %s\n", $ARGV[0], $ARGV[1], $ARGV[2]);
printf (CSOURCE "\n");
printf (CSOURCE "%s is got from\n", $ARGV[0]);
printf (CSOURCE "http\:\/\/www.unicode.org\/Public\/UNIDATA\/UnicodeData.txt\n");
printf (CSOURCE "\*\/\n");
printf (CSOURCE "\n");
printf (CSOURCE "\#include \<stdint.h\>\n");
printf (CSOURCE "\#include \<atalk\/unicode.h\>\n");
printf (CSOURCE "\#include \"%s\"\n", $ARGV[1]);
printf (CSOURCE "\n");

&make_array("upper");
&make_array("lower");

printf (CHEADER "\/\* EOF \*\/\n");
printf (CSOURCE "\/\* EOF \*\/\n");

close(CHEADER);
close(CSOURCE);


###########################################################################
sub make_array{

    # init table -----------------------------------------------------

    for ($char = 0 ; $char <= 0xFFFF ; $char++) {
        $table[$char][0] = $char;       # mapped char
        $table[$char][1] = $char;       # orig char
        $table[$char][2] = "";          # char name
    }

    for ($char = 0x10000 ; $char <= 0x10FFFF ; $char++) {
        $sp = ((0xD800 - (0x10000 >> 10) + ($char >> 10)) << 16)
            + (0xDC00 + ($char & 0x3FF));
        $table_sp[$char][0] = $sp;      # mapped surrogate pair
        $table_sp[$char][1] = $sp;      # orig surrogate pair
        $table_sp[$char][2] = $char;    # mapped char
        $table_sp[$char][3] = $char;    # orig char
        $table_sp[$char][4] = "";       # char name
    }

    for ($block = 0 ; $block <= 1025 ; $block++) {
        $block_enable[$block] = 0;
    }

    $block_enable[1] = 1;           # ASCII block is forcibly included
    $block_enable[2] = 1;           # in the array for Speed-Up.

    for ($block = 1024 ; $block <= 17409 ; $block++) {
        $block_enable_sp[$block] = 0;
    }

    # write data to table --------------------------------------------

    open(UNICODEDATA, "<$ARGV[0]");

    while (<UNICODEDATA>) {
        chop;
        (
            $code0,
            $Name1,
            $General_Category2,
            $Canonical_Combining_Class3,
            $Bidi_Class4,
            $Decomposition_Mapping5,
            $Numeric_Value6,
            $Numeric_Value7,
            $Numeric_Value8,
            $Bidi_Mirrored9,
            $Unicode_1_Name10,
            $ISO_Comment11,
            $Simple_Uppercase_Mapping12,
            $Simple_Lowercase_Mapping13,
            $Simple_Titlecase_Mapping14
        ) = split(/\;/);

        if ($_[0] eq "upper") {
            $Mapping = $Simple_Uppercase_Mapping12;
        } elsif ($_[0] eq "lower") {
            $Mapping = $Simple_Lowercase_Mapping13;
        } else {
            exit(1);
        }

        next if ($Mapping eq "");

        $hex_code0 = hex($code0);
        $hex_Mapping = hex($Mapping);

        if ($hex_code0 <= 0xFFFF) {
            $table[$hex_code0][0] = $hex_Mapping;
            #table[$hex_code0][1]   already set
            $table[$hex_code0][2] = $Name1;
            $block_enable[($hex_code0 / 64) +1] = 1;
        } else {
            $sp = ((0xD800 - (0x10000 >> 10) + ($hex_Mapping >> 10)) << 16)
                + (0xDC00 + ($hex_Mapping & 0x3FF));
            $table_sp[$hex_code0][0] = $sp;
            #table_sp[$hex_code0][1]   already set
            $table_sp[$hex_code0][2] = $hex_Mapping;
            #table_sp[$hex_code0][3]   already set
            $table_sp[$hex_code0][4] = $Name1;
            $block_enable_sp[($hex_code0 / 64) +1] = 1;
        }
    }

    close(UNICODEDATA);

    # array for BMP --------------------------------------------------

    printf(CSOURCE "\/*******************************************************************\n");
    printf(CSOURCE " Convert a wide character to %s case.\n", $_[0]);
    printf(CSOURCE "*******************************************************************\/\n");
    printf(CSOURCE "ucs2\_t to%s\_w\(ucs2\_t val\)\n", $_[0]);
    printf(CSOURCE "{\n");

    $table_no = 1;

    for ($block = 1 ; $block <= 1024 ; $block++) {

        # rising edge detection
        if ($block_enable[$block - 1] == 0 && $block_enable[$block] == 1) {
            $block_start = $block;
        }

        # falling edge detection
        if ($block_enable[$block] == 1 && $block_enable[$block + 1] == 0) {
            $block_end = $block;

            $char_start = ($block_start -1)* 64;
            $char_end = ($block_end * 64) -1;

            printf(CHEADER "static const uint16\_t %s\_table\_%d\[%d\] \= \{\n",
                   $_[0], $table_no, $char_end - $char_start +1);

            for ($char = $char_start ; $char <= $char_end ; $char++) {
                printf(CHEADER "  0x%04X, /*U\+%04X*/ /*%s*/\n",
                       $table[$char][0],
                       $table[$char][1],
                       $table[$char][2]
                   );
            }
            printf(CHEADER "\}\;\n");
            printf(CHEADER "\n");

            if ($char_start == 0x0000) {
                printf(CSOURCE "    if \( val \<\= 0x%04X)\n",
                       $char_end);
                printf(CSOURCE "        return %s\_table\_%d\[val]\;\n",
                       $_[0], $table_no);
            } else {
                printf(CSOURCE "    if \( val \>\= 0x%04X \&\& val \<\= 0x%04X)\n",
                       $char_start, $char_end);
                printf(CSOURCE "        return %s\_table\_%d\[val-0x%04X\]\;\n",
                       $_[0], $table_no, $char_start);
            }
            printf(CSOURCE "\n");

            $table_no++;
        }
    }

    printf(CSOURCE "\treturn \(val\)\;\n");
    printf(CSOURCE "\}\n");
    printf(CSOURCE "\n");

    # array for Surrogate Pair ---------------------------------------

    printf(CSOURCE "\/*******************************************************************\n");
    printf(CSOURCE " Convert a surrogate pair to %s case.\n", $_[0]);
    printf(CSOURCE "*******************************************************************\/\n");
    printf(CSOURCE "uint32\_t to%s\_sp\(uint32\_t val\)\n", $_[0]);
    printf(CSOURCE "{\n");

    $table_no = 1;

    for ($block = 1025 ; $block <= 17408 ; $block++) {

        # rising edge detection
        if ((($block_enable_sp[$block - 1] == 0) || ((($block - 1) & 0xF) == 0))
                && ($block_enable_sp[$block] == 1)) {
            $block_start = $block;
        }

        # falling edge detection
        if (($block_enable_sp[$block] == 1) &&
                ((($block - 1) & 0xF == 0xF) || ($block_enable_sp[$block + 1] == 0))) {
            $block_end = $block;

            $char_start = ($block_start -1)* 64;
            $char_end = ($block_end * 64) -1;

            printf(CHEADER "static const uint32\_t %s\_table\_sp\_%d\[%d\] \= \{\n",
                   $_[0], $table_no, $char_end - $char_start +1);

            for ($char = $char_start ; $char <= $char_end ; $char++) {
                printf(CHEADER "  0x%08X, /*0x%08X*/ /*U\+%06X*/ /*U\+%06X*/ /*%s*/\n",
                       $table_sp[$char][0],
                       $table_sp[$char][1],
                       $table_sp[$char][2],
                       $table_sp[$char][3],
                       $table_sp[$char][4]
                   );
            }
            printf(CHEADER "\}\;\n");
            printf(CHEADER "\n");

            printf(CSOURCE "    if \( val \>\= 0x%08X \&\& val \<\= 0x%08X)\n",
                   $table_sp[$char_start][1], $table_sp[$char_end][1]);
            printf(CSOURCE "        return %s\_table\_sp\_%d\[val-0x%08X\]\;\n",
                   $_[0], $table_no, $table_sp[$char_start][1]);
            printf(CSOURCE "\n");

            $table_no++;
        }
    }

    printf(CSOURCE "\treturn \(val\)\;\n");
    printf(CSOURCE "\}\n");
    printf(CSOURCE "\n");
}

# EOF
