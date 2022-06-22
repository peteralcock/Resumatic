require 'zip/zip'
require 'json'
require 'sinatra'
require 'bigdecimal/math'

 
configure do
  set :protection, :except => [:json_csrf]
  # set :sessions, true
  set :bind, '0.0.0.0'
  set :logging, true
  set :dump_errors, true
  set :port, 3142
end

before do
  content_type 'application/json'
  headers['Access-Control-Allow-Origin'] = '*'
#  error 401 unless params[:key] == ENV['SECRET_API_KEY']
end

helpers do
  
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
  end
  
    
  def pi(digits=20)
    result = BigMath.PI(digits)
    result = result.truncate(digits).to_s
    result = result[2..-1]
    result = result.split('e').first
    result = result.insert(1, '.')
    result
  end
  
  
  def json_params
    begin
      JSON.parse(request.body.read)
    rescue
      halt 400, { message:'Invalid JSON' }.to_json
    end
  end

end
  
get '/pi/:digits' do
  digits = Integer(params[:digits])
  result = pi(digits)
  if result
    status 200
    body result.to_json
  else
    status 500
    body "[ERROR]: #{params}".to_json
  end
  
end

get '/pi/:digits/download' do
  digits = Integer(params[:digits])
  result = pi(digits)
  Zip::ZipInputStream.open_buffer(StringIO.new(last_response.body)) do |io|
  while (entry = io.get_next_entry)
    puts result
  end
  if result
    status 200
    body result.to_json
  else
    status 500
  end
end

end
