#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -l, --list              List available backups"
    echo "  -r, --restore BACKUP    Restore from specified backup"
    echo "  -h, --help              Show this help message"
    exit 1
}

# Function to list available backups
list_backups() {
    if [ ! -d "backups" ]; then
        echo "No backups found."
        exit 0
    fi
    
    echo "Available backups:"
    ls -1 backups/ | while read -r backup; do
        echo "  $backup"
        echo "    Created: $(cat backups/$backup/manifest.txt | head -n 1)"
    done
}

# Function to restore from backup
restore_backup() {
    local backup_dir="backups/$1"
    
    if [ ! -d "$backup_dir" ]; then
        echo "Error: Backup '$1' not found."
        exit 1
    fi
    
    echo "Restoring from backup: $1"
    
    # Restore Terraform state files
    echo "Restoring Terraform state files..."
    find "$backup_dir" -name "*.tfstate" -o -name "*.tfstate.backup" | while read -r file; do
        if [ -f "$file" ]; then
            cp "$file" .
            echo "Restored: $file"
        fi
    done
    
    # Restore Terraform configuration files
    echo "Restoring Terraform configuration files..."
    find "$backup_dir" -name "*.tf" | while read -r file; do
        if [ -f "$file" ]; then
            cp "$file" .
            echo "Restored: $file"
        fi
    done
    
    echo "Restore completed successfully."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            list_backups
            exit 0
            ;;
        -r|--restore)
            if [ -z "$2" ]; then
                echo "Error: No backup specified for restore."
                usage
            fi
            restore_backup "$2"
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# If no arguments provided, show usage
usage 