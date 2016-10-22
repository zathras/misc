
package scurses;

/**
 * Representation of a field within a Screen.  Field objects are made with
 * the static factory methods makeGet() and makePut().
 **/

public class Field {

    final int y;
    final int x;
    final int minLength;	// 0 means "no minimum"
    String value;

    private Field(int y, int x, int minLength) {
	this.y = y;
	this.x = x;
	this.minLength = minLength;
    }

    public static Field makePut(int y, int x, String value) {
	Field result = new Field(y, x, 0);
	result.setValue(value);
	return result;
    }

    public static Field makeGet(int y, int x, int minLength) {
	Field result = new Field(y, x, minLength);
	result.setValue("");
	return result;
    }

    public String getValue() {
	return value;
    }

    public void setValue(String value) {
	this.value = value;
    }
}
