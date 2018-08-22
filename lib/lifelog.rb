class Lifelog
  module NoParent; end

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
end

lives = Hash.new {|h,k| h[k] = Life.new(k)}

dir = "cache/lifeLog_server1.onehouronelife.com"
Dir.foreach(dir) do |path|
  next unless path.match(/\d{4}_\d{2}/) and not path.match('_names.txt')

  p path

  lines = File.open(File.join(dir, path), "r", :external_encoding => 'ASCII-8BIT') {|f| f.readlines}

  lines.each do |line|
    log = Lifelog.create(line)

    if log.kind_of?(Lifelog::Birth)
      lives[log.player].birth = log
    else
      lives[log.player].death = log
    end
  end
end
#lines = File.open("cache/lifeLog_server1.onehouronelife.com/2018_03March_09_Friday.txt", "r") {|f| f.readlines}

p lives.length
