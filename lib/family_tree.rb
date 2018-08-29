require 'lifelog'
require 'history'
require 'graph'
require 'date'

lives = History.new

dir = "cache/lifeLog_server1.onehouronelife.com"
#dir = "cache/lifeLog_server7.onehouronelife.com"
lives.load_dir(dir)
#lives.load_log(dir+"/2018_08August_19_Sunday.txt")
#lives.load_names(dir+"/2018_08August_19_Sunday_names.txt")

p lives.length

focus = History.new

# larger family
#target = 1110120
#target = 1114108
#focus = lives.family(lives[target])

#focus = lives

p focus.length

Graph.graph(focus).output('family_tree.gv', 'dot')
