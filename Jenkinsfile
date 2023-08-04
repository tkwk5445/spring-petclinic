pipeline {
    agent any   // 어떤 노드를 쓸 것인가
    tools {
        maven 'M3'
        jdk 'JDK11'
    }
    environment {    // 환경변수들,  파라미터: 매개변수
        AWS_CREDENTIALS_NAME = 'AWSCredentials'
        REGION = 'ap-northeast-2'
        DOCKER_IMAGE_NAME = 'project03-spring-petclinic'
        DOCKER_TAG = '1.0'
        ECR_REPOSITORY = '257307634175.dkr.ecr.ap-northeast-2.amazonaws.com/'
        ECR_DOCKER_IMAGE = "${ECR_REPOSITORY}/${DOCKER_IMAGE_NAME}"
        ECR_DOCKER_TAG = "${DOCKER_TAG}"
        S3_BUCKET = 'project03-terraform-state'
        S3_KEY = 'deploy-1.0.zip'
        APPLICATION_NAME = 'project03-exercise'
        DEPLOYMENT_GROUP = 'project03-production-in_place'
        AUTO_SCALING_GROUP = 'project03-GROUP'
    }

    stages {    // 작업해야할 stages들
        stage('Git Clone') {    // 젠킨스의 workspace에 git clone 한다.
            steps {
                git url: 'https://github.com/tkwk5445/spring-petclinic.git', branch: 'efficient-webjars', credentialsId: 'gitCredentials'
            }
        }
        stage('mvn build') {    // Maven 빌드 ( 컴파일 + 테스트 , 성공하면 taget 디렉토리와 jar파일이 만들어짐)
            steps {
                sh 'mvn -Dmaven.test.failure.ignore=true install'
            }
            post {
                success {
                    junit '**/target/surefire-reports/TEST-*.xml'
                }
            }
        }
        stage('Docker Image Build') {    // Docker 이미지 빌드
            steps {
                dir("${env.WORKSPACE}") {
                    sh 'docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} .'
                }
            }
        }

        stage('Push Docker Image') {    // Docker 이미지 ecr에 푸시
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
                    sh 'zip -r deploy-1.0.zip ./scripts appspec.yml'    // workspace의 yml파일과 scripts폴더를 deploy-1.0.zip으로 압축한다.
                    sh 'aws s3 cp --region ap-northeast-2 --acl private ./deploy-1.0.zip s3://${S3_BUCKET}'  // 압축 된 파일을 s3 버킷으로 보낸다
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
                       "--deployment-config-name CodeDeployDefault.OneAtATime"
                }
            }
        }
    }
}
