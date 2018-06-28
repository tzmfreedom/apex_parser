module ApexParser
  module AST
    class ArgumentNode < Base
      attr_accessor :type, :name

      def initialize(*args)
        super

        self.type =
          case type.to_s.to_sym
          when :Integer
            ApexIntegerNode
          when :Double
            ApexDoubleNode
          when :Boolean
            BooleanNode
          when :String
            ApexStringNode
          when :Blob
            Blob
          when :Object
            AnyObject
          else
            ObjectNode
          end
      end
    end
  end
end
