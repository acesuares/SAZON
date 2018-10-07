# encoding: utf-8
require 'carrierwave'

class CkeditorAttachmentFileUploader < CarrierWave::Uploader::Base
  include Ckeditor::Backend::CarrierWave

  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  storage :file

  # rip the underscore from allowed filenames
  # this was NOT the way to do it, it turns out
  # CarrierWave::SanitizedFile.sanitize_regexp = /(_|[^[:word:]\.\-\+])/

  # this is the way to rip out the underscores. Carrierwave already rips out everything bad,
  # but is replaces it hardcoded with '_'

  # for some reason, MiniMagick needs to be enabled: https://github.com/galetahub/ckeditor/issues/820

  def filename
    original_filename.gsub('_','-') if original_filename
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/ckeditor/attachments/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    Ckeditor.attachment_file_types
  end
end
