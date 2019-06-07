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
      @coords = parts[5] && parts[5].gsub(/\(|\)/, '').split(',').map(&:to_i)
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
      @coords = parts[6] && parts[6].gsub(/\(|\)/, '').split(',').map(&:to_i)
      @cause = parts[7]
      @population = parts[8]
    end

    attr_reader :age,
      :gender,
      :coords,
      :cause,
      :population

    def killer
      if cause && cause.match('killer')
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
    @playerid = 0
    @parent = Lifelog::NoParent
    @chain = 0
    @lineage = 0
    @age = 0.0
    @cause = "unknown"
  end

  def birth=(birth)
    return unless birth
    @playerid = birth.playerid
    @birth_time = birth.time
    @birth_coords = birth.coords
    @hash = birth.hash
    @parent = birth.parent
    @chain = birth.chain
    @gender = birth.gender
  end

  def death=(death)
    return unless death
    @playerid = death.playerid
    @death_time = death.time
    @death_coords = death.coords
    @hash = death.hash
    @gender = death.gender
    @age = death.age
    @cause = death.cause
    @killer = death.killer
  end

  attr_reader :key

  attr_accessor :highlight
  attr_accessor :player_name
  attr_accessor :lineage
  attr_reader :playerid
  attr_reader :time
  attr_reader :birth_time
  attr_reader :birth_coords
  attr_reader :death_time
  attr_reader :death_coords
  attr_reader :hash
  attr_reader :parent
  attr_reader :chain
  attr_reader :gender
  attr_reader :age
  attr_reader :cause
  attr_reader :killer

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
    birth_time || death_time
  end

  def lifetime
    if birth_time && death_time
      (death_time - birth_time).to_f / 60
    else
      0
    end
  end
end
