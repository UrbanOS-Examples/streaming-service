def image

node {
    stage('Checkout') {
        env.GIT_COMMIT_HASH = checkout(scm).GIT_COMMIT
    }

    stage('Build Smoke Tester') {
        dir('smoke-test') {
            image = docker.build("scos/streaming-service-smoke-test:${env.GIT_COMMIT_HASH}")
        }
    }

    if (env.BRANCH_NAME == 'master') {
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
                sh("sed -i 's/%VERSION%/${env.GIT_COMMIT_HASH}/' k8s/01-deployment.yaml")
                kubernetesDeploy(
                    kubeconfigId: 'kubeconfig-dev',
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
                try {
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
                finally {
                    sh('kubectl delete -f k8s/')
                }
            }
        }
    }
}
