module OHOLFamilyTrees
  class Maplog
    def self.create(line)
      parts = line.split(' ')
      if (parts[0] == 'startTime:')
        ArcStart.new(parts[1])
      else
        Placement.new(parts)
      end
    end

    class ArcStart < Maplog
      attr_reader :ms_start

      def initialize(start)
        @ms_start = (start.to_f * 1000).to_i
      end

      def s_start
        (ms_start / 1000).floor
      end
    end

    class Placement < Maplog
      attr_reader :ms_offset
      attr_reader :x
      attr_reader :y
      attr_reader :object

      def initialize(parts)
        @ms_offset = (parts[0].to_f * 1000).to_i
        @x = parts[1].to_i
        @y = parts[2].to_i
        @object = parts[3]
      end

      def floor?
        object.start_with?('f')
      end
    end
  end
end
