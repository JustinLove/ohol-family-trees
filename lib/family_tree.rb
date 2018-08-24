require 'lifelog'
require 'graph'

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

  break
end

p lives.length

p lives[lives.keys.first].id

Graph.graph(lives).output('family_tree.gv', 'dot')
