# Web-based Dashboard Server

[CmdletBinding()]
param(
    [Parameter()]
    [int] $Port = 8080,

    [Parameter()]
    [string] $HostName = 'localhost'
)

$ErrorActionPreference = 'Stop'

# Simple HTTP server using .NET HttpListener
Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.Text;
using System.IO;

public class SimpleHttpServer {
    private HttpListener listener;
    private string basePath;
    
    public SimpleHttpServer(string prefix, string basePath) {
        this.listener = new HttpListener();
        this.listener.Prefixes.Add(prefix);
        this.basePath = basePath;
    }
    
    public void Start() {
        listener.Start();
        Console.WriteLine("Server started on " + listener.Prefixes.FirstOrDefault());
    }
    
    public void Stop() {
        listener.Stop();
    }
    
    public void ProcessRequests() {
        while (listener.IsListening) {
            var context = listener.GetContext();
            ProcessRequest(context);
        }
    }
    
    private void ProcessRequest(HttpListenerContext context) {
        var request = context.Request;
        var response = context.Response;
        
        string path = request.Url.AbsolutePath;
        string filePath = Path.Combine(basePath, path.TrimStart('/'));
        
        if (File.Exists(filePath)) {
            byte[] buffer = File.ReadAllBytes(filePath);
            response.ContentLength64 = buffer.Length;
            response.OutputStream.Write(buffer, 0, buffer.Length);
        } else {
            string html = "<html><body><h1>Better11 Deployment Dashboard</h1><p>Dashboard content here</p></body></html>";
            byte[] buffer = Encoding.UTF8.GetBytes(html);
            response.ContentLength64 = buffer.Length;
            response.OutputStream.Write(buffer, 0, buffer.Length);
        }
        
        response.OutputStream.Close();
    }
}
"@ -Language CSharp

$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force

$root = Get-DeployRoot
$dashboardPath = Join-Path $root 'src\Dashboard'
$prefix = "http://${HostName}:${Port}/"

$server = New-Object SimpleHttpServer($prefix, $dashboardPath)

Write-Host "Starting web dashboard server on $prefix" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

try {
    $server.Start()
    $server.ProcessRequests()
}
finally {
    $server.Stop()
    Write-Host "Server stopped" -ForegroundColor Yellow
}

