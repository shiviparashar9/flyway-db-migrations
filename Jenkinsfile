pipeline {
    agent any

    triggers {
        pollSCM('H/2 * * * *')  // poll every 2 minutes
    }
    
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

        stage('Prepare Migration Files') {
            steps {
                sh '''
                timestamp=$(date +%Y%m%d_%H%M%S)
                FILES=(sql/*.sql)

                # Skip if no SQL files
                [ -e "${FILES[0]}" ] || exit 0

                if [[ ${#FILES[@]} -eq 1 ]]; then
                  # Only one file, allow without prefix
                  FILE="${FILES[0]}"
                  BASENAME=$(basename "$FILE")

                  if [[ "$BASENAME" =~ ^V[0-9]+__.*\\.sql$ ]]; then
                      echo "Skipping already versioned: $BASENAME"
                  else
                      NAME="${BASENAME%.sql}"
                      NEWFILE="sql/V${timestamp}__${NAME}.sql"
                      echo "Single file detected. Renaming $BASENAME -> $(basename $NEWFILE)"
                      mv "$FILE" "$NEWFILE"
                  fi
                else
                  # Multiple files
                  counter=1
                  for FILE in "${FILES[@]}"; do
                      BASENAME=$(basename "$FILE")

                      # Skip already versioned
                      if [[ "$BASENAME" =~ ^V[0-9]+__.*\\.sql$ ]]; then
                          echo "Skipping already versioned: $BASENAME"
                          continue
                      fi

                      if [[ "$BASENAME" =~ ^([0-9]+)_(.*)\\.sql$ ]]; then
                          ORDER="${BASH_REMATCH[1]}"
                          NAME="${BASH_REMATCH[2]}"
                          NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}.sql"
                          echo "Renaming $BASENAME -> $(basename $NEWFILE)"
                          mv "$FILE" "$NEWFILE"
                      else
                          ORDER=$(printf "%02d" $counter)
                          NAME="${BASENAME%.sql}"
                          NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}.sql"
                          echo "Auto-ordering: $BASENAME -> $(basename $NEWFILE)"
                          mv "$FILE" "$NEWFILE"
                          counter=$((counter+1))
                      fi
                  done
                fi
                '''
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
