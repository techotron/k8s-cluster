pipeline {
  agent {
    node {
      label 'docker'
      customWorkspace "./workspace/${BUILD_TAG}"
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
          config = readYaml file: 'pipelines/deploy-k8s-infra.yaml'
          service_name = config.service_name
          version = sh(
            returnStdout: true,
            script: 'git rev-parse --short HEAD').trim()
          setBuildDisplayName([application: config.service_name, version: version])
          println "THIS IS A TEST - Part 2"
        }
      }
    }
  }
}