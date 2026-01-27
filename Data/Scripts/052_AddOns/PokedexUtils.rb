class PokedexUtils
  # POSSIBLE_ALTS = ["", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
  #                  "r", "s", "t", "u", "v", "w", "x", "y", "z", "aa", "ab", "ac", "ad", "ae", "af", "ag", "ah",
  #                  "ai", "aj", "ak", "al", "am", "an", "ao", "ap", "aq", "ar", "as", "at", "au", "av", "aw", "ax",
  #                  "ay", "az"]

  def self.getAltLettersList()
    return ('a'..'z').to_a + ('aa'..'az').to_a
  end

  def self.pbGetAvailableAlts(species, form_index = 0)
    if form_index
      form_suffix = form_index <= 0 ? "" : "_" + form_index.to_s
    else
      form_suffix = ""
    end

    ret = []
    return ret if !species
    species_data = GameData::Species.try_get(species)
    if species_data && !GameData::SpeciesId.official_namespace?(species_data.namespace)
      front_path = _INTL("Graphics/Pokemon/Front/{1}/{2}.png", species_data.namespace, species_data.internal_key)
      ret << front_path if pbResolveBitmap(front_path)
      # Legacy/non-namespaced fakemon path support
      front_path = _INTL("Graphics/Pokemon/Front/{1}.png", species_data.internal_key)
      ret << front_path if pbResolveBitmap(front_path)
      battler_path = _INTL("Graphics/Battlers/{1}/{2}.png", species_data.namespace, species_data.internal_key)
      ret << battler_path if pbResolveBitmap(battler_path)
      battler_path = _INTL("Graphics/Battlers/{1}.png", species_data.internal_key)
      ret << battler_path if pbResolveBitmap(battler_path)
      fakemon_dir = _INTL("Graphics/Battlers/{1}/{2}", species_data.namespace, species_data.id_number.to_s)
      fakemon_base = species_data.id.to_s
      fakemon_path = _INTL("{1}/{2}", fakemon_dir, fakemon_base)
      resolved = pbResolveBitmap(fakemon_path)
      ret << resolved if resolved
      Dir.glob("#{fakemon_dir}/#{fakemon_base}_*.{png,jpg,jpeg}").each do |path|
        ret << path
      end
      fakemon_path = _INTL("Graphics/Battlers/FAKEMON/{1}.png", species_data.id.to_s)
      ret << fakemon_path if pbResolveBitmap(fakemon_path)
      ret.uniq!
      return ret if ret.length > 0
    end

    if GameData::SpeciesId.fusion?(species)
      head_id, body_id = GameData::SpeciesId.split_fusion(species)
      fusion_path = get_fusion_sprite_path(head_id, body_id, nil, nil)
      ret << fusion_path if fusion_path
      return ret
    end

    dexNum = getDexNumberForSpecies(species)
    unfused_path = Settings::CUSTOM_BASE_SPRITE_FOLDER + dexNum.to_s + form_suffix + ".png"
    if !pbResolveBitmap(unfused_path)
      unfused_path = Settings::BATTLERS_FOLDER + dexNum.to_s + form_suffix + "/" + dexNum.to_s + form_suffix + ".png"
    end
    ret << unfused_path

    getAltLettersList().each { |alt_letter|
      altFilePath = Settings::CUSTOM_BASE_SPRITES_FOLDER + dexNum.to_s + form_suffix + alt_letter + ".png"
      if pbResolveBitmap(altFilePath)
        ret << altFilePath
      end
    }
    return ret
  end

  #todo: return array for split evolution lines that have multiple final evos
  def self.getFinalEvolution(species)
    #ex: [[F__4_OFFICIAL.3_OFFICIAL,Level 32],[F__5_OFFICIAL.2_OFFICIAL, Level 35]]
    evolution_line = species.get_evolutions
    return species if evolution_line.empty?
    finalEvoId = evolution_line[0][0]
    return evolution_line[]
    for evolution in evolution_line
      evoSpecies = evolution[0]
      p GameData::Species.get(evoSpecies).get_evolutions
      isFinalEvo = GameData::Species.get(evoSpecies).get_evolutions.empty?
      return evoSpecies if isFinalEvo
    end
    return nil
  end

end
