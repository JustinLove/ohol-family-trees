require 'httpclient'
require 'nokogiri'

module OHOLFamilyTrees
  module MonumentServer
    def self.extract_monument_path_list(directory)
      paths = []
      Nokogiri::HTML(directory).css('table table table a').each do |node|
        path = node.attr(:href)
        paths << path
      end

      return paths
    end

    MonumentsUrl = "https://onehouronelife.com/monuments/"

    Client = HTTPClient.new

    class Servers
      include Enumerable

      def initialize(baseurl = MonumentsUrl)
        @baseurl = baseurl
      end

      attr_reader :baseurl

      def each(&block)
        p baseurl
        index = Client.get_content(baseurl)
        #p index
        iter = MonumentServer.extract_monument_path_list(index)
          .select {|dir| dir.match("onehouronelife.com.php")}
          .map {|dir| Logfile.new(dir, baseurl) }
        if block_given?
          iter.each(&block)
        end
      end
    end

    class Logfile
      def initialize(path, baseurl = MonumentsUrl) 
        @path = path
        @baseurl = baseurl
      end

      attr_reader :path
      attr_reader :baseurl

      def url
        baseurl + path
      end

      def server
        path.sub('.php', '')
      end

      def read
        p baseurl + path
        Client.get_content(baseurl + path)
      end
    end
  end
end
