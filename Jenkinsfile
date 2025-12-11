pipeline {
  agent any
  environment {
    // Jenkins secret text credentials (must exist)
    ARM_CLIENT_ID       = credentials('azure-sp-client-id')
    ARM_CLIENT_SECRET   = credentials('azure-sp-client-secret')
    ARM_TENANT_ID       = credentials('azure-sp-tenant-id')
    ARM_SUBSCRIPTION_ID = credentials('azure-sp-sub-id')
  }
  parameters {
    string(name: 'MY_IP_CIDR', defaultValue: '0.0.0.0/0', description: 'Your IP/CIDR for SSH (recommended: x.x.x.x/32)')
    string(name: 'VM_SIZE',   defaultValue: 'Standard_B1ms', description: 'VM size to use (override terraform variable vm_size)')
    booleanParam(name: 'AUTO_APPLY', defaultValue: false, description: 'If true, skip manual approval and auto-apply the plan (use with caution)')
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Azure Login') {
      steps {
        sh '''
          set -e
          az --version || (echo "az cli not found" && exit 1)
          az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
          az account set --subscription "$ARM_SUBSCRIPTION_ID"
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        sh '''
          set -e
          terraform --version || (echo "terraform not found" && exit 1)
          terraform init -input=false
        '''
      }
    }

    stage('Terraform Plan') {
      steps {
        // pass both my_ip_cidr and vm_size as -var overrides
        sh '''
          set -e
          terraform plan -out=tfplan -input=false -var="my_ip_cidr=${params.MY_IP_CIDR}" -var="vm_size=${params.VM_SIZE}"
        '''
      }
    }

    stage('Terraform Apply') {
      steps {
        script {
          if (params.AUTO_APPLY) {
            // fully automated apply (no manual approval)
            sh 'terraform apply -auto-approve tfplan'
          } else {
            input message: "Apply Terraform plan to create Azure infra?"
            sh 'terraform apply -auto-approve tfplan'
          }
        }
      }
    }
  }

  post {
    success {
      sh 'terraform output -json > tf_outputs.json || true'
      archiveArtifacts artifacts: 'tf_outputs.json', fingerprint: true
    }
    cleanup {
      sh 'az logout || true'
    }
    always {
      echo "Pipeline finished. Check tf_outputs.json artifact for outputs (private key saved to tf_generated_key.pem if configured in Terraform)."
    }
  }
}
