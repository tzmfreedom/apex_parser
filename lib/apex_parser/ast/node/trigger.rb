module ApexParser
  module AST
    class Trigger < Base
      attr_accessor :name, :object, :arguments, :statements

      def accept(visitor)
        visitor.visit_trigger(self)
      end
    end
  end
end
