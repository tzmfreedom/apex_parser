module ApexParser
  module AST
    class NewNode < Base
      attr_accessor :apex_class_name, :arguments

      def initialize(*args)
        super

        @arguments ||= []
      end

      def accept(visitor, local_scope)
        visitor.visit_new(self, local_scope)
      end
    end
  end
end
