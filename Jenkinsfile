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
            withDockerRegistry {
                image.push()
                image.push('latest')
            }
        }
    }

    stage('Deploy to Dev') {
        def cluster = 'dev'
        deployStrimzi(cluster)
        deployKafka(cluster)
        runSmokeTest(cluster)
    }

    if (env.BRANCH_NAME == 'master') {
        def tag = "RC-${new Date().format("yyyy.MM.dd.HHmmss")}"
        stage('Deploy to Staging'){
            sh "git tag ${tag}"

            def cluster = 'staging'
            deployStrimzi(cluster)
            deployKafka(cluster)
            runSmokeTest(cluster)

            sh "git push github ${tag}"
            withDockerRegistry {
                image.push(tag)
            }
        }
    }
}

/*
 * The k8s deployments use raw kubectl commands because the plugin we use
 * for other projects doesn't support the creation of role based auth.
 * The Strimzi deployment creates roles.
 */
def deployStrimzi(environment) {
    dir('k8s/strimzi') {
        sh "kubectl apply --kubeconfig=${kubeConfigPath(environment)} -f cluster-operator/"
    }
}

def deployKafka(environment) {
    dir('k8s') {
        sh "kubectl apply --kubeconfig=${kubeConfigPath(environment)} -f deployments/"
    }
}

def runSmokeTest(environment) {
    deploySmokeTest(environment)
    verifySmokeTest(environment)
}

def deploySmokeTest(environment) {
    dir('smoke-test') {
        sh("sed -i 's/%VERSION%/${env.GIT_COMMIT_HASH}/' k8s/01-deployment.yaml")
        kubernetesDeploy(
            kubeconfigId: "kubeconfig-${environment}",
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

def verifySmokeTest(environment) {
    dir('smoke-test') {
        try {
            timeout(10) {
                sh("""\
                    #!/usr/bin/env bash
                    set -e
                    export KUBECONFIG=${kubeConfigPath(environment)}
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
            sh("kubectl delete --kubeconfig=${kubeConfigPath(environment)} -f k8s/")
        }
    }
}

def kubeConfigPath(environment) {
    "/var/jenkins_home/.kube/${environment}/config"
}

def withDockerRegistry(Closure func) {
    docker.withRegistry("https://199837183662.dkr.ecr.us-east-2.amazonaws.com", "ecr:us-east-2:aws_jenkins_user") {
        func()
    }
}
