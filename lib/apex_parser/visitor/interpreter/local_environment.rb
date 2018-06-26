module ApexParser
  class LocalEnvironment
    attr_accessor :parent

    def initialize(env = {}, parent = nil)
      @env = HashWithUpperCasedSymbolicKey.new(env)
      @parent = parent
    end

    def include?(value)
      return true if @env.include?(value)
      return false unless @parent
      @parent.include?(value)
    end

    def []=(key, value)
      unless include?(key)
        @env[key] = value
        return
      end

      if @env.include?(key)
        @env[key] = value
      else
        unless @parent
          # TODO: handling
          puts 'Fatal Error'
        end
        @parent[key] = value
      end
    end

    def [](key)
      if @env.include?(key)
        @env[key]
      else
        unless @parent
          # TODO: handling
          puts 'Undefined Variable'
        end
        @parent[key]
      end
    end
  end
end
