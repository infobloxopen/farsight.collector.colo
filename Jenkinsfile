@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_docker_label'
  }
  options {
    checkoutToSubdirectory('src/github.com/infobloxopen/farsight.collector.colo')
  }
  environment {
    DIRECTORY = "src/github.com/github.com/infobloxopen/farsight.collector.colo"
  }
  stages {
    stage("Build") {
      steps {
        dir("${WORKSPACE}/${DIRECTORY}") {
            sh "make docker"
        }
      }
    }
    stage("Publish docker image") {
      when {
        anyOf {
          branch "master"
          branch "release*"
          buildingTag()
        }
        expression { !isPrBuild() }
      }
      steps {
        dir("${WORKSPACE}/${DIRECTORY}") {
          signDockerImage("farsight.collector.colo", sh(script:'make show-version', returnStdout: true).trim(), "infobloxopen")
        }
      }
    }
  }
  post {
    always {
      dir("${WORKSPACE}/${DIRECTORY}") {
        sh "make clean || true"
      }
      cleanWs()
    }
  }
}
