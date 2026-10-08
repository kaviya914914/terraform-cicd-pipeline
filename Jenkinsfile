pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    REGISTRY   = '990851550012.dkr.ecr.ap-south-1.amazonaws.com'
    IMAGE      = "${REGISTRY}/cicd-app:${BUILD_NUMBER}"
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
  }
}
