class ApexParser::ApexCompiler

token INTEGER IDENT ASSIGN SEMICOLON MUL DIV MOD ADD SUB DOUBLE
  CLASS PUBLIC PRIVATE PROTECTED GLOBAL LC_BRACE RC_BRACE L_BRACE R_BRACE COMMA
  RETURN DOT STRING REM_IN REM_OUT COMMENT ANNOTATION INSERT DELETE
  UNDELETE UPDATE UPSERT BEFORE AFTER TRIGGER ON WITH WITHOUT SHARING
  OVERRIDE STATIC FINAL NEW GET SET EXTENDS IMPLEMENTS ABSTRACT VIRTUAL
  INSTANCEOF TRUE FALSE IF ELSE FOR WHILE COLON
  LESS_THAN LESS_THAN_EQUAL NOT_EQUAL EQUAL GREATER_THAN GREATER_THAN_EQUAL
  NULL CONTINUE BREAK SELECT FROM
  LS_BRACE RS_BRACE TRY CATCH INCR DECR
  # LEFT_SHIFT RIGHT_SHIFT
  AND OR TILDE CONDITIONAL_AND CONDITIONAL_OR QUESTION SWITCH WHEN TEST_METHOD
  EXCLAMATION ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
  SOQL_TERM ARROW

rule
  root_statements : class_or_trigger { result = [val[0]] }
                  | root_statements class_or_trigger { val[0].push(val[1]) }
  class_or_trigger : class_declaration
                   | trigger_declaration
  # Class Declaration

class_declaration : empty_or_modifiers CLASS IDENT empty_or_extends empty_or_implements LC_BRACE empty_or_class_statements RC_BRACE
                  {
                    result = ApexClassInitializer.create(
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
empty_or_class_statements :
                          | class_statements
  class_statements : class_statement { result = [val[0]] }
                   | class_statements class_statement { result = val[0].push(val[1]) }
  class_statement : method_declaration
                  | constructor_declaration
                  | field_declaration
                  | class_declaration

  field_declaration : empty_or_modifiers type field_declarators SEMICOLON
                    {
                      result = AST::FieldDeclarationNode.new(
                        modifiers: val[0],
                        type: val[1],
                        statements: val[2],
                        lineno: val[1].lineno
                      )
                    }
                    | empty_or_modifiers type simple_name LC_BRACE getter_setter RC_BRACE
  field_declarators : field_declarator { result = [val[0]] }
                    | field_declarators COLON field_declarator { result = val[0].push(val[2]) }
  field_declarator : simple_name { result = AST::FieldDeclarator.new(name: val[0].to_s, expression: AST::NullNode.new) }
                   | simple_name ASSIGN expression { result= AST::FieldDeclarator.new(name: val[0].to_s, expression: val[2]) }
                   | simple_name LC_BRACE getter_setter RC_BRACE
                   { result = AST::FieldDeclarator.new(name: val[0].to_s, expression: val[2]) }
  getter_setter : getter setter
                | setter getter
  getter : empty_or_modifiers GET SEMICOLON
  setter : empty_or_modifiers SET SEMICOLON

constructor_declaration : empty_or_modifiers simple_name L_BRACE empty_or_parameters R_BRACE LC_BRACE empty_or_statements RC_BRACE
                        {
                          result = AST::ConstructorDeclarationNode.new(
                            modifiers: val[0],
                            return_type: AST::Type.new(name: :void),
                            name: val[1].to_s,
                            arguments: val[3],
                            statements: val[6],
                            lineno: val[1].lineno
                          )
                        }
method_declaration : empty_or_modifiers type simple_name L_BRACE empty_or_parameters R_BRACE LC_BRACE statements RC_BRACE
                   {
                     result = AST::MethodDeclarationNode.new(
                       modifiers: val[0],
                       return_type: val[1],
                       name: val[2].to_s,
                       arguments: val[4],
                       statements: val[7],
                       lineno: val[1].lineno
                     )
                   }
empty_or_parameters :
                     | parameters
  parameters: parameter { result = [val[0]] }
            | parameters COMMA parameter { result = val[0].push(val[2]) }
parameter : type simple_name { result = AST::ArgumentNode.new(type: val[0], name: val[1].to_s) }

empty_or_modifiers :
                   | modifiers
modifiers : modifier { result = [value(val, 0)] }
          | modifiers modifier { result = val[0].push(value(val,1)) }
modifier : ANNOTATION
         | ABSTRACT
         | FINAL
         | GLOBAL
         | STATIC
         | PUBLIC
         | PRIVATE
         | PROTECTED
         | TEST_METHOD
         | WITH SHARING { result = ['with_sharing', get_lineno(val, 0)] }
         | WITHOUT SHARING { result = ['without_sharing', get_lineno(val, 0)] }

trigger_declaration : TRIGGER IDENT ON IDENT L_BRACE before_after_arguments R_BRACE LC_BRACE statements RC_BRACE
                     {
                       result = AST::Trigger.new(
                         name: value(val, 1),
                         object: value(val, 3),
                         arguments: val[5],
                         statements: val[8]
                       )
                     }
  before_after_arguments : before_after_argument { result = [val[0]] }
                         | before_after_arguments COMMA before_after_argument { result = val[0].push(val[2]) }
  before_after_argument : BEFORE dml { result = AST::TriggerTiming.new(timing: :before, dml: value(val, 1)) }
                        | AFTER dml { result = AST::TriggerTiming.new(timing: :after, dml: value(val, 1)) }
  dml : INSERT
      | UPDATE
      | UPSERT
      | DELETE
      | UNDELETE
empty_or_statements :
                    | statements
  statements : statement { result = [val[0]] }
             | statements statement { result = val[0].push(val[1]) }
  statement : variable_declaration
            | if_statement
            | switch_statement
            | for_statement
            | return_statement
            | break_statement
            | continue_statement
            | while_statement
            | try_statement
            | expression_statement
            | dml_statement

  expression_statement : statement_expression SEMICOLON
  statement_expression : assignment
                       | field_access # 不要かも
                       | pre_increment_expression
                       | pre_decrement_expression
                       | post_increment_expression
                       | post_decrement_expression
                       | method_invocation
                       | new_expression
  try_statement : TRY statements CATCH L_BRACE R_BRACE LC_BRACE statements RC_BRACE

  array_access : name LS_BRACE expression RS_BRACE
               { result = AST::ArrayAccess.new(receiver: val[0], key: val[2]) }
               | primary_expression LS_BRACE expression RS_BRACE
               { result = AST::ArrayAccess.new(receiver: val[0], key: val[2]) }
  field_access : primary_expression DOT simple_name { result = val }
empty_or_expression :
                    | expression
  expression : assignment_expression
             | instanceof_expression
  instanceof_expression : name INSTANCEOF name
assignment_expression  : conditional_expression
                       | assignment
                       | soql_expression
assignment : left_hand_side assignment_operator assignment_expression
           {
             result = AST::OperatorNode.new(
               type: :assign,
               left: val[0],
               right: val[2]
             )
           }
  assignment_operator : ASSIGN
                      | ADD_ASSIGN
                      | SUB_ASSIGN
                      | MUL_ASSIGN
                      | DIV_ASSIGN

  conditional_expression : conditional_or_expression
                         | conditional_or_expression QUESTION expression COLON conditional_expression { result = AST::OperatorNode.new(type: :'?', left: val[0], right: val[2]) }
  conditional_or_expression : conditional_and_expression
                            | conditional_or_expression CONDITIONAL_OR conditional_and_expression { result = AST::OperatorNode.new(type: :'||', left: val[0], right: val[2]) }

  conditional_and_expression : inclusive_expression
                             | conditional_and_expression CONDITIONAL_AND inclusive_expression { result = AST::OperatorNode.new(type: :'&&', left: val[0], right: val[2]) }

  inclusive_expression : exclusive_expression
                       | inclusive_expression OR exclusive_expression { result = AST::OperatorNode.new(type: :|, left: val[0], right: val[2]) }

  exclusive_expression : and_expression
                       | exclusive_expression TILDE and_expression { result = AST::OperatorNode.new(type: :~, left: val[0], right: val[2]) }

and_expression : equality_expression
               | and_expression AND equality_expression { result = AST::OperatorNode.new(type: :&, left: val[0], right: val[2]) }


equality_expression : relational_expression
                    | equality_expression EQUAL relational_expression { result = AST::OperatorNode.new(type: :==, left: val[0], right: val[2]) }
                    | equality_expression NOT_EQUAL relational_expression { result = AST::OperatorNode.new(type: :!=, left: val[0], right: val[2]) }

relational_expression : shift_expression
                      | relational_expression LESS_THAN shift_expression { result = AST::OperatorNode.new(type: :<, left: val[0], right: val[2]) }
                      | relational_expression LESS_THAN_EQUAL shift_expression { result = AST::OperatorNode.new(type: :<=, left: val[0], right: val[2]) }
                      | relational_expression GREATER_THAN shift_expression { result = AST::OperatorNode.new(type: :>, left: val[0], right: val[2]) }
                      | relational_expression GREATER_THAN_EQUAL shift_expression { result = AST::OperatorNode.new(type: :>=, left: val[0], right: val[2]) }

shift_expression : additive_expression
#                 | shift_expression LEFT_SHIFT additive_expression { result = AST::OperatorNode.new(type: :<<, left: val[0], right: val[2]) }
#                 | shift_expression RIGHT_SHIFT additive_expression { result = AST::OperatorNode.new(type: :>>, left: val[0], right: val[2]) }
additive_expression : multiplicative_expression
                    | additive_expression ADD multiplicative_expression { result = AST::OperatorNode.new(type: :+, left: val[0], right: val[2]) }
                    | additive_expression SUB multiplicative_expression { result = AST::OperatorNode.new(type: :-, left: val[0], right: val[2]) }
multiplicative_expression : unary_expression
                          | multiplicative_expression MUL unary_expression { result = AST::OperatorNode.new(type: :*, left: val[0], right: val[2]) }
                          | multiplicative_expression DIV unary_expression { result = AST::OperatorNode.new(type: :'/', left: val[0], right: val[2]) }
                          | multiplicative_expression MOD unary_expression { result = AST::OperatorNode.new(type: :%, left: val[0], right: val[2]) }

  unary_expression : pre_increment_expression
                   | pre_decrement_expression
                   | postfix_expression
                   | ADD unary_expression
                   | SUB unary_expression
                   | EXCLAMATION unary_expression
                   | TILDE unary_expression

  postfix_expression : post_increment_expression
                     | post_decrement_expression
                     | name
                     | primary_expression

pre_increment_expression : INCR unary_expression { result = AST::OperatorNode.new(type: :pre_increment, left: val[0]) }
pre_decrement_expression : DECR unary_expression { result = AST::OperatorNode.new(type: :pre_decrement, left: val[0]) }
post_increment_expression : postfix_expression INCR { result = AST::OperatorNode.new(type: :post_increment, left: val[0]) }
post_decrement_expression : postfix_expression DECR { result = AST::OperatorNode.new(type: :post_decrement, left: val[0]) }

  primary_expression : method_invocation
                     | array_access
                     | L_BRACE expression R_BRACE { result = val[1] }
                     | literal
                     | field_access
                     | new_expression
                     | NULL { result = AST::NullNode.new }

  literal : string_expression
          | boolean
          | primary_number

  left_hand_side : name
                 | array_access
                 | field_access
  string_expression : STRING { result = AST::ApexStringNode.new(value: value(val, 0), lineno: get_lineno(val, 0)) }
  primary_number : INTEGER { result = AST::ApexIntegerNode.new(value: value(val, 0), lineno: get_lineno(val, 0)) }
                 | DOUBLE { result = AST::ApexDoubleNode.new(value: val(val, 0), lineno: get_lineno(val, 0)) }

  variable_declaration : type variable_declarators SEMICOLON
                       {
                         result = AST::OperatorNode.new(
                           type: :declaration,
                           left: val[0],
                           right: val[1]
                         )
                       }
  variable_declarators : variable_declarator { result = [val[0]] }
                       | variable_declarators COMMA variable_declarator { result = val[0].push(val[2]) }
  variable_declarator : name
                       {
                         result = AST::VariableDeclaratorNode.new(
                           left: val[0],
                           right: AST::NullNode.new,
                           lineno: val[0].lineno
                         )
                       }
                      | name ASSIGN expression
                      {
                        result = AST::VariableDeclaratorNode.new(
                          left: val[0],
                          right: val[2],
                          lineno: val[0].lineno
                        )
                      }
  method_invocation : name L_BRACE empty_or_arguments R_BRACE
                     {
                       result = AST::MethodInvocationNode.new(
                         receiver: val[0],
                         apex_method_name: val[0].value.pop,
                         arguments: val[2],
                         lineno: val[0].lineno
                       )
                     }
                    | primary_expression DOT IDENT L_BRACE empty_or_arguments R_BRACE
                    {
                      result = AST::MethodInvocationNode.new(
                        receiver: val[0],
                        apex_method_name: value(val, 2),
                        arguments: val[4],
                        lineno: get_lineno(val, 1)
                      )
                    }
  empty_or_arguments :
                     | arguments
  arguments : expression { result = [val[0]] }
            | arguments COMMA expression { result = val[0].push(val[2]) }
  type : reference_type
       | name LS_BRACE RS_BRACE
reference_type : name { result = AST::Type.new(name: val[0].to_s) }
               | generics_type
  generics_type : name generics { result = AST::Type.new(name: val[0].name, generics_arguments: val[1]) }
  types : type { result = [val[0]] }
        | types COMMA type { result = val[0].push(val[2]) }
  generics : LESS_THAN types GREATER_THAN { result = val[1] }
  name : simple_name
       | qualified_name
  simple_name: IDENT { result = AST::NameNode.new(value: [value(val, 0)], lineno: get_lineno(val, 0)) }
  qualified_name : name DOT IDENT { val[0].value.push(value(val, 2)) }


  boolean : TRUE { result = AST::BooleanNode.new(true) }
          | FALSE { result = AST::BooleanNode.new(false) }

  soql_expression : LS_BRACE soql_terms RS_BRACE
                   {
                     result = AST::SoqlNode.new(soql: val[0])
                   }
  new_expression : NEW type initializer_statemenet
                 {
                   result = AST::NewNode.new(type: val[1], arguments: val[3])
                 }
  initializer_statemenet : L_BRACE empty_or_arguments R_BRACE { result = val[1] }
                         | LC_BRACE initializers RC_BRACE { result = val[1] }

  initializers : initializer { result = [val[0]] }
               | initializers COMMA initializer { result = val[0].push(val[2]) }
  initializer : assignment
              | STRING ARROW expression
  if_statement : IF L_BRACE expression R_BRACE LC_BRACE statements RC_BRACE else_statement_or_empty
               {
                 result = AST::IfNode.new(condition: val[2], if_stmt: val[5], else_stmt: val[7])
               }
  else_statement_or_empty :
                          | else_statements
  else_statements : ELSE LC_BRACE statements RC_BRACE { result = val[2] }
                 | ELSE statement { result = [val[1]] }
  switch_statement : SWITCH ON expression LC_BRACE when_statements RC_BRACE
                   { result = AST::Switch.new(expression: val[2], statements: val[4]) }
  when_statements : when_statement { result = [val[0]] }
                  | when_statements when_statement { result = val[0].push(val[1]) }
  when_statement : WHEN when_argument LC_BRACE statements RC_BRACE
                  { result = AST::When.new(condition: val[1], statements: val[3]) }
  when_argument : ELSE { result = :else }
                | name simple_name
                | when_literals
  when_literals : literal { result = [val[0]] }
                | when_literals COMMA literal { result = val[0].push(val[2]) }
  for_statement : FOR L_BRACE empty_or_variable_declaration SEMICOLON empty_or_expression SEMICOLON empty_or_expression R_BRACE LC_BRACE statements RC_BRACE
                  { result = AST::ForNode.new(init_statement: val[2], exit_condition: val[4], increment_statement: val[6], statements: val[9]) }
                  | FOR L_BRACE type simple_name COLON expression R_BRACE LC_BRACE statements RC_BRACE
                  { result = AST::ForEnumNode.new(type: val[2], ident: val[3], expression: val[5], statements: val[8]) }
  empty_or_variable_declaration :
                                | type variable_declarators
                                 {
                                   result = AST::OperatorNode.new(
                                     type: :declaration,
                                     left: val[0],
                                     right: val[1]
                                   )
                                 }
  while_statement : WHILE L_BRACE expression R_BRACE LC_BRACE statements RC_BRACE
                  { result = AST::WhileNode.new(condition_statement: val[2], statements: val[5]) }

  soql_terms : SOQL_TERM
             | soql_terms SOQL_TERM

  break_statement : BREAK SEMICOLON { result = AST::BreakNode.new }
  continue_statement : CONTINUE SEMICOLON { result = AST::ContinueNode.new }
  return_statement : RETURN SEMICOLON { result = AST::ReturnNode.new(expression: AST::NullNode.new) }
                   | RETURN expression SEMICOLON { result = AST::ReturnNode.new(expression: val[1]) }
  dml_statement : dml expression SEMICOLON { result = AST::DML.new(dml: value(val, 0), object: val[1]) }
end

---- header

require 'apex_parser/apex_compiler.l'
require 'apex_parser/util/hash_with_upper_cased_symbolic_key'
require 'apex_parser/visitor/interpreter/apex_class_initializer'
require 'apex_parser/ast/node/node'

Dir[File.expand_path('./ast/node/**/*.rb', __dir__)].each do |f|
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

