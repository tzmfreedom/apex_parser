module ApexParser
  module AST
    class ApexStringNode < Base
      attr_accessor :value

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
