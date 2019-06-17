require 'nokogiri'
require 'date'

module OHOLFamilyTrees
  class Monument
    attr_accessor :date
    attr_reader :server
    attr_reader :x
    attr_reader :y

    def initialize(node, server)
      @server = server
      @date = DateTime.parse(node.children[3].text)
      @x, @y = node.children[5].text.sub("\nLocation: (", '').sub(')', '').split(', ').map(&:to_i)
    end

    def self.load_log(logfile)
      server = logfile.server
      content = logfile.read

      monuments = []
      Nokogiri::HTML(content).css('table table table td').each do |node|
        monument = Monument.new(node, server)
        monuments << monument
      end

      return monuments
    end
  end
end
