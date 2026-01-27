require 'json'

# Load the migration map
migration_map = JSON.parse(File.read('migration_map.json'))

# Load the dex.json
dex_path = 'Data/pokedex/dex.json'
dex_data = JSON.parse(File.read(dex_path))

migrated_count = 0

dex_data.each do |entry|
  if entry['sprite'] =~ /^(\d+)\.(\d+)(\.png)?$/
    head_num = $1
    body_num = $2
    
    head_sym = "#{head_num}_0"
    body_sym = "#{body_num}_0"

    # New format
    entry['species'] = "F__#{head_sym}.#{body_sym}"
    migrated_count += 1
  elsif entry['sprite'] =~ /^(\d+)(\.png)?$/
    num = $1
    entry['species'] = "#{num}_0"
    migrated_count += 1
  end
end

File.write('Data/pokedex/dex_migrated.json', JSON.pretty_generate(dex_data))
puts "Successfully migrated #{migrated_count} entries in dex.json to dex_migrated.json."
