#!/bin/bash
fly login -t 'vagrant' --concourse-url 'http://localhost:8080' --team-name 'main'
fly -t 'vagrant' set-pipeline --pipeline 'ci-pipeline' --config 'ci/ci-pipeline.yml'