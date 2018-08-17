library(
    identifier: 'pipeline-lib@1.2.1',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

def smokeTestImage
def currentTagIsReadyForProduction = scos.isRelease(env.BRANCH_NAME)
def currentTagIsReadyForStaging = env.BRANCH_NAME == "master"
def doStageIf = scos.&doStageIf

node('master') {
    ansiColor('xterm') {
        stage('Checkout') {
            deleteDir()
            env.GIT_COMMIT_HASH = checkout(scm).GIT_COMMIT

            scos.addGitHubRemoteForTagging("SmartColumbusOS/streaming-service.git")
        }

        stage('Build Smoke Tester') {
            dir('smoke-test') {
                smokeTestImage = docker.build("scos/streaming-service-smoke-test:${env.GIT_COMMIT_HASH}")
            }
        }

        stage('Publish Smoke Tester') {
            dir('smoke-test') {
                scos.withDockerRegistry {
                    smokeTestImage.push()
                    smokeTestImage.push('latest')
                }
            }
        }

        doStageIf(!currentTagIsReadyForProduction, 'Deploy to Dev') {
            scos.withEksCredentials('dev') {
                deployStrimzi()
                deployKafka()
                runSmokeTest()
            }
        }

        doStageIf(currentTagIsReadyForStaging, 'Deploy to Staging') {
            def promotionTag = scos.releaseCandidateNumber()

            scos.withEksCredentials('staging') {
                deployStrimzi()
                deployKafka()
                runSmokeTest()
            }

            scos.applyAndPushGitHubTag(promotionTag)

            scos.withDockerRegistry {
                smokeTestImage.push(promotionTag)
            }
        }

        doStageIf(currentTagIsReadyForProduction, 'Deploy to Production') {
            def currentTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            scos.withEksCredentials(promotionTag) {
                deployStrimzi()
                deployKafka()
                runSmokeTest(currentTag)
            }

            scos.applyAndPushGitHubTag(promotionTag)

            scos.withDockerRegistry {
                smokeTestImage = scos.pullImageFromDockerRegistry("scos/streaming-service-smoke-test", currentTag)
                smokeTestImage.push(promotionTag)
            }
        }
    }
}

def deployStrimzi() {
    dir('k8s/strimzi') {
        sh "kubectl apply -f cluster-operator/"
    }
}

def deployKafka() {
    dir('k8s') {
        sh "kubectl apply -f deployments/"
    }
}

def runSmokeTest(dockerImageVersion=env.GIT_COMMIT_HASH) {
    deploySmokeTest(dockerImageVersion)
    verifySmokeTest()
}

def deploySmokeTest(dockerImageVersion) {
    dir('smoke-test') {
        sh("sed -i 's/%VERSION%/${dockerImageVersion}/' k8s/01-deployment.yaml")
        sh("kubectl apply -f k8s/")
    }
}

def verifySmokeTest() {
    dir('smoke-test') {
        try {
            timeout(10) {
                sh("""\
                    #!/usr/bin/env bash
                    set -e
                    until kubectl logs -f kafka-smoke-tester 2>/dev/null; do
                        echo "waiting for smoke test docker to start"
                        sleep 1
                    done

                    kubectl --output=json get pod kafka-smoke-tester \
                        | jq -r '.status.phase' \
                        | grep -qx "Succeeded"
                """.trim())
            }
        }
        finally {
            sh("kubectl delete -f k8s/")
        }
    }
}