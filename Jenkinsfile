pipeline {
    agent any

    tools {
        maven 'M3'
        jdk 'JDK11'
    }

    environment {
        // AWS 자격 증명 및 리전 설정
        AWS_CREDENTIALS_NAME = 'AWSCredentials'
        REGION = 'ap-northeast-2'
        
        // Docker 이미지 정보
        DOCKER_IMAGE_NAME = 'project03-spring-petclinic'
        DOCKER_TAG = '1.0'
        ECR_REPOSITORY = '257307634175.dkr.ecr.ap-northeast-2.amazonaws.com/'
        ECR_DOCKER_IMAGE = "${ECR_REPOSITORY}${DOCKER_IMAGE_NAME}"
        ECR_DOCKER_TAG = "${DOCKER_TAG}"
        
        // S3 업로드에 필요한 정보
        S3_BUCKET = 'project03-terraform-state'
        S3_KEY = 'deploy-1.0.zip'
        
        // CodeDeploy 배포에 필요한 정보
        APPLICATION_NAME = 'project03-exercise'
        DEPLOYMENT_GROUP = 'project03-production-in_place'
        AUTO_SCALING_GROUP = 'project03-GROUP'
        TARGET_GROUP_NAME = 'project03-target-group'
        
        // CodeDeploy 서비스 역할 ARN
        CODEDEPLOY_SERVICE_ROLE_ARN = 'arn:aws:iam::257307634175:role/project03-codedeploy-service-role'
    }

    stages {
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
                    // CodeDeploy 애플리케이션 생성 
                    sh "aws deploy create-application --application-name ${APPLICATION_NAME}"

                    // CodeDeploy 배포 그룹 생성 
                    sh """aws deploy create-deployment-group \\
                          --application-name \${APPLICATION_NAME} \\
                          --deployment-group-name \${DEPLOYMENT_GROUP} \\
                          --service-role-arn \${CODEDEPLOY_SERVICE_ROLE_ARN} \\
                          --auto-scaling-groups \${AUTO_SCALING_GROUP} \\
                          --load-balancer-info '{\"targetGroupInfoList\":[{\"name\":\"\${TARGET_GROUP_NAME}\"}]}'
                    """

                    /* // CodeDeploy에 배포 생성 (기본값으로 진행)
                    sh "aws deploy create-deployment " +
                        "--application-name ${APPLICATION_NAME} " +
                        "--s3-location bucket=${S3_BUCKET},bundleType=zip,key=${S3_KEY} " +
                        "--deployment-group-name ${DEPLOYMENT_GROUP}" */
                }
            }
        }

        stage('First Test Stage') {
            steps {
                echo 'This is a webhook test stage added for verification purposes!!.'
            }
        }
    }
}
