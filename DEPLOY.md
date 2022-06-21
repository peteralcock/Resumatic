# Deploying to AWS

Lamda is an AWS service which lets you run code without provisioning full servers. You pay only for the compute time and not when your code is not running. The price of execution depends of how much memory you allocate and how long it will took to finish your code's execution. Duration is calculated from the time your code begins executing until it returns or otherwise terminates, rounded up to the nearest 100ms. If you need to run the same Lambda function simultaneously 10 times you have to spin up 10 separate Lamba invocations of the same functionality. However next execution of AWS lamda function will be executed on waiting AWS Lambda (no spin up is necessary you just invoke code/params on span-up one that is not performing anything), and depending on what programming lang you use in AWS Lambda. Java, C# would have slower cold starts than Python or Ruby.

## Plugging into API Gateway

AWS Lambda has no routing inside as you would have in Ruby on Rails application. What you need to do is to plug routing solution to your individual Lambda Functions. AWS provides another product called AWS API Gateway in which you define what route will call what AWS Lambda / Lambdas. For example...

```
GET /api/v1/candidates => call list_candidates AWS Lambda function
POST /api/v1/candidates => call create_candidate AWS Lambda function and pass the JSON request body to it e.g {"email": "you@example.org"}

```
(You can also configure proxy routes with * where anything (POST/GET/PUT/DELETED can be directed to a particular Lambda Function)

When you call ruby api.rb you will start the web server, but in production on Lambda the API Gateway is your web server. You just need to call the Rack part of Sinatra with your AWS Lambda function passing the request params/body from the AWS API Gateway, which will proxy any/every request to this one AWS Lambda that will spin up and execute one route of the Sinatra application. After the response is returned, Lambda will die. That means if this Sinatra app needs to receive 50 requests, it will spin up 50 AWS Lambda Functions, and next requests “may be” executed on loaded up Lambdas with Sinatra dependancies in memory. If there are 1000 requests concurrently, AWS will try to run 1000 invocations for the same Lambda function. However, if it’s 1000 requests/second, and each request only needs 200 ms to process, there could only be 200 concurrent invocations at any point of time. You need to have your Lambda functions load up fast otherwise you will have slow response times and pay more than you would with server running 24h a day.

## Preparing your application

Now you must set enviroment variables related to the replication of the server. Most important is the setting of the PATH_INFO => what will end up in Sinatra routing and the "rack.input" => what will become params. Then we call The Rack application...

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
```

...
    status, headers, body = $app.call(env)
...
```

From here onward Sinatra will carry on application execution as normal Sinatra webserver. That means it will find the get ‘/hello-world’ route and execute the code. Add this before block at the top of the file:

```
before do
  if request.body.size > 0
    request.body.rewind
    @params = Sinatra::IndifferentHash.new
    @params.merge!(JSON.parse(request.body.read))
  end
end
```

As in first step we were setting the ENV variable rack.input with the body of API Gateway, Sinatra would not effectively parse the body as it would be in raw JSON format. That’s why this block will parse the JSON to hash as would Sinatra normally do with HTTP form params. This will be needed when you do POST /api/v1/candidates to create new records.

# Further Reading
https://aws.amazon.com/blogs/compute/announcing-ruby-support-for-aws-lambda/
https://github.com/aws-samples/serverless-sinatra-sample

