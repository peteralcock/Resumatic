# Resumatic
![All your resume are belong to us.](/robot.jpg?raw=true "10X.AI")

"Welcome to the machine, bitch."


<h4>
API Endpoints:
</h4>

- [List candidates](#get-candidates)
- [Find a resume](#get-candidate)
- [Upload a resume](#create-candidate)
- [Editing resumes](#update-candidate)
- [Removing candidates](#delete-candidate)
- [Listing open jobs](#get-jobs)
- [Find a specific job](#get-job)
- [Adding new jobs](#create-job)
- [Edit a job listing](#update-job)
- [Filling a position](#delete-job)
- [Detect hotdogs](#hotdog-detection)

Models:

- [Candidate model](#candidate-model)
- [Job model](#job-model)
- [Match model](#match-model)

------------------------------------


# Getting Started
Score any candidates' potential for any tech job listing using the candidate's email address followed by the job ID for the position:

- `GET /score/candidate@example.com/1234` will return the score of the candidates potential for the job with an ID of `1234`.

- `GET /jobs` will return a list of all available jobs posted.

<!--
_Optional query parameters_:

* `attribute1` - when set to true, will only return resources that...
* `attribute2` - when set to true, will only return resources that...
-->


## Finding a specific job

- `GET /jobs/1` will return the job with an ID of `1`.

## Create new job listings

- `POST /jobs` creates job.

_Required parameters_:

* `title` - title of the job.
* `description` - content of the job.
* `email` - email of the job.

This endpoint will return `201 Created` with the current JSON representation of the job if the creation was a success. See the [Job model](#job-model) for more info on the payload.

## Update job listing

- `PUT /jobs/1` allows changing the job with an ID of `1`.

You may change any of the required or optional parameters as listed in the [create job](#create-job) endpoint.

This endpoint will return `200 OK` with the current JSON representation of the job if the update was a success. See the [Job model](#job-model) for more info on the payload.

## Delete job listings

- `DELETE /jobs/1` will delete the job with an ID of `1`.

This endpoint will return `204 No Content` if successful. No parameters are required.


# Candidates

## List all resumes

- `GET /candidates` will return a [paginated list](../README.md#pagination) of candidates.

<!--
_Optional query parameters_:

* `company` - when set to true, will only return resources that...
* `title` - when set to true, will only return resources that...
-->


## Find candidate by ID

- `GET /candidates/1` will return the candidate with an ID of `1`.


## Lookup candidates by email

- `GET /candidate/nerd@example.com` will return the candidate with an email of `nerd@example.com`.


## Upload a resume

- `POST /candidates` creates candidate.

<!--
**Required parameters**:

* `name` - real name of the candidate.
* `resume` - resume text for the candidate.
* `email` - email address of the candidate.
-->

_Required parameters_:

* `name` - real name of the candidate.
* `resume` - resume text for the candidate.
* `email` - email address of the candidate.

This endpoint will return `201 Created` with the current JSON representation of the candidate if the creation was a success. See the [Candidate model](#candidate-model) for more info on the payload.

## Update resume

- `PUT /candidates/1` allows changing the candidate with an ID of `1`.

You may change any of the required or optional parameters as listed in the [create candidate](#create-candidate) endpoint.

This endpoint will return `200 OK` with the current JSON representation of the candidate if the update was a success. See the [Candidate model](#candidate-model) for more info on the payload.

## Removing candidates

- `DELETE /candidates/1` will delete the candidate with an ID of `1`.

This endpoint will return `204 No Content` if successful. No parameters are required.


## Detect Hotdog

- `GET /hotdog/eatmorehotdogs` will return a percentile value representing the amount of hotdog found in `eatmorehotdogs`
- `GET /hotdog/ilikepizza` will return `NOT HOTDOG!` because it has nothing to do with hotdog.



## Data Models

### Candidate Resume

```json
{
  "_id": "string",
  "company": "string",
  "title": "string",
  "email": "string",
  "phone": "string",
  "name": "string",
  "resume": "text",
  "linkedin": "string"
}
```


### Job Listing

```json
{
  "_id": "string",
  "title": "string",
  "description": "text",
  "company": "string",
  "email": "string",
  "phone": "string",
  "url": "string",
}
```


### Hiring Match

```json
{
  "job_id": "string",
  "candidate_id": "string",
  "score": "float"
}
```


------------------------------------------

# Deploying to Production

Lamda is an AWS service which lets you run code without provisioning full servers. You pay only for the compute time and not when your code is not running. The price of execution depends of how much memory you allocate and how long it will took to finish your code's execution. Duration is calculated from the time your code begins executing until it returns or otherwise terminates, rounded up to the nearest 100ms. If you need to run the same Lambda function simultaneously 10 times you have to spin up 10 separate Lamba invocations of the same functionality. However next execution of AWS lamda function will be executed on waiting AWS Lambda (no spin up is necessary you just invoke code/params on span-up one that is not performing anything), and depending on what programming lang you use, Java, C# would have slower cold starts than Python or Ruby.

## Connecting API Gateway

AWS Lambda has no routing inside as you would have in Ruby on Rails application. What you need to do is to plug routing solution to your individual Lambda Functions. AWS provides another product called AWS API Gateway in which you define what route will call what AWS Lambda / Lambdas. For example...


GET /api/v1/candidates => calls list_candidates AWS Lambda function

POST /api/v1/candidates => calls create_candidate AWS Lambda function and pass the JSON request 


** You can also configure proxy routes with * where anything (POST/GET/PUT/DELETED can be directed to a particular Lambda Function

When you call ruby api.rb you will start the web server, but in production on Lambda the API Gateway is your web server. You just need to call the Rack part of Sinatra with your AWS Lambda function passing the request params/body from the AWS API Gateway, which will proxy any/every request to this one AWS Lambda that will spin up and execute one route of the Sinatra application. After the response is returned, Lambda will die. That means if this Sinatra app needs to receive 50 requests, it will spin up 50 AWS Lambda Functions, and next requests “may be” executed on loaded up Lambdas with Sinatra dependancies in memory. If there are 1000 requests concurrently, AWS will try to run 1000 invocations for the same Lambda function. However, if it’s 1000 requests/second, and each request only needs 200 ms to process, there could only be 200 concurrent invocations at any point of time. You need to have your Lambda functions load up fast otherwise you will have slow response times and pay more than you would with server running 24h a day.

## Preparing your application

From here onward Sinatra will carry on application execution as normal Sinatra webserver. That means it will find the get ‘/hello-world’ route and execute the code. Add this before block at the top of the file: As in first step we were setting the ENV variable rack.input with the body of API Gateway, Sinatra would not effectively parse the body as it would be in raw JSON format. That’s why this block will parse the JSON to hash as would Sinatra normally do with HTTP form params. This will be needed when you do POST /api/v1/candidates to create new records. You must set enviroment variables related to the replication of the server. Most important is the setting of the PATH_INFO => what will end up in Sinatra routing and the "rack.input" => what will become params.

```
env = {
    "REQUEST_METHOD" => event['httpMethod'],
    "SCRIPT_NAME" => "",
    "PATH_INFO" => event['path'] || "",
    "QUERY_STRING" => event['queryStringParameters'] || "",
    "SERVER_NAME" => "localhost",
    "SERVER_PORT" => 443,

    "rack.version" => Rack::VERSION,
    "rack.url_scheme" => "https",
    "rack.input" => StringIO.new(event['body'] || ""),
    "rack.errors" => $stderr,
    }
 

before do
  if request.body.size > 0
    request.body.rewind
    @params = Sinatra::IndifferentHash.new
    @params.merge!(JSON.parse(request.body.read))
  end
end

status, headers, body = $app.call(env)

```


## Further Reading

1. https://aws.amazon.com/blogs/compute/announcing-ruby-support-for-aws-lambda/
2. https://github.com/aws-samples/serverless-sinatra-sample

