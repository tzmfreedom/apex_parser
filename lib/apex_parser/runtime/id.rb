module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Id, %i[public])
    c.add_instance_method(:addError, [:public], :String, [[:String, :string_to_integer]]) do |local_scope|
    end

    c.add_instance_method(:getSObjectType, [:public], :String, [[:String, :string_to_integer]]) do |local_scope|
    end

    c.add_instance_method(:valueOf, [:public], :String, [[:String, :to_id]]) do |local_scope|
      AST::Id.new(value: local_scope[:to_id].value)
    end
  end
end
