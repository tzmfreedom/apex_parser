module ApexParser
  class SoqlNode < Base
    attr_accessor :soql

    def accept(visitor, local_scope)
      visitor.visit_soql(self, local_scope)
    end

    def value
      soql
    end
  end
end
