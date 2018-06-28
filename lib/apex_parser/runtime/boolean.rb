module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Boolean, %i[public])
    c.add_static_method(:valueOf, [:public], :String, [[:String, :string_to_boolean]]) do |local_scope|
      AST::BooleanNode.new(value: local_scope[:string_to_boolean].value == 'true')
    end
  end
end
