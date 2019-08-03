require 'ohol-family-trees/maplog'

module OHOLFamilyTrees
  class Arc
    attr_reader :server
    attr_reader :s_start
    attr_reader :s_end
    attr_reader :seed

    def initialize(server, st, length, sd)
      @server = server
      @s_start = st
      @s_end = st + length
      @seed = sd
    end

    def self.load_log(logfile)
      server = logfile.server
      seed = logfile.seed
      file = logfile.open
      arcs = []
      start = nil
      ms_last_offset = 0
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if start
            arcs << Arc.new(server, start.s_start, (ms_last_offset/1000).round, seed)
          end
          start = log
        else
          ms_last_offset = log.ms_offset
        end
      end
      if start
        arcs << Arc.new(server, start.s_start, (ms_last_offset/1000).round, seed)
      end
      arcs
    end
  end
end
