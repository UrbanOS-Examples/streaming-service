#!/usr/bin/env groovy

node {
    stage('Checkout') {
        checkout scm
    }

    stage('Deploy Strimzi') {
        dir('k8s/strimzi') {
            sh 'kubectl apply -f cluster-operator/'
            sh 'kubectl apply -f topic-operator/'
        }
    }

    stage ('Deploy Kakfa') {
        dir('k8s') {
            sh 'kubectl apply -f deployments/'
        }
    }
}
