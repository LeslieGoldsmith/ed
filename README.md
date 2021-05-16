# ed

Q line editor and full-screen interface editor

Contains two different workspace-centric function editors,
`ed` and `qed`.  `ed` shells out to the OS to invoke an
external editor of choice, and `qed` edits entirely within Q
using a line-mode editor.

# Usage

| Name and Syntax | Description |
| --------------- | ----------- |
| `ed name` | Edits the named function using the OS editor specified by the variable `.ed.ED` |
| `qed name` | Edits the named function using a line-mode editor running within the workspace |

Loading the editor file `ed.q` aliases the global names `ed` and `qed` to `.ws.ed` and `.ws.qed`.

## The `ed` Editor

Define the variable `.ed.ED` to refer to the external editor of choice.  Editing occurs entirely
within the context of the chosen editor. By default, under Windows `ed` uses Notepad++; there is
no default editor for Linux.

To keep changes made in the external editor, save the function in the editor and
exit back to Q.  If `ed` cannot define the function in Q (for example, if it has an
expression that can't be parsed), enter any key when
prompted to return to the editor with the changes intact, or `\q` to discard
the changes.

## The `qed` Editor

`qed` is a line-mode editor written entirely in Q. `qed` starts by displaying all lines of the specified function,
and prompting in insert mode at a line before the closing `}`.  If the function is defined on a single
line, `qed` prompts after that line.

Valid `qed` commands are as follows:

| Command | Description |
| --------| ----------- |
| `[n]` | Moves to line `n`; prepares to insert a new line if line `n` does not exist |
| `[n] text` | Defines (or redefines) line `n` |
| | |
| `[~n1 n2 n3]` | Deletes the specified line or lines |
| `[n~m]` | Deletes from line `n` to `m` inclusively |
| | |
| `[$]` | Displays all lines |
| `[$n]` |Displays from line `n` to the end |
| `[n$]` |Displays line `n` |
| | |
| `[n$m]` | Edits line `n`, setting the cursor to position `m` (see below) |
| | |
| `\w` | Saves the function and exits; stays in the editor on failure |
| `\q` | Quits (discarding changes) |

Lines in a `qed` session are initially numbered consecutively starting at `[0]`.
Line numbers can be fractional; for example, line 2.5 falls between lines 2 and 3, and line 2.51 falls between lines 2.5 and 2.6.
`qed` attempts to make it difficult to overwrite an existing line when in insert mode, by
choosing line numbers that do not already exist.

When editing a line, the following commands are supported under the displayed line:

| Command | Description |
| --------| ----------- |
| `,xxx` | Inserts text (including any trailing spaces) before the character above `,`; redisplays the line and remains in edit mode |
| `.xxx` | Inserts text (including any trailing spaces) before the character above `.`; moves to the next line |
| `/ //` | Deletes the characters immediately above slashes; can be combined with trailing `,xxx` or `.xxx` |

In edit mode, invalid characters are ignored.  Because backspacing over a prompt
is not permitted in Q, the cursor position `m` specified by `[n$m]` should be _at
or before the position of interest_; space or tab over to get to the desired
character position.  As a special case, if `m` is 0 the cursor is positioned at
the end of the line and the edit phase is bypassed.

Any part of a line can be edited, including the line number itself provided that
the cursor position is suitably to the left.  If the line number is changed, the
old line remains and the new line either replaces an existing line or is
inserted into the appropriate position in the function.  This provides a simple
way to duplicate a line.

The function name can also be changed.  If it is, the new function replaces any
existing function of the same name and the original version is left unchanged.

### Example

This example illustrates the interactive development of a function that generates random trade data. We begin by defining some
global variables and then editing (or in this case, defining) the function `build`.

```
q)n:5000 / Number of trades
q)s:1000 / Number of symbols
q)st:09:30t / Start time
q)et:16t / End time
q)h:14 / Historical days

q)qed`build
[0]   build:{
[1]    }
[0.1] d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[0.2] usym:neg[s]?`3; / Unique symbols
[0.3] ps:1+s?99f; / Starting prices
[0.4] p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
[0.5] trade::flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100); / Build trade table
[0.6] \w
build defined
```

Let's display what we have defined.

```
q)build
{
d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
usym:neg[s]?`3; / Unique symbols
ps:1+s?99f; / Starting prices
p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
trade::flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100); / Build trade table
 }
 ```
 
Next, we execute the function to ensure there are no obvious errors. The computed trade data is
available as a global variable.

```
q)build[]
q)count trade
5000
q)2#trade
date       time         sym price    size
-----------------------------------------
2021.05.06 13:46:32.914 ebm 50.90974 9300
2021.05.04 09:49:34.094 okh 79.07636 8000
```

Let's increase the symbol length from 3 to 4, add a parameter that specifies the number of trades to generate, and return
the trade data as the explicit result.

```
q)qed`build
[0]   build:{
[1]   d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[2]   usym:neg[s]?`3; / Unique symbols
[3]   ps:1+s?99f; / Starting prices
[4]   p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
[5]   trade::flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100); / Build trade table
[6]    }
[5.1] [2$10]
[2]   usym:neg[s]?`3; / Unique symbols
                   /,4
[2]   usym:neg[s]?`4; / Unique symbols
                    .
[3]   [2$]
[2]   usym:neg[s]?`4; / Unique symbols
[2]   [0$0]
[0]   build:{[n]
[1]   [5$4]
[5]   trade::flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100); / Build trade table
      ///////                                                                /.
[6]   [$]
[0]   build:{[n]
[1]   d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[2]   usym:neg[s]?`4; / Unique symbols
[3]   ps:1+s?99f; / Starting prices
[4]   p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
[5]   flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100) / Build trade table
[6]    }
[7]   \w
build defined
q)count trade:build 5000000
5000000
q)2#trade
date       time         sym  price    size
------------------------------------------
2021.05.04 14:10:15.762 mgec 98.52243 6000
2021.05.10 12:53:31.019 amij 78.0223  9200
q)\ts build 5000000
3664 302002416
```

Performance seems to be quite poor when a large number of trades is involved. Let's profile the code to see where the problem lies.

```
q)\l prof.q
q).prof.prof`build
q)build 5000000;
q).prof.report[]
Name  Line Stmt                           Count Total     Own       Pct
--------------------------------------------------------------------------
build 4    p:{[usym;ps;s]ps[usym?s]+rand  1     00:03.473 00:03.473 95.49%
build 5    flip`date`time`sym`price`size! 1     00:00.163 00:00.163 4.49%
build 0    d@:where 1<(d:.z.D-til h)mod 7 1     00:00.000 00:00.000 0.00%
build 2    usym:neg[s]?`4;                1     00:00.000 00:00.000 0.11%
build 3    ps:1+s?99f;                    1     00:00.000 00:00.000 0.00%
```

The problem is line 4. Let's look a little closer by introducing a break point and experimenting in the context of the suspended function.

```
q).prof.unprof`

q)qed`build
[0]   build:{[n]
[1]   d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[2]   usym:neg[s]?`4; / Unique symbols
[3]   ps:1+s?99f; / Starting prices
[4]   p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
[5]   flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100) / Build trade table
[6]    }
[5.1] [3.1]1+`a; / Intentional error
[3.2] \w
build defined
q)build 5000000
type error
{}[4]   1+`a; / Intentional error
         ^
q))count usym
1000
q))\ts sym:n?usym
56 100663504
q))\ts {[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym
3451 180663968
```

The problem is the repeated look-ups of each nonunique symbol in the unique symbol list. This is simple to improve, by
doing the look-up once.

```
q))\ts ps[usym?sym]+rand 1f
25 134218144
q))\
```

Let's edit the function, removing our temporary breakpoint and switching to the vectorized symbol look-up approach.

```
q)qed`build
[0]   build:{[n]
[1]   d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[2]   usym:neg[s]?`4; / Unique symbols
[3]   ps:1+s?99f; / Starting prices
[4]   1+`a; / Intentional error
[5]   p:{[usym;ps;s] ps[usym?s]+rand 1f}[usym;ps] each sym:n?usym; / Generate trade prices
[6]   flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100) / Build trade table
[7]    }
[6.1] [~4]
[5]   p:ps[usym?sym:n?usym]+rand 1f; / Generate trade prices
[6]   [$]
[0]   build:{[n]
[1]   d@:where 1<(d:.z.D-til h)mod 7; / Ignore weekends
[2]   usym:neg[s]?`4; / Unique symbols
[3]   ps:1+s?99f; / Starting prices
[5]   p:ps[usym?sym:n?usym]+rand 1f; / Generate trade prices
[6]   flip`date`time`sym`price`size!(n?d;st+n?et-st;sym;p;100*1+n?100) / Build trade table
[7]    }
[8]   \w
build defined

q)\ts build 5000000
254 302002416
```

The modified version exhibits much better performance characteristics, with this simple change giving an
improvement of nearly 15 times.

# Configuration

The variable `.ed.ED` controls the OS editor invoked by `ed`. By default, under Windows `ed` uses Notepad++; there is
no default editor for Linux.

The variable `.ed.TABS` controls with width of a tab stop in `qed`. By default, tabs are set to 8.

# Acknowledgement

The `qed` line editor is based on the design of the original APL\360 line editor that was implemented as part of
IBM's XM6 Program product, and later enhanced by I.P. Sharp Associates in its Sharp APL product.

# Author

Leslie Goldsmith
