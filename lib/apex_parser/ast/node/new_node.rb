module ApexParser
  module AST
    class NewNode < Base
      attr_accessor :apex_class_name, :arguments

      def initialize(*args)
        super

        @arguments ||= []
      end

      def accept(visitor)
        visitor.visit_new(self)
      end
    end
  end
end
