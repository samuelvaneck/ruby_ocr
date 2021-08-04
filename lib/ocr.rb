# frozen_string_literal: true

require 'rtesseract'
require 'erb'
require 'sinatra/base'
require 'zaru'

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
      filename = if params[:file][:type] == 'application/pdf'
                   pdf_to_image(File.join(settings.files, filename))
                 else
                   filename
                 end
      @text = file_to_text(filename, params[:language], params[:psm])
      remove_temp_files

      flash 'Upload successful'
    else
      flash 'You have to choose a file'
    end
    erb :index, { layout: :application }
  end

  private

  def file_to_text(filename, lang = 'eng', psm = 4)
    image = RTesseract.new(File.join(settings.files, filename), lang: lang, psm: psm)
    image.to_s
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

    `cd #{public_files} && pdftoppm -jpeg -jpegopt quality=100 -r 300 #{pdf_file} #{filename}`

    "#{filename.split('/')[-1]}-1.jpg"
  end

  def remove_temp_files
    `cd #{File.join(settings.files)} && rm *`
  end
end
