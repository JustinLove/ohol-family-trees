module OHOLFamilyTrees
  class TileSet
    attr_reader :tiles
    attr_reader :index
    attr_reader :loader

    def initialize(index = [], loader = nil)
      @tiles = {}
      @index = index.map {|tilex,tiley,time| [[tilex, tiley], time]}.to_h
      @loader = loader
    end

    def [](coords)
      tiles[coords] ||= load_tile(coords) || Tile.new(coords, 0)
    end

    def []=(coords, tile)
      tiles[coords] = tile
    end

    def load_tile(coords)
      if loader && index[coords]
        loader.read(coords, index[coords]).copy
      end
    end

    def at(tilex, tiley, time)
      coords = [tilex, tiley]
      tiles[coords] = Tile.new(coords, time)
    end

    def updated_tiles
      tiles.select {|_,tile| tile.updated}
    end

    def tile_index(s_end)
      index.merge(tiles.values.reject(&:empty?).map {|tile|
        [tile.coords,(tile.updated ? s_end : tile.time)]
      }.to_h).map(&:flatten)
    end

    def placements
      tiles.transform_values {|tile| tile.placements}
    end

    def copy_key(previous)
      @index = previous.index
      @loader = previous.loader
      previous.tiles.each_pair {|coords, tile| tiles[coords] = tile.copy }
      self
    end

  end

  class Tile
    attr_reader :floors
    attr_reader :objects
    attr_reader :placements

    attr_reader :updated
    attr_reader :coords
    attr_reader :time

    def initialize(cor, t)
      @updated = false
      @coords = cor
      @time = t
      @floors = {}
      @objects = {}
      @placements = []
    end

    def copy_key(tile)
      @coords = tile.coords
      @floors = tile.floors
      @objects = tile.objects
      self
    end

    def copy
      self.class.new(coords, time).copy_key(self)
    end

    def empty?
      floors.empty? && objects.empty?
    end

    def tilex
      coords[0]
    end

    def tiley
      coords[1]
    end

    def floor(x, y)
      floors["#{x} #{y}"]
    end

    def remove_floor(x, y)
      @updated = true
      floors.delete("#{x} #{y}")
    end

    def set_floor(x, y, object)
      @updated = true
      floors["#{x} #{y}"] = object
    end

    def object(x, y)
      objects["#{x} #{y}"]
    end

    def set_object(x, y, object)
      @updated = true
      objects["#{x} #{y}"] = object
    end

    def add_placement(log)
      placements << log
    end
  end
end
