public class Hoge {
    public Integer a;
    public Integer b = 1;

    @aaa
    public static Integer action() {
        List<Account> account = new List<Account>();
        System.debug(account);
        new Fuga().aaa();
        System.debug(new Fuga());
        System.debug('*** variable test assign***');
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);

        System.debug('*** instance variable/method test ***');
        Hoge a = new Hoge();
        System.debug(a);
        b = a.fuga();
        System.debug(b);
        System.debug(a.a);
        a.a = 100;
        System.debug(a.a);

        System.debug('*** list test ***');
        List<Account> accounts = new List<Account>();
        accounts.add(1);
        accounts.add(100);
        System.debug(accounts);
        for(Account acc : accounts){
            System.debug(acc);
        }

        System.debug('*** soql test ***');
        a = [SELECT id FROM Account WHERE id = 1];
        System.debug(a);

        System.debug('*** case test ***');
        if (true) {
            System.debug('hello!!!');
        } else if (false) {
            System.debug('else!!');
        } else if (true) {
            System.debug('falseaaaa');
        }
        System.debug('*** for loop ***');
        for (Integer i = 0; i < 2; i++) {
            System.debug(i);
        }
        System.debug('*** while loop ***');
        i = 3;
        while (i < 5) {
          System.debug(i);
          i++;
        }
        System.debug('*** add/sub/mul/div ***');
        System.debug(1+4*5);
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

    public Integer foo() {
        this.accounts = [SELECT id FROM Account];
        this.contacts = [SELECT id FROM Contact];
        return 1;
    }
}
