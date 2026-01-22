#!/usr/bin/env python3
"""Script to remove all remaining Lombok imports from Java files"""

import os
import re

def remove_lombok_imports(file_path):
    """Remove Lombok import statements from a Java file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove Lombok imports
    content = re.sub(r'import lombok\.\w+;[\r\n]*', '', content)
    content = re.sub(r'import lombok\.extern\.slf4j\.\*;[\r\n]*', '', content)
    content = re.sub(r'import lombok\.\*;[\r\n]*', '', content)
    
    # Remove @Slf4j annotation and replace with regular logger
    if '@Slf4j' in content and 'import org.slf4j.Logger' not in content:
        content = content.replace('@Slf4j\n', '')
        content = content.replace('@Slf4j', '')
        # Find the class definition and add logger
        class_match = re.search(r'(public\s+(?:class|abstract class|interface)\s+\w+)', content)
        if class_match:
            # Add logger import if not present
            if 'import org.slf4j.Logger;' not in content:
                insert_pos = content.rfind('\n\n', 0, class_match.start())
                if insert_pos > 0:
                    logger_imports = 'import org.slf4j.Logger;\nimport org.slf4j.LoggerFactory;\n\n'
                    content = content[:insert_pos] + '\n' + logger_imports + content[insert_pos+2:]
            
            # Add logger field
            logger_decl = f'    private static final Logger log = LoggerFactory.getLogger({get_class_name(content)}.class);\n\n'
            insert_pos = content.find('{', class_match.start()) + 1
            content = content[:insert_pos] + '\n' + logger_decl + content[insert_pos:]
    
    # Remove @RequiredArgsConstructor
    content = content.replace('@RequiredArgsConstructor\n', '')
    content = content.replace('@RequiredArgsConstructor', '')
    
    # Remove @Data  
    content = content.replace('@Data\n', '')
    content = content.replace('@Data', '')
    
    # Remove @Builder annotations  
    content = content.replace('@Builder\n', '')
    content = content.replace('@Builder.Default\n', '')
    content = content.replace('@Builder', '')
    
    # Remove @Getter, @Setter, @NoArgsConstructor, @AllArgsConstructor
    content = content.replace('@Getter\n', '')
    content = content.replace('@Setter\n', '')
    content = content.replace('@NoArgsConstructor\n', '')
    content = content.replace('@AllArgsConstructor\n', '')
    content = content.replace('@Getter', '')
    content = content.replace('@Setter', '')
    content = content.replace('@NoArgsConstructor', '')
    content = content.replace('@AllArgsConstructor', '')
    
    # Fix double newlines
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Processed: {file_path}")

def get_class_name(content):
    """Extract class name from Java content"""
    match = re.search(r'class\s+(\w+)', content)
    if match:
        return match.group(1)
    return 'ApplicationClass'

# Get all Java files
java_files = []
base_dir = r'c:\Users\MIHIR\Downloads\IntelCrypt\backend\src'
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.java'):
            java_files.append(os.path.join(root, file))

# Process each file
for file_path in java_files:
    try:
        remove_lombok_imports(file_path)
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print(f"\nProcessed {len(java_files)} Java files")
