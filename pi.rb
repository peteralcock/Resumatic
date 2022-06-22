require 'zip/zip'
require 'json'
require 'sinatra'
require 'bigdecimal/math'


  def initialize(candidate)
   
  end

  def as_json(*)
    data = {
        id:@candidate.id.to_s,
        name:@candidate.name,
        email:@candidate.email,
        phone:@candidate.phone,
        resume:@candidate.resume
    }
    data[:errors] = @candidate.errors if@candidate.errors.any?
    data
  end
end
configure do
  set :protection, :except => [:json_csrf]
  # set :sessions, true
  set :bind, '0.0.0.0'
  set :logging, true
  set :dump_errors, true
  set :port, 4567
end

before do
  content_type 'application/json'
  headers['Access-Control-Allow-Origin'] = '*'
  error 401 unless params[:key] == ENV['SECRET_API_KEY']
end

helpers do
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
  end
  def json_params
    begin
      JSON.parse(request.body.read)
    rescue
      halt 400, { message:'Invalid JSON' }.to_json
    end
  end

  def candidate
    @candidate ||= Candidate.where(id: params[:id]).first
  end
  
  def pi(digits=20)
  result = BigMath.PI(digits)
  result = result.truncate(digits).to_s
  result = result[2..-1]
  result = result.split('e').first
  result = result.insert(1, '.')
  result
end
  
  def job
    @job ||= Job.where(id: params[:id]).first
  end

  def candidate_serialize(candidate)
    CandidateSerializer.new(candidate).to_json
  end

  def job_serialize(job)
    JobSerializer.new(job).to_json
  end

end

get '/' do

end
  
  get '/pi/:digits' do
  result = pi(params[:digits])
  if result
    status 200
    body result.to_json
  else
    status 500
    body "ERROR".to_json
  end
end
  
get '/inspect/:url' do
  page = MetaInspector.new(self.url)
  website = Website.new(json_params)
  if page and website
    website.description = page.best_description.to_json
    website.title = page.title
    website.save
    website.domain = page.host
    if website.save
      status 200
      body website.to_json
    end
  end
end

get '/hotdog/:test' do
  score = params[:test].similar("hotdog")
  if score and score > 10.0
    status 200
    body "#{score.round(2).to_json}% HOTDOG!".to_json
  else
    status 200
    body "NOT HOTDOG!".to_json
  end
end

post '/candidate/:resume' do
  record = Candidate.new(json_params)
  if record.save
    status 200
    body record.to_json
  else
    status 500
    body "COULD NOT SAVE: #{json_params.to_s}".to_json
  end
end

get '/candidate/:email' do
  record = Candidate.where(:email => params[:email]).first
  if record
    status 200
    body record.to_json
  else
    status 500
    body "NOT FOUND: #{json_params.to_s}".to_json
  end
end

get '/job/:id' do
  record = Job.where(id: params[:id]).first
  if record
    status 200
    body record.to_json
  else
    status 500
    body "NOT FOUND: #{json_params.to_s}".to_json
  end
end


get '/matches/:email' do
  person = Candidate.where(email:params[:email]).first
  results = []
  Job.all.each do |item|
    score = person.resume.similar(item.description)
    if score and score > 61.0
      email = person.email.to_s
      job_id = item.id.to_s
      if matches.insert(email: email, job_id: job_id, score:score)
        results << {email:email,job_id:job_id,score:score}
        puts "+ #{person.name}: #{score}% #{item.title}"
      end
    end
  end
  status 200
  body results.to_json
end

get '/score/:email/:job_id' do
  @candidate = Candidate.where(email: params[:email]).first
  @job = Job.where(id: params[:job_id]).first
  @score = @job.description.similar(@candidate.resume)
  if @score
    status 200
    body @score.to_json
  else
    status 200
    body "NO RESULTS FOR #{params}".to_json
  end
end

get '/jobs' do
  jobs = Job.all
  [:title, :company, :description, :email].each do |filter|
    jobs = jobs.send(filter, params[filter]) if params[filter]
  end
  jobs.map { |job| JobSerializer.new(job) }.to_json
end

get '/jobs/:id' do |id|
  halt_if_not_found!
  job_serialize(job)
end

post '/jobs ' do
  job = Job.new(json_params)
  halt 422, job_serialize(job) unless job.save
  response.headers['Location'] = "#{base_url}/jobs/#{job.id}"
  status 201
end

patch '/jobs/:id' do |id|
  halt_if_not_found!
  halt 422, serialize(job) unless job.update_attributes(json_params)
  job_serialize(job)
end

delete '/jobs/:id' do |id|
  job.destroy if job
  status 204
end

get '/candidates' do
  candidates = Candidate.all
  [:name, :resume, :email].each do |filter|
    candidates = candidates.send(filter, params[filter]) if params[filter]
  end
  candidates.map { |candidate| CandidateSerializer.new(candidate) }.to_json
end

get '/candidates/:id' do |id|
  # halt_if_not_found!
  candidate_serialize(candidate)
end

post '/candidates' do
  candidate = Candidate.new(json_params)
  candidate.parse_resume
  halt 422, serialize(candidate) unless candidate.save
  response.headers['Location'] = "#{base_url}/candidates/#{candidate.id}"
  status 201
end

patch '/candidates/:id' do |id|
  # halt_if_not_found!
  halt 422, serialize(candidate) unless candidate.update_attributes(json_params)
  candidate_serialize(candidate)
end

delete '/candidates/:id' do |id|
  candidate.destroy if candidate
  status 204
end

def download
Zip::ZipInputStream.open_buffer(StringIO.new(last_response.body)) do |io|
  while (entry = io.get_next_entry)
    puts "Contents of #{entry.name}: '#{io.read}'"
  end
end
end
