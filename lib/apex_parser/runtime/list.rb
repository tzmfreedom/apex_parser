module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:List, %i[public])

    c.set_constructor(:List, %i[public], []) do |local_scope|
      this = local_scope[:this]
      this.instance_fields[:records] = []
    end

    c.add_instance_method(:next, %i[public], :Account, []) do |local_scope|
      this = local_scope[:this]
      idx = this.instance_fields[:_idx] ||= 0
      this.instance_fields[:_idx] += 1
      this.instance_fields[:records][idx]
    end

    c.add_instance_method(:has_next, %i[public], :Boolean, []) do |local_scope|
      this = local_scope[:this]
      this.instance_fields[:records]
      idx = this.instance_fields[:_idx] ||= 0
      AST::BooleanNode.new(idx < this.instance_fields[:records].length)
    end

    c.add_instance_method(:add, %i[public], :void, [[:Object, :object]]) do |local_scope|
      this = local_scope[:this]
      this.instance_fields[:records].push(local_scope[:object])
    end

    c.add_instance_method(:get, %i[public], :Object, [[:Integer, :idx]]) do |local_scope|
      this = local_scope[:this]
      idx = local_scope[:idx].value
      this.instance_fields[:records][idx]
    end

    c.add_instance_method(:[], %i[public], :Object, [[:Integer, :idx]]) do |local_scope|
      this = local_scope[:this]
      idx = local_scope[:idx].value
      this.instance_fields[:records][idx]
    end

    c.add_instance_method(:[]=, %i[public], :Object, [[:Integer, :idx], [:Object, :object]]) do |local_scope|
      this   = local_scope[:this]
      idx    = local_scope[:idx].value
      object = local_scope[:object]

      record = this.instance_fields[:records]
      record[idx] = object
    end
  end
end
