library(
    identifier: 'pipeline-lib@master',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

def image

node {
    stage('Checkout') {
        deleteDir()
        env.GIT_COMMIT_HASH = checkout(scm).GIT_COMMIT

        withCredentials([usernamePassword(credentialsId: 'jenkins-github-user', passwordVariable: 'GIT_PWD', usernameVariable: 'GIT_USER')]) {
            sh 'git remote add github https://$GIT_USER:$GIT_PWD@github.com/SmartColumbusOS/streaming-service.git'
        }
    }

    stage('Build Smoke Tester') {
        dir('smoke-test') {
            image = docker.build("scos/streaming-service-smoke-test:${env.GIT_COMMIT_HASH}")
        }
    }

    stage('Publish Smoke Tester') {
        dir('smoke-test') {
            scos.withDockerRegistry {
                image.push()
                image.push('latest')
            }
        }
    }

    stage('Deploy to Dev') {
        scos.withEksCredentials('dev') {
            deployStrimzi()
            deployKafka()
            runSmokeTest()
        }
    }

    if (env.BRANCH_NAME == 'master') {
        def tag = scos.releaseCandidateNumber()

        stage('Deploy to Staging'){
            scos.withEksCredentials('staging') {
                deployStrimzi()
                deployKafka()
                runSmokeTest()
            }

            sh "git tag ${tag}"
            sh "git push github ${tag}"

            scos.withDockerRegistry {
                image.push(tag)
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