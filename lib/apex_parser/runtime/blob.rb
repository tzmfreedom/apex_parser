module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Blob, %i[public])
    c.add_static_method(:valueOf, [:public], :String, [[:String, :string_to_blob]]) do |local_scope|
      AST::Blob.new(value: local_scope[:string_to_blob].value)
    end

    c.add_instance_method(:size, [:public], :Integer, []) do |local_scope|
      AST::ApexIntegerNode.new(value: local_scope[:this].value.bytesize)
    end

    c.add_instance_method(:toString, [:public], :String, []) do |local_scope|
      AST::ApexStringNode.new(value: local_scope[:this].value)
    end

    c.add_static_method(:toPdf, [:public], :String, [[:String, :string_to_convert]]) do |local_scope|
      raise 'Not Implement'
    end
  end
end
