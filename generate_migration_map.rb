require 'json'

# Define necessary classes for Marshal
module GameData
  class Ability; def self.marshal_load(array); end; end
  class Move; def self.marshal_load(array); end; end
  class Species
    attr_accessor :id, :id_number
    def self.marshal_load(array); end
  end
  class Type; def self.marshal_load(array); end; end
  class Item; def self.marshal_load(array); end; end
  class TrainerType; def self.marshal_load(array); end; end
end

def try_load(path)
  return nil unless File.exist?(path)
  begin
    Marshal.load(File.open(path, 'rb'))
  rescue ArgumentError => e
    if e.message =~ /undefined class\/module (.*)/
      parts = $1.split('::')
      curr = Object
      parts.each do |p|
        next if p == ""
        if !curr.const_defined?(p)
          curr.const_set(p, Class.new)
        end
        curr = curr.const_get(p)
      end
      retry
    end
    nil
  end
end

data_species = try_load('Data/species.dat')
mapping = {}

if data_species.is_a?(Hash)
  data_species.each do |key, value|
    next if key.is_a?(Integer)
    id_num = value.instance_variable_get(:@id_number)
    id_sym = key.to_s
    mapping[id_num] = id_sym if id_num
  end
end

File.write('migration_map.json', JSON.pretty_generate(mapping))
puts "Successfully created migration_map.json with #{mapping.size} entries."
