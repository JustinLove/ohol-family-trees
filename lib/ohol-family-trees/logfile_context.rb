module OHOLFamilyTrees
  module LogfileContext
    def self.process(seeds, logs)
      context = {}

      prior_logfile = nil
      prior_arc = nil
      root = nil

      logs.each do |logfile|
        next unless logfile.placements?

        context[logfile.path] = {}
        arc = seeds.arc_at(logfile.timestamp+1)

        if (arc == prior_arc || logfile.timestamp == 1574102503) && prior_logfile && logfile.merges_with?(prior_logfile)
          #p "#{logfile.path} merges with #{prior_logfile.path}"
          context[logfile.path][:basefile] = prior_logfile
        else
          #p "#{logfile.path} is root"
          root = logfile
        end
        context[logfile.path][:rootfile] = root
        if prior_logfile
          #p (logfile.timestamp - prior_logfile.timestamp) / (60.0 * 60.0)
        end
        prior_logfile = logfile
        prior_arc = arc
      end

      context
    end
  end
end
