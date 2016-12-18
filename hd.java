

import java.io.InputStream;
import java.io.PrintStream;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.BufferedInputStream;

public class hd {
    
    private static String hexDigits = "0123456789abcdef";

    public static void dump(InputStream in, PrintStream out) 
		throws IOException
    {
	int ch = 0;
	int count = 0;
	String line = "";
	for(;;) {
	    if (ch != -1) {
		ch = in.read();
	    }
	    int m = count % 16;
	    if (m == 0) {
		if (ch == -1) {
		    break;
		}
	        System.out.print(toHex(count, 8) + ":  ");
	    }
	    if (m == 8) {
		System.out.print(" ");
	    }
	    if (ch == -1) {
	        System.out.print("  ");
	    } else {
		System.out.print(toHex(ch, 2));
		if (ch >= 32 && ch < 127) {
		    line += ((char) ch);
		} else {
		    line += ".";
		}
	    }
	    if (m == 15)  {
	        System.out.println("   " + line);
		line = "";
	    } else {
		System.out.print(" ");
	    }
	    count++;
	}
    }

    private static String toHex(int b, int digits) {
	if (digits <= 0) {
	    throw new IllegalArgumentException();
	}
	String result = "";
	while (digits > 0 || b > 0) {
	    result = hexDigits.charAt(b % 16) + result;
	    b = b / 16;
	    digits--;
	}
	return result;
    }

    public static void main(String[] args) {
	try {
	    if (args.length == 0) {
		System.out.println("stdin:");
		System.out.println("======");
		System.out.println();
		System.out.println();
		dump(System.in, System.out);
	    } else {
		for (int i = 0; i < args.length; i++) {
		    if (i > 0) {
			System.out.println("--------------------------------------------------------------------------");
			System.out.println();
			System.out.println();
		    }
		    System.out.println(args[i]);
		    for (int j = 0; j < args[i].length(); j++) {
		        System.out.print('=');
		    }
		    System.out.println();
		    System.out.println();
		    System.out.println();
		    InputStream is = new BufferedInputStream(
		    			new FileInputStream(args[i]));
		    dump(is, System.out);
		    is.close();
		}
	    }
	} catch (IOException ex) {
	    ex.printStackTrace();
	}
    }

}
