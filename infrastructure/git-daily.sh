#!/bin/bash
echo "This script will pull the changes from main branch and create a new branch for your work"

read -p "Continue? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then

    echo "Proceeding..."
    read -p "please provide new branch name: " branch
    if [ -n "$branch" ]; then
        cd ~/aws-lab
        echo "Switching to main"
        git checkout main &&
        echo "Pulling latest"
        git pull &&
        echo "Creating new branch..."
        git checkout -b "$branch"
        if [ $? -eq 0 ]; then
            echo "Branch created successfully"

        else
            echo "Failed to create branch"
        fi
    else
        echo "Branch is not created because branch name is empty"

    fi


else

    echo "Cancelled."

    exit 1

fi