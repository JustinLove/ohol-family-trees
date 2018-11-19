require 'lifelog'

class History
  def initialize
    @lives = Hash.new {|h,k| h[k] = Life.new(k)}
  end

  attr_reader :lives

  def [](key)
    @lives[key]
  end

  def []=(key, value)
    @lives[key] = value
  end

  def length
    @lives.length
  end

  def merge!(other)
    @lives.merge!(other.lives)
  end

  def select(&block)
    @lives.values.select(&block)
  end

  def each(&block)
    @lives.values.each(&block)
  end

  def include?(key)
    @lives.include?(key)
  end

  def load_log(path)
    lines = File.open(path, "r", :external_encoding => 'ASCII-8BIT') {|f| f.readlines}

    lines.each do |line|
      log = Lifelog.create(line)

      if log.kind_of?(Lifelog::Birth)
        lives[log.player].birth = log
      else
        lives[log.player].death = log
      end
    end
  end

  def load_names(path)
    lines = File.open(path, "r", :external_encoding => 'ASCII-8BIT') {|f| f.readlines}

    lines.each do |line|
      namelog = Namelog.new(line)

      lives[namelog.id].name = namelog.name
    end
  end

  def load_dir(dir, time_range = (Time.at(0)..Time.now))
    Dir.foreach(dir) do |path|
      dateparts = path.match(/(\d{4})_(\d{2})\w+_(\d{2})/)
      next unless dateparts

      approx_log_time = Time.gm(dateparts[1], dateparts[2], dateparts[3])
      next unless time_range.cover?(approx_log_time)

      p path

      if path.match('_names.txt')
        load_names(File.join(dir, path))
      else
        load_log(File.join(dir, path))
      end

    end
  end

  def ancestors(target)
    cursor = target
    lineage = [target]
    while cursor && lives[cursor.parent] && cursor.parent != Lifelog::NoParent
      cursor = lives[cursor.parent]
      lineage << cursor
    end

    return lineage
  end

  def family(target)
    cursor = target
    while cursor && lives[cursor.parent] && cursor.parent != Lifelog::NoParent
      cursor = lives[cursor.parent]
    end

    focus = History.new
    focus[cursor.id] = cursor

    count = 0
    while focus.length > count
      count = focus.length
      lives.values.each do |life|
        if focus.include?(life.parent)
          focus[life.id] = life
        end
      end
    end

    return focus
  end
end
