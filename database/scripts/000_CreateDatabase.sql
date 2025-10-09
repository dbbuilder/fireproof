/*============================================================================
  File:     000_CreateDatabase.sql
  Summary:  Creates the FireProofDB database
  Date:     October 9, 2025

  Description:
    This script creates the FireProofDB database if it doesn't exist.
    Run this first before any other database setup scripts.
============================================================================*/

-- Check if database exists
IF DB_ID('FireProofDB') IS NOT NULL
BEGIN
    PRINT 'Database FireProofDB already exists'
END
ELSE
BEGIN
    PRINT 'Creating database FireProofDB...'
    CREATE DATABASE FireProofDB
    PRINT 'Database FireProofDB created successfully!'
END
GO

-- Use the database
USE FireProofDB
GO

PRINT 'Ready to run migration scripts on FireProofDB'
GO
