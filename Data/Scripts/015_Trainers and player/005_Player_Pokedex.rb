class Player < Trainer
  # Represents the player's Pokédex.
  class Pokedex
    # @return [Array<Integer>] an array of accessible Dexes
    # @see #refresh_accessible_dexes
    attr_reader :accessible_dexes

    def inspect
      str = super.chop
      str << format(' seen: %d, owned: %d>', self.seen_count, self.owned_count)
      return str
    end

    # Creates an empty Pokédex.
    def initialize
      @unlocked_dexes = []
      0.upto(pbLoadRegionalDexes.length) do |i|
        @unlocked_dexes[i] = (i == 0)
      end
      self.clear
    end

    # Clears the Pokédex.
    def clear
      @seen_standard = {}
      @seen_fusion = {}
      @seen_triple = {}

      @owned_standard = {}
      @owned_fusion = {}
      @owned_triple = {}

      @seen_forms = {}
      @last_seen_forms = {}
      @owned_shadow = {}
      self.refresh_accessible_dexes
    end

    def initStandardDexArray()
      return {}
    end

    def initFusionDexArray()
      return {}
    end

    def resync_pokedex
      echoln "Syncing Pokedex to new structured format..."
      @seen_standard = migrate_pokedex_hash(@seen_standard, :standard)
      @owned_standard = migrate_pokedex_hash(@owned_standard, :standard)

      @seen_fusion = migrate_pokedex_hash(@seen_fusion, :fusion)
      @owned_fusion = migrate_pokedex_hash(@owned_fusion, :fusion)
    end

    def migrate_pokedex_hash(old_data, type)
      return {} if old_data.nil?
      return old_data if old_data.is_a?(Hash) && !old_data.keys.any? { |k| k.is_a?(Integer) }

      new_data = {}
      if type == :standard
        if old_data.is_a?(Array)
          old_data.each_with_index do |seen, i|
            next if !seen || i == 0
            species_id = GameData::SpeciesId.official_id(i)
            new_data[species_id] = true
          end
        elsif old_data.is_a?(Hash)
          old_data.each do |k, v|
            next unless v
            if k.is_a?(Integer)
              species_id = GameData::SpeciesId.official_id(k)
              new_data[species_id] = true
            else
              new_data[k] = true
            end
          end
        end
      elsif type == :fusion
        if old_data.is_a?(Array)
          old_data.each_with_index do |bodies, h|
            next if !bodies || h == 0
            bodies.each_with_index do |seen, b|
              next if !seen || b == 0
              fusion_id = GameData::SpeciesId.build_fusion(
                GameData::SpeciesId.official_id(h),
                GameData::SpeciesId.official_id(b)
              )
              new_data[fusion_id] = true
            end
          end
        elsif old_data.is_a?(Hash)
          old_data.each do |k, v|
            if v.is_a?(Hash)
              v.each do |b_id, b_val|
                next unless b_val
                head_id = k.is_a?(Integer) ? GameData::SpeciesId.official_id(k) : k
                body_id = b_id.is_a?(Integer) ? GameData::SpeciesId.official_id(b_id) : b_id
                fusion_id = GameData::SpeciesId.build_fusion(head_id, body_id)
                new_data[fusion_id] = true
              end
            elsif v
              new_data[k] = true
            end
          end
        end
      end
      return new_data
    end

    def isTripleFusion(num)
      return isTripleFusion?(num)
    end

    def isTripleFusion?(num)
      return num.is_a?(Integer) && num >= Settings::ZAPMOLCUNO_NB
    end

    def isFusion(num)
      return species_is_fusion(num)
    end

    def resyncPokedexIfNumberOfPokemonChanged()
      # No longer needed to check length as we use Hashes
      # but we check if we need to migrate from Arrays
      if @seen_standard.is_a?(Array) || @seen_fusion.is_a?(Array)
        resync_pokedex()
      end
    end

    def verify_dex_is_correct_length(current_dex)

      expected_length = 509 + 2
      return current_dex.length == expected_length
    end

    def set_seen_fusion(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return if species_obj.nil?
      species_id = species_obj.id
      @seen_fusion[species_id] = true
    end

    def set_seen_normalDex(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return if species_obj.nil?
      species_id = species_obj.id
      @seen_standard[species_id] = true
    end

    def set_seen_triple(species)
      if species.is_a?(Pokemon)
        species_id = species.species
      else
        species_id = GameData::Species.try_get(species)&.species
      end
      return if species_id.nil?
      @seen_triple[species_id] = true
    end

    def set_seen(species, should_refresh_dexes = true)
      try_resync_pokedex()
      dexNum = getDexNumberForSpecies(species)
      if isTripleFusion(dexNum)
        set_seen_triple(species)
      elsif isFusion(dexNum)
        set_seen_fusion(species)
      else
        set_seen_normalDex(species)
      end
      self.refresh_accessible_dexes if should_refresh_dexes
    end

    # @param species [Symbol, GameData::Species] species to check
    # @return [Boolean] whether the species is seen

    def seen_fusion?(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return false if species_obj.nil?
      species_id = species_obj.id
      return @seen_fusion[species_id] == true
    end

    def seen_normalDex?(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return false if species_obj.nil?
      species_id = species_obj.id
      return @seen_standard[species_id] == true
    end

    def seen_triple?(species)
      species_id = GameData::Species.try_get(species)&.species
      return false if species_id.nil?
      return @seen_triple[species_id]
    end

    def seen?(species)
      return false if !species
      try_resync_pokedex()
      num = getDexNumberForSpecies(species)
      if isTripleFusion(num)
        return seen_triple?(species)
      elsif isFusion(num)
        return seen_fusion?(species)
      else
        return seen_normalDex?(species)
      end
    end

    def seen_form?(species, gender, form)
      return false
      # species_id = GameData::Species.try_get(species)&.species
      # return false if species_id.nil?
      # @seen_forms[species_id] ||= [[], []]
      # return @seen_forms[species_id][gender][form] == true
    end

    # Returns the amount of seen Pokémon.
    # If a region ID is given, returns the amount of seen Pokémon
    # in that region.
    # @param dex [Integer] region ID
    def seen_count(dex = -1)
      try_resync_pokedex()
      # if dex_sync_needed?()
        # resync_pokedex()
      # end
      return count_dex(@seen_standard, @seen_fusion) + @owned_triple.size
    end

    # Returns whether there are any seen Pokémon.
    # If a region is given, returns whether there are seen Pokémon
    # in that region.
    # @param region [Integer] region ID
    # @return [Boolean] whether there are any seen Pokémon
    def seen_any?(dex = -1)
      return seen_count >= 1
    end

    # Returns the amount of seen forms for the given species.
    # @param species [Symbol, GameData::Species] Pokémon species
    # @return [Integer] amount of seen forms
    def seen_forms_count(species)
      return 0
    end

    # @param species [Symbol, GameData::Species] Pokémon species
    def last_form_seen(species)
      @last_seen_forms[species] ||= []
      return @last_seen_forms[species][0] || 0, @last_seen_forms[species][1] || 0
    end

    # @param species [Symbol, GameData::Species] Pokémon species
    # @param gender [Integer] gender (0=male, 1=female, 2=genderless)
    # @param form [Integer] form number
    def set_last_form_seen(species, gender = 0, form = 0)
      @last_seen_forms[species] = [gender, form]
    end

    #===========================================================================

    # Sets the given species as owned in the Pokédex.
    # @param species [Symbol, GameData::Species] species to set as owned
    # @param should_refresh_dexes [Boolean] whether Dex accessibility should be recalculated
    def set_owned_fusion(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return if species_obj.nil?
      species_id = species_obj.id
      @owned_fusion[species_id] = true
    end

    def set_owned_triple(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return if species_obj.nil?
      species_id = species_obj.id
      @owned_triple[species_id] = true
    end

    def set_owned_normalDex(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return if species_obj.nil?
      species_id = species_obj.id
      @owned_standard[species_id] = true
    end

    def set_owned(species, should_refresh_dexes = true)
      dexNum = getDexNumberForSpecies(species)
      if isTripleFusion(dexNum)
        set_owned_triple(species)
      elsif isFusion(dexNum)
        set_owned_fusion(species)
      else
        set_owned_normalDex(species)
      end
      self.refresh_accessible_dexes if should_refresh_dexes
    end

    # Sets the given species as owned in the Pokédex.
    # @param species [Symbol, GameData::Species] species to set as owned
    def set_shadow_pokemon_owned(species)
      return
    end

    # @param species [Symbol, GameData::Species] species to check
    # @return [Boolean] whether the species is owned
    def owned_fusion?(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return false if species_obj.nil?
      species_id = species_obj.id
      return @owned_fusion[species_id] == true
    end

    def owned_triple?(species)
      species_id = GameData::Species.try_get(species)&.species
      return false if species_id.nil?
      return @owned_triple[species_id]
    end

    def owned?(species)
      try_resync_pokedex()
      num = getDexNumberForSpecies(species)
      if isTripleFusion(num)
        return owned_triple?(species)
      elsif isFusion(num)
        return owned_fusion?(species)
      else
        return owned_normalDex?(species)
      end
    end

    def owned_normalDex?(species)
      species = species.species if species.is_a?(Pokemon)
      species_obj = GameData::Species.try_get(species)
      return false if species_obj.nil?
      species_id = species_obj.id
      return @owned_standard[species_id] == true
    end

    # @param species [Symbol, GameData::Species] species to check
    # @return [Boolean] whether a Shadow Pokémon of the species is owned
    def owned_shadow_pokemon?(species)
      return
    end

    # Returns the amount of owned Pokémon.
    # If a region ID is given, returns the amount of owned Pokémon
    # in that region.
    # @param region [Integer] region ID
    def owned_count(dex = -1)
      # if dex_sync_needed?()
      #   resync_pokedex()
      # end
      return count_dex(@owned_standard, @owned_fusion) + @owned_triple.size
    end

    def count_dex(standardList, fusedList)
      return standardList.size + fusedList.size
    end

    def count_true(list)
      count = 0
      list.each { |owned|
        if owned
          count += 1
        end
      }
      return count
    end

    def dex_sync_needed?()
      return @owned_standard.is_a?(Array) || @seen_fusion.is_a?(Array)
    end

    #todo:
    # loop on @owned and @seen and add the pokemon in @owned_standard/fusion @seen_standard/fusion
    # then clear @owned and @seen
    def try_resync_pokedex()
      resyncPokedexIfNumberOfPokemonChanged
      #
      # if dex_sync_needed?()
      #   print "syncing"
      #   init_new_pokedex_if_needed()
      #   @seen.each { |pokemon|
      #     set_seen(pokemon[0])
      #   }
      #   @owned.each { |pokemon|
      #     set_owned(pokemon[0])
      #   }
      #   self.refresh_accessible_dexes
      #   @seen = {} #deprecated
      #   @owned = {} #deprecated
      # end
      #self.clear
    end

    def resync_boxes_to_pokedex
      $PokemonStorage.boxes.each { |box|
        box.pokemon.each { |pokemon|
          if pokemon != nil
            if !pokemon.egg?
              set_owned(pokemon.species)
              set_seen(pokemon.species)
            end
          end
        }
      }
    end

    def init_new_pokedex_if_needed()
      @seen_standard = initStandardDexArray() # if @seen_standard == nil
      @seen_fusion = initFusionDexArray() # if @seen_fusion == nil
      @seen_triple = {} if @seen_triple == nil

      @owned_standard = initStandardDexArray() # if @owned_standard == nil
      @owned_fusion = initFusionDexArray() # if @owned_fusion == nil
      @owned_triple = {} if @owned_triple == nil
    end

    #===========================================================================

    # @param pkmn [Pokemon, Symbol, GameData::Species] Pokemon to register as seen
    # @param gender [Integer] gender to register (0=male, 1=female, 2=genderless)
    # @param form [Integer] form to register
    def register(species, gender = 0, form = 0, should_refresh_dexes = true)
      set_seen(species, should_refresh_dexes)
    end

    # @param pkmn [Pokemon] Pokemon to register as most recently seen
    def register_last_seen(pkmn)
      return
      # validate pkmn => Pokemon
      # species_data = pkmn.species_data
      # form = species_data.pokedex_form
      # form = 0 if species_data.form_name.nil? || species_data.form_name.empty?
      # @last_seen_forms[pkmn.species] = [pkmn.gender, form]
    end

    # @param pkmn [Pokemon] Pokemon to register unfused pkmn from
    # @return [Array<Integer>] Dex numbers of unfused pokemon
    def register_unfused_pkmn(pkmn)
      # Trapstarr & HungryPickle
      registered = []
      return registered if !pkmn.isFusion? || $PokemonSystem.improved_pokedex == 0
      if pkmn.isTripleFusion?
        # Triple Fusion Logic, skipping for now (not sure if supported yet)
      else
        bodyPoke = getBasePokemonID(pkmn.species, true)
        headPoke = getBasePokemonID(pkmn.species, false)
        [headPoke, bodyPoke].each do |poke|
          if !owned?(poke)
            set_owned(poke)
            if $Trainer.has_pokedex
              register(poke)
              registered << poke
            end
          end
        end
      end
      return registered
    end

    #===========================================================================

    # Unlocks the given Dex, -1 being the National Dex.
    # @param dex [Integer] Dex ID (-1 is the National Dex)
    def unlock(dex)
      validate dex => Integer
      dex = @unlocked_dexes.length - 1 if dex < 0 || dex > @unlocked_dexes.length - 1
      @unlocked_dexes[dex] = true
      self.refresh_accessible_dexes
    end

    # Locks the given Dex, -1 being the National Dex.
    # @param dex [Integer] Dex ID (-1 is the National Dex)
    def lock(dex)
      validate dex => Integer
      dex = @unlocked_dexes.length - 1 if dex < 0 || dex > @unlocked_dexes.length - 1
      @unlocked_dexes[dex] = false
      self.refresh_accessible_dexes
    end

    # @param dex [Integer] Dex ID (-1 is the National Dex)
    # @return [Boolean] whether the given Dex is unlocked
    def unlocked?(dex)
      return dex == 0
      # validate dex => Integer
      # dex = @unlocked_dexes.length - 1 if dex == -1
      # return @unlocked_dexes[dex] == true
    end

    # @return [Integer] the number of defined Dexes (including the National Dex)
    def dexes_count
      return @unlocked_dexes.length
    end

    # Decides which Dex lists are able to be viewed (i.e. they are unlocked and
    # have at least 1 seen species in them), and saves all accessible Dex region
    # numbers into {#accessible_dexes}. National Dex comes after all regional
    # Dexes.
    # If the Dex list shown depends on the player's location, this just decides
    # if a species in the current region has been seen - doesn't look at other
    # regions.
    def refresh_accessible_dexes
      @accessible_dexes = []
      if self.unlocked?(0) && self.seen_any?
        @accessible_dexes.push(-1)
      end
    end

    #===========================================================================

    private

    # @param hash [Hash]
    # @param region [Integer]
    # @return [Integer]
    def count_species(hash, region = -1)
      return hash.size()
    end
  end
end
