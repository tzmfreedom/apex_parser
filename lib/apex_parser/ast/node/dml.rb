module ApexParser
  module AST
    class DML < Base
      attr_accessor :dml, :object

      def accept(visitor)
        visitor.visit_dml(self)
      end
    end
  end
end
