module ApexParser
  module AST
    class FieldDeclarationNode < Base
      attr_accessor :type, :modifiers, :statements

      def static?
        modifiers.include?('static')
      end

      def accept(visitor)
        visitor.visit_field_declaration(self)
      end
    end
  end
end
