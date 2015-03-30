require 'hydra-file_characterization'
require 'mime/types'

module Hydra
  module Derivatives
    module ExtractMetadata

      def extract_metadata
        return unless has_content?
        Hydra::FileCharacterization.characterize(content, filename_for_characterization.join(""), :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      end

      # Restored method. It was required by other creatures
      def to_tempfile(&block)
        return unless has_content?
        Tempfile.open(filename_for_characterization) do |f|
          f.binmode
          if content.respond_to? :read
            f.write(content.read)
          else
            f.write(content)
          end
          content.rewind if content.respond_to? :rewind
          f.rewind
          yield(f)
        end
      end

      protected

      def filename_for_characterization
        registered_mime_type = MIME::Types[mime_type].first
        # A janky fix for DNG files but the quickest path to 
        # resolution for now. Register DNGs here until a better
        # solution is found
        if (registered_mime_type.nil? && 
            "image/x-adobe-dng" == mime_type)
          Logger.info("Registering image/x-adobe-dng MIME type")
          dng_type = MIME::Type.new('image/x-adobe-dng')
          dng_type.extensions = 'dng'
  
          MIME::Types.add(dng_type)
          registered_mime_type = dng_type 
        end

        Logger.warn "Unable to find a registered mime type for #{mime_type.inspect} on #{uri}" unless registered_mime_type
        extension = registered_mime_type ? ".#{registered_mime_type.extensions.first}" : ''
        version_id = 1 # TODO fixme
        m = /\/([^\/]*)$/.match(uri)
        ["#{m[1]}-#{version_id}", "#{extension}"]
      end
    end
  end
end
