properties([
    parameters([
        credentials(
            credentialType: 'com.microsoft.jenkins.kubernetes.credentials.KubeconfigCredentials',
            defaultValue: 'kubeconfig-dev',
            description: 'Environment to deploy to',
            name: 'kubernetesCreds',
            required: true
        )
    ])
])

node {
    stage('Checkout') {
        checkout scm
        GIT_COMMIT_HASH = sh(
            script: 'git rev-parse HEAD',
            returnStdout: true
        ).trim()
    }

    stage('Build Smoke Tester') {
        dir('smoke-test') {
            image = docker.build("scos/streaming-service-smoke-test:${GIT_COMMIT_HASH}")
        }
    }

    stage('Publish Smoke Tester') {
        dir('smoke-test') {
            docker.withRegistry("https://199837183662.dkr.ecr.us-east-2.amazonaws.com", "ecr:us-east-2:aws_jenkins_user") {
                image.push()
                image.push('latest')
            }
        }
    }

    stage('Deploy Strimzi') {
        dir('k8s/strimzi') {
            sh 'kubectl apply -f cluster-operator/'
        }
    }

    stage ('Deploy Kakfa') {
        dir('k8s') {
            sh 'kubectl apply -f deployments/'
        }
    }

    stage('Run Smoke Tester') {
        dir('smoke-test') {
            kubernetesDeploy(
                kubeconfigId: "${params.kubernetesCreds}",
                configs: 'k8s/*',
                secretName: 'regcred',
                dockerCredentials: [
                    [
                        credentialsId: 'ecr:us-east-2:aws_jenkins_user',
                        url: 'https://199837183662.dkr.ecr.us-east-2.amazonaws.com'
                    ],
                ]
            )
        }
    }

    stage ('Verify Smoke Test') {
        dir('smoke-test') {
            timeout(10) {
                sh('''\
                    #!/usr/bin/env bash
                    set -e

                    until kubectl logs -f kafka-smoke-tester 2>/dev/null; do
                        echo "waiting for smoke test docker to start"
                        sleep 1
                    done

                    kubectl --output=json get pod kafka-smoke-tester \
                        | jq -r '.status.phase' \
                        | grep -qx "Succeeded"
                '''.trim())
            }
        }
    }
}
