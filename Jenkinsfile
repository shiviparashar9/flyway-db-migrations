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
                git branch: 'main', url: 'https://github.com/shiviparashar9/flyway-db-migrations'
            }
        }

        stage('Prepare Migration Files') {
            steps {
                sh '''
                timestamp=$(date +%Y%m%d_%H%M%S)
                counter=1

                for FILE in sql/*.sql; do
                  [ -e "$FILE" ] || continue
                  BASENAME=$(basename "$FILE")

                  # 1. Skip already Flyway-versioned files
                  # Match any file that already starts with VYYYYMMDD_HHMMSS_ followed by number __name.sql
                  if [[ "$BASENAME" =~ ^V[0-9]{8}_[0-9]{6}_[0-9]+__.*\.sql$ ]]; then
                      echo "Skipping already versioned: $BASENAME"
                      continue
                  fi

                  # 2. If prefixed with number (01_, 02_, etc.)
                  if [[ "$BASENAME" =~ ^([0-9]+)_(.*)\\.sql$ ]]; then
                      ORDER="${BASH_REMATCH[1]}"
                      NAME="${BASH_REMATCH[2]}"
                      NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}.sql"
                      echo "Renaming $BASENAME -> $(basename "$NEWFILE")"
                      mv "$FILE" "$NEWFILE"

                  # 3. If no prefix, assign sequential order
                  else
                      ORDER=$(printf "%02d" $counter)
                      NAME="$BASENAME"
                      NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}"
                      [[ "$NEWFILE" =~ \\.sql$ ]] || NEWFILE="${NEWFILE}.sql"
                      echo "Auto-ordering: $BASENAME -> $(basename "$NEWFILE")"
                      mv "$FILE" "$NEWFILE"
                      counter=$((counter+1))
                  fi
                done
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
