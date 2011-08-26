import java.security.MessageDigest;

public class Solve
{
    private static final char[] table = {
        50, 52, 51, 53, 55, 48, 66, 69, 68, 49, 67, 54, 57, 56, 70, 65
    };
 
    public static void main(String[] args) {
        try {
            String code = getCode("KoRoN.KaoriYa", "w8f21fgtk8");
            System.out.println("code=" + code);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static String getCode(String seed1, String seed2)
        throws Exception
    {
        seed1 = seed1.trim();
        seed2 = seed2.trim().toLowerCase();

        MessageDigest digester = MessageDigest.getInstance("SHA-1");
        byte[] digest = digester.digest((seed1 + seed2).getBytes("8859_1"));

        StringBuilder code = new StringBuilder();
        for (int i = 0; i < 10; ++i) {
            if (i > 0 && (i % 2) == 0) {
                code.append(' ');
            }
            int n = ((int)digest[i] ^ (int)(digest[i + 10]));
            code.append(table[(n >> 4) & 0xF]);
            code.append(table[(n >> 0) & 0xF]);
        }

        return code.toString();
    }
}
