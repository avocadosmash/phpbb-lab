#!/bin/bash

# GitHub Issues Creator Script with API Support
# This script creates GitHub issues from processed_issues.json using GitHub API via gh cli
# Supports issue types, custom fields, and comprehensive error handling
#
# USAGE EXAMPLES:
#   ./setup/create_github_issues_api.sh                    # Create all issues with defaults
#   ./setup/create_github_issues_api.sh --dry-run          # Preview what would be created
#   ./setup/create_github_issues_api.sh --no-issue-types   # Disable issue types for compatibility
#   ./setup/create_github_issues_api.sh --repo owner/repo  # Specify custom repository
#   ./setup/create_github_issues_api.sh --batch-size 5     # Process in smaller batches
#   ./setup/create_github_issues_api.sh --file my_issues.json --sleep 5  # Custom file and delay
#
# REQUIREMENTS:
#   - GitHub CLI (gh) must be installed and authenticated
#   - jq must be installed for JSON processing
#   - Must be run from a git repository (unless --repo is specified)
#
# ISSUE TYPE SUPPORT:
#   The script uses GitHub's issue types feature when available. If your repository
#   doesn't have issue types configured or you're not on a plan that supports them,
#   use the --no-issue-types flag to avoid API errors.

set -e  # Exit on any error

# Default values
DRY_RUN=false
BATCH_SIZE=100
DELAY=2
JSON_FILE="processed_issues.json"
REPO=""
USE_ISSUE_TYPES=true

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Create GitHub issues from processed_issues.json using GitHub API.

OPTIONS:
    -f, --file FILE         JSON file to read issues from (default: processed_issues.json)
    -r, --repo REPO         Repository in format owner/repo (auto-detected if in git repo)
    -d, --dry-run           Show what would be created without actually creating issues
    -b, --batch-size N      Number of issues to create before pausing (default: 10)
    -s, --sleep N           Seconds to sleep between issues (default: 2)
    --no-issue-types        Don't attempt to set issue types (for compatibility)
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Create all issues with defaults
    $0 --dry-run                               # Preview what would be created
    $0 --repo myorg/myrepo                     # Specify repository
    $0 --file my_issues.json --batch-size 5   # Use different file and batch size
    $0 --no-issue-types                       # Don't use issue types

REQUIREMENTS:
    - GitHub CLI (gh) must be installed and authenticated
    - jq must be installed for JSON processing
    - Must be run from a git repository (unless --repo is specified)

ISSUE TYPES:
    This script attempts to use GitHub's issue types feature. If your repository
    doesn't have issue types configured or you're not on a plan that supports them,
    use the --no-issue-types flag.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            JSON_FILE="$2"
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -b|--batch-size)
            BATCH_SIZE="$2"
            shift 2
            ;;
        -s|--sleep)
            DELAY="$2"
            shift 2
            ;;
        --no-issue-types)
            USE_ISSUE_TYPES=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v gh &> /dev/null; then
        missing_deps+=("GitHub CLI (gh)")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo
        echo "Please install the missing dependencies:"
        echo "  - GitHub CLI: https://cli.github.com/"
        echo "  - jq: https://stedolan.github.io/jq/"
        exit 1
    fi
}

# Check GitHub CLI authentication
check_gh_auth() {
    if ! gh auth status &> /dev/null; then
        echo "Error: You are not authenticated with GitHub CLI."
        echo "Please run: gh auth login"
        exit 1
    fi
}

# Determine repository
get_repository() {
    if [[ -n "$REPO" ]]; then
        echo "$REPO"
        return
    fi
    
    # First try to get repo info from the current directory or parent directory
    local repo_info=""
    
    # Check if we're in a git repository (current or parent directory)
    if [[ -d ".git" ]] || [[ -d "../.git" ]]; then
        # Try to get remote origin URL and parse it
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ -n "$remote_url" ]]; then
            # Extract owner/repo from GitHub URL
            if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
                local owner="${BASH_REMATCH[1]}"
                local name="${BASH_REMATCH[2]}"
                name="${name%.git}"  # Remove .git suffix if present
                repo_info="$owner/$name"
            fi
        fi
    fi
    
    # If git parsing failed, try gh CLI
    if [[ -z "$repo_info" ]]; then
        local owner=$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo "")
        local name=$(gh repo view --json name -q '.name' 2>/dev/null || echo "")
        
        if [[ -n "$owner" && -n "$name" ]]; then
            repo_info="$owner/$name"
        fi
    fi
    
    if [[ -z "$repo_info" ]]; then
        echo "Error: Could not determine repository information."
        echo "Please specify repository with --repo owner/repo or run from within a git repository."
        exit 1
    fi
    
    echo "$repo_info"
}

# Validate JSON file
validate_json_file() {
    # If JSON_FILE is relative, check both current directory and setup directory
    if [[ ! -f "$JSON_FILE" ]]; then
        if [[ -f "setup/$JSON_FILE" ]]; then
            JSON_FILE="setup/$JSON_FILE"
        elif [[ -f "../$JSON_FILE" ]] && [[ $(basename "$(pwd)") == "setup" ]]; then
            JSON_FILE="../$JSON_FILE"
        elif [[ -f "./$JSON_FILE" ]]; then
            JSON_FILE="./$JSON_FILE"
        else
            echo "Error: JSON file '$JSON_FILE' not found."
            echo "Searched in:"
            echo "  - $(pwd)/$JSON_FILE"
            echo "  - $(pwd)/setup/$JSON_FILE"
            if [[ $(basename "$(pwd)") == "setup" ]]; then
                echo "  - $(pwd)/../$JSON_FILE"
            fi
            exit 1
        fi
    fi
    
    if ! jq empty "$JSON_FILE" &> /dev/null; then
        echo "Error: '$JSON_FILE' is not valid JSON."
        exit 1
    fi
    
    local issue_count=$(jq '. | length' "$JSON_FILE")
    if [[ "$issue_count" -eq 0 ]]; then
        echo "Error: No issues found in '$JSON_FILE'."
        exit 1
    fi
    
    echo "Found $issue_count issues in '$JSON_FILE'"
}

# Escape JSON strings properly
escape_json_string() {
    echo "$1" | jq -R -s '.'
}

# Create a single issue using GitHub API
create_issue() {
    local issue="$1"
    local repo="$2"
    local issue_num="$3"
    local total="$4"
    
    # Extract issue data
    local title=$(echo "$issue" | jq -r '.title')
    local body_content=$(echo "$issue" | jq -r '.body')
    local type=$(echo "$issue" | jq -r '.type // "Bug"')
    local jira_key=$(echo "$issue" | jq -r '.jira_key // ""')
    local affects_versions=$(echo "$issue" | jq -r '.affects_versions[]? // empty' | tr '\n' ', ' | sed 's/,$//')
    
    # Build the issue body with additional metadata
    local issue_body="$body_content"
    
    # Add JIRA key and affects versions if they exist
    if [[ -n "$jira_key" ]]; then
        issue_body="$issue_body

**JIRA Key:** $jira_key"
    fi
    
    if [[ -n "$affects_versions" ]]; then
        issue_body="$issue_body

**Affects Versions:** $affects_versions"
    fi
    
    echo "[$issue_num/$total] Processing: $title"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would create issue with:"
        echo "    Title: $title"
        echo "    Type: $type"
        echo "    JIRA Key: ${jira_key:-"None"}"
        echo "    Affects Versions: ${affects_versions:-"None"}"
        echo "    Body length: ${#issue_body} characters"
        echo "    Use issue types: $USE_ISSUE_TYPES"
        return 0
    fi
    
    # Prepare the JSON payload for the API
    local issue_json
    if [[ "$USE_ISSUE_TYPES" == "true" ]]; then
        # Include issue type in the payload
        issue_json=$(jq -n \
            --arg title "$title" \
            --arg body "$issue_body" \
            --arg type "$type" \
            '{
                title: $title,
                body: $body,
                labels: [$type],
                issue_type: $type
            }')
    else
        # Basic payload without issue type
        issue_json=$(jq -n \
            --arg title "$title" \
            --arg body "$issue_body" \
            --arg type "$type" \
            '{
                title: $title,
                body: $body,
                labels: [$type]
            }')
    fi
    
    # Create the GitHub issue using API
    local response
    if response=$(gh api \
        -X POST \
        "/repos/$repo/issues" \
        --input - <<< "$issue_json" 2>&1); then
        
        local issue_url=$(echo "$response" | jq -r '.html_url // "unknown"')
        local issue_number=$(echo "$response" | jq -r '.number // "unknown"')
        echo "  ✓ Successfully created issue #$issue_number"
        echo "    URL: $issue_url"
        return 0
    else
        echo "  ✗ Failed to create issue"
        echo "    Error: $response"
        
        # If issue type caused the error and we're using issue types, suggest retry
        if [[ "$USE_ISSUE_TYPES" == "true" && "$response" =~ "issue_type" ]]; then
            echo "    Hint: Try using --no-issue-types flag if your repository doesn't support issue types"
        fi
        return 1
    fi
}

# Main execution
main() {
    echo "GitHub Issues Creator (API Version)"
    echo "==================================="
    echo
    
    # Check all dependencies and requirements
    check_dependencies
    check_gh_auth
    
    # Get repository info
    local repository=$(get_repository)
    echo "Target repository: $repository"
    
    # Validate JSON file
    validate_json_file
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "🔍 DRY RUN MODE - No issues will be created"
        echo
    fi
    
    if [[ "$USE_ISSUE_TYPES" == "true" ]]; then
        echo "ℹ️  Issue types will be set (use --no-issue-types to disable)"
    else
        echo "ℹ️  Issue types will NOT be set"
    fi
    echo
    
    # Process issues
    local created_count=0
    local failed_count=0
    local total_issues=$(jq '. | length' "$JSON_FILE")
    local current_batch=0
    
    echo "Processing $total_issues issues..."
    echo
    
    local issue_num=1
    
    # Loop through each issue by index
    for ((i=0; i<total_issues; i++)); do
        local issue=$(jq -c ".[$i]" "$JSON_FILE")
        
        if create_issue "$issue" "$repository" "$issue_num" "$total_issues"; then
            created_count=$((created_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
        
        current_batch=$((current_batch + 1))
        issue_num=$((issue_num + 1))
        
        # Batch processing pause
        if [[ "$current_batch" -eq "$BATCH_SIZE" && "$issue_num" -le "$total_issues" ]]; then
            echo
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "Completed batch of $BATCH_SIZE issues (dry run mode - continuing automatically)..."
            else
                echo "Completed batch of $BATCH_SIZE issues. Pausing for rate limiting..."
                echo "Press Enter to continue or Ctrl+C to stop"
                # Use /dev/tty to read user input separately from the main loop input
                read -r </dev/tty
            fi
            current_batch=0
            echo
        elif [[ "$DRY_RUN" == "false" ]]; then
            # Small delay between individual issues
            sleep "$DELAY"
        fi
        
        echo
    done
    
    echo "==============================================="
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN COMPLETED"
        echo "Would have processed $total_issues issues"
    else
        echo "ISSUE CREATION COMPLETED"
        echo "Successfully created: $created_count issues"
        echo "Failed to create: $failed_count issues"
        echo "Total processed: $total_issues issues"
        
        if [[ $failed_count -gt 0 ]]; then
            echo
            echo "⚠️  Some issues failed to create. Please check the output above."
            exit 1
        fi
    fi
}

# Run main function
main "$@"