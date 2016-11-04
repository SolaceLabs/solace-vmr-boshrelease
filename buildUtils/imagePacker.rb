require 'rubygems/package'
require 'zlib'
require 'json'

fileEntries = Hash.new
dirEntries = Hash.new
manifests = Array.new
repositories = Hash.new

# Generate the merged gzipped image tarball
Zlib::GzipWriter.wrap(STDOUT) do |gz|
  Gem::Package::TarWriter.new(gz) do |targetTar|
    ARGV.each do |image|
      Gem::Package::TarReader.new(Zlib::GzipReader.open(image)) do |inputTar|
        inputTar.each do |entry|
          if entry.full_name == "manifest.json"
            # Merge the manifests into an array
            manifest = JSON.parse(entry.read)
            manifest.each do |element|
              manifests.push(element)
            end
          elsif entry.full_name == "repositories"
            # Merge all repositories together.  Add all images, and merge all tags.
            repository = JSON.parse(entry.read)
            repository.each do |image_name, tags|
              if repositories.has_key?(image_name)
                tags.each do |tag, hash|
                  repositories[image_name][tag] = hash
                end
              else
                repositories[image_name] = tags
              end
            end
          else
            if entry.directory?
              if !dirEntries.has_key?(entry.full_name)
                targetTar.mkdir(entry.full_name, 0755)
                dirEntries[entry.full_name] = entry
              end
            else
              if !fileEntries.has_key?(entry.full_name)
                entryData = entry.read
                targetTar.add_file_simple(entry.full_name, 0644, entryData.length) do |io|
                  io.write(entryData)
                end
                fileEntries[entry.full_name] = entry
              end
            end
          end
        end
      end
    end

    manifestsData = JSON.pretty_generate(manifests)
    targetTar.add_file_simple("manifest.json", 0644, manifestsData.length) do |io|
      io.write(manifestsData)
    end

    respositoriesData = JSON.pretty_generate(repositories)
    targetTar.add_file_simple("repositories", 0644, respositoriesData.length) do |io|
      io.write(respositoriesData)
    end
  end
end
