require 'apex_parser/util/hash_with_upper_cased_symbolic_key'

module ApexParser
  module Visitor
    class TriggerTable
      class << self
        attr_accessor :triggers

        def register(name, trigger)
          @triggers ||= HashWithUpperCasedSymbolicKey.new
          triggers[name] = trigger
        end

        def [](name)
          triggers[name]
        end
      end
    end
  end
end
