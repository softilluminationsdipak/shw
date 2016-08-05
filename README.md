Soft Illuminations
-

Dependencies
-

Information about external dependencies.

- MySQL 5.6.17
  - `brew install mysql`
- Redis 2.8.8
  - `brew install redis`

Information about ruby and rails versions.

- Ruby 1.9.3
  - `rbenv install 1.9.3-p484`

Scripts
-

* `script/bootstrap` - setup required gems and load db schema with seeds
* `script/quality` - runs specs, brakeman and rubocop for the app
* `script/ci` - should be used in the CI or locally
* `script/server` - to run server locally

Quick Start
-

Clone application

    git clone git@github.com:softilluminations/eripme.git

Setup YML files

    copy and rename redis.yml and database.yml in /config

Run bootstrap script

    script/bootstrap

Make sure all test are green

    script/ci

Run app

    script/server

Documentation & Examples
-

Where is documentation and examples (e.g. `./docs`)?

Continuous Integration
-

CI service info and status (if available).

Staging
-

http://dev.selecthomewarranty.com

Production
-

http://selecthomewarranty.com

Third-party services
-

Code Climate, etc

Workflow
-

Information about base branch, branch naming, commit messages, specs and pull requests.

Deployment
-

## Staging

Semaphoreapp performs automatic deploy on staging server after every successfull build on master branch

For manual deploy:

Login to Engine Yard using CLI

    ey login

Deploy

    ey deploy -e development -r master
