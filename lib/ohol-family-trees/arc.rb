require 'ohol-family-trees/maplog'
require 'date'

module OHOLFamilyTrees
  class Arc
    SplitArcsBefore = DateTime.parse('2019-07-31 12:56-0500').to_time.to_i

    attr_reader :server
    attr_accessor :s_start
    attr_accessor :s_end
    attr_accessor :seed

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
      s_end = 0
      while line = file.gets
        log = Maplog.create(line)
        if log.kind_of?(Maplog::ArcStart)
          if s_start == 0
            s_end = s_start = log.s_start
          end
          if start && log.s_start < SplitArcsBefore
            #p [s_start, s_end]
            arcs << Arc.new(server, start.s_start, s_end, seed)
            s_start = log.s_start
            s_end = s_start
          end
          start = log
        elsif log.kind_of?(Maplog::Placement)
          log.ms_start = start.ms_start
          s_end = log.s_time
        end
      end
      if s_start != 0
        #p [s_start, s_end]
        arcs << Arc.new(server, s_start, s_end, seed)
      end
      arcs
    end
  end
end
