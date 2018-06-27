module ApexParser
  class SingleValueNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  class Base
    attr_accessor :lineno

    def initialize(args = {})
      args.each do |key, value|
        public_send("#{key}=", value)
      end
    end
  end

  class AnyObject; end

  class SObject
    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def value
      inspect
    end
  end
end
