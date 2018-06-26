module ApexParser
  module AST
    class ApexClassNode < Base
      attr_accessor :modifiers, :name, :access_modifier, :annotations,
        :instance_fields, :instance_methods, :constructor,
        :static_fields, :static_fields,
        :apex_super_class, :implements

      def accept(visitor)
        visitor.visit_class(self)
      end
    end
  end
end
