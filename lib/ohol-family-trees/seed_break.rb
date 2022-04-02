require 'ohol-family-trees/arc_list'

module OHOLFamilyTrees
  module SeedBreak
    def self.read_resets(filesystem, path)
      resets = []
      filesystem.read(path) do |f|
        while line = f.gets
          resets << line.to_i
        end
      end
      return resets
    end

    def self.process(logs, manual_resets = [], automatic_resets = [])
      arcs = ArcList.new
      prior = nil
      current_arc = nil
      hanging_reset = automatic_resets.last || 0
      reset_window = hanging_reset..(hanging_reset + 20)
      logs.each do |logfile|
        #next unless logfile.timestamp >= 1573895673

        detected_reset = manual_resets.member?(logfile.timestamp) || reset_window.cover?(logfile.timestamp)

        if logfile.placements?
          if !detected_reset and prior and logfile.merges_with?(prior)
          else
            #p "merge break at #{logfile.timestamp}"
            if current_arc
              current_arc.s_end = logfile.timestamp
            end
            current_arc = Arc.new(0, logfile.timestamp+1, nil, logfile.seed)
            arcs << current_arc
          end

          if prior and false
            gap = (logfile.timestamp - prior.timestamp) / (60.0 * 60.0)
            #p "#{prior.approx_log_time} #{gap} #{logfile.approx_log_time}"
            unless (23.99..24.01).member?(gap)
              p "#{gap} gap at #{logfile.timestamp}"
            end
          end

          prior = logfile
        end

        if logfile.seed_only?
          #p "seed change at #{logfile.timestamp}"
          if detected_reset
            if current_arc
              current_arc.seed = logfile.seed
            end
          else
            if current_arc
              current_arc.s_end = logfile.timestamp
            end
            current_arc = Arc.new(0, logfile.timestamp+1, nil, logfile.seed)
            arcs << current_arc
          end
        end
      end
      p "hanging reset window #{reset_window}"
      return arcs
    end
  end
end
