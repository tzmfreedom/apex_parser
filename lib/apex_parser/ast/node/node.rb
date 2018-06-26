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
      self.class.attributes.each do |attr|
        public_send("#{attr}=", args[attr])
      end
    end

    class << self
      attr_accessor :attributes

      @attributes ||= []

      def attr_accessor(*args)
        (@attributes ||= []).concat(args)
        super
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
