module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Map, :public)

    c.add_instance_method(:Map, :public, :void, []) do |local_scope|
      this = local_scope[:this]
      this.apex_instance_variables[:map] = {}
    end

    c.add_instance_method(:next, :public, :Object, []) do |local_scope|
      this = local_scope[:this]
      idx = this.apex_instance_variables[:_idx] ||= 0
      this.apex_instance_variables[:_idx] += 1
      key = this.apex_instance_variables[:map].keys[idx]
      this.apex_instance_variables[:map][key]
    end

    c.add_instance_method(:has_next, :public, :Boolean, []) do |local_scope|
      this = local_scope[:this]
      this.apex_instance_variables[:map]
      idx = this.apex_instance_variables[:_idx] ||= 0
      BooleanNode.new(idx < this.apex_instance_variables[:map].length)
    end

    c.add_instance_method(:get, :public, :Object, [[:String, :key]]) do |local_scope|
      this = local_scope[:this]
      key = local_scope[:key].value
      this.apex_instance_variables[:map][key]
    end

    c.add_instance_method(:put, :public, :Object, [[:String, :key], [:Object, :object]]) do |local_scope|
      this   = local_scope[:this]
      key = local_scope[:key].value
      object = local_scope[:object]

      map = this.apex_instance_variables[:map]
      map[key] = object
    end
  end
end
