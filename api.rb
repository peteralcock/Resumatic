require 'sequel'
require 'csv'
require 'ffaker'
require 'json'
require 'sinatra'
require "sinatra/namespace"
require 'similar_text'
require 'mongoid'
require 'presume'
require 'metainspector'
require 'dotenv'

Dotenv.load
$match_counter = 0
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))
Mongoid.load!('config/mongoid.yml')
# connect to an in-memory database
DB = Sequel.sqlite

# create an items table
DB.create_table :matches do
  primary_key :id
  String :email, null: false
  Integer :job_id, null: false
  Float :score, null: false
end

# create a dataset from the items table
matches = DB[:matches]

class Website
  include Mongoid::Document
  field :url, type: String
  field :domain, type: String
  field :title, type: String
  field :description, type: String
  validates :url, presence: true
end

class Job
  include Mongoid::Document
  field :email, type: String
  field :title, type: String
  field :company, type: String
  field :phone, type: String
  field :url, type: String
  field :description, type: String
  validates :email, presence: true
  validates :title, presence: true
  validates :description, presence: true
  index({ email: 'text' })
  index({ company: 'text' })
  index({description:1 }, { name: "description_index" })
  scope :email, -> (email) { where(email: /^#{email}/) }
  scope :description, -> (description) { where(description: description) }
  scope :title, -> (title) { where(title: title) }
  scope :company, -> (company) { where(company: company) }
  scope :url, -> (url) { where(url: url) }

end

class Candidate
  include Mongoid::Document
  field :email, type: String
  field :name, type: String
  field :resume, type: String
  field :phone, type: String
  validates :email, presence: true
  validates :resume, presence: true
  index({ email: 'text' }, { unique: true })
  index({ phone: 'text' })
  scope :email, -> (email) { where(email: /^#{email}/) }
  scope :resume, -> (resume) { where(resume: resume) }
  scope :name, -> (name) { where(name: name) }
  scope :phone, -> (phone) { where(phone: phone) }
end
class JobSerializer
  def initialize(job)
    @job = job
  end

  def as_json(*)
    data = {
        id:@job.id.to_s,
        title:@job.title,
        company:@job.company,
        email:@job.email,
        description:@job.description
    }
    data[:errors] = @job.errors if@job.errors.any?
    data
  end
end


class CandidateSerializer
  def initialize(candidate)
    @candidate = candidate
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
  "ID.AI".to_json
end
namespace '/api/v1' do

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

end


if ENV['SEED']
csvs = ["data/ai.csv", "data/ml.csv", "data/dsci.csv"]
csvs.each do |filename|
  csv = CSV.open(filename)
  csv.each do |row|
    job = Job.new(description: row.last, title: row[1], email: FFaker::Internet.email, phone: FFaker::PhoneNumber.phone_number)
    if rand(11) == 1
      candidate = Candidate.new(:email => FFaker::Internet.email, :name => FFaker::Name.name, :resume => FFaker::HipsterIpsum.paragraph, :phone => FFaker::PhoneNumber.phone_number)
      if candidate.save
        puts candidate.name
      end
    end
    if job.save
      puts job.title
    end
  end
end

end
if ENV['MATCH_JOBS']
# puts "[INFO] >> (#{Time.now}) Begin processing #{Candidate.all.count * Job.all.count}  possible scores of #{Candidate.all.count} resumes for #{Job.all.count} open positions in 5 seconds..."
$scores = []
time_start = Time.now.to_i
$all_matches = []
$match_limit = 1000
Candidate.all.each do |person|
  $match_limit -= 1
  Job.all.each do |item|
    break if $match_limit < 1
    @score = person.to_s.similar(item.to_s)
    $match_limit -= 1
    if @score and @score > 61.0
      email = person.email.to_s
      job_id = item.id.to_s
      if matches.insert(email: email, job_id: job_id, score: @score)
        $all_matches << {email:email,job_id:job_id,score:@score}
        $match_counter += 1
        puts "+ #{person.name}: #{@score}% #{item.title}"
      end
    end
  end
end
time_end = Time.now.to_i
puts "!------DONE--------!"
puts "MATCHES: #{$match_counter} total"
puts "RUN TIME: #{time_end - time_start} seconds"
puts "AVG SCORE: #{matches.avg(:score)}%"
puts "<------------------>"
end
