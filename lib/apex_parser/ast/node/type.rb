module ApexParser
  module AST
    class Type < Base
      attr_accessor :name, :generics_arguments

      def accept(visitor)
        visitor.visit_type(self)
      end
    end
  end
end
