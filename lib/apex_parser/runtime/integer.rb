module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Integer, %i[public])
    c.add_static_method(:valueOf, [:public], :String, [[:String, :string_to_integer]]) do |local_scope|
      AST::ApexIntegerNode.new(value: local_scope[:string_to_integer].to_i)
    end
  end
end
