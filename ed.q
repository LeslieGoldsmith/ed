/
	Q function editor
	Copyright (c) 2018 Leslie Goldsmith

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at:

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing,
	software distributed under the License is distributed on an
	"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
	either express or implied.  See the License for the specific 
	language governing permissions and limitations under the 
	License.

	----------------

	Contains two different workspace-centric function editors,
	<ed> and <qed>.  <ed> shells out to the OS to invoke an
	external editor of choice, and <qed> edits entirely within Q
	using a line-mode editor.

	Usage information appears at the bottom of this file.
	
	Author:		Leslie Goldsmith
\


\d .ed

ED:$["w"=first string .z.o;"\"C:\\Program Files\\Notepad++\\notepad++.exe\" -multiInst -nosession -notabbar";"Editor_not_specified"] / External editor invocation
TABS:8
POW:1 10 100 1000 10000

enl:enlist


//
// @desc Edits a new or existing function using an external editor.
//
// @param x {symbol|string}	Specifies the name of the function to edit.  If the
//							function does not exist, a new one is created.  The
//							name may be preceded by `:` to force definition (or
//							redefinition) in the specified namespace.
//
ed:{
	if[0~v:ncsv x;:()];nm:first v;c:v 1; / Extract name (with possible namespace) and context
	`:_ed.tmp 0:enl fn0:ssr[;"\n ";"\n\t"]fn:nm,":",last v; / Write temporary file in canonical format
	if[v 2;fn0:0];b:1b; / Kill inceptive defn if new, and set loop terminator
	
	while[b;
		system ED," _ed.tmp"; / Invoke editor
		n:name fn:read0`:_ed.tmp; / Grab new defn and name
		nm:def[n;ctx[c;nm;n];(1+fn?":")_fn:"\n"sv fn]; / Attempt to define function
		if[b:nm~"";-1 "Press any key to re-edit, or \"\\q\" to quit and discard changes";b:not"\\q"~read0 0]];
	
	if[count nm;-1 nm,(" defined";" unchanged")fn0~fn];
	}


//
// @desc Edits a new or existing function using an internal line-mode editor.
// Editor commands are described at the end of this file.
//
// @param x {symbol|string}	Specifies the name of the function to edit.  If the
//							function does not exist, a new one is created.  The
//							name may be preceded by `:` to force definition (or
//							redefinition) in the specified namespace.
//
qed:{
	if[0~v:ncsv x;:()];nm:first v;c:v 1; / Extract name (with possible namespace) and context
	i:0,1+where"\n"=fn0:nm,":",last v; / Find line breaks
	Lns::10000*til count Fn::i _fn0,"\n"; / Scaled line numbers and corresponding lines
	Cur::0|-2+count Lns; / Current line (= insert point), before closing }
	Mode::0b; / Set insert (vs. edit) mode
	Ln::-1; / User-specified line number, if any
	if[v 2;fn0:0]; / Kill inceptive defn if new
	d:system"c";system"c 1000 2000"; / Set display size
	p:system"P";system"P 10"; / Set formatting precision
	
	dl(); / Display all lines

	while[not$[[2 pr:fmtn seln[];"\\w"~s:read0 0];
			[s:"";count nm:def[n;ctx[c;nm;n:name Fn];(1+fn?":")_fn:-1_(,/)Fn]];[if[i:"\\q"~s;nm:""];i]]; / Attempt to define function
		r:$[0=count s:ltrim s;Cur; / No change if input empty
			[Ln::-1;"["=first s];lcmd s; / Look for edit command
			upd pr,s]; / Otherwise, update current line
		$[r=-1;-2 "Command error";Mode&::r=Cur::r&-1+count Lns]];

	if[count nm;-1 nm,(" defined";" unchanged")fn0~fn];

	system"c ",.Q.s1 d;system"P ",string p; / Restore settings
	}


//
// @desc Returns the name, context namespace, status, and value of an object.
//
// @param x {symbol|string}	Specifies the name of the function to edit.  The
//							name may be preceded by `:` to force definition (or
//							redefinition) in the specified namespace.
//
// @return {list[4]|0}		A 4-element array containing the name, context,
//							status, and value of the function, or `0` if the
//							name is illegal.  Status is `1b` if the object
//							is new or if an explicit namespace override is
//							specified, or `0b` otherwise.
//
ncsv:{
	nm:$[10h=type x;;-11h=type x;string;0#]x; / Convert name to string (empty if illegal)
	c:`$$[":."~2#nm;$["."in i:2_nm;(i?".")#i;""];1_string system"d"]; / Get context namespace
	v:$[(0=count nm)|" "in nm:sqz nm;0;b:0h=type key x:`$nm:(i:":"=first nm)_nm;(0;0;0;c;"{\n }");100h=type v:value x;value v;0]; / Validate name; hallucinate value if new function
	$[v~0;0*-2 "Unable to edit";(nm;$[i;c;first v 3];b|i;last v)] / Name, context, status, value
	}


//
// Extracts the function name (with possible namespace) from its definition.
//
// @param x {string[]}		The function definition, split by lines.  The first
//							line has the form:  `name:{...` .
//
// @return {string}			The function name if plausible, or an empty string
//							otherwise.  Note that the returned name may be still
//							be illegal; the caller is expected to accommodate
//							this.
//
name:{{$[(first[x]in .Q.n)<":"in x;(x?":")#x;""]}ltrim first x}


//
// @desc Computes the context for a function based on its initial and final
// properties.
//
// @param c {symbol}		Specifies the context of the original definition.
// @param nm0 {string}		Specifies the initial function name (with possible
//							namespace).
// @param nm {string}		Specifies the final function name (with possible
//							namespace).
//
// @return {symbol}			The context in which the function should be defined.
//
ctx:{[c;nm0;nm]
	i:`${$["."=first y;(y?".")#y:1_y;x]}[1_string system"d"]@/:(nm0;nm); / Extract namespace from names, defaulting to active namespace
	$[(=/)i;c;last i] / Use context if no change; else use namespace of final name
	}


//
// @desc Displays lines to the console.
//
// @param x {long[2|0]}	The starting line number and the number of lines to
//						display, or an empty vector to display all lines.
//
// @return {long}		The line index of the last line displayed.
//
dl:{
	i:first[x]+til last x:2#x,0,count Lns; / Indices of selected lines (all if none specified)
	1"",/((1+5|count each j)$j:"[",/:string[0.0001*Lns i],\:"]"),'Fn i; / Prepend line numbers and display
	last count[Lns],i
	}


//
// @desc Formats a line number for output.
//
// @param x {long}		The scaled line number.
//
// @return {string}		The decorated string representation of the line number.
//
fmtn:{(1+5|count s)$s:"[",string[0.0001*x],"]"}


//
// @desc Selects the line number to display for the current line.
//
// @return {long}	The line number to display.
//
seln:{[] $[Mode;Lns Cur;Ln>=0;Ln;$[null i:nextn[];[-2 "No room for insertion";Lns Cur];i]]}


//
// @desc Computes the line number for insertion mode.
//
// @return {long}	The next line number, or `0N` if there is no room for
//					insertion at the current line index.
//
nextn:{[] {x+POW(last where i=(_)i:x%POW)&POW bin -1+y-x}. 2#Cur _Lns,0W}
	

//
// @desc Processes a line command (beginning with `[`).  Valid command formats are
// described at the end of this file.
//
// @param s {string}	The input line command, starting with the leading bracket.
//
// @return {long}		The new line index if the operation is successful, or `-1`
//						if an error occurred.
//
lcmd:{[s]
	if[not"]"in s;:-1]; / Must be matched
	(del;edt;upd)[("~$"in(s?"]")#s)?1b]s / Invoke appropriate routine
	}


//
// @desc Deletes one or more lines.
//
// @param s {string}	The input line command, starting with the leading bracket.
//						Valid formats are `[~n1 n2 n3]` and `[n~m]`.
//
// @return {long}		The new line index if the operation is successful, or `-1`
//						if an error occurred.
//
del:{[s]
	if[1b in" "<>(1+count i:(s?"]")#s)_s:ltrim 1_s;:-1]; / Must be no line residual
	
	i:$["~"=first i; / Distinguish case
		[if[-1~n:getnv 1_i;:-1];Lns in n]; / Monadic (vector) form
		[if[-1=n:getn(j:i?"~")#i;:-1];if[n>m:getn(j+1)_i;:-1];Lns within n:n,m]]; / Dyadic form
	
	if[1b in i;Lns@:i:where not i;Fn@:i]; / Remove affected lines
	Mode::count[Lns]>p:Lns binr last n; / Compute new line index and adjust line mode
	p
	}


//
// @desc Displays one or more lines, or edits a line.
//
// @param s {string}	The input line command, starting with the leading bracket.
//						Valid formats are `[$]`, `[$n]`, `[n$]`, and `[n$m]`.
//
// @return {long}		The new line index if the operation is successful, or `-1`
//						if an error occurred.
//
edt:{[s]
	if[1b in" "<>(1+count i:(s?"]")#s)_s:ltrim 1_s;:-1]; / Must be no line residual
	
	if["$"=first i;$[0=count ltrim 1_i;[Mode::0b;:dl()]; / Display entire function
		[if[-1=n:getn 1_i;:-1];Mode::0b;:dl p,count[Lns]-p:Lns binr n]]]; / Display from specified line to end
		
	if[-1=n:getn(j:i?"$")#i;:-1]; / Extract line number
	p:Lns binr n; / Where this line is (or goes)
	if[0=count ltrim(j+1)_i;:$[Mode::n=Lns p;dl p,1;[Ln::n;p]]]; / Display specified line
	
	if[0>m:"J"$(j+1)_i;:-1]; / Reject illegal or negative position values
	$[Mode::n=Lns p;upd edln[fmtn[n],-1_Fn p;m];[Ln::n;p]] / Edit specified line (note line number may be modified as well)
	}


//
// @desc Sets or updates a line.
//
// @param s {string}	The input line command, starting with the leading bracket.
//						Format is `[n]` optionally followed by line text.
//
// @return {long}		The new line index if the operation is successful, or `-1`
//						if an error occurred.
//
upd:{[s]
	if[-1=n:getn(j:s?"]")#s:ltrim 1_s;:-1]; / Extract line number
	s:ltrim(j+1)_s; / Text to insert
	Mode::n=Lns p:Lns binr n; / Where this line is (or goes)
	
	if[i:count s;$[Mode;[Fn[p]:s,"\n";p+:1]; / Update existing line
		[Lns::(p#Lns),n,p _Lns;Fn::(p#Fn),enl[s,"\n"],p _Fn]]]; / Insert new line
		
	if[not Mode+i;Ln::n]; / Retain user line number if insert mode with no change
	p
	}

	
//
// @desc Gets a line number from an input string.
//
// @param s {string}	The character line number, which may be nonintegral.
//
// @return {long}		The line number (scaled to integer) if the operation is
//						successful, or `-1` if an error occurred.
//
getn:{[s]
	if[0n=n:10000*"F"$s;:-1]; / Interpret and scale number
	if[(n<0)|0.0001<n-(_)0.1+n;:-1]; / Disallow negatives and excessive fractions
	"j"$n
	}

	
//
// @desc Gets one or more line numbers from an input string.
//
// @param s {string}	The character line numbers, which may be nonintegral.
//
// @return {long}		The line numbers (scaled to integer) if the operation is
//						successful, or `-1` if an error occurred.
//
getnv:{[s]
	if[0n in n:10000*"F"$" "vs sqz s;:-1]; / Interpret and scale numbers
	if[1b in(n<=0)|0.0001<n-(_)0.1+n;:-1]; / Disallow negatives and line 0, and excessive fractions
	"j"$n
	}


//
// @desc Emulates APL-style superedit line editing, subject to limitations of q console.
//
// A displayed line can be modified using the following control characters:
//
//		/		Characters above slashes are deleted
//		.		First dot to the right of possible slashes inserts subsequent text
//		,		As per dot, but process repeats until dot is used or input is empty
//
// @param x {string}	Specifies the line to edit.
// @param n {long}		Specifies the horizontal position of the cursor after initial
//						line display (origin 1).  If n is `0`, the cursor is positioned
//						at the end of the displayed line and typed input can be directly
//						appended.
//
// @return {string}		The modified line.
//
edln:{[s;n]
	while[1b;
		if[n;-2@[s;where s="\t";:;" "];2 pr:(count[s]&n-1)#" ";n:count a:read0 0]; / If nonzero position, display line, space over, and acquire input
		if[not n;2@[s;where s="\t";:;" "];:s,read0 0]; / If final display, return input appended to line -- too bad user can't backspace over prompt
		j:count[s]&i:(&/)(a:exptb[pr,a;TABS])?".,"; / Pre-insertion control chars
		s:((j#s)where not k:"/"=j#a),((i+1)_a),j _s; / Delete selected chars and insert new
		if["."=a i;:s]; / Quit if dot
		n:$[","<>a i;0;count[a]-(+/)k]]; / Position to right of insertion, or at end of line
	}


//
// @desc Expands tabs in a character string.
//
// @param s {string}	Specifies the string to process.
// @param t {int}		Specifies the tab spacing.
//
// @return {string}		The input string with tabs replaced by spaces.
//
exptb:{[s;t]
	if[not 1b in i:s="\t";:s]; / Quick exit if no tabs
	j:-1+-1-':k:where i; / Lengths of segments between tabs
	p:0|t-j mod t; / Number of blanks to replace tabs
	@[s;k;:;" "]where 1+@["j"$i;k;:;p-1] / Replace tabs with blanks and replicate to fill
	}


//
// @desc Defines a function within its associated namespace.
//
// @param nm {string}	Specifies the fully-qualified name of the function to define.
// @param c {symbol}	Specifies the context in which to define the function.
// @param f {string}	Specifies the definition of the function.
//
// @return {string}		The name of the object defined if the operation is successful,
//						or an empty string if an error occurred.
//
def:{[nm;c;f]
	d:system "d";system "d .",string c; / Set namespace
	if[b:(nm~"")|" "in nm:sqz nm;f:"name"]; / Prepare to reject illegal names
	r:@[$[b;{'x};string(`$nm)set value@];f;{-2 "Unable to define: ",x," error";""}]; / Define object (reification performed by <value> must be under proper ns)
	system "d ",string d; / Restore previous namespace
	r
	}


//
// @desc Removes leading, trailing, and multiple internal blanks from a string.
//
// @param x {string}	Specifies the string to be trimmed.
//
// @return {string}		A character string with extraneous blanks removed.
//
sqz:{-1_x where i|-1_0b,i:" "<>x," "}


\d .

ed:.ed.ed
qed:.ed.qed

\

<ed> and <qed> edit new or existing functions in the Q workspace.  The function
name can be specified either as a symbol or a string, and may have an optional
namespace prefix.

By default, an existing function is saved back to its namespace with the same
prevailing context in which it was previously defined.  A new function is saved
to the specified namespace (or the active one if the name is unqualified) using
the context in effect when the editor was invoked.  This behavio[u]r can be
overridden by prefixing the function name with colon (:) in the editor argument.
This causes the namespace specified in the argument to be used to define both
the function name and the context.

If the name of the function is changed during the editing session, the new
function is saved (possibly replacing an earlier definition of the same name)
and the original version is untouched.  If the namespace is changed, the new
namespace is also taken to be the new context.

<ed> usage:

Define the variable <.ed.ED> to refer to the external editor of choice.

To keep changes made in the external editor, save the function in the editor and
exit back to Q.  If <ed> cannot define the function in Q, enter any key when
prompted to return to the editor (with the changes intact), or "\q" to discard
the changes.

<qed> usage:

<qed> starts by displaying all lines of the function and prompting in insert
mode at a line before the closing "}".  If the function is defined on a single
line, <qed> prompts after that line.

Valid <qed> commands are as follows:

	[n]				Move to specified line; prepare to insert line if new
	[n] text		Define (or redefine) specified line

	[~n1 n2 n3]		Delete specified line or lines
	[n~m]			Delete from line <n> to <m> inclusive

	[$]				Display all lines
	[$n]			Display from specified line to end
	[n$]			Display specified line

	[n$m]			Edit line <n>, setting cursor to position <m> (see below)

	\w				Save function and exit; stay in editor on failure
	\q				Quit (discard changes)

Lines in a <qed> session are initially numbered consecutively starting at [0].
Line numbers can be fractional, and <qed> attempts to make it difficult to
overwrite an existing line when in insert mode by choosing line numbers that
do not already exist.

When editing a line, the following commands are supported:

	,xxx			Insert text (including any trailing spaces) before character
					above ","; redisplay line and remain in edit mode
	.xxx			Insert text (including any trailing spaces) before character
					above "."; move to next line
	/ //			Delete characters above slashes; can be combined with
					trailing ",xxx" or ".xxx"

In edit mode, invalid characters are ignored.  Because backspacing over a prompt
is not permitted in Q, the cursor position <m> specified by [n$m] should be at
or before the position of interest; space or tab over to get to the desired
character position.  As a special case, if <m> is 0 the cursor is positioned at
the end of the line and the edit phase is bypassed.

Any part of a line can be edited, including the line number itself provided that
the cursor position is suitably to the left.  If the line number is changed, the
old line remains and the new line either replaces an existing line or is
inserted into the appropriate position in the function.  This provides a simple
way to duplicate a line.

The function name can also be changed.  If it is, the new function replaces any
existing function of the same name and the original version is left unchanged.


Globals (ed):

.ed.ED   - External editor command line prefix (name to edit is appended); assign to change

Globals (qed):

.ed.Fn   - Function lines
.ed.Lns  - Line numbers, scaled by 10000
.ed.Cur  - Index in <Lns> of current line
.ed.Ln   - User-specified explicit line number, or -1
.ed.Mode - Mode flag (0b = input, 1b = edit)