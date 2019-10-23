module OHOLFamilyTrees
  class Maplog
    def self.create(line)
      parts = line.split(' ')
      if parts[0] == 'startTime:'
        ArcStart.new(parts[1])
      elsif parts.length == 4
        Placement.new(parts)
      elsif line.match('startTime:')
        ArcStart.new(parts[parts.length-1])
      else
        p ['invalid maplog line', line]
        nil
      end
    end

    class ArcStart < Maplog
      attr_reader :ms_start

      def initialize(start)
        @ms_start = (start.to_f * 1000).to_i
      end

      def s_start
        (ms_start.to_f / 1000).ceil
      end
    end

    class Placement < Maplog
      attr_reader :ms_offset
      attr_reader :x
      attr_reader :y
      attr_accessor :object
      attr_accessor :ms_start

      def initialize(parts)
        @ms_offset = (parts[0].to_f * 1000).to_i
        @x = parts[1].to_i
        @y = parts[2].to_i
        @object = parts[3]
        @ms_start = 0
      end

      def floor?
        object.start_with?('f')
      end

      def id
        object.sub('f', '').split(/\D/).first
      end

      def s_offset
        (ms_offset.to_f / 1000).ceil
      end

      def ms_time
        ms_start + ms_offset
      end

      def s_time
        (ms_time.to_f / 1000).ceil
      end

      def self.id(object)
        object.sub('f', '').split(/\D/).first
      end
    end
  end
end
