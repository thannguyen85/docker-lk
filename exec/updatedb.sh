#!/bin/bash


# Variables
REPO_URL="git@github.com:thannguyen85/logknotdb.git"
CLONE_DIR="/tmp/repository"

# Check if the directory exists and delete it if it does
if [ -d "$CLONE_DIR" ]; then
  rm -rf "$CLONE_DIR"
fi
CONTAINER_NAME="logknot-mysql"
DB_NAME="watashiga_db"
DB_USER="root"
DB_PASSWORD="root"

# Create a MySQL configuration file
cat <<EOF > ~/.my.cnf
[client]
user=$DB_USER
password=$DB_PASSWORD
EOF

# Ensure the configuration file is only readable by the user
chmod 600 ~/.my.cnf

# Copy the MySQL configuration file into the container
docker cp ~/.my.cnf $CONTAINER_NAME:/root/.my.cnf


# Check if the directory exists and delete it if it does
if [ -d "$CLONE_DIR" ]; then
  rm -rf "$CLONE_DIR"
fi

# Remove all databases in the container except for the default ones
DROP_DB_SQL=$(docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf -N -e "
SET FOREIGN_KEY_CHECKS = 0;
SELECT CONCAT('DROP DATABASE \`', schema_name, '\`;')
FROM information_schema.schemata
WHERE schema_name NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');
SET FOREIGN_KEY_CHECKS = 1;")

# Execute the generated SQL commands
docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf -e "$DROP_DB_SQL"



echo "All non-system databases have been deleted."


# docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASSWORD -e "SHOW DATABASES;" | grep -v -E "Database|information_schema|performance_schema|mysql|sys" | while read dbname; do
#     docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASSWORD -e "DROP DATABASE $dbname;"
# done
# SQL to drop all databases except system databases
# Drop all non-system databases

# docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf -e "SHOW DATABASES;" | grep -v -E "Database|information_schema|performance_schema|mysql|sys" | while read dbname; do
#     docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf -e "DROP DATABASE \`$dbname\`;"
# done

# docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# # Check the result
# if [ $? -eq 0 ]; then
#     echo "Database '$DB_NAME' created successfully!"
# else
#     echo "Failed to create database '$DB_NAME'."
#     exit 1
# fi

# Clone the repository
git clone $REPO_URL $CLONE_DIR

# Loop through each SQL file and import it into the corresponding database
for SQL_FILE in $CLONE_DIR/*.sql; do
    DB_NAME=$(basename $SQL_FILE .sql)

    # Create the database if it doesn't exist
    docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

    # Check the result
    if [ $? -eq 0 ]; then
        echo "Database '$DB_NAME' created successfully!"
    else
        echo "Failed to create database '$DB_NAME'."
        exit 1
    fi

    # Import the SQL file
    docker exec -i $CONTAINER_NAME mysql --defaults-file=/root/.my.cnf $DB_NAME < $SQL_FILE

    # Check the result
    if [ $? -eq 0 ]; then
        echo "Database '$DB_NAME' import successful!"
    else
        echo "Database '$DB_NAME' import failed!"
        exit 1
    fi
done
# Cleanup
rm -rf $CLONE_DIR

# Check the result
if [ $? -eq 0 ]; then
    echo "Database import successful!"
else
    echo "Database import failed!"
fi

# Clean up the MySQL configuration file from the container
docker exec -i $CONTAINER_NAME rm /root/.my.cnf

# Clean up the local MySQL configuration file
rm ~/.my.cnf