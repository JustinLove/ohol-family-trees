require 'lifelog'
require 'graph'
require 'date'

def load_log(path, lives)
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

def load_names(path, lives)
  lines = File.open(path, "r", :external_encoding => 'ASCII-8BIT') {|f| f.readlines}

  lines.each do |line|
    namelog = Namelog.new(line)

    lives[namelog.id].name = namelog.name
  end
end

def load_dir(dir, lives)
  Dir.foreach(dir) do |path|
    next unless path.match(/\d{4}_\d{2}/)

    p path

    if path.match('_names.txt')
      load_names(File.join(dir, path), lives)
    else
      load_log(File.join(dir, path), lives)
    end

  end
end

def add_family(target, lives)
  cursor = target
  while cursor && lives[cursor.parent] && cursor.parent != Lifelog::NoParent
    cursor = lives[cursor.parent]
  end

  focus = {}
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

def ancestors(target, lives)
  cursor = target
  lineage = [target]
  while cursor && lives[cursor.parent] && cursor.parent != Lifelog::NoParent
    cursor = lives[cursor.parent]
    lineage << cursor
  end

  return lineage
end

# boots family
#dir = "cache/lifeLog_server7.onehouronelife.com"
#load_dir(dir, lives)
#target = 6897
#focus = add_family(lives[target], lives)

dir = "cache/lifeLog_server1.onehouronelife.com"
#dir = "cache/lifeLog_server7.onehouronelife.com"
lives = Hash.new {|h,k| h[k] = Life.new(k)}
load_dir(dir, lives)
#load_log(dir+"/2018_08August_19_Sunday.txt", lives)
#load_names(dir+"/2018_08August_19_Sunday_names.txt", lives)

p lives.length

p lives[lives.keys.first].id

focus = {}

# larger family
#target = 1110120
#target = 1114108
#focus = add_family(lives[target], lives)

# small family
#target = 1109187
#focus = add_family(lives[target], lives)

# small named family
#target = 1110334
#focus = add_family(lives[target], lives)

wondible = 'e45aa4e489b35b6b0fd9f59f0049c688237a9a86'

#focus = lives

=begin

lives.values.select do |life|
  if life.name == 'LILLY'
    p life
    family = add_family(life, lives)
    p family.length
    focus.merge!(family)
  end
end

from = (Date.today << 4).to_time.to_i
to = (Date.today << 2).to_time.to_i


lives.values.select do |life|
  if life.time > from && life.time < to && life.name == 'LILLY'
    lineage = ancestors(life, lives)
    if lineage[1] && lineage[1].name == 'ANA' && lineage[-1].name == 'EVE WEST'
      p life
      p Time.at(life.time)
      p Time.at(lineage[-1].time)
      p life.id
      p lineage.map(&:name).join(', ')
      family = add_family(life, lives)
      #p family.length
      focus.merge!(family)
    end
  end
end

lives.values.select do |life|
  if life.hash == wondible
    life.highlight = true
    p [life.id, life.name, Time.at(life.time)]
    if life.parent == Lifelog::NoParent
      family = add_family(life, lives)
      focus.merge!(family)
    end
  end
end
=end

from = (Date.today - 8).to_time.to_i

lives.values.select do |life|
  if life.hash == wondible
    life.highlight = true
    p [life.id, life.name, Time.at(life.time)]
    if life.time > from
      family = add_family(life, lives)
      focus.merge!(family)
    end
  end
end

p focus.length

Graph.graph(focus).output('family_tree.gv', 'dot')
