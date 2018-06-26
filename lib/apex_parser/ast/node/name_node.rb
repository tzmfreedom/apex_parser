module ApexParser
  module AST
    class NameNode < Base
      attr_accessor :value

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
