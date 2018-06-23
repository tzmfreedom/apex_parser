module ApexParser
  class HashWithUpperCasedSymbolicKey
    attr_accessor :env

    def initialize(init_hash = {})
      @env = {}
      init_hash.map { |k, v| @env[k.upcase.to_sym] = v }
    end

    def []=(key, value)
      @env[key.upcase.to_sym] = value
    end

    def [](key)
      @env[key.upcase.to_sym]
    end

    def map(&block)
      @env.map(&block)
    end
  end
end
