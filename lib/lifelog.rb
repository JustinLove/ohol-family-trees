class Lifelog
  module NoParent
    def self.to_s
      'noParent'
    end
  end

  def self.create(line)
    parts = line.split(' ')
    if parts.first == 'B'
      Birth.new(parts)
    elsif parts.first == 'D'
      Death.new(parts)
    else
      p line
      raise "unknown line type #{parts.first}"
    end
  end

  def initialize(parts)
    @time = parts[1].to_i
    @player = parts[2].to_i
    @hash = parts[3]
  end

  attr_reader :time,
    :player,
    :hash

  class Birth < Lifelog
    def initialize(parts)
      super
      @gender = parts[4]
      @coords = parts[5]
      if parts[6].nil? or parts[6] == 'noParent'
        @parent = NoParent
      else
        @parent = parts[6][7..-1].to_i
      end
      @population = parts[7]
      @chain = parts[8]
    end

    attr_reader :gender,
      :coords,
      :parent,
      :population,
      :chain
  end

  class Death < Lifelog
    def initialize(parts)
      super
      @age = parts[4]
      @gender = parts[5]
      @coords = parts[6]
      @cause = parts[7]
      @population = parts[8]
    end

    attr_reader :age,
      :gender,
      :coords,
      :cause,
      :population
  end
end

class Life
  def initialize(id)
    @id = id
  end

  attr_reader :id

  attr_accessor :birth, :death

  def parent
    (birth && birth.parent) || Lifelog::NoParent
  end

  def gender
    (birth && birth.gender) || (death && death.gender)
  end
end
