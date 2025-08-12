pipeline {
    agent any

    environment {
        FLYWAY_URL = 'jdbc:postgresql://localhost:5433/ntnx_ds_test'  // match your port
        FLYWAY_USER = 'flyway_user'
        FLYWAY_PASSWORD = 'flyway_user'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/shiviparashar9/flyway-db-migrations'
            }
        }

        stage('Flyway Migrate') {
            steps {
                sh '''
                # Ensure Flyway is available
                if ! command -v flyway &> /dev/null; then
                    brew install flyway
                fi

                flyway -url=$FLYWAY_URL -user=$FLYWAY_USER -password=$FLYWAY_PASSWORD migrate
                '''
            }
        }
    }
}
