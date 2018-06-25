module Registerable
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def register(name, apex_class)
      (@registered_data ||= HashWithUpperCasedSymbolicKey.new)[name] = apex_class
    end

    def [](name)
      @registered_data[name]
    end
  end
end
