module GameData
  class Species
    def self.sprite_bitmap_from_pokemon(pkmn, back = false, species = nil, makeShiny = true)
      species = pkmn.species if !species
      species_obj = GameData::Species.try_get(species)
      species = species_obj ? species_obj.id : GameData::SpeciesId.normalize(species)
      return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
      if back
        #KurayX - KURAYX_ABOUT_SHINIES
        if makeShiny
          ret = self.back_sprite_bitmap(species, pkmn.spriteform_body, pkmn.spriteform_head, pkmn.shiny?,pkmn.bodyShiny?,pkmn.headShiny?,pkmn.shinyValue?,pkmn.shinyR?,pkmn.shinyG?,pkmn.shinyB?,pkmn.shinyKRS?,pkmn.shinyOmega?,pkmn.kuraycustomfile?)
        else
          ret = self.back_sprite_bitmap(species, pkmn.spriteform_body, pkmn.spriteform_head, false, false, false)
        end
      else
        #KurayX - KURAYX_ABOUT_SHINIES
        if makeShiny
          ret = self.front_sprite_bitmap(species, nil, nil, pkmn.shiny?,pkmn.bodyShiny?,pkmn.headShiny?,pkmn.shinyValue?,pkmn.shinyR?,pkmn.shinyG?,pkmn.shinyB?,pkmn.shinyKRS?,pkmn.shinyOmega?,pkmn.kuraycustomfile?)
        else
          ret = self.front_sprite_bitmap(species, nil, nil, false, false, false)
        end
      end
      ret.scale_bitmap(pkmn.sprite_scale) #for pokemon with size differences
      return ret
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.sprite_bitmap_from_pokemon_id(id, back = false, shiny=false, bodyShiny=false,headShiny=false, pokeHue = 0, pokeR = 0, pokeG = 1, pokeB = 2, pokeKRS = [0, 0, 0, 0, 0, 0, 0, 0, 0], pokeOmega = {}, cusFile=nil)
      if back
        ret = self.back_sprite_bitmap(id,nil,nil,shiny,bodyShiny,headShiny,pokeHue,pokeR,pokeG,pokeB,pokeKRS,pokeOmega,cusFile)
      else
        ret = self.front_sprite_bitmap(id,nil,nil,shiny,bodyShiny,headShiny,pokeHue,pokeR,pokeG,pokeB,pokeKRS,pokeOmega,cusFile)
      end
      return ret
    end

    MAX_SHIFT_VALUE = 360
    MINIMUM_OFFSET=40
    ADDITIONAL_OFFSET_WHEN_TOO_CLOSE=40
    MINIMUM_DEX_DIF=20

    #KurayBringingBack
    def self.calculateShinyHueOffset(dex_number, isBodyShiny = false, isHeadShiny = false, color = :c1)
      dex_number = getDexNumberForSpecies(dex_number) unless dex_number.is_a?(Integer)
      if dex_number <= NB_POKEMON
        if SHINY_COLOR_OFFSETS[dex_number]&.dig(color)
          return SHINY_COLOR_OFFSETS[dex_number]&.dig(color)
        end
        body_number = dex_number
        head_number = dex_number
      else
        body_number = getBodyID(dex_number)
        head_number = getHeadID(dex_number, body_number)
      end
      if isBodyShiny && isHeadShiny && SHINY_COLOR_OFFSETS[body_number]&.dig(color) && SHINY_COLOR_OFFSETS[head_number]&.dig(color)
        offset = SHINY_COLOR_OFFSETS[body_number]&.dig(color) + SHINY_COLOR_OFFSETS[head_number]&.dig(color)
      elsif isHeadShiny && SHINY_COLOR_OFFSETS[head_number]&.dig(color)
        offset = SHINY_COLOR_OFFSETS[head_number]&.dig(color)
      elsif isBodyShiny && SHINY_COLOR_OFFSETS[body_number]&.dig(color)
        offset = SHINY_COLOR_OFFSETS[body_number]&.dig(color)
      else
        return 0 if color != :v1
        offset = calculateShinyHueOffsetDefaultMethod(body_number, head_number, dex_number, isBodyShiny, isHeadShiny)
      end
      return offset
    end

    #KurayBringingBack
    def self.calculateShinyHueOffsetDefaultMethod(body_number,head_number,dex_number, isBodyShiny = false, isHeadShiny = false)
      dex_offset = dex_number
      #body_number = getBodyID(dex_number)
      #head_number=getHeadID(dex_number,body_number)
      dex_diff = (body_number-head_number).abs
      if isBodyShiny && isHeadShiny
        dex_offset = dex_number
      elsif isHeadShiny
        dex_offset = head_number
      elsif isBodyShiny
        dex_offset = dex_diff > MINIMUM_DEX_DIF ? body_number : body_number+ADDITIONAL_OFFSET_WHEN_TOO_CLOSE
      end
      offset = dex_offset + Settings::SHINY_HUE_OFFSET
      offset /= MAX_SHIFT_VALUE if offset > NB_POKEMON
      offset = MINIMUM_OFFSET if offset < MINIMUM_OFFSET
      offset = MINIMUM_OFFSET if (MAX_SHIFT_VALUE - offset).abs < MINIMUM_OFFSET
      offset += pbGet(VAR_SHINY_HUE_OFFSET) #for testing - always 0 during normal gameplay
      return offset
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    #KuraSprite
    def self.front_sprite_bitmap(dex_number, spriteform_body = nil, spriteform_head = nil, isShiny = false, bodyShiny = false, headShiny = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={},cusFile=nil)
      spriteform_body = nil# if spriteform_body == 0
      spriteform_head = nil# if spriteform_head == 0
      #TODO Remove spriteform mechanic entirely

      #la méthode est utilisé ailleurs avec d'autres arguments (gender, form, etc.) mais on les veut pas
      species_id = dex_number
      species_id = species_id.id if species_id.is_a?(GameData::Species)
      dex_num_for_shiny = getDexNumberForSpecies(species_id) rescue 0
      if cusFile == nil
        filename = self.sprite_filename(species_id, spriteform_body, spriteform_head)
      else
        if pbResolveBitmap(cusFile) && (!$PokemonSystem.kurayindividcustomsprite || $PokemonSystem.kurayindividcustomsprite == 0)
          filename = cusFile
        else
          filename = self.sprite_filename(species_id, spriteform_body, spriteform_head)
        end
      end
      sprite = (filename) ? AnimatedBitmap.new(filename).recognizeDims() : nil
      if isShiny
        # sprite.shiftColors(colorshifting)
        #KurayBringBackOldShinies
        if access_deprecated_kurayshiny() == 1
          sprite.shiftColors(self.calculateShinyHueOffset(dex_num_for_shiny, bodyShiny, headShiny))
        else
          sprite.pbGiveFinaleColor(shinyR, shinyG, shinyB, shinyValue, shinyKRS, shinyOmega)
        end
      end
      return sprite
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    #KuraSprite
    def self.back_sprite_bitmap(dex_number, spriteform_body = nil, spriteform_head = nil, isShiny = false, bodyShiny = false, headShiny = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={}, cusFile=nil)
      species_id = dex_number
      species_id = species_id.id if species_id.is_a?(GameData::Species)
      dex_num_for_shiny = getDexNumberForSpecies(species_id) rescue 0
      if cusFile == nil
        filename = self.sprite_filename(species_id, spriteform_body, spriteform_head)
      else
        if pbResolveBitmap(cusFile) && (!$PokemonSystem.kurayindividcustomsprite || $PokemonSystem.kurayindividcustomsprite == 0)
          filename = cusFile
        else
          filename = self.sprite_filename(species_id, spriteform_body, spriteform_head)
        end
      end
      sprite = (filename) ? AnimatedBitmap.new(filename).recognizeDims() : nil
      if isShiny
        # sprite.shiftColors(colorshifting)
        #KurayBringBackOldShinies
        if access_deprecated_kurayshiny() == 1
          sprite.shiftColors(self.calculateShinyHueOffset(dex_num_for_shiny, bodyShiny, headShiny))
        else
          sprite.pbGiveFinaleColor(shinyR, shinyG, shinyB, shinyValue, shinyKRS, shinyOmega)
        end
      end
      return sprite
    end

    def self.egg_sprite_bitmap(dex_number, form = nil)
      filename = self.egg_sprite_filename(dex_number, form)
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end

    #KurayX - KURAYX_ABOUT_SHINIES
    def self.sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false, back = false, egg = false, shinyValue = 0, shinyR = 0, shinyG = 1, shinyB = 2, shinyKRS=[0, 0, 0, 0, 0, 0, 0, 0, 0], shinyOmega={}, cusFile=nil)
      return self.egg_sprite_bitmap(species, form) if egg
      return self.back_sprite_bitmap(species, form, gender, shiny, shadow, shinyValue, shinyR, shinyG, shinyB, shinyKRS, shinyOmega, cusFile) if back
      return self.front_sprite_bitmap(species, form, gender, shiny, shadow, shinyValue, shinyR, shinyG, shinyB, shinyKRS, shinyOmega, cusFile)
    end

    def self.getSpecialSpriteName(dexNum)
      return kuray_global_triples(dexNum)
    end

    def self.sprite_filename(dex_number, spriteform_body = nil, spriteform_head = nil)
      # Normalize dex_number to an ID (Symbol)
      species_id = dex_number
      if dex_number.is_a?(GameData::Species)
        species_id = dex_number.id
      elsif dex_number.is_a?(String)
        species_id = dex_number.to_sym
      end

      return nil if species_id == nil

      # KIF MIGRATION: Pure Symbolic Check
      if species_is_fusion(species_id)
        head_id = get_head_id_from_symbol(species_id)
        body_id = get_body_id_from_symbol(species_id)
        return get_fusion_sprite_path(head_id, body_id, spriteform_body, spriteform_head)
      else
        return get_unfused_sprite_path(species_id, spriteform_body)
      end
    end  # customPath = pbResolveBitmap(Settings::CUSTOM_BATTLERS_FOLDER_INDEXED + "/" + head_id.to_s + "/" +filename)
      # customPath = download_custom_sprite(head_id,body_id)
      #
      # species = getSpecies(dex_number)
      # use_custom = customPath && !species.always_use_generated
      # if use_custom
      #   return customPath
      # end
      # #return Settings::BATTLERS_FOLDER + folder + "/" + filename
      # return download_autogen_sprite(head_id,body_id)

  end
end


def get_unfused_sprite_path(species_id, spriteform = nil)
  species_data = GameData::Species.try_get(species_id)
  if !species_data
    default_path = Settings::DEFAULT_SPRITE_PATH
    resolved = pbResolveBitmap(default_path)
    return resolved if resolved
    return "Graphics/Battlers/000.png"
  end

  # Fakemon sprite map support
  if species_data.generation == 99
    mapped_path = FakemonUtility.get_sprite_path(species_data.id, :front) rescue nil
    resolved = mapped_path ? pbResolveBitmap(mapped_path) : nil
    return resolved if resolved
    fakemon_author_path = _INTL("Graphics/Battlers/{1}/{2}/{3}.png",
      species_data.namespace, species_data.id_number.to_s, species_data.id.to_s)
    resolved = pbResolveBitmap(fakemon_author_path)
    return resolved if resolved
  end

  # Namespaced pathing for custom authors
  if !GameData::SpeciesId.official_namespace?(species_data.namespace)
    front_path = _INTL("Graphics/Pokemon/Front/{1}/{2}.png", species_data.namespace, species_data.internal_key)
    resolved = pbResolveBitmap(front_path)
    return resolved if resolved
    path = _INTL("Graphics/Battlers/{1}/{2}.png", species_data.namespace, species_data.internal_key)
    resolved = pbResolveBitmap(path)
    return resolved if resolved
    path = _INTL("Graphics/Battlers/FAKEMON/{1}.png", species_data.id.to_s)
    resolved = pbResolveBitmap(path)
    return resolved if resolved
  end

  # Legacy logic for standard mons or when namespaced file isn't found
  dex_key = species_data.internal_key.to_s
  if dex_key.empty? && species_data.generation != 99
    default_path = Settings::DEFAULT_SPRITE_PATH
    resolved = pbResolveBitmap(default_path)
    return resolved if resolved
    return "Graphics/Battlers/000.png"
  end

  spriteform_letter = (spriteform && spriteform.to_i != 0) ? "_" + spriteform.to_s : ""
  folder = dex_key.to_s
  
  # Try symbolic path first if enabled/available
  sym_path = _INTL("Graphics/Battlers/{1}/{1}.png", species_data.id.to_s)
  resolved = pbResolveBitmap(sym_path)
  return resolved if resolved

  # Standard numeric path
  filename = _INTL("{1}{2}.png", dex_key, spriteform_letter)
  path = Settings::BATTLERS_FOLDER + folder + spriteform_letter + "/" + filename
  resolved = pbResolveBitmap(path)
  return resolved if resolved

  # Legacy numeric fallback (e.g., Graphics/Battlers/4/4.png)
  if species_data.id_number && species_data.id_number > 0
    legacy_key = species_data.id_number.to_s
    legacy_path = Settings::BATTLERS_FOLDER + legacy_key + "/" + _INTL("{1}.png", legacy_key)
    resolved = pbResolveBitmap(legacy_path)
    return resolved if resolved
    if spriteform
      legacy_form_path = Settings::BATTLERS_FOLDER + legacy_key + "/" + _INTL("{1}_{2}.png", legacy_key, spriteform)
      resolved = pbResolveBitmap(legacy_form_path)
      return resolved if resolved
    end
  end

  default_path = Settings::DEFAULT_SPRITE_PATH
  resolved = pbResolveBitmap(default_path)
  return resolved if resolved
  return "Graphics/Battlers/000.png"
end

def alt_sprites_substitutions_available
  return $PokemonGlobal && $PokemonGlobal.alt_sprite_substitutions
end

def print_stack_trace
  stack_trace = caller
  stack_trace.each_with_index do |call, index|
    echo("#{index + 1}: #{call}")
  end
end

def record_sprite_substitution(substitution_id, sprite_name)
  return if !$PokemonGlobal
  return if !$PokemonGlobal.alt_sprite_substitutions
  $PokemonGlobal.alt_sprite_substitutions[substitution_id] = sprite_name
end

def debug_fusion_sprite(path)
  return if !defined?(Settings::DEBUG_FUSION_SPRITES) || !Settings::DEBUG_FUSION_SPRITES
  echoln "Fusion sprite resolved: #{path}"
end

def add_to_autogen_cache(pokemon_id, sprite_name)
  return if !$PokemonGlobal
  return if !$PokemonGlobal.autogen_sprites_cache
  $PokemonGlobal.autogen_sprites_cache[pokemon_id]=sprite_name
end

class PokemonGlobalMetadata
  attr_accessor :autogen_sprites_cache
end

#To force a specific sprites before a battle
#
#  ex:
# $PokemonTemp.forced_alt_sprites={"20.25" => "20.25a"}
#
class PokemonTemp
  attr_accessor :forced_alt_sprites
end

#todo: refactor into smaller methods
def get_fusion_sprite_path(head_id, body_id, spriteform_body = nil, spriteform_head = nil)
  $PokemonGlobal.autogen_sprites_cache = {} if $PokemonGlobal && !$PokemonGlobal.autogen_sprites_cache
  
  # KIF MIGRATION: IDs are likely Symbols now.
  head_data = GameData::Species.get(head_id) rescue nil
  body_data = GameData::Species.get(body_id) rescue nil
  head_sym = head_data ? head_data.id : head_id
  body_sym = body_data ? body_data.id : body_id

  form_suffix = ""
  form_suffix += "_" + spriteform_body.to_s if spriteform_body
  form_suffix += "_" + spriteform_head.to_s if spriteform_head

  # Swap path if alt is selected for this pokemon
  dex_num = get_fusion_symbol(head_id, body_id)
  substitution_id = dex_num.to_s + form_suffix

  if alt_sprites_substitutions_available && $PokemonGlobal.alt_sprite_substitutions.keys.include?(substitution_id)
    substitutionPath = $PokemonGlobal.alt_sprite_substitutions[substitution_id]
    return substitutionPath if pbResolveBitmap(substitutionPath)
  end

  spriteform_body_letter = spriteform_body ? "_" + spriteform_body.to_s : ""
  spriteform_head_letter = spriteform_head ? "_" + spriteform_head.to_s : ""

  # PURE SYMBOLIC FILENAME
  pokemon_name = _INTL("{1}{2}.{3}{4}", head_sym, spriteform_head_letter, body_sym, spriteform_body_letter)

  # Alt letter: avoid calling PokedexUtils here to prevent recursion.
  random_alt = ""
  
  forcingSprite = false
  if $PokemonTemp.forced_alt_sprites && $PokemonTemp.forced_alt_sprites.key?(pokemon_name)
    random_alt = $PokemonTemp.forced_alt_sprites[pokemon_name]
    forcingSprite = true
  end

  filename = _INTL("{1}{2}.png", pokemon_name, random_alt)
  
  # TRY SYMBOLIC FOLDER (Graphics/Battlers/HEADSYMB/HEADSYMB.BODYSYMB.png)
  local_custom_path = _INTL("Graphics/Battlers/{1}/{2}", head_sym, filename)
  if pbResolveBitmap(local_custom_path)
    debug_fusion_sprite(local_custom_path)
    record_sprite_substitution(substitution_id, local_custom_path) if !forcingSprite
    return local_custom_path
  end

  # CUSTOM AUTHOR FOLDER (Graphics/Battlers/AUTHOR/ID_NUM/HEADSYM.BODYTOKEN.png)
  author_namespace = head_data ? head_data.namespace : nil
  author_id_number = head_data ? head_data.id_number : nil
  if (!author_namespace || !author_id_number)
    head_sym_str = head_sym.to_s
    if head_sym_str =~ /^(\d+)_([A-Za-z0-9]+)$/
      author_id_number ||= Regexp.last_match(1).to_i
      author_namespace ||= Regexp.last_match(2)
    end
  end
  if author_namespace && author_id_number && author_id_number > 0
    author_folder = _INTL("Graphics/Battlers/{1}/{2}", author_namespace, author_id_number.to_s)
    body_tokens = []
    begin
      dex_body = getDexNumberForSpecies(body_id)
      body_tokens << dex_body.to_s if dex_body && dex_body > 0
    rescue
    end
    if body_data && body_data.id_number
      body_tokens << body_data.id_number.to_s
      body_tokens << _INTL("{1}_0", body_data.id_number.to_s)
    end
    body_tokens << body_data.internal_key.to_s if body_data
    body_tokens << body_sym.to_s
    body_tokens.uniq.each do |body_token|
      author_filename = _INTL("{1}.{2}{3}.png", head_sym, body_token, random_alt)
      author_path = _INTL("{1}/{2}", author_folder, author_filename)
      if pbResolveBitmap(author_path)
        debug_fusion_sprite(author_path)
        record_sprite_substitution(substitution_id, author_path) if !forcingSprite
        return author_path
      end
    end
  end

  # FALLBACKS: allow name-based and legacy author-number variants
  alt_heads = [head_sym.to_s]
  alt_bodies = [body_sym.to_s]
  if head_data
    alt_heads << head_data.internal_key.to_s
    alt_heads << _INTL("{1}_0", head_data.id_number.to_s) if head_data.id_number
    alt_heads << head_data.id_number.to_s if head_data.id_number
  end
  if body_data
    alt_bodies << body_data.internal_key.to_s
    alt_bodies << _INTL("{1}_0", body_data.id_number.to_s) if body_data.id_number
    alt_bodies << body_data.id_number.to_s if body_data.id_number
  end
  alt_heads.uniq!
  alt_bodies.uniq!
  alt_heads.each do |head_key|
    alt_bodies.each do |body_key|
      next if head_key == head_sym.to_s && body_key == body_sym.to_s
      alt_name = _INTL("{1}{2}.{3}{4}", head_key, spriteform_head_letter, body_key, spriteform_body_letter)
      alt_filename = _INTL("{1}{2}.png", alt_name, random_alt)
      alt_path = _INTL("Graphics/Battlers/{1}/{2}", head_key, alt_filename)
      if pbResolveBitmap(alt_path)
        debug_fusion_sprite(alt_path)
        record_sprite_substitution(substitution_id, alt_path) if !forcingSprite
        return alt_path
      end
    end
  end

  # LEGACY INDEXED FOLDER (Graphics/CustomBattlers/indexed/HEAD_ID/HEAD_ID.BODY_ID.png)
  head_num = head_data ? (head_data.id_number || 0) : 0
  body_num = body_data ? (body_data.id_number || 0) : 0
  if head_data && body_data &&
     GameData::SpeciesId.official_namespace?(head_data.namespace) &&
     GameData::SpeciesId.official_namespace?(body_data.namespace)
    if head_num > 0 && body_num > 0
      legacy_filename = _INTL("{1}.{2}{3}.png", head_num, body_num, random_alt)
      legacy_path = Settings::CUSTOM_BATTLERS_FOLDER_INDEXED + head_num.to_s + "/" + legacy_filename
      if pbResolveBitmap(legacy_path)
         return legacy_path
      end
    end
  end

  # Legacy fakemon folder fallback (Graphics/Battlers/FAKEMON/<BODY_NUM>/<HEADSYM>.<BODY_NUM>.png)
  if head_data && !GameData::SpeciesId.official_namespace?(head_data.namespace) && body_num > 0
    fakemon_legacy_path = _INTL("Graphics/Battlers/FAKEMON/{1}/{2}.{3}{4}.png",
      body_num.to_s, head_sym, body_num.to_s, random_alt)
    return fakemon_legacy_path if pbResolveBitmap(fakemon_legacy_path)
  end

  # if the game has loaded an autogen earlier, no point in trying to redownload, so load that instead
  return $PokemonGlobal.autogen_sprites_cache[substitution_id] if $PokemonGlobal && $PokemonGlobal.autogen_sprites_cache[substitution_id]

  # Try to download custom sprite if none found locally
  downloaded_custom = download_custom_sprite(head_id, body_id, spriteform_body_letter, spriteform_head_letter, random_alt)
  if downloaded_custom
    record_sprite_substitution(substitution_id, downloaded_custom) if !forcingSprite
    return downloaded_custom
  end

  # Try local generated sprite (numeric only for OFFICIAL)
  if head_data && body_data &&
     GameData::SpeciesId.official_namespace?(head_data.namespace) &&
     GameData::SpeciesId.official_namespace?(body_data.namespace)
    if head_num > 0 && body_num > 0
      local_generated_path = Settings::BATTLERS_FOLDER + head_num.to_s + spriteform_head_letter + "/" + _INTL("{1}.{2}{3}.png", head_num, body_num, random_alt)
      if pbResolveBitmap(local_generated_path)
        add_to_autogen_cache(substitution_id, local_generated_path)
        return local_generated_path
      end

      # Download generated sprite if nothing else found
      autogen_path = download_autogen_sprite(head_num, body_num, spriteform_body_letter, spriteform_head_letter)
      if autogen_path && pbResolveBitmap(autogen_path)
        add_to_autogen_cache(substitution_id, autogen_path)
        return autogen_path
      end
    end
  end

  # Numeric folder + symbolic body fallback (legacy battler folder with symbolic body)
  if head_num > 0
    symbolic_body = body_sym.to_s
    symbolic_filename = _INTL("{1}.{2}{3}.png", head_num, symbolic_body, random_alt)
    symbolic_path = Settings::BATTLERS_FOLDER + head_num.to_s + spriteform_head_letter + "/" + symbolic_filename
    return symbolic_path if pbResolveBitmap(symbolic_path)
  end

  # Numeric-only local fallback (legacy battler folders like Graphics/Battlers/4/4.10.png)
  if head_num > 0 && body_num > 0
    numeric_filename = _INTL("{1}.{2}{3}.png", head_num, body_num, random_alt)
    numeric_path = Settings::BATTLERS_FOLDER + head_num.to_s + spriteform_head_letter + "/" + numeric_filename
    return numeric_path if pbResolveBitmap(numeric_path)
  end

  return Settings::DEFAULT_SPRITE_PATH
end

# def get_fusion_sprite_path(head_id, body_id, spriteform_body = nil, spriteform_head = nil)
#   $PokemonGlobal.autogen_sprites_cache = {} if $PokemonGlobal && !$PokemonGlobal.autogen_sprites_cache
#   #Todo: ça va chier si on fusionne une forme d'un pokemon avec une autre forme, mais pas un problème pour tout de suite
#   form_suffix = ""
#   form_suffix += "_" + spriteform_body.to_s if spriteform_body
#   form_suffix += "_" + spriteform_head.to_s if spriteform_head

#   #Swap path if alt is selected for this pokemon
#   dex_num = getSpeciesIdForFusion(head_id, body_id)
#   substitution_id = dex_num.to_s + form_suffix


#   if alt_sprites_substitutions_available && $PokemonGlobal.alt_sprite_substitutions.keys.include?(substitution_id)
#     substitutionPath= $PokemonGlobal.alt_sprite_substitutions[substitution_id]
#     return substitutionPath if pbResolveBitmap(substitutionPath)
#   end

#   random_alt = get_random_alt_letter_for_custom(head_id, body_id) #nil if no main
#   random_alt = "" if !random_alt
#   #if the game has loaded an autogen earlier, no point in trying to redownload, so load that instead
#   return $PokemonGlobal.autogen_sprites_cache[substitution_id] if  $PokemonGlobal && $PokemonGlobal.autogen_sprites_cache[substitution_id]

#   #Try local custom sprite
#   spriteform_body_letter = spriteform_body ? "_" + spriteform_body.to_s : ""
#   spriteform_head_letter = spriteform_head ? "_" + spriteform_head.to_s : ""

#   filename = _INTL("{1}{2}.{3}{4}{5}.png", head_id, spriteform_head_letter, body_id, spriteform_body_letter, random_alt)
#   local_custom_path = Settings::CUSTOM_BATTLERS_FOLDER_INDEXED + head_id.to_s + spriteform_head_letter + "/" + filename
#   if pbResolveBitmap(local_custom_path)
#     record_sprite_substitution(substitution_id, local_custom_path)
#     return local_custom_path
#   end
#   #Try to download custom sprite if none found locally
#   downloaded_custom = download_custom_sprite(head_id, body_id, spriteform_body_letter, spriteform_head_letter, random_alt)
#   if downloaded_custom
#     record_sprite_substitution(substitution_id, downloaded_custom)
#     return downloaded_custom
#   end

#   #Try local generated sprite
#   local_generated_path = Settings::BATTLERS_FOLDER + head_id.to_s + spriteform_head_letter + "/" + filename
#   if pbResolveBitmap(local_generated_path)
#     add_to_autogen_cache(substitution_id,local_generated_path)
#     return local_generated_path
#   end

#   #Download generated sprite if nothing else found
#   # autogen_path = download_autogen_sprite(head_id, body_id)
#   autogen_path = download_autogen_sprite(head_id, body_id,spriteform_body,spriteform_head)
#   if pbResolveBitmap(autogen_path)
#     add_to_autogen_cache(substitution_id,autogen_path)
#     return autogen_path
#   end

#   return Settings::DEFAULT_SPRITE_PATH
# end

def get_random_alt_letter_for_custom(head_id, body_id, onlyMain = true)
  spriteName = _INTL("{1}.{2}", head_id, body_id)
  if onlyMain
    return list_main_sprites_letters(spriteName).sample
  else
    return list_all_sprites_letters(spriteName).sample
  end
end

def get_random_alt_letter_for_unfused(dex_num, onlyMain = true)
  spriteName = _INTL("{1}", dex_num)
  if onlyMain
    letters_list= list_main_sprites_letters(spriteName)
  else
    letters_list= list_all_sprites_letters(spriteName)
  end
  letters_list << ""  #add main sprite
  return letters_list.sample
end

def list_main_sprites_letters(spriteName)
  all_sprites = map_alt_sprite_letters_for_pokemon(spriteName)
  main_sprites = []
  all_sprites.each do |key, value|
    main_sprites << key if value == "main"
  end
  
  #add temp sprites if no main sprites found
  if main_sprites.empty?
    all_sprites.each do |key, value|
      main_sprites << key if value == "temp"
    end
  end
  return main_sprites
end

def list_all_sprites_letters(spriteName)
  all_sprites_map = map_alt_sprite_letters_for_pokemon(spriteName)
  letters = []
  all_sprites_map.each do |key, value|
    letters << key
  end
  return letters
end

def list_alt_sprite_letters(spriteName)
  all_sprites = map_alt_sprite_letters_for_pokemon(spriteName)
  alt_sprites = []
  all_sprites.each do |key, value|
    alt_sprites << key if value == "alt"
  end
end



def map_alt_sprite_letters_for_pokemon(spriteName)
  alt_sprites = {}
  File.foreach(Settings::CREDITS_FILE_PATH) do |line|
    row = line.split(',')
    sprite_name = row[0]
    if sprite_name.start_with?(spriteName)
      if sprite_name.length > spriteName.length #alt letter
        letter = sprite_name[spriteName.length]
        if letter.match?(/[a-zA-Z]/)
          main_or_alt = row[2] ? row[2] : nil
          alt_sprites[letter] = main_or_alt
        end
      else  #letterless
      main_or_alt = row[2] ? row[2] : nil
      alt_sprites[""] = main_or_alt
      end
    end
  end
  # Fallback to sprite list files when credits are missing/incomplete.
  [Settings::CUSTOM_SPRITES_FILE_PATH, Settings::BASE_SPRITES_FILE_PATH].each do |list_path|
    sprite_map = sprite_letters_from_list(list_path)
    next if !sprite_map[spriteName]
    sprite_map[spriteName].each do |letter, kind|
      alt_sprites[letter] ||= kind
    end
  end
  return alt_sprites
end

def sprite_letters_from_list(list_path)
  $sprite_letter_map_cache ||= {}
  return $sprite_letter_map_cache[list_path] if $sprite_letter_map_cache[list_path]
  map = Hash.new { |h, k| h[k] = {} }
  if File.exist?(list_path)
    File.foreach(list_path) do |line|
      name = line.strip
      next if name.empty?
      name = name.sub(/\.png\z/i, "")
      match = name.match(/\A(.+?)([A-Za-z]+)?\z/)
      next if !match
      base = match[1]
      letter = match[2] || ""
      map[base][letter] = letter.empty? ? "main" : "alt"
    end
  end
  $sprite_letter_map_cache[list_path] = map
  return map
end