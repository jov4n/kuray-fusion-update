require 'json'

# Load the migration map
migration_map = JSON.parse(File.read('migration_map.json'))

# Load all_entries.json
path = 'Data/pokedex/all_entries.json'
data = JSON.parse(File.read(path))

migrated_data = {}
migrated_count = 0

data.each do |key, value|
  sym = migration_map[key]
  if sym
    migrated_data[sym] = value
    migrated_count += 1
  else
    migrated_data[key] = value
  end
end

File.write('Data/pokedex/all_entries_migrated.json', JSON.pretty_generate(migrated_data))
puts "Successfully migrated #{migrated_count} keys in all_entries.json to all_entries_migrated.json."
