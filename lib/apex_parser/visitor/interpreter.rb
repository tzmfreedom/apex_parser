require 'apex_parser/data_loader'

require 'apex_parser/visitor/interpreter/apex_class_table'
require 'apex_parser/apex_class_creator'
Dir[File.expand_path('./runtime/**/*.rb', __dir__)].each do |f|
  require f
end

module ApexParser
  module Visitor
    class Interpreter
      NULL = Object.new

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
          if node.left.class == IdentifyNode
            current_scope[node.left.name] = node.right.accept(self)
          else
            receiver_node = node.left.receiver.accept(self)
            receiver_node.apex_instance_variables[node.left.name] = node.right.accept(self)
          end
        when :define
          if current_scope[node.left.name]
            # TODO: Define Duplicate Error
          end

          if node.right
            current_scope[node.left.name] = node.right.accept(self)
          else
            current_scope[node.left.name] = NULL
          end
        when :add
          ApexIntegerNode.new(node.left.accept(self).value + node.right.accept(self).value)
        when :sub
          ApexIntegerNode.new(node.left.accept(self).value - node.right.accept(self).value)
        when :div
          ApexIntegerNode.new(node.left.accept(self).value / node.right.accept(self).value)
        when :mul
          ApexIntegerNode.new(node.left.accept(self).value * node.right.accept(self).value)
        when :<<
          ApexIntegerNode.new(node.left.accept(self).value << node.right.accept(self).value)
        when :'<<<'
          ApexIntegerNode.new(node.left.accept(self).value << node.right.accept(self).value)
        when :>>
          ApexIntegerNode.new(node.left.accept(self).value >> node.right.accept(self).value)
        when :'>>>'
          ApexIntegerNode.new(node.left.accept(self).value >> node.right.accept(self).value)
        when :&
          ApexIntegerNode.new(node.left.accept(self).value && node.right.accept(self).value)
        when :|
          ApexIntegerNode.new(node.left.accept(self).value | node.right.accept(self).value)
        when :^
          ApexIntegerNode.new(node.left.accept(self).value ^ node.right.accept(self).value)
        when :'&&'
          BooleanNode.new(node.left.accept(self).value && node.right.accept(self).value)
        when :'||'
          BooleanNode.new(node.left.accept(self).value || node.right.accept(self).value)[]
        when :!=
          BooleanNode.new(node.left.accept(self).value != node.right.accept(self).value)
        when :'!=='
          BooleanNode.new(node.left.accept(self).value == node.right.accept(self).value)
        when :===
          BooleanNode.new(node.left.accept(self).value == node.right.accept(self).value)
        when :<=
          BooleanNode.new(node.left.accept(self).value <= node.right.accept(self).value)
        when :>=
          BooleanNode.new(node.left.accept(self).value >= node.right.accept(self).value)
        when :<
          BooleanNode.new(node.left.accept(self).value < node.right.accept(self).value)
        when :>
          BooleanNode.new(node.left.accept(self).value > node.right.accept(self).value)
        when :plus_plus
          value = current_scope[node.left.name].value
          current_scope[node.left.name] = ApexIntegerNode.new(value + 1)
        when :minus_minus
          value = current_scope[node.left.name].value
          current_scope[node.left.name] = ApexIntegerNode.new(value - 1)
        end
      end

      def visit_for(node)
        push_scope({})
        node.init_stmt.accept(self)

        loop do
          break if node.exit_condition.accept(self).value == false
          return_value = execute_statement(node, false)
          return return_value if return_value
          node.increment_stmt.accept(self)
        end
        pop_scope
      end

      def visit_while(node)
        push_scope({})

        loop do
          break if node.condition_stmt.accept(self).value == false
          return_value = execute_statement(node, false)
          return return_value if return_value
        end
        pop_scope
      end

      def visit_forenum(node)
        push_scope({})
        list_node = current_scope[node.list.name]
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
          current_scope[node.ident.name] = next_return_value
          return_value = execute_statement(node, false)
          pop_scope

          case return_value
          when ReturnNode
            return return_value
          when BreakNode
            return
          when ContinueNode
          end
        end

        pop_scope
      end

      def search_instance_method(apex_class_node, method_name)
        class_node = apex_class_node
        while class_node
          method_node = class_node.apex_instance_methods[method_name]
          return method_node if method_node

          class_node = class_node.apex_super_class.accept(self, {})
        end

        # TODO: Error Handling
        puts 'ERROR : NO METHOD ERROR'
        nil
      end

      def search_static_method(apex_class_node, method_name)
        class_node = apex_class_node
        while class_node
          method_node = class_node.apex_static_methods[method_name]
          return method_node if method_node

          break unless class_node.apex_super_class
          class_node = class_node.apex_super_class.accept(self, {})
        end

        # TODO: Error Handling
        puts 'ERROR : NO METHOD ERROR'
        nil
      end

      def visit_class(node)
        ApexClassTable.register(node.name, node)
      end

      def visit_new(node)
        apex_class_node, generics_node = parse_type(node.apex_class_name)
        object_node = ApexObjectNode.new(apex_class_node: apex_class_node, arguments: node.arguments)
        object_node.generics_node = generics_node
        # assign instance variables
        object_node.apex_instance_variables = HashWithUpperCasedSymbolicKey.new(apex_class_node.apex_instance_variables.map do |variable_name, variable_node|
          [variable_name, variable_node.accept(self, HashWithUpperCasedSymbolicKey.new)]
        end.to_h)

        # constructor
        instance_method_node = apex_class_node.apex_instance_methods[apex_class_node.name]
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
        [ApexClassTable[class_name], generics_type ? ApexClassTable[generics_type] : nil]
      end

      def visit_def_instance_method(node)
      end

      def visit_def_instance_variable(node)
        class_node = node.apex_class_node
        expression = class_node.apex_instance_variables[node.name].expression
        return unless expression
        expression.accept(self)
      end

      def visit_instance_variable(node)
        receiver = current_scope[node.receiver.name]
        receiver.apex_instance_variables[node.name]
      end

      def visit_method_invocation(node)
        # binding.pry if node.receiver.name == 'System'
        receiver_node = node.receiver.accept(self)
        method =
          if receiver_node.is_a?(ApexClassNode)
            search_static_method(receiver_node, node.apex_method_name)
          else
            search_instance_method(receiver_node.apex_class_node, node.apex_method_name)
          end
        unless method
          puts "No Method Error!!"
          binding.pry
          return nil
        end
        env = check_argument(method, node.arguments)
        return unless env

        env[:this] = receiver_node
        push_scope(env)
        result = execute_statement(method)
        pop_scope
        result
      end

      def execute_statement(method_node, must_return = true)
        if method_node.respond_to?(:native?) && method_node.native?
          method_node.call(current_scope)
        else
          method_node.statements.each do |statement|
            return_value = statement.accept(self)
            # TODO: return_value.value
            if [ReturnNode, ContinueNode, BreakNode].include?(return_value.class)
              return return_value.value
            end
          end

          if must_return
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
        list_node = NewNode.new(apex_class_name: :'List<Account>', arguments: [])
          .accept(self)
        list_node.apex_instance_variables[:records] = records
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
        if node
          field_from_name(node)
        else
          receiver_from_name(node)
        end
      end

      def field_from_name(node)
        names = node.name
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
        names = node.name
        name = names.first
        method_name = node.method_name

        # variable.field.field...method()
        variable = current_scope[name]
        receiver = names[1..-1].reduce(variable) do |receiver, name|
          break nil if receiver.nil?
          receiver.fields[name]
        end

        unless !(receiver.nil?) && receiver.methods[method_name]
          return receiver
        end

        # this_field.field.field...method()
        field = current_scope[:this].fields[name]
        receiver = names[1..-1].reduce(field) do |receiver, name|
          break nil if receiver.nil?
          receiver.fields[name]
        end

        unless !(receiver.nil?) && receiver.methods[method_name]
          return receiver
        end

        # class.static_field.static_method()
        if names.length == 2
          apex_class = ApexClassTable[name]
          apex_class.static_fields[names[1]]
          unless receiver.nil? && apex_class.methods[method_name]
            return receiver
          end
        end

        # class.static_field.field...method()
        if names.length >= 3
          apex_class = ApexClassTable[name]
          static_method = names[1]
          static_field = apex_class.static_fields[static_method]
          receiver = names[2..-1].reduce(static_field) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end
          unless receiver.nil? && apex_class.methods[method_name]
            return receiver
          end
        end

        # namespace.class.static_field.field....method()
        if names.length >= 3
          namespace = NameSpaceTable[name]
          class_name = names[1]
          apex_class = namespace.classes[class_name]
          static_method_name = apex_class[names[2]]
          receiver = names[2..-1].reduce(static_method_name) do |receiver, name|
            break nil if receiver.nil?
            receiver.fields[name]
          end
          unless receiver.nil? && apex_class.methods[method_name]
            return receiver
          end
        end
      end

      def current_scope
        @current_scope
      end

      def push_scope(env, parent = @current_scope)
        scope = LocalEnvironment.new(env, parent)
        @current_scope = scope
      end

      def pop_scope
        @current_scope = scope.parent
      end
    end
  end
end
