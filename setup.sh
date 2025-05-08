# !/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Docker UV Devcontainer CI Template Setup ===${NC}"
echo -e "${YELLOW}This script will customize the template for your project.${NC}"
echo

# Get project name
read -p "Enter your project name (lowercase, use hyphens for spaces): " project_name

# Validate project name (allow lowercase letters, numbers, and hyphens)
if ! [[ $project_name =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${YELLOW}Warning: Project name should only contain lowercase letters, numbers, and hyphens.${NC}"
    read -p "Continue anyway? (y/n): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo "Setup aborted."
        exit 1
    fi
fi

# Convert project name to uppercase for environment variables
project_name_upper=$(echo $project_name | tr '[:lower:]' '[:upper:]' | tr '-' '_')

# Ask about Node.js requirement
echo
echo -e "${BLUE}Node.js Support${NC}"
read -p "Does this project require Node.js / npm? (y/n): " requires_node
requires_node=$(echo $requires_node | tr '[:upper:]' '[:lower:]')

# Ask about Wagtail CMS
echo
echo -e "${BLUE}Wagtail CMS Support${NC}"
read -p "Does this project use Wagtail CMS? (y/n): " uses_wagtail
uses_wagtail=$(echo $uses_wagtail | tr '[:upper:]' '[:lower:]')

# Determine which Dockerfile to use
if [[ $requires_node == "y" && $uses_wagtail == "y" ]]; then
    dockerfile_source="backend/Dockerfile_node_wagtail"
    compose_source="compose_node.yaml"
elif [[ $requires_node == "y" && $uses_wagtail != "y" ]]; then
    dockerfile_source="backend/Dockerfile_node"
    compose_source="compose_node.yaml"
elif [[ $requires_node != "y" && $uses_wagtail == "y" ]]; then
    dockerfile_source="backend/Dockerfile_Wagtail"
    compose_source="compose.yaml"
else
    dockerfile_source="backend/Dockerfile"
    compose_source="compose.yaml"
fi

# Determine which dependencies to remove from pyproject.toml
node_dependencies=("django-tailwind")
wagtail_dependencies=("django-taggit" "django-reversion")

echo
echo -e "${BLUE}Configuration Summary:${NC}"
echo -e "Project name: ${GREEN}$project_name${NC}"
echo -e "Environment variable name: ${GREEN}$project_name_upper${NC}"
echo -e "Node.js support: ${GREEN}$(if [[ $requires_node == "y" ]]; then echo "Yes"; else echo "No"; fi)${NC}"
echo -e "Wagtail CMS support: ${GREEN}$(if [[ $uses_wagtail == "y" ]]; then echo "Yes"; else echo "No"; fi)${NC}"
echo -e "Selected Dockerfile: ${GREEN}$dockerfile_source${NC}"
echo -e "Selected compose file: ${GREEN}$compose_source${NC}"
echo

# Confirm before proceeding
read -p "Proceed with these settings? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Setup aborted."
    exit 1
fi

echo
echo -e "${BLUE}Applying changes...${NC}"

# Rename and copy the selected Dockerfile
echo "Setting up Dockerfile..."
cp "$dockerfile_source" "backend/Dockerfile"

# Create .devcontainer directory if it doesn't exist
if [ ! -d ".devcontainer" ]; then
    echo "Creating .devcontainer directory..."
    mkdir -p ".devcontainer"
fi

# Copy the selected Dockerfile to .devcontainer and remove Prod Stage
echo "Setting up .devcontainer Dockerfile..."
cp "$dockerfile_source" ".devcontainer/Dockerfile"

# Remove Prod Stage from .devcontainer Dockerfile
echo "Removing Prod Stage from .devcontainer Dockerfile..."
sed -i '/# ----------------------\n# ----- PROD STAGE -----/,$d' ".devcontainer/Dockerfile"

# Rename and copy the selected compose file
echo "Setting up compose file..."
cp "$compose_source" "compose.yaml"

# Replace occurrences of template names with the project name
echo "Replacing template names with your project name..."

# Find all files that might contain the template names (excluding .git directory and this script)
files_to_process=$(find . -type f \( -not -path "*/\.git/*" -and -not -path "./setup.sh" -or -path "*/.devcontainer/*" -or -path "*/.github/workflows/*" \) | xargs grep -l -E "docker_uv_devcontainer_ci|project-name|PROJECT_NAME|project_name" 2>/dev/null)

for file in $files_to_process; do
    echo "Processing $file..."
    # Replace the template names with the project name
    sed -i "s/docker_uv_devcontainer_ci/$project_name/g" "$file"
    sed -i "s/project-name/$project_name/g" "$file"
    sed -i "s/project_name/$project_name/g" "$file"
    sed -i "s/PROJECT_NAME/$project_name/g" "$file"
done

# Rename the Django project folder
echo "Renaming Django project folder..."
if [ -d "backend/PROJECT_NAME" ]; then
    mv "backend/PROJECT_NAME" "backend/$project_name"
fi

# Delete unused Dockerfiles
echo "Cleaning up unused Dockerfiles..."
for df in backend/Dockerfile_* ; do
    if [[ -f "$df" ]]; then
        echo "Removing $df"
        rm "$df"
    fi
done

# Delete unused compose file
if [[ -f "compose_node.yaml" ]]; then
    echo "Removing compose_node.yaml"
    rm "compose_node.yaml"
fi

# Remove unneeded dependencies from pyproject.toml
echo "Updating dependencies in pyproject.toml..."
if [[ $requires_node != "y" ]]; then
    for dep in "${node_dependencies[@]}"; do
        echo "Removing $dep dependency..."
        sed -i "/\"$dep==/d" pyproject.toml
    done
fi

if [[ $uses_wagtail != "y" ]]; then
    for dep in "${wagtail_dependencies[@]}"; do
        echo "Removing $dep dependency..."
        sed -i "/\"$dep==/d" pyproject.toml
    done
fi

# Handle GitHub workflow files
echo "Updating GitHub workflow files..."
if [[ $requires_node == "y" ]]; then
    # If Node.js is required, use tests_node.yml as tests.yml
    if [[ -f ".github/workflows/tests_node.yml" ]]; then
        echo "Using Node.js workflow file..."
        cp ".github/workflows/tests_node.yml" ".github/workflows/tests.yml"
    fi
else
    # If Node.js is not required, keep the existing tests.yml
    echo "Using standard workflow file..."
fi

# Always keep code-quality.yml

# Delete this setup script
echo "Removing setup script..."
# We don't actually delete the script here since we're still running it

echo
echo -e "${GREEN}Setup complete!${NC}"
echo -e "Your project '$project_name' is now ready to use."
echo -e "You can now delete this setup script manually."
