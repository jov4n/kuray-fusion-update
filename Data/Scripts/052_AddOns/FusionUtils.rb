def is_fusion_of_any(species_id, pokemonList)
  is_species = false
  for fusionPokemon in pokemonList
    if is_fusion_of(species_id, fusionPokemon)
      is_species = true
    end
  end
  return is_species
end

def is_fusion_of(checked_species, checked_against)
  return species_has_body_of(checked_species, checked_against) || species_has_head_of(checked_species, checked_against)
end

def is_species(checked_species, checked_against)
  return checked_species == checked_against
end

def species_has_body_of(checked_species, checked_against)
  if !species_is_fusion(checked_species)
    return is_species(checked_species, checked_against)
  end
  bodySpecies = get_body_species_from_symbol(checked_species)
  ret = bodySpecies == checked_against
  #echoln _INTL("{1} HAS BODY OF {2} : {3} (body is {4})",checked_species,checked_against,ret,bodySpecies)
  return ret
end

def species_has_head_of(checked_species, checked_against)
  if !species_is_fusion(checked_species)
    return is_species(checked_species, checked_against)
  end
  headSpecies = get_head_species_from_symbol(checked_species)
  ret = headSpecies == checked_against
  #echoln _INTL("{1} HAS HEAD OF {2} : {3}",checked_species,checked_against,ret)
  return ret
end

def species_is_fusion(species_id)
  return GameData::SpeciesId.fusion?(species_id)
end

def get_dex_number(species_id)
  return GameData::Species.get(species_id).id_number
end

def getBodyID(species, nb_pokemon = NB_POKEMON)
  return getBasePokemonID(species, true)
end

def getHeadID(species, bodyId = nil, nb_pokemon = NB_POKEMON)
  return getBasePokemonID(species, false)
end

def get_fusion_id(head_number, body_number)
  head_id = GameData::SpeciesId.normalize(head_number)
  body_id = GameData::SpeciesId.normalize(body_number)
  return GameData::SpeciesId.build_fusion(head_id, body_id)
end

def get_body_id_from_symbol(id)
  return id unless GameData::SpeciesId.fusion?(id)
  return GameData::SpeciesId.split_fusion(id)[1]
end

def get_head_id_from_symbol(id)
  return id unless GameData::SpeciesId.fusion?(id)
  return GameData::SpeciesId.split_fusion(id)[0]
end

def obtainPokemonSpritePath(id, includeCustoms = true)
  head = getBasePokemonID(param.to_i, false)
  body = getBasePokemonID(param.to_i, true)

  return obtainPokemonSpritePath(body, head, includeCustoms)
end

def obtainPokemonSpritePath(bodyId, headId, include_customs = true)
  download_pokemon_sprite_if_missing(bodyId, headId)
  picturePath = _INTL("Graphics/Battlers/{1}/{1}.{2}.png", headId, bodyId)

  if include_customs && customSpriteExistsBodyHead(bodyId, headId)
    pathCustom = getCustomSpritePath(bodyId, headId)
    if (pbResolveBitmap(pathCustom))
      picturePath = pathCustom
    end
  end
  return picturePath
end

def getCustomSpritePath(body, head)
  # return _INTL("#{Settings::CUSTOM_BATTLERS_FOLDER_INDEXED}{1}/{1}.{2}.png", head, body)
  return _INTL("Graphics/CustomBattlers/indexed/{1}/{1}.{2}.png", head, body)
end

def customSpriteExistsForm(species, form_id_head = nil, form_id_body = nil)
  head = getBasePokemonID(species, false)
  body = getBasePokemonID(species, true)

  folder = head.to_s

  folder += "_" + form_id_head.to_s if form_id_head

  spritename = head.to_s
  spritename += "_" + form_id_head.to_s if form_id_head
  spritename += "." + body.to_s
  spritename += "_" + form_id_body.to_s if form_id_body

  # pathCustom = _INTL("Graphics/.CustomBattlers/indexed/{1}/{2}.png", folder, spritename)
  pathCustom = _INTL("Graphics/CustomBattlers/indexed/{1}/{2}.png", folder, spritename)
  return true if pbResolveBitmap(pathCustom) != nil
  # return download_custom_sprite(head, body) != nil
  return download_custom_sprite(head, body,form_id_head,form_id_body) != nil
end

def get_fusion_spritename(head_id, body_id, alt_letter = "")
  return "#{head_id}.#{body_id}#{alt_letter}"
end

# def customSpriteExistsSpecies(species)
#   head = getBasePokemonID(species, false)
#   body = getBasePokemonID(species, true)
#   return customSpriteExists(body, head)
#   # pathCustom = getCustomSpritePath(body, head)
#   #
#   # return true if pbResolveBitmap(pathCustom) != nil
#   # return download_custom_sprite(head, body) != nil
# end


# old code
# def getRandomCustomFusion(returnRandomPokemonIfNoneFound = true, customPokeList = [], maxPoke = -1, recursionLimit = 3, maxBST=300)
#   if customPokeList.length == 0
#     customPokeList = getCustomSpeciesList()
#   end
#   randPoke = []
#   if customPokeList.length >= 5000
#     chosen = false
#     i = 0 #loop pas plus que 3 fois pour pas lag
#     while chosen == false
#       fusedPoke = customPokeList[rand(customPokeList.length)]
#       if (i >= recursionLimit) || maxPoke == -1
#         return fusedPoke
#       end
#     end
#   else
#     if returnRandomPokemonIfNoneFound
#       return rand(maxPoke) + 1
#     end
#   end

#   return randPoke
# end

def getRandomCustomFusion(returnRandomPokemonIfNoneFound = true, customPokeList = [], maxPoke = -1, recursionLimit = 3)
  if customPokeList.length == 0
    customPokeList = getCustomSpeciesList(false)
  end
  randPoke = []
  if customPokeList.length >= 5000
    chosen = false
    i = 0 #loop pas plus que 3 fois pour pas lag
    while chosen == false
      fusedPoke = customPokeList[rand(customPokeList.length)]
      poke1 = getBasePokemonID(fusedPoke, false)
      poke2 = getBasePokemonID(fusedPoke, true)

      if ((species_local_number(poke1) <= maxPoke && species_local_number(poke2) <= maxPoke) || i >= recursionLimit) || maxPoke == -1
        randPoke << poke1
        randPoke << poke2
        chosen = true
      end
    end
  else
    if returnRandomPokemonIfNoneFound
      randPoke << getRandomSpeciesId(maxPoke)
      randPoke << getRandomSpeciesId(maxPoke)
    end
  end
  return randPoke
end

def checkIfCustomSpriteExistsByPath(path)
  return true if pbResolveBitmap(path) != nil
end

def customSpriteExistsBodyHead(body, head)
  pathCustom = getCustomSpritePath(body, head)

  return true if pbResolveBitmap(pathCustom) != nil
  return download_custom_sprite(head, body) != nil
end

def customSpriteExistsSpecies(species)
  # body_id = getBodyID(species)
  # head_id = getHeadID(species, body_id)

  head = getBasePokemonID(species, false)
  body = getBasePokemonID(species, true)
  pathCustom = getCustomSpritePath(body,head)

  return true if pbResolveBitmap(pathCustom) != nil
  return download_custom_sprite(head, body) != nil
end

def customSpriteExists(body, head)
  # fusion_id = get_fusion_symbol(head, body)
  # return $game_temp.custom_sprites_list.include?(fusion_id)
  pathCustom = getCustomSpritePath(body,head)

  return true if pbResolveBitmap(pathCustom) != nil
  return download_custom_sprite(head, body) != nil
end

#shortcut for using in game events because of script characters limit
def dexNum(species)
  return getDexNumberForSpecies(species)
end

def isTripleFusion?(num)
  return num.is_a?(Integer) && num >= Settings::ZAPMOLCUNO_NB
end

def isFusion(num)
  return species_is_fusion(num)
end

def species_local_number(species_id)
  species_data = GameData::Species.get(species_id) rescue nil
  return species_data ? (species_data.id_number || 0) : 0
end

def getRandomSpeciesId(maxPoke = -1)
  candidates = []
  GameData::Species.each do |spec|
    next if species_is_fusion(spec.id)
    if maxPoke && maxPoke > 0
      next if spec.id_number.nil? || spec.id_number <= 0 || spec.id_number > maxPoke
    end
    candidates << spec.id
  end
  return candidates.sample || :PIKACHU
end

def isSpeciesFusion(species)
  return species_is_fusion(species)
end

def getRandomLocalFusion()
  spritesList = []
  $PokemonGlobal.alt_sprite_substitutions.each_value do |value|
    if value.is_a?(PIFSprite)
      spritesList << value
    end
  end
  return spritesList.sample
end

def getRandomCustomFusionForIntro(returnRandomPokemonIfNoneFound = true, customPokeList = [], maxPoke = -1, recursionLimit = 3)
  if customPokeList.length == 0
    customPokeList = getCustomSpeciesList(false )
  end
  randPoke = []
  if customPokeList.length >= 5000
    chosen = false
    i = 0 #loop pas plus que 3 fois pour pas lag
    while chosen == false
      fusedPoke = customPokeList[rand(customPokeList.length)]
      poke1 = getBasePokemonID(fusedPoke, false)
      poke2 = getBasePokemonID(fusedPoke, true)

      if ((species_local_number(poke1) <= maxPoke && species_local_number(poke2) <= maxPoke) || i >= recursionLimit) || maxPoke == -1
        randPoke << poke1
        randPoke << poke2
        chosen = true
      end
    end
  else
    if returnRandomPokemonIfNoneFound
      randPoke << getRandomSpeciesId(maxPoke)
      randPoke << getRandomSpeciesId(maxPoke)
    end
  end

  return randPoke
end

# crashes 'cause we don't have spritesheets
def getRandomFusionForIntro()
  random_pokemon = $game_temp.custom_sprites_list.keys.sample || :PIKACHU
  alt_letter = $game_temp.custom_sprites_list[random_pokemon]
  body_id = get_body_number_from_symbol(random_pokemon)
  head_id = get_head_number_from_symbol(random_pokemon)
  return PIFSprite.new(:CUSTOM, head_id, body_id, alt_letter)
end

def getSpeciesIdForFusion(head_number, body_number)
  return get_fusion_id(head_number, body_number)
end

def get_body_species_from_symbol(fused_id)
  body_id = get_body_id_from_symbol(fused_id)
  spec = GameData::Species.get(body_id)
  return spec ? spec.species : :PIKACHU
end

def get_head_species_from_symbol(fused_id)
  head_id = get_head_id_from_symbol(fused_id)
  spec = GameData::Species.get(head_id)
  return spec ? spec.species : :PIKACHU
end

def get_body_number_from_symbol(id)
  body_id = get_body_id_from_symbol(id)
  body_obj = GameData::Species.try_get(body_id)
  return body_obj ? body_obj.id_number : 0
end

def get_head_number_from_symbol(id)
  head_id = get_head_id_from_symbol(id)
  head_obj = GameData::Species.try_get(head_id)
  return head_obj ? head_obj.id_number : 0
end

def get_fusion_symbol(head_id, body_id)
  head_sym = GameData::SpeciesId.normalize(head_id)
  body_sym = GameData::SpeciesId.normalize(body_id)
  return GameData::SpeciesId.build_fusion(head_sym, body_sym)
end

def getFusionSpecies(body, head)
  fusion_id = get_fusion_symbol(head, body)
  return GameData::Species.get(fusion_id)
end

def getDexNumberForSpecies(species)
  return species if species.is_a?(Integer)
  if species.is_a?(Symbol)
    obj = GameData::Species.try_get(species)
    dexNum = obj ? obj.id_number : 0
  elsif species.is_a?(Pokemon)
    obj = GameData::Species.try_get(species.species)
    dexNum = obj ? obj.id_number : 0
  elsif species.is_a?(GameData::Species)
    return species.id_number
  else
    dexNum = species
  end
  return dexNum
end

def getFusedPokemonIdFromDexNum(body_dex, head_dex)
  body_sym = GameData::SpeciesId.normalize(body_dex)
  head_sym = GameData::SpeciesId.normalize(head_dex)
  return GameData::SpeciesId.build_fusion(head_sym, body_sym)
end

def getFusedPokemonIdFromSymbols(body_dex, head_dex)
  body_sym = GameData::SpeciesId.normalize(body_dex)
  head_sym = GameData::SpeciesId.normalize(head_dex)
  return GameData::SpeciesId.build_fusion(head_sym, body_sym)
end

def generateFusionIcon(dexNum, path)
  begin
    IO.copy_stream(dexNum, path)
    return true
  rescue
    return false
  end
end

def ensureFusionIconExists
  directory_name = "Graphics/Pokemon/FusionIcons"
  Dir.mkdir(directory_name) unless File.exists?(directory_name)
end

def addNewTripleFusion(pokemon1, pokemon2, pokemon3, level = 1)
  return if !pokemon1
  return if !pokemon2
  return if !pokemon3

  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return false
  end

  pokemon = TripleFusion.new(pokemon1, pokemon2, pokemon3, level)
  pokemon.calc_stats
  pbMessage(_INTL("{1} obtained {2}!\\me[Pkmn get]\\wtnp[80]\1", $Trainer.name, pokemon.name))
  pbNicknameAndStore(pokemon)
  #$Trainer.pokedex.register(pokemon)
  return true
end
