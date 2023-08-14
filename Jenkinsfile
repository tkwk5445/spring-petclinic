pipeline {
    agent any

    // 사용할 도구들 정의
    tools {
        maven 'M3' // Maven 버전 'M3' 사용
        jdk 'JDK11' // JDK 버전 'JDK11' 사용
    }

    // 파이프라인 전체에서 사용될 환경 변수들 정의
    environment {
        // Docker 레지스트리와 S3에 필요한 AWS 자격 증명
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
    }

    // 파이프라인의 단계들 정의
    stages {
        stage('Git Clone') {
            steps {
                // Git 리포지토리를 지정된 인증 정보로 클론
                git url: 'https://github.com/tkwk5445/spring-petclinic.git', branch: 'efficient-webjars', credentialsId: 'gitCredentials'
            }
        }

        stage('mvn build') {
            steps {
                // Maven 프로젝트를 테스트 실패를 무시하고 빌드
                sh 'mvn -Dmaven.test.failure.ignore=true install'
            }
            post {
                success {
                    // JUnit 테스트 결과를 surefire-reports에서 파싱하여 게시
                    junit '**/target/surefire-reports/TEST-*.xml'
                }
            }
        }

        stage('Docker Image Build') {
            steps {
                // Docker 이미지 빌드
                dir("${env.WORKSPACE}") {
                    sh 'docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Docker 레지스트리에 인증하고 Docker 이미지를 푸시
                    sh 'rm -f ~/.dockercfg ~/.docker/config.json || true'

                    docker.withRegistry("https://${ECR_REPOSITORY}", "ecr:${REGION}:${AWS_CREDENTIALS_NAME}") {
                        docker.image("${DOCKER_IMAGE_NAME}:${DOCKER_TAG}").push()
                    }
                }
            }
        }

        stage('Upload to S3') {
            steps {
                // 파일들을 압축하여 S3 버킷에 업로드
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
                    // AWS CLI를 사용하여 CodeDeploy에 배포 생성
                    sh "aws deploy create-deployment " +
                        "--application-name ${APPLICATION_NAME} " +
                        "--s3-location bucket=${S3_BUCKET},bundleType=zip,key=${S3_KEY} " +
                        "--deployment-group-name ${DEPLOYMENT_GROUP} " +
                        "--deployment-config-name CodeDeployDefault.OneAtATime " +
                        "--target-instances autoScalingGroups=${AUTO_SCALING_GROUP}"
                }
            }
        }

/*         stage('First Test Stage') {
            steps {
                // webhook 적용후 확인용 테스트 단계
                echo 'This is a webhook test stage added for verification purposes!!.'
            }
        } */
    }
}
