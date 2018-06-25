module ApexParser
  module AST
    class MethodDeclarationNode < Base
      attr_accessor :name, :access_level, :return_type,
        :arguments, :statements, :apex_class_name, :native

      def native?
        native
      end

      def accept(visitor, local_scope)
        visitor.visit_method(self, local_scope)
      end
    end
  end
end
