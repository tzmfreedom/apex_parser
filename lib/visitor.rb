class InterpreterVisitor
  NULL = Object.new

  def visit_return(node, local_scope)
    value = node.expression.accept(self, local_scope)
    node.value = value
    node
  end

  def visit_if(node, local_scope)
    condition_node = node.condition.accept(self, local_scope)
    if condition_node.value == true
      node.if_stmt.each do |statement|
        statement.accept(self, local_scope)
      end
    else
      return unless node.else_stmt
      node.else_stmt.each do |statement|
        statement.accept(self, local_scope)
      end
    end
  end

  def visit_operator(node, local_scope)
    case node.type.to_sym
      when :assign
        if node.left.class == String
          local_scope[node.left.to_sym] = node.right.accept(self, local_scope)
        else
          receiver_node = node.left.receiver.accept(self, local_scope)
          receiver_node.apex_instance_variables[node.left.name.to_sym] = node.right.accept(self, local_scope)
        end
      when :define
        if local_scope[node.left.to_sym]
          # TODO: Define Duplicate Error
        end

        if node.right
          local_scope[node.left.to_sym] = node.right.accept(self, local_scope)
        else
          local_scope[node.left.to_sym] = NULL
        end
      when :<
        BooleanNode.new(node.left.accept(self, local_scope).value < node.right.accept(self, local_scope).value)
      when :>
        BooleanNode.new(node.left.accept(self, local_scope).value > node.right.accept(self, local_scope).value)
      when :plus_plus
        value = local_scope[node.left.to_sym].value
        local_scope[node.left.to_sym] = ApexIntegerNode.new(value: value + 1)
      when :minus_minus
      value = local_scope[node.left.to_sym].value
      local_scope[node.left.to_sym] = ApexIntegerNode.new(value: value - 1)
    end
  end

  def visit_for(node, local_scope)
    new_local_scope = local_scope.dup
    node.init_stmt.accept(self, new_local_scope)

    loop do
      break if node.exit_condition.accept(self, new_local_scope).value == false
      return_value = execute_statement(node, new_local_scope, false)
      return return_value if return_value
      node.increment_stmt.accept(self, new_local_scope)
    end
  end

  def visit_forenum(node, local_scope)
    new_local_scope = local_scope.dup
    list_node = new_local_scope[node.list.to_sym]
    next_method = list_node.apex_class_node.apex_instance_methods[:next]
    has_next_method= list_node.apex_class_node.apex_instance_methods[:has_next]

    loop do
      has_next_local_scope = { this: list_node }
      has_next_return_node = execute_statement(has_next_method, has_next_local_scope)

      break if has_next_return_node.value == false

      next_local_scope = { this: list_node }
      next_return_value = execute_statement(next_method, next_local_scope)
      new_local_scope[node.ident.to_sym] = next_return_value
      execute_statement(node, new_local_scope, false)
    end
  end

  def visit_class(node)
    ApexClassTable.register(node.name, node)
  end

  def visit_new(node, local_scope)
    apex_class_node = ApexClassTable[node.apex_class_name.to_sym]
    object_node = ApexObjectNode.new(apex_class_node: apex_class_node, arguments: node.arguments)

    # assign instance variables
    object_node.apex_instance_variables = apex_class_node.apex_instance_variables.map do |variable_name, variable_node|
      [variable_name, variable_node.accept(self, {})]
    end.to_h

    # constructor
    instance_method_node = apex_class_node.apex_instance_methods[apex_class_node.name.to_sym]
    return object_node unless instance_method_node

    # check constructor argument
    new_local_scope = check_argument(instance_method_node, node.arguments, local_scope)
    return unless new_local_scope

    # execute constructor argument
    new_local_scope = {}
    new_local_scope[:this] = object_node
    execute_statement(instance_method_node, new_local_scope, false)
    object_node
  end

  def visit_def_instance_method(node, local_scope)
  end

  def visit_def_instance_variable(node, local_scope)
    class_node = node.apex_class_node
    expression = class_node.apex_instance_variables[node.name.to_sym].expression
    return unless expression
    expression.accept(self, local_scope)
  end

  def visit_instance_variable(node, local_scope)
    receiver = local_scope[node.receiver.name.to_sym]
    receiver.apex_instance_variables[node.name.to_sym]
  end

  def visit_call_instance_method(node, local_scope)
    receiver_node = node.receiver.accept(self, local_scope)
    class_node = receiver_node.apex_class_node
    method = class_node.apex_instance_methods[node.name.to_sym]

    local_scope = check_argument(method, node.arguments, local_scope)
    return unless local_scope

    new_local_scope = {}
    new_local_scope[:this] = receiver_node
    execute_statement(method, new_local_scope)
  end

  def visit_call_static_method(node, local_scope)
    class_node = ApexClassTable[node.apex_class_name]
    method = class_node.apex_static_methods[node.apex_method_name.to_sym]

    local_scope = check_argument(method, node.arguments, local_scope)
    return unless local_scope

    execute_statement(method, local_scope)
  end

  def execute_statement(method_node, local_scope, must_return = true)
    if method_node.respond_to?(:native?) && method_node.native?
      method_node.call(local_scope)
    else
      method_node.statements.each do |statement|
        return_value = statement.accept(self, local_scope)
        return return_value.value if return_value.class == ReturnNode
      end

      if must_return
        # TODO: no return error
        puts 'NO RETURN ERROR'
      end
      nil
    end
  end

  def visit_soql(node, local_scope)
    node
  end

  def check_argument(method, arguments, local_scope)
    evaluated_arguments = arguments.map { |argument|
      argument.accept(self, local_scope)
    }
    # Check Argument
    if evaluated_arguments.size !=  method.arguments.size
      # TODO: Error Handling
      puts "Error!!"
      return
    end

    new_local_scope = {}
    evaluated_arguments.each_with_index do |evaluated_argument, idx|
      if method.arguments[idx].type != AnyObject && evaluated_argument.class != method.arguments[idx].type
        # TODO: Error Handling
        puts "Error!!"
        return
      end
      variable_name = method.arguments[idx].name.to_sym
      new_local_scope[variable_name] = evaluated_argument
    end
    new_local_scope
  end

  def visit_null(node, local_scope)
    node
  end

  def visit_boolean(node, local_scope)
    node
  end

  def visit_identify(node, local_scope)
    local_scope[node.name.to_sym]
  end

  def visit_string(node, local_scope)
    node
  end

  def visit_integer(node, local_scope)
    node
  end

  def visit_double(node, local_scope)
    node
  end
end
