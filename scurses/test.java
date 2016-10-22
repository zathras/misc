
import com.sun.jna.Native;

public class test {
    public static void main(String[] args) {
        Native.loadLibrary("foo", null);
    }
}
