require 'ohol-family-trees/arc'
require 'json'

module OHOLFamilyTrees
  class ArcList
    attr_reader :arcs

    def initialize
      @arcs = {}
    end

    def [](start)
      arcs[start]
    end

    def <<(arc)
      arcs[arc.s_start] = arc
    end

    def arc_at(timestamp)
      candidates = arcs.values
        .select {|arc| arc.s_start <= timestamp && (arc.s_end.nil? || timestamp <= arc.s_end)}
        .sort_by {|arc| arc.s_end || arc.s_start}
      #p candidates.map {|arc| arc.s_end || arc.s_start}
      candidates.last
    end

    def load(filesystem, arc_path)
      @arcs = {}
      filesystem.read(arc_path) do |f|
        list = JSON.parse(f.read)
        list.each do |jarc|
          arc = decode(jarc)
          @arcs[arc.s_start] = arc
        end
      end
      #p @arcs
      @arcs
    end

    def save(filesystem, arc_path)
      filesystem.write(arc_path) do |f|
        f << JSON.pretty_generate(arcs.values
            .sort_by(&:s_start)
            .map {|arc| encode(arc) })
      end
    end

    def encode(arc)
      {
        'start' => arc.s_start,
        'end' => arc.s_end,
        'seed' => arc.seed[0],
        'seed2' => arc.seed[1],
      }
    end

    def decode(jarc)
      Arc.new(0, jarc['start'], jarc['end'], [jarc['seed'], jarc['seed2']].compact)
    end
  end
end

