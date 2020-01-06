module OHOLFamilyTrees
  class LogfileContext
    attr_reader :seeds
    attr_reader :prior_logfile
    attr_reader :prior_arc
    attr_reader :root
    attr_reader :base

    def initialize(_seeds)
      @seeds = _seeds
      @prior_logfile = nil
      @prior_arc = nil
      @root = nil
      @base = nil
    end

    def update!(logfile)
      arc = seeds.arc_at(logfile.timestamp+1)

      @base = nil
      if (arc == prior_arc || logfile.timestamp == 1574102503) && prior_logfile && logfile.merges_with?(prior_logfile)
        p "#{logfile.path} merges with #{prior_logfile.path}"
        @base = prior_logfile
      else
        p "#{logfile.path} is root"
        @root = logfile
      end
      if prior_logfile
        #p (logfile.timestamp - prior_logfile.timestamp) / (60.0 * 60.0)
      end
      @prior_logfile = logfile
      @prior_arc = arc
      self
    end
  end
end
