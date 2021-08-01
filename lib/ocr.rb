# frozen_string_literal: true

require 'rtesseract'
require 'erb'
require 'sinatra/base'

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

  post '/upload' do
    if params[:file]
      save_file_to_public_foler(params[:file])
      file_location = File.join(settings.files, params[:file][:filename])
      lang = params[:language]
      @text = file_to_text(file_location, lang)

      flash 'Upload successful'
    else
      flash 'You have to choose a file'
    end

    erb :index, { layout: :application }
  end

  def file_to_text(file_location, lang = 'eng')
    image = RTesseract.new(file_location, lang: lang)
    image.to_s
  end

  def save_file_to_public_foler(params_file)
    filename = params_file[:filename]
    file = params_file[:tempfile]

    File.open(File.join(settings.files, filename), 'wb') do |f|
      f.write file.read
    end
  end
end

