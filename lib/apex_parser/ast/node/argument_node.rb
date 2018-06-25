module ApexParser
  module AST
    class ArgumentNode < Base
      attr_accessor :type, :name

      def initialize(*args)
        super

        self.type =
          case type
          when :Integer
            ApexIntegerNode
          when :Double
            ApexDoubleNode
          when :Boolean
            BooleanNode
          when :String
            ApexStringNode
          when :Object
            AnyObject
          else
            ApexObjectNode
          end
      end
    end
  end
end
