class ApexCompiler
macro
  BLANK  [\ \t]+
  REMIN \/\*
  REMOUT \*\/
rule
      {BLANK}
      {REMIN}          { state = :REM; [:REM_IN, text] }
:REM  {REMOUT}         { state = nil; [:REM_OUT, text] }
:REM  (.+)(?={REMOUT}) { [:COMMENT, text] }
      \/\/.*\n         { [:COMMENT, text] }
      \{               { [:LC_BRACE, text] }
      \}               { [:RC_BRACE, text] }
      \(               { [:L_BRACE, text] }
      \)               { [:R_BRACE, text] }
      '[^']*'          { [:STRING, text[1..-2]] }
      @\w+             { [:ANNOTATION, text] }
      true             { [:TRUE, text] }
      false            { [:FALSE, text] }
      for              { [:FOR, text] }
      while            { [:WHILE, text] }
      if               { [:IF, text] }
      else             { [:ELSE, text] }
      this             { [:THIS, text] }
      insert           { [:INSERT, text] }
      delete           { [:DELETE, text] }
      undelete         { [:UNDELETE, text] }
      update           { [:UPDATE, text] }
      upsert           { [:UPSERT, text] }
      before           { [:BEFORE, text] }
      after            { [:AFTER, text] }
      trigger          { [:TRIGGER, text] }
      on               { [:ON, text] }
      with             { [:WITH, text] }
      without          { [:WITHOUT, text] }
      sharing          { [:SHARING, text] }
      class            { [:CLASS, text] }
      public           { [:PUBLIC, text] }
      private          { [:PRIVATE, text] }
      protected        { [:PROTECTED, text] }
      global           { [:GLOBAL, text] }
      override         { [:OVERRIDE, text] }
      static           { [:STATIC, text] }
      final            { [:FINAL, text] }
      new              { [:NEW, text] }
      get              { [:GET, text] }
      set              { [:SET, text] }
      extends          { [:EXTENDS, text] }
      implements       { [:IMPLEMENTS, text] }
      abstract         { [:ABSTRACT, text] }
      virtual          { [:VIRTUAL, text] }
      instance_of      { [:INSTANCE_OF, text] }
      return           { [:RETURN, text] }
      \d+              { [:INTEGER, text.to_i] }
      [A-Z]\w*         { [:U_IDENT, text] }
      [a-z]\w*         { [:IDENT, text] }
      \n
      \+               { [:ADD, text] }
      \-               { [:SUB, text] }
      \*               { [:MUL, text] }
      \/               { [:DIV, text] }
      ==               { [:EQUAL, text] }
      !=               { [:NOT_EQUAL, text] }
      <                { [:LESS_THAN, text] }
      >                { [:GREATER_THAN, text] }
      <=               { [:LESS_THAN_EQUAL, text] }
      >=               { [:GREATER_THAN_EQUAL, text] }
      =                { [:ASSIGN, text] }
      ;                { [:SEMICOLON, text]}
      ,                { [:COMMA, text] }
      \.               { [:DOT, text] }
      .                { [text, text] }
end
