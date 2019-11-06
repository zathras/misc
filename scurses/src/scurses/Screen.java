
package scurses;

/**
 * Screen representation, based on curses.  A screen consists of a list
 * of fields, where fields can be fixed, variable put fields (display), 
 * or variable get fields.
 **/

public class Screen {

    /**
     * Fixed put fields.  The value of these fields is intended to be
     * compiled in; they're the fixed part of the screen.
     **/
    private final Field[] fixedFields;

    /**
     * Variable put fields.  The value of these fields is intended to be
     * changeable by the client.
     **/
    public final Field[] putFields;

    /**
     * Get fields.  These are fields that can accept user input.
     * Note that if there are no get fields, then the screen will wait
     * for a single keystroke.
     **/
    public final Field[] getFields;

    public Screen(Field[] fixedFields, Field[] putFields, Field[] getFields) {
	this.fixedFields = fixedFields;
	this.putFields = putFields;
	this.getFields = getFields;
    }

    /**
     * Show the screen, and prompt for input.  If there are no get fields,
     * it is an error.
     *
     * @return  The number of modified fields, or -1 on undo
     * @see showScreenWaitKey(int, int, String)
     **/
    public int showScreen() {
	assert getFields.length > 0;
	RawCurses.clear();
	showAllFields();
	return editFields();
    }

    /**
     * Show the screen, and wait for a single keystroke.  It's OK if
     * there are no get fields, but they won't be editable.
     *
     * @return The key that was pressed
     * @see showScreen()
     **/
    public int showScreenWaitKey(int y, int x, String prompt) {
	RawCurses.clear();
	showAllFields();
	RawCurses.move(y, x);
	RawCurses.print(prompt);
	return RawCurses.getch();
    }

    private void showAllFields() {
	for (int i = 0; i < fixedFields.length; i++) {
	    Field f = fixedFields[i];
	    RawCurses.move(f.y, f.x);
	    RawCurses.print(f.value);
	}
	for (int i = 0; i < putFields.length; i++) {
	    Field f = putFields[i];
	    RawCurses.move(f.y, f.x);
	    RawCurses.print(f.value);
	}
	for (int i = 0; i < getFields.length; i++) {
	    showGet(getFields[i]);
	}
    }

    //
    // Show a get field
    //
    private void showGet(Field f) {
	RawCurses.move(f.y, f.x);
	RawCurses.reverse(true);
	RawCurses.print(f.value);
	for (int j = f.value.length(); j < f.minLength; j++) {
	    RawCurses.addch(' ');
	}
	RawCurses.reverse(false);
    }
    
    private void moveTo(int y, int x) {
	int cols = RawCurses.getmaxx();
	while (x >= cols) {
	    y++;
	    x -= cols;
	}
	RawCurses.move(y, x);
    }

    //
    //  Edit the fields, and return the number of modified fields.  The
    //  user pressing ^U (undo) exits the screen with no changes and returns -1.
    //
    private int editFields() {
	final String[] undoBuffer = new String[getFields.length];
	for (int i = 0; i < getFields.length; i++) {
	    undoBuffer[i] = getFields[i].value;
	}
	int currField = 0;
	int fieldPos = 0;
	while (currField < getFields.length) {
	    Field f = getFields[currField];
	    showGet(f);
	    moveTo(f.y, f.x + fieldPos);
	    RawCurses.refresh();
	    int ch = RawCurses.getch();
	    if (ch == ('U' - 'A' + 1))  {	// ^U
		for (int i = 0; i < getFields.length; i++) {
		    Field uf = getFields[i];
		    uf.value = undoBuffer[i];
		    showGet(uf);
		}
		RawCurses.refresh();
		return -1;
	    } else if (ch == ('W' - 'A' + 1))  {	// ^W
		break;
	    } else if (ch == ('R' - 'A' + 1))  {	// ^R, redraw
		RawCurses.clear();
		showAllFields();
		RawCurses.clearok(true);
	    } else if (ch == ('J' - 'A' + 1) || ch == RawCurses.KEY_DOWN
		       || ch == ('M' - 'A' + 1))  	// ^J, ^M, down
	    {
		fieldPos = 0;
		currField++;
	    } else if (ch == ('K' - 'A' + 1) || ch == RawCurses.KEY_UP) {
		fieldPos = 0;
		currField--;
		if (currField < 0) {
		    currField = 0;
		}
	    } else if (ch == RawCurses.KEY_RIGHT || ch == ('L' - 'A' + 1)) {
		fieldPos++;
		int maxLen = Math.max(f.minLength, f.value.length());
		if (fieldPos > maxLen) {
		    fieldPos = maxLen;
		}
	    } else if (ch == RawCurses.KEY_LEFT
		       || ch == ('H' - 'A' + 1)) {
		if (fieldPos > 0) {
		    fieldPos--;
		}
	    } else if (    ch == RawCurses.KEY_DELETE_CHAR
                       || ch == RawCurses.KEY_BACKSPACE
                       || ch == 127)    // Mac:  Backspace generates 127!
	    {
		if (ch == RawCurses.KEY_DELETE_CHAR) {
		    fieldPos++;
		}
		if (fieldPos > 0) {
		    // Destructive backspace
		    int l = f.value.length();
		    boolean redrawAll = f.value.length() > f.minLength;
		    if (l == fieldPos) {
			f.value = f.value.substring(0, fieldPos - 1);
		    } else if (l > fieldPos) {
			f.value = f.value.substring(0, fieldPos - 1)
			          + f.value.substring(fieldPos, l);
		    }
		    fieldPos--;
		    if (redrawAll) {
			RawCurses.clear();
			showAllFields();
		    }
		}
	    } else if (ch == RawCurses.KEY_INSERT_CHAR) {
		int l = f.value.length();
		if (fieldPos < l) {
		    f.value = f.value.substring(0, fieldPos) + ' '
		              + f.value.substring(fieldPos, l);
		}
	    } else if (ch == ('X' - 'A' + 1)) {	// ^X, clear to EOL
		int l = f.value.length();
		boolean redrawAll = f.value.length() > f.minLength;
		if (l > fieldPos) {
		     f.value = f.value.substring(0, fieldPos);
		}
		if (redrawAll) {
		     RawCurses.clear();
		     showAllFields();
		}

	    } else if (ch >= ' ' && ch < 127) {
		while (f.value.length() < fieldPos) {
		    f.value = f.value + " ";
		}
		String endPart = null;
		if (f.value.length() > fieldPos) {
		    endPart = f.value.substring(fieldPos, f.value.length());
		    f.value = f.value.substring(0, fieldPos);
		}
		if (endPart != null) {
		    f.value = f.value + ((char) ch) + endPart;
		} else {
		    f.value = f.value + ((char) ch);
		}
		fieldPos++;
	    } else {
		RawCurses.beep();
	    }
	}
	int changed = 0;
	for (int i = 0; i < getFields.length; i++) {
	    getFields[i].value = getFields[i].value.trim();
	    if (!getFields[i].value.equals(undoBuffer[i])) {
		changed++;
	    }
	}
	return changed;
    }

    static public void main(String[] args) {
	if (!RawCurses.initialize()) {
	    System.err.println("Initialization error");
	    System.exit(1);
	}
	Screen s = new Screen(
		new Field[] { 
		    Field.makePut(0, 0, "Hello"),
		    Field.makePut(1, 0, "World")
		},
		new Field[] { 
		},
		new Field[] { 
		    Field.makeGet(7, 15, 40)
		}
	);
	s.showScreen();
	RawCurses.endwin();
    }
}

