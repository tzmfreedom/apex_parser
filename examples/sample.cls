public class Hoge extends HogeSuper{
    public Integer a;
    public Integer b = 1;

    public Hoge (){
        System.debug(100);
    }

    public Integer foo(Integer c){
        System.debug(100);
    }

    @aaa
    public static Integer action() {
        System.debug('*** variable test assign***');
        Integer b = 100;
        System.debug(b);
        Integer a = b = 20;
        System.debug(a);
        System.debug(b);
    }
}
