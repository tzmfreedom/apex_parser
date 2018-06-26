module ApexParser
  module AST
    class AnnotationNode < Base
      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def accept(visitor)
        visitor.visit_annotation(self)
      end
    end
  end
end
