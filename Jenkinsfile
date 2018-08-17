library(
    identifier: 'pipeline-lib@1.2.1',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

def smokeTestImage
def currentTagIsReadyForProduction = scos.isRelease(env.BRANCH_NAME)
def currentTagIsReadyForStaging = (env.BRANCH_NAME == "master")
def doStageIf = scos.&doStageIf

node('master') {
    ansiColor('xterm') {
        stage('Checkout') {
            deleteDir()
            env.GIT_COMMIT_HASH = checkout(scm).GIT_COMMIT

            scos.addGitHubRemoteForTagging("SmartColumbusOS/streaming-service.git")
        }

        doStageIf(!currentTagIsReadyForProduction, 'Build Smoke Tester') {
            dir('smoke-test') {
                smokeTestImage = docker.build("scos/streaming-service-smoke-test:${env.GIT_COMMIT_HASH}")
            }
        }

        doStageIf(!currentTagIsReadyForProduction, 'Publish Smoke Tester') {
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
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            scos.withEksCredentials('prod') {
                deployStrimzi()
                deployKafka()
                runSmokeTest()
            }

            scos.applyAndPushGitHubTag(promotionTag)

            scos.withDockerRegistry {
                smokeTestImage = scos.pullImageFromDockerRegistry("scos/streaming-service-smoke-test", env.GIT_COMMIT_HASH)
                smokeTestImage.push(releaseTag)
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

def runSmokeTest() {
    deploySmokeTest()
    verifySmokeTest()
}

def deploySmokeTest() {
    dir('smoke-test') {
        sh("sed -i 's/%VERSION%/${env.GIT_COMMIT_HASH}/' k8s/01-deployment.yaml")
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