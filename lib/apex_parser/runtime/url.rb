module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:URL, %i[public])
    c.add_static_method(:getSalesforceBaseUrl, [:public], :String, []) do |local_scope|
      AST::ApexStringNode.new(value: '')
    end
  end
end
