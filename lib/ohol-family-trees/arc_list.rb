require 'ohol-family-trees/arc'
require 'json'

module OHOLFamilyTrees
  class ArcList
    def arc_path
      "#{output_path}/arcs.json"
    end

    attr_reader :filesystem
    attr_reader :output_path

    def initialize(filesystem, output_path)
      @filesystem = filesystem
      @output_path = output_path
    end

    def [](start)
      arcs[start]
    end

    def <<(arc)
      @arcs[arc.s_start] = arc
    end

    def arcs
      return @arcs if @arcs
      @arcs = {}
      filesystem.read(arc_path) do |f|
        list = JSON.parse(f.read)
        list.each do |jarc|
          self << decode(jarc)
        end
      end
      p @arcs
      @arcs
    end

    def checkpoint
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
      Arc.new(0, jarc['start'], jarc['end'], [jarc['seed'], jarc['seed']].compact)
    end
  end
end

