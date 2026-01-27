def run_overhaul_tests
  echoln "--- STARTING ID OVERHAUL TESTS ---"
  
  # Test 1: Species lookup by canonical symbol
  pikachu = GameData::Species.get(GameData::SpeciesId.official_id(25))
  if pikachu
    echoln "SUCCESS: Lookup by symbol works for Pikachu (ID 25_0)"
  else
    echoln "FAILURE: Lookup by symbol failed for Pikachu"
  end
  
  # Test 2: Fusion Symbol generation
  fusion_sym = get_fusion_symbol(GameData::SpeciesId.official_id(25), GameData::SpeciesId.official_id(58))
  if fusion_sym == GameData::SpeciesId.build_fusion(GameData::SpeciesId.official_id(25), GameData::SpeciesId.official_id(58))
    echoln "SUCCESS: Fusion Symbol generated correctly: #{fusion_sym}"
  else
    echoln "FAILURE: Fusion Symbol mismatch: #{fusion_sym}"
  end
  
  # Test 4: Fusion lookup
  begin
    fused_data = GameData::Species.get(fusion_sym)
    if fused_data.is_a?(GameData::FusedSpecies)
      echoln "SUCCESS: FusedSpecies created from Symbol: #{fused_data.name}"
      echoln "Head: #{fused_data.head_pokemon.id}, Body: #{fused_data.body_pokemon.id}"
    else
      echoln "FAILURE: FusedSpecies lookup returned wrong type"
    end
  rescue => e
    echoln "FAILURE: Fusion lookup crashed: #{e.message}"
  end
  
  echoln "--- TESTS COMPLETED ---"
end

# Trigger tests on game start in debug mode
if $DEBUG
  # run_overhaul_tests
end
