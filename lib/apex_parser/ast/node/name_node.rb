module ApexParser
  module AST
    class NameNode < Base
      attr_accessor :value

      def accept(visitor, local_scope)
        visitor.visit_string(self, local_scope)
      end
    end
  end
end
