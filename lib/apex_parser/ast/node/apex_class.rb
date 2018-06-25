module ApexParser
  module AST
    class ApexClassNode < Base
      attr_accessor :modifiers, :name, :statements, :apex_super_class, :implements

      def initialize(args = {})
        super
        @statements ||= []
        @implements ||= []
      end

      def accept(visitor)
        visitor.visit_class(self)
      end
    end
  end
end
