class ApexParser::ApexCompiler
macro
  WORD [a-zA-Z][a-zA-Z0-9]*
  BLANK  [\ \t]+
  COMMENT [\s\S\t\n]+?
  REMIN \/\*
  REMOUT \*\/
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
      select             { [:SELECT, [text, lineno]] }
      from               { [:FROM, [text, lineno]] }
      null               { [:NULL, [text, lineno]] }
      true               { [:TRUE, [text, lineno]] }
      false              { [:FALSE, [text, lineno]] }
      for                { [:FOR, [text, lineno]] }
      while              { [:WHILE, [text, lineno]] }
      if                 { [:IF, [text, lineno]] }
      else               { [:ELSE, [text, lineno]] }
      insert             { [:INSERT, [text, lineno]] }
      delete             { [:DELETE, [text, lineno]] }
      undelete           { [:UNDELETE, [text, lineno]] }
      update             { [:UPDATE, [text, lineno]] }
      upsert             { [:UPSERT, [text, lineno]] }
      before             { [:BEFORE, [text, lineno]] }
      after              { [:AFTER, [text, lineno]] }
      trigger            { [:TRIGGER, [text, lineno]] }
      on                 { [:ON, [text, lineno]] }
      with               { [:WITH, [text, lineno]] }
      without            { [:WITHOUT, [text, lineno]] }
      sharing            { [:SHARING, [text, lineno]] }
      class              { [:CLASS, [text, lineno]] }
      public             { [:PUBLIC, [text, lineno]] }
      private            { [:PRIVATE, [text, lineno]] }
      protected          { [:PROTECTED, [text, lineno]] }
      global             { [:GLOBAL, [text, lineno]] }
      override           { [:OVERRIDE, [text, lineno]] }
      static             { [:STATIC, [text, lineno]] }
      final              { [:FINAL, [text, lineno]] }
      new                { [:NEW, [text, lineno]] }
      get                { [:GET, [text, lineno]] }
      set                { [:SET, [text, lineno]] }
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
      \+                 { [:ADD, [text, lineno]] }
      \-                 { [:SUB, [text, lineno]] }
      \*                 { [:MUL, [text, lineno]] }
      \/                 { [:DIV, [text, lineno]] }
      ==                 { [:EQUAL, [text, lineno]] }
      !=                 { [:NOT_EQUAL, [text, lineno]] }
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
