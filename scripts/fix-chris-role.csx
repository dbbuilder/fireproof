#!/usr/bin/env dotnet-script
#r "nuget: Microsoft.Data.SqlClient, 5.1.0"

using Microsoft.Data.SqlClient;
using System;

var connectionString = "Server=sqltest.schoolvision.net,14333;Database=FireProofDB;User Id=sv;Password=Gv51076!;TrustServerCertificate=True;Encrypt=Optional;MultipleActiveResultSets=true;Connection Timeout=30";

Console.WriteLine("============================================================================");
Console.WriteLine("Fixing chris@servicevision.net tenant role");
Console.WriteLine("============================================================================");
Console.WriteLine();

try
{
    using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    Console.WriteLine("✓ Connected to database");
    Console.WriteLine();

    // Get chris user ID
    var chrisUserId = Guid.Empty;
    var tenantId = Guid.Parse("634F2B52-D32A-46DD-A045-D158E793ADCB");

    using (var cmd = new SqlCommand("SELECT UserId FROM dbo.Users WHERE Email = 'chris@servicevision.net'", connection))
    {
        var result = await cmd.ExecuteScalarAsync();
        if (result != null)
        {
            chrisUserId = (Guid)result;
            Console.WriteLine($"✓ Found chris@servicevision.net");
            Console.WriteLine($"  UserId: {chrisUserId}");
            Console.WriteLine();
        }
        else
        {
            Console.WriteLine("❌ ERROR: chris@servicevision.net not found");
            return 1;
        }
    }

    // Check current roles
    Console.WriteLine("Current roles:");
    using (var cmd = new SqlCommand(@"
        SELECT 'System' AS RoleType, sr.RoleName
        FROM dbo.UserSystemRoles usr
        INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
        WHERE usr.UserId = @UserId AND usr.IsActive = 1
        UNION ALL
        SELECT 'Tenant' AS RoleType, utr.RoleName
        FROM dbo.UserTenantRoles utr
        WHERE utr.UserId = @UserId AND utr.IsActive = 1
    ", connection))
    {
        cmd.Parameters.AddWithValue("@UserId", chrisUserId);
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            Console.WriteLine($"  {reader["RoleType"]}: {reader["RoleName"]}");
        }
    }
    Console.WriteLine();

    // Check if TenantAdmin role exists
    bool roleExists = false;
    using (var cmd = new SqlCommand(@"
        SELECT COUNT(*) FROM dbo.UserTenantRoles
        WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = 'TenantAdmin'
    ", connection))
    {
        cmd.Parameters.AddWithValue("@UserId", chrisUserId);
        cmd.Parameters.AddWithValue("@TenantId", tenantId);
        roleExists = ((int)await cmd.ExecuteScalarAsync()) > 0;
    }

    if (roleExists)
    {
        Console.WriteLine("✓ chris@servicevision.net already has TenantAdmin role for DEMO001");

        // Make sure it's active
        using (var cmd = new SqlCommand(@"
            UPDATE dbo.UserTenantRoles
            SET IsActive = 1
            WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = 'TenantAdmin'
        ", connection))
        {
            cmd.Parameters.AddWithValue("@UserId", chrisUserId);
            cmd.Parameters.AddWithValue("@TenantId", tenantId);
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("  ✓ Ensured role is active");
        }
    }
    else
    {
        Console.WriteLine("Adding TenantAdmin role for DEMO001...");
        using (var cmd = new SqlCommand(@"
            INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
            VALUES (@UserId, @TenantId, 'TenantAdmin', 1, GETUTCDATE())
        ", connection))
        {
            cmd.Parameters.AddWithValue("@UserId", chrisUserId);
            cmd.Parameters.AddWithValue("@TenantId", tenantId);
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("  ✓ Added TenantAdmin role");
        }
    }

    Console.WriteLine();
    Console.WriteLine("============================================================================");
    Console.WriteLine("Updated roles:");
    Console.WriteLine("============================================================================");

    using (var cmd = new SqlCommand(@"
        SELECT 'System' AS RoleType, sr.RoleName, CAST(NULL AS UNIQUEIDENTIFIER) AS TenantId
        FROM dbo.UserSystemRoles usr
        INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
        WHERE usr.UserId = @UserId AND usr.IsActive = 1
        UNION ALL
        SELECT 'Tenant' AS RoleType, utr.RoleName, utr.TenantId
        FROM dbo.UserTenantRoles utr
        WHERE utr.UserId = @UserId AND utr.IsActive = 1
    ", connection))
    {
        cmd.Parameters.AddWithValue("@UserId", chrisUserId);
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            if (reader["RoleType"].ToString() == "System")
                Console.WriteLine($"  System: {reader["RoleName"]}");
            else
                Console.WriteLine($"  Tenant: {reader["RoleName"]} (TenantId: {reader["TenantId"]})");
        }
    }

    Console.WriteLine();
    Console.WriteLine("✓ Done! JWT tokens will now include tenant_id claim for DEMO001");
    Console.WriteLine("============================================================================");

    return 0;
}
catch (Exception ex)
{
    Console.WriteLine($"❌ ERROR: {ex.Message}");
    Console.WriteLine(ex.StackTrace);
    return 1;
}
