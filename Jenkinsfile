pipeline {
    agent any

    tools {
        maven 'M3'
        jdk 'JDK11'
    }

    environment {
        // 환경변수들, 파라미터: 매개변수
        AWS_CREDENTIALS_NAME = 'AWSCredentials'
        REGION = 'ap-northeast-2'
        DOCKER_IMAGE_NAME = 'project03-spring-petclinic'
        DOCKER_TAG = '1.0'
        ECR_REPOSITORY = '257307634175.dkr.ecr.ap-northeast-2.amazonaws.com/'
        ECR_DOCKER_IMAGE = "${ECR_REPOSITORY}${DOCKER_IMAGE_NAME}"
        ECR_DOCKER_TAG = "${DOCKER_TAG}"
        S3_BUCKET = 'project03-terraform-state'
        S3_KEY = 'deploy-1.0.zip'
        APPLICATION_NAME = 'project03-exercise'
        DEPLOYMENT_GROUP = 'project03-production-in_place'
        AUTO_SCALING_GROUP = 'project03-GROUP'
    }

    stages {
        stage('Test Stage 2') {
            steps {
                echo 'This is a test stage added for verification purposes.'
            }
        }

        stage('Git Clone') {
            steps {
                git url: 'https://github.com/tkwk5445/spring-petclinic.git', branch: 'efficient-webjars', credentialsId: 'gitCredentials'
            }
        }

        stage('mvn build') {
            steps {
                sh 'mvn -Dmaven.test.failure.ignore=true install'
            }
            post {
                success {
                    junit '**/target/surefire-reports/TEST-*.xml'
                }
            }
        }

        stage('Docker Image Build') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh 'docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    sh 'rm -f ~/.dockercfg ~/.docker/config.json || true'

                    docker.withRegistry("https://${ECR_REPOSITORY}", "ecr:${REGION}:${AWS_CREDENTIALS_NAME}") {
                        docker.image("${DOCKER_IMAGE_NAME}:${DOCKER_TAG}").push()
                    }
                }
            }
        }

        stage('Upload to S3') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh 'zip -r deploy-1.0.zip ./scripts appspec.yml'
                    sh 'aws s3 cp --region ${REGION} --acl private ./deploy-1.0.zip s3://${S3_BUCKET}/${S3_KEY}'
                    sh 'rm -rf ./deploy-1.0.zip'
                }
            }
        }

        stage('Deploy to CodeDeploy') {
            steps {
                script {
                    sh "aws deploy create-deployment " +
                       "--application-name ${APPLICATION_NAME} " +
                       "--s3-location bucket=${S3_BUCKET},bundleType=zip,key=${S3_KEY} " +
                       "--deployment-group-name ${DEPLOYMENT_GROUP} " +
                       "--deployment-config-name CodeDeployDefault.OneAtATime " +
                       "--target-instances autoScalingGroups=${AUTO_SCALING_GROUP}"
                }
            }
        }
    }
}
