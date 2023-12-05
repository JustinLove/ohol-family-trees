class OneLine
  desc 'fetch [all/lives/food/maps/monuments/bells]', 'download logs to local cache for other commands. Shorthand any combo of lmb'
  option :publicdata, :type => :string, :desc => 'public data url', :default => Mirror::PublicDataUrl
  option :check_all, :type => :boolean, :desc => 'check all files, not just the most recent', :default => false
  def fetch(what='all')
    l, m, b, f = false, false, false, false
    if what.match(/^[lmb]+$/)
      l = what.match('l')
      m = what.match('m')
      f = what.match('f')
      b = what.match('b')
    end
    l = true if what == 'lives' || what == 'all'
    m = true if what == 'maps' || what == 'all'
    b = true if what == 'monuments' || what == 'bells' || what == 'all'
    f = true if what == 'food' || what == 'all'
    mirror.lives if l
    mirror.food if f
    mirror.monuments if b
    mirror.maps if m
  end

  private

  def publicdata
    options[:publicdata]
  end

  def check_all
    options[:check_all]
  end

  def mirror
    @Mirror ||= Mirror.new(log, publicdata, cache, check_all)
  end
end
