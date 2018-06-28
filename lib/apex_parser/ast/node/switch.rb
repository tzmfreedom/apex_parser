module ApexParser
  module AST
    class Switch < Base
      attr_accessor :expression, :statements

      def accept(visitor)
        visitor.visit_switch(self)
      end
    end
  end
end
