# PowerShell script for Docker UV Devcontainer CI Template Setup

# Colors for better readability
$Green = [System.ConsoleColor]::Green
$Blue = [System.ConsoleColor]::Blue
$Yellow = [System.ConsoleColor]::Yellow

Write-Host "=== Docker UV Devcontainer CI Template Setup ===" -ForegroundColor $Blue
Write-Host "This script will customize the template for your project." -ForegroundColor $Yellow
Write-Host ""

# Get project name
$project_name = Read-Host "Enter your project name (lowercase, use hyphens for spaces)"

# Validate project name (allow lowercase letters, numbers, and hyphens)
if ($project_name -notmatch "^[a-z0-9-]+$") {
    Write-Host "Warning: Project name should only contain lowercase letters, numbers, and hyphens." -ForegroundColor $Yellow
    $continue_anyway = Read-Host "Continue anyway? (y/n)"
    if ($continue_anyway -notmatch "^[Yy]$") {
        Write-Host "Setup aborted."
        exit 1
    }
}

# Convert project name to uppercase for environment variables
$project_name_upper = $project_name.ToUpper() -replace "-", "_"

# Ask about Node.js requirement
Write-Host ""
Write-Host "Node.js Support" -ForegroundColor $Blue
$requires_node = Read-Host "Does this project require Node.js / npm? (y/n)"
$requires_node = $requires_node.ToLower()

# Ask about Wagtail CMS
Write-Host ""
Write-Host "Wagtail CMS Support" -ForegroundColor $Blue
$uses_wagtail = Read-Host "Does this project use Wagtail CMS? (y/n)"
$uses_wagtail = $uses_wagtail.ToLower()

# Determine which Dockerfile to use
if ($requires_node -eq "y" -and $uses_wagtail -eq "y") {
    $dockerfile_source = "backend\Dockerfile_node_wagtail"
    $compose_source = "compose_node.yaml"
}
elseif ($requires_node -eq "y" -and $uses_wagtail -ne "y") {
    $dockerfile_source = "backend\Dockerfile_node"
    $compose_source = "compose_node.yaml"
}
elseif ($requires_node -ne "y" -and $uses_wagtail -eq "y") {
    $dockerfile_source = "backend\Dockerfile_Wagtail"
    $compose_source = "compose.yaml"
}
else {
    $dockerfile_source = "backend\Dockerfile"
    $compose_source = "compose.yaml"
}

# Determine which dependencies to remove from pyproject.toml
$node_dependencies = @("django-tailwind")
$wagtail_dependencies = @("django-taggit", "django-reversion")

Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor $Blue
Write-Host "Project name: $project_name" -ForegroundColor $Green
Write-Host "Environment variable name: $project_name_upper" -ForegroundColor $Green
Write-Host "Node.js support: $(if ($requires_node -eq 'y') { 'Yes' } else { 'No' })" -ForegroundColor $Green
Write-Host "Wagtail CMS support: $(if ($uses_wagtail -eq 'y') { 'Yes' } else { 'No' })" -ForegroundColor $Green
Write-Host "Selected Dockerfile: $dockerfile_source" -ForegroundColor $Green
Write-Host "Selected compose file: $compose_source" -ForegroundColor $Green
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "Proceed with these settings? (y/n)"
if ($confirm -notmatch "^[Yy]$") {
    Write-Host "Setup aborted."
    exit 1
}

Write-Host ""
Write-Host "Applying changes..." -ForegroundColor $Blue

# Rename and copy the selected Dockerfile
Write-Host "Setting up Dockerfile..."
Copy-Item -Path $dockerfile_source -Destination "backend\Dockerfile" -Force

# Create .devcontainer directory if it doesn't exist
if (-not (Test-Path ".devcontainer")) {
    Write-Host "Creating .devcontainer directory..."
    New-Item -Path ".devcontainer" -ItemType Directory -Force | Out-Null
}

# Copy the selected Dockerfile to .devcontainer and remove Prod Stage
Write-Host "Setting up .devcontainer Dockerfile..."
Copy-Item -Path $dockerfile_source -Destination ".devcontainer\Dockerfile" -Force

# Remove Prod Stage from .devcontainer Dockerfile
Write-Host "Removing Prod Stage from .devcontainer Dockerfile..."
$dockerfile_content = Get-Content -Path ".devcontainer\Dockerfile" -Raw
$prod_stage_index = $dockerfile_content.IndexOf("# ----------------------\n# ----- PROD STAGE -----")
if ($prod_stage_index -gt 0) {
    $dockerfile_content = $dockerfile_content.Substring(0, $prod_stage_index)
    Set-Content -Path ".devcontainer\Dockerfile" -Value $dockerfile_content
}

# Rename and copy the selected compose file
Write-Host "Setting up compose file..."
Copy-Item -Path $compose_source -Destination "compose.yaml" -Force

# Replace occurrences of template names with the project name
Write-Host "Replacing template names with your project name..."

# Find all files that might contain the template names (excluding .git directory and this script)
$files_to_process = Get-ChildItem -Path . -Recurse -File -Force | 
                    Where-Object { 
                        $_.FullName -notmatch "\\\.git\\" -and 
                        $_.FullName -ne (Resolve-Path ".\setup.ps1").Path 
                    } | 
                    Select-String -Pattern "docker_uv_devcontainer_ci|project-name|PROJECT_NAME|Docker UV DevContainer CI Template|project_name" -List |
                    Select-Object -ExpandProperty Path

# Create a properly capitalized version of the project name for titles
$project_name_title = ($project_name -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ' '

foreach ($file in $files_to_process) {
    Write-Host "Processing $file..."
    $content = Get-Content -Path $file -Raw

    # Special handling for pyproject.toml
    if ($file -eq ".\pyproject.toml") {
        # Replace name = "PROJECT_NAME" with lowercase project name
        $content = $content -replace 'name = "PROJECT_NAME"', "name = `"$project_name`""
        # Replace other PROJECT_NAME occurrences with lowercase
        $content = $content -replace 'PROJECT_NAME', $project_name
    }
    # Special handling for README.md
    elseif ($file -eq ".\README.md") {
        # Replace title with properly capitalized project name
        $content = $content -replace 'Docker UV DevContainer CI Template', "$project_name_title"
        # Replace other occurrences with lowercase
        $content = $content -replace 'docker-uv-devcontainer-ci', $project_name
    }
    # Default replacements for other files
    else {
        $content = $content -replace 'docker_uv_devcontainer_ci', $project_name
        $content = $content -replace 'project-name', $project_name
        $content = $content -replace 'PROJECT_NAME', $project_name
    }

    # Write the modified content back to the file
    Set-Content -Path $file -Value $content
}

# Rename the Django project folder
Write-Host "Renaming Django project folder..."
if (Test-Path "backend\PROJECT_NAME") {
    Rename-Item -Path "backend\PROJECT_NAME" -NewName $project_name -Force
}

# Delete unused Dockerfiles
Write-Host "Cleaning up unused Dockerfiles..."
Get-ChildItem -Path "backend\Dockerfile_*" | ForEach-Object {
    Write-Host "Removing $_"
    Remove-Item -Path $_.FullName -Force
}

# Delete unused compose file
if (Test-Path "compose_node.yaml") {
    Write-Host "Removing compose_node.yaml"
    Remove-Item -Path "compose_node.yaml" -Force
}

# Remove unneeded dependencies from pyproject.toml
Write-Host "Updating dependencies in pyproject.toml..."
$pyproject_content = Get-Content -Path "pyproject.toml" -Raw

if ($requires_node -ne "y") {
    foreach ($dep in $node_dependencies) {
        Write-Host "Removing $dep dependency..."
        $pyproject_content = $pyproject_content -replace "    `"$dep==.*?`",`n", ""
    }
}

if ($uses_wagtail -ne "y") {
    foreach ($dep in $wagtail_dependencies) {
        Write-Host "Removing $dep dependency..."
        $pyproject_content = $pyproject_content -replace "    `"$dep==.*?`",`n", ""
    }
}

Set-Content -Path "pyproject.toml" -Value $pyproject_content

# Handle GitHub workflow files
Write-Host "Updating GitHub workflow files..."
if ($requires_node -eq "y") {
    # If Node.js is required, use tests_node.yml as tests.yml
    if (Test-Path ".github\workflows\tests_node.yml") {
        Write-Host "Using Node.js workflow file..."
        Copy-Item -Path ".github\workflows\tests_node.yml" -Destination ".github\workflows\tests.yml" -Force
    }
}
else {
    # If Node.js is not required, keep the existing tests.yml
    Write-Host "Using standard workflow file..."
}

# Always keep code-quality.yml

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor $Green
Write-Host "Your project '$project_name' is now ready to use."
Write-Host "You can now delete this setup script manually."
