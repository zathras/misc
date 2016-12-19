
/*
 * This was adapted from code from hdcookbook (http://hdcookbook.jovial.com/),
 * so I've retained the Sun copyright...
 */
/*  
 * Copyright (c) 2009, Sun Microsystems, Inc.
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Sun Microsystems nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 *  Note:  In order to comply with the binary form redistribution 
 *         requirement in the above license, the licensee may include 
 *         a URL reference to a copy of the required copyright notice, 
 *         the list of conditions and the disclaimer in a human readable 
 *         file with the binary form of the code that is subject to the
 *         above license.  For example, such file could be put on a 
 *         Blu-ray disc containing the binary form of the code or could 
 *         be put in a JAR file that is broadcast via a digital television 
 *         broadcast medium.  In any event, you must include in any end 
 *         user licenses governing any code that includes the code subject 
 *         to the above license (in source and/or binary form) a disclaimer 
 *         that is at least as protective of Sun as the disclaimers in the 
 *         above license.
 * 
 *         A copy of the required copyright notice, the list of conditions and
 *         the disclaimer will be maintained at 
 *         https://hdcookbook.dev.java.net/misc/license.html .
 *         Thus, licensees may comply with the binary form redistribution
 *         requirement with a text file that contains the following text:
 * 
 *             A copy of the license(s) governing this code is located
 *             at https://hdcookbook.dev.java.net/misc/license.html
 */


import java.io.Reader;
import java.io.Writer;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.FileReader;
import java.io.FileInputStream;
import java.io.OutputStreamWriter;
import java.io.IOException;
import java.util.*;


/**
 * This is a minimal JSON pretty printer.
 */
public class JsonPretty {
    private static int levelIndent = 2;
    private static Reader input;
    private static Writer output;

    //
    // No public constructor
    //
    private JsonPretty() {
    }

    //
    // The maximum long value's most significant digit
    //
    private static long LONG_MAX_MSD = 9000000000000000000l;

    public static void readJSON(int indent) throws IOException {
        if (!input.markSupported()) {
            throw new IOException("Reader.markSupported must be true");
        }
        for (;;) {
            int c = input.read();
            if (c == -1) {
                throw new IOException("Unexpected EOF");
            }
            char ch = (char) c;
            if (skipWhitespace(ch)) {
                continue;
            }  else if (ch == '"' || ch == '\'') {
                readString(indent, ch);
		return;
            } else if (ch == '{') {
		output.write("{\n");
                readHashMap(indent + levelIndent);
		return;
            } else if (ch == '[') {
		output.write("[\n");
                readArray(indent + levelIndent);
		return;
            }
            ch = Character.toLowerCase(ch);
            if (ch == 't') {
                readConstant("rue");
		output.write("true");
                return;
            } else if (ch == 'f') {
                readConstant("alse");
		output.write("false");
		return;
            } else if (ch == 'n') {
                readConstant("ull");
		output.write("null");
		return;
            } else {
                output.write(readNumber(input, ch).toString());
		return;
            }
        }
    }

    //
    // Skip whitespace, including comments.  Return true iff ch used.
    //
    private static boolean skipWhitespace(int ch) throws IOException {
        if (Character.isWhitespace((char) ch)) {
            return true;
        } else if (ch == '/') {
            skipSlashComment();
            return true;
        } else if (ch == '#') {
            skipToEOLN();
            return true;
        }
        return false;
    }

    private static void skipSlashComment() throws IOException {
        int c = input.read();
        if (c == '/') {
            skipToEOLN();
        } else if (c == '*') {
            boolean starSeen = false;
            for (;;) {
                c = input.read();
                if (c == -1) {
                    throw new IOException("Unexpected EOF");
                } else if (starSeen && c == '/') {
                    return;
                }
                starSeen = c == '*';
            }
        } else {
            throw new IOException("Syntax error");
        }
    }

    private static void skipToEOLN() throws IOException {
        for (;;) {
            int c = input.read();
            if (c == -1) {
                throw new IOException("Unexpected EOF");
            }
            if (c == '\n' || c == '\r') {
                return;
            }
        }
    }

    private static void readString(int indent, char delimiter) 
            throws IOException 
    {
	output.write(delimiter);
        for (;;) {
            int c = input.read();
            if (c == -1) {
                throw new IOException("Unexpected EOF");
            } else if (c == '\\') {
                c = input.read();
                switch (c) {
                    case -1:
                        throw new IOException("Unexpected EOF");
                    case 'b':
                        c = '\b';
                        break;
                    case 't':
                        c = '\t';
                        break;
                    case 'n':
                        c = '\n';
                    case 'f':
                        c = '\f';
                        break;
                    case 'r':
                        c = '\r';
                        break;
                    case 'u':
                        c = parseHex(input, 4);
                        break;
                    case 'x':
                        c = parseHex(input, 2);
                        break;
                    default:
                        break;
                }
	    } else if (c == delimiter) {
		output.write(c);
		return;
	    }
	    if (c == '"') {
		output.write('\\');
		output.write('"');
	    } else if (c == '\\') {
		output.write("\\\\");
	    } else if (c == '\b') {
		output.write("\\b");
	    } else if (c == '\f') {
		output.write("\\f");
	    } else if (c == '\n') {
		output.write("\\n");
	    } else if (c == '\r') {
		output.write("\\r");
	    } else if (c == '\t') {
		output.write("\\t");
	    } else if (c < 32 || c > 126) {
		output.write("\\u");
		String hex = Integer.toHexString(c);
		for (int j = hex.length(); j < 4; j++) {
		    output.write('0');
		}
		output.write(hex);
	    } else {
		output.write(c);
	    }
        }
    }

    private static char parseHex(Reader rdr, int digits) throws IOException {
        int val = 0;
        for (int i = 0; i < digits; i++) {
            val *= 16;
            int ch = rdr.read();
            if (ch >= '0' && ch <= '9') {
                val += (ch - '0');
            } else if (ch >= 'A' && ch <= 'F') {
                val += (ch - 'A' + 10);
            } else if (ch >= 'a' && ch <= 'f') {
                val += (ch - 'a' + 10);
            } else {
                throwUnexpected(ch);
            }
        }
        return (char) val;
    }

    private static void printIndent(int indent) throws IOException {
	for (int i = 0; i < indent; i++) {
	    output.write(' ');
	}
    }

    private static void readHashMap(int indent) throws IOException {
        for (;;) {
            input.mark(1);
            int ch = input.read();
            if (skipWhitespace(ch)) {
                continue;
            } else if (ch == '}') {
		output.write('\n');
		output.flush();
		printIndent(indent - levelIndent);
		output.write('}');
                return;
            } else if (ch == ',') {
		output.write(",\n");
		output.flush();
                continue;
            } else {
		printIndent(indent);
                input.reset();
		readJSON(indent + levelIndent);
                for (;;) {
                    ch = input.read();
                    if (ch == ':') {
			output.write('\n');
			output.flush();
			printIndent(indent);
			output.write(" : ");
			break;
                    } else if (skipWhitespace(ch)) {
                        continue;
                    } else {
                        throwUnexpected(ch);
                    }
                }
                readJSON(indent + levelIndent);
            }
        }
    }

    private static void readArray(int indent) throws IOException {
        for (;;) {
            input.mark(1);
            int ch = input.read();
            if (ch == -1) {
                throwUnexpected(ch);
            } else if (ch == ']') {
		output.write("\n");
		output.flush();
		printIndent(indent - levelIndent);
		output.write(']');
		return;
            } else if (skipWhitespace(ch)) {
                continue;
            } else {
                input.reset();
                break;
            }
        }
        for (;;) {
	    printIndent(indent);
            readJSON(indent);
            for (;;) {
                int ch = input.read();
                if (ch == ',') {
		    output.write(",\n");
		    output.flush();
                    break;
                } else if (ch == ']') {
		    output.write('\n');
		    output.flush();
		    printIndent(indent - levelIndent);
		    output.write(']');
		    return;
                } else if (skipWhitespace(ch)) {
                    continue;
                } else { 
                    throwUnexpected(ch);
                }
            }
        }
    }

    private static void readConstant(String wanted) 
            throws IOException 
    {
        for (int i = 0; i < wanted.length(); i++) {
            int ch = input.read();
            if (ch != (int) wanted.charAt(i)) {
                throwUnexpected(ch);
            }
        }
    }

    private static Number readNumber(Reader rdr, char initial) throws IOException {
        boolean negative = false;
        boolean digitSeen = false;
        int value = 0;          // Kept as a negative value
            // Value is kept as a negative number throughtout.  That's because
            // abs(Integer.MIN_VALUE) > abs(Integer.MIN_VALUE).
        int ch = initial;
        if (initial == '-') {
            negative = true;
            ch = rdr.read();
        }
        for (;;) {
            if (ch >= '0' && ch <= '9') {
                digitSeen = true;
                if (value <= (Integer.MIN_VALUE / 10)) {
                    // It might or mignt not overflow if it's ==
                    return readLong(rdr, negative, value, ch);
                }
                value *= 10;
                value -= (ch - '0');    // value is negative
                rdr.mark(1);
                ch = rdr.read();
            } else if (ch == '.') {
                return readDouble(rdr, negative, value, true);
            } else if (ch == 'e' || ch == 'E') {
                double v = negative ? ((double) value) : (-((double) value));
                return readScientific(rdr, v);
            } else if (digitSeen) {
                rdr.reset();
                if (negative) {
                    return new Integer(value);
                } else {
                    return new Integer(-value);
                }
            } else {
                throwUnexpected(ch);
            }
        }
    }

    //
    // Read a number that might be a long.  It might be an integer that's
    // close to Integer.MAX_VALUE or Integer.MIN_VALUE too; in this case an
    // Integer is returned.
    //
    // value is negative
    //
    private static Number readLong(Reader rdr, boolean negative, 
                                   long value, int ch) 
        throws IOException 
    {
        long limit = negative ? Long.MIN_VALUE : -Long.MAX_VALUE;
        limit += LONG_MAX_MSD;  // Knock the most significant digit off
        value *= 10;
        value -= (ch - '0');    // Remember, value is negative
        for (;;) {
            rdr.mark(1);
            ch = rdr.read();
            if (ch >= '0' && ch <= '9') {
                if (value < (Long.MIN_VALUE / 10)) {
                    rdr.reset();
                    return readDouble(rdr, negative, value, false);
                }
                value *= 10;
                int digit = ch - '0';
                if ((value + LONG_MAX_MSD) - digit < limit) {
                    double v = value;
                    v -= digit;
                    return readDouble(rdr, negative, v, false);
                }
                value -= digit;
            } else if (ch == '.') {
                return readDouble(rdr, negative, value, true);
            } else if (ch == 'e' || ch == 'E') {
                double v = negative ? ((double) value) : (-((double) value));
                readScientific(rdr, v);
            } else {
                rdr.reset();
                if (negative) {
                    if (value >= Integer.MIN_VALUE) {
                        return new Integer((int) value);
                    } else {
                        return new Long(value);
                    }
                } else {
                    if (value >= -Integer.MAX_VALUE) {
                        return new Integer((int) -value);
                    } else {
                        return new Long(-value);
                    }
                }
            }
        }
    }

    //
    // Read a double
    //
    // value is negative
    //
    private static Number readDouble(Reader rdr, boolean negative, double value, 
                                     boolean decimalSeen)
        throws IOException
    {
        while (!decimalSeen) {
            rdr.mark(1);
            int ch = rdr.read();
            if (ch >= '0' && ch <= '9') {
                value *= 10;
                value -= ch - '0';      // value is negative
            } else if (ch == '.') {
                decimalSeen = true;
            } else if (ch == 'e' || ch == 'E') {
                if (!negative) {
                    value = -value;
                }
                return readScientific(rdr, value);
            } else {
                rdr.reset();
                if (negative) {
                    return new Double(value);
                } else {
                    return new Double(-value);
                }
            }
        }
        double multiplier = 1.0;
        for (;;) {
            rdr.mark(1);
            int ch = rdr.read();
            if (ch >= '0' && ch <= '9') {
                multiplier /= 10;
                value -= multiplier * (ch - '0');       // value is negative
            } else if (ch == 'e' || ch == 'E') {
                if (!negative) {
                    value = -value;
                }
                return readScientific(rdr, value);
            } else {
                rdr.reset();
                if (negative) {
                    return new Double(value);
                } else {
                    return new Double(-value);
                }
            }
        }
    }

    //
    // Read a double after an 'e' or 'E' is seen
    //
    // value is the correct sign for the number being read
    //
    private static Number readScientific(Reader rdr, double value) 
            throws IOException 
    {
        boolean expNegative = false;
        int ch = rdr.read();
        if (ch == '+') {
            ch = rdr.read();
        } else if (ch == '-') {
            expNegative = true;
            ch = rdr.read();
        }
        if (ch < '0' || ch > '9') {
            throwUnexpected(ch);
        }
        int exp = ch - '0';     
            // We don't worry about exponent overflow, since the biggest
            // exponent for a positive number is only 309.
        for (;;) {
            rdr.mark(1);
            ch = rdr.read();
            if (ch >= '0' && ch <= '9') {
                exp *= 10;
                exp += ch - '0';
            } else {
                rdr.reset();
                if (expNegative) {
                    return new Double(value / Math.pow(10.0, exp));
                } else {
                    return new Double(value * Math.pow(10.0, exp));
                }
            }
        }
    }

    private static void throwUnexpected(int ch) throws IOException {
        String str;
        if (ch == -1) {
            str = "EOF";
        } else {
            str = "" + ((char) ch);
        }
        throw new IOException("Syntax error in JSON object:  " + str 
                              + " unexpected.");
    }

    public static void main(String[] args) throws Exception {
	InputStream str = null;
	if (args.length == 0) {
	    str = System.in;
	} else if (args.length == 1) {
	    str = new FileInputStream(args[0]);
	} else {
	    System.err.println("Usage:  jsonpretty [file.json]");
	    System.exit(1);
	}
	input = new BufferedReader(new InputStreamReader(str, "UTF-8"));
	output = new OutputStreamWriter(System.out, "UTF-8");
	try {
	    readJSON(0);
	} finally {
	    output.write('\n');
	    output.flush();
	}
	System.exit(0);
    }
}
