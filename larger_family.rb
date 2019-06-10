require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/graph'
require 'date'

include OHOLFamilyTrees

lives = History.new

dir = "cache/lifeLog_server1.onehouronelife.com"
lives.load_log(dir+"/2018_08August_19_Sunday.txt")
lives.load_names(dir+"/2018_08August_19_Sunday_names.txt")

p lives.length

focus = History.new

# larger family
#target = 1110120
target = 1114108
focus = lives.family(lives[target])

p focus.length

Graph.graph(focus).output(:dot => "larger_family.gv")
