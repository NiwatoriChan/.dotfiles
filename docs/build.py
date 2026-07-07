#!/usr/bin/env python3
import os
import re

def main():
    docs_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(docs_dir, "index.html")

    # 1. Read all .md files in the docs directory
    docs_database = {}
    for filename in sorted(os.listdir(docs_dir)):
        if filename.endswith(".md"):
            page_name = os.path.splitext(filename)[0]
            file_path = os.path.join(docs_dir, filename)
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            # Escape backslashes, backticks, and ES6 interpolation markers
            escaped = content.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")
            docs_database[page_name] = escaped

    # 2. Read the current docs/index.html
    with open(html_path, "r", encoding="utf-8") as f:
        html_content = f.read()

    # 3. Construct the new docsDatabase block content
    database_entries = []
    for key, val in docs_database.items():
        database_entries.append(f'      "{key}": `{val}`,')
    
    new_database_content = "\n" + "\n".join(database_entries) + "\n"
    
    # 5. Locate the exact database block using a robust pattern
    # We match from 'const docsDatabase = {' to the closing '};' right before 'let currentMode'
    pattern = r'(const docsDatabase\s*=\s*\{)([\s\S]*?)(\n    \};\n\n\s*let currentMode)'
    match = re.search(pattern, html_content)
    if not match:
        print("Error: Could not locate 'const docsDatabase = { ... };' block inside index.html")
        return

    # Use slice-based replacement to avoid re.sub backslash expansion errors
    start_idx = match.start(2)
    end_idx = match.end(2)
    html_content_new = html_content[:start_idx] + new_database_content + html_content[end_idx:]

    # 6. Save the updated index.html
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content_new)

    print(f"Successfully generated docs/index.html database from {len(docs_database)} markdown files:")
    for page in docs_database.keys():
        print(f"  - {page}.md -> docsDatabase['{page}']")

if __name__ == "__main__":
    main()
