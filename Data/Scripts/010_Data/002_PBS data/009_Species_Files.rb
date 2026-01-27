module GameData
  class Species
    def self.check_graphic_file(path, species, form = "", gender = 0, shiny = false, shadow = false, subfolder = "")
      try_subfolder = sprintf("%s/", subfolder)
      try_species = species
      try_form = form ? sprintf("_%s", form) : ""
      try_gender = (gender == 1) ? "_female" : ""
      try_shadow = (shadow) ? "_shadow" : ""
      factors = []
      factors.push([4, sprintf("%s shiny/", subfolder), try_subfolder]) if shiny
      factors.push([3, try_shadow, ""]) if shadow
      factors.push([2, try_gender, ""]) if gender == 1
      factors.push([1, try_form, ""]) if form
      
      species_data = GameData::Species.try_get(species)
      return nil if species_data.nil?
      if GameData::SpeciesId.official_namespace?(species_data.namespace)
        try_species = species_data.internal_key.to_s
      else
        # Custom mapping: Graphics/Battlers/{NAMESPACE}/{INTERNAL_KEY}
        try_species = "#{species_data.namespace}/#{species_data.internal_key}"
      end
      factors.push([0, try_species, "000"])

      # Go through each combination of parameters in turn to find an existing sprite
      for i in 0...2 ** factors.length
        # Set try_ parameters for this combination
        factors.each_with_index do |factor, index|
          value = ((i / (2 ** index)) % 2 == 0) ? factor[1] : factor[2]
          case factor[0]
          when 0 then
            try_species = value
          when 1 then
            try_form = value
          when 2 then
            try_gender = value
          when 3 then
            try_shadow = value
          when 4 then
            try_subfolder = value # Shininess
          end
        end
        # Look for a graphic matching this combination's parameters
        try_species_text = try_species
        ret = pbResolveBitmap(sprintf("%s%s%s%s%s%s", path, try_subfolder,
                                      try_species_text, try_form, try_gender, try_shadow))
        return ret if ret
      end
      # Fallback: allow custom sprites without namespace folder.
      if !GameData::SpeciesId.official_namespace?(species_data.namespace)
        try_species = species_data.internal_key.to_s
        for i in 0...2 ** factors.length
          factors.each_with_index do |factor, index|
            value = ((i / (2 ** index)) % 2 == 0) ? factor[1] : factor[2]
            case factor[0]
            when 0 then
              try_species = value
            when 1 then
              try_form = value
            when 2 then
              try_gender = value
            when 3 then
              try_shadow = value
            when 4 then
              try_subfolder = value
            end
          end
          try_species_text = try_species
          ret = pbResolveBitmap(sprintf("%s%s%s%s%s%s", path, try_subfolder,
                                        try_species_text, try_form, try_gender, try_shadow))
          return ret if ret
        end
      end
      # Final fallback to a default icon so UI never gets nil.
      return pbResolveBitmap("Graphics/Icons/icon000")
    end

    def self.check_egg_graphic_file(path, species, form, suffix = "")
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      if form > 0
        ret = pbResolveBitmap(sprintf("%s%s_%d%s", path, species_data.species, form, suffix))
        return ret if ret
      end
      return pbResolveBitmap(sprintf("%s%s%s", path, species_data.species, suffix))
    end

    def self.front_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Front")
    end

    def self.back_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Back")
    end

    # def self.egg_sprite_filename(species, form)
    #   ret = self.check_egg_graphic_file("Graphics/Pokemon/Eggs/", species, form)
    #   return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/Eggs/000")
    # end
    def self.egg_sprite_filename(species, form)
      species_data = GameData::Species.get(species)
      if !GameData::SpeciesId.official_namespace?(species_data.namespace)
        custom_path = sprintf("Graphics/Battlers/Eggs/%s/%s", species_data.namespace, species_data.internal_key)
        return custom_path if pbResolveBitmap(custom_path)
      end
      dex_num = species_data.id_number || 0
      bitmapFileName = sprintf("Graphics/Battlers/Eggs/%03d", dex_num) rescue nil
      if !pbResolveBitmap(bitmapFileName)
        if isTripleFusion?(dex_num)
          bitmapFileName = "Graphics/Battlers/Eggs/egg_base"
        else
          bitmapFileName = sprintf("Graphics/Battlers/Eggs/%03d", dex_num)
          if !pbResolveBitmap(bitmapFileName)
            bitmapFileName = sprintf("Graphics/Battlers/Eggs/000")
          end
        end
      end
      return bitmapFileName
    end

    def self.sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false, back = false, egg = false)
      return self.egg_sprite_filename(species, form) if egg
      return self.back_sprite_filename(species, form, gender, shiny, shadow) if back
      return self.front_sprite_filename(species, form, gender, shiny, shadow)
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.front_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={}, cusFile=nil)
      #filename = self.front_sprite_filename(species, form, gender, shiny, shadow)
      filename = self.front_sprite_filename(species)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.back_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={}, cusFile=nil)
      filename = self.back_sprite_filename(species, form, gender, shiny, shadow, shinyValue, shinyR, shinyG, shinyB, shinyKRS, shinyOmega, cusFile)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.egg_sprite_bitmap(species, form = 0)
      filename = self.egg_sprite_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false, back = false, egg = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={}, cusFile=nil)
      return self.egg_sprite_bitmap(species, form) if egg
      return self.back_sprite_bitmap(species, form, gender, shiny, shadow, shinyValue, shinyR, shinyG, shinyB, shinyKRS, shinyOmega, cusFile) if back
      return self.front_sprite_bitmap(species, form, gender, shiny, shadow, shinyValue, shinyR, shinyG, shinyB, shinyKRS, shinyOmega, cusFile)
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.sprite_bitmap_from_pokemon(pkmn, back = false, species = nil, makeShiny = true)
      species = pkmn.species if !species
      species = GameData::Species.get(species).species # Just to be sure it's a symbol
      return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
      if back
        #KurayX - KURAYX_ABOUT_SHINIES
        if makeShiny
          ret = self.back_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, pkmn.shinyValue?, pkmn.shinyR?, pkmn.shinyG?, pkmn.shinyB?, pkmn.shinyKRS?, pkmn.shinyOmega?, pkmn.kuraycustomfile?)
        else
          ret = self.back_sprite_bitmap(species, pkmn.form, pkmn.gender, false, false, false)
        end
      else
        #KurayX - KURAYX_ABOUT_SHINIES
        if makeShiny
          ret = self.front_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, pkmn.shinyValue?, pkmn.shinyR?, pkmn.shinyG?, pkmn.shinyB?, pkmn.shinyKRS?, pkmn.shinyOmega?, pkmn.kuraycustomfile?)
        else
          ret = self.front_sprite_bitmap(species, pkmn.form, pkmn.gender, false, false, false)
        end
      end
      alter_bitmap_function = MultipleForms.getFunction(species, "alterBitmap")
      if ret && alter_bitmap_function
        new_ret = ret.copy
        ret.dispose
        new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
        ret = new_ret
      end
      print "hat"
      add_hat_to_bitmap(ret,pkmn.hat,pkmn.hat_x,pkmn.hat_y) if pkmn.hat
      return ret
    end

    #===========================================================================

    def self.egg_icon_filename(species, form)
      ret = self.check_egg_graphic_file("Graphics/Pokemon/Eggs/", species, form, "_icon")
      return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/Eggs/000_icon")
    end

    def self.icon_filename(species, spriteform = nil, gender = nil, shiny = false, shadow = false, egg = false)
      return self.egg_icon_filename(species, 0) if egg
      spriteform = nil if spriteform == 0
      #End of KurayX patch attempt

      # Fakemon specific icon lookup
      species_data = GameData::Species.try_get(species)
      if species_data.nil?
        normalized = GameData::SpeciesId.normalize(species) rescue species
        species_data = GameData::Species.try_get(normalized)
      end
      if species_data && GameData::SpeciesId.official_namespace?(species_data.namespace)
        legacy_number = species_data.id_number || GameData::SpeciesId.local_number(species)
        if legacy_number && legacy_number > 0
          legacy_icon = sprintf("Graphics/Icons/icon%03d", legacy_number)
          return pbResolveBitmap(legacy_icon) if pbResolveBitmap(legacy_icon)
        end
      end
      if species_data && species_data.generation == 99
        # 1. Dynamic Map
        mapped_path = FakemonUtility.get_sprite_path(species_data.id, :icon)
        return pbResolveBitmap(mapped_path) if mapped_path && pbResolveBitmap(mapped_path)
        
        # 2. Standard Icon Folder
        fakemon_icon = sprintf("Graphics/Icons/FAKEMON/%s", species_data.id.to_s)
        return pbResolveBitmap(fakemon_icon) if pbResolveBitmap(fakemon_icon)

        # 3. Fallback to Front Sprite (so it doesn't look like a fusion/ ?)
        fakemon_front = sprintf("Graphics/Battlers/%s/%s/%s",
          species_data.namespace, species_data.id_number.to_s, species_data.id.to_s)
        return pbResolveBitmap(fakemon_front) if pbResolveBitmap(fakemon_front)
        fakemon_front = sprintf("Graphics/Battlers/FAKEMON/%s", species_data.id.to_s)
        return pbResolveBitmap(fakemon_front) if pbResolveBitmap(fakemon_front)
      end

      filename = self.check_graphic_file("Graphics/Pokemon/", species, spriteform, gender, shiny, shadow, "Icons")
      if !filename && shiny
        filename = self.check_graphic_file("Graphics/Pokemon/", species, spriteform, gender, false, shadow, "Icons")
      end
      return filename if filename

      # OFFICIAL fallback: icon packs use name-based filenames (e.g. PIDGEY.png)
      if species_data && GameData::SpeciesId.official_namespace?(species_data.namespace)
        name_key = species_data.real_name.to_s.upcase.gsub(/[^A-Z0-9]/, "")
        if !name_key.empty?
          subfolder = shiny ? "Graphics/Pokemon/Icons shiny/" : "Graphics/Pokemon/Icons/"
          form_suffix = spriteform ? "_#{spriteform}" : ""
          gender_suffix = (gender == 1) ? "_female" : ""
          shadow_suffix = shadow ? "_shadow" : ""
          candidate = "#{subfolder}#{name_key}#{form_suffix}#{gender_suffix}#{shadow_suffix}"
          return pbResolveBitmap(candidate) if pbResolveBitmap(candidate)
          # If a form suffix was provided but no icon exists, retry without it.
          if spriteform
            candidate = "#{subfolder}#{name_key}#{gender_suffix}#{shadow_suffix}"
            return pbResolveBitmap(candidate) if pbResolveBitmap(candidate)
          end
          if shiny
            subfolder = "Graphics/Pokemon/Icons/"
            candidate = "#{subfolder}#{name_key}#{form_suffix}#{gender_suffix}#{shadow_suffix}"
            return pbResolveBitmap(candidate) if pbResolveBitmap(candidate)
            if spriteform
              candidate = "#{subfolder}#{name_key}#{gender_suffix}#{shadow_suffix}"
              return pbResolveBitmap(candidate) if pbResolveBitmap(candidate)
            end
          end
        end
        # Legacy numeric icon pack fallback (Graphics/Icons/icon###)
        if species_data.id_number
          legacy_icon = sprintf("Graphics/Icons/icon%03d", species_data.id_number)
          return pbResolveBitmap(legacy_icon) if pbResolveBitmap(legacy_icon)
        end
      end
      # Legacy numeric icon pack fallback via symbol local number
      local_number = GameData::SpeciesId.local_number(species) rescue nil
      if local_number && local_number > 0
        legacy_icon = sprintf("Graphics/Icons/icon%03d", local_number)
        return pbResolveBitmap(legacy_icon) if pbResolveBitmap(legacy_icon)
      end
      return nil
    end

    def self.icon_filename_from_pokemon(pkmn)
      return pbResolveBitmap(sprintf("Graphics/Icons/iconEgg")) if pkmn.egg?
      if pkmn.isFusion?
        return  pbResolveBitmap(sprintf("Graphics/Icons/iconDNA"))
      end

      # Use normal form for unfused Pokemon; spriteform_head is for fusions only.
      return self.icon_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, pkmn.egg?)
    end

    def self.icon_filename_from_species(species)
      return self.icon_filename(species, 0, 0, false, false, false)
    end

    def self.egg_icon_bitmap(species, form)
      filename = self.egg_icon_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename).deanimate : nil
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    #KuraIcon
    def self.icon_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false, shinyValue = 0, dex_number = 0, bodyShiny = false, headShiny = false, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={})
      filename = self.icon_filename(species, form, gender, shiny, shadow)
      spritemade = (filename) ? AnimatedBitmap.new(filename).deanimate : nil
      if shiny && $PokemonSystem.shiny_icons_kuray == 1 && access_deprecated_kurayshiny() != 1
        # spritemade.shiftColors(colorshifting)
        spritemade.pbGiveFinaleColor(shinyR, shinyG, shinyB, shinyValue, shinyKRS, shinyOmega)
      end
      return spritemade
    end

    # #KurayX - KURAYX_ABOUT_SHINIES
    def self.icon_bitmap_from_pokemon(pkmn)
      return self.icon_bitmap(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, pkmn.egg?, pkmn.shinyValue?, pkmn.dexNum, pkmn.bodyShiny?, pkmn.headShiny?, pkmn.shinyR?, pkmn.shinyG?, pkmn.shinyB?, pkmn.shinyKRS?, pkmn.shinyOmega?)
    end

    #===========================================================================

    def self.footprint_filename(species, form = 0)
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      if form > 0
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/%s_%d", species_data.species, form))
        return ret if ret
      end
      return pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/%s", species_data.species))
    end

    #===========================================================================

    def self.shadow_filename(species, form = 0)
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      # Look for species-specific shadow graphic
      if form > 0
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_%d", species_data.species, form))
        return ret if ret
      end
      ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s", species_data.species))
      return ret if ret
      # Use general shadow graphic
      return pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%d", species_data.shadow_size))
    end

    def self.shadow_bitmap(species, form = 0)
      filename = self.shadow_filename(species, form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    def self.shadow_bitmap_from_pokemon(pkmn)
      filename = self.shadow_filename(pkmn.species, pkmn.form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #===========================================================================

    def self.check_cry_file(species, form)
      species_data = self.get_species_form(species, form)
      return nil if species_data.nil?
      return "Cries/BIRDBOSS_2" if $game_switches[SWITCH_TRIPLE_BOSS_BATTLE] && !$game_switches[SWITCH_SILVERBOSS_BATTLE]
      if species_data.is_fusion
        head_id = getHeadID(species_data)
        species_data = GameData::Species.get(head_id) if head_id
      end
      return nil if species_data.nil?

      # if form > 0
      #   ret = sprintf("Cries/%s_%d", species_data.species, form)
      #   return ret if pbResolveAudioSE(ret)
      # end
      ret = sprintf("Cries/%s", species_data.species)
      return (pbResolveAudioSE(ret)) ? ret : nil
    end

    def self.cry_filename(species, form = 0)
      return self.check_cry_file(species, form)
    end

    def self.cry_filename_from_pokemon(pkmn)
      return self.check_cry_file(pkmn.species, pkmn.form)
    end

    def self.play_cry_from_species(species, form = 0, volume = 90, pitch = 100)
      filename = self.cry_filename(species, form)
      return if !filename
      pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
    end

    def self.play_cry_from_pokemon(pkmn, volume = 90, pitch = nil)
      return if !pkmn || pkmn.egg?
      filename = self.cry_filename_from_pokemon(pkmn)
      return if !filename
      pitch ||= 75 + (pkmn.hp * 25 / pkmn.totalhp)
      pbSEPlay(RPG::AudioFile.new(filename, volume, pitch)) rescue nil
    end

    def self.play_cry(pkmn, volume = 90, pitch = nil)
      if pkmn.is_a?(Pokemon)
        self.play_cry_from_pokemon(pkmn, volume, pitch)
      else
        self.play_cry_from_species(pkmn, nil, volume, pitch)
      end
    end

    def self.cry_length(species, form = 0, pitch = 100)
      return 0 if !species || pitch <= 0
      pitch = pitch.to_f / 100
      ret = 0.0
      if species.is_a?(Pokemon)
        if !species.egg?
          filename = pbResolveAudioSE(GameData::Species.cry_filename_from_pokemon(species))
          ret = getPlayTime(filename) if filename
        end
      else
        filename = pbResolveAudioSE(GameData::Species.cry_filename(species, form))
        ret = getPlayTime(filename) if filename
      end
      ret /= pitch # Sound played at a lower pitch lasts longer
      return (ret * Graphics.frame_rate).ceil + 4 # 4 provides a buffer between sounds
    end
  end
end

#===============================================================================
# Deprecated methods
#===============================================================================
# @deprecated This alias is slated to be removed in v20.
def pbLoadSpeciesBitmap(species, gender = 0, form = 0, shiny = false, shadow = false, back = false, egg = false)
  Deprecation.warn_method('pbLoadSpeciesBitmap', 'v20', 'GameData::Species.sprite_bitmap(species, form, gender, shiny, shadow, back, egg)')
  return GameData::Species.sprite_bitmap(species, form, gender, shiny, shadow, back, egg)
end

# @deprecated This alias is slated to be removed in v20.
def pbLoadPokemonBitmap(pkmn, back = false)
  Deprecation.warn_method('pbLoadPokemonBitmap', 'v20', 'GameData::Species.sprite_bitmap_from_pokemon(pkmn)')
  return GameData::Species.sprite_bitmap_from_pokemon(pkmn, back)
end

# @deprecated This alias is slated to be removed in v20.
def pbLoadPokemonBitmapSpecies(pkmn, species, back = false)
  Deprecation.warn_method('pbLoadPokemonBitmapSpecies', 'v20', 'GameData::Species.sprite_bitmap_from_pokemon(pkmn, back, species)')
  return GameData::Species.sprite_bitmap_from_pokemon(pkmn, back, species)
end

# @deprecated This alias is slated to be removed in v20.
def pbPokemonIconFile(pkmn)
  Deprecation.warn_method('pbPokemonIconFile', 'v20', 'GameData::Species.icon_filename_from_pokemon(pkmn)')
  return GameData::Species.icon_filename_from_pokemon(pkmn)
end

# @deprecated This alias is slated to be removed in v20.
def pbLoadPokemonIcon(pkmn)
  Deprecation.warn_method('pbLoadPokemonIcon', 'v20', 'GameData::Species.icon_bitmap_from_pokemon(pkmn)')
  return GameData::Species.icon_bitmap_from_pokemon(pkmn)
end

# @deprecated This alias is slated to be removed in v20.
def pbPokemonFootprintFile(species, form = 0)
  Deprecation.warn_method('pbPokemonFootprintFile', 'v20', 'GameData::Species.footprint_filename(species, form)')
  return GameData::Species.footprint_filename(species, form)
end

# @deprecated This alias is slated to be removed in v20.
def pbCheckPokemonShadowBitmapFiles(species, form = 0)
  Deprecation.warn_method('pbCheckPokemonShadowBitmapFiles', 'v20', 'GameData::Species.shadow_filename(species, form)')
  return GameData::Species.shadow_filename(species, form)
end

# @deprecated This alias is slated to be removed in v20.
def pbLoadPokemonShadowBitmap(pkmn)
  Deprecation.warn_method('pbLoadPokemonShadowBitmap', 'v20', 'GameData::Species.shadow_bitmap_from_pokemon(pkmn)')
  return GameData::Species.shadow_bitmap_from_pokemon(pkmn)
end

# @deprecated This alias is slated to be removed in v20.
def pbCryFile(species, form = 0)
  if species.is_a?(Pokemon)
    Deprecation.warn_method('pbCryFile', 'v20', 'GameData::Species.cry_filename_from_pokemon(pkmn)')
    return GameData::Species.cry_filename_from_pokemon(species)
  end
  Deprecation.warn_method('pbCryFile', 'v20', 'GameData::Species.cry_filename(species, form)')
  return GameData::Species.cry_filename(species, form)
end

# @deprecated This alias is slated to be removed in v20.
def pbPlayCry(pkmn, volume = 90, pitch = nil)
  Deprecation.warn_method('pbPlayCry', 'v20', 'GameData::Species.play_cry(pkmn)')
  GameData::Species.play_cry(pkmn, volume, pitch)
end

# @deprecated This alias is slated to be removed in v20.
def pbPlayCrySpecies(species, form = 0, volume = 90, pitch = nil)
  Deprecation.warn_method('pbPlayCrySpecies', 'v20', 'Pokemon.play_cry(species, form)')
  Pokemon.play_cry(species, form, volume, pitch)
end

# @deprecated This alias is slated to be removed in v20.
def pbPlayCryPokemon(pkmn, volume = 90, pitch = nil)
  Deprecation.warn_method('pbPlayCryPokemon', 'v20', 'pkmn.play_cry')
  pkmn.play_cry(volume, pitch)
end

# @deprecated This alias is slated to be removed in v20.
def pbCryFrameLength(species, form = 0, pitch = 100)
  Deprecation.warn_method('pbCryFrameLength', 'v20', 'GameData::Species.cry_length(species, form)')
  return GameData::Species.cry_length(species, form, pitch)
end
