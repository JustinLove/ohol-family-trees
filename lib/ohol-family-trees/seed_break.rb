require 'ohol-family-trees/arc_list'

module OHOLFamilyTrees
  module SeedBreak
    def self.process(logs, manual_resets = [])
      arcs = ArcList.new
      prior = nil
      current_arc = nil
      logs.each do |logfile|
        #next unless logfile.timestamp >= 1573895673

        if logfile.placements?
          if !manual_resets.member?(logfile.timestamp) and prior and logfile.merges_with?(prior)
          else
            p "merge break at #{logfile.timestamp}"
            if current_arc
              current_arc.s_end = logfile.timestamp
            end
            current_arc = Arc.new(0, logfile.timestamp+1, nil, logfile.seed)
            arcs << current_arc
          end

          if prior and false
            gap = (logfile.timestamp - prior.timestamp) / (60.0 * 60.0)
            p "#{prior.approx_log_time} #{gap} #{logfile.approx_log_time}"
            unless (23.99..24.01).member?(gap)
              p "#{gap} gap at #{logfile.timestamp}"
            end
          end

          prior = logfile
        end

        if logfile.seed_only?
          p "seed change at #{logfile.timestamp}"
          if manual_resets.member?(logfile.timestamp)
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
      return arcs
    end
  end
end
