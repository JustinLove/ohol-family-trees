class OneLine
  desc 'fetch [all/lives/maps/monuments]', 'download logs to local cache for other commands.'
  option :publicdata, :type => :string, :desc => 'public data url', :default => Mirror::PublicDataUrl
  def fetch(what='all')
    mirror.lives if what == 'lives' || what == 'all'
    mirror.maps if what == 'maps' || what == 'all'
    mirror.monuments if what == 'monuments' || what == 'all'
  end

  private

  def publicdata
    options[:publicdata]
  end

  def mirror
    @Mirror ||= Mirror.new(log, publicdata, cache)
  end
end
