pipeline {
    agent any

    triggers {
        // Poll every 2 minutes (only detects new commits on main)
        pollSCM('H/2 * * * *')
    }
    
    environment {
        FLYWAY_URL = 'jdbc:postgresql://localhost:5433/ntnx_ds_test'
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
                counter=1

                for FILE in sql/*.sql; do
                  [ -e "$FILE" ] || continue
                  BASENAME=$(basename "$FILE")

                  # Remove .sql extension for clean naming
                  NAME_NO_EXT="${BASENAME%.sql}"

                  # 1. Skip already Flyway-versioned files
                  if [[ "$BASENAME" =~ ^V[0-9]+__.*\\.sql$ ]]; then
                      echo "Skipping already versioned: $BASENAME"
                      continue
                  fi

                  # 2. If prefixed with number (01_, 02_, etc.)
                  if [[ "$NAME_NO_EXT" =~ ^([0-9]+)_(.*)$ ]]; then
                      ORDER="${BASH_REMATCH[1]}"
                      NAME="${BASH_REMATCH[2]}"
                      NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}.sql"
                      echo "Renaming $BASENAME -> $(basename "$NEWFILE")"
                      mv "$FILE" "$NEWFILE"

                  # 3. If no prefix, assign sequential order
                  else
                      ORDER=$(printf "%02d" $counter)
                      NAME="$NAME_NO_EXT"
                      NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}.sql"
                      echo "Auto-ordering: $BASENAME -> $(basename "$NEWFILE")"
                      mv "$FILE" "$NEWFILE"
                      counter=$((counter+1))
                  fi
                done
                '''
            }
        }

        stage('Flyway Migrate') {
            steps {
                sh '''
                if [ ! -f flyway/flyway ]; then
                    echo "Downloading Flyway..."
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
