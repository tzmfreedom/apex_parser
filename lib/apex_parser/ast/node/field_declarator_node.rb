module ApexParser
  module AST
    class FieldDeclarator < Base
      attr_accessor :name, :modifiers, :expression

      def accept(visitor)
        visitor.visit_static_variable(self)
      end
    end
  end
end
