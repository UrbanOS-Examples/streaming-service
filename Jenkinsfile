#!/usr/bin/env groovy

node {
    stage('Checkout') {
        checkout scm
    }

    stage('Deploy Service Account') {
        sh """#!/usr/bin/env bash
        echo "${credentials('kubeconfig-dev')}" > kubeconfig

        export KUBECONFIG=kubeconfig
        kubectl apply -f k8s/service-accounts/*

        rm kubeconfig
        """
    }

    stage('Deploy') {
        kubernetesDeploy(
            kubeconfigId: "kubeconfig-dev",
            configs: 'k8s/**/*',
            dockerCredentials: [[
                credentialsId: 'ecr:us-east-2:aws_jenkins_user',
                url: 'https://199837183662.dkr.ecr.us-east-2.amazonaws.com'
            ]]
        )
    }
}
