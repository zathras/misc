
import java.io.StringReader;
import com.jovial.util.JsonIO;

public class Main {

    private static Object readFrom(String s) throws Exception {
	Object result = JsonIO.readJSON(new StringReader(s));
	System.out.println(s + " gives " + result.getClass() + " " + result);
	return result;
    }

    public static void main(String[] args) throws Exception {
	Object n = readFrom("1000");
	assert (n instanceof Integer);
	String notInteger = "" + Integer.MAX_VALUE + "000";
	n = readFrom(notInteger);
	assert (n instanceof Long);
	n = readFrom(notInteger + ".0");
	assert (n instanceof Double);
	n = readFrom(notInteger + "e7");
	assert (n instanceof Double);
	n = readFrom("" + Long.MAX_VALUE);
	assert (n instanceof Long);
	n = readFrom("" + Long.MIN_VALUE);
	assert (n instanceof Long);
	n = readFrom("9223372036854775808");
	assert (n instanceof Double);
	n = readFrom("-9223372036854775809");
	assert (n instanceof Double);
    }
}
