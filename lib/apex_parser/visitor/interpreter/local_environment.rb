class LocalEnvironment
  def initialize(env = {}, parent = nil)
    @env = HashWithUpperCasedSymbolicKey.new(env)
    @parent = parent
  end

  def include?(value)
    return true if @env.include?(value)
    return false unless @parent
    @parent.include?(value)
  end

  def []=(value)
    unless include?(value)
      @env[value] = value
      return
    end

    if @env.include?(value)
      @env[value] = value
    else
      unless @parent
        # TODO: handling
        puts 'Fatal Error'
      end
      @parent[value] = value
    end
  end

  def [](value)
    if @env.include?(value)
      @env[value] = value
    else
      unless @parent
        # TODO: handling
        puts 'Undefined Variable'
      end
      @parent[value] = value
    end
  end
end
