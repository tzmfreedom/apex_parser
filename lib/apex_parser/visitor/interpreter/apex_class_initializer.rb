require 'apex_parser/util/hash_with_upper_cased_symbolic_key'

module ApexParser
  class ApexClassInitializer
    def self.create(
      name:,
        statements:,
        modifiers:,
        apex_super_class:,
        implements:,
        lineno:
    )
      instance_methods = {}
      static_methods   = {}
      instance_fields  = {}
      static_fields    = {}
      annotations      = {}
      other_modifiers  = {}
      constructor      = nil
      access_modifier  = nil

      statements.each do |statement|
        case statement
        when AST::ConstructorDeclarationNode
          constructor = statement
        when AST::MethodDeclarationNode
          if statement.static?
            static_methods[statement.name] = statement
          else
            instance_methods[statement.name] = statement
          end
        when AST::FieldDeclarationNode
          if statement.static?
            static_fields[statement.name] = statement
          else
            instance_fields[statement.name] = statement
          end
        end
      end

      modifiers.each do |modifier|
        case modifier
        when AST::AnnotationNode
          annotations[modifier.name] = modifier
        else
          if %w[public private protected].include?(modifiers.name)
            access_modifier = modifier
          else
            other_modifiers[modifier.name] = modifier
          end
        end
      end

      AST::ApexClassNode.new(
        name: name,
        constructor: constructor,
        access_modifier: access_modifier,
        annotations: annotations,
        modifiers: other_modifiers,
        instance_methods: instance_methods,
        static_methods: static_methods,
        instance_fields: instance_fields,
        static_fields: static_fields,
        apex_super_class: apex_super_class,
        implements: implements,
        lineno: lineno
      )
    end
  end
end
