module ApexParser
  module AST
    class ForEnumNode < Base
      attr_accessor :type, :ident, :expression, :statements

      def accept(visitor)
        visitor.visit_forenum(self)
      end
    end
  end
end
