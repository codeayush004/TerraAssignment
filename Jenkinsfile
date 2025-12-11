pipeline {
  agent any
  environment {
    // Configure these in Jenkins credentials or as pipeline environment variables
    ARM_CLIENT_ID     = credentials('azure-sp-client-id')      // service principal client id
    ARM_CLIENT_SECRET = credentials('azure-sp-client-secret')  // service principal secret
    ARM_TENANT_ID     = credentials('azure-sp-tenant-id')      // tenant id
    ARM_SUBSCRIPTION_ID = credentials('azure-sp-sub-id')       // subscription id
    TF_VAR_my_ip_cidr = "${params.MY_IP_CIDR ?: '0.0.0.0/0'}"   // override via build param
  }
  parameters {
    string(name: 'MY_IP_CIDR', defaultValue: '0.0.0.0/0', description: 'Your IP/CIDR for SSH (recommended: x.x.x.x/32)')
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Azure Login') {
      steps {
        sh '''
          az --version || (echo "az cli not found"; exit 1)
          az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
          az account set --subscription "$ARM_SUBSCRIPTION_ID"
        '''
      }
    }
    stage('Terraform Init') {
      steps {
        sh 'terraform --version || (echo "terraform not found"; exit 1)'
        sh 'terraform init -input=false'
      }
    }
    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan -input=false -var="my_ip_cidr=${TF_VAR_my_ip_cidr}"'
      }
    }
    stage('Terraform Apply') {
      steps {
        input message: "Apply Terraform plan to create Azure infra?"
        sh 'terraform apply -auto-approve tfplan'
      }
    }
  }
  post {
    success {
      sh 'terraform output -json > tf_outputs.json || true'
      archiveArtifacts artifacts: 'tf_outputs.json', fingerprint: true
    }
    always {
      sh 'az logout || true'
    }
  }
}
