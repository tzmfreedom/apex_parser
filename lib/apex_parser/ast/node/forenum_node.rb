module ApexParser
  module AST
    class ForEnumNode < Base
      attr_accessor :type, :ident, :list, :statements

      def accept(visitor, local_scope)
        visitor.visit_forenum(self, local_scope)
      end
    end
  end
end
