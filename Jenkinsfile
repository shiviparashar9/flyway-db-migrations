pipeline {
    agent any
    
    environment {
        FLYWAY_URL = 'jdbc:postgresql://localhost:5433/ntnx_ds_test'
        FLYWAY_USER = 'flyway_user'
        FLYWAY_PASSWORD = 'flyway_user'
        GIT_CREDENTIALS = 'git-credentials-id'
    }

    stages {
        stage('Checkout') {
            steps {
                // Use checkout scm to preserve workspace state
                checkout scm
            }
        }

        stage('Prepare Migration Files') {
            steps {
                sh '''
                #!/bin/sh

                timestamp=$(date +%Y%m%d_%H%M%S)
                counter=1

                for FILE in sql/*.sql; do
                    [ -e "$FILE" ] || continue
                    BASENAME=$(basename "$FILE")

                    # Skip files already in Flyway format
                    case "$BASENAME" in
                        V[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]_??__*.sql)
                            echo "Skipping already versioned: $BASENAME"
                            continue
                            ;;
                    esac

                    # If file starts with number prefix (01_, 02_, etc.)
                    case "$BASENAME" in
                        [0-9][0-9]_*.sql)
                            ORDER=${BASENAME%%_*}
                            NAME=${BASENAME#*_}
                            NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}"
                            echo "Renaming $BASENAME -> $(basename "$NEWFILE")"
                            mv "$FILE" "$NEWFILE"
                            ;;

                        *)
                            # No prefix: assign sequential order
                            ORDER=$(printf "%02d" $counter)
                            NEWFILE="sql/V${timestamp}_${ORDER}__${BASENAME}"
                            echo "Auto-ordering: $BASENAME -> $(basename "$NEWFILE")"
                            mv "$FILE" "$NEWFILE"
                            counter=$((counter + 1))
                            ;;
                    esac
                done
                '''
            }
        }

        stage('Debug Workspace') {
            steps {
                sh '''
                echo "Listing SQL files after renaming:"
                ls -l sql/
                git status
                '''
            }
        }

        stage('Commit Renamed Files') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${env.GIT_CREDENTIALS}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                    git config user.email "ci-bot@example.com"
                    git config user.name "CI Bot"

                    git add sql/V*.sql || true

                    if ! git diff --cached --quiet; then
                      echo "Files to commit:"
                      git diff --cached --name-only
                      git commit -m "Auto-renamed migration files [ci skip]"
                      git push https://${GIT_USER}:${GIT_PASS}@github.com/shiviparashar9/flyway-db-migrations HEAD:main
                    else
                      echo "No migration files to commit"
                    fi
                    '''
                }
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
