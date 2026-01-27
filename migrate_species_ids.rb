#!/usr/bin/env ruby
# Migrates species IDs from numeric or legacy symbols to <NUMBER>_<AUTHOR> format.

AUTHOR = "0"
INCLUDE_SCRIPTS = ARGV.include?("--include-scripts")

def build_mapping(pokemon_path)
  mapping = {}
  current_section = nil
  new_id_for_section = nil

  File.readlines(pokemon_path, chomp: true).each do |line|
    if line =~ /^\s*\[\s*(.+?)\s*\]\s*$/
      current_section = Regexp.last_match(1)
      if current_section.match?(/^\d+$/)
        new_id_for_section = "#{current_section}_#{AUTHOR}"
      else
        new_id_for_section = current_section
      end
    elsif line =~ /^\s*InternalName\s*=\s*(.+?)\s*$/
      old_name = Regexp.last_match(1).strip
      mapping[old_name] = new_id_for_section if new_id_for_section
    end
  end
  mapping
end

def normalize_species_id(text, mapping)
  return mapping[text] if mapping.key?(text)
  return text
end

def convert_fusion_ids(content, mapping)
  # Convert legacy B<Body>H<Head> format
  content = content.gsub(/\bB(\d+)H(\d+)\b/) do
    body = "#{Regexp.last_match(1)}_#{AUTHOR}"
    head = "#{Regexp.last_match(2)}_#{AUTHOR}"
    "F__#{head}.#{body}"
  end

  # Convert legacy F__HEAD__BODY to F__HEAD.BODY with mapping
  content = content.gsub(/\bF__([A-Z0-9_]+)__([A-Z0-9_]+)\b/) do
    head = normalize_species_id(Regexp.last_match(1), mapping)
    body = normalize_species_id(Regexp.last_match(2), mapping)
    "F__#{head}.#{body}"
  end
  content
end

def replace_species_tokens(content, mapping)
  mapping.each do |old_id, new_id|
    next if old_id == new_id
    pattern = /(?<![A-Z0-9_])#{Regexp.escape(old_id)}(?![A-Z0-9_])/
    content = content.gsub(pattern, new_id)
  end
  convert_fusion_ids(content, mapping)
end

def migrate_pokemon_txt(path, mapping)
  output = []
  current_section = nil

  File.readlines(path, chomp: true).each do |line|
    if line =~ /^\s*\[\s*(.+?)\s*\]\s*$/
      current_section = Regexp.last_match(1)
      if current_section.match?(/^\d+$/)
        line = line.sub(current_section, "#{current_section}_#{AUTHOR}")
      end
    elsif line =~ /^\s*InternalName\s*=\s*(.+?)\s*$/
      old_name = Regexp.last_match(1).strip
      new_name = mapping[old_name]
      line = line.sub(old_name, new_name) if new_name
    end
    output << line
  end

  File.write(path, output.join("\n") + "\n")
end

def migrate_pokemonforms_txt(path, mapping)
  output = []
  File.readlines(path, chomp: true).each do |line|
    if line =~ /^\s*\[\s*(.+?)\s*\]\s*$/
      section = Regexp.last_match(1)
      parts = section.split(/[-,\s]/)
      if parts.length == 2
        species_part = normalize_species_id(parts[0], mapping)
        form_part = parts[1]
        new_section = "#{species_part},#{form_part}"
        line = line.sub(section, new_section)
      end
    end
    output << line
  end
  File.write(path, output.join("\n") + "\n")
end

def migrate_text_file(path, mapping)
  content = File.read(path)
  updated = replace_species_tokens(content, mapping)
  File.write(path, updated) if updated != content
end

pokemon_path = File.join("PBS", "pokemon.txt")
unless File.exist?(pokemon_path)
  warn "Missing PBS/pokemon.txt"
  exit 1
end

mapping = build_mapping(pokemon_path)
migrate_pokemon_txt(pokemon_path, mapping)

pokemonforms_path = File.join("PBS", "pokemonforms.txt")
migrate_pokemonforms_txt(pokemonforms_path, mapping) if File.exist?(pokemonforms_path)

Dir.glob("PBS/**/*.txt").each do |path|
  next if path.end_with?("pokemon.txt")
  next if path.end_with?("pokemonforms.txt")
  migrate_text_file(path, mapping)
end

Dir.glob("ExportedPokemons/**/*.json").each do |path|
  migrate_text_file(path, mapping)
end

Dir.glob("tools/MapEditorGo/maps_json/**/*.json").each do |path|
  migrate_text_file(path, mapping)
end

if INCLUDE_SCRIPTS
  Dir.glob("Data/Scripts/**/*.rb").each do |path|
    migrate_text_file(path, mapping)
  end
end

puts "Migration complete."
