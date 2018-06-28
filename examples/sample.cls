public class Hoge extends HogeSuper {
    public Integer a;
    public Integer b = 1;

    public Hoge (){
        System.debug(112312312300);
    }

    public Integer foo(Integer c){
        System.debug(1000);
        return c;
    }
    /*
    123
     */

    @aaa // hogehoge
    public static void action() {
        System.debug('*** variable test assign***');
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);
        Hoge h = new Hoge();
        System.debug(h.b);
        h.b = 123;
        System.debug(h.b);

        List<Account> accounts = new List<Account>();
        accounts.add(new Account());
        accounts.add(new Account());
        accounts.add(new Account());

        for (Account acc : accounts) {
            System.debug(acc);
        }

        List<List<Account>> accounts = new List<List<Account>>();
        accounts.add(new List<Account>());
        accounts.add(new List<Account>());
        accounts.add(new List<Account>());

        for (List<Account> acc : accounts) {
            System.debug(acc);
        }

        List<Map<String, Integer>> ii = new List<Map<String, Integer>>();
        ii.add(new Map<String, Integer>());
        ii.add(new Map<String, Integer>());
        ii.add(new Map<String, Integer>());
        for (Map<String, Integer> i : ii) {
            System.debug(i);
        }
        Hoge h = new Hoge();
        System.debug(h);
        ii[1] = h;
        for (Map<String, Integer> i : ii) {
            System.debug(i);
        }

        System.debug(EncodingUtil.base64Decode('hogehoge'));
        System.debug(EncodingUtil.base64Encode(Blob.valueOf('hogehoge')));
        System.debug(Blob.valueOf('hogehoge').size());
        System.debug(Blob.valueOf('aahogehoge').toString());

/*
        System.debug(new Hoge());
        System.debug(h.foo(1234));
        System.debug(h.aaa());

        List l = new List();
        l.add(1);
        l.add(2);
        System.debug(l.get(1));
        System.debug(l.get(0));

        Map m = new Map();
        m.put('A', 'B');
        m.put('C', 'D');
        System.debug(m.get('A'));
        System.debug(m.get('C'));

        List accounts = [SELECT id FROM Account];
        System.debug(accounts);

        for (Account acc : accounts) {
            System.debug(acc);
        }

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
*/
    }
}
