# wdate-cpm 

Version 0.1a

A utility for CP/M to read and set the real-time clock on a machine with ROMWBW firmware

## What is this?

`wdate` is a utility for CP/M systems that have Wayne Warthen's
ROMWBW firmware. It reads or sets the real-time clock, using function
calls in the BIOS. It should work on any RTC device that is supported by
ROMWBW, including the internal interrupt-driven timer that is is available
on some systems. 

`wdate` differs from the `rtc.com` utility that is provided with the
ROMWBW version of CP/M in that it only gets and sets the date/time. 
`rtc.com` can also manipulate the nonvolatile RAM in certain clock
devices, and modify the charge controller. However, `wdate` is (I would
argue) easier to use, as it takes its input from the command line, which
can be edited, and it's less fussy about the format. It doesn't require
the date to be set if you only want to change the time, for example.
 In addition, `wdate` has at least some error checking.

`wdate` displays the day-of-week and month as English text, not 
numbers. It calculates the day-of-week from the year, month, and day.
RTC chips usually store a day-of-week value, but it's useless in this
application for two reasons: first, the BIOS does not expose it. Second,
there is no universally-accepted way to interpret it (which day does
the week start on? Is '0' a valid day of the week?) 

## Usage

    A> wdate
    Saturday 27 May 13:14:39 2023

With no arguments, displays the current date and time. 

    A> wdate hr min

With two arguments, sets the time in hours and minutes, without changing date
or seconds

    A> wdate hr min sec

With three arguments, sets the time in hours, minutes, and seconds, without
changing date

    A > wdate year month day hr min sec

With six arguments, sets date and time. All numbers are one or two digits.  The
two-digit year starts at 2000. 

    A > wdate /?

Show a summary of the command-line usage.

## Building

I wrote this utility to be built on CP/M using the Microsoft
Macro80 assembler and Link80 linker. These are available from here:

http://www.retroarchive.org/cpm/lang/m80.com
http://www.retroarchive.org/cpm/lang/l80.com

Assemble all the `.asm` files to produce `.rel` files, then feed all
the `.rel` files into the linker. See the Makefile (for Linux) for
the syntax for these commands. There is no `make` for CP/M, so far as I
know, so building is a bit of a tedious process. However, this utility
_can_ be build and modified on on CP/M itself, with a bit of patience.

## Limitations 

There is some error checking on the input, but it isn't comprehensive. 
`wdate` won't stop you setting the date to April 31st, for example.

`wdate` may behave oddly if the date actually set into the RTC is
nonsensical. The RTC will allow month numbers up to 99, for example.
`wdate` should prevent you entering something this silly, but it can't
prevent another utility doing so.

`wdate` can set the date and time on the interrupt-driven timer, if installed.
However, this timer isn't usually battery-backed, so it won't hold its date and
time in the long term.

Text output is only in English.

## Technical notes

I've tested this utility with the DS1302 clock board designed by 
Ed Brindly, and on the interrupt-driven timer built into my Z180 board.
However, it does not interact with hardware, only BIOS; I would expect it
to work with other hardware. 

`wdate` checks for the non-existence of ROMWBW, and also for failing
operations on the RTC. It will display the terse "No RTC" message 
in both cases.

The ROMWBW functions that manipulate the date and time operate on 
BCD numbers, as RTC chips themselves usually do. `wdate` works in
decimal, so that it can check that the user input makes sense. 
A substantial part of the program's code is taken up by number
format conversion and range checking.  

## Author and legal

`wdate` is maintained by Kevin Boone, and is distributed under the terms of the
GNU Public Licence, v3.0, in the hope that, just maybe, somebody will find it
useful. All the code is original. There is no warranty of any kind.

## Revisions

v0.1a May 2023
First working version


