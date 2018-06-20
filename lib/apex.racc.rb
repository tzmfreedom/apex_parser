class ApexCompiler

prechigh
  right ASSIGN
preclow

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV ADD SUB DOUBLE
  U_IDENT CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING THIS REMIN REMOUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF RETURN TRUE FALSE IF ELSE FOR WHILE COLON

rule
  class_or_trigger : class_def { result = val[0] }
                   | trigger_def { result = val[0] }
  type : U_IDENT
  trigger_def : TRIGGER U_IDENT ON type L_BRACE R_BRACE LC_BRACE stmts RC_BRACE
              {
                result = [:trigger, val[1], val[3], val[7]]
              }
  class_def : access_level CLASS sharing type LC_BRACE class_stmts RC_BRACE
            {
              result = ApexClassNode.new(
                access_level: val[0],
                sharing: val[2],
                name: val[3],
                statements: val[5]
              )
            }
  class_stmts : class_stmt { result = [val[0]] }
              | class_stmts class_stmt { result = val[0].push(val[1]) }
  class_stmt : instance_method_def { result = val[0] }
             | static_method_def
             | instance_variable_def SEMICOLON { result = val[0] }

  instance_variable_def : access_level modifier type IDENT { result = InstanceVariableNode.new(access_level: val[0], type: val[2], name: val[3]) }
                        | access_level modifier type IDENT ASSIGN expr
                        { result = InstanceVariableNode.new(access_level: val[0], type: val[2], name: val[3], expression: val[5]) }

  instance_method_def : access_level modifier type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                      {
                        result = ApexInstanceMethodNode.new(
                          access_level: val[0],
                          return_type: val[2],
                          name: val[3],
                          arguments: val[5],
                          statements: val[8]
                        )
                      }
  static_method_def : access_level STATIC modifier type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                    {
                      result = ApexStaticMethodNode.new(
                        access_level: val[0],
                        return_type: val[3],
                        name: val[4],
                        arguments: val[6],
                        statements: val[9]
                      )
                    }
  empty_or_arguments :
                     | arguments
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[2]) }
  argument : type IDENT { result = [:argument, val[0], val[1]] }

  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON { result = val[0] }
        | assigns SEMICOLON
        | return_stmt SEMICOLON
        | variable_def SEMICOLON
        | if_stmt
        | for_stmt
        | while_stmt
  if_stmt : IF L_BRACE expr R_BRACE LC_BRACE stmts RC_BRACE else_stmt_or_empty
          {
            result = IfNode.new(condition: val[2], if_stmt: val[5], else_stmt: val[7])
          }
else_stmt_or_empty :
                   | else_stmts
else_stmts : ELSE LC_BRACE stmts RC_BRACE { result = val[2] }
           | ELSE stmt { result = [val[1]] }
  enumurator_expr : IDENT COLON IDENT
                  { result = ConditionNode.new(left: val[0], right: val[2]) }
  for_stmt : FOR L_BRACE enumurator_expr R_BRACE LC_BRACE stmts RC_BRACE
           { result = ForNode.new(condition: val[2], statements: val[5]) }
  while_stmt : WHILE L_BRACE expr R_BRACE LC_BRACE stmts RC_BRACE
             { result = WhileNode.new(condition: val[2], statements: val[5]) }
  assigns : assign { result = val[0] }
          | IDENT ASSIGN assigns { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
  assign : IDENT ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }

  expr  : number { result = val[0] }
        | STRING { result = ApexStringNode.new(value: val[0]) }
        | call_class_method { result = val[0] }
        | call_method { result = val[0] }
        | IDENT { result = IdentifyNode.new(name: val[0]) }
        | IDENT INSTANCE_OF U_IDENT
        | boolean
  number : term { result = ApexIntegerNode.new(value: val[0]) }
         | number ADD term {}
         | number SUB term {}
  term   : primary_expr
         | term MUL primary_expr {}
         | term DIV primary_expr {}
  return_stmt : RETURN expr { result = OperatorNode.new(type: :return, left: val[1]) }
  primary_expr : INTEGER
               | DOUBLE
  variable_def : type IDENT { result = OperatorNode.new(type: :define, left: val[1]) }
               | type IDENT ASSIGN def_assigns
               { result = OperatorNode.new(type: :define, left: val[1], right: val[3]) }
  def_assigns : expr
              | IDENT ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
  call_class_method : U_IDENT DOT IDENT L_BRACE call_arguments R_BRACE
                      {
                        result = CallStaticMethodNode.new(
                          apex_class_name: val[0],
                          apex_method_name: val[2],
                          arguments: val[4]
                        )
                      }
  call_method : expr DOT IDENT L_BRACE call_arguments R_BRACE
                { result = CallInstanceMethodNode.new(type: :call, receiver: val[0], method_name: val[2], arguments: val[4]) }
  call_arguments : call_argument { result = [val[0]] }
                 | call_arguments COMMA call_argument { result = val[0].push(val[2]) }
  call_argument : expr { result = val[0] }

  access_level : PUBLIC
               | PRIVATE
               | PROTECTED
  modifier :
           | ABSTRACT
           | FINAL
           | GLOBAL
  sharing :
          | WITH SHARING { result = :with_sharing }
          | WITHOUT SHARING { result = :without_sharing }
  boolean : TRUE { result = BooleanNode.new(true) }
          | FALSE { result = BooleanNode.new(false) }
end

---- header

require './lib/apex.l'
require './lib/node'

---- inner

---- footer

