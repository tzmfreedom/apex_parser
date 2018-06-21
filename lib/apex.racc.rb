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
  class_or_trigger : class_def
                   | trigger_def
  type : U_IDENT { result = value(val, 0) }
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
  class_stmt : instance_method_def
             | static_method_def
             | constructor_def
             | instance_variable_def SEMICOLON

  instance_variable_def : access_level type IDENT { result = InstanceVariableNode.new(access_level: val[0], type: val[1], name: value(val, 2)) }
                        | access_level type IDENT ASSIGN expr
                        { result = InstanceVariableNode.new(access_level: val[0], type: val[1], name: value(val, 2), expression: val[4]) }
  constructor_def : access_level U_IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                  {
                    result = ApexInstanceMethodNode.new(
                      access_level: val[0],
                      return_type: :void,
                      name: value(val, 1),
                      arguments: val[3] || [],
                      statements: val[6]
                    )
                  }
  instance_method_def : access_level modifier type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                      {
                        result = ApexInstanceMethodNode.new(
                          access_level: val[0],
                          return_type: val[2],
                          name: value(val, 3),
                          arguments: val[5] || [],
                          statements: val[8]
                        )
                      }
                      | access_level type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                      {
                        result = ApexInstanceMethodNode.new(
                          access_level: val[0],
                          return_type: val[1],
                          name: value(val, 2),
                          arguments: val[4] || [],
                          statements: val[7]
                        )
                      }
  static_method_def : access_level STATIC modifier type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                    {
                      result = ApexStaticMethodNode.new(
                        access_level: val[0],
                        return_type: val[3],
                        name: value(val, 4),
                        arguments: val[6] || [],
                        statements: val[9]
                      )
                    }
                    | access_level STATIC type IDENT L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                    {
                      result = ApexStaticMethodNode.new(
                        access_level: val[0],
                        return_type: val[2],
                        name: value(val, 3),
                        arguments: val[5] || [],
                        statements: val[8]
                      )
                    }
  empty_or_arguments :
                     | arguments
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[2]) }
  argument : type IDENT { result = ArgumentNode.new(type: val[0], name: val[1]) }

  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON
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
                  { result = ConditionNode.new(left: value(val, 0), right: value(val, 2)) }
  for_stmt : FOR L_BRACE enumurator_expr R_BRACE LC_BRACE stmts RC_BRACE
           { result = ForNode.new(condition: val[2], statements: val[5]) }
  while_stmt : WHILE L_BRACE expr R_BRACE LC_BRACE stmts RC_BRACE
             { result = WhileNode.new(condition: val[2], statements: val[5]) }
  assigns : assign
          | variable ASSIGN assigns { result = OperatorNode.new(type: :assign, left: value(val, 0), right: val[2]) }
  assign : variable ASSIGN expr { result = OperatorNode.new(type: :assign, left: value(val, 0), right: val[2]) }
  variable : IDENT
           | instance_variable
expr  : number
        | new_expr
        | STRING { result = ApexStringNode.new(value: value(val, 0), lineno: get_lineno(val, 0)) }
        | call_class_method
        | call_method
        | IDENT { result = IdentifyNode.new(name: value(val, 0)) }
        | IDENT INSTANCE_OF U_IDENT
        | boolean
        | instance_variable
new_expr : NEW U_IDENT L_BRACE empty_or_arguments R_BRACE
         {
           result = NewNode.new(apex_class_name: value(val, 1), arguments: val[3] && value(val, 3))
         }
  number : term
         | number ADD term {}
         | number SUB term {}
  term   : primary_expr
         | term MUL primary_expr {}
         | term DIV primary_expr {}
  return_stmt : RETURN expr { result = OperatorNode.new(type: :return, left: val[1]) }
  primary_expr : INTEGER { result = ApexIntegerNode.new(value: value(val, 0)) }
               | DOUBLE
  variable_def : type IDENT { result = OperatorNode.new(type: :define, left: value(val, 1)) }
               | type IDENT ASSIGN def_assigns
               { result = OperatorNode.new(type: :define, left: value(val, 1), right: val[3]) }
  def_assigns : expr
              | IDENT ASSIGN expr { result = OperatorNode.new(type: :assign, left: value(val, 0), right: val[2]) }
  call_class_method : U_IDENT DOT IDENT L_BRACE call_arguments R_BRACE
                      {
                        result = CallStaticMethodNode.new(
                          apex_class_name: value(val, 0),
                          apex_method_name: value(val, 2),
                          arguments: val[4]
                        )
                      }
instance_variable : expr DOT IDENT
  call_method : expr DOT IDENT L_BRACE empty_or_call_arguments R_BRACE
                { result = CallInstanceMethodNode.new(type: :call, receiver: val[0], name: value(val, 2), arguments: val[4] || []) }
  empty_or_call_arguments :
                          | call_arguments
  call_arguments : call_argument { result = [val[0]] }
                 | call_arguments COMMA call_argument { result = val[0].push(val[2]) }
  call_argument : expr

  access_level : PUBLIC
               | PRIVATE
               | PROTECTED
  modifier : ABSTRACT
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

def value(val, idx)
  val[idx][0]
end

def get_lineno(val, idx)
  val[idx][1]
end

---- footer

