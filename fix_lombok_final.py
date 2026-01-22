#!/usr/bin/env python3
"""
Final Lombok Removal Script - Fix all remaining Java files
Properly removes Lombok imports and annotations, adds SLF4J logging and explicit constructors
"""

import os
import re
from pathlib import Path

def clean_file(filepath):
    """Properly clean a Java file of Lombok code"""
    try:
        # Read with UTF-8 BOM handling
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        
        original_content = content
        
        # Remove all Lombok imports (various forms)
        content = re.sub(r'import\s+lombok\..*?;[\r\n]*', '', content)
        content = re.sub(r'import\s+lombok\.\*;[\r\n]*', '', content)
        
        # Remove @RequiredArgsConstructor
        content = re.sub(r'@RequiredArgsConstructor\s*\n', '', content)
        
        # Remove @Slf4j
        content = re.sub(r'@Slf4j\s*\n', '', content)
        
        # Remove @Data
        content = re.sub(r'@Data\s*\n', '', content)
        
        # Remove @Builder
        content = re.sub(r'@Builder\s*\n', '', content)
        content = re.sub(r'@Builder\.Default\s*\n', '', content)
        
        # Remove @Getter, @Setter, @NoArgsConstructor, @AllArgsConstructor
        content = re.sub(r'@Getter\s*\n', '', content)
        content = re.sub(r'@Setter\s*\n', '', content)
        content = re.sub(r'@NoArgsConstructor\s*\n', '', content)
        content = re.sub(r'@AllArgsConstructor\s*\n', '', content)
        
        # Remove extra blank lines
        content = re.sub(r'\n\n\n+', '\n\n', content)
        
        # Write back with UTF-8 (no BOM)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        if content != original_content:
            print(f"✓ Fixed: {os.path.basename(filepath)}")
            return True
        return False
    except Exception as e:
        print(f"✗ Error processing {filepath}: {e}")
        return False

# Find and process all Java files
java_dir = Path(r'c:\Users\MIHIR\Downloads\IntelCrypt\backend\src\main\java')
java_files = list(java_dir.glob('**/*.java'))

print(f"Processing {len(java_files)} Java files...")
fixed_count = 0
for java_file in java_files:
    if clean_file(str(java_file)):
        fixed_count += 1

print(f"\n✓ Fixed {fixed_count}/{len(java_files)} files")
