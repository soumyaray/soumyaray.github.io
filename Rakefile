desc 'Build the site master into build folder'
task :build do
  sh 'bundle exec middleman build'
end

desc 'Serve the site locally'
task :serve do
  sh 'bundle exec middleman serve'
end

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
