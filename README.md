# 10X.AI
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


## Scoring resumes for jobs
Score any candidates' potential for any tech job listing using the candidate's email address followed by the job ID for the position they're considering.

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

## Delete resume

- `DELETE /candidates/1` will delete the candidate with an ID of `1`.

This endpoint will return `204 No Content` if successful. No parameters are required.


## Data Models

### Candidate Resume

```json
{
  "id": "integer",
  "company": "string",
  "email": "string",
  "phone": "string",
  "name": "string",
  "title": "string",
  "resume": "text",
  "linkedin": "string"
}
```


### Job Listing

```json
{
  "id": "string",
  "title": "string",
  "email": "string",
  "phone": "string",
  "url": "string",
  "description": "text"

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
