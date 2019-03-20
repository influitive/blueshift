#!/usr/bin/env groovy
timeout(time: 60, unit: "MINUTES") {
    node("alpine") {
        stage("Checkout") {
            checkout scm
            COMMIT = sh(returnStdout: true, script: """git rev-parse HEAD""").trim()
            COMMIT_HASH = sh(returnStdout: true, script: """git rev-parse --short HEAD""").trim()
            TAG = sh(returnStdout: true, script: """git show-ref --tags | grep ${env.BRANCH_NAME} | awk {'print \$1'}""").trim()
        }

        stage("Login") {
            withCredentials([[$class: 'StringBinding', credentialsId: 'registry-namely-land', variable: 'docker_login']]) {
                sh """docker login -u="namely+jenkins" -p="${env.docker_login}" registry.namely.land"""
            }
        }

        try {
            stage("Docker Pull") {
                parallel images: {
                    sh """docker pull ruby:2.3"""
                }
            }

            stage("Push") {
                if (COMMIT == TAG) {
                    try {
                        retry(3) {
                          withCredentials([[$class: 'StringBinding', credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'],
                          [$class: 'StringBinding', credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY']]) {
                              // pull down the S3 gems
                              sh """mkdir -p s3/gems"""
                              sh """aws s3 sync s3://namely-gems-internal s3"""
                              // build our gem and copy it to the gems dir
                              sh """docker exec gem${COMMIT_HASH} gem build blueshift.gemspec"""
                              sh """mv *.gem s3/gems/"""
                              // update the index
                              sh """docker exec gem${COMMIT_HASH} gem generate_index --update --directory s3"""
                              // push it back up to s3
                              sh """aws s3 sync --acl public-read s3 s3://namely-gems-internal"""
                              echo "SUCCESS: commit tag exists - gem built and copied to s3"
                          }
                        }
                    } catch(e) {
                        echo "FAILURE: commit tag exists - exception caught when trying to build and copy gem to s3!"
                    }
                }
                else {
                    echo "INFO: commit tag does not exist - skipping gem build and copy to s3"
                }
            }
        }
        catch (error) {
            CleanUp(COMMIT_HASH)
            slackSend color: "danger", channel: "#sre-alert", message: "${env.BUILD_URL} BUILD FAILED for https://github.com/namely/blueshift/commit/${COMMIT_HASH}"
            throw error
        }

        stage("Cleanup") {
            CleanUp(COMMIT_HASH)
        }
    }
}

def CleanUp(String hash) {
    sh """docker rm -f gem${hash} || true"""
    sh """docker rmi gem${hash} || true"""
    sh """docker network rm "${hash}" || true"""
}
