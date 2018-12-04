library(
    identifier: 'pipeline-lib@4.3.0',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

properties([
    pipelineTriggers([scos.dailyBuildTrigger()]),
])

def doStageIf = scos.&doStageIf
def doStageIfRelease = doStageIf.curry(scos.changeset.isRelease)
def doStageUnlessRelease = doStageIf.curry(!scos.changeset.isRelease)
def doStageIfPromoted = doStageIf.curry(scos.changeset.isMaster)

node('infrastructure') {
    ansiColor('xterm') {
        scos.doCheckoutStage()

        doStageUnlessRelease('Deploy to Dev') {
            scos.withEksCredentials('dev') {
                deployStrimzi()
                deployKafka()
            }
        }

        doStageIfPromoted('Deploy to Staging') {
            def promotionTag = scos.releaseCandidateNumber()

            scos.withEksCredentials('staging') {
                deployStrimzi()
                deployKafka()
            }

            scos.applyAndPushGitHubTag(promotionTag)
        }

        doStageIfRelease('Deploy to Production') {
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            scos.withEksCredentials('prod') {
                deployStrimzi()
                deployKafka()
            }

            scos.applyAndPushGitHubTag(promotionTag)
        }
    }
}

def deployStrimzi() {
    sh "kubectl apply -f k8s/namespace.yaml"
    sh "helm init --service-account tiller"
    sh "helm repo add strimzi http://strimzi.io/charts/"
    sh "helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.8.2 -f strimzi-config.yml --namespace strimzi"
}

def deployKafka() {
    sh "helm upgrade --install streaming-service-kafka-prime chart/ --namespace streaming-prime --timeout 600"
}
