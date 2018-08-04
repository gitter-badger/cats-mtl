#!/bin/bash

# Build Overview:
# The overall build is split into a number of parts
# 0. Coursier is enabled for the user account, to speed up resolution.
# 1. The build for coverage is performed. This:
#   a. First enables the coverage processing, and then
#   b. Builds and tests for the JVM using the validateJVM target, and then
#   c. Produces the coverage report, and then
#   d. Clean is run (as part of coverageReport), to clear down the built artifacts
# 2. The scala js build is executed, compiling the application and testing it for scala js.
# 3. The validateJVM target is executed again, due to the fact that producing coverage with the
#    code coverage tool causes the byte code to be instrumented/modified to record the coverage
#    metrics when the tests are executing. This causes the full JVM build to be run a second time.

# Example setting to use at command line for testing:
# export TRAVIS_SCALA_VERSION=2.10.5;export TRAVIS_PULL_REQUEST="false";export TRAVIS_BRANCH="master"

mkdir -p ~/.sbt/0.13/plugins
echo "addSbtPlugin(\"io.get-coursier\" % \"sbt-coursier\" % \"1.0.0-RC10\")" >> ~/.sbt/0.13/plugins/build.sbt

export publish_cmd="publishLocal"

if [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_BRANCH == "master" && $(cat version.sbt) =~ "-SNAPSHOT" ]]; then
  export publish_cmd="publish gitSnapshots publish"
  # temporarily disable to stabilize travis
  #if [[ $TRAVIS_SCALA_VERSION =~ ^2\.11\. ]]; then
  #  export publish_cmd="publishMicrosite"
  #fi
fi

sbt_cmd="sbt ++$TRAVIS_SCALA_VERSION"

core_js="$sbt_cmd validateJS"

js="$core_js"
jvm="$sbt_cmd coverage validateJVM coverageReport && codecov"

if [[ $JS_BUILD == "true" ]]; then
run_cmd="$js"
else
run_cmd="$jvm && $sbt_cmd $publish_cmd"
fi

eval $run_cmd
