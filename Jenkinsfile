pipeline {
    agent {
        docker {
            image 'devops123iocom/maven:runner-v3'
            label 'Build_agent'
            args '--group-add 109 -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    parameters {
        booleanParam(
            name: 'ARCHIVE_JAR',
            defaultValue: false,
            description: 'Archive the generated JAR files'
        )
        booleanParam(
            name: 'Dry_run',
            defaultValue: false,
            description: 'Dry run the pipeline to verify the flow'
        )
    }

    environment {
        REGISTRY_URL = 'docker.io'
        IMAGE_REPOSITORY = 'devops123iocom/maven'
        REGISTRY_CREDENTIALS_ID = 'Docker_registry'
    }

    stages {
        stage('Checkout') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                checkout scmGit(
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        credentialsId: 'git_token',
                        url: 'https://github.com/Balaji8123/maven-simple.git'
                    ]]
                )
                sh 'ls -l'
            }
        }

        stage('Unit Test') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                sh 'mvn test'
            }
        }

        stage('Maven Build') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Validate Docker') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                sh '''
                    set -eu
                    docker version
                    test -f Dockerfile
                    test -f target/maven-simple-0.2-SNAPSHOT.jar
                '''
            }
        }

        stage('Docker Build') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                sh '''
                    docker build \
                        --file Dockerfile \
                        --tag "$IMAGE_REPOSITORY:$BUILD_NUMBER" \
                        .
                '''
            }
        }

        stage('Docker Push') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${REGISTRY_CREDENTIALS_ID}",
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$REGISTRY_PASSWORD" |
                            docker login "$REGISTRY_URL" \
                                --username "$REGISTRY_USER" \
                                --password-stdin

                        docker push "$IMAGE_REPOSITORY:$BUILD_NUMBER"
                        docker logout "$REGISTRY_URL"
                    '''
                }
            }
        }
                 
                 stage('Docker Deploy') {
            when {
                expression { !params.Dry_run }
            }
            steps {
                sh '''
                    set -eu

                    IMAGE="$IMAGE_REPOSITORY:$BUILD_NUMBER"
                    CONTAINER_NAME="maven-simple-app"

                    docker pull "$IMAGE"

                    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
                        docker stop "$CONTAINER_NAME" || true
                        docker rm "$CONTAINER_NAME"
                    fi

                    docker run -d \
                        --name "$CONTAINER_NAME" \
                        --restart unless-stopped \
                        -p 8080:8080 \
                        "$IMAGE"

                    docker ps --filter "name=$CONTAINER_NAME"
                '''
            }
        }
        stage('Archive JAR') {
            when {
                allOf {
                    expression { !params.Dry_run }
                    expression { params.ARCHIVE_JAR }
                }
            }
            steps {
                archiveArtifacts(
                    artifacts: 'target/*.jar',
                    fingerprint: true,
                    onlyIfSuccessful: true
                )
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('target/surefire-reports')) {
                    junit(
                        testResults: 'target/surefire-reports/*.xml',
                        allowEmptyResults: true
                    )
                }
            }
        }
    }
}
