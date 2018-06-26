module ApexParser
  module AST
    class MethodDeclarationNode < Base
      attr_accessor :name, :modifiers, :return_type,
        :arguments, :statements, :native, :call_proc

      def initialize(*args)
        super

        @modifiers ||= []
      end

      def native?
        native
      end

      def static?
        modifiers.include?('static')
      end

      def accept(visitor)
        visitor.visit_method_declaration(self)
      end
    end
  end
end
