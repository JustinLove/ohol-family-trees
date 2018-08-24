require 'lifelog'
require 'graph'

dir = "cache/lifeLog_server1.onehouronelife.com"

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
  focus[cursor.id] = target

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

lives = Hash.new {|h,k| h[k] = Life.new(k)}
#load_dir(dir, lives)
load_log(dir+"/2018_08August_19_Sunday.txt", lives)
load_names(dir+"/2018_08August_19_Sunday_names.txt", lives)

p lives.length

p lives[lives.keys.first].id

focus = {}

#target = 1110120
target = 1114108
focus = add_family(lives[target], lives)

=begin

lives.values.select do |life|
  if life.name == 'LILLY'
    p life
    family = add_family(life, lives)
    p family.length
    focus.merge!(family)
  end
end
=end

p focus.length

Graph.graph(focus).output('test.gv', 'dot')
