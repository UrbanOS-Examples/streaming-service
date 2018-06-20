#!/usr/bin/env groovy

node {
    stage('Checkout') {
        checkout scm
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
}
