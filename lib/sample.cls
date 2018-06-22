public class Hoge {
    public Integer a;
    public Integer b = 1;

    @aaa
    public static Integer action() {
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);
        Hoge a = new Hoge();
        b = a.fuga();
        System.debug(a.a);
        System.debug(b);
        a.a = 100;
        System.debug(a.a);
        System.debug(a);
        a = 5;
        System.debug(a);
        List accounts = new List();
        System.debug(accounts);
        for(Acount acc : accounts){
            System.debug(acc);
        }
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
        for (Integer i = 0; i < 2; i++) {
            j = 0;
        }
        return null;
    }

    public Hoge() {
        System.debug('constructor');
    }

    public Integer fuga(){
        this.a = 10000000;
        System.debug(this.a);
        return 12345;
    }
}
