# frozen_string_literal: true

# Structural checks for data/*.yml: unique ids, highlights that resolve, linked files exist,
# required paper fields, sane page ranges.
# Usage (from the repo root): ruby scripts/check_data.rb
# Exits 1 when a check fails.

require 'yaml'

DATA = File.expand_path('../data', __dir__)
PAPER_FILES = %w[journal_papers conference_papers].freeze

def load(name)
  YAML.safe_load_file(File.join(DATA, "#{name}.yml"))
end

errors = []

# Every list of hashes with an `id` key must have unique ids.
def each_id_list(node, path, &block)
  case node
  when Array
    block.call(path, node) if node.any? { |e| e.is_a?(Hash) && e.key?('id') }
    node.each_with_index { |e, i| each_id_list(e, "#{path}[#{i}]", &block) }
  when Hash
    node.each { |k, v| each_id_list(v, "#{path}.#{k}", &block) }
  end
end

Dir[File.join(DATA, '*.yml')].each do |file|
  name = File.basename(file, '.yml')
  each_id_list(load(name), name) do |path, list|
    ids = list.map { |e| e['id'].to_s }
    ids.tally.select { |_, n| n > 1 }.each_key do |id|
      errors << "#{path}: duplicate id #{id.inspect}"
    end
  end
end

# Highlights must point at entries in the same file.
{ 'journal_papers' => 'papers', 'conference_papers' => 'papers',
  'instruction' => 'courses' }.each do |name, list_key|
  data = load(name)
  ids = Array(data[list_key]).map { |e| e['id'].to_s }
  Array(data['highlights']).each do |h|
    errors << "#{name}.highlights: #{h.inspect} is not an id in #{list_key}" unless ids.include?(h.to_s)
  end
end

social = load('social')
social_ids = social['identities'].values.flatten.map { |e| e['id'] }
Array(social['highlights']).each do |h|
  errors << "social.highlights: #{h.inspect} is not an identity id" unless social_ids.include?(h)
end

# Papers: required fields and ascending page ranges.
PAPER_FILES.each do |name|
  Array(load(name)['papers']).each do |p|
    label = "#{name}/#{p['id']}"
    %w[id authors year title].each do |f|
      errors << "#{label}: missing #{f}" if p[f].nil? || p[f].to_s.strip.empty?
    end
    unless p['journal'] || p['conference'] || p['book']
      errors << "#{label}: needs one of journal, conference, book"
    end
    if (m = p['pages'].to_s.match(/\A(\d+)\s*[-–]\s*(\d+)\z/)) && m[1].to_i >= m[2].to_i
      errors << "#{label}: page range #{p['pages']} is not ascending"
    end
  end
end

# Local files a page links to must exist under source/.
SOURCE = File.expand_path('../source', __dir__)
Array(load('instruction')['courses']).each do |c|
  link = c['syllabus'].to_s
  next if link.empty? || link.start_with?('http')

  errors << "instruction/#{c['id']}: syllabus #{link} not found in source/" unless File.exist?(File.join(SOURCE, link))
  errors << "instruction/#{c['id']}: local syllabus needs syllabus_term" unless c['syllabus_term']
end
Array(load('instruction')['courses']).each do |c|
  dir = File.join(SOURCE, 'images/courses', c['id'].to_s)
  errors << "instruction/#{c['id']}: no images/courses/#{c['id']}/" unless Dir.exist?(dir)
end

if errors.empty?
  puts 'data OK'
else
  puts errors
  exit 1
end
