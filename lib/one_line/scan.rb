class OneLine
  desc 'scan @x,y', 'report activity in a map area'
  option :r, :type => :numeric, :desc => 'search radius', :default => 0
  option :dx, :type => :numeric, :desc => 'x search radius'
  option :dy, :type => :numeric, :desc => 'y search radius'
  option :objects, :type => :string, :desc => 'objects 1,2,3', :default => ''
  def scan(coords)
    actors = Set.new
    x,y = *coords.sub('@', '').split(',').map(&:to_i)
    dx = (options[:dx] || options[:r]).to_i
    dy = (options[:dy] || options[:r]).to_i
    xr = (x-dx)..(x+dx)
    yr = (y-dy)..(y+dy)
    p xr, yr

    objects = options[:objects].split(',')

    matching_placements do |log|
      if xr.cover?(log.x) && yr.cover?(log.y) && (objects.empty? || objects.include?(log.object))
        p [log.object, log.x, log.y, log.actor, log.s_time]
        actors << log.actor
      end
    end

    print_actors(actors)
  end
end
