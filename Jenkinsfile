@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_docker_label'
  }
  options {
    checkoutToSubdirectory('src/github.com/infoblox/farsight.collector.colo')
  }
  environment {
    DIRECTORY = "src/github.com/github.com/infoblox/farsight.collector.colo"
  }
  stages {
    stage("Build") {
      steps {
        dir("${WORKSPACE}/${DIRECTORY}") {
            sh "make docker"
        }
      }
    }
  }
  post {
    success {
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
    always {
      dir("${WORKSPACE}/${DIRECTORY}") {
        sh "make clean || true"
      }
      cleanWs()
    }
  }
}
