#!/bin/bash

# Docker Servers Quick Start Script
# Usage: ./start.sh [profile] [proxy]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if docker-compose is available
check_docker() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed or not in PATH"
        exit 1
    fi
}

# Function to check required files
check_required_files() {
    local missing_files=()

    if [[ "$1" == *"automation"* ]] || [[ "$1" == *"all"* ]]; then
        if [[ ! -f "./n8n/.env" ]]; then
            missing_files+=("./n8n/.env")
        fi
    fi

    if [[ "$1" == *"finance"* ]] || [[ "$1" == *"all"* ]]; then
        if [[ ! -f "./firefly/.env" ]]; then
            missing_files+=("./firefly/.env")
        fi
        if [[ ! -f "./firefly/.db.env" ]]; then
            missing_files+=("./firefly/.db.env")
        fi
    fi

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required configuration files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        echo "Please create these files before continuing."
        echo "See README.md for configuration examples."
        exit 1
    fi
}

# Function to validate proxy choice
validate_proxy() {
    local valid_proxies=("caddy" "nginx" "manager" "traefik")

    if [[ ! " ${valid_proxies[@]} " =~ " ${1} " ]] && [[ "$1" != "" ]]; then
        print_error "Invalid proxy: $1"
        echo "Valid options: ${valid_proxies[*]}"
        exit 1
    fi
}

# Function to start services
start_services() {
    local profile="$1"
    local proxy="$2"
    local compose_cmd="docker-compose"

    # Build base command
    if [[ "$profile" != "all" ]]; then
        compose_cmd="$compose_cmd --profile $profile"
    fi

    # Add proxy if specified
    if [[ "$proxy" != "" ]]; then
        validate_proxy "$proxy"
        case "$proxy" in
            "caddy")
                compose_cmd="$compose_cmd --profile caddy"
                ;;
            "nginx")
                compose_cmd="$compose_cmd --profile nginx"
                ;;
            "manager")
                compose_cmd="$compose_cmd --profile manager"
                ;;
            "traefik")
                compose_cmd="$compose_cmd --profile traefik"
                ;;
            "caddy-direct"|"nginx-direct"|"manager-direct"|"traefik-direct")
                compose_cmd="$compose_cmd --profile $proxy"
                ;;
            *)
                compose_cmd="$compose_cmd --profile $proxy"
                ;;
        esac
    fi

    # Add up -d command
    compose_cmd="$compose_cmd up -d"

    print_status "Starting services with command:"
    echo -e "${BLUE}$compose_cmd${NC}"
    echo ""

    # Execute command
    eval "$compose_cmd"

    if [[ $? -eq 0 ]]; then
        print_status "Services started successfully!"
        echo ""
        echo "Access URLs:"
        show_urls "$profile" "$proxy"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Function to show service URLs
show_urls() {
    local profile="$1"
    local proxy="$2"

    echo -e "${GREEN}=== Service URLs ===${NC}"

    # Database URLs
    if [[ "$profile" == *"databases"* ]] || [[ "$profile" == *"all"* ]]; then
        echo "PostgreSQL (pgAdmin): http://localhost:5011"
        echo "MySQL: localhost:33069"
        echo "MySQL 8: localhost:33068"
        echo "PostgreSQL: localhost:54320"
        echo "PostgreSQL + pgvector: localhost:54321"
    fi

    # Development URLs
    if [[ "$profile" == *"development"* ]] || [[ "$profile" == *"all"* ]]; then
        echo "Node.js: http://localhost:3000"
        echo "Image Registry: http://localhost:5200"
    fi

    # AI URLs
    if [[ "$profile" == *"ai"* ]] || [[ "$profile" == *"all"* ]]; then
        echo "Ollama: http://localhost:11434"
        echo "Open WebUI: http://localhost:8090"
    fi

    # Automation URLs
    if [[ "$profile" == *"automation"* ]] || [[ "$profile" == *"all"* ]]; then
        echo "n8n: http://localhost:5678"
        echo "RabbitMQ Management: http://localhost:15672"
        echo "Redis: localhost:6379"
    fi

    # Finance URLs
    if [[ "$profile" == *"finance"* ]] || [[ "$profile" == *"all"* ]]; then
        echo "Firefly III: http://localhost:8081"
    fi

    # Proxy URLs
    case "$proxy" in
        "caddy")
            echo "Caddy Proxy: http://localhost:80, https://localhost:443"
            ;;
        "nginx")
            echo "Nginx Proxy: http://localhost:8080, https://localhost:8443"
            ;;
        "manager")
            echo "Proxy Manager: http://localhost:8081"
            echo "Proxy Manager Dashboard: http://localhost:8082"
            ;;
        "traefik")
            echo "Traefik Proxy: http://localhost:8085, https://localhost:8445"
            echo "Traefik Dashboard: http://localhost:8086"
            ;;
    esac

    echo ""
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    docker-compose down
    if [[ $? -eq 0 ]]; then
        print_status "All services stopped successfully!"
    else
        print_error "Failed to stop services"
    fi
}

# Function to show logs
show_logs() {
    local service="$1"
    if [[ "$service" == "" ]]; then
        docker-compose logs
    else
        docker-compose logs "$service"
    fi
}

# Function to show help
show_help() {
    echo -e "${GREEN}Docker Servers Quick Start Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start [profile] [proxy]  Start services"
    echo "  stop                     Stop all services"
    echo "  restart [profile] [proxy] Restart services"
    echo "  logs [service]            Show logs"
    echo "  ps                        Show running services"
    echo "  proxy-manager [proxy]    Start port manager + proxy"
    echo "  help                     Show this help"
    echo ""
    echo "Profiles:"
    echo "  databases     Database services only"
    echo "  development   Development tools"
    echo "  ai           AI/ML services"
    echo "  automation   Automation tools"
    echo "  finance      Finance management"
    echo "  all          Start all services"
    echo ""
    echo "Port Management:"
    echo "  proxy-manager              Start intelligent port management system"
    echo ""
    echo "Proxies (with port-manager for auto 80/443 access):"
    echo "  caddy            caddy      Simple proxy (recommended)"
    echo "  caddy-direct      caddy-direct     Direct access to Caddy"
    echo "  nginx             nginx      Advanced reverse proxy"
    echo "  nginx-direct      nginx-direct     Direct access to Nginx"
    echo "  manager           manager      GUI-based proxy management"
    echo "  manager-direct      manager-direct  Direct access to Manager"
    echo "  traefik           traefik      Kubernetes-style proxy"
    echo "  traefik-direct      traefik-direct  Direct access to Traefik"
    echo ""
    echo "Examples:"
    echo "  $0 start databases                          # Start databases only"
    echo "  $0 start ai caddy                           # Start AI services with Caddy"
    echo "  $0 start all nginx                        # Start everything with Nginx proxy"
    echo "  $0 proxy-manager caddy                    # Auto port management + Caddy"
    echo "  $0 stop                                   # Stop all services"
    echo "  $0 logs n8n                              # Show n8n logs"
    echo ""
    echo "Configuration files in README.md must exist before starting."
    echo ""
    echo "Port Management Details:"
    echo "- When proxy-manager runs, it automatically assigns ports 80/443 to the first proxy"
    echo "- Direct-access proxies (-direct) can use 80/443 when proxy-manager is active"
    echo "- Alternative ports are used when proxy-manager is NOT active"
}

# Main script logic
main() {
    check_docker

    case "${1:-help}" in
        "start")
            if [[ -z "${2:-}" ]]; then
                print_error "Please specify a profile"
                show_help
                exit 1
            fi

            check_required_files "$2"
            start_services "$2" "${3:-}"
            ;;
        "proxy-manager")
            if [[ -z "${2:-}" ]]; then
                print_error "Please specify a proxy for port manager"
                show_help
                exit 1
            fi

            print_status "Starting port manager..."
            docker compose -f /docker-compose.yml --profile port-manager up -d
            sleep 5
            print_status "Port manager started. It will manage port 80/443 automatically."
            echo ""
            echo "Active proxy detection and management is now running."
            echo "Use Ctrl+C to stop the port manager."
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            if [[ -z "${2:-}" ]]; then
                print_error "Please specify a profile"
                show_help
                exit 1
            fi

            check_required_files "$2"
            stop_services
            sleep 2
            start_services "$2" "${3:-}"
            ;;
        "ps")
            docker-compose ps
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"