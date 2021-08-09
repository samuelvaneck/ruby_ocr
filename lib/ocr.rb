# frozen_string_literal: treu

require 'rtesseract'
require 'zaru'

class OCR
  SUPPORTED_FILES = ['image/png', 'image/gif', 'image/jpeg', 'application/pdf'].freeze
  ENV['TESSDATA_PREFIX'] = File.join(File.dirname(__FILE__), 'tessdata')

  attr_reader :filename, :params

  def initialize(filename, params, settings)
    @filename = filename
    @params = params
    @settings = settings
  end

  def file_to_text(filename, params)
    preserve_interword_spaces = params[:preserve_interword_spaces] == 'on' ? 1 : 0
    file_location = File.join(@settings.files, filename)
    image = RTesseract.new(file_location,
                           lang: params[:language],
                           psm: params[:psm],
                           oem: params[:oem],
                           preserve_interword_spaces: preserve_interword_spaces)
    image.to_s
  end
end
