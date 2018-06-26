module ApexParser
  module AST
    class MethodDeclarationNode < Base
      attr_accessor :name, :access_level, :return_type,
        :arguments, :statements, :apex_class_name, :native

      def native?
        native
      end

      def accept(visitor)
        visitor.visit_method(self)
      end
    end
  end
end
