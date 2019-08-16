require 'ohol-family-trees/maplog'
require 'date'

module OHOLFamilyTrees
  class Arc
    SplitArcsBefore = DateTime.parse('2019-07-31 12:56-0500').to_time.to_i

    attr_reader :server
    attr_reader :s_start
    attr_reader :s_end
    attr_reader :seed

    def initialize(server, st, en, sd)
      @server = server
      @s_start = st
      @s_end = en
      @seed = sd
    end

    def self.load_log(logfile)
      server = logfile.server
      seed = logfile.seed
      file = logfile.open
      arcs = []
      start = nil
      s_start = 0
      ms_last_offset = 0
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if s_start == 0
            s_start = log.s_start
          end
          if start && log.s_start < SplitArcsBefore
            s_start = log.s_start
            s_end = start.s_start + (ms_last_offset/1000).round
            arcs << Arc.new(server, start.s_start, s_end, seed)
          end
          start = log
        else
          ms_last_offset = log.ms_offset
        end
      end
      if s_start != 0
        s_end = start.s_start + (ms_last_offset/1000).round
        arcs << Arc.new(server, s_start, s_end, seed)
      end
      arcs
    end
  end
end
