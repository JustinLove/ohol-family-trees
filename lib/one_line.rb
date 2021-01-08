require 'ohol-family-trees/lifelog'
require 'ohol-family-trees/history'
require 'ohol-family-trees/lifelog_cache'
require 'date'
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

  require 'one_line/find'

  require 'one_line/options'
end
