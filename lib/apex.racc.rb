class ApexCompiler

prechigh
  right ASSIGN
preclow

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV ADD SUB DOUBLE
  CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING REMIN REMOUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF TRUE FALSE IF ELSE FOR WHILE COLON
  LESS_THAN LESS_THAN_EQUAL NOT_EQUAL EQUAL GREATER_THAN GREATER_THAN_EQUAL
  SOQL SOQL_IN SOQL_OUT NULL

rule
  class_or_trigger : class_def
                   | trigger_def
  trigger_def : TRIGGER ident ON ident L_BRACE R_BRACE LC_BRACE stmts RC_BRACE
              {
                result = [:trigger, val[1], val[3], val[7]]
              }
  class_def : access_level CLASS sharing ident LC_BRACE class_stmts RC_BRACE
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

  instance_variable_def : empty_or_annotations access_level ident ident { result = DefInstanceVariableNode.new(access_level: val[1], type: val[2], name: val[3]) }
                        | empty_or_annotations access_level ident ident ASSIGN expr
                        { result = DefInstanceVariableNode.new(access_level: val[1], type: val[2], name: val[3], expression: val[5]) }
  constructor_def : empty_or_annotations access_level ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                  {
                    result = ApexDefInstanceMethodNode.new(
                      access_level: val[1],
                      return_type: :void,
                      name: val[2],
                      arguments: val[4] || [],
                      statements: val[7]
                    )
                  }
  instance_method_def : empty_or_annotations access_level modifier ident ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                      {
                        result = ApexDefInstanceMethodNode.new(
                          access_level: val[1],
                          return_type: val[3],
                          name: val[4],
                          arguments: val[6] || [],
                          statements: val[9]
                        )
                      }
                      | empty_or_annotations access_level ident ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                      {
                        result = ApexDefInstanceMethodNode.new(
                          access_level: val[1],
                          return_type: val[2],
                          name: val[3],
                          arguments: val[5] || [],
                          statements: val[8]
                        )
                      }
  static_method_def : empty_or_annotations access_level STATIC modifier ident ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                    {
                      result = ApexStaticMethodNode.new(
                        access_level: val[1],
                        return_type: val[4],
                        name: val[5],
                        arguments: val[7] || [],
                        statements: val[10]
                      )
                    }
                    | empty_or_annotations access_level STATIC ident ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                    {
                      result = ApexStaticMethodNode.new(
                        access_level: val[1],
                        return_type: val[3],
                        name: val[4],
                        arguments: val[6] || [],
                        statements: val[9]
                      )
                    }
  empty_or_arguments :
                     | arguments
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[2]) }
  argument : ident ident { result = ArgumentNode.new(type: val[0], name: val[1]) }

  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON
        | assigns SEMICOLON
        | return_stmt SEMICOLON
        | variable_def SEMICOLON
        | boolean_stmt SEMICOLON
        | if_stmt
        | for_stmt
        | while_stmt
  loop_stmt  : expr
             | assigns
             | variable_def
             | boolean_stmt
  if_stmt : IF L_BRACE expr R_BRACE LC_BRACE stmts RC_BRACE else_stmt_or_empty
          {
            result = IfNode.new(condition: val[2], if_stmt: val[5], else_stmt: val[7])
          }
else_stmt_or_empty :
                   | else_stmts
else_stmts : ELSE LC_BRACE stmts RC_BRACE { result = val[2] }
           | ELSE stmt { result = [val[1]] }
  for_stmt : FOR L_BRACE empty_or_loop_stmt SEMICOLON empty_or_loop_stmt SEMICOLON empty_or_loop_stmt R_BRACE LC_BRACE stmts RC_BRACE
           { result = ForNode.new(init_stmt: val[2], exit_condition: val[4], increment_stmt: val[6], statements: val[9]) }
           | FOR L_BRACE ident ident COLON ident R_BRACE LC_BRACE stmts RC_BRACE
           { result = ForEnumNode.new(type: val[2], ident: val[3], list: val[5], statements: val[8]) }
  empty_or_loop_stmt :
                     | loop_stmt
  while_stmt : WHILE L_BRACE expr R_BRACE LC_BRACE stmts RC_BRACE
             { result = WhileNode.new(condition: val[2], statements: val[5]) }
  assigns : assign
          | ident ASSIGN assigns { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
          | instance_variable ASSIGN assigns { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
  assign : ident ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
         | instance_variable ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
  expr  : number
        | new_expr
        | STRING { result = ApexStringNode.new(value: value(val, 0), lineno: get_lineno(val, 0)) }
        | call_method
        | ident INSTANCE_OF ident
        | ident
        | instance_variable
        | boolean
        | NULL { result = NullNode.new }
        | unary_operator ident { result = OperatorNode.new(type: val[0], left: val[1])}
        | ident unary_operator { result = OperatorNode.new(type: val[1], left: val[0])}
        | SOQL_IN SOQL SOQL_OUT { result = SoqlNode.new(soql: value(val,1)) }
new_expr : NEW ident L_BRACE empty_or_arguments R_BRACE
         {
           result = NewNode.new(apex_class_name: val[1], arguments: val[3] && val[3])
         }
  number : term
         | number ADD term {}
         | number SUB term {}
  term   : primary_expr
         | term MUL primary_expr {}
         | term DIV primary_expr {}
  return_stmt : RETURN expr { result = ReturnNode.new(expression: val[1]) }
  primary_expr : INTEGER { result = ApexIntegerNode.new(value: value(val,0)) }
               | DOUBLE
  variable_def : ident ident { result = OperatorNode.new(type: :define, left: val[1]) }
               | ident ident ASSIGN def_assigns
               { result = OperatorNode.new(type: :define, left: val[1], right: val[3]) }
  def_assigns : expr
              | ident ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
  call_method : expr DOT ident L_BRACE empty_or_call_arguments R_BRACE
              {
                result = CallMethodNode.new(
                  receiver: val[0],
                  apex_method_name: val[2],
                  arguments: val[4]
                )
              }
instance_variable : expr DOT ident { result = InstanceVariableNode.new(receiver: val[0], name: val[2]) }
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
  boolean_stmt : expr comparator expr { result = OperatorNode.new(type: value(val, 1), left: val[0], right: val[2])}
  comparator : LESS_THAN
             | LESS_THAN_EQUAL
             | GREATER_THAN
             | GREATER_THAN_EQUAL
             | NOT_EQUAL
             | EQUAL
  empty_or_annotations :
                       | annotations
  annotations : annotation { result = [val[0]]}
              | annotations annotation { result = val[0].push(val[1]) }
  annotation : ANNOTATION { result = AnnotationNode.new(val[0]) }
  unary_operator: ADD ADD { result = :plus_plus }
                | SUB SUB { resutl = :minus_minus }
  ident : IDENT { result = IdentifyNode.new(name: value(val, 0)) }
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

