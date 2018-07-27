pipeline {
    agent any

    options {
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    parameters {
        credentials(
            credentialType: 'com.microsoft.jenkins.kubernetes.credentials.KubeconfigCredentials',
            defaultValue: 'kubeconfig-dev',
            description: 'Environment to deploy to',
            name: 'kubernetesCreds',
            required: true
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    GIT_COMMIT_HASH = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Smoke Tester') {
            steps {
                script {
                    dir('smoke-test') {
                        image = docker.build("scos/streaming-service-smoke-test:${GIT_COMMIT_HASH}")
                    }
                }
            }
        }

        stage('Publish Smoke Tester') {
            when {
                branch 'master'
            }
            steps {
                script {
                    dir('smoke-test') {
                        docker.withRegistry("https://199837183662.dkr.ecr.us-east-2.amazonaws.com", "ecr:us-east-2:aws_jenkins_user") {
                            image.push()
                            image.push('latest')
                        }
                    }
                }
            }
        }

        stage('Deploy Strimzi') {
            when {
                branch 'master'
            }
            steps {
                script {
                    dir('k8s/strimzi') {
                        sh 'kubectl apply -f cluster-operator/'
                    }
                }
            }
        }

        stage ('Deploy Kakfa') {
            when {
                branch 'master'
            }
            steps {
                script {
                    dir('k8s') {
                        sh 'kubectl apply -f deployments/'
                    }
                }
            }
        }

        stage('Run Smoke Tester') {
            when {
                branch 'master'
            }
            steps {
                script {
                    dir('smoke-test') {
                        sh("sed -i 's/%VERSION%/${GIT_COMMIT_HASH}/' k8s/01-deployment.yaml")
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
            }
        }

        stage ('Verify Smoke Test') {
            options {
                timeout(time: 10, unit: 'MINUTES')
            }
            when {
                branch 'master'
            }
            steps {
                script {
                    dir('smoke-test') {
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
    }
    post {
        always {
            script {
                dir('smoke-test') {
                    sh(script: 'kubectl delete -f k8s/', returnStatus: true)
                }
            }
        }
    }
}
