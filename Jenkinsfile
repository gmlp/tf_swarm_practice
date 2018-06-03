pipeline {
    agent {
        docker {image 'softtekcoe/terraform:0.11.3'}
    }
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws_access_key')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_key')
        TF_VAR_key_name = 'gmlp'
        TF_VAR_private_key = credentials('gmlp')
    }
    stages {
        stage('init') {
            steps {
                // send build started notifications
                slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
                sh 'terraform init -input=false'
            }
        }
        stage('plan') {
            steps {
                sh 'terraform plan -out=plan -input=false'
            }
        }
        stage('apply') {
            steps {
                sh 'terraform apply -input=false plan'
            }
        }
        stage('test') {
            steps {
                sh 'sleep 120'
            }
        }
        stage('destroy') {
            steps {
                sh 'terraform destroy -force -input=false'
            }
        }
    }
    post {
        success {
            slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")    

        }
    }
}
