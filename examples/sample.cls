public class Hoge extends HogeSuper{
    public Integer a;
    public Integer b = 1;

    public Hoge (){
        System.debug(100);
    }

    public Integer foo(Integer c){
        System.debug(1000);
        return c;
    }

    @aaa
    public static void action() {
        System.debug('*** variable test assign***');
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);

        System.debug(new Hoge());
        Hoge h = new Hoge();
        System.debug(h.foo(1234));

        if (1 == 2) {
            System.debug('hoge');
        } else if (false) {
            System.debug('fuga');
        } else if (true) {
            System.debug('piyp');
        }

        for (Integer i = 0; i < 10; i++) {
            System.debug(i);
        }

        Integer i = 0;
        while (i < 4) {
            System.debug(i+5);
            i++;
        }
    }
}
