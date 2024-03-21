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
/*         AWS_CREDENTIALS_NAME = 'AWSCredentials'
        REGION = 'ap-northeast-2' */
        AWS_CREDENTIALS_NAME = 'NCPCredentials'
        REGION = 'KR'
        
        // Docker 이미지 정보
        DOCKER_IMAGE_NAME = 'spring-petclinic'
        DOCKER_TAG = '1.0'
        ECR_REPOSITORY = 'spring-repo.kr.ncr.ntruss.com'
        ECR_DOCKER_IMAGE = "${ECR_REPOSITORY}/${DOCKER_IMAGE_NAME}"
        ECR_DOCKER_TAG = "${DOCKER_TAG}"
        CONTAINER_NAME = 'spring-petclinic'
        DEPLOY_SERVER = 'root@10.0.0.7'
        SSH_CREDENTIALS_ID = 'SpringCredentials'
        
        // S3 업로드에 필요한 정보
        S3_BUCKET = 'deploy-bucket'
        S3_KEY = 'deploy-1.0.zip'
        
/*         // CodeDeploy 배포에 필요한 정보
        APPLICATION_NAME = 'project03-exercise'
        DEPLOYMENT_GROUP = 'project03-production-in_place'
        AUTO_SCALING_GROUP = 'project03-asg' */
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
                    // NCP 컨테이너 레지스트리 로그인
                    sh 'docker login spring-repo.kr.ncr.ntruss.com -u 603F20D2573C48A383E5 -p 6BA89F64D834CAEBCD445661DA35EF30EDF561B1'
        
                    // Docker 이미지 푸시
                    sh 'docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} ${ECR_DOCKER_IMAGE}:${ECR_DOCKER_TAG}'
                    sh 'docker push ${ECR_DOCKER_IMAGE}:${ECR_DOCKER_TAG}'
                }
            }
        }


        stage('Upload to S3') {
            steps {
                // 파일들을 압축하여 S3 버킷에 업로드
                dir("${env.WORKSPACE}") {
                    sh 'zip -r deploy-1.0.zip ./scripts appspec.yml'
                    //sh 'aws s3 cp --region ${REGION} --acl private ./deploy-1.0.zip s3://${S3_BUCKET}/${S3_KEY}'
                    sh 'aws --endpoint-url=https://kr.object.ncloudstorage.com s3 cp ./deploy-1.0.zip s3://${S3_BUCKET}/${S3_KEY}'
                    sh 'rm -rf ./deploy-1.0.zip'
                }
            }
        }
        
        stage('Install Docker') {
            steps {
                script {
                    sshagent([SSH_CREDENTIALS_ID]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} << 'EOF'
                            # Docker가 설치되어 있는지 확인
                            if ! type docker > /dev/null 2>&1; then
                                echo 'Docker is not installed. Installing Docker...'
                                
                                # 운영 체제에 따른 Docker 설치 명령어
                                # Ubuntu를 예로 들면 다음 명령어를 사용할 수 있습니다.
                                sudo apt-get update
                                sudo apt-get install -y docker.io
                                
                                # Docker 서비스 시작
                                sudo systemctl start docker
                                sudo systemctl enable docker
                                
                                echo 'Docker installation completed.'
                            else
                                echo 'Docker is already installed.'
                            fi
EOF
                        """
                    }
                }
            }
        }

        // Docker 컨테이너 배포 단계
        stage('Deploy Container') {
            steps {
                script {
                    sshagent([SSH_CREDENTIALS_ID]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} << 'EOF'
                            # Docker 레지스트리 로그인
                            echo 'Logging into Docker registry...'
                            docker login spring-repo.kr.ncr.ntruss.com -u 603F20D2573C48A383E5 -p 6BA89F64D834CAEBCD445661DA35EF30EDF561B1
        
                            # Docker 이미지 Pull
                            echo 'Pulling Docker image...'
                            docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
        
                            # 기존 컨테이너 중지 및 삭제
                            echo 'Stopping and removing existing container...'
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
        
                            # 새 Docker 컨테이너 실행
                            echo 'Running new container...'
                            docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}
        
                            # 실행 중인 컨테이너 확인
                            echo 'Checking running containers...'
                            docker ps
EOF
                        """
                    }
                }
            }
        }
/*         stage('Deploy to CodeDeploy') {
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
 */
        stage('First Test Stage') {
            steps {
                // webhook 적용후 확인용 테스트 단계
                echo 'This is a webhook test stage added for verification purposes!!.'
            }
        }
    }
}
