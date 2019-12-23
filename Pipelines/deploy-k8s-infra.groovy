pipeline {
  agent {
    // docker {
    //   image 'techotron/ci_agent:latest'
    // }
    node {
      label 'docker'
      customWorkspace "./workspace/${BUILD_TAG}"
      image 'techotron/ci_agent:latest'
    }
  }
  options {
    timestamps()
    timeout(time: 1, unit: 'HOURS')
    buildDiscarder(logRotator(numToKeepStr: '20', daysToKeepStr: '30'))
    durabilityHint('PERFORMANCE_OPTIMIZED')
    ansiColor('xterm')
  }
  parameters {
    booleanParam(name: 'TestBoolean', defaultValue: false, description: 'Button to test job')
  }
  stages {
    stage("Initialise") {
      steps {
        script {
          checkout scm
          config = readYaml file: 'Pipelines/deploy-k8s-infra.yaml'
          version = sh(
            returnStdout: true,
            script: 'git rev-parse --short HEAD').trim()
          setBuildDisplayName([application: config.service_name, version: version])
          println "THIS IS A TEST - Part 2"
        }
      }
    }
    stage("List Deployed Stacks") {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'jenkins-user', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
              sh '''
                aws help
              '''
          }
        }
      }
    }
  }
}