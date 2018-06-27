module ApexParser
  module AST
    class SoqlNode < Base
      attr_accessor :soql

      def accept(visitor)
        visitor.visit_soql(self)
      end

      def value
        soql
      end
    end
  end
end
