#IMPORTANT
#La méthode   def pbCheckEvolution(pokemon,item=0)
#dans PokemonFusion (class PokemonFusionScene)
#a été modifiée et pour une raison ou une autre ca marche
#pas quand on la copie ici. 
#Donc NE PAS OUBLIER DE LE COPIER AVEC


############################
#   MODIFIED CODE SECTION  #
###########################
#
# require PokeBattle_Scene_edited2
#         PokemonFusion
#

NB_POKEMON = Settings::NB_POKEMON#809#420 #351  #aussi CONST_NB_POKE
CONST_NB_POKE = NB_POKEMON

def pbPokemonBitmapFile(species)
  # Used by the Pokédex
  # Load normal bitmap
  #get body and head num
  dex_num = getDexNumberForSpecies(species)
  isFused = species_is_fusion(species)
  if isFused
    if dex_num >= ZAPMOLCUNO_NB
      path = getSpecialSpriteName(dex_num) + ".png"
    else
      poke1 = getBodyID(species) #getBasePokemonID(species,true)
      poke2 = getHeadID(species, poke1) #getBasePokemonID(species,false)
      path = GetSpritePath(poke1, poke2, isFused)
    end
  else
    path = GetSpritePath(species, species, false)
  end
  ret = sprintf(path) rescue nil
  if !pbResolveBitmap(ret)
    ret = "Graphics/Battlers/000.png"
  end
  return ret
end


def pbLoadPokemonBitmap(pokemon, species, back = false)
  #species est utilisé par elitebattle mais ca sert a rien
  return pbLoadPokemonBitmapSpecies(pokemon, pokemon.species, back)
end

def getEggBitmapPath(pokemon)
  dex_num = getDexNumberForSpecies(pokemon.species)
  bitmapFileName = sprintf("Graphics/Battlers/Eggs/%s", getConstantName(PBSpecies, pokemon.species)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    if dex_num >= NUM_ZAPMOLCUNO
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


def pbLoadPokemonBitmapSpecies(pokemon, species, back = false, scale = POKEMONSPRITESCALE)
  ret = nil
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  dex_num = getDexNumberForSpecies(species)
  if pokemon.isEgg?
    bitmapFileName = getEggBitmapPath(pokemon)
    bitmapFileName = pbResolveBitmap(bitmapFileName)
  elsif dex_num >= ZAPMOLCUNO_NB #zapmolcuno
    bitmapFileName = getSpecialSpriteName(dex_num) #sprintf("Graphics/Battlers/special/144.145.146")
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName = sprintf("Graphics/Battlers/special/000")
    end
    bitmapFileName = pbResolveBitmap(bitmapFileName)
  else
    #edited here
    isFusion = species_is_fusion(species)
    if isFusion
      poke1 = getBodyID(species)
      poke2 = getHeadID(species, poke1)
    else
      poke1 = species
      poke2 = species
    end
    bitmapFileName = GetSpritePath(poke1, poke2, isFusion)
    # Alter bitmap if supported
    alterBitmap = (MultipleForms.getFunction(species, "alterBitmap") rescue nil)
  end
  if bitmapFileName && alterBitmap
    animatedBitmap = AnimatedBitmap.new(bitmapFileName)
    copiedBitmap = animatedBitmap.copy
    animatedBitmap.dispose
    copiedBitmap.each { |bitmap| alterBitmap.call(pokemon, bitmap) }
    ret = copiedBitmap
  elsif bitmapFileName
    ret = AnimatedBitmap.new(bitmapFileName)
  end
  return ret
end

#######################
#   NEW CODE SECTION  #
#######################

DOSSIERCUSTOMSPRITES = "CustomBattlers"
BATTLERSPATH = "Battlers"

def GetSpritePath(poke1, poke2, isFused)
  #Check if custom exists
  head_num = getDexNumberForSpecies(poke2)
  body_num = getDexNumberForSpecies(poke1)
  spritename = GetSpriteName(body_num, head_num, isFused)
  pathCustom = sprintf("Graphics/%s/indexed/%s/%s.png", DOSSIERCUSTOMSPRITES, head_num, spritename)
  pathReg = sprintf("Graphics/%s/%s/%s.png", BATTLERSPATH, head_num, spritename)
  path = pbResolveBitmap(pathCustom) && $game_variables[196] == 0 ? pathCustom : pathReg
  return path
end


def GetSpritePathForced(poke1, poke2, isFused)
  #Check if custom exists
  spritename = GetSpriteName(poke1, poke2, isFused)
  pathCustom = sprintf("Graphics/%s/indexed/%s/%s.png", DOSSIERCUSTOMSPRITES, poke2, spritename)
  pathReg = sprintf("Graphics/%s/%s/%s.png", BATTLERSPATH, poke2, spritename)
  path = pbResolveBitmap(pathCustom) ? pathCustom : pathReg
  return path
end


def GetSpriteName(poke1, poke2, isFused)
  ret = isFused ? sprintf("%d.%d", poke2, poke1) : sprintf("%d", poke2) rescue nil
  return ret
end

#in: pokemon number
def Kernel.isPartPokemon(src, target)
  
  src_num = getDexNumberForSpecies(src)
  target_num = getDexNumberForSpecies(target)
  return true if src_num == target_num
  return false if src_num <= NB_POKEMON
  # Fakemon range check
  return false if src_num >= Settings::KURAY_CUSTOM_POKEMONS
  
  # Generation check if possible
  species_data = GameData::Species.try_get(src)
  return false if species_data && species_data.generation == 99
  
  bod = getBasePokemonID(src_num, true)
  head = getBasePokemonID(src_num, false)
  return bod == target || head == target
end

##EDITED HERE
#Retourne le pokemon de base 
#param1 = int
#param2 = true pour body, false pour head
#return int du pokemon de base
def getBasePokemonID(pokemon, body = true)
  if pokemon.respond_to?(:species)
    return getBasePokemonID(pokemon.species, body)
  end
  if pokemon.is_a?(GameData::Species) || pokemon.respond_to?(:id)
    return getBasePokemonID(pokemon.id, body)
  end
  id = GameData::SpeciesId.normalize(pokemon)
  if GameData::SpeciesId.fusion?(id)
    head_id, body_id = GameData::SpeciesId.split_fusion(id)
    return body ? body_id : head_id
  end
  return id
end

###################
##  CONVERTER     #
###################
def convertAllPokemon()
  Kernel.pbMessage(_INTL("Conversion from numeric IDs is no longer supported. Please migrate to symbol IDs."))
  return
  Kernel.pbMessage(_INTL("The game has detected that your previous savefile was from an earlier build of the game."))
  Kernel.pbMessage(_INTL("In order to play this version, your Pokémon need to be converted to their new Pokédex numbers. "))
  Kernel.pbMessage(_INTL("If you were playing Randomized mode, the trainers and wild Pokémon will also need to be reshuffled."))


  if (Kernel.pbConfirmMessage(_INTL("Convert your Pokémon?")))

    #get previous version
    msgwindow = Kernel.pbCreateMessageWindow(nil)
    msgwindow.text = "What is the last version of the game you played?"
    choice = Kernel.pbShowCommands(msgwindow, [
        "4.7        (September 2020)",
        "4.5-4.6.2        (2019-2020)",
        "4.2-4.4           (2019)",
        "4.0-4.1           (2018-2019)",
        "3.x or earlier (2015-2018)"], -1)
    case choice
    when 0
      prev_total = 381
    when 1
      prev_total = 351
    when 2
      prev_total = 315
    when 3
      prev_total = 275
    when 4
      prev_total = 151
    else
      prev_total = 381
    end
    Kernel.pbDisposeMessageWindow(msgwindow)

    pbEachPokemon { |poke, box|
      if poke.species >= NB_POKEMON
        pf = poke.species
        pBody = (pf / prev_total).round
        pHead = pf - (prev_total * pBody)

        #   Kernel.pbMessage(_INTL("pbod {1} pHead {2}, species: {3})",pBody,pHead,pf))

        prev_max_value = (prev_total * prev_total) + prev_total
        if pf >= prev_max_value
          newSpecies = convertTripleFusion(pf, prev_max_value)
          if newSpecies == nil
            boxname = box == -1 ? "Party" : box
            Kernel.pbMessage(_INTL("Invalid Pokémon detected in box {1}:\n num. {2}, {3} (lv. {4})", boxname, pf, poke.name, poke.level))
            if (Kernel.pbConfirmMessage(_INTL("Delete Pokémon and continue?")))
              poke = nil
              next
            else
              Kernel.pbMessage(_INTL("Conversion cancelled. Please restart the game."))
              Graphics.freeze
            end
          end
        end

        newSpecies = pBody * NB_POKEMON + pHead
        poke.species = newSpecies
      end
    }
    Kernel.initRandomTypeArray()
    if $game_switches[SWITCH_RANDOM_TRAINERS] #randomized trainers
      Kernel.pbShuffleTrainers()
    end
    if $game_switches[956] #randomized pokemon
      range = pbGet(197) == nil ? 25 : pbGet(197)
      Kernel.pbShuffleDex(range, 1)
    end

  end

end

def convertTripleFusion(species, prev_max_value)
  if prev_max_value == (351 * 351) + 351
    case species
    when 123553
      return 145543
    when 123554
      return 145544
    when 123555
      return 145545
    when 123556
      return 145546
    when 123557
      return 145547
    when 123558
      return 145548
    else
      return nil
    end
  end
  return nil
end


def convertTrainers()
  if ($game_switches[SWITCH_RANDOM_TRAINERS])
    Kernel.pbShuffleTrainers()
  end
end

def convertAllPokemonManually()

  if (Kernel.pbConfirmMessage(_INTL("When you last played the game, where there any gen 2 Pokémon?")))
    #4.0
    prev_total = 315
  else
    #3.0
    prev_total = 151
  end
  convertPokemon(prev_total)
end

def convertPokemon(prev_total = 275)
  pbEachPokemon { |poke, box|
    if poke.species >= NB_POKEMON
      pf = poke.species
      pBody = (pf / prev_total).round
      pHead = pf - (prev_total * pBody)

      newSpecies = pBody * NB_POKEMON + pHead
      poke.species = newSpecies
    end
  }
end


