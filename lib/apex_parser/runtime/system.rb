module ApexParser
  ApexClassCreator.new do |c|
    c.add_class(:System, %i[public])
    c.add_static_method(:debug, [:public], :String, [[:Object, :object]]) do |local_scope|
      puts local_scope[:object].to_s
    end

    c.add_static_method(:assert, [:public], :void, [[:Boolean, :condition], [:String, :msg]]) do |local_scope|
      next if local_scope[:condition].value == true
      puts local_scope[:msg].value
    end

    c.add_static_method(:assertEquals, [:public], :void, [[:Object, :expected], [:Object, :actual], [:String, :msg]]) do |local_scope|
      next if local_scope[:expected].value == local_scope[:actual].value
      puts <<~ERROR_MESSAGE
        expected => #{local_scope[:expected].value}
        actual   => #{local_scope[:actual].value}
      ERROR_MESSAGE
    end
  end
end
