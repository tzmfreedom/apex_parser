module ApexParser
  module AST
    class FieldDeclarationNode < Base
      attr_accessor :type, :modifiers, :expression

      def accept(visitor)
        visitor.visit_static_variable(self)
      end
    end
  end
end
