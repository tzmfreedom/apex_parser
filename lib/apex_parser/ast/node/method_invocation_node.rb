module ApexParser
  module AST
    class MethodInvocationNode < Base
      attr_accessor :receiver, :arguments, :apex_method_name

      def initialize(*args)
        super
        @arguments ||= []
      end

      def accept(visitor, local_scope)
        visitor.visit_call_method(self, local_scope)
      end
    end
  end
end
