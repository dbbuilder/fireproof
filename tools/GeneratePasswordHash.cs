using System;

class Program
{
    static void Main(string[] args)
    {
        string password = "FireProofIt!";
        int workFactor = 12;

        // Generate salt
        string salt = BCrypt.Net.BCrypt.GenerateSalt(workFactor);

        // Hash password with salt
        string hash = BCrypt.Net.BCrypt.HashPassword(password, salt);

        Console.WriteLine("Password: " + password);
        Console.WriteLine("Salt: " + salt);
        Console.WriteLine("Hash: " + hash);
        Console.WriteLine();
        Console.WriteLine("SQL UPDATE Statement:");
        Console.WriteLine($"UPDATE dbo.Users SET PasswordHash = '{hash}', PasswordSalt = '{salt}' WHERE Email IN ('jdunn@2amarketing.com', 'cpayne4@kumc.edu');");
    }
}
