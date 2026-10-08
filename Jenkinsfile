pipeline {
  agent any

  options {
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    AWS_REGION        = 'ap-south-1'
    REGISTRY          = '990851550012.dkr.ecr.ap-south-1.amazonaws.com'
    IMAGE             = "${REGISTRY}/cicd-app:${BUILD_NUMBER}"
    TF_VAR_my_ip_cidr = '122.167.101.53/32'
  }

  stages {
    stage('Build') {
      steps {
        sh 'docker build -t $IMAGE app/'
      }
    }

    stage('Test') {
      steps {
        sh 'docker run --rm $IMAGE pytest -q'
      }
    }

    stage('Trivy scan') {
      steps {
        sh 'trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed $IMAGE'
      }
    }

    stage('Push to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
          docker push $IMAGE
        '''
      }
    }

    stage('Staging: provision') {
      steps {
        dir('terraform') {
          sh '''
            terraform init -input=false
            terraform workspace select -or-create staging
            terraform apply -auto-approve -input=false -var env=staging
          '''
          script {
            env.STG_IP = sh(script: 'terraform output -raw public_ip', returnStdout: true).trim()
          }
        }
      }
    }

    stage('Staging: deploy + health check') {
      steps {
        sh './scripts/deploy.sh $STG_IP $IMAGE'
        sh './scripts/health_check.sh $STG_IP'
      }
    }

    stage('Approval') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          input message: 'Staging is healthy. Deploy to PRODUCTION?', ok: 'Deploy'
        }
      }
    }

    stage('Production: provision + deploy') {
      steps {
        dir('terraform') {
          sh '''
            terraform workspace select -or-create production
            terraform apply -auto-approve -input=false -var env=production
          '''
          script {
            env.PRD_IP = sh(script: 'terraform output -raw public_ip', returnStdout: true).trim()
          }
        }
        sh './scripts/deploy.sh $PRD_IP $IMAGE'
        sh './scripts/health_check.sh $PRD_IP'
      }
    }
  }

  post {
    always {
      dir('terraform') {
        sh '''
          for e in staging production; do
            terraform workspace select -or-create $e && terraform destroy -auto-approve -input=false -var env=$e || true
          done
        '''
      }
    }
  }
}
