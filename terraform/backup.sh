#!/bin/bash

# Create backup directory with timestamp
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup Terraform state files
echo "Backing up Terraform state files..."
find . -name "*.tfstate" -o -name "*.tfstate.backup" | while read -r file; do
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/"
        echo "Backed up: $file"
    fi
done

# Backup Terraform configuration files
echo "Backing up Terraform configuration files..."
find . -name "*.tf" | while read -r file; do
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/"
        echo "Backed up: $file"
    fi
done

# Create a backup manifest
echo "Creating backup manifest..."
echo "Backup created at: $(date)" > "$BACKUP_DIR/manifest.txt"
echo "Backed up files:" >> "$BACKUP_DIR/manifest.txt"
find "$BACKUP_DIR" -type f -not -name "manifest.txt" >> "$BACKUP_DIR/manifest.txt"

echo "Backup completed successfully in directory: $BACKUP_DIR" 