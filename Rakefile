require 'fileutils'

CV_DIR = File.expand_path('~/Sync/Dropbox/Work/Curriculum Vitae')
CV_PDF = File.join(CV_DIR, 'Soumya Ray - CV.pdf')
CV_DOCX = File.join(CV_DIR, 'Soumya Ray - CV.docx')
CV_SITE = 'source/downloads/SoumyaRay-CV.pdf'

# The CV is read-only: this only copies it into the site.
desc 'Copy the latest CV PDF into the site download if it changed'
task :cv do
  next warn("CV not found, download left as is: #{CV_PDF}") unless File.exist?(CV_PDF)

  if File.exist?(CV_DOCX) && File.mtime(CV_DOCX) > File.mtime(CV_PDF)
    warn 'Warning: the CV .docx is newer than its PDF; export a fresh PDF if it has new content'
  end
  if FileUtils.compare_file(CV_PDF, CV_SITE)
    puts 'CV download is up to date'
  else
    FileUtils.cp(CV_PDF, CV_SITE)
    updated = `pdftotext "#{CV_PDF}" - 2>/dev/null`[/updated:\s*(\S+)/, 1]
    puts "CV download updated (#{updated || 'new PDF'}); commit #{CV_SITE} on source"
  end
end

desc 'Build the site master into build folder (brings in the latest CV first)'
task build: :cv do
  sh 'bundle exec middleman build'
end

desc 'Serve the site locally'
task :serve do
  sh 'bundle exec middleman serve'
end

# Image tasks
# (requires ImageMagick to be installed: e.g., brew install imagemagick)
namespace :images do
  namespace :convert do
    def change_file_suffix(filename, suffix)
      base_filename = filename.gsub(/_.*\.png/,'')
      base_filename + "_#{suffix}.png"
    end

    desc 'convert all images to thumbnail size (small)'
    task :thumbnail do
      Dir['source/**/*_original.png'].each do |file|
        thumb_file = change_file_suffix(file, 'thumb')
        `convert -quiet -thumbnail 200 #{file} #{thumb_file}`
      end
    end

    desc 'convert all images to full modal size (medium)'
    task :modal do
      Dir['source/**/*_original.png'].each do |file|
        modal_file = change_file_suffix(file, 'modal')
        `convert #{file} -resize 568 #{modal_file}`
      end
    end
  end

  desc 'delete all thumbnail images'
  task :delete do
    Dir['source/**/*_thumb.png'].each { |f| `rm #{f}` }
  end
end

namespace :url do
  # usage: $ rake url:integrity URL=http://example.org/script.js
  desc 'Generate integrity hash for a URL'
  task :integrity do
    sha384 = `curl -L -s #{ENV['URL']} | openssl dgst -sha384 -binary | openssl enc -base64`
    puts "sha384-#{sha384}"
  end
end
