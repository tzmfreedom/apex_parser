require 'apex_parser/visitor/interpreter/local_environment'
require 'apex_parser/visitor/interpreter/data_loader'

require 'apex_parser/visitor/interpreter/apex_class_table'
require 'apex_parser/visitor/interpreter/apex_class_creator'
Dir[File.expand_path('./runtime/**/*.rb', __dir__)].each do |f|
  require f
end

module ApexParser
  module Visitor
    class TypeChecker
      def initialize
        push_scope({})
      end

      def visit_return(node)
        value = node.expression.accept(self)
        node.value = value
        node
      end

      def visit_if(node)
        node.condition.accept(self)

        unless node.condition.is_a?(AST::BooleanNode)
          STDERR.puts "line #{node.lineno}: condition statement should be boolean expression"
        end

        node.if_stmt.each do |statement|
          statement.accept(self)
        end

        node.else_stmt.each do |statement|
          statement.accept(self)
        end
      end

      def visit_operator(node)
        case node.type.to_sym
        when :assign
          if node.left.is_a?(AST::NameNode)
            type = current_scope[node.left.to_s]
            if type != node.right.accept(self).type
              STDERR.puts "line #{node.lineno}: expression must be #{type}"
            end
          else
            STDERR.puts 'node must be AST::NameNode'
          end
        when :declaration
          variable_type = node.left.to_s
          node.right.each do |statement|
            current_scope[statement.left.to_s] = variable_type
          end
        when :+
          AST::ApexIntegerNode
        when :-
          AST::ApexIntegerNode
        when :/
          AST::ApexIntegerNode
        when :*
          AST::ApexIntegerNode
        when :%
          AST::ApexIntegerNode
        when :<<
          AST::ApexIntegerNode
        when :'<<<'
          AST::ApexIntegerNode
        when :>>
          AST::ApexIntegerNode
        when :'>>>'
          AST::ApexIntegerNode
        when :&
          AST::ApexIntegerNode
        when :|
          AST::ApexIntegerNode
        when :^
          AST::ApexIntegerNode
        when :'&&'
          AST::BooleanNode
        when :'||'
          AST::BooleanNode
        when :!=
          AST::BooleanNode
        when :'!=='
          AST::BooleanNode
        when :==
          AST::BooleanNode
        when :===
          AST::BooleanNode
        when :<=
          AST::BooleanNode
        when :>=
          AST::BooleanNode
        when :<
          AST::BooleanNode
        when :>
          AST::BooleanNode
        when :pre_increment
        when :pre_decrement
        when :post_increment
        when :post_decrement
          AST::ApexIntegerNode
        else
          STDERR.puts 'No Operation Error'
        end
      end

      def visit_for(node)
        push_scope({})
        node.init_statement.accept(self)
        node.exit_condition.accept(self)
        node.increment_statement.accept(self)
        execute_statements(node.statements)
        pop_scope
      end

      def visit_while(node)
        push_scope({})
        node.condition_statement.accept(self)
        execute_statements(node.statements)
        pop_scope
      end

      def visit_forenum(node)
        push_scope({})
        list_node = current_scope[node.list.name]
        next_method = search_instance_method(list_node.apex_class_node, :next)
        has_next_method= search_instance_method(list_node.apex_class_node, :has_next)

        env = HashWithUpperCasedSymbolicKey.new({ this: list_node })
        push_scope(env, nil)
        execute_statement(has_next_method)
        pop_scope

        env = HashWithUpperCasedSymbolicKey.new({ this: list_node })
        push_scope(env, nil)
        next_return_value = execute_statement(next_method)
        current_scope[node.ident.name] = next_return_value
        execute_statement(node, false)
        pop_scope

        pop_scope
      end

      def search_instance_method(apex_class_node, method_name)
        class_node = apex_class_node
        while class_node
          method_node = class_node.instance_methods[method_name]
          return method_node if method_node

          class_node = class_node.apex_super_class.accept(self)
        end

        # TODO: Error Handling
        puts 'ERROR : NO METHOD ERROR'
        nil
      end

      def search_static_method(apex_class_node, method_name)
        class_node = apex_class_node
        while class_node
          method_node = class_node.static_methods[method_name]
          return method_node if method_node

          break unless class_node.apex_super_class
          class_node = class_node.apex_super_class.accept(self)
        end

        # TODO: Error Handling
        puts 'ERROR : NO METHOD ERROR'
        nil
      end

      def visit_class(node)
        ApexClassTable.register(node.name, node)
      end

      def visit_new(node)
        apex_class_node, generics_node = parse_type(node.apex_class_name.to_s)
        object_node = AST::ObjectNode.new(apex_class_node: apex_class_node, arguments: node.arguments)
        object_node.generics_node = generics_node
        # assign instance variables
        object_node.instance_fields = HashWithUpperCasedSymbolicKey.new(apex_class_node.instance_fields.map do |variable_name, variable_node|
          [variable_name, variable_node.accept(self)]
        end.to_h)

        # constructor
        instance_method_node = apex_class_node.instance_fields[apex_class_node.name]
        return object_node unless instance_method_node

        # check constructor argument
        env = check_argument(instance_method_node, node.arguments)
        return unless env

        # execute constructor argument
        env[:this] = object_node
        push_scope(env)
        execute_statement(instance_method_node, false)
        pop_scope
        object_node
      end

      def parse_type(apex_class_name)
        class_name, generics_type =
          if m = /([a-zA-Z0-9]+)\<([a-zA-Z0-9]+)\>/.match(apex_class_name)
            [m[1], m[2]]
          elsif m = /([a-zA-Z0-9]+)\[\]/.match(apex_class_name)
            [:Array, m[1]]
          else
            [apex_class_name, nil]
          end
        [ApexClassTable[class_name][:_top], generics_type ? ApexClassTable[generics_type][:_top] : nil]
      end

      def visit_def_instance_method(node)
      end

      def visit_def_instance_variable(node)
        class_node = node.apex_class_node
        expression = class_node.instance_fields[node.name].expression
        return unless expression
        expression.accept(self)
      end

      def visit_instance_variable(node)
        receiver = current_scope[node.receiver.name]
        receiver.instance_fields[node.name]
      end

      def visit_method_invocation(node)
        receiver_node, method_node = receiver_from_name(node)
        unless receiver_node && method_node
          puts "No Method Error!!"
          return nil
        end
        env = check_argument(method_node, node.arguments)
        return unless env

        unless method_node.static?
          env[:this] = receiver_node
        end
        push_scope(env)
        result = execute_statement(method_node)
        pop_scope
        result
      end

      def execute_statements(statements)
        statements.each do |statement|
          return_value = statement.accept(self)
          # TODO: return_value.value
          if [AST::ReturnNode, AST::ContinueNode, AST::BreakNode].include?(return_value.class)
            return return_value.value
          end
        end
        nil
      end

      def execute_statement(method_node, must_return = true)
        if method_node.respond_to?(:native?) && method_node.native?
          method_node.call_proc.call(current_scope)
        else
          method_node.statements.each do |statement|
            return_value = statement.accept(self)
            # TODO: return_value.value
            if [AST::ReturnNode, AST::ContinueNode, AST::BreakNode].include?(return_value.class)
              return return_value.value
            end
          end

          if method_node.return_type.to_s != 'void' && must_return
            # TODO: no return error
            puts 'NO RETURN ERROR'
          end
          nil
        end
      end

      def visit_annotation(node)
        node
      end

      def visit_soql(node)
        @data_loader ||= ApexParser::DataLoader.new
        records = @data_loader.call(:account)
        list_node = AST::NewNode.new(apex_class_name: :'List<Account>', arguments: [])
          .accept(self)
        list_node.instance_fields[:records] = records
        list_node
      end

      def check_argument(method, arguments)
        evaluated_arguments = arguments.map { |argument|
          argument.accept(self)
        }
        # Check Argument
        if evaluated_arguments.size !=  method.arguments.size
          # TODO: Error Handling
          puts "Argument Length Error!! #{evaluated_arguments.size} != #{method.arguments.size}"
          return
        end

        env = HashWithUpperCasedSymbolicKey.new
        evaluated_arguments.each_with_index do |evaluated_argument, idx|
          if method.arguments[idx].type != AnyObject && evaluated_argument.class != method.arguments[idx].type
            binding.pry
            # TODO: Error Handling
            puts "Argument Type Error!! #{evaluated_argument.class} != #{method.arguments[idx].type}"
            return
          end
          variable_name = method.arguments[idx].name
          env[variable_name] = evaluated_argument
        end
        env
      end

      def visit_null(node)
        node
      end

      def visit_boolean(node)
        node
      end

      def visit_string(node)
        node
      end

      def visit_integer(node)
        node
      end

      def visit_double(node)
        node
      end

      def visit_name(node)
        current_scope[node.to_s]
      end

      def field_from_name(node)
        names = node.value
        name = names.first

        # variable.field...field
        variable = current_scope[name]
        receiver = names[1..-1].reduce(variable) do |receiver, name|
          break nil if receiver.nil?
          receiver.fields[name]
        end
        return receiver unless receiver.nil?

        # this_field.field...field
        field = current_scope[:this].fields[name]
        receiver = names[1..-1].reduce(field) do |receiver, name|
          break nil if receiver.nil?
          receiver.fields[name]
        end
        return receiver unless receiver.nil?

        # class.static_field...field
        if names.length > 1
          apex_class = ApexClassTable[name]
          static_method_name = names[1]
          static_method = apex_class.static_fields[static_method_name]
          receiver = names[1..-1].reduce(static_method) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end
          return receiver unless receiver.nil?
        end

        # name_space.class.static_field...field
        if names.length > 2
          namespace = NameSpaceTable[name]
          apex_class_name = names[1]
          apex_class = namespace[apex_class_name]
          static_method = names[2]
          receiver = names[2..-1].reduce(apex_class[static_method]) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end
          return receiver unless receiver.nil?
        end
      end

      def receiver_from_name(node)
        return node.receiver.accept(self) unless node.receiver.is_a?(AST::NameNode)

        names = node.receiver.value
        name = names.first
        method_name = node.apex_method_name

        # variable.field.field...method()
        if current_scope.include?(name)
          variable = current_scope[name]
          receiver = names[1..-1].reduce(variable) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end

          method_node = receiver.apex_class_node.instance_methods[method_name]
          return [receiver, method_node] if receiver && method_node
        end

        # this_field.field.field...method()
        if current_scope.include?(:this)
          field = current_scope[:this].instance_fields[name]
          if field
            receiver = names[1..-1].reduce(field) do |receiver, name|
              break nil if receiver.nil?
              receiver.instance_fields[name]
            end

            method_node = receiver.instance_methods[method_name]
            return [receiver, method_node] if receiver && method_node
          end
        end

        # class.static_method()
        if names.length == 1
          class_info = ApexClassTable[name]
          if class_info
            apex_class = class_info[:_top]
            method_node = apex_class.static_methods[method_name]
            return [apex_class, method_node] unless method_node.nil?
          end
        end

        # class.static_field.field...method()
        if names.length >= 2
          class_info = ApexClassTable[name]
          if class_info
            apex_class = class_info[:_top]
            static_method = names[1]
            static_field = apex_class.static_fields[static_method]
            receiver = names[2..-1].reduce(static_field) do |receiver, name|
              break nil if receiver.nil?
              receiver.fields[name]
            end
            unless receiver.nil? && apex_class.instance_methods[method_name]
              return receiver
            end
          end
        end

        # namespace.class.static_field.field....method()
        if names.length >= 2
          namespace = NameSpaceTable[name]
          class_name = names[1]
          apex_class = namespace.classes[class_name]
          static_method_name = apex_class[names[2]]
          receiver = names[2..-1].reduce(static_method_name) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end
          unless receiver.nil? && apex_class.instance_methods[method_name]
            return receiver
          end
        end
      end

      def visit_object(node)
        node
      end

      def current_scope
        @current_scope
      end

      def push_scope(env, parent = @current_scope)
        scope = LocalEnvironment.new(env, parent)
        @current_scope = scope
      end

      def pop_scope
        @current_scope = current_scope.parent
      end
    end
  end
end
