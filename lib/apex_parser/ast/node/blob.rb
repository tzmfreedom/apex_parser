module ApexParser
  module AST
    class Blob < Base
      attr_accessor :value

      def apex_class_node
        ApexClassTable[:Blob][:_top]
      end

      def to_s
        "Blob[#{value.bytesize}]"
      end

      def accept(visitor)
        visitor.visit_blob(self)
      end
    end
  end
end
