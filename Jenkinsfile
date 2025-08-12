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
                if [ ! -f flyway/flyway ]; then
                    curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/10.16.0/flyway-commandline-10.16.0-macosx-x64.tar.gz \
                    -o flyway.tar.gz
                    tar -xzf flyway.tar.gz
                    mv flyway-10.16.0 flyway
                    chmod +x flyway/flyway
                fi

                ./flyway/flyway -url=$FLYWAY_URL -user=$FLYWAY_USER -password=$FLYWAY_PASSWORD migrate
                '''
            }
        }
    }
}
