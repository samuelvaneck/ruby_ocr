# frozen_string_literal: true

require File.expand_path('../../ocr.rb', __FILE__)

class OCR::Image < OCR
  def process_file
    [file_to_text(@filename, @params)]
  end
end
