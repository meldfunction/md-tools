#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to get first line of file
get_first_line() {
    head -n 1 "$1" | sed 's/^#* *//'
}

# Function to scan for markdown files
scan_files() {
    local files=$(find . -maxdepth 1 -name "*.md" | sort -k 1 -t _)
    printf "\n%-40s %s\n" "FILENAME" "TITLE"
    printf "%.0s-" {1..80}
    printf "\n"
    for file in $files; do
        filename=$(basename "$file")
        title=$(get_first_line "$file")
        printf "%-40s %s\n" "$filename" "$title"
    done
}

# Function to generate manifest
generate_manifest() {
    local files=$(find . -maxdepth 1 -name "*.md" | sed 's/\.\///' | sort -k 1 -t _)
    cat > manifest.yml << EOL
input:
$(for file in $files; do
    echo "  $file:"
    echo "    noYAML: true"
done)

output:
  name: complete.md
  doctoc:
    mode: github
    title: "Complete Guide"
    maxlevel: 3
EOL
    echo -e "${GREEN}Generated manifest.yml${NC}"
}

# Function to convert to HTML
convert_html() {
    pandoc complete.md \
        --from markdown \
        --to html \
        --standalone \
        --toc \
        --number-sections \
        --metadata title="Complete Guide" \
        --css=styles.css \
        -o complete.html

    # Create default CSS if it doesn't exist
    if [ ! -f styles.css ]; then
        cat > styles.css << 'EOL'
body {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
    font-family: -apple-system, system-ui, sans-serif;
    line-height: 1.6;
}
h1, h2, h3 { color: #2c3e50; }
code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
pre { background: #f5f5f5; padding: 1em; border-radius: 4px; overflow-x: auto; }
EOL
    fi
}

# Function to convert to PDF
convert_pdf() {
    convert_html && \
    wkhtmltopdf \
        --page-size Letter \
        --margin-top 25mm \
        --margin-bottom 25mm \
        --margin-left 25mm \
        --margin-right 25mm \
        --enable-local-file-access \
        --footer-center "[page]" \
        complete.html \
        complete.pdf
}

# Main menu
while true; do
    clear
    echo -e "${BLUE}Markdown File Manager${NC}"
    echo "1. List markdown files"
    echo "2. Generate manifest"
    echo "3. Merge files"
    echo "4. Convert to HTML"
    echo "5. Convert to PDF"
    echo "6. Exit"
    
    read -p "Select option (1-6): " choice
    
    case $choice in
        1)
            echo -e "\nMarkdown files in current directory:"
            scan_files
            read -p "Press Enter to continue..."
            ;;
        2)
            generate_manifest
            read -p "Press Enter to continue..."
            ;;
        3)
            merge-markdown -m manifest.yml
            echo -e "${GREEN}Files merged into complete.md${NC}"
            read -p "Press Enter to continue..."
            ;;
        4)
            convert_html
            echo -e "${GREEN}HTML generated as complete.html${NC}"
            read -p "Press Enter to continue..."
            ;;
        5)
            convert_pdf
            echo -e "${GREEN}PDF generated as complete.pdf${NC}"
            read -p "Press Enter to continue..."
            ;;
        6)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
