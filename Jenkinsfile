@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_docker_label'
  }
  options {
    checkoutToSubdirectory('src/github.com/infobloxopen/farsight.collector.colo')
  }
  environment {
    DIRECTORY = "src/github.com/infobloxopen/farsight.collector.colo"
  }
  stages {
    stage("Build") {
      steps {
        dir("${WORKSPACE}/${DIRECTORY}") {
            sh "make docker"
        }
      }
    }
    stage("Pubish image") {
      steps {
        dir("${WORKSPACE}/${DIRECTORY}") {
          script {
              def imageList = ''
              if (!isPrBuild()) {
                  imageList = sh(script: 'make list-of-images', returnStdout: true)
              }
          }
          finalizeBuild(imageList)
        }
      }
    }
  }
  post {
    success {
    }
    always {
      dir("${WORKSPACE}/${DIRECTORY}") {
        sh "make clean || true"
      }
      cleanWs()
    }
  }
}
