class ApexCompiler

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV ADD SUB DOUBLE
  U_IDENT CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING THIS REMIN REMOUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF RETURN TRUE FALSE

rule
  class_or_trigger : class_def { result = val[0] }
                   | trigger_def { result = val[0] }
  type : U_IDENT
  trigger_def : TRIGGER U_IDENT ON U_IDENT L_BRACE R_BRACE LC_BRACE stmts RC_BRACE
              {
                result = [:trigger, val[1], val[3], val[7]]
              }
  class_def : access_level CLASS sharing U_IDENT LC_BRACE class_stmts RC_BRACE
            {
              result = ApexClassNode.new(
                access_level: val[0],
                sharing: val[2],
                name: val[3],
                statements: val[5]
              )
            }
  instance_variable_def : access_level type IDENT SEMICOLON { result = InstanceVaribleNode.new(access_level: val[0], type: val[1], name: val[2]) }
                        | access_level type IDENT ASSIGN expr SEMICOLON
                          { result = InstanceVariableNode.new(access_level: val[0], type: val[1], name: val[2], expression: val[4]) }
  class_stmts : class_stmt { result = [val[0]] }
              | class_stmts class_stmt { result = val[0].push(val[1]) }
  class_stmt : method_def { result = val[0] }
             | instance_variable_def { result = val[0] }
  method_def : PUBLIC U_IDENT IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
               {
                 result = ApexMethodNode.new(
                   access_level: val[0],
                   return_type: val[1],
                   name: val[2],
                   arguments: val[4],
                   statements: val[7]
                 )
               }
  empty_or_arguments :
                     | arguments
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[1]) }
  argument : U_IDENT IDENT { result = [:argument, val[0], val[1]] }

  call_arguments : call_argument { result = [val[0]] }
                 | call_arguments COMMA call_argument { result = val[0].push(val[1]) }
  call_argument : expr { result = val[0] }

  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON { result = val[0] }
        | return_stmt SEMICOLON
        | variable_def SEMICOLON
        | IDENT ASSIGN expr SEMICOLON { result = StatementNode.new(type: :assign, name: val[0], expression: val[2]) }

  expr  : number { result = val[0] }
        | STRING { result = ApexStringNode.new(value: val[0]) }
        | call_class_method { result = val[0] }
        | call_method { result = val[0] }
        | IDENT { result = IdentifyNode.new(name: val[0]) }
        | IDENT INSTANCE_OF U_IDENT
        | boolean
  number : primary_expr { result = ApexIntegerNode.new(value: val[0]) }
         | number MUL primary_expr {}
         | number DIV primary_expr {}
  return_stmt : RETURN expr { result = StatementNode.new(type: :return, expression: val[1]) }
  primary_expr : INTEGER
               | DOUBLE
  variable_def : U_IDENT IDENT { result = StatementNode.new(type: :define, name: val[1]) }
               | U_IDENT IDENT ASSIGN expr { result = StatementNode.new(type: :define, name: val[1], expression: val[3]) }

  call_class_method : U_IDENT DOT IDENT L_BRACE call_arguments R_BRACE
                      { result = StatementNode.new(type: :call, receiver: val[0], method_name: val[2], arguments: val[4]) }
  call_method : expr DOT IDENT L_BRACE call_arguments R_BRACE
                { result = StatementNode.new(type: :call, receiver: val[0], method_name: val[2], arguments: val[4]) }
  access_level : PUBLIC
               | PRIVATE
               | PROTECTED
  modifier : ABSTRACT
           | FINAL
           | GLOBAL
  sharing :
          | WITH SHARING { result = :with_sharing }
          | WITHOUT SHARING { result = :without_sharing }
  boolean : FALSE
          | TRUE
end

---- header

require './lib/apex.l'
require './lib/node'

---- inner

---- footer

