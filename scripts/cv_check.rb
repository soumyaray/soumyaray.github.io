# frozen_string_literal: true

# Coverage report: which CV entries are missing from, or only partly in, the
# site's data/*.yml files. Read-only; it never edits the CV or the data.
#
# Usage (from the repo root):
#   ruby scripts/cv_check.rb [--all] [path/to/CV.pdf]
#
# It runs `pdftotext -layout` on the CV, splits the text into sections at
# the CV's upper-case headings, and splits each section into entries. An
# entry is "covered" when most of its distinctive words (4+ letters, years)
# appear in the data files that SECTIONS maps it to. Entries below
# THRESHOLD are printed; --all prints every entry with its score.
# Sections not in SECTIONS are listed as "not on site" so new CV sections
# are noticed.

require 'open3'

DEFAULT_CV = File.expand_path('~/Sync/Dropbox/Work/Curriculum Vitae/Soumya Ray - CV.pdf')
DATA = File.expand_path('../data', __dir__)
THRESHOLD = 0.75

# CV heading => [data files (without .yml), entry mode]
# :paper — an entry starts at a line that begins "Surname, I." (multi-line citations)
# :line  — every non-blank line is an entry
# :caps  — only lines that open with an upper-case name ("COURSE NAME (X): …");
#          the text before the first colon is the entry
SECTIONS = {
  'JOURNAL ARTICLES' => [%w[journal_papers], :paper],
  'COLLABORATION PAPERS' => [%w[journal_papers], :paper],
  'NOTABLE CONFERENCE PROCEEDINGS' => [%w[conference_papers], :paper],
  'BOOKS' => [%w[books], :paper],
  'BOOK CHAPTERS' => [%w[books], :paper],
  'EDITORIAL SERVICE' => [%w[service], :line],
  'CONFERENCE SERVICE' => [%w[service], :line],
  'AWARDS' => [%w[achievements], :line],
  'GRANTS' => [%w[achievements], :line],
  'SOFTWARE RELEASED' => [%w[software], :line],
  'INVITED ACADEMIC TALKS' => [%w[talks], :line],
  'SERVICE AT NATIONAL TSING HUA UNIVERSITY' => [%w[service], :line],
  'SERVICE AT COLLEGE OF TECHNOLOGY MANAGEMENT' => [%w[service], :line],
  'TEACHING EXPERIENCE' => [%w[instruction], :caps],
  'JOURNAL REVIEWS' => [%w[service], :line],
  'CONFERENCE REVIEWS' => [%w[service], :line],
  'PUBLIC ROLES' => [%w[service], :line]
}.freeze

STOP = %w[with from that this their they into have been were also over than such
          about through which what when where while under between information
          systems university national journal conference international].freeze

def norm(str)
  str.to_s.unicode_normalize(:nfkd).downcase.gsub(/[^a-z0-9]+/, ' ').strip
end

def tokens(str)
  norm(str).split.select { |w| w.length >= 4 && !STOP.include?(w) }.uniq
end

# A heading starts in column 0 and is all capitals, apart from an optional
# trailing "(explanation)".
def heading(line)
  return nil if line.start_with?(' ')

  key = line.strip.sub(/\s*\([^)]*\)\s*\z/, '')
  key.match?(/\A[A-Z][A-Z ,&\-–]{3,}\z/) && key.split.size <= 7 ? key : nil
end

argv = ARGV.dup
show_all = argv.delete('--all')
cv = argv.first || ENV.fetch('CV_PDF', DEFAULT_CV)
abort "CV not found: #{cv}" unless File.exist?(cv)
text, status = Open3.capture2('pdftotext', '-layout', cv, '-')
abort 'pdftotext failed (brew install poppler)' unless status.success?

lines = text.lines.map(&:rstrip).reject do |l|
  l.strip.empty? || l =~ /updated:\s*\w+-\d+-\d{4}\s*\z/ || l.strip =~ /\A\d+\z/
end

sections = Hash.new { |h, k| h[k] = [] }
current = nil
lines.each do |l|
  if (h = heading(l))
    current = h
    sections[current] # register even if empty
  elsif current
    sections[current] << l
  end
end

blobs = Hash.new do |h, files|
  h[files] = files.map { |f| File.join(DATA, "#{f}.yml") }
                  .select { |p| File.exist?(p) }
                  .map { |p| norm(File.read(p)) }.join(' ').split.to_h { |w| [w, true] }
end

sections.each do |name, body|
  files, mode = SECTIONS.find { |k, _| name.start_with?(k) }&.last
  unless files
    puts "== #{name}: not on site (#{body.size} lines)"
    next
  end
  entries = if mode == :paper
              body.slice_before { |l| l.strip =~ /\A\p{Lu}[\p{L}'\- ]+, \p{Lu}[\p{L}]?\./ }.map { |e| e.map(&:strip).join(' ') }
            elsif mode == :caps
              body.map(&:strip).grep(/\A[A-Z&]{3,}[A-Z&() ]+:/).map { |l| l.split(':').first }
            else
              # group labels such as "Council member:" are not entries
              body.map(&:strip).grep_v(/:\s*\z/)
            end
  blob = blobs[files]
  missing = files.reject { |f| File.exist?(File.join(DATA, "#{f}.yml")) }
  results = entries.filter_map do |e|
    toks = tokens(e)
    next if toks.empty?

    found = toks.count { |t| blob[t] }
    [found.fdiv(toks.size), e, toks.reject { |t| blob[t] }]
  end
  flagged = results.select { |score, _, _| show_all || score < THRESHOLD }
  note = missing.empty? ? '' : " (no data/#{missing.join(', ')}.yml yet)"
  puts "== #{name} → #{files.join(', ')}#{note}: #{results.size - results.count { |s, _, _| s < THRESHOLD }}/#{results.size} covered"
  flagged.each do |score, e, miss|
    puts format('  %3d%%  %s', (score * 100).round, e[0, 150])
    puts "        missing: #{miss.first(12).join(' ')}" unless miss.empty?
  end
end
