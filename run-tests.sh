#!/bin/bash

# Task Manager Selenium Test Runner Script
# This script runs the automated UI tests using Docker--checking trigger

echo "=== Task Manager Selenium Test Suite ==="
echo "Starting automated UI tests..."

# Check if Task Manager is running
echo "Checking if Task Manager is accessible..."
if curl -s http://localhost:5050/health > /dev/null; then
    echo "✓ Task Manager is running and accessible"
else
    echo "⚠ Warning: Task Manager may not be running at http://localhost:5050"
    echo "Please ensure the Task Manager application is running before continuing."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
fi

echo ""
echo "Running Selenium tests with Docker..."
echo "Using markhobson/maven-chrome image for headless testing"
echo ""

# Run the tests
docker run --rm \
  -v "$(pwd)":/usr/src/mymaven \
  -w /usr/src/mymaven \
  markhobson/maven-chrome \
  mvn test

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 All tests completed successfully!"
    echo "Test reports are available in target/surefire-reports/"
else
    echo ""
    echo "❌ Some tests failed. Check the output above for details."
    echo "Test reports are available in target/surefire-reports/"
    exit 1
fi 
