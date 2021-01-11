class OneLine
  desc 'fetch [all/livesl/maps/monuments/bells]', 'download logs to local cache for other commands. Shorthand any combo of lmb'
  option :publicdata, :type => :string, :desc => 'public data url', :default => Mirror::PublicDataUrl
  def fetch(what='all')
    l, m, b = false, false, false
    if what.match(/^[lmb]+$/)
      l = what.match('l')
      m = what.match('m')
      b = what.match('b')
    end
    l = true if what == 'lives' || what == 'all'
    m = true if what == 'maps' || what == 'all'
    b = true if what == 'monuments' || what == 'bells' || what == 'all'
    mirror.lives if l
    mirror.maps if m
    mirror.monuments if b
  end

  private

  def publicdata
    options[:publicdata]
  end

  def mirror
    @Mirror ||= Mirror.new(log, publicdata, cache)
  end
end
