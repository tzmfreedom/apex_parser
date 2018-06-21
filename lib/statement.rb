class CallInstanceMethodNode < ApexNode
  attr_accessor :type, :receiver, :name, :arguments, :expression

  def accept(visitor, local_scope)
    visitor.visit_call_instance_method(self, local_scope)
  end
end

class CallStaticMethodNode < ApexNode
  attr_accessor :apex_class_name, :arguments, :apex_method_name

  def accept(visitor, local_scope)
    visitor.visit_call_static_method(self, local_scope)
  end
end

class OperatorNode < ApexNode
  attr_accessor :type, :left, :operator, :right

  def accept(visitor, local_scope)
    visitor.visit_operator(self, local_scope)
  end
end
