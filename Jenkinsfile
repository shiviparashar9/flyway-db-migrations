pipeline {
    agent any

    environment {
        FLYWAY_URL       = 'jdbc:postgresql://localhost:5433/ntnx_ds_test'
        FLYWAY_USER      = 'flyway_user'
        FLYWAY_PASSWORD  = 'flyway_user'
        GIT_CREDENTIALS  = 'git-credentials-id'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Prepare Migration Files (Versioned + Repeatable)') {
            steps {
                sh '''
                #!/bin/sh
                set -e

                # Ensure directories exist
                mkdir -p sql sql/views

                ###############################################################################
                # 1) VERSIONED MIGRATIONS (sql/*.sql)  -> VYYYYMMDD_HHMMSS_XX__name.sql
                ###############################################################################
                timestamp=$(date +%Y%m%d_%H%M%S)
                counter=1

                for FILE in sql/*.sql; do
                    [ -e "$FILE" ] || continue
                    BASENAME=$(basename "$FILE")

                    # Skip repeatables and already-versioned files in the root folder
                    case "$BASENAME" in
                        R__*.sql)
                            # leave repeatables to the views logic below (some repos keep them in root)
                            continue
                            ;;
                        V[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]_??__*.sql)
                            echo "Skipping already versioned: $BASENAME"
                            continue
                            ;;
                    esac

                    case "$BASENAME" in
                        [0-9][0-9]_*.sql)
                            ORDER=${BASENAME%%_*}
                            NAME=${BASENAME#*_}
                            NEWFILE="sql/V${timestamp}_${ORDER}__${NAME}"
                            echo "Renaming $BASENAME -> $(basename "$NEWFILE")"
                            mv "$FILE" "$NEWFILE"
                            ;;
                        *)
                            ORDER=$(printf "%02d" $counter)
                            NEWFILE="sql/V${timestamp}_${ORDER}__${BASENAME}"
                            echo "Auto-ordering: $BASENAME -> $(basename "$NEWFILE")"
                            mv "$FILE" "$NEWFILE"
                            counter=$((counter + 1))
                            ;;
                    esac
                done

                ###############################################################################
                # 2) REPEATABLE MIGRATIONS FOR VIEWS (sql/views/*.sql) -> R__name.sql
                #    Any filename becomes repeatable. If it already starts with R__, skip.
                ###############################################################################
                for FILE in sql/views/*.sql; do
                    [ -e "$FILE" ] || continue
                    BASENAME=$(basename "$FILE")

                    case "$BASENAME" in
                        R__*.sql)
                            echo "Skipping already repeatable: $BASENAME"
                            continue
                            ;;
                    esac

                    # strip any leading order like 01_ if present
                    NAME="$BASENAME"
                    case "$BASENAME" in
                        [0-9][0-9]_*.sql)
                            NAME=${BASENAME#*_}
                            ;;
                    esac

                    NEWFILE="sql/views/R__${NAME}"
                    echo "Converting to repeatable: $BASENAME -> $(basename "$NEWFILE")"
                    mv "$FILE" "$NEWFILE"
                done

                ###############################################################################
                # 3) CLEANUP: remove anything that is not V* or R__* inside sql/ and sql/views
                ###############################################################################
                find sql/       -type f ! -name 'V*.sql' ! -name 'R__*.sql' -delete
                find sql/views/ -type f ! -name 'R__*.sql'                  -delete
                '''
            }
        }

        stage('Debug Workspace') {
            steps {
                sh '''
                echo "== After prepare =="
                echo "-- sql/:"
                ls -l sql/ || true
                echo "-- sql/views/:"
                ls -l sql/views/ || true
                echo "-- git status:"
                git status
                '''
            }
        }

        stage('Commit Changes') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${env.GIT_CREDENTIALS}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                    set -e
                    git config user.email "ci-bot@example.com"
                    git config user.name "CI Bot"

                    # Stage additions, modifications, deletions in sql/ (and subfolders)
                    git add -A sql/

                    if ! git diff --cached --quiet; then
                      echo "Files to commit:"
                      git diff --cached --name-status
                      git commit -m "Auto-prepare migrations (V) and views (R__) [ci skip]"
                      git push https://${GIT_USER}:${GIT_PASS}@github.com/shiviparashar9/flyway-db-migrations HEAD:main
                    else
                      echo "No migration/view changes to commit"
                    fi
                    '''
                }
            }
        }

        stage('Flyway Migrate') {
            steps {
                sh '''
                set -e

                if [ ! -f flyway/flyway ]; then
                    # NOTE: change artifact to match your agent OS/arch if needed
                    curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/10.16.0/flyway-commandline-10.16.0-macosx-x64.tar.gz \
                      -o flyway.tar.gz
                    tar -xzf flyway.tar.gz
                    mv flyway-10.16.0 flyway
                    chmod +x flyway/flyway
                fi

                # Include both locations: versioned and views (repeatables)
                ./flyway/flyway \
                  -url=$FLYWAY_URL \
                  -user=$FLYWAY_USER \
                  -password=$FLYWAY_PASSWORD \
                  -locations=filesystem:sql,filesystem:sql/views \
                  migrate
                '''
            }
        }
    }
}
