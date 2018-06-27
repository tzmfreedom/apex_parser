module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:Map, %i[public])

    c.set_constructor(:Map, %i[public], []) do |local_scope|
      this = local_scope[:this]
      this.instance_fields[:map] = {}
    end

    c.add_instance_method(:next, %i[public], :Object, []) do |local_scope|
      this = local_scope[:this]
      idx = this.instance_fields[:_idx] ||= 0
      this.instance_fields[:_idx] += 1
      key = this.instance_fields[:map].keys[idx]
      this.instance_fields[:map][key]
    end

    c.add_instance_method(:has_next, %i[public], :Boolean, []) do |local_scope|
      this = local_scope[:this]
      this.instance_fields[:map]
      idx = this.instance_fields[:_idx] ||= 0
      BooleanNode.new(idx < this.instance_fields[:map].length)
    end

    c.add_instance_method(:get, %i[public], :Object, [[:String, :key]]) do |local_scope|
      this = local_scope[:this]
      key = local_scope[:key].value
      this.instance_fields[:map][key]
    end

    c.add_instance_method(:put, %i[public], :Object, [[:String, :key], [:Object, :object]]) do |local_scope|
      this   = local_scope[:this]
      key = local_scope[:key].value
      object = local_scope[:object]

      map = this.instance_fields[:map]
      map[key] = object
    end
  end
end
