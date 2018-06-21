public class Hoge {
    public Integer a;
    public Integer b = 1;
    public static Integer action() {
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);
        Hoge a = new Hoge();
        a.fuga();
        System.debug(a);
        a = 5;
        System.debug(a);
        a = [SELECT id FROM Account WHERE id = 1];
        System.debug(a);
        System.debug(b);
        if (true) {
            System.debug('hello!!!');
        } else if (false) {
            System.debug('else!!');
        } else if (true) {
            System.debug('falseaaaa');
        }
        for (Integer i = 0; i < 10; i++) {
            System.debug(i);
        }
        return null;
    }

    public Hoge() {
        System.debug('constructor');
    }

    public Integer fuga(){
        System.debug('call fuga!!!');
    }
}
