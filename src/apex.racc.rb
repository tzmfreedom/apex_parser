class ApexParser::ApexCompiler

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV MOD ADD SUB DOUBLE
  CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING REM_IN REM_OUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCE_OF TRUE FALSE IF ELSE FOR WHILE COLON
  LESS_THAN LESS_THAN_EQUAL NOT_EQUAL EQUAL GREATER_THAN GREATER_THAN_EQUAL
  NULL CONTINUE BREAK SELECT FROM
  LS_BRACE RS_BRACE TRY CATCH INCR DECR
  LEFT_SHIFT RIGHT_SHIFT
  AND OR TILDE CONDITIONAL_AND CONDITIONAL_OR QUESTION

rule
  root_statements : class_or_trigger { result = [val[0]] }
                  | root_statements class_or_trigger { val[0].push(val[1]) }
  class_or_trigger : class_declaration
                   | trigger_declaration
                   | comment
  # Class Declaration

class_declaration : empty_or_modifiers CLASS IDENT empty_or_extends empty_or_implements LC_BRACE class_statements RC_BRACE
                  {
                    result = ApexClassNode.new(
                      modifiers: val[0],
                      name: value(val, 2),
                      statements: val[6],
                      apex_super_class: val[3],
                      implements: val[4],
                      lineno: get_lineno(val, 2)
                    )
                  }
  empty_or_extends :
                   | EXTENDS name { result = val[1] }
  empty_or_implements :
                      | IMPLEMENTS implements { result = val[1] }
  implements : name { result = [val[0]] }
             | implements COMMA name { result = val[0].push(val[1]) }
  class_statements : class_statement { result = [val[0]] }
                   | class_statements class_statement { result = val[0].push(val[1]) }
  class_statement : method_declaration
                  | constructor_declaration
                  | field_declaration
                  | comment

  field_declaration : empty_or_modifiers name field_declarators SEMICOLON
                    {
                      result = DefInstanceVariableNode.new(
                        modifiers: val[0],
                        type: value(val, 1),
                        name: val[2],
                        lineno: get_lineno(val, 1)
                      )
                    }
  field_declarators : field_declarator { result = [val[0]] }
                    | field_declarators COLON field_declarator { result = val[0].push(val[2]) }
  field_declarator : simple_name
                   | simple_name ASSIGN expression
                   | simple_name LC_BRACE getter_setter RC_BRACE
  getter_setter : getter setter
                | setter getter
  getter : GET SEMICOLON
  setter : SET SEMICOLON

constructor_declaration : empty_or_modifiers simple_name L_BRACE empty_or_parameters R_BRACE LC_BRACE statements RC_BRACE
                        {
                          result = ApexDefMethodNode.new(
                            modifiers: val[0],
                            return_type: :void,
                            name: value(val, 1),
                            arguments: val[3],
                            statements: val[6]
                          )
                        }
method_declaration : empty_or_modifiers name simple_name L_BRACE empty_or_parameters R_BRACE LC_BRACE statements RC_BRACE
                   {
                     result = ApexDefMethodNode.new(
                       modifiers: val[0],
                       return_type: value(val, 1),
                       name: value(val, 2),
                       arguments: val[4],
                       statements: val[7]
                     )
                   }
empty_or_parameters :
                     | parameters
  parameters: parameter { result = [val[0]] }
            | parameters COMMA parameter { result = val[0].push(val[2]) }
parameter : name simple_name { result = ArgumentNode.new(type: value(val, 0), name: value(val, 1)) }

empty_or_modifiers :
                   | modifiers
modifiers : modifier { result = [value(val, 0)] }
          | modifiers modifier { result = val[0].push(val[1]) }
modifier : ANNOTATION
         | ABSTRACT
         | FINAL
         | GLOBAL
         | STATIC
         | PUBLIC
         | PRIVATE
         | PROTECTED
         | WITH SHARING { result = :with_sharing }
         | WITHOUT SHARING { result = :without_sharing }

trigger_declaration : TRIGGER IDENT ON IDENT L_BRACE R_BRACE LC_BRACE statements RC_BRACE

  statements : statement { result = [val[0]] }
             | statements statement { result = val[0].push(val[1]) }
  statement : variable_declaration
            | if_statement
            | for_statement
            | return_statement
            | break_statement
            | continue_statement
            | while_statement
            | comment
            | try_statement
            | expression_statement

  expression_statement : statement_expression SEMICOLON
  statement_expression : assignment
                       | pre_increment_expression
                       | pre_decrement_expression
                       | post_increment_expression
                       | post_decrement_expression
                       | method_invocation
  try_statement : TRY statements CATCH L_BRACE R_BRACE LC_BRACE statements RC_BRACE

  array_access : name LS_BRACE expression RS_BRACE
               { result = VariableNode.new(name: value(val, 0), index: val[2]) }
               | primary_expression LS_BRACE expression RS_BRACE
  field_access : primary_expression DOT IDENT
empty_or_expression :
                    | expression
  expression : assignment_expression
assignment_expression  : conditional_expression
                       | assignment
                       | soql_expression
assignment : left_hand_side ASSIGN assignment_expression
           {
             result = OperatorNode.new(
               type: :assign,
               left: val[0],
               right: val[2]
             )
           }


  conditional_expression : conditional_or_expression
                         | conditional_or_expression QUESTION expression COLON conditional_expression
  conditional_or_expression : conditional_and_expression
                            | conditional_or_expression CONDITIONAL_OR conditional_and_expression

  conditional_and_expression : inclusive_expression
                             | conditional_and_expression CONDITIONAL_AND inclusive_expression

  inclusive_expression : exclusive_expression
                       | inclusive_expression OR exclusive_expression

  exclusive_expression : and_expression
                       | exclusive_expression TILDE and_expression

and_expression : equality_expression
               | and_expression AND equality_expression


equality_expression : relational_expression
                    | equality_expression EQUAL relational_expression
                    | equality_expression NOT_EQUAL relational_expression

relational_expression : shift_expression
                      | relational_expression LESS_THAN shift_expression
                      | relational_expression LESS_THAN_EQUAL shift_expression
                      | relational_expression GREATER_THAN shift_expression
                      | relational_expression GREATER_THAN_EQUAL shift_expression

shift_expression : additive_expression
                 | shift_expression LEFT_SHIFT additive_expression
                 | shift_expression RIGHT_SHIFT additive_expression
additive_expression : multiplicative_expression
                    | additive_expression ADD multiplicative_expression
                    | additive_expression SUB multiplicative_expression
                    | additive_expression MOD multiplicative_expression
multiplicative_expression : unary_expression
                          | multiplicative_expression MUL unary_expression
                          | multiplicative_expression DIV unary_expression

  unary_expression : pre_increment_expression
                   | pre_decrement_expression
                   | postfix_expression

  postfix_expression : post_increment_expression
                     | post_decrement_expression
                     | name
                     | primary_expression

pre_increment_expression : INCR unary_expression
pre_decrement_expression : DECR unary_expression
post_increment_expression : postfix_expression INCR
post_decrement_expression : postfix_expression DECR

  primary_expression : method_invocation
                     | array_access
                     | L_BRACE expression R_BRACE
                     | literal
                     | field_access
                     | new_expression
                     | NULL

  literal : string_expression
          | boolean
          | primary_number

  left_hand_side : name
                 | array_access
  string_expression : STRING
  primary_number : INTEGER { result = ApexIntegerNode.new(value: value(val, 0), lineno: get_lineno(val, 0)) }
                 | DOUBLE

  variable_declaration : name variable_declarators SEMICOLON
                       {
                         result = OperatorNode.new(
                           type: :define,
                           left: val[0],
                           right: val[1]
                         )
                       }
  variable_declarators : variable_declarator
                       | variable_declarators COMMA variable_declarator
  variable_declarator : name
                      | name ASSIGN expression
                      {
                        result = OperatorNode.new(
                          type: :assign,
                          left: val[0],
                          right: val[2]
                        )
                      }
  method_invocation : name L_BRACE empty_or_arguments R_BRACE
                     {
                       result = MethodInvocationNode.new(
                         name: val[0][0],
                         arguments: val[2],
                         lineno: get_lineno(val, 0)
                       )
                     }
                    | primary_expression DOT IDENT L_BRACE empty_or_arguments R_BRACE
                    {
                      result = MethodInvocationNode.new(
                        expression: val[0],
                        arguments: val[2],
                        lineno: get_lineno(val, 1)
                      )
                    }
  empty_or_arguments :
                     | arguments
  arguments : expression { result = [val[0]] }
            | arguments COMMA expression { result = val[0].push(val[2]) }

  name : simple_name
       | qualified_name
  simple_name: IDENT { result = [[value(val, 0)], get_lineno(val, 0)] }
  qualified_name : name DOT IDENT { result = [val[0][0].push(value(val, 2)), get_lineno(val, 1)] }


  boolean : TRUE { result = BooleanNode.new(true) }
          | FALSE { result = BooleanNode.new(false) }

  soql_expression : LS_BRACE SELECT soql_terms FROM soql_terms RS_BRACE
                   {
                     result = SoqlNode.new(soql: val[4])
                   }
  new_expression : NEW name L_BRACE empty_or_arguments R_BRACE
                 {
                   result = NewNode.new(apex_class_name: value(val, 1), arguments: val[3])
                 }
  if_statement : IF L_BRACE expression R_BRACE LC_BRACE statements RC_BRACE else_statement_or_empty
               {
                 result = IfNode.new(condition: val[2], if_stmt: val[5], else_stmt: val[7])
               }
  else_statement_or_empty :
                          | else_statements
  else_statements : ELSE LC_BRACE statements RC_BRACE { result = val[2] }
                 | ELSE statement { result = [val[1]] }
  for_statement : FOR L_BRACE empty_or_variable_declarators SEMICOLON empty_or_expression SEMICOLON empty_or_expression R_BRACE LC_BRACE statements RC_BRACE
                  { result = ForNode.new(init_statement: val[2], exit_condition: val[4], increment_statement: val[6], statements: val[9]) }
                  | FOR L_BRACE name simple_name COLON name R_BRACE LC_BRACE statements RC_BRACE
                  { result = ForEnumNode.new(type: val[2], ident: val[3], list: val[5], statements: val[8]) }
  empty_or_variable_declarators :
                                | name variable_declarators
  while_statement : WHILE L_BRACE expression R_BRACE LC_BRACE statements RC_BRACE
                  { result = WhileNode.new(condition_statement: val[2], statements: val[5]) }

  soql_term : name
            | INTEGER
            | STRING
            | ASSIGN
            | LESS_THAN
            | LESS_THAN_EQUAL
            | GREATER_THAN
            | GREATER_THAN_EQUAL
  soql_terms : soql_term
             | soql_terms soql_term

  break_statement : BREAK SEMICOLON { result = BreakNode.new }
  continue_statement : CONTINUE SEMICOLON { result = ContinueNode.new }
  return_statement : RETURN expression SEMICOLON { result = ReturnNode.new(expression: val[1]) }

  comment : COMMENT { result = CommentNode.new(val[0]) }
          | REM_IN COMMENT REM_OUT { result = CommentNode.new(val[1]) }
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

