library(
    identifier: 'pipeline-lib@4.3.0',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

properties([
    pipelineTriggers([scos.dailyBuildTrigger()]),
])

def smokeTestImage
def doStageIf = scos.&doStageIf
def doStageIfRelease = doStageIf.curry(scos.changeset.isRelease)
def doStageUnlessRelease = doStageIf.curry(!scos.changeset.isRelease)
def doStageIfPromoted = doStageIf.curry(scos.changeset.isMaster)

node('infrastructure') {
    ansiColor('xterm') {
        scos.doCheckoutStage()

        doStageUnlessRelease('Build Smoke Tester') {
            dir('smoke-test') {
                smokeTestImage = docker.build("scos/streaming-service-smoke-test:${env.GIT_COMMIT_HASH}")
            }
        }

        doStageUnlessRelease('Publish Smoke Tester') {
            dir('smoke-test') {
                scos.withDockerRegistry {
                    smokeTestImage.push()
                    smokeTestImage.push('latest')
                }
            }
        }

        doStageUnlessRelease('Deploy to Dev') {
            scos.withEksCredentials('dev') {
                deployStrimzi()
                deployKafka()
                runSmokeTest()
            }
        }

        doStageIfPromoted('Deploy to Staging') {
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

        doStageIfRelease('Deploy to Production') {
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
    sh "kubectl apply -f k8s/namespace.yaml"
    sh "helm repo add strimzi http://strimzi.io/charts/"
    sh "helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.8.0 -f strimzi-config.yml"
}

def deployKafka() {
    sh "helm upgrade --install streaming-service-kafka chart/ --namespace streaming"
}

def runSmokeTest() {
    deploySmokeTest()
    verifySmokeTest()
}

def deploySmokeTest() {
    dir('smoke-test') {
        sh("""sed -i "s/%VERSION%/${env.GIT_COMMIT_HASH}/" k8s/01-deployment.yaml""")
        sh("kubectl apply --namespace streaming -f k8s/")
    }
}

def verifySmokeTest() {
    dir('smoke-test') {
        try {
            timeout(10) {
                sh("""\
                    #!/usr/bin/env bash
                    set -e
                    until kubectl logs --namespace streaming -f kafka-smoke-tester 2>/dev/null; do
                        echo "waiting for smoke test docker to start"
                        sleep 1
                    done

                    kubectl --output=json get pod kafka-smoke-tester --namespace streaming \
                        | jq -r '.status.phase' \
                        | grep -qx "Succeeded"
                """.trim())
            }
        }
        finally {
            sh("kubectl delete --namespace streaming -f k8s/")
        }
    }
}
