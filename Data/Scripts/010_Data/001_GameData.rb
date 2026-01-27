module GameData
  module SpeciesId
    FUSION_PATTERN = /\AF__(.+)\.(.+)\z/
    COMPOUND_PATTERN = /\A(\d+)_([A-Z0-9]+)\z/
    AUTHOR_INVALID = /[_.]/
    DEFAULT_AUTHOR = "0"

    def self.normalize(value)
      return nil if value.nil?
      return value.id if value.is_a?(GameData::Species)
      if value.is_a?(Symbol)
        key = value.to_s.upcase
        return alias_map[key] if alias_map.key?(key)
        if defined?(FakemonUtility) && FakemonUtility.respond_to?(:resolve_internal_name)
          resolved = FakemonUtility.resolve_internal_name(key)
          return resolved if resolved
        end
        if (match = key.match(COMPOUND_PATTERN))
          local = match[1]
          author = normalize_author(match[2])
          return :"#{local}_#{author}"
        end
        return value
      end
      if value.is_a?(Integer)
        nb_pokemon = (defined?(Settings::NB_POKEMON) ? Settings::NB_POKEMON : nil)
        if nb_pokemon && value > nb_pokemon
          # Legacy numeric fusion ID -> convert to new fusion symbol.
          body_id = (value % nb_pokemon == 0) ? (value / nb_pokemon) - 1 : (value / nb_pokemon).floor
          head_id = (value - (body_id * nb_pokemon)).floor
          head_id = nb_pokemon if head_id == 0
          return build_fusion(official_id(head_id), official_id(body_id))
        end
        return official_id(value)
      end
      if value.is_a?(String)
        key = value.to_s.strip.upcase
        return alias_map[key] if alias_map.key?(key)
        if defined?(FakemonUtility) && FakemonUtility.respond_to?(:resolve_internal_name)
          resolved = FakemonUtility.resolve_internal_name(key)
          return resolved if resolved
        end
        if (match = key.match(COMPOUND_PATTERN))
          local = match[1]
          author = normalize_author(match[2])
          return :"#{local}_#{author}"
        end
        if key.match?(/\A\d+\z/)
          return official_id(key.to_i)
        end
        return key.to_sym
      end
      raise "Species IDs must be symbols or strings (got #{value.class})."
    end

    def self.fusion?(value)
      id = normalize(value)
      return false if id.nil?
      return id.to_s.match?(FUSION_PATTERN)
    end

    def self.split_fusion(value)
      id = normalize(value)
      match = id.to_s.match(FUSION_PATTERN)
      raise "Invalid fusion ID: #{value}" if !match
      head_id = normalize(match[1])
      body_id = normalize(match[2])
      return head_id, body_id
    end

    def self.build_fusion(head_id, body_id)
      head = normalize(head_id).to_s
      body = normalize(body_id).to_s
      return :"F__#{head}.#{body}"
    end

    def self.namespace_and_key(id)
      id_sym = normalize(id)
      return [DEFAULT_AUTHOR, "UNKNOWN"] if id_sym.nil?
      text = id_sym.to_s
      if (match = text.match(COMPOUND_PATTERN))
        local = match[1]
        author = normalize_author(match[2])
        validate_author!(author)
        return [author, local]
      end
      return [DEFAULT_AUTHOR, text]
    end

    def self.local_number(id)
      id_sym = normalize(id)
      return nil if id_sym.nil?
      match = id_sym.to_s.match(/\A(\d+)_/)
      return match ? match[1].to_i : nil
    end

    def self.official_id(number)
      return :"#{number}_#{DEFAULT_AUTHOR}"
    end

    def self.official_fusion_id(body_number, head_number)
      head = official_id(head_number)
      body = official_id(body_number)
      return build_fusion(head, body)
    end

    def self.display_label(id)
      id_sym = normalize(id)
      return "???" if id_sym.nil?
      return "FUSION" if fusion?(id_sym)
      namespace, _key = namespace_and_key(id_sym)
      local = local_number(id_sym)
      return "???" if local.nil?
      return "#{local}_#{namespace}"
    end

    def self.alias_map
      @alias_map ||= begin
        map = {}
        if File.exist?("migration_map.json")
          File.readlines("migration_map.json").each do |line|
            if line =~ /"(\d+)"\s*:\s*"([^"]+)"/
              num = $1.to_i
              name = $2
              next if name.nil? || name.to_s.strip.empty?
              map[name.to_s.upcase] = official_id(num)
            end
          end
        end
        map
      end
    end

    def self.legacy_name_for_number(number)
      return nil if number.nil?
      @legacy_number_map ||= begin
        map = {}
        if File.exist?("migration_map.json")
          File.readlines("migration_map.json").each do |line|
            if line =~ /"(\d+)"\s*:\s*"([^"]+)"/
              num = $1.to_i
              name = $2
              next if name.nil? || name.to_s.strip.empty?
              map[num] = name.to_s.upcase
            end
          end
        end
        map
      end
      name = @legacy_number_map[number.to_i]
      return name ? name.to_sym : nil
    end

    def self.normalize_author(author)
      up = author.to_s.upcase
      return DEFAULT_AUTHOR if up == "OFFICIAL"
      return up
    end

    def self.official_namespace?(author)
      return normalize_author(author) == DEFAULT_AUTHOR
    end

    def self.validate_author!(author)
      raise "Author/namespace cannot contain '_' or '.' (got #{author})." if author.match?(AUTHOR_INVALID)
      return true
    end
  end
  #=============================================================================
  # A mixin module for data classes which provides common class methods (called
  # by GameData::Thing.method) that provide access to data held within.
  # Assumes the data class's data is stored in a class constant hash called DATA.
  # For data that is known by a symbol or an ID number.
  #=============================================================================
  module ClassMethods
    def register(hash)
      @data_by_number ||= {}
      obj = self.new(hash)
      self::DATA[hash[:id]] = obj
      if defined?(GameData::Species) && self == GameData::Species
        id_text = hash[:id].to_s.upcase
        if (match = id_text.match(/\A(\d+)_OFFICIAL\z/))
          self::DATA[:"#{match[1]}_#{GameData::SpeciesId::DEFAULT_AUTHOR}"] = obj
        elsif (match = id_text.match(/\A(\d+)_#{GameData::SpeciesId::DEFAULT_AUTHOR}\z/))
          self::DATA[:"#{match[1]}_OFFICIAL"] = obj
        end
        return
      end
      @data_by_number[hash[:id_number]] = obj if hash[:id_number]
      # Still allow numeric lookup in the main DATA hash for backward compatibility
      # in case code directly accesses DATA[id_number]
      self::DATA[hash[:id_number]] = obj if hash[:id_number]
    end

    def get_by_number(number)
      return nil if number.nil?
      if self == GameData::Species
        raise "Numeric lookup is not supported for Species IDs."
      end
      @data_by_number ||= {}
      if !@data_by_number[number]
        # Fallback: Search in DATA values for matching id_number
        found = self::DATA.values.find { |obj| obj.respond_to?(:id_number) && obj.id_number == number }
        @data_by_number[number] = found if found
      end
      return @data_by_number[number]
    end

    # @param other [Symbol, self, String, Integer]
    # @return [Boolean] whether the given other is defined as a self
    def exists?(other)
      return false if other.nil? || other == 0
      validate other => [Symbol, self, String, Integer, NilClass]
      if self == GameData::Species
        species_id = GameData::SpeciesId.normalize(other)
        return true if self::DATA.has_key?(species_id)
        return true if GameData::SpeciesId.fusion?(species_id)
        return false
      end
      other = other.id if other.is_a?(self)
      other = other.to_sym if other.is_a?(String)
      return true if self::DATA.has_key?(other)

      return false
    end

    # @param other [Symbol, self, String, Integer]
    # @return [self]
    def get(other)
      return nil if other.nil?
      validate other => [Symbol, self, String, Integer, NilClass]

      return other if other.is_a?(self)
      if self == GameData::Species
        species_id = GameData::SpeciesId.normalize(other)
        return GameData::FusedSpecies.new(species_id) if GameData::SpeciesId.fusion?(species_id)
        return self::DATA[species_id] if self::DATA.has_key?(species_id)
        return nil
      end
      other = other.to_sym if other.is_a?(String)
      raise "Unknown ID #{other}." unless self::DATA.has_key?(other)
      return self::DATA[other]
    end

    # @param other [Symbol, self, String, Integer]
    # @return [self, nil]
    def try_get(other)
      return nil if other.nil?
      if self == GameData::Species && other.is_a?(Pokemon)
        other = other.species
      end
      validate other => [Symbol, self, String, Integer]
      return other if other.is_a?(self)
      if self == GameData::Species
        species_id = GameData::SpeciesId.normalize(other)
        return GameData::FusedSpecies.new(species_id) if GameData::SpeciesId.fusion?(species_id)
        return self::DATA[species_id] if self::DATA.has_key?(species_id)
        # Backward compatibility: old data files may still use numeric or
        # legacy internal names for official species.
        if species_id.is_a?(Symbol)
          local = GameData::SpeciesId.local_number(species_id)
          if local
            legacy_name = GameData::SpeciesId.legacy_name_for_number(local)
            return self::DATA[legacy_name] if legacy_name && self::DATA.has_key?(legacy_name)
            return self::DATA[local] if self::DATA.has_key?(local)
          end
        elsif species_id.is_a?(Integer)
          return self::DATA[species_id] if self::DATA.has_key?(species_id)
        end
        return nil
      end
      other = other.to_sym if other.is_a?(String)
      return (self::DATA.has_key?(other)) ? self::DATA[other] : nil
    end

    # Returns the array of keys for the data.
    # @return [Array]
    def keys
      return self::DATA.keys
    end

    # Yields all data in order of their id_number.
    def each
      if self == GameData::Species
        keys = self::DATA.keys.sort { |a, b| a.to_s <=> b.to_s }
        keys.each { |key| yield self::DATA[key] }
        return
      end
      keys = self::DATA.keys.sort { |a, b| self::DATA[a].id_number <=> self::DATA[b].id_number }
      keys.each { |key| yield self::DATA[key] if !key.is_a?(Integer) }
    end

    def load
      filename = self::DATA_FILENAME
      if !safeExists?("Data/" + filename) && safeExists?("Data/" + filename.sub(".dat", " copy.dat"))
        filename = filename.sub(".dat", " copy.dat")
      end
      const_set(:DATA, load_data("Data/#{filename}"))
    end

    def save
      save_data(self::DATA, "Data/#{self::DATA_FILENAME}")
    end
  end

  #=============================================================================
  # A mixin module for data classes which provides common class methods (called
  # by GameData::Thing.method) that provide access to data held within.
  # Assumes the data class's data is stored in a class constant hash called DATA.
  # For data that is only known by a symbol.
  #=============================================================================
  module ClassMethodsSymbols
    def register(hash)
      self::DATA[hash[:id]] = self.new(hash)
    end

    # @param other [Symbol, self, String]
    # @return [Boolean] whether the given other is defined as a self
    def exists?(other)
      return false if other.nil?
      validate other => [Symbol, self, String]
      other = other.id if other.is_a?(self)
      other = other.to_sym if other.is_a?(String)
      return !self::DATA[other].nil?
    end

    # @param other [Symbol, self, String]
    # @return [self]
    def get(other)
      validate other => [Symbol, self, String]
      return other if other.is_a?(self)
      other = other.to_sym if other.is_a?(String)
      raise "Unknown ID #{other}." unless self::DATA.has_key?(other)
      return self::DATA[other]
    end

    # @param other [Symbol, self, String]
    # @return [self, nil]
    def try_get(other)
      return nil if other.nil?
      validate other => [Symbol, self, String]
      return other if other.is_a?(self)
      other = other.to_sym if other.is_a?(String)
      return (self::DATA.has_key?(other)) ? self::DATA[other] : nil
    end

    # Returns the array of keys for the data.
    # @return [Array]
    def keys
      return self::DATA.keys
    end

    # Yields all data in alphabetical order.
    def each
      keys = self::DATA.keys.sort { |a, b| self::DATA[a].real_name <=> self::DATA[b].real_name }
      keys.each { |key| yield self::DATA[key] }
    end

    def load
      filename = self::DATA_FILENAME
      if !safeExists?("Data/" + filename) && safeExists?("Data/" + filename.sub(".dat", " copy.dat"))
        filename = filename.sub(".dat", " copy.dat")
      end
      const_set(:DATA, load_data("Data/#{filename}"))
    end

    def save
      save_data(self::DATA, "Data/#{self::DATA_FILENAME}")
    end
  end

  #=============================================================================
  # A mixin module for data classes which provides common class methods (called
  # by GameData::Thing.method) that provide access to data held within.
  # Assumes the data class's data is stored in a class constant hash called DATA.
  # For data that is only known by an ID number.
  #=============================================================================
  module ClassMethodsIDNumbers
    def register(hash)
      self::DATA[hash[:id]] = self.new(hash)
    end

    # @param other [self, Integer]
    # @return [Boolean] whether the given other is defined as a self
    def exists?(other)
      return false if other.nil?
      validate other => [self, Integer]
      other = other.id if other.is_a?(self)
      return !self::DATA[other].nil?
    end

    # @param other [self, Integer]
    # @return [self]
    def get(other)
      validate other => [self, Integer]
      return other if other.is_a?(self)
      # Backward compatibility: return nil instead of raising if ID is missing.
      return nil unless self::DATA.has_key?(other)
      return self::DATA[other]
    end

    def try_get(other)
      return nil if other.nil?
      validate other => [self, Integer]
      return other if other.is_a?(self)
      return (self::DATA.has_key?(other)) ? self::DATA[other] : nil
    end

    # Returns the array of keys for the data.
    # @return [Array]
    def keys
      return self::DATA.keys
    end

    # Yields all data in numberical order.
    def each
      keys = self::DATA.keys.sort
      keys.each { |key| yield self::DATA[key] }
    end

    def load
      filename = self::DATA_FILENAME
      if !safeExists?("Data/" + filename) && safeExists?("Data/" + filename.sub(".dat", " copy.dat"))
        filename = filename.sub(".dat", " copy.dat")
      end
      const_set(:DATA, load_data("Data/#{filename}"))
    end

    def save
      save_data(self::DATA, "Data/#{self::DATA_FILENAME}")
    end
  end

  #=============================================================================
  # A mixin module for data classes which provides common instance methods
  # (called by thing.method) that analyse the data of a particular thing which
  # the instance represents.
  #=============================================================================
  module InstanceMethods
    # @param other [Symbol, self.class, String, Integer]
    # @return [Boolean] whether other represents the same thing as this thing
    def ==(other)
      return false if other.nil?
      if other.is_a?(Symbol)
        return @id == other
      elsif other.is_a?(self.class)
        return @id == other.id
      elsif other.is_a?(String)
        return @id_number == other.to_sym
      elsif other.is_a?(Integer)
        return @id_number == other
      end
      return false
    end
  end

  #=============================================================================
  # A bulk loader method for all data stored in .dat files in the Data folder.
  #=============================================================================
  def self.load_all
    Type.load
    Ability.load
    Move.load
    Item.load
    BerryPlant.load
    Species.load
    Ribbon.load
    Encounter.load
    EncounterModern.load
    EncounterRandom.load
    TrainerType.load
    Trainer.load
    TrainerModern.load
    TrainerExpert.load
    Metadata.load
    MapMetadata.load

    #Sylvi Items

    # I just put item data here unless we get a better system for this
    # Use ID numbers 1000 and above!!
    # https://essentialsdocs.fandom.com/wiki/Defining_an_item?oldid=1031#PBS_file_%22items.txt%22

    #Item.register({
    #  :id               => :MARIO,
    #  :id_number        => 1000,
    #  :name             => "Mario",
    #  :name_plural      => "Marios",
    #  :pocket           => 1,
    #  :price            => 1000,
    #  :description      => "A Mario.",
    #  :field_use        => 1,
    #  :battle_use       => 0,
    #  :type             => 7,
    #  :move             => nil
    #})
    #MessageTypes.set(MessageTypes::Items,            1000, "Mario")
    #MessageTypes.set(MessageTypes::ItemPlurals,      1000, "Marios")
    #MessageTypes.set(MessageTypes::ItemDescriptions, 1000, "A Mario.")
    
    # Item.register({
    #  :id               => :HPREINFORCER,
    #  :id_number        => 2000,
    #  :name             => "HP Reinforcer",
    #  :name_plural      => "HP Reinforcers",
    #  :pocket           => 1,
    #  :price            => 1000,
    #  :description      => "A Mario.",
    #  :field_use        => 1,
    #  :battle_use       => 0,
    #  :type             => 7,
    #  :move             => nil
    # })
    # MessageTypes.set(MessageTypes::Items,            1000, "Mario")
    # MessageTypes.set(MessageTypes::ItemPlurals,      1000, "Marios")
    # MessageTypes.set(MessageTypes::ItemDescriptions, 1000, "A Mario.")

    # _INTL("Items"),
    # _INTL("Medicine"),
    # _INTL("Poké Balls"),
    # _INTL("TMs & HMs"),
    # _INTL("Berries"),
    # _INTL("Mail"),
    # _INTL("Battle Items"),
    # _INTL("Key Items")
  end
end
