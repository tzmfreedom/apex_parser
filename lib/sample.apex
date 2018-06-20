public class Hoge {
    public Integer a;
    public Integer b = 1;
    public static Integer action() {
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);
        a = 5;
        System.debug(a);
        System.debug(b);
        if (true) {
            System.debug('hello!!!');
        } else {
            System.debug('else!!');
        }
        return null;
    }
}
