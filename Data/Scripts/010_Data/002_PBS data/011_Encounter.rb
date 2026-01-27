module GameData
  class Encounter
    attr_accessor :id
    attr_accessor :map
    attr_accessor :version

    attr_reader :step_chances
    attr_reader :types

    DATA = {}
    DATA_FILENAME = "encounters.dat"

    extend ClassMethodsSymbols
    include InstanceMethods

    # @param map_id [Integer]
    # @param map_version [Integer, nil]
    # @return [Boolean] whether there is encounter data for the given map ID/version
    def self.exists?(map_id, map_version = 0)
      validate map_id => [Integer]
      validate map_version => [Integer]
      key = sprintf("%s_%d", map_id, map_version).to_sym
      return !self::DATA[key].nil?
    end

    # @param map_id [Integer]
    # @param map_version [Integer, nil]
    # @return [self, nil]
    def self.get(map_id, map_version = 0)
      validate map_id => Integer
      validate map_version => Integer
      inject_fakemon_encounters!
      trial_key = sprintf("%s_%d", map_id, map_version).to_sym
      key = (self::DATA.has_key?(trial_key)) ? trial_key : sprintf("%s_0", map_id).to_sym
      return self::DATA[key]
    end

    def self.inject_fakemon_encounters!
      return if @fakemon_injected
      @fakemon_injected = true
      species_id = GameData::SpeciesId.normalize(:FAKEMON2) ||
                   GameData::SpeciesId.normalize("2_FAKEMON")
      min_level = 2
      max_level = 5
      chance = 20
      injected = 0
      touched = 0
      self::DATA.each_value do |encounter|
        next if !encounter || !encounter.types
        encounter.types.each do |enc_type, slots|
          next if !slots || slots.empty?
          type_data = GameData::EncounterType.try_get(enc_type)
          next if !type_data || type_data.type != :land
          touched += 1
          already = slots.any? do |slot|
            slot_species = slot.is_a?(Array) ? slot[1] : nil
            slot_species = slot[0] if slot.is_a?(Array) && slot.length == 3
            GameData::SpeciesId.normalize(slot_species) == species_id
          end
          next if already
          if slots.first.is_a?(Array) && slots.first.length >= 4
            slots << [chance, species_id, min_level, max_level]
            injected += 1
          elsif slots.first.is_a?(Array) && slots.first.length == 3
            slots << [species_id, min_level, max_level]
            injected += 1
          end
        end
      end
      echoln "Fakemon encounters injected: #{injected}/#{touched} land tables" if $DEBUG
    end

    # Yields all encounter data in order of their map and version numbers.
    def self.each
      keys = self::DATA.keys.sort do |a, b|
        if self::DATA[a].map == self::DATA[b].map
          self::DATA[a].version <=> self::DATA[b].version
        else
          self::DATA[a].map <=> self::DATA[b].map
        end
      end
      keys.each { |key| yield self::DATA[key] }
    end

    # Yields all encounter data for the given version. Also yields encounter
    # data for version 0 of a map if that map doesn't have encounter data for
    # the given version.
    def self.each_of_version(version = 0)
      self.each do |data|
        yield data if data.version == version
        if version > 0
          yield data if data.version == 0 && !self::DATA.has_key?([data.map, version])
        end
      end
    end

    def initialize(hash)
      @id           = hash[:id]
      @map          = hash[:map]
      @version      = hash[:version]      || 0
      @step_chances = hash[:step_chances]
      @types        = hash[:types]        || {}
    end
  end
end

#===============================================================================
# Deprecated methods
#===============================================================================
# @deprecated This alias is slated to be removed in v20.
def pbLoadEncountersData
  Deprecation.warn_method('pbLoadEncountersData', 'v20', 'GameData::Encounter.get(map_id, version)')
  return nil
end
