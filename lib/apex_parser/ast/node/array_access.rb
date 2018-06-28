module ApexParser
  module AST
    class ArrayAccess < Base
      attr_accessor :receiver, :key

      def accept(visitor)
        visitor.visit_access(self)
      end
    end
  end
end
