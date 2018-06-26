module ApexParser
  module AST
    class MethodInvocationNode < Base
      attr_accessor :receiver, :arguments, :apex_method_name

      def initialize(*args)
        super
        @arguments ||= []
      end

      def accept(visitor)
        visitor.visit_method_invocation(self)
      end
    end
  end
end
