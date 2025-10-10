#!/bin/bash
# test-sql-connection.sh
# Tests SQL Server connection using password from file

# Create password file (run once)
if [ ! -f ~/.sqlpass ]; then
    echo "Creating password file..."
    echo "Gv51076!" > ~/.sqlpass
    chmod 600 ~/.sqlpass
fi

# Set password from file
export SQLCMDPASSWORD=$(cat ~/.sqlpass)

# Test connection
echo "Testing SQL Server connection..."
sqlcmd -S sqltest.schoolvision.net,14333 \
    -U sv \
    -d FireProofDB \
    -C \
    -Q "SELECT DB_NAME() AS [Database], SUSER_NAME() AS [User], @@VERSION AS [SQL Version]" \
    -W

echo ""
echo "Listing tables..."
sqlcmd -S sqltest.schoolvision.net,14333 \
    -U sv \
    -d FireProofDB \
    -C \
    -Q "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_SCHEMA, TABLE_NAME" \
    -W
