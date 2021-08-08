# frozen_string_literal: true

require 'erb'
require 'json'
require 'sinatra/base'
require_relative 'ocr'
require_relative 'ocr/pdf'
require_relative 'ocr/image'

Tilt.register Tilt::ERBTemplate, 'html.erb'

class App < Sinatra::Base
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
      if OCR::SUPPORTED_FILES.include?(params[:file][:type])
        filename = save_file_to_public_folder(params[:file])
        ocr_engine = if params[:file][:type] == 'application/pdf'
                       OCR::PDF.new(filename, params, settings)
                     else
                       OCR::Image.new(filename, params, settings)
                     end
        @text = ocr_engine.process_file.to_json
        remove_temp_files
      else
        flash 'Unsupported file type'
      end
    else
      flash 'You have to choose a file'
    end
    erb :index, { layout: :application }
  end

  post '/download' do
    json = JSON.parse(request.body.read)
    download_file = prepare_download_file(json)
    send_file(download_file, type: 'application/octet-stream')
    remove_temp_files
    redirect '/'
  end

  private

  def save_file_to_public_folder(params_file)
    filename = params_file[:filename]
    file = params_file[:tempfile]
    safe_filename = Zaru.sanitize!(filename).downcase.gsub(/\s/, '_')

    File.open(File.join(settings.files, safe_filename), 'wb') do |file_to_write|
      file_to_write.write(file.read)
    end

    safe_filename
  end

  def prepare_download_file(json)
    download_file = File.join(settings.files, "download.#{json['format']}")
    File.open(download_file, 'wb') do |file_to_write|
      text = if json['lines'].empty?
               JSON.parse(JSON.parse(json['full_text']))[0]
             else
               json['lines'].join("\n")
             end
      text = parse_csv(text) if json['format'] == 'csv'
      file_to_write.puts text
    end
    download_file
  end

  def remove_temp_files
    `cd #{File.join(settings.files)} && rm *`
  end

  def parse_csv(text)
    text.split(/\n/).map do |line|
      line.gsub(/\s{2}/, ',').squeeze(',').gsub(', ', ',')
    end.join("\n")
  end
end
