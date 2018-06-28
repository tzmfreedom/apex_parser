module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:ApexPages, %i[public])
    c.add_static_method(:currentPage, [:public], :PageReference, []) do |local_scope|
      apex_class_node = ApexClassTable[:PageReference][:_top]
      object_node = AST::ObjectNode.new(apex_class_node: apex_class_node)
      object_node
    end
  end
end
