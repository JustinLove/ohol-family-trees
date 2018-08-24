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

def load_dir(dir, lives)
  Dir.foreach(dir) do |path|
    next unless path.match(/\d{4}_\d{2}/) and not path.match('_names.txt')
    p path

    load_log(File.join(dir, path), lives)
  end
end

lives = Hash.new {|h,k| h[k] = Life.new(k)}
#load_dir(dir, lives)
load_log(dir+"/2018_08August_19_Sunday.txt", lives)

p lives.length

p lives[lives.keys.first].id

# 1110120

Graph.graph(lives).output('family_tree.gv', 'dot')
