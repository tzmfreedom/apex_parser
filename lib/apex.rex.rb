class ApexCompiler
macro
  BLANK  [\ \t]+
rule
  {BLANK}
  \{        { [:LC_BRACE, text] }
  \}        { [:RC_BRACE, text] }
  \(        { [:L_BRACE, text] }
  \)        { [:R_BRACE, text] }
  '[\s\w]*' { [:STRING, text[1..-2]] }
  class     { [:CLASS, text] }
  public    { [:PUBLIC, text] }
  return    { [:RETURN, text] }
  \d+       { [:INTEGER, text.to_i] }
  [A-Z]\w*       { [:U_IDENT, text] }
  [a-z]\w*       { [:IDENT, text] }
  \n
  \+         { [:ADD, text] }
  \-         { [:SUB, text] }
  \*         { [:MUL, text] }
  \/         { [:DIV, text] }
  =         { [:ASSIGN, text] }
  ;         { [:SEMICOLON, text]}
  ,         { [:COMMA, text] }
  \.         { [:DOT, text] }
  .         { [text, text] }
end
