// Jenkins trigger: force rebuild
pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    environment {
        DOCKER_IMAGE = 'ataulhaq490/bug-fixer:latest'
        CONTAINER_NAME = 'bug-fixer-test-container'
        APP_PORT = '5050'
        APP_URL = 'http://51.20.121.239:5050'
    }
    
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                script {
                    echo "🧹 Cleaning workspace with proper permissions..."
                    sh '''
                        # Use Docker to cleanup files created by previous builds
                        docker run --rm -v "${WORKSPACE}:/workspace" alpine:latest sh -c "rm -rf /workspace/* /workspace/.* 2>/dev/null || true"
                        
                        # Fallback: try regular cleanup
                        rm -rf ${WORKSPACE}/* || true
                        rm -rf ${WORKSPACE}/.* || true
                    '''
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Pull Docker Image') {
            steps {
                script {
                    echo "🐳 Pulling Docker image: ${DOCKER_IMAGE}"
                    sh "docker pull ${DOCKER_IMAGE}"
                }
            }
        }
        
        stage('Deploy App') {
            steps {
                script {
                    echo "🚀 Starting Task Manager application..."
                    
                    // Stop and remove any existing container
                    sh """
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true
                    """
                    
                    // Run the application container
                    sh """
                        docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${APP_PORT}:5050 \
                        ${DOCKER_IMAGE}
                    """
                    
                    // Wait for application to be ready
                    echo "⏳ Waiting for application to start..."
                    timeout(time: 2, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def response = sh(
                                    script: "curl -s -o /dev/null -w '%{http_code}' ${APP_URL} || echo '000'",
                                    returnStdout: true
                                ).trim()
                                echo "Health check response: ${response}"
                                return response == '200'
                            }
                        }
                    }
                    
                    echo "✅ Application is running at ${APP_URL}"
                }
            }
        }
        
        stage('Run Selenium Tests') {
            steps {
                script {
                    echo "🧪 Running Selenium tests against ${APP_URL}"
                    
                    sh """
                        docker run --rm \
                        --network host \
                        -v \${PWD}:/usr/src/mymaven \
                        -w /usr/src/mymaven \
                        markhobson/maven-chrome \
                        mvn test -DAPP_URL=${APP_URL}
                    """
                }
            }
            post {
                always {
                    // Archive test results
                    junit testResults: 'target/surefire-reports/TEST-*.xml', allowEmptyResults: true
                    archiveArtifacts artifacts: 'target/surefire-reports/**/*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Parse Results') {
            steps {
                script {
                    echo "📊 Parsing test results for email report..."
                    // Test results parsing will be done in post section
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Stop and cleanup containers using env variables
                echo "🧹 Cleaning up containers..."
                sh """
                    docker stop ${env.CONTAINER_NAME} || true
                    docker rm ${env.CONTAINER_NAME} || true
                """
                
                // Clean up Docker images to save disk space
                echo "🧹 Cleaning up Docker images and cache..."
                sh """
                    docker system prune -f
                    docker image prune -a -f
                """
                
                // Generate detailed email report
                def emailBody = """
                <h2>🧪 Task Manager CI/CD Pipeline Results</h2>
                <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                <p><strong>Status:</strong> ${currentBuild.currentResult}</p>
                <p><strong>Docker Image:</strong> ${env.DOCKER_IMAGE}</p>
                <p><strong>App URL:</strong> ${env.APP_URL}</p>
                <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">View Console Output</a></p>
                
                <h3>📋 Pipeline Stages</h3>
                <table border="1" style="border-collapse: collapse; width: 100%;">
                    <tr><th>Stage</th><th>Status</th></tr>
                """
                
                // Add stage results
                def stageResults = [
                    'Cleanup Workspace': '✅ Completed',
                    'Checkout': '✅ Completed',
                    'Pull Docker Image': '✅ Completed', 
                    'Deploy App': currentBuild.currentResult == 'SUCCESS' ? '✅ Completed' : '❌ Failed',
                    'Run Selenium Tests': currentBuild.currentResult == 'SUCCESS' ? '✅ Completed' : '❌ Failed',
                    'Parse Results': '✅ Completed'
                ]
                
                stageResults.each { stage, status ->
                    emailBody += "<tr><td>${stage}</td><td>${status}</td></tr>"
                }
                
                emailBody += "</table><h3>📊 Test Summary</h3>"
                
                // Parse test results if available
                if (fileExists('target/surefire-reports/TEST-BugFixerTest.xml')) {
                    try {
                        def testXml = readFile('target/surefire-reports/TEST-BugFixerTest.xml')
                        
                        // Extract test suite attributes using regex
                        def testsMatch = (testXml =~ /tests="(\d+)"/)
                        def failuresMatch = (testXml =~ /failures="(\d+)"/)
                        def errorsMatch = (testXml =~ /errors="(\d+)"/)
                        def timeMatch = (testXml =~ /time="([0-9.]+)"/)
                        
                        def total = testsMatch ? testsMatch[0][1] as Integer : 0
                        def failed = failuresMatch ? failuresMatch[0][1] as Integer : 0
                        def errors = errorsMatch ? errorsMatch[0][1] as Integer : 0
                        def passed = total - failed - errors
                        def duration = timeMatch ? timeMatch[0][1] : "0"
                        
                        emailBody += """
                        <table border="1" style="border-collapse: collapse; width: 100%;">
                            <tr><td><strong>Total Tests</strong></td><td>${total}</td></tr>
                            <tr><td><strong>✅ Passed</strong></td><td>${passed}</td></tr>
                            <tr><td><strong>❌ Failed</strong></td><td>${failed}</td></tr>
                            <tr><td><strong>⚠️ Errors</strong></td><td>${errors}</td></tr>
                            <tr><td><strong>⏱️ Duration</strong></td><td>${duration}s</td></tr>
                        </table>
                        
                        <h3>📋 Individual Test Cases</h3>
                        <table border="1" style="border-collapse: collapse; width: 100%;">
                            <tr><th>Test Case</th><th>Status</th><th>Time (s)</th></tr>
                        """
                        
                        // Extract test case names and status (simplified approach)
                        def testCaseMatches = (testXml =~ /<testcase[^>]*name="([^"]*)"[^>]*time="([^"]*)"[^>]*/)
                        
                        testCaseMatches.each { match ->
                            def name = match[1]
                            def time = match[2]
                            def status = "✅ Passed"
                            
                            // Look for failures in this test case section
                            def testCaseStart = testXml.indexOf(match[0])
                            def testCaseEnd = testXml.indexOf('</testcase>', testCaseStart)
                            if (testCaseEnd > testCaseStart) {
                                def testCaseSection = testXml.substring(testCaseStart, testCaseEnd)
                                if (testCaseSection.contains('<failure')) {
                                    status = "❌ Failed"
                                } else if (testCaseSection.contains('<error')) {
                                    status = "⚠️ Error"
                                }
                            }
                            
                            emailBody += "<tr><td>${name}</td><td>${status}</td><td>${time}</td></tr>"
                        }
                        
                        emailBody += "</table>"
                        
                    } catch (Exception e) {
                        emailBody += "<p>⚠️ Could not parse detailed test results: ${e.message}</p>"
                    }
                } else {
                    emailBody += "<p>⚠️ No test results file found</p>"
                }
                
                emailBody += """
                <br>
                <p><strong>📄 Artifacts:</strong></p>
                <ul>
                    <li><a href="${env.BUILD_URL}testReport/">Test Report</a></li>
                    <li><a href="${env.BUILD_URL}console">Console Output</a></li>
                </ul>
                """
                
                env.EMAIL_BODY = emailBody
            }
            
            emailext (
                to: "afnanajmal03@gmail.com",
                subject: "🚀 Task Manager CI/CD - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}",
                body: env.EMAIL_BODY ?: "Build completed with status: ${currentBuild.currentResult}",
                mimeType: 'text/html'
            )
        }
        
        failure {
            script {
                echo "❌ Pipeline failed - cleaning up any remaining containers"
                sh """
                    docker stop ${env.CONTAINER_NAME} || true
                    docker rm ${env.CONTAINER_NAME} || true
                """
                
                // Clean up Docker images even on failure
                echo "🧹 Cleaning up Docker images after failure..."
                sh """
                    docker system prune -f
                    docker image prune -a -f
                """
            }
        }
    }
}
