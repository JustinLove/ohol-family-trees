require 'ohol-family-trees/curselog_cache'
require 'ohol-family-trees/curselog'
require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/lifelog_cache'
require 'ohol-family-trees/maplog_cache'
require 'ohol-family-trees/maplog'
require 'ohol-family-trees/mirror'
require 'date'
require 'set'
require 'csv'
require 'thor'
require 'logger'

class OneLine < Thor
  include OHOLFamilyTrees

  def initialize(*args)
    super
    @log = Logger.new(STDERR)
    @log.level = Logger.const_get(verbose)
    log.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
  end
  attr_reader :log

  def self.exit_on_failure?
    true
  end

  require 'one_line/cursecount'
  require 'one_line/cursed'
  require 'one_line/cursedby'
  require 'one_line/curseleader'
  require 'one_line/cursers'
  require 'one_line/defcon'
  require 'one_line/fetch'
  require 'one_line/find'
  require 'one_line/idname'
  require 'one_line/scan'
  require 'one_line/tree'

  require 'one_line/options'
end
