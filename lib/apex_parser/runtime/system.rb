module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:System, :public)
    c.add_static_method(:debug, :public, :String, [[:Object, :object]]) do |local_scope|
      puts local_scope[:object].value
    end
  end
end
