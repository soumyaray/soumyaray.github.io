
task :build do
  sh 'middleman build'
end

task :serve do
  sh 'middleman serve'
end

namespace :images do
  namespace :convert do
    def change_file_suffix(filename, suffix)
      base_filename = filename.gsub(/_.*\.png/,'')
      base_filename + "_#{suffix}.png"
    end

    # convert all images to thumbnail size (small)
    task :thumbnail do
      Dir['source/**/*_original.png'].each do |file|
        thumb_file = change_file_suffix(file, 'thumb')
        `convert -quiet -thumbnail 200 #{file} #{thumb_file}`
      end
    end

    # convert all images to full modal size (medium)
    task :modal do
      Dir['source/**/*_original.png'].each do |file|
        modal_file = change_file_suffix(file, 'modal')
        `convert #{file} -resize 568 #{modal_file}`
      end
    end
  end

  task :delete do
    Dir['source/**/*_thumb.png'].each { |f| `rm #{f}` }
  end
end

namespace :url do
  desc 'Generate integrity hash for a URL'
  # usage: $ rake url:integrity URL=http://example.org/script.js
  task :integrity do
    sha384 = `curl -L -s #{ENV['URL']} | openssl dgst -sha384 -binary | openssl enc -base64`
    puts "sha384-#{sha384}"
  end
end
