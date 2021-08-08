# frozen_string_literal: true

require File.expand_path('../../ocr.rb', __FILE__)

class OCR::PDF < OCR
  def process_pdf_file
    @filename, page_count = pdf_to_image(File.join(@settings.files, @filename))
    rjust_value = page_count.to_s.split('').count

    (1..page_count).map do |page|
      file_to_text("#{@filename}-#{page.to_s.rjust(rjust_value, '0')}.jpg", @params)
    end
  end

  private

  def pdf_to_image(pdf_file)
    filename = pdf_file.split('.')[0].to_s
    public_files = File.join(@settings.files)
    page_count = pdf_page_count(pdf_file)

    `cd #{public_files} && pdftoppm -jpeg -jpegopt quality=100 -r 300 #{pdf_file} #{filename}`

    [filename.split('/')[-1].to_s, page_count]
  end

  def pdf_page_count(pdf_file)
    info = `cd #{File.join(@settings.files)} && pdfinfo #{pdf_file}`
    pages_index = info.split(/\n/).index { |x| x if x.include? 'Pages: ' }
    info.split(/\n/)[pages_index].delete('^0-9').to_i
  end
end
