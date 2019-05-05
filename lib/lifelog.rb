class Lifelog
  module NoParent
    def self.to_s
      'noParent'
    end
  end

  def self.create(line, epoch = 0, server = '?')
    parts = line.split(' ')
    if parts.first == 'B'
      Birth.new(parts, epoch, server)
    elsif parts.first == 'D'
      Death.new(parts, epoch, server)
    else
      p line
      raise "unknown line type #{parts.first}"
    end
  end

  def self.key(playerid, epoch, server)
    "p#{playerid}e#{epoch}s#{server}"
  end

  def initialize(parts, epoch = 0, server = '?')
    @time = parts[1].to_i
    @playerid = parts[2].to_i
    @hash = parts[3]
    @epoch = epoch
    @server = server
  end

  attr_reader :time,
    :playerid,
    :hash,
    :epoch,
    :server
  attr_writer :epoch

  def key
    Lifelog.key(playerid, epoch, server)
  end

  class Birth < Lifelog
    def initialize(parts, epoch = 0, server = '?')
      super
      @gender = parts[4]
      @coords = parts[5] && parts[5].gsub(/\(|\)/, '').split(',')
      if parts[6].nil? or parts[6] == 'noParent'
        @parent = NoParent
      else
        @parent = parts[6][7..-1].to_i
      end
      @population = parts[7]
      @chain = parts[8] && parts[8][6..-1].to_i
    end

    attr_reader :gender,
      :coords,
      :population,
      :chain

    def parent
      if @parent == NoParent
        return NoParent
      else
        Lifelog.key(@parent, epoch, server)
      end
    end
  end

  class Death < Lifelog
    def initialize(parts, epoch = 0, server = '?')
      super
      @age = parts[4] && parts[4][4..-1].to_f
      @gender = parts[5]
      @coords = parts[6] && parts[6].gsub(/\(|\)/, '').split(',')
      @cause = parts[7]
      @population = parts[8]
    end

    attr_reader :age,
      :gender,
      :coords,
      :cause,
      :population

    def killer
      if cause.match('killer')
        pid = cause.sub('killer_', '')
        Lifelog.key(pid, epoch, server)
      end
    end
  end
end

class Namelog
  def initialize(line)
    parts = line.split(' ')
    @playerid = parts.shift.to_i
    @name = parts.join(' ')
  end

  attr_reader :playerid, :name
end

class Life
  def initialize(key)
    @key = key
  end

  attr_reader :key

  attr_accessor :birth, :death
  attr_accessor :highlight
  attr_accessor :player_name

  def playerid
    (birth && birth.playerid) || (death && death.playerid) || 0
  end

  def name=(text)
    @name = text
  end

  def name
    @name || ('p' + playerid.to_s)
  end

  def name_or_blank
    @name
  end

  def time
    (birth && birth.time) || (death && death.time) || 0
  end

  def hash
    (birth && birth.hash) || (death && death.hash)
  end

  def parent
    (birth && birth.parent) || Lifelog::NoParent
  end

  def chain
    (birth && birth.chain) || 0
  end

  def gender
    (birth && birth.gender) || (death && death.gender)
  end

  def age
    (death && death.age) || 0.0
  end

  def lifetime
    if birth && death
      (death.time - birth.time).to_f / 60
    else
      0
    end
  end

  def cause
    (death && death.cause) || "unknown"
  end

  def killer
    (death && death.killer)
  end
end
