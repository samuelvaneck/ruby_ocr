# frozen_string_literal: true

require 'rtesseract'
require 'erb'
require 'sinatra/base'
require 'zaru'

require 'pry'

Tilt.register Tilt::ERBTemplate, 'html.erb'

class OCR < Sinatra::Base
  ENV['TESSDATA_PREFIX'] = File.join(File.dirname(__FILE__), 'tessdata')

  configure do
    enable :static
    enable :sessions

    set :views, File.join(File.dirname(__FILE__), 'views')
    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :files, File.join(settings.public_folder, 'files')
    set :unallowed_paths, ['.', '..']
  end

  helpers do
    def flash(message = '')
      session[:flash] = message
    end
  end

  before do
    @flash = session.delete(:flash)
  end

  not_found do
    slim 'h1 404'
  end

  error do
    slim "Error (#{request.env['sinatra.error']})"
  end

  get '/' do
    erb :index, { layout: :application }
  end

  post '/' do
    if params[:file]
      filename = save_file_to_public_folder(params[:file])
      @text = if params[:file][:type] == 'application/pdf'
                process_pdf_file(filename, params)
              else
                process_image_file(filename, params)
              end
      remove_temp_files

      flash 'Upload successful'
    else
      flash 'You have to choose a file'
    end
    erb :index, { layout: :application }
  end

  private

  def process_pdf_file(filename, params)
    filename, page_count = pdf_to_image(File.join(settings.files, filename))
    (1..page_count).map do |page|
      file_to_text("#{filename}-#{page}.jpg", params)
    end
  end

  def process_image_file(filename, params)
    [file_to_text(filename, params)]
  end

  def file_to_text(filename, params)
    preserve_interword_spaces = params[:preserve_interword_spaces] == 'on' ? 1 : 0
    file_location = File.join(settings.files, filename)
    image = RTesseract.new(file_location,
                           lang: params[:language],
                           psm: params[:psm],
                           oem: params[:oem],
                           preserve_interword_spaces: preserve_interword_spaces)
    text = image.to_s
    preserve_spaces(text)
  end

  def save_file_to_public_folder(params_file)
    filename = params_file[:filename]
    file = params_file[:tempfile]
    safe_filename = Zaru.sanitize!(filename).downcase.gsub(/\s/, '_')

    File.open(File.join(settings.files, safe_filename), 'wb') do |file_to_write|
      file_to_write.write(file.read)
    end

    safe_filename
  end

  def pdf_to_image(pdf_file)
    filename = pdf_file.split('.')[0].to_s
    public_files = File.join(settings.files)
    page_count = pdf_page_count(pdf_file)

    `cd #{public_files} && pdftoppm -jpeg -jpegopt quality=100 -r 300 #{pdf_file} #{filename}`

    [filename.split('/')[-1].to_s, page_count]
  end

  def remove_temp_files
    `cd #{File.join(settings.files)} && rm *`
  end

  def preserve_spaces(text)
    text.gsub(' ', '&nbsp;')
  end

  def pdf_page_count(pdf_file)
    info = `cd #{File.join(settings.files)} && pdfinfo #{pdf_file}`
    pages_index = info.split(/\n/).index { |x| x if x.include? 'Pages: ' }
    info.split(/\n/)[pages_index].delete('^0-9').to_i
  end
end
