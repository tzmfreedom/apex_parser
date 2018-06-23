class ApexParser::ApexCompiler

prechigh
  right ASSIGN
preclow

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV ADD SUB DOUBLE
  CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING REM_IN REM_OUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF TRUE FALSE IF ELSE FOR WHILE COLON
  LESS_THAN LESS_THAN_EQUAL NOT_EQUAL EQUAL GREATER_THAN GREATER_THAN_EQUAL
  NULL CONTINUE BREAK SELECT FROM
  LS_BRACE RS_BRACE

rule
  root_stmts : class_or_trigger { result = [val[0]] }
             | root_stmts class_or_trigger { val[0].push(val[1]) }
  class_or_trigger : class_def
                   | trigger_def
                   | comment
  trigger_def : TRIGGER ident ON ident L_BRACE R_BRACE LC_BRACE stmts RC_BRACE
              {
                result = [:trigger, val[1], val[3], val[7]]
              }
  class_def : access_level sharing empty_or_modifiers CLASS ident empty_or_extends empty_or_implements LC_BRACE class_stmts RC_BRACE
            {
              result = ApexClassNode.new(
                access_level: val[0],
                sharing: val[1],
                modifiers: val[2],
                name: val[4].name,
                statements: val[8],
                apex_super_class: val[5],
                implements: val[6]
              )
            }
  empty_or_extends :
                   | EXTENDS ident { result = val[1] }
  empty_or_implements :
                      | IMPLEMENTS implements { result = val[1] }
  implements : ident { result = [val[0]] }
             | implements COMMA ident { result = val[0].push(val[1]) }
  class_stmts : class_stmt { result = [val[0]] }
              | class_stmts class_stmt { result = val[0].push(val[1]) }
  class_stmt : method_def
             | constructor_def
             | instance_variable_def
             | comment

  instance_variable_def : empty_or_annotations access_level empty_or_modifiers ident ident SEMICOLON
                        {
                          result = DefInstanceVariableNode.new(access_level: val[1], modifiers: val[2], type: val[3].name, name: val[4].name)
                        }
                        | empty_or_annotations access_level empty_or_modifiers ident ident ASSIGN expr SEMICOLON
                        { result = DefInstanceVariableNode.new(access_level: val[1], modifiers: val[2], type: val[3].name, name: val[4].name, expression: val[6]) }
                        | empty_or_annotations access_level empty_or_modifiers ident ident LC_BRACE getter_setter RC_BRACE
                        { result = DefInstanceVariableNode.new(access_level: val[1], modifiers: val[2], type: val[3].name, name: val[4].name, expression: val[6]) }
  getter_setter : getter setter
                | setter getter
  getter : GET
  setter : SET

  constructor_def : empty_or_annotations access_level empty_or_modifiers ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
                  {
                    result = ApexDefMethodNode.new(
                      access_level: val[1],
                      return_type: :void,
                      modifiers: val[2],
                      name: val[3].name,
                      arguments: val[5] || [],
                      statements: val[8]
                    )
                  }
  method_def : empty_or_annotations access_level empty_or_modifiers ident ident L_BRACE empty_or_arguments R_BRACE LC_BRACE stmts RC_BRACE
             {
               result = ApexDefMethodNode.new(
                 access_level: val[1],
                 return_type: val[3].name,
                 modifiers: val[2],
                 name: val[4].name,
                 arguments: val[6] || [],
                 statements: val[9]
               )
             }
  empty_or_arguments :
                     | arguments
  arguments : argument { result = [val[0]] }
            | arguments COMMA argument { result = val[0].push(val[2]) }
  argument : ident ident { result = ArgumentNode.new(type: val[0].name, name: val[1].name) }



  stmts : stmt { result = [val[0]] }
        | stmts stmt { result = val[0].push(val[1]) }
  stmt  : expr SEMICOLON
        | assigns SEMICOLON
        | return_stmt SEMICOLON
        | break_stmt SEMICOLON
        | continue_stmt SEMICOLON
        | variable_def SEMICOLON
        | boolean_expr SEMICOLON
        | if_stmt
        | for_stmt
        | while_stmt
        | comment
  comment : COMMENT { result = CommentNode.new(val[0]) }
          | REM_IN COMMENT REM_OUT { result = CommentNode.new(val[1]) }
  loop_stmt  : expr
             | assigns
             | variable_def
             | boolean_expr
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
  while_stmt : WHILE L_BRACE loop_stmt R_BRACE LC_BRACE stmts RC_BRACE
             { result = WhileNode.new(condition_stmt: val[2], statements: val[5]) }
  assigns : assign
          | ident ASSIGN assigns { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
          | instance_variable ASSIGN assigns { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
          | expr LS_BRACE expr RS_BRACE ASSIGN assigns
          { result = CallMethodNode.new(receiver: val[0], apex_method_name: :[]=, arguments: [val[2], val[5]]) }
  assign : ident ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
         | instance_variable ASSIGN expr { result = OperatorNode.new(type: :assign, left: val[0], right: val[2]) }
         | expr LS_BRACE expr RS_BRACE ASSIGN expr
         { result = CallMethodNode.new(receiver: val[0], apex_method_name: :[]=, arguments: [val[2], val[5]]) }
instance_variable : expr DOT ident { result = InstanceVariableNode.new(receiver: val[0], name: val[2].name) }
  expr  : number
        | new_expr
        | STRING { result = ApexStringNode.new(value(val, 0)) }
        | call_method
        | ident INSTANCE_OF ident
        | ident
        | expr LS_BRACE expr RS_BRACE
        { result = CallMethodNode.new(receiver: val[0], apex_method_name: :[], arguments: [val[2]]) }
        | instance_variable
        | boolean
        | NULL { result = NullNode.new }
        | unary_operator ident { result = OperatorNode.new(type: val[0], left: val[1])}
        | ident unary_operator { result = OperatorNode.new(type: val[1], left: val[0])}
        | LS_BRACE SELECT call_arguments FROM soql_options RS_BRACE
        { result = SoqlNode.new(soql: val[4]) }
soql_option : ident
            | INTEGER
            | STRING
            | ASSIGN
            | LESS_THAN
            | LESS_THAN_EQUAL
            | GREATER_THAN
            | GREATER_THAN_EQUAL
soql_options : soql_option
             | soql_options soql_option
new_expr : NEW ident L_BRACE empty_or_call_arguments R_BRACE
         {
           result = NewNode.new(apex_class_name: val[1].name, arguments: val[3])
         }
  number : term
         | number ADD term { result = OperatorNode.new(type: :add, left: val[0], right: val[2]) }
         | number SUB term { result = OperatorNode.new(type: :sub, left: val[0], right: val[2]) }
  term   : primary_expr
         | term MUL primary_expr { result = OperatorNode.new(type: :mul, left: val[0], right: val[2]) }
         | term DIV primary_expr { result = OperatorNode.new(type: :div, left: val[0], right: val[2]) }
  break_stmt : BREAK { result = BreakNode.new }
  continue_stmt : CONTINUE { result = ContinueNode.new }
  return_stmt : RETURN expr { result = ReturnNode.new(expression: val[1]) }
  primary_expr : INTEGER { result = ApexIntegerNode.new(value(val,0)) }
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
                  apex_method_name: val[2].name,
                  arguments: val[4]
                )
              }
  empty_or_call_arguments :
                          | call_arguments
  call_arguments : call_argument { result = [val[0]] }
                 | call_arguments COMMA call_argument { result = val[0].push(val[2]) }
  call_argument : expr
                | boolean_expr
  access_level : PUBLIC
               | PRIVATE
               | PROTECTED
empty_or_modifiers :
                   | modifiers
  modifiers : modifier { result = [value(val, 0)] }
            | modifiers modifier { result = val[0].push(val[1]) }
  modifier : ABSTRACT
           | FINAL
           | GLOBAL
           | STATIC
  sharing :
          | WITH SHARING { result = :with_sharing }
          | WITHOUT SHARING { result = :without_sharing }
  boolean : TRUE { result = BooleanNode.new(true) }
          | FALSE { result = BooleanNode.new(false) }
  boolean_expr: expr comparator expr { result = OperatorNode.new(type: value(val, 1), left: val[0], right: val[2])}
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
        | GET { result = IdentifyNode.new(name: 'get') }
        | SET { result = IdentifyNode.new(name: 'set') }
end

---- header

require 'apex_parser/apex_compiler.l'
require 'apex_parser/util/hash_with_upper_cased_symbolic_key'
require 'apex_parser/node/node'
require 'apex_parser/apex_class_creator'

Dir[File.expand_path('./runtime/**/*.rb', __dir__)].each do |f|
  require f
end

---- inner

def value(val, idx)
  val[idx][0]
end

def get_lineno(val, idx)
  val[idx][1]
end

---- footer

