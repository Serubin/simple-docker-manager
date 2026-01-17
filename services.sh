#!/bin/bash

# Docker Service Manager
# Manages Docker Compose services in docker/<service_name>/docker-compose.yml structure

set -e

SERVICES_PATH="$(pwd)"
CONFIG_FILE=".enabled_services"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to get all available services
get_all_services() {
    if [ ! -d "$SERVICES_PATH" ]; then
        print_error "Docker directory not found: $SERVICES_PATH"
        exit 1
    fi
    
    local services=()
    for dir in "$SERVICES_PATH"/*; do
        if [ -d "$dir" ] && [ -f "$dir/docker-compose.yml" ]; then
            services+=("$(basename "$dir")")
        fi
    done
    echo "${services[@]}"
}

# Function to get enabled services (for "all" command)
get_enabled_services() {
    if [ ! -f "$CONFIG_FILE" ]; then
        # If no config file, return all services
        get_all_services
        return
    fi
    
    local enabled=()
    while IFS= read -r service; do
        # Skip empty lines and comments
        [[ -z "$service" || "$service" =~ ^[[:space:]]*# ]] && continue
        # Trim whitespace
        service=$(echo "$service" | xargs)
        if [ -n "$service" ]; then
            enabled+=("$service")
        fi
    done < "$CONFIG_FILE"
    
    echo "${enabled[@]}"
}

# Function to normalize service name (remove trailing slash)
normalize_service_name() {
    local service=$1
    # Remove trailing slash if present
    echo "${service%/}"
}

# Function to check if a service exists
service_exists() {
    local service=$1
    local compose_file="${SERVICES_PATH}/${service}/docker-compose.yml"
    
    if [ ! -f "$compose_file" ]; then
        return 1
    fi
    return 0
}

# Function to start a service
start_service() {
    local service=$1
    local compose_file="${SERVICES_PATH}/${service}/docker-compose.yml"
    
    print_info "Starting service: $service"
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found at $compose_file"
        return 1
    fi
    
    cd "${SERVICES_PATH}/${service}"
    if docker compose up -d; then
        print_success "✓ Service '$service' started successfully"
        return 0
    else
        print_error "Failed to start service '$service'"
        return 1
    fi
}

# Function to stop a service
stop_service() {
    local service=$1
    local compose_file="${SERVICES_PATH}/${service}/docker-compose.yml"
    
    print_info "Stopping service: $service"
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found at $compose_file"
        return 1
    fi
    
    cd "${SERVICES_PATH}/${service}"
    if docker compose down; then
        print_success "✓ Service '$service' stopped successfully"
        return 0
    else
        print_error "Failed to stop service '$service'"
        return 1
    fi
}

# Function to restart a service
restart_service() {
    local service=$1
    
    print_info "Restarting service: $service"
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    if stop_service "$service"; then
        if start_service "$service"; then
            print_success "✓ Service '$service' restarted successfully"
            return 0
        else
            print_error "Failed to restart service '$service' (start failed)"
            return 1
        fi
    else
        print_error "Failed to restart service '$service' (stop failed)"
        return 1
    fi
}

# Function to show logs for a service
log_service() {
    local service=$1
    local follow_flag=$2
    local compose_file="${SERVICES_PATH}/${service}/docker-compose.yml"
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found at $compose_file"
        return 1
    fi
    
    cd "${SERVICES_PATH}/${service}"
    
    if [ "$follow_flag" = "-f" ]; then
        print_info "Showing logs for service: $service (following...)"
        docker compose logs -f
    else
        print_info "Showing logs for service: $service"
        docker compose logs
    fi
}

# Function to start all services
start_all() {
    print_info "Starting all enabled services..."
    local services=($(get_enabled_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_error "No enabled services found. Use '$0 enable <service>' to enable services."
        exit 1
    fi
    
    local failed=0
    for service in "${services[@]}"; do
        if ! start_service "$service"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        print_success "\n✓ All enabled services started successfully"
    else
        print_error "\n✗ $failed service(s) failed to start"
        exit 1
    fi
}

# Function to stop all services
stop_all() {
    print_info "Stopping all enabled services..."
    local services=($(get_enabled_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_error "No enabled services found. Use '$0 enable <service>' to enable services."
        exit 1
    fi
    
    local failed=0
    for service in "${services[@]}"; do
        if ! stop_service "$service"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        print_success "\n✓ All enabled services stopped successfully"
    else
        print_error "\n✗ $failed service(s) failed to stop"
        exit 1
    fi
}

# Function to restart all services
restart_all() {
    print_info "Restarting all enabled services..."
    local services=($(get_enabled_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_error "No enabled services found. Use '$0 enable <service>' to enable services."
        exit 1
    fi
    
    local failed=0
    for service in "${services[@]}"; do
        if ! restart_service "$service"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        print_success "\n✓ All enabled services restarted successfully"
    else
        print_error "\n✗ $failed service(s) failed to restart"
        exit 1
    fi
}

# Function to list available services
list_services() {
    print_info "Available services:"
    local all_services=($(get_all_services))
    local enabled_services=($(get_enabled_services))
    
    if [ ${#all_services[@]} -eq 0 ]; then
        echo "  No services found in $SERVICES_PATH"
        return
    fi
    
    for service in "${all_services[@]}"; do
        if [[ " ${enabled_services[@]} " =~ " ${service} " ]]; then
            echo -e "  ${GREEN}✓${NC} $service (enabled)"
        else
            echo -e "  ${YELLOW}○${NC} $service (disabled)"
        fi
    done
    
    echo ""
    echo "Use '$0 enable <service>' to enable a service for 'all' operations"
    echo "Use '$0 disable <service>' to disable a service from 'all' operations"
}

# Function to enable a service
enable_service() {
    local service=$1
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    local enabled_services=($(get_enabled_services))
    
    # Check if already enabled
    if [[ " ${enabled_services[@]} " =~ " ${service} " ]]; then
        print_info "Service '$service' is already enabled"
        return 0
    fi
    
    # Add to config file
    echo "$service" >> "$CONFIG_FILE"
    print_success "✓ Service '$service' enabled"
}

# Function to disable a service
disable_service() {
    local service=$1
    
    if ! service_exists "$service"; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    # If config file doesn't exist, create it with all services first
    if [ ! -f "$CONFIG_FILE" ]; then
        local all_services=($(get_all_services))
        for svc in "${all_services[@]}"; do
            echo "$svc" >> "$CONFIG_FILE"
        done
    fi
    
    # Create temp file without the service
    grep -v "^${service}$" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    print_success "✓ Service '$service' disabled"
}

# Function to enable all services
enable_all() {
    local all_services=($(get_all_services))
    
    if [ ${#all_services[@]} -eq 0 ]; then
        print_error "No services found"
        exit 1
    fi
    
    # Clear config file and add all services
    > "$CONFIG_FILE"
    for service in "${all_services[@]}"; do
        echo "$service" >> "$CONFIG_FILE"
    done
    
    print_success "✓ All services enabled (${#all_services[@]} services)"
}

# Function to disable all services
disable_all() {
    if [ -f "$CONFIG_FILE" ]; then
        > "$CONFIG_FILE"
    fi
    print_success "✓ All services disabled"
}

# Function to show usage
show_usage() {
    cat << EOF
Docker Service Manager

Usage: $0 <command> [service_name] [options]

Commands:
    start <service_name>    Start a specific service
    stop <service_name>     Stop a specific service
    restart <service_name>  Restart a specific service
    start all               Start all enabled services
    stop all                Stop all enabled services
    restart all             Restart all enabled services
    logs <service_name> [-f] Show logs for a service (-f to follow)
    list                    List all available services (enabled/disabled)
    enable <service_name>   Enable a service for 'all' operations
    disable <service_name>  Disable a service from 'all' operations
    enable all              Enable all services
    disable all             Disable all services
    help                    Show this help message

Examples:
    $0 start postgres
    $0 stop redis
    $0 restart postgres
    $0 start all
    $0 stop all
    $0 restart all
    $0 logs postgres
    $0 logs postgres -f
    $0 list
    $0 enable postgres
    $0 disable redis
    $0 enable all

Note: The 'all' command only affects services marked as enabled.
      Enable/disable services to control which ones are included in 'all' operations.

EOF
}

# Main script logic
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local command=$1
    local service=$(normalize_service_name "$2")
    local option=$3
    
    case "$command" in
        start)
            if [ -z "$service" ]; then
                print_error "Please specify a service name or 'all'"
                show_usage
                exit 1
            fi
            
            if [ "$service" = "all" ]; then
                start_all
            else
                start_service "$service"
            fi
            ;;
        stop)
            if [ -z "$service" ]; then
                print_error "Please specify a service name or 'all'"
                show_usage
                exit 1
            fi
            
            if [ "$service" = "all" ]; then
                stop_all
            else
                stop_service "$service"
            fi
            ;;
        restart)
            if [ -z "$service" ]; then
                print_error "Please specify a service name or 'all'"
                show_usage
                exit 1
            fi
            
            if [ "$service" = "all" ]; then
                restart_all
            else
                restart_service "$service"
            fi
            ;;
        logs)
            if [ -z "$service" ]; then
                print_error "Please specify a service name"
                show_usage
                exit 1
            fi
            
            log_service "$service" "$option"
            ;;
        enable)
            if [ -z "$service" ]; then
                print_error "Please specify a service name or 'all'"
                show_usage
                exit 1
            fi
            
            if [ "$service" = "all" ]; then
                enable_all
            else
                enable_service "$service"
            fi
            ;;
        disable)
            if [ -z "$service" ]; then
                print_error "Please specify a service name or 'all'"
                show_usage
                exit 1
            fi
            
            if [ "$service" = "all" ]; then
                disable_all
            else
                disable_service "$service"
            fi
            ;;
        list)
            list_services
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"

