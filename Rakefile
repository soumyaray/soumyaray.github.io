
namespace :thumbnails do
  task :generate do
    Dir['source/**/*.png'].each do |file|
      thumb_file = file.split('.png').first+"_thumb.png"
      `convert -quiet -thumbnail 200 #{file} #{thumb_file}`
    end
  end

  task :delete do
    Dir['source/**/*_thumb.png'].each { |f| `rm #{f}` }
  end
end
