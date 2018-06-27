require 'apex_parser/visitor/interpreter/local_environment'
require 'apex_parser/visitor/interpreter/data_loader'

require 'apex_parser/visitor/interpreter/apex_class_table'
require 'apex_parser/visitor/interpreter/trigger_table'
require 'apex_parser/visitor/interpreter/apex_class_creator'
Dir[File.expand_path('./runtime/**/*.rb', __dir__)].each do |f|
  require f
end

module ApexParser
  module Visitor
    class Interpreter
      NULL = Object.new

      def initialize
        @environment_stack = []
        push_scope({})
      end

      def visit_return(node)
        value = node.expression.accept(self)
        node.value = value
        node
      end

      def visit_if(node)
        condition_node = node.condition.accept(self)
        if condition_node.value == true
          node.if_stmt.each do |statement|
            statement.accept(self)
          end
        else
          return unless node.else_stmt
          node.else_stmt.each do |statement|
            statement.accept(self)
          end
        end
      end

      def visit_operator(node)
        case node.type.to_sym
        when :assign
          if node.left.is_a?(AST::NameNode)
            receiver_or_name, field_name = field_from_name(node.left)
            if field_name
              receiver_or_name.instance_fields[field_name] = node.right.accept(self)
            else
              current_scope[receiver_or_name] = node.right.accept(self)
            end
          elsif node.left.is_a?(AST::ArrayAccess)
            receiver_node = node.left.receiver.accept(self)
            key = node.left.key.accept(self)
            receiver_node.instance_fields[:_records][key.value] = node.right.accept(self)
          else
            STDERR.puts 'Assign Error'
          end
        when :declaration
          variable_type = node.left.to_s
          node.right.each do |statement|
            current_scope[statement.left.to_s] = statement.right.accept(self)
          end
        when :+
          AST::ApexIntegerNode.new(value: node.left.accept(self).value + node.right.accept(self).value)
        when :-
          AST::ApexIntegerNode.new(value: node.left.accept(self).value - node.right.accept(self).value)
        when :/
          AST::ApexIntegerNode.new(value: node.left.accept(self).value / node.right.accept(self).value)
        when :*
          AST::ApexIntegerNode.new(value: node.left.accept(self).value * node.right.accept(self).value)
        when :%
          AST::ApexIntegerNode.new(value: node.left.accept(self).value % node.right.accept(self).value)
        when :<<
          AST::ApexIntegerNode.new(value: node.left.accept(self).value << node.right.accept(self).value)
        when :'<<<'
          AST::ApexIntegerNode.new(value: node.left.accept(self).value << node.right.accept(self).value)
        when :>>
          AST::ApexIntegerNode.new(value: node.left.accept(self).value >> node.right.accept(self).value)
        when :'>>>'
          AST::ApexIntegerNode.new(value: node.left.accept(self).value >> node.right.accept(self).value)
        when :&
          AST::ApexIntegerNode.new(value: node.left.accept(self).value && node.right.accept(self).value)
        when :|
          AST::ApexIntegerNode.new(value: node.left.accept(self).value | node.right.accept(self).value)
        when :^
          AST::ApexIntegerNode.new(value: node.left.accept(self).value ^ node.right.accept(self).value)
        when :'&&'
          AST::BooleanNode.new(node.left.accept(self).value && node.right.accept(self).value)
        when :'||'
          AST::BooleanNode.new(node.left.accept(self).value || node.right.accept(self).value)[]
        when :!=
          AST::BooleanNode.new(node.left.accept(self).value != node.right.accept(self).value)
        when :'!=='
          AST::BooleanNode.new(node.left.accept(self).value != node.right.accept(self).value)
        when :==
          AST::BooleanNode.new(node.left.accept(self).value == node.right.accept(self).value)
        when :===
          AST::BooleanNode.new(node.left.accept(self).value == node.right.accept(self).value)
        when :<=
          AST::BooleanNode.new(node.left.accept(self).value <= node.right.accept(self).value)
        when :>=
          AST::BooleanNode.new(node.left.accept(self).value >= node.right.accept(self).value)
        when :<
          AST::BooleanNode.new(node.left.accept(self).value < node.right.accept(self).value)
        when :>
          AST::BooleanNode.new(node.left.accept(self).value > node.right.accept(self).value)
        when :pre_increment
          name = node.left.to_s
          value = current_scope[name].value
          current_scope[name] = AST::ApexIntegerNode.new(value: value + 1)
        when :pre_decrement
          name = node.left.to_s
          value = current_scope[name].value
          current_scope[name] = AST::ApexIntegerNode.new(value: value - 1)
        when :post_increment
          name = node.left.to_s
          value = current_scope[name].value
          current_scope[name] = AST::ApexIntegerNode.new(value: value + 1)
          value
        when :post_decrement
          name = node.left.to_s
          value = current_scope[name].value
          current_scope[name] = AST::ApexIntegerNode.new(value: value - 1)
          value
        else
          STDERR.puts 'No Operation Error'
        end
      end

      def visit_for(node)
        push_scope({})
        node.init_statement.accept(self)

        loop do
          break if node.exit_condition.accept(self).value == false
          return_value = execute_statements(node.statements)
          return return_value if return_value
          node.increment_statement.accept(self)
        end
        pop_scope
      end

      def visit_while(node)
        push_scope({})

        loop do
          break if node.condition_statement.accept(self).value == false
          return_value = execute_statements(node.statements)
          return return_value if return_value
        end
        pop_scope
      end

      def visit_forenum(node)
        push_scope({})
        list_node = node.expression.accept(self)
        next_method = search_instance_method(list_node.apex_class_node, :next)
        has_next_method= search_instance_method(list_node.apex_class_node, :has_next)

        loop do
          env = HashWithUpperCasedSymbolicKey.new({ this: list_node })
          push_scope(env, nil)
          has_next_return_node = execute_statement(has_next_method)
          pop_scope

          break if has_next_return_node.value == false

          env = HashWithUpperCasedSymbolicKey.new({ this: list_node })
          push_scope(env, nil)
          next_return_value = execute_statement(next_method)
          pop_scope

          current_scope[node.ident.to_s] = next_return_value
          return_value = execute_statements(node.statements)

          case return_value
          when AST::ReturnNode
            return return_value
          when AST::BreakNode
            return
          when AST::ContinueNode
          end
        end

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
        STDERR.puts 'ERROR : NO METHOD ERROR'
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
        STDERR.puts 'ERROR : NO METHOD ERROR'
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
        constructor_node = apex_class_node.constructor
        return object_node unless constructor_node

        # check constructor argument
        env = check_argument(constructor_node, node.arguments)
        return unless env

        # execute constructor argument
        env[:this] = object_node
        push_scope(env)
        execute_statement(constructor_node, false)
        pop_scope
        object_node
      end

      def parse_type(apex_class_name)
        [ApexClassTable[apex_class_name][:_top]]
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
          STDERR.puts "No Method Error!!"
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
            STDERR.puts 'NO RETURN ERROR'
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
          STDERR.puts "Argument Length Error!! #{evaluated_arguments.size} != #{method.arguments.size}"
          return
        end

        env = HashWithUpperCasedSymbolicKey.new
        evaluated_arguments.each_with_index do |evaluated_argument, idx|
          if method.arguments[idx].type != AnyObject && evaluated_argument.class != method.arguments[idx].type
            # TODO: Error Handling
            STDERR.puts "Argument Type Error!! #{evaluated_argument.class} != #{method.arguments[idx].type}"
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

      def visit_access(node)
        receiver_node = node.receiver.accept(self)
        key = node.key.accept(self)
        receiver_node.instance_fields[:_records][key.value]
      end

      def visit_name(node)
        receiver_or_name, field_name = field_from_name(node)
        if field_name
          receiver_or_name.instance_fields[field_name]
        else
          current_scope[receiver_or_name]
        end
      end

      def field_from_name(node)
        names = node.value
        name = names.first

        # variable.field...field
        variable = current_scope[name]
        if variable && names.size == 1
          return [name, nil]
        end
        receiver = names[1..-2].reduce(variable) do |receiver, name|
          break nil if receiver.nil?
          receiver.instance_fields[name]
        end


        if receiver && receiver.instance_fields[names.last]
          return [receiver, names.last]
        end

        # this_field.field...field
        field = current_scope[:this].instance_fields[name]
        if field && names.size == 1
          return [current_scope[:this], name]
        end
        receiver = names[1..-2].reduce(field) do |receiver, name|
          break nil if receiver.nil?
          receiver.instance_fields[name]
        end

        if receiver && receiver.instance_fields[names.last]
          return [receiver, names.last]
        end

        # class.static_field...field
        if names.length > 1
          apex_class = ApexClassTable[name]
          static_method_name = names[1]
          static_method = apex_class.static_fields[static_method_name]
          receiver = names[1..-2].reduce(static_method) do |receiver, name|
            break nil if receiver.nil?
            receiver.instance_fields[name]
          end
          if receiver && receiver.instance_fields[names.last]
            return [receiver, names.last]
          end
        end

        # name_space.class.static_field...field
        if names.length > 2
          namespace = NameSpaceTable[name]
          apex_class_name = names[1]
          apex_class = namespace[apex_class_name]
          static_method = names[2]
          receiver = names[2..-2].reduce(apex_class[static_method]) do |receiver, name|
            break nil if receiver.nil?
            receiver.instance_fields[name]
          end
          if receiver && receiver.instance_fields[names.last]
            return [receiver, names.last]
          end
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
            receiver.instance_fields[name]
          end

          method_node = receiver.apex_class_node.search_instance_method(method_name)
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

            method_node = receiver.search_instance_method(method_name)
            return [receiver, method_node] if receiver && method_node
          end
        end

        # class.static_method()
        if names.length == 1
          class_info = ApexClassTable[name]
          if class_info
            apex_class = class_info[:_top]
            method_node = apex_class.search_static_method(method_name)
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
              receiver.instance_fields[name]
            end
            unless receiver.nil? && apex_class.search_instance_method(method_name)
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
            receiver.instance_fields[name]
          end
          unless receiver.nil? && apex_class.search_instance_method(method_name)
            return receiver
          end
        end
      end

      def visit_switch(node)
      end

      def visit_when(node)
      end

      def visit_dml(node)
      end

      def visit_trigger(node)
        TriggerTable.register(node.name, node)
      end

      def visit_object(node)
        node
      end

      def current_scope
        @environment_stack.last
      end

      def push_scope(env, parent = current_scope)
        @environment_stack.push(LocalEnvironment.new(env, parent))
      end

      def pop_scope
        @environment_stack.pop
      end
    end
  end
end
