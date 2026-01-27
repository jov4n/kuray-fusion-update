module FakemonUtility
  FAKEMON_DATA_PATH = "Data/fakemon.json"
  INTERNAL_NAME_TO_ID = {}

  def self.parse_pokengine_record(line)
    return nil if !line || !line.include?("MONS[")
    start_idx = line.index("{")
    end_idx = line.rindex("}")
    return nil if !start_idx || !end_idx || end_idx <= start_idx
    json_str = line[start_idx..end_idx]
    data = HTTPLite::JSON.parse(json_str) rescue nil
    return nil if !data.is_a?(Hash)
    return data
  end

  def self.gender_ratio_from_percent(raw)
    return "Genderless" if raw.nil?
    pct = raw.to_f
    return "AlwaysMale" if pct <= 0.0
    return "AlwaysFemale" if pct >= 100.0
    return "FemaleOneEighth" if pct <= 12.5
    return "Female25Percent" if pct <= 25.0
    return "Female50Percent" if pct <= 50.0
    return "Female75Percent" if pct <= 75.0
    return "FemaleSevenEighths"
  end

  def self.steps_to_hatch_pool
    return @steps_to_hatch_pool if @steps_to_hatch_pool
    pool = []
    pbs_path = "PBS/pokemon.txt"
    if File.exist?(pbs_path)
      File.foreach(pbs_path) do |line|
        if line =~ /^StepsToHatch\s*=\s*(\d+)/i
          pool << $1.to_i
        end
      end
    end
    @steps_to_hatch_pool = pool
    return @steps_to_hatch_pool
  end

  def self.random_steps_to_hatch
    pool = steps_to_hatch_pool
    return pool.sample if pool && pool.length > 0
    return 5000
  end

  def self.random_abilities(count = 1)
    return [] if count <= 0
    if defined?(GameData::Ability)
      keys = GameData::Ability.keys
      return [] if !keys || keys.empty?
      return keys.sample(count).map { |k| ":" + k.to_s }
    end
    return []
  end

  def self.ordinal_suffix(index)
    return "Two" if index == 2
    return "Three" if index == 3
    return "Four" if index == 4
    return "Five" if index == 5
    return "Six" if index == 6
    return "Seven" if index == 7
    return "Eight" if index == 8
    return "Nine" if index == 9
    return "Ten" if index == 10
    return index.to_s
  end

  def self.unique_internal_name(base_internal, existing_internal)
    base = base_internal.to_s.upcase.gsub(/[^A-Z0-9_]/, "")
    return base if !existing_internal.include?(base)
    i = 2
    loop do
      candidate = "#{base}#{ordinal_suffix(i).upcase}"
      return candidate if !existing_internal.include?(candidate)
      i += 1
    end
  end

  def self.unique_display_name(base_name, target_internal)
    base = base_name.to_s
    return base if target_internal == base.upcase.gsub(/[^A-Z0-9_]/, "")
    suffix = target_internal.sub(base.upcase.gsub(/[^A-Z0-9_]/, ""), "")
    return base if suffix.empty?
    return base + " " + suffix.capitalize
  end

  def self.pokengine_to_fakemon(data, existing_internal)
    name = (data["name"] || "FAKEMON").to_s
    base_internal = name.upcase.gsub(/[^A-Z0-9_]/, "")
    internal = unique_internal_name(base_internal, existing_internal)
    display_name = unique_display_name(name, internal)
    abilities = random_abilities(1)
    {
      "name" => display_name,
      "internalName" => internal,
      "type1" => ":NORMAL",
      "type2" => "",
      "hp" => (data.dig("stats", "hp") || 60),
      "atk" => (data.dig("stats", "att") || 60),
      "def" => (data.dig("stats", "def") || 60),
      "spa" => (data.dig("stats", "spatt") || 60),
      "spd" => (data.dig("stats", "spdef") || 60),
      "spe" => (data.dig("stats", "spe") || 60),
      "abilities" => abilities,
      "genderRate" => gender_ratio_from_percent(data["genderRatio"]),
      "growthRate" => "Medium",
      "baseExp" => (data.dig("yield", "exp") || 100),
      "rareness" => (data["catchRate"] || 45),
      "happiness" => (data["happiness"] || 70),
      "compatibility" => "Undiscovered",
      "stepsToHatch" => random_steps_to_hatch,
      "height" => (data["height"] || 1.0).to_f,
      "weight" => (data["weight"] || 10.0).to_f,
      "color" => "Red",
      "shape" => "Head",
      "habitat" => "None",
      "kind" => (data["classification"] || "Fakemon"),
      "pokedex" => (data["flavor"] || "A newly discovered Fakemon."),
      "author" => "PE",
      "generation" => 99,
      "pe_uid" => data["uid"],
      "pe_types" => data["types"],
      "pe_abilities" => data["abilities"],
      "pe_hiddenAbility" => data["hiddenAbility"],
      "pe_moveset" => data["moveset"]
    }
  end

  def self.import_pokengine_file(path)
    return false if !File.exist?(path)
    existing = []
    if File.exist?(FAKEMON_DATA_PATH)
      existing = HTTPLite::JSON.parse(File.read(FAKEMON_DATA_PATH)) rescue []
    end
    existing = [] if !existing.is_a?(Array)
    existing_internal = existing.map { |e| (e["internalName"] || "").to_s.upcase }
    imported = 0
    File.foreach(path) do |line|
      data = parse_pokengine_record(line)
      next if !data
      entry = pokengine_to_fakemon(data, existing_internal)
      next if existing_internal.include?(entry["internalName"].to_s.upcase)
      existing << entry
      existing_internal << entry["internalName"].to_s.upcase
      imported += 1
    end
    File.open(FAKEMON_DATA_PATH, "wb") { |f| f.write(HTTPLite::JSON.generate(existing)) }
    return imported
  end
  
  def self.inject_all
    return unless File.exist?(FAKEMON_DATA_PATH)
    
    file_content = File.binread(FAKEMON_DATA_PATH)
    # Strip UTF-8 BOM if present to avoid JSON parse errors
    if file_content.bytesize >= 3 && file_content.byteslice(0, 3) == "\xEF\xBB\xBF"
      file_content = file_content.byteslice(3, file_content.bytesize - 3)
    end
    begin
      data = HTTPLite::JSON.parse(file_content)
    rescue => e
      echoln "FakemonUtility: Failed to parse JSON: #{e.message}"
      return
    end

    data.each_with_index do |p, index|
      register_fakemon(p, index)
    end
    echoln "FakemonUtility: Successfully injected #{data.length} Fakemon."
  end

  def self.register_fakemon(p, index)
    internal_name = (p['internalName'] || "FAKEMON").to_s.strip.upcase
    author = (p['author'] || "FAKEMON").to_s.strip.upcase.gsub(/[^A-Z0-9]/, "")
    author = "FAKEMON" if author.empty?
    if internal_name.match?(/\A\d+_[A-Z0-9]+\z/)
      id = internal_name.to_sym
    else
      id = "#{index + 1}_#{author}".to_sym
    end
    INTERNAL_NAME_TO_ID[internal_name.to_sym] = id
    return if GameData::Species::DATA.has_key?(id) # Avoid double registration
    
    # id_number decoupled - relying on Symbol lookup
    # Clean types and other symbols
    type1 = (p['type1'] || ":NORMAL").gsub(':', '').to_sym
    type2 = p['type2'] && !p['type2'].empty? ? p['type2'].gsub(':', '').to_sym : nil
    abilities = (p['abilities'] || []).map { |a| a.gsub(':', '').to_sym }
    growth_rate = (p['growthRate'] || "Medium").to_sym
    gender_ratio = (p['genderRate'] || "Female50Percent").to_sym
    color = (p['color'] || "Red").to_sym
    shape = (p['shape'] || "Head").to_sym
    habitat = (p['habitat'] || "None").to_sym
    compatibility = (p['compatibility'] || "Undiscovered").split(',').map { |c| c.strip.to_sym }

    hash = {
      :id => id,
      :id_number => index + 1,
      :namespace => author,
      :internal_key => internal_name,
      :name => p['name'] || p['internalName'],
      :type1 => type1,
      :type2 => type2,
      :base_stats => {
        :HP => p['hp'] || 60,
        :ATTACK => p['atk'] || 60,
        :DEFENSE => p['def'] || 60,
        :SPECIAL_ATTACK => p['spa'] || 60,
        :SPECIAL_DEFENSE => p['spd'] || 60,
        :SPEED => p['spe'] || 60
      },
      :base_exp => p['baseExp'] || 100,
      :growth_rate => growth_rate,
      :gender_ratio => gender_ratio,
      :catch_rate => p['rareness'] || 45,
      :happiness => p['happiness'] || 70,
      :moves => [[1, :TACKLE]], 
      :abilities => abilities,
      :egg_groups => compatibility,
      :hatch_steps => p['stepsToHatch'] || 5000,
      :height => ((p['height'] || 1.0) * 10).to_i, 
      :weight => ((p['weight'] || 10.0) * 10).to_i, 
      :color => color,
      :shape => shape,
      :habitat => habitat,
      :category => p['kind'] || "Fakemon",
      :pokedex_entry => p['pokedex'] || "A newly discovered Fakemon.",
      :generation => 99,
      :author => author
    }

    GameData::Species.register(hash)
    sprite_front = p['spriteFront']
    if sprite_front && !sprite_front.to_s.empty?
      register_sprite_paths(id, front: sprite_front)
    end
    echoln "Registered Fakemon: #{id} (Author: #{hash[:author]})"
  end

  def self.resolve_internal_name(name)
    return nil if name.nil?
    INTERNAL_NAME_TO_ID[name.to_sym]
  end

  # Dynamic Sprite Map for decoupling filenames from IDs
  # Format: { :INTERNAL_NAME => { :front => "path", :back => "path", :icon => "path" } }
  SPRITE_MAP = {}

  def self.register_sprite_paths(id, front: nil, back: nil, icon: nil)
    id = id.to_sym
    SPRITE_MAP[id] ||= {}
    SPRITE_MAP[id][:front] = front if front
    SPRITE_MAP[id][:back] = back if back
    SPRITE_MAP[id][:icon] = icon if icon
  end

  def self.get_sprite_path(id, type)
    return nil unless SPRITE_MAP[id.to_sym]
    return SPRITE_MAP[id.to_sym][type]
  end

  def self.get_fakemon_list
    return [] unless File.exist?(FAKEMON_DATA_PATH)
    begin
      data = HTTPLite::JSON.parse(File.read(FAKEMON_DATA_PATH))
      return data.map { |p| resolve_internal_name((p['internalName'] || "").to_s.upcase) }.compact
    rescue
      return []
    end
  end
end

def pbFakemonPicker
  FakemonUtility.inject_all # Ensure everything in JSON is in memory
  list = FakemonUtility.get_fakemon_list
  if list.empty?
    pbMessage(_INTL("No Fakemon found in Data/fakemon.json."))
    return
  end

  commands = []
  for sym in list
    commands.push(sym.to_s)
  end
  commands.push(_INTL("Cancel"))

  loop do
    cmd = pbMessage(_INTL("Select a Fakemon to spawn:"), commands, commands.length)
    if cmd >= 0 && cmd < list.length
      begin
        pkmn = Pokemon.new(list[cmd], 5)
        if pbAddPokemon(pkmn)
          pbMessage(_INTL("Received {1}!", pkmn.name))
        end
      rescue Exception => e
        pbMessage(_INTL("Error spawning Fakemon: {1}", e.message))
        echoln e.backtrace
      end
    else
      break
    end
  end
end

# Hook into the game startup in multiple places to ensure it runs even if mods overwrite GameData.load_all
module GameData
  class Species
    class << self
      alias fakemon_load load
      def load
        fakemon_load
        FakemonUtility.inject_all
      end
    end
  end

  # We also keep this just in case
  class << self
    if self.respond_to?(:load_all)
      alias fakemon_load_all load_all
      def load_all
        fakemon_load_all
        FakemonUtility.inject_all
      end
    end
  end
end

# One final catch-all injection point: when the map scene starts
class Scene_Map
  alias fakemon_main main
  def main
    FakemonUtility.inject_all
    fakemon_main
  end
end
