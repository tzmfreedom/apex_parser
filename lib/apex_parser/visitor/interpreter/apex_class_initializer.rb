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
      instance_methods = HashWithUpperCasedSymbolicKey.new
      static_methods   = HashWithUpperCasedSymbolicKey.new
      instance_fields  = HashWithUpperCasedSymbolicKey.new
      static_fields    = HashWithUpperCasedSymbolicKey.new
      annotations      = HashWithUpperCasedSymbolicKey.new
      other_modifiers  = HashWithUpperCasedSymbolicKey.new
      constructor      = nil
      access_modifier  = nil
      statements ||= []

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
            statement.statements.each do |statement|
              static_fields[statement.name] = statement.expression
            end
          else
            statement.statements.each do |statement|
              instance_fields[statement.name] = statement.expression
            end
          end
        end
      end

      modifiers.each do |modifier|
        case modifier
        when AST::AnnotationNode
          annotations[modifier] = modifier
        else
          if %w[public private protected].include?(modifier)
            access_modifier = modifier
          else
            other_modifiers[modifier] = modifier
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
