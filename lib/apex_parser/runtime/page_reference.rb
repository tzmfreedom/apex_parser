module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:PageReference, %i[public])
    c.add_instance_method(:getParameters, [:public], :Map, []) do |local_scope|
      apex_class_node = ApexClassTable[:Map][:_top]
      object_node = AST::ObjectNode.new(apex_class_node: apex_class_node)
      object_node
    end
  end
end
