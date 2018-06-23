module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Array, :public)

    c.add_instance_method(:Array, :public, :void, []) do |local_scope|
      this = local_scope[:this]
      this.apex_instance_variables[:records] = [SObject.new, SObject.new]
    end

    c.add_instance_method(:next, :public, :Account, []) do |local_scope|
      this = local_scope[:this]
      idx = this.apex_instance_variables[:_idx] ||= 0
      this.apex_instance_variables[:_idx] += 1
      this.apex_instance_variables[:records][idx]
    end

    c.add_instance_method(:has_next, :public, :Boolean, []) do |local_scope|
      this = local_scope[:this]
      this.apex_instance_variables[:records]
      idx = this.apex_instance_variables[:_idx] ||= 0
      BooleanNode.new(idx < this.apex_instance_variables[:records].length)
    end

    c.add_instance_method(:add, :public, :Boolean, [[:Object, :object]]) do |local_scope|
      this = local_scope[:this]
      this.apex_instance_variables[:records].push(local_scope[:object])
    end

    c.add_instance_method(:[], :public, :Boolean, [[:Integer, :idx]]) do |local_scope|
      this = local_scope[:this]
      idx = local_scope[:idx].value
      this.apex_instance_variables[:records][idx]
    end

    c.add_instance_method(:[]=, :public, :Boolean, [[:Integer, :idx], [:Object, :object]]) do |local_scope|
      this   = local_scope[:this]
      idx    = local_scope[:idx].value
      object = local_scope[:object]

      record = this.apex_instance_variables[:records]
      record[idx] = object
    end
  end
end
