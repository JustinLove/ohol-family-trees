module OHOLFamilyTrees
  class ObjectData
    def initialize
      @object_size = {}
      @object_over = Hash.new {|h,k| h[k] = TiledPlacementLog::ObjectOver.new(2, 2, 2, 4)}
      @floor_removal = {}
    end

    attr_reader :object_size
    attr_reader :object_over
    attr_reader :floor_removal

    def read!(contents)
      object_master = JSON.parse(contents)

      object_master['ids'].each_with_index do |id,i|
        bounds = object_master['bounds'][i]
        object_over[id] = TiledPlacementLog::ObjectOver.new(*bounds.map {|b| (b/128.0).round.abs})
        object_size[id] = [bounds[2] - bounds[0] - 30, bounds[3] - bounds[1] - 30].min
      end

      object_master['floorRemovals'].each do |transition|
        floor_removal[transition['newTargetID']] = 'f' + transition['targetID']
      end
      self
    end
  end
end
