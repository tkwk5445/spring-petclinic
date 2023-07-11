pipeline {
  agent any
  tools {
    maven 'M3'
    jdk 'JDK11'
  }

  stages {
    stage('Git Clone') {
      steps {
        git url: 'https://github.com/skfrhan7/spring-petclinic.git', branch: 'efficient-webjars', credentialsId: 'gitCredentials'
      }
    }
    stage('mvn build') {
      steps {
       sh 'mvn -Dmaven.test.failure.igonore=true install' 
      }
      post {
        success {
          junit '**/target/surefire-reports/Test-*.xml'
        }
      }
    } 
  
  
  }
}
