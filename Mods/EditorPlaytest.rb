# EditorPlaytest.rb
# Drops into the map specified in playtest.json, skipping the title screen.

module MapEditorPlaytest
  FILE_PATH = "playtest.json"

  def self.data
    return nil unless File.exist?(FILE_PATH)
    begin
      content = File.read(FILE_PATH)
      # Manual parsing to be dependency-free
      map_id = content.match(/"map_id":\s*(\d+)/)
      x = content.match(/"x":\s*(\d+)/)
      y = content.match(/"y":\s*(\d+)/)
      
      if map_id && x && y
        return { 
          :map_id => map_id[1].to_i, 
          :x => x[1].to_i,
          :y => y[1].to_i
        }
      end
    rescue
      return nil
    end
    return nil
  end

  def self.cleanup
    File.delete(FILE_PATH) if File.exist?(FILE_PATH)
  end
end

# Hook into Scene_Intro to skip the title screen
class Scene_Intro
  # A safe alias method that prevents stack overflow on F12 soft reset
  alias :map_editor_playtest_main :main unless method_defined?(:map_editor_playtest_main)
  
  def main
    # Check for playtest request
    if MapEditorPlaytest.data
      do_playtest_launch
      return
    end
    # Call original main if no playtest data
    map_editor_playtest_main
  end

  def do_playtest_launch
    data = MapEditorPlaytest.data
    return unless data

    # Clean up immediately
    MapEditorPlaytest.cleanup

    # Initialize standard global variables if they aren't already
    # This mimics standard RPG Maker XP / Essentials startup
    $game_system ||= ::Game_System.new
    $game_temp   ||= ::Game_Temp.new
    $game_switches ||= ::Game_Switches.new
    $game_variables ||= ::Game_Variables.new
    $game_self_switches ||= ::Game_SelfSwitches.new
    $game_screen ||= ::Game_Screen.new
    $game_map    ||= ::Game_Map.new
    $game_player ||= ::Game_Player.new
    
    # Pokemon Essentials / Infinite Fusion specific globals
    $PokemonGlobal ||= ::PokemonGlobalMetadata.new
    $PokemonMap    ||= ::PokemonMapMetadata.new
    $PokemonSystem ||= ::PokemonSystem.new
    
    # Infinite Fusion uses $Trainer instead of $game_party for player data
    # We initialize it if it doesn't exist.
    if !$Trainer
      trainer_type = nil
      if defined?(::GameData::TrainerType)
        ::GameData::TrainerType.each { |t| trainer_type = t.id; break }
      end
      trainer_type ||= :PLAYER # Fallback
      $Trainer = ::Player.new("Fill", trainer_type)
      $Trainer.character_ID = 0
      $game_player.character_name = "trchar000"
    end
    
    $PokemonBag  ||= ::PokemonBag.new
    $PokemonStorage ||= ::PokemonStorage.new
    $PokemonTemp ||= ::PokemonTemp.new

    # Map Factory is required for Scene_Map to render multiple connected maps
    $MapFactory = ::PokemonMapFactory.new(data[:map_id])
    $PokemonEncounters = ::PokemonEncounters.new
    $PokemonEncounters.setup(data[:map_id])
    
    begin
      # Load Database if needed (usually loaded in Main, but let's be safe)
      if $data_system.nil?
        $data_system = load_data("Data/System.rxdata")
        $data_tilesets = load_data("Data/Tilesets.rxdata")
        $data_common_events = load_data("Data/CommonEvents.rxdata")
        $data_items = load_data("Data/Items.rxdata")
        $data_skills = load_data("Data/Skills.rxdata")
        $data_weapons = load_data("Data/Weapons.rxdata")
        $data_armors = load_data("Data/Armors.rxdata")
        $data_enemies = load_data("Data/Enemies.rxdata")
        $data_troops = load_data("Data/Troops.rxdata")
        $data_states = load_data("Data/States.rxdata")
        $data_animations = load_data("Data/Animations.rxdata")
        $data_actors = load_data("Data/Actors.rxdata")
        $data_classes = load_data("Data/Classes.rxdata")
        $data_map_infos = load_data("Data/MapInfos.rxdata")
      end
    rescue Exception => e
      echopn "Database load error: #{e.message}"
    end

    # Setup New Game
    # $game_party.setup_starting_members # Unused in Essentials/Infinite Fusion
    $game_map = $MapFactory.map
    $game_map.setup(data[:map_id]) # Ensure internal setup is done if needed, though Factory usually does it. 
    # Actually Factory.map usually returns a map that is already setup or needs it.
    # In essentials v19, Factory does the setup. 
    # Lets keep setup(data[:map_id]) just in case it wasn't.
    
    # Move player to cursor position
    $game_player.moveto(data[:x], data[:y])
    $game_player.refresh
    
    # Reset timer/system settings
    $game_system.timer = 0
    $game_system.timer_working = false
    $game_system.save_disabled = false
    $game_system.menu_disabled = false
    $game_system.encounter_disabled = false
    $game_system.message_position = 2
    
    # Switch to Map
    $scene = Scene_Map.new
    $game_map.autoplay # Play BGM/BGS
    
    # Run the scene main loop manually because we hijacked Scene_Intro logic
    # and Scene_Map needs its own loop
    $scene.main
  end
end
