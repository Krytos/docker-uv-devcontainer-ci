# Docker UV DevContainer CI Template

This project serves as a template for quickly setting up new projects with a Docker-based development environment, using UV for Python package management, VS Code DevContainers for development, and various other features.

## Features

- **Interactive Setup**: Run the setup script to create a new project with your chosen features
- **Docker Development Environment**: Containerized development environment for consistent development across machines
- **Python with UV**: Modern, fast Python package management
- **VS Code DevContainer Integration**: Seamless development experience in VS Code
- **Customizable Features**: Choose from various components including:
  - Django Backend
  - PostgreSQL Database
  - Redis Cache
  - Frontend (Node.js)
  - CI/CD Pipeline
  - Pre-commit Hooks
  - Wagtail CMS

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/docker-uv-devcontainer-ci.git
   cd docker-uv-devcontainer-ci
   ```

2. Make the setup script executable (on Unix-like systems):
   ```bash
   chmod +x setup.sh
   ```

   On Windows, you may need to run it using:
   ```bash
   bash setup.sh
   ```

3. Run the setup script:

   On Unix-like systems:
   ```bash
   ./setup.sh
   ```

   On Windows:
   ```powershell
   .\setup.ps1
   ```

4. Follow the interactive prompts:
   - Enter your project name
   - Select desired features using checkboxes (navigate with arrow keys, select with space, confirm with enter)
   - Wait for the script to generate your project

5. Navigate to your new project directory and start developing!

## Requirements

- Bash shell
- Docker and Docker Compose
- VS Code with Remote - Containers extension (for DevContainer support)

## How It Works

The setup script will:
1. Ask for your project name
2. Present a list of features to include
3. Create a new directory with your project name
4. Generate customized configuration files based on your selections
5. Set up Docker, DevContainer, and other configurations

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve this template.

## License

MIT
