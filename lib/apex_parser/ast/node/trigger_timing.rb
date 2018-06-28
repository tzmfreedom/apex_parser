module ApexParser
  module AST
    class TriggerTiming < Base
      attr_accessor :timing, :dml

      def accept(visitor)
        visitor.visit_trigger(self)
      end
    end
  end
end
