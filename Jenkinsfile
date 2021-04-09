properties([
    [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '20']],
    disableConcurrentBuilds(),
    pipelineTriggers([[$class: 'GitHubPushTrigger']]),
    parameters([
        credentials(
            credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl',
            defaultValue: 'e94cc910-d25f-4ce7-984f-4d968183edcc',
            description: '',
            name: 'DOCKERHUB_CREDENTIAL',
            required: true),
        credentials(
            credentialType: 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl',
            defaultValue: 'github-commit-status-token',
            description: '',
            name: 'GITHUB_REPO_STATUS_TOKEN_CREDENTIAL',
            required: true),
        credentials(
            credentialType: 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl',
            defaultValue: '	github_repo_status_username',
            description: '',
            name: 'GITHUB_REPO_STATUS_USER_CREDENTIAL',
            required: true),
        ]
    )
])

pipeline {
    agent {label 'master'}

    stages {
        stage('Build'){
            steps {
                script {
                    customStage('\u2780 Build Image(s)') {
                        sh 'make build'
                        }
                    customStage('\u2781 Test Image(s)') {
                        sh 'make test'
                    }
                    customStage('\u2782 Push Image(s) to Dockerhub') {
                        script{
                            dockerLogin()
                            sh 'make push'
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Store test results"
            script {
                def junitReportFilesRoot = findFiles glob: "*.xml"
                if (junitReportFilesRoot.length > 0) {
                    junit "*.xml"
                }
                def junitReportFilesSubFolders = findFiles glob: "**/*.xml"
                if (junitReportFilesSubFolders.length > 0) {
                    junit "**/*.xml"
                }
            }
            echo "Cleanup"

            timestamps{
                ansiColor('xterm') {
                    script{
                        sh 'make clean'
                    }
                }
                deleteDir()
            }
        }
        changed {
            emailext(
                attachLog: true,
                body: """${currentBuild.result}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':Check console output at ${env.BUILD_URL} ${env.JOB_NAME} [${env.BUILD_NUMBER}]""",,
                compressLog: true,
                recipientProviders: [
                    [$class: 'CulpritsRecipientProvider'],
                    [$class: 'DevelopersRecipientProvider'],
                    [$class: 'RequesterRecipientProvider'],
                ],
                subject: """${currentBuild.result}: ${currentBuild.fullDisplayName}"""

            )
        }
    }
}

def dockerLogin(){
    withCredentials([
            usernamePassword(credentialsId: params.DOCKERHUB_CREDENTIAL,
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD')
    ]) {
        sh """echo ${PASSWORD} | docker login --username ${USERNAME} --password-stdin"""
    }
}

def setBuildStatus(String context, String message, String state) {
    if (env.GIT_COMMIT) {
    // add a Github access token as a global 'secret text' credential on Jenkins with the id 'github-commit-status-token'
        try {
            withCredentials([
                string(credentialsId: params.GITHUB_REPO_STATUS_TOKEN_CREDENTIAL,   variable: 'TOKEN'),
                string(credentialsId: params.GITHUB_REPO_STATUS_USER_CREDENTIAL,    variable: 'USER'),
                ]) {
            // 'set -x' for debugging. Don't worry the access token won't be actually logged
            // Also, the sh command actually executed is not properly logged, it will be further escaped when written to the log
                sh """
                    set -x
                    curl \"https://api.github.com/repos/${getOrgName()}/${getRepoName()}/statuses/${env.GIT_COMMIT}\" \
                        -u ${USER}:${TOKEN} \
                        -H \"Content-Type: application/json\" \
                        -X POST \
                        -d \"{\\\"description\\\": \\\"${message}\\\", \\\"state\\\": \\\"${state}\\\", \\\"context\\\": \\\"${context}\\\", \\\"target_url\\\": \\\"${env.BUILD_URL}\\\"}\"
                """
            }
        } catch (Exception err){
            print err
        }
    }
}

def customStage(String context, Closure closure) {
    stage(context){
        timestamps{
            ansiColor('xterm') {
                echo env.STAGE_NAME;
                try {
                    setBuildStatus(context, "In progress...", "pending");
                        closure();
                } catch (Exception err) {
                    setBuildStatus(context, "Failure", "failure");
                    throw err;
                }
                setBuildStatus(context, "Success", "success");
            }
        }
    }

}

def getOrgName() {
    env.GIT_URL ? env.GIT_URL.split(':').last().split('/').first() : ''
}

def getRepoName() {
    env.GIT_URL ? env.GIT_URL.split(':').last().split('/').last() : ''
}
