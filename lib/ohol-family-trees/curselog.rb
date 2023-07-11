module OHOLFamilyTrees
  class Curselog
    def self.create(line, epoch = 0, server = '?')
      parts = line.split(' ')
      if parts.first == 'C'
        Curse.new(parts, epoch, server)
      elsif parts.first == 'T'
        Trust.new(parts, epoch, server)
      elsif parts.first == 'F'
        Forgive.new(parts, epoch, server)
      elsif parts.first == 'A' && parts[3] == '=>'
        ForgiveAllEffect.new(parts, epoch, server)
      elsif parts.first == 'A'
        ForgiveAll.new(parts, epoch, server)
      elsif parts.first == 'E'
        Expire.new(parts, epoch, server)
      elsif parts.first == 'S'
        Status.new(parts, epoch, server)
      elsif parts.first == 'START'
        CurseStart.new(parts, epoch, server)
      elsif parts.first == 'STOP'
        CurseStop.new(parts, epoch, server)
      else
        p line
        raise "unknown line type #{parts.first}"
      end
    end

    def self.key(playerid, epoch, server)
      "p#{playerid}e#{epoch}s#{server}"
    end

    def initialize(parts, epoch = 0, server = '?')
      @time = parts[1] && parts[1].to_i
      @epoch = epoch
      @server = server
    end

    attr_reader :time
    attr_reader :epoch
    attr_reader :server
    attr_writer :epoch


    class Relation < Curselog
      def initialize(parts, epoch = 0, server = '?')
        super
        @playerid = parts[2] && parts[2].to_i
        @from_hash = parts[3] && parts[3].tr('^0-9a-f', '')
        @to_hash = parts[5] && parts[5].tr('^0-9a-f', '')
      end

      attr_reader :playerid
      attr_reader :from_hash
      attr_reader :to_hash

      def key
        Lifelog.key(playerid, epoch, server)
      end
    end

    class Curse < Relation
      def net
        1
      end
    end

    class Trust < Relation
    end

    class Forgive < Relation
      def net
        -1
      end
    end

    class ForgiveAll
      def initialize(parts, epoch = 0, server = '?')
        super
        @playerid = parts[2] && parts[2].to_i
        @from_hash = parts[3] && parts[3].tr('^0-9a-f', '')
      end

      attr_reader :playerid
      attr_reader :from_hash

      def key
        Lifelog.key(playerid, epoch, server)
      end
    end

    class LifelessRelation < Curselog
      def initialize(parts, epoch = 0, server = '?')
        super
        @from_hash = parts[2] && parts[2].tr('^0-9a-f', '')
        @to_hash = parts[4] && parts[4].tr('^0-9a-f', '')
      end

      attr_reader :from_hash
      attr_reader :to_hash
    end

    class ForgiveAllEffect < LifelessRelation
      def net
        -1
      end
    end

    class Expire < LifelessRelation
      def net
        -1
      end
    end

    class Status < Curselog
      def initialize(parts, epoch = 0, server = '?')
        super
        @hash = parts[2] && parts[2].tr('^0-9a-f', '')
        @count = parts[3] && parts[3].to_i
      end

      attr_reader :hash
      attr_reader :count
    end

    class CurseStart < Curselog
    end

    class CurseStop < Curselog
    end
  end
end
