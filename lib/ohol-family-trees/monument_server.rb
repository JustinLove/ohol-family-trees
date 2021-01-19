require 'httpclient'
require 'nokogiri'

module OHOLFamilyTrees
  module MonumentServer
    BaseUrl = "http://onehouronelife.com/"

    Client = HTTPClient.new

    def self.extract_monument_path_list(directory)
      paths = []
      Nokogiri::HTML(directory).css('table table table a').each do |node|
        path = node.attr(:href)
        paths << path
      end

      return paths
    end

    class Servers
      include Enumerable

      def initialize(baseurl = BaseUrl)
        @baseurl = baseurl
      end

      attr_reader :baseurl

      def each(&block)
        index = Client.get_content(baseurl + "monuments/")
        #p index
        iter = MonumentServer.extract_monument_path_list(index)
          .select {|dir| dir.match("onehouronelife.com.php")}
          .map {|dir| Logfile.new("monuments/" + dir, baseurl) }
        if block_given?
          iter.each(&block)
        end
      end

      def monument_count
        contents = Client.get_content(baseurl + "monumentStats.php")
        if contents && match = contents.match(/(\d+) monuments completed/)
          match[1].to_i
        end
      end
    end

    class Logfile
      def initialize(path, baseurl = BaseUrl) 
        @path = path
        @baseurl = baseurl
      end

      attr_reader :path
      attr_reader :baseurl

      def url
        baseurl + path
      end

      def server
        path.sub('monuments/', '').sub('.php', '')
      end

      def read
        p url
        Client.get_content(url)
      end
    end
  end
end
