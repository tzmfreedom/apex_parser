class ApexCompiler

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV ADD SUB DOUBLE
  U_IDENT CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING REMIN REMOUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF RETURN TRUE FALSE

rule
  define_class : PUBLIC CLASS U_IDENT LC_BRACE class_stmts RC_BRACE { result = [[:class, val[0], val[2], val[4]]] }
  class_stmts : method { result = [val[0]] }
              | class_stmts method { result val[0].push(val[1]) }
  method : PUBLIC U_IDENT IDENT L_BRACE arguments R_BRACE LC_BRACE stmts RC_BRACE
           { result = [:method, val[0], val[1], val[2], val[4], val[7]]}
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[1]) }
  argument : U_IDENT IDENT { result = [:argument, val[0], val[1]] }
  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON { result = val[0] }
        | return_stmt SEMICOLON
        | definement
        | call_class_method
  expr  : term { result = val[0] }
        | IDENT { result = [:ident, val[0]] }
        | IDENT ASSIGN term { result = [:assign, val[0], val[2]]}
        | IDENT INSTANCE_OF U_IDENT
  term  : primary_expr { result = val[0] }
        | INTEGER MUL INTEGER
        | INTEGER DIV INTEGER
  return_stmt : RETURN expr { result = [:return, val[1]] }
  primary_expr : INTEGER
               | DOUBLE { result = val[0] }
  definement : U_IDENT IDENT SEMICOLON { result = [:define, val[1]] }
             | U_IDENT IDENT ASSIGN expr SEMICOLON { result = [:define, val[1], val[3]]}
  call_class_method : U_IDENT DOT IDENT L_BRACE STRING R_BRACE SEMICOLON { result = [:class_method, val[0], val[2], val[4]] }
  access_level : PUBLIC
               | PRIVATE
               | PROTECTED
  modifier : ABSTRACT
           | FINAL
           | GLOBAL
  sharing : WITH SHARING
          | WITHOUT SHARING
  boolean : FALSE
          | TRUE
end

---- header

require './lib/apex.l'
require './lib/element'

---- inner

---- footer

parser = ApexCompiler.new

statements = parser.scan_str(STDIN.read)
parts = statements[0][3][0][5][2]
ApexClassTable[parts[1]].instance_methods[parts[2].to_sym].eval(parts[3])
# statements.each do |statement|
#   pp statement
# end
