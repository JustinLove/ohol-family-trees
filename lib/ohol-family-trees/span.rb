module OHOLFamilyTrees
  class Span
    attr_reader :server
    attr_accessor :s_start
    attr_accessor :s_end
    attr_accessor :s_base
    attr_reader :seed

    def initialize(server, st, sd)
      @server = server
      @s_base = 0
      @s_start = st
      @s_end = st
      @seed = sd
    end

    def next(st)
      n = self.class.new(server, st, seed)
      n.s_base = s_end
      n
    end
  end
end
