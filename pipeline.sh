node('holdman-jnlp') {
    stage('Clone') {
        echo "1.Clone Stage"
        git url: "https://github.com/holdman2001/jenkins-demo.git"
        script {
            build_tag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            if (env.BRANCH_NAME != 'master') {
                build_tag = "${env.BRANCH_NAME}-${build_tag}"
				env.BRANCH_NAME = "master"
            }
        }
    }
    stage('Test') {
      echo "2.Test Stage"
    }
    stage('Build') {
        echo "3.Build Docker Image Stage"
        sh "docker build -t 192.168.43.110/library/jenkins-demo:${build_tag} ."
    }
    stage('Push') {
        echo "4.Push Docker Image Stage"
        withCredentials([usernamePassword(credentialsId: 'localharbor', passwordVariable: 'localharborPassword', usernameVariable: 'localharborUser')]) {
            sh "docker login -u ${localharborUser} -p ${localharborPassword} 192.168.43.110"
            sh "docker push 192.168.43.110/library/jenkins-demo:${build_tag}"
        }
    }
    stage('Deploy') {
        echo "5. Deploy Stage"
        def userInput = input(
            id: 'userInput',
            message: 'Choose a deploy environment',
            parameters: [
                [
                    $class: 'ChoiceParameterDefinition',
                    choices: "开发测试\n质量验证\n生产上线",
                    name: 'Env'
                ]
            ]
        )
        echo "This is a deploy step to ${userInput}"
        sh "sed -i 's/<BUILD_TAG>/${build_tag}/' k8s.yaml"
        sh "sed -i 's/<BRANCH_NAME>/${env.BRANCH_NAME}/' k8s.yaml"
        if (userInput == "开发测试") {
            // deploy dev stuff
        } else if (userInput == "质量验证"){
            // deploy qa stuff
        } else {
            // deploy prod stuff
        }
		sh "cat k8s.yaml"
        sh "kubectl apply -f k8s.yaml --record --validate=false"
    }
}
