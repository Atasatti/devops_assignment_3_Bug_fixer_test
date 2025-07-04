# Bug Tracker Selenium Test Suite

This project contains automated UI tests for the Bug Tracker application using Java, Selenium WebDriver, and JUnit 5.

## Project Structure

```
selenium-tests/
├── pom.xml                           # Maven configuration
├── src/test/java/
│   └── BugTrackerTest.java          # Main test class with 10 test cases
└── README.md                         # This file
```

## Test Cases Covered

1. **TC01: Homepage Title Verification** - Verifies application loads with correct title
2. **TC02: Create New Bug** - Tests bug creation functionality
3. **TC03: Update Existing Bug** - Tests bug editing functionality  
4. **TC04: Delete Bug** - Tests bug deletion functionality
5. **TC05: Form Validation** - Tests form validation with empty fields
6. **TC06: Create Multiple Bugs** - Tests handling of multiple bugs
7. **TC07: Toggle Bug Status** - Tests status change functionality
8. **TC08: Priority Color Indicators** - Tests visual priority indicators
9. **TC09: Bug Persistence After Refresh** - Tests data persistence
10. **TC10: Health Endpoint Check** - Tests application health monitoring

## Prerequisites

- Docker (for running with markhobson/maven-chrome)
- Bug Tracker application running at `http://localhost:5050`

## Running Tests

### Option 1: Using Docker (Recommended for CI/CD)

```bash
# Navigate to the selenium-tests directory
cd selenium-tests

# Run tests using the markhobson/maven-chrome Docker image
docker run --rm \
  -v "$(pwd)":/usr/src/mymaven \
  -w /usr/src/mymaven \
  markhobson/maven-chrome \
  mvn test
```

### Option 2: Local Maven (if Maven and Chrome are installed)

```bash
cd selenium-tests
mvn test
```

## Configuration

- **Target URL**: `http://host.docker.internal:5050` (works from inside Docker)
- **Browser**: Chrome (headless mode)
- **Timeout**: 10 seconds for element waits
- **Test Order**: Tests run in a specific order using `@Order` annotations

## Test Features

- **Headless Chrome**: Tests run without GUI for CI/CD compatibility
- **Robust Waits**: Uses WebDriverWait for reliable element interactions
- **Cleanup**: Automatically clears bugs between tests
- **Detailed Logging**: Console output for debugging
- **Cross-platform**: Works on Linux, macOS, and Windows

## Jenkins Integration

This test suite is designed for Jenkins CI integration:

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                dir('selenium-tests') {
                    sh '''
                        docker run --rm \
                          -v "$(pwd)":/usr/src/mymaven \
                          -w /usr/src/mymaven \
                          markhobson/maven-chrome \
                          mvn test
                    '''
                }
            }
        }
    }
    post {
        always {
            publishTestResults testResultsPattern: 'selenium-tests/target/surefire-reports/*.xml'
        }
    }
}
```

## Troubleshooting

1. **Connection Issues**: Ensure Bug Tracker is running at `http://localhost:5050`
2. **Docker Issues**: Verify Docker is running and has network access
3. **Test Failures**: Check console output for detailed error messages
4. **Timing Issues**: Increase timeout in `BugTrackerTest.java` if needed

## Dependencies

- Selenium WebDriver 4.15.0
- JUnit 5.10.0
- WebDriverManager 5.6.2
- Chrome WebDriver (included in markhobson/maven-chrome image) 