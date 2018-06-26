require 'apex_parser/util/hash_with_upper_cased_symbolic_key'

module ApexParser
  module Visitor
    class Interpreter
      class ApexClassTable
        attr_accessor :apex_classes

        class << self
          def register(name, apex_class)
            @apex_classes ||= HashWithUpperCasedSymbolicKey.new
            @apex_classes[name] = { _top: apex_class }
          end

          def [](name)
            @apex_classes[name]
          end
        end
      end
    end
  end
end
