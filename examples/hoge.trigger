trigger Account on Account (before insert, after update) {
   System.debug(100);
   insert hoge;

   switch on hoge {
     when 'hoge' {
       System.debug('123');
     }
     when else {
       System.debug('else');
     }
   }
}
