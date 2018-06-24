class ApexParser::ApexCompiler
macro
  WORD [a-zA-Z][a-zA-Z0-9\_]*
  BLANK  [\ \t]+
  COMMENT [\s\S\t]+?
  REMIN \/\*
  REMOUT \*\/
  DELIM_BLANK (?=\s)
  DELIM (?=[\(\s])
rule
      {BLANK}
      {REMIN}            { @state = :REM; [:REM_IN, [text, lineno]] }
:REM  {REMOUT}           { @state = nil; [:REM_OUT, [text, lineno]] }
:REM  ({COMMENT})(?={REMOUT})   { [:COMMENT, [text, lineno]] }
      \/\/.*\n           { [:COMMENT, [text, lineno]] }
      \[                 { [:LS_BRACE, [text, lineno]] }
      \]                 { [:RS_BRACE, [text, lineno]] }
      \{                 { [:LC_BRACE, [text, lineno]] }
      \}                 { [:RC_BRACE, [text, lineno]] }
      \(                 { [:L_BRACE, [text, lineno]] }
      \)                 { [:R_BRACE, [text, lineno]] }
      '[^']*'            { [:STRING, [text[1..-2], lineno]] }
      @\w+               { [:ANNOTATION, [text, lineno]] }
      select{DELIM_BLANK} { [:SELECT, [text, lineno]] }
      from{DELIM_BLANK}               { [:FROM, [text, lineno]] }
      try(?=[\s\{])               { [:TRY, [text, lineno]] }
      catch(?=[\s\{])               { [:CATCH, [text, lineno]] }
      null(?=[\s;\(\)])               { [:NULL, [text, lineno]] }
      true(?=[\s;\(\)])               { [:TRUE, [text, lineno]] }
      false(?=[\s;\(\)])              { [:FALSE, [text, lineno]] }
      for{DELIM}        { [:FOR, [text, lineno]] }
      while{DELIM}              { [:WHILE, [text, lineno]] }
      if{DELIM}                 { [:IF, [text, lineno]] }
      else{DELIM}               { [:ELSE, [text, lineno]] }
      insert{DELIM_BLANK}             { [:INSERT, [text, lineno]] }
      delete{DELIM_BLANK}             { [:DELETE, [text, lineno]] }
      undelete{DELIM_BLANK}           { [:UNDELETE, [text, lineno]] }
      update{DELIM_BLANK}             { [:UPDATE, [text, lineno]] }
      upsert{DELIM_BLANK}             { [:UPSERT, [text, lineno]] }
      before{DELIM_BLANK}             { [:BEFORE, [text, lineno]] }
      after{DELIM_BLANK}              { [:AFTER, [text, lineno]] }
      trigger{DELIM_BLANK}            { [:TRIGGER, [text, lineno]] }
      on{DELIM_BLANK}                 { [:ON, [text, lineno]] }
      with{DELIM_BLANK}               { [:WITH, [text, lineno]] }
      without{DELIM_BLANK}            { [:WITHOUT, [text, lineno]] }
      sharing{DELIM_BLANK}            { [:SHARING, [text, lineno]] }
      class{DELIM_BLANK}              { [:CLASS, [text, lineno]] }
      public{DELIM_BLANK}             { [:PUBLIC, [text, lineno]] }
      private{DELIM_BLANK}            { [:PRIVATE, [text, lineno]] }
      protected{DELIM_BLANK}          { [:PROTECTED, [text, lineno]] }
      global{DELIM_BLANK}            { [:GLOBAL, [text, lineno]] }
      override{DELIM_BLANK}          { [:OVERRIDE, [text, lineno]] }
      static{DELIM_BLANK}           { [:STATIC, [text, lineno]] }
      final{DELIM_BLANK}            { [:FINAL, [text, lineno]] }
      new{DELIM_BLANK}              { [:NEW, [text, lineno]] }
      get(?=[;\s])           { [:GET, [text, lineno]] }
      set(?=[;\s])           { [:SET, [text, lineno]] }
      extends            { [:EXTENDS, [text, lineno]] }
      implements         { [:IMPLEMENTS, [text, lineno]] }
      abstract           { [:ABSTRACT, [text, lineno]] }
      virtual            { [:VIRTUAL, [text, lineno]] }
      instance_of        { [:INSTANCE_OF, [text, lineno]] }
      return             { [:RETURN, [text, lineno]] }
      \d+                { [:INTEGER, [text.to_i, lineno]] }
      {WORD}\<{WORD}\>   { [:IDENT, [text, lineno]] }
      {WORD}\[\]         { [:IDENT, [text, lineno]] }
      {WORD}             { [:IDENT, [text, lineno]] }
      \n
      \+\+                 { [:INCR, [text, lineno]] }
      \-\-                 { [:DECR, [text, lineno]] }
      \+                 { [:ADD, [text, lineno]] }
      \-                 { [:SUB, [text, lineno]] }
      \*                 { [:MUL, [text, lineno]] }
      \/                 { [:DIV, [text, lineno]] }
      &                  { [:AND, [text, lineno]] }
      \|                  { [:OR, [text, lineno]] }
      \^                 { [:TILDE, [text, lineno]] }
      &&                 { [:CONDITIONAL_AND, [text, lineno]] }
      \|\|                 { [:CONDITIONAL_OR, [text, lineno]] }
      ==                 { [:EQUAL, [text, lineno]] }
      !=                 { [:NOT_EQUAL, [text, lineno]] }
      <<                 { [:LEFT_SHIFT, [text, lineno]] }
      >>                 { [:RIGHT_SHIFT, [text, lineno]] }
      <                  { [:LESS_THAN, [text, lineno]] }
      >                  { [:GREATER_THAN, [text, lineno]] }
      <=                 { [:LESS_THAN_EQUAL, [text, lineno]] }
      >=                 { [:GREATER_THAN_EQUAL, [text, lineno]] }
      =                  { [:ASSIGN, [text, lineno]] }
      \:                 { [:COLON, [text, lineno]]}
      ;                  { [:SEMICOLON, [text, lineno]]}
      ,                  { [:COMMA, [text, lineno]] }
      \.                 { [:DOT, [text, lineno]] }
      .                  { [text, [text, lineno]] }
end
