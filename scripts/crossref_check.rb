# frozen_string_literal: true

# Compare each paper in data/journal_papers.yml and data/conference_papers.yml
# with its Crossref record: author order, year, volume, issue, pages, DOI.
# Looks a paper up by its `doi:` field when present, else by title.
# Read-only: it prints differences and never edits the YAML.
# Usage (from the repo root): ruby scripts/crossref_check.rb [id ...]

require 'yaml'
require 'json'
require 'net/http'
require 'uri'

DATA = File.expand_path('../data', __dir__)
FILES = %w[journal_papers conference_papers].freeze
API = 'https://api.crossref.org/works'
UA = 'soumyaray.com-data-check (mailto:soumya.ray@gmail.com)'

def get_json(uri)
  res = Net::HTTP.get_response(uri, { 'User-Agent' => UA })
  res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body)['message'] : nil
rescue StandardError
  nil
end

def norm(str)
  str.to_s.unicode_normalize(:nfkd).downcase.gsub(/[^a-z0-9]+/, ' ').strip
end

def lookup(paper)
  if paper['doi']
    get_json(URI("#{API}/#{URI.encode_www_form_component(paper['doi'])}"))
  else
    uri = URI(API)
    uri.query = URI.encode_www_form('query.bibliographic' => paper['title'], 'rows' => 5)
    items = get_json(uri)&.fetch('items', []) || []
    items.find { |it| norm(Array(it['title']).first) == norm(paper['title']) } ||
      items.find { |it| norm(Array(it['title']).first).start_with?(norm(paper['title'])[0, 40]) }
  end
end

def year_of(item)
  parts = (item['published-print'] || item['journal-issue']&.dig('published-print') || item['published'])
  parts&.dig('date-parts', 0, 0)
end

def site_surnames(paper)
  Array(paper['authors']).map { |a| norm(a.to_s.split(',').first) }
end

only = ARGV
FILES.each do |file|
  Array(YAML.safe_load_file(File.join(DATA, "#{file}.yml"))['papers']).each do |paper|
    next unless only.empty? || only.include?(paper['id'].to_s)

    item = lookup(paper)
    unless item
      puts "#{file}/#{paper['id']}: no Crossref match (#{paper['title']})"
      next
    end
    diffs = []
    # Crossref sometimes lists affiliations as `name`-only authors; keep people only.
    cr_authors = Array(item['author']).filter_map { |a| norm(a['family']) if a['family'] }
    site = site_surnames(paper)
    people = site.reject { |s| s.include?('collaboration') }
    diffs << "authors site=#{site.join('/')} crossref=#{cr_authors.join('/')}" if
      !cr_authors.empty? && people != cr_authors.first(people.size)
    { 'year' => year_of(item), 'volume' => item['volume'], 'issue' => item['issue'],
      'pages' => item['page'] || item['article-number'] }.each do |field, cr|
      next if cr.nil?

      ours = (field == 'pages' ? paper['pages'] || paper['article'] : paper[field]).to_s.tr('–', '-')
      diffs << "#{field} site=#{paper[field].inspect} crossref=#{cr.inspect}" unless ours == cr.to_s
    end
    diffs << "doi missing on site: #{item['DOI']}" unless paper['doi']
    status = diffs.empty? ? 'OK' : "\n    #{diffs.join("\n    ")}"
    puts "#{file}/#{paper['id']}: #{status}"
    sleep 0.2
  end
end
