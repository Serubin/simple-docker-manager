# Simple Docker Manager

A lightweight, bash-based Docker Compose service manager that simplifies managing multiple Docker services organized in a clean directory structure.

## Features

- 🚀 **Simple CLI**: Easy-to-use commands for managing Docker services
- 📁 **Organized Structure**: Each service lives in its own directory
- ⚡ **Bulk Operations**: Start, stop, or restart all enabled services at once
- 🎯 **Selective Control**: Enable/disable services for bulk operations
- 📊 **Service Status**: List all services with their enabled/disabled status
- 📝 **Log Viewing**: View logs for individual services with optional follow mode
- 🎨 **Colorized Output**: Clear, color-coded messages for better readability

## Requirements

- Bash 4.0 or higher
- Docker
- Docker Compose (v2.0+)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/serubin/simple-docker-manager.git
cd simple-docker-manager
```

2. Make the script executable:
```bash
chmod +x services.sh
```

3. (Optional) Add to your PATH for global access:
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/simple-docker-manager"
alias services="./services.sh"  # Optional: create a shorter alias
```

## Directory Structure

The script expects services to be organized in the following structure:

```
your-docker-compose-location/
├── .enabled_services        # Configuration file (auto-generated)
├── service1/                # Service directory
│   └── docker-compose.yml   # Docker Compose configuration
├── service2/
│   └── docker-compose.yml
├── postgres/
│   └── docker-compose.yml
└── redis/
    └── docker-compose.yml
```

### Service Directory Structure

Each service should be in its own directory at the root level of the project. The directory name becomes the service name. Inside each service directory, place a `docker-compose.yml` file.

**Example service directory:**
```
postgres/
├── docker-compose.yml
├── .env                    # Optional: environment variables
├── data/                   # Optional: persistent data
└── config/                 # Optional: configuration files
```

**Example docker-compose.yml:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - ./data:/var/lib/postgresql/data
```

## Usage

### Basic Commands

#### Start a service
```bash
./services.sh start <service_name>
```

#### Stop a service
```bash
./services.sh stop <service_name>
```

#### Restart a service
```bash
./services.sh restart <service_name>
```

#### View logs
```bash
# View logs
./services.sh logs <service_name>

# Follow logs (live updates)
./services.sh logs <service_name> -f
```

### Bulk Operations

Bulk operations (`start all`, `stop all`, `restart all`) only affect services that have been explicitly enabled.

#### Start all enabled services
```bash
./services.sh start all
```

#### Stop all enabled services
```bash
./services.sh stop all
```

#### Restart all enabled services
```bash
./services.sh restart all
```

### Service Management

#### List all services
Shows all available services and their enabled/disabled status:
```bash
./services.sh list
```

Output example:
```
Available services:
  ✓ postgres (enabled)
  ✓ redis (enabled)
  ○ nginx (disabled)
  ○ mongodb (disabled)
```

#### Enable a service
Enable a service to include it in bulk operations:
```bash
./services.sh enable <service_name>
```

#### Disable a service
Disable a service to exclude it from bulk operations:
```bash
./services.sh disable <service_name>
```

#### Enable all services
```bash
./services.sh enable all
```

#### Disable all services
```bash
./services.sh disable all
```

### Help

View the help message:
```bash
./services.sh help
# or
./services.sh --help
# or
./services.sh -h
```

## Examples

### Setting up a new service

1. Create a directory for your service:
```bash
mkdir postgres
```

2. Create a `docker-compose.yml` file inside:
```bash
cd postgres
# Create your docker-compose.yml file
```

3. Enable the service (optional, for bulk operations):
```bash
cd ..
./services.sh enable postgres
```

4. Start the service:
```bash
./services.sh start postgres
```

### Common Workflows

**Start your development environment:**
```bash
./services.sh start all
```

**Stop everything:**
```bash
./services.sh stop all
```

**Check what's running:**
```bash
./services.sh list
```

**Debug a service:**
```bash
./services.sh logs postgres -f
```

**Restart a specific service:**
```bash
./services.sh restart postgres
```

## Configuration

The script automatically creates a `.enabled_services` file in the project root to track which services are enabled for bulk operations. This file is plain text, with one service name per line. You can edit it manually if needed, or use the `enable`/`disable` commands.

**Example .enabled_services file:**
```
postgres
redis
nginx
```

Comments (lines starting with `#`) are supported and will be ignored.

## How It Works

1. The script scans the project directory for subdirectories containing `docker-compose.yml` files
2. Each directory with a `docker-compose.yml` is considered a service
3. Services can be individually managed or grouped for bulk operations
4. The `.enabled_services` file determines which services are included in `all` operations
5. All Docker Compose commands are executed from within each service's directory

## Troubleshooting

### Service not found
- Ensure the service directory exists at the root level
- Verify that `docker-compose.yml` exists in the service directory
- Check that the service name matches the directory name exactly

### Permission denied
- Make sure the script is executable: `chmod +x services.sh`
- Ensure Docker is running and you have permissions to use it

### Services not starting
- Check Docker and Docker Compose are installed and running
- Verify your `docker-compose.yml` files are valid
- Use `./services.sh logs <service_name>` to view error messages

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created with ❤️ for simplifying Docker service management.

