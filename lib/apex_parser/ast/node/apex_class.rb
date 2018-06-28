module ApexParser
  module AST
    class ApexClassNode < Base
      attr_accessor :modifiers, :name, :access_modifier, :annotations,
        :instance_fields, :instance_methods, :constructor,
        :static_fields, :static_methods,
        :apex_super_class, :implements

      def super_class
        @super_class ||= begin
          super_class_hash = ApexClassTable[apex_super_class.to_s]
          if super_class_hash
            super_class_hash[:_top]
          end
        end
      end

      def search_static_method(method_name)
        if static_methods.include?(method_name)
          static_methods[method_name]
        elsif super_class
          super_class.search_static_method(method_name)
        end
      end

      def search_instance_method(method_name)
        if instance_methods.include?(method_name)
          instance_methods[method_name]
        elsif super_class
          super_class.search_instance_method(method_name)
        end
      end

      def accept(visitor)
        visitor.visit_class(self)
      end
    end
  end
end
