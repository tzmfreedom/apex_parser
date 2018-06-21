class InterpreterVisitor
  NULL = Object.new

  def visit_class(node)
    ApexClassTable.register(node.name, node)
  end

  def visit_method(node, local_scope)
    node.statements.each do |statement|
      statement.accept(self, local_scope)
    end
  end

  def visit_instance_variable
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
    case node.type
      when :assign
        local_scope[node.left.to_sym] = node.right.accept(self, local_scope)
      when :define
        if local_scope[node.left.to_sym]
          # TODO: Define Duplicate Error
        end

        if node.right
          local_scope[node.left.to_sym] = node.right.accept(self, local_scope)
        else
          local_scope[node.left.to_sym] = NULL
        end
    end
  end

  def visit_call_instance_method(node, local_scope)
    receiver_node = node.receiver.accept(self, local_scope)
    class_node = ApexClassTable[receiver_node.apex_class_node.name]
    method = class_node.apex_instance_methods[node.name.to_sym]

    local_scope = check_argument(method, node.arguments, local_scope)
    return unless local_scope

    if method.native?
      method.call(local_scope)
    else
      method.statements.each do |statement|
        statement.accept(self, local_scope)
      end
    end
  end

  def visit_call_static_method(node, local_scope)
    class_node = ApexClassTable[node.apex_class_name]
    method = class_node.apex_static_methods[node.apex_method_name.to_sym]

    local_scope = check_argument(method, node.arguments, local_scope)
    return unless local_scope

    if method.native?
      method.call(local_scope)
    else
      method.statements.each do |statement|
        statement.accept(self, local_scope)
      end
    end
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

  def visit_new(node, local_scope)
    apex_class_node = ApexClassTable[node.apex_class_name.to_sym]
    object_node = ApexObjectNode.new(apex_class_node: apex_class_node, arguments: node.arguments)
    instance_method_node = apex_class_node.apex_instance_methods[apex_class_node.name.to_sym]
    return unless instance_method_node

    new_local_scope = check_argument(instance_method_node, node.arguments, local_scope)
    return unless new_local_scope

    new_local_scope = {}
    new_local_scope[:this] = object_node
    instance_method_node.accept(self, new_local_scope)
    object_node
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
