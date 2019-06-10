require 'nokogiri'
require 'date'

module OHOLFamilyTrees
  ServerStartYear = {
    "server1.onehouronelife.com" => 2018,
    "server2.onehouronelife.com" => 2018,
    "server3.onehouronelife.com" => 2018,
    "server4.onehouronelife.com" => 2018,
    "server5.onehouronelife.com" => 2018,
    "server6.onehouronelife.com" => 2018,
    "server7.onehouronelife.com" => 2018,
    "server8.onehouronelife.com" => 2018,
    "server9.onehouronelife.com" => 2018,
    "server10.onehouronelife.com" => 2018,
    "server11.onehouronelife.com" => 2018,
    "server12.onehouronelife.com" => 2018,
    "server13.onehouronelife.com" => 2018,
    "server14.onehouronelife.com" => 2018,
    "server15.onehouronelife.com" => 2018,
    "bigserver1.onehouronelife.com" => 2019,
    "bigserver2.onehouronelife.com" => 2019,
  }

  class Monument
    attr_accessor :date
    attr_reader :server
    attr_reader :x
    attr_reader :y

    def initialize(node, server, year)
      @server = server
      @date = Date.parse(node.children[3].text + ' ' + year.to_s)
      @x, @y = node.children[5].text.sub("\nLocation: (", '').sub(')', '').split(', ').map(&:to_i)
    end

    def self.load_dir(dir)
      monuments = []
      Dir.foreach(dir) do |path|
        next unless path.match('onehouronelife.com.php')

        p path

        monuments += load_file(File.join(dir, path))
      end
    end

    def self.load_file(path, file)
      server = file.sub('.php','')
      content = File.read(path)

      monuments = []
      year = ServerStartYear[server]
      last_date = nil
      Nokogiri::HTML(content).css('table table table td').each do |node|
        monument = Monument.new(node, server, year)

        if last_date && monument.date < last_date
          year += 1
          monument.date = Date.parse(node.children[3].text + ' ' + year.to_s)
        end
        last_date = monument.date

        monuments << monument
      end

      return monuments
    end
  end
end
