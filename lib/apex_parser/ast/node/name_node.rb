module ApexParser
  module AST
    class NameNode < Base
      attr_accessor :value

      def to_s
        value.join('.')
      end

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
