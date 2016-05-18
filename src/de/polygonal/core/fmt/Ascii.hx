/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.fmt;

/**
	US ASCII Character Set, ANSI X3.4-1986 (ISO 646 International Reference Version)
	
	- Codes 0 through 31 and 127 are unprintable control characters.
	- Code 32 is a non-printing spacing character.
	- Codes 33 through 126 are printable graphic characters.
	- Unprintable control characters except newline are omitted.
**/
class Ascii
{
	/**
		Returns true if `x` is an ASCII character.
	**/
	public inline static function isASCII(x:Int):Bool
	{
		return x >= 0 && x <= 127;
	}
	
	/**
		Returns true if `x` is a decimal digit ([0-9]).
	**/
	public inline static function isDigit(x:Int):Bool
	{
		return x >= ZERO && x <= NINE;
	}
	
	/**
		Returns true if `x` is whitespace.
	**/
	public inline static function isWhite(x:Int):Bool
	{
		return x <= SPACE;
	}
	
	/**
		Returns true if `x` is printable.
	**/
	public inline static function isPrintable(x:Int):Bool
	{
		return x >= EXCLAM && x <= TILDE;
	}
	
	/**
		Returns true if `x` is a uppercase alphabetic character ([A-Z]).
	**/
	public inline static function isUpperCaseAlphabetic(x:Int):Bool
	{
		return x >= A && x <= Z;
	}
	
	/**
		Returns true if `x` is a lowercase alphabetic character ([a-z]).
	**/
	public inline static function isLowerCaseAlphabetic(x:Int):Bool
	{
		return x >= a && x <= z;
	}
	
	/**
		Returns true if `x` is an alphabetic character ([a-z,A-Z]).
	**/
	public inline static function isAlphabetic(x:Int):Bool
	{
		return isUpperCaseAlphabetic(x) || isLowerCaseAlphabetic(x);
	}
	
	/**
		Returns true if `x` is a alphanumeric character ([a-zA-Z0-9]).
	**/
	public inline static function isAlphaNumeric(x:Int):Bool
	{
		return isDigit(x) || isUpperCaseAlphabetic(x) || isLowerCaseAlphabetic(x);
	}
	
   /**"\b"**/public inline static var BACKSPACE      = 8;
   /**"\t"**/public inline static var TAB            = 9;
   /**"\n"**/public inline static var NEWLINE        = 10;
   /**"\f"**/public inline static var FORMFEED       = 12;
   /**"\r"**/public inline static var CARRIAGERETURN = 13;
	/**" "**/public inline static var SPACE          = 32;
	/** ! **/public inline static var EXCLAM         = 33;
	/** " **/public inline static var QUOTEDBL       = 34;
	/** # **/public inline static var NUMBERSIGN     = 35;
	/** $ **/public inline static var DOLLAR         = 36;
	/** % **/public inline static var PERCENT        = 37;
	/** & **/public inline static var AMPERSAND      = 38;
	/** ' **/public inline static var QUOTESINGLE    = 39;
	/** ( **/public inline static var PARENLEFT      = 40;
	/** ) **/public inline static var PARENRIGHT     = 41;
	/** * **/public inline static var ASTERISK       = 42;
	/** + **/public inline static var PLUS           = 43;
	/** , **/public inline static var COMMA          = 44;
	/** - **/public inline static var HYPHEN         = 45;
	/** . **/public inline static var PERIOD         = 46;
	/** / **/public inline static var SLASH          = 47;
	
	/** 0 **/public inline static var ZERO           = 48;
	/** 1 **/public inline static var ONE            = 49;
	/** 2 **/public inline static var TWO            = 50;
	/** 3 **/public inline static var THREE          = 51;
	/** 4 **/public inline static var FOUR           = 52;
	/** 5 **/public inline static var FIVE           = 53;
	/** 6 **/public inline static var SIX            = 54;
	/** 7 **/public inline static var SEVEN          = 55;
	/** 8 **/public inline static var EIGHT          = 56;
	/** 9 **/public inline static var NINE           = 57;
	
	/** : **/public inline static var COLON          = 58;
	/** ; **/public inline static var SEMICOLON      = 59;
	/** &lt; **/public inline static var LESS        = 60;
	/** = **/public inline static var EQUAL          = 61;
	/** &gt; **/public inline static var GREATER     = 62;
	/** ? **/public inline static var QUESTION       = 63;
	/** @ **/public inline static var AT             = 64;
	
	/** A **/public inline static var A              = 65;
	/** B **/public inline static var B              = 66;
	/** C **/public inline static var C              = 67;
	/** D **/public inline static var D              = 68;
	/** E **/public inline static var E              = 69;
	/** F **/public inline static var F              = 70;
	/** G **/public inline static var G              = 71;
	/** H **/public inline static var H              = 72;
	/** I **/public inline static var I              = 73;
	/** J **/public inline static var J              = 74;
	/** K **/public inline static var K              = 75;
	/** L **/public inline static var L              = 76;
	/** M **/public inline static var M              = 77;
	/** N **/public inline static var N              = 78;
	/** O **/public inline static var O              = 79;
	/** P **/public inline static var P              = 80;
	/** Q **/public inline static var Q              = 81;
	/** R **/public inline static var R              = 82;
	/** S **/public inline static var S              = 83;
	/** T **/public inline static var T              = 84;
	/** U **/public inline static var U              = 85;
	/** V **/public inline static var V              = 86;
	/** W **/public inline static var W              = 87;
	/** X **/public inline static var X              = 88;
	/** Y **/public inline static var Y              = 89;
	/** Z **/public inline static var Z              = 90;
	
	/** [ **/public inline static var BRACKETLEFT    = 91;
	/** \ **/public inline static var BACKSLASH      = 92;
	/** ] **/public inline static var BRACKETRIGHT   = 93;
	/** ^ **/public inline static var CIRCUM         = 94;
	/** _ **/public inline static var UNDERSCORE     = 95;
	/** ` **/public inline static var GRAVE          = 96;
	
	/** a **/public inline static var a              = 97;
	/** b **/public inline static var b              = 98;
	/** c **/public inline static var c              = 99;
	/** d **/public inline static var d              = 100;
	/** e **/public inline static var e              = 101;
	/** f **/public inline static var f              = 102;
	/** g **/public inline static var g              = 103;
	/** h **/public inline static var h              = 104;
	/** i **/public inline static var i              = 105;
	/** j **/public inline static var j              = 106;
	/** k **/public inline static var k              = 107;
	/** l **/public inline static var l              = 108;
	/** m **/public inline static var m              = 109;
	/** n **/public inline static var n              = 110;
	/** o **/public inline static var o              = 111;
	/** p **/public inline static var p              = 112;
	/** q **/public inline static var q              = 113;
	/** r **/public inline static var r              = 114;
	/** s **/public inline static var s              = 115;
	/** t **/public inline static var t              = 116;
	/** u **/public inline static var u              = 117;
	/** v **/public inline static var v              = 118;
	/** w **/public inline static var w              = 119;
	/** x **/public inline static var x              = 120;
	/** y **/public inline static var y              = 121;
	/** z **/public inline static var z              = 122;
	
	/** { **/public inline static var BRACELEFT      = 123;
	/** | **/public inline static var BAR            = 124;
	/** } **/public inline static var BRACERIGTH     = 125;
	/** ~ **/public inline static var TILDE          = 126;
}