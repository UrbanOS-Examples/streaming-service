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
                deployKafka('dev')
            }
        }

        doStageIfPromoted('Deploy to Staging') {
            def environment = 'staging'

            scos.withEksCredentials(environment) {
                deployStrimzi()
                deployKafka('staging')
            }

            scos.applyAndPushGitHubTag(environment)
        }

        doStageIfRelease('Deploy to Production') {
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            scos.withEksCredentials('prod') {
                deployStrimzi()
                deployKafka('prod')
            }

            scos.applyAndPushGitHubTag(promotionTag)
        }
    }
}

def deployStrimzi() {
    sh "kubectl apply -f k8s/namespace.yaml"
    sh "helm init --service-account tiller"
    sh "helm repo add strimzi http://strimzi.io/charts/"
    sh "helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.13.0 -f strimzi-config.yml --namespace strimzi"
    sh 'kubectl patch Kafka streaming-service-public -n streaming-public --type merge --patch "$(cat k8s/kafka-version-patch.yml)"'
    sh 'kubectl patch Kafka streaming-service -n streaming-prime --type merge --patch "$(cat k8s/kafka-version-patch.yml)"'
}

def deployKafka(environment) {
    sh "helm upgrade --install streaming-service-kafka-prime chart/ --namespace streaming-prime --timeout 600 -f chart/${environment}-values.yaml"
    sh "helm upgrade --install streaming-service-kafka-public chart/ --namespace streaming-public -f ./chart/public-values.yaml --timeout 600"
}
