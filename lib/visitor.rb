class InterpreterVisitor
  NULL = Object.new

  def visit_class(node)
    ApexClassTable.register(node.name, node)
  end

  def visit_method(node, arguments)
    local_scope = {}
    local_scope[:arg1] = arguments[0]
    node.statements.each do |statement|
      statement.call(local_scope)
    end
  end

  def visit_class_method(node, arguments)
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
    node.call(method_name, arguments, local_scope)
  end

  def visit_call_static_method(node, local_scope)
    class_node = ApexClassTable[node.apex_class_name]
    # argumentsをlocal_scopeで評価
    evaluated_arguments = node.arguments.map { |argument|
      argument.accept(self, local_scope)
    }
    method = class_node.apex_static_methods[node.apex_method_name.to_sym]

    local_scope = {}
    local_scope[:arg1] = evaluated_arguments[0]
    if method.native?
      method.call(local_scope)
    else
      method.statements.each do |statement|
        statement.accept(self, local_scope)
      end
    end
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
