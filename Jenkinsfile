library(
    identifier: 'pipeline-lib@4.8.0',
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
    sh "helm repo add strimzi http://strimzi.io/charts/"
    sh "helm upgrade --install strimzi-kafka-operator strimzi/strimzi-kafka-operator --version 0.15.0 -f strimzi-config.yml --namespace strimzi"
}

def deployKafka(environment) {
    sh "helm upgrade --install streaming-service-kafka-prime chart/ --namespace streaming-prime --timeout 600s -f chart/${environment}-values.yaml"
}
