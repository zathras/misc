
package scurses;

/**
 *  Access to the underlying -lcurses C library via JNI
 **/
public class RawCurses {

    private static native boolean init();	// clients use initialize()
    public static native void endwin();

    public static native int refresh();
    public static native int getmaxx();
    public static native int getmaxy();
    public static native void clearok(boolean ok);
    public static native int clear();
    public static native int addch(char ch);
    public static native int getch();
    public static native void move(int y, int x);
    public static native void reverse(boolean on);
    public static native void beep();

    public static native int getKeyDown();
    private static native int getKeyUp();
    private static native int getKeyLeft();
    private static native int getKeyRight();
    private static native int getKeyHome();
    private static native int getKeyBackspace();
    private static native int getKeyDC();
    private static native int getKeyIC();

    public static int KEY_DOWN;
    public static int KEY_UP;
    public static int KEY_LEFT;
    public static int KEY_RIGHT;
    public static int KEY_HOME;
    public static int KEY_BACKSPACE;
    public static int KEY_DELETE_CHAR;
    public static int KEY_INSERT_CHAR;


    public static boolean initialize() {
	System.loadLibrary("scurses");
	KEY_DOWN = getKeyDown();
	KEY_UP = getKeyUp();
	KEY_LEFT = getKeyLeft();
	KEY_RIGHT = getKeyRight();
	KEY_HOME = getKeyHome();
	KEY_BACKSPACE = getKeyBackspace();
	KEY_DELETE_CHAR = getKeyDC();
	KEY_INSERT_CHAR = getKeyIC();
	return init();
    }

    public static void print(String s) {
	for (int i = 0; i < s.length(); i++) {
	    addch(s.charAt(i));
	}
    }

}

