#!/usr/bin/env python3
"""
Fetch Laravel documentation from GitHub for multiple versions.

Usage:
    # Fetch a single version
    python fetch_laravel_docs.py --version 12.x --output ../references
    
    # Fetch multiple versions
    python fetch_laravel_docs.py --versions 10.x,11.x,12.x --output ../references
    
    # Fetch all supported versions
    python fetch_laravel_docs.py --all-versions --output ../references
    
    # Set current version
    python fetch_laravel_docs.py --set-current 12.x
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

# Supported Laravel versions
SUPPORTED_VERSIONS = ["10.x", "11.x", "12.x"]
DEFAULT_VERSION = "12.x"
GITHUB_REPO = "laravel/docs"


def fetch_github_contents(path: str, branch: str = "12.x") -> list:
    """Fetch contents of a directory from GitHub API."""
    url = f"https://api.github.com/repos/{GITHUB_REPO}/contents/{path}?ref={branch}"
    headers = {"Accept": "application/vnd.github.v3+json"}

    try:
        req = Request(url, headers=headers)
        with urlopen(req) as response:
            return json.loads(response.read().decode())
    except (URLError, HTTPError) as e:
        print(f"Error fetching {url}: {e}")
        return []


def fetch_file_content(download_url: str) -> str:
    """Fetch raw file content from GitHub."""
    try:
        req = Request(download_url, headers={"Accept": "application/vnd.github.raw"})
        with urlopen(req) as response:
            return response.read().decode()
    except (URLError, HTTPError) as e:
        print(f"Error fetching file: {e}")
        return ""


def clean_markdown(content: str) -> str:
    """Clean markdown content for skill usage."""
    # Remove frontmatter (--- ... ---)
    content = re.sub(r'^---\n.*?\n---\n', '', content, flags=re.DOTALL)
    
    # Remove unnecessary headers
    lines = []
    skip_next = False
    for line in content.split('\n'):
        # Skip title and introduction lines that duplicate the filename
        if skip_next:
            skip_next = False
            continue
        if line.strip() in ['# Introduction', '# Intro']:
            skip_next = True
            continue
        
        lines.append(line)
    
    return '\n'.join(lines)


def group_docs_by_topic(docs: list) -> dict:
    """Group documentation files by topic."""
    topics = {}
    
    # Topic mapping based on Laravel docs structure
    topic_map = {
        # Core topics
        'installation': 'installation',
        'configuration': 'configuration',
        'structure': 'structure',
        
        # Database
        'database': 'database',
        'eloquent': 'database',
        'migrations': 'database',
        'seeding': 'database',
        'queries': 'database',
        
        # Routing & Controllers
        'routing': 'routing',
        'controllers': 'routing',
        'middleware': 'routing',
        
        # Views & Frontend
        'blade': 'views',
        'views': 'views',
        'frontend': 'views',
        
        # Authentication & Authorization
        'authentication': 'auth',
        'authorization': 'auth',
        
        # Requests & Responses
        'requests': 'requests',
        'responses': 'requests',
        'validation': 'requests',
        
        # Testing
        'testing': 'testing',
        
        # Security
        'security': 'security',
        'csrf': 'security',
        
        # Queues & Jobs
        'queues': 'queues',
        'jobs': 'queues',
        
        # Caching
        'cache': 'cache',
        
        # Mail
        'mail': 'mail',
        
        # Notifications
        'notifications': 'notifications',
        
        # Storage
        'filesystems': 'storage',
        
        # Artisan CLI
        'artisan': 'artisan',
        
        # Additional topics
        'events': 'events',
        'logging': 'logging',
        'errors': 'errors',
        'packages': 'packages',
        'helpers': 'helpers',
        'contracts': 'contracts',
        'collections': 'collections',
        'hashing': 'security',
        'encryption': 'security',
        'http-client': 'requests',
        'session': 'sessions',
        'pagination': 'database',
        'broadcasting': 'events',
        'scheduling': 'queues',
    }
    
    for doc in docs:
        name = doc['name'].replace('.md', '')
        topic = topic_map.get(name, 'misc')
        
        if topic not in topics:
            topics[topic] = []
        topics[topic].append(doc)
    
    return topics


def fetch_and_save_docs(version: str, output_dir: str, base_output: str) -> None:
    """Fetch all Laravel docs for a version and save to version-specific directory."""
    # Create version-specific output directory
    version_dir = Path(output_dir) / f"v{version.replace('.x', '')}"
    version_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Fetching Laravel {version} documentation...")
    
    # Fetch the source directory
    source_docs = fetch_github_contents('', version)
    
    if not source_docs:
        print(f"No documentation found for version {version}.")
        return
    
    # Filter for .md files
    md_files = [f for f in source_docs if f['name'].endswith('.md')]
    
    if not md_files:
        print(f"No markdown files found for version {version}.")
        return
    
    # Group by topic
    topics = group_docs_by_topic(md_files)
    
    # Create topic files
    for topic_name, files in topics.items():
        if not files:
            continue
        
        topic_content = f"# {topic_name.title()}\n\n"
        
        for file_info in sorted(files, key=lambda x: x['name']):
            file_name = file_info['name']
            doc_name = file_name.replace('.md', '')
            
            print(f"  Fetching: {file_name}")
            content = fetch_file_content(file_info['download_url'])
            
            if content:
                cleaned = clean_markdown(content)
                topic_content += f"\n## {doc_name.title().replace('_', ' ')}\n\n"
                topic_content += cleaned + "\n\n"
        
        # Save topic file
        output_file = version_dir / f"{topic_name}.md"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(topic_content)
    
    print(f"  Version {version} saved to {version_dir}")
    print(f"  Topics: {', '.join(topics.keys())}")


def generate_version_index(output_dir: str) -> None:
    """Generate VERSIONS.md file listing all available versions."""
    versions_file = Path(output_dir) / "VERSIONS.md"
    
    content = "# Laravel Documentation Versions\n\n"
    content += "This directory contains Laravel documentation for multiple versions.\n\n"
    content += "## Available Versions\n\n"
    
    for version in SUPPORTED_VERSIONS:
        v_num = version.replace('.x', '')
        v_dir = Path(output_dir) / f"v{v_num}"
        
        if v_dir.exists():
            files = list(v_dir.glob("*.md"))
            content += f"- **{version}** - {len(files)} topic files available\n"
        else:
            content += f"- **{version}** - Not yet downloaded\n"
    
    content += "\n## Switching Versions\n\n"
    content += f"To switch between versions, use the version manager:\n\n"
    content += "```bash\n"
    content += "python scripts/version_manager.py --set-current 12.x\n"
    content += "```\n"
    
    with open(versions_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Generated VERSIONS.md")


def set_current_version(version: str, base_dir: str) -> bool:
    """Set the current version by creating a symbolic link."""
    if version not in SUPPORTED_VERSIONS:
        print(f"Error: Version {version} is not supported.")
        print(f"Supported versions: {', '.join(SUPPORTED_VERSIONS)}")
        return False
    
    v_num = version.replace('.x', '')
    source_dir = Path(base_dir) / f"v{v_num}"
    link_file = Path(base_dir) / "current"
    
    if not source_dir.exists():
        print(f"Error: Documentation for version {version} is not downloaded.")
        return False
    
    # Remove existing link if it exists
    if link_file.exists() or link_file.is_symlink():
        link_file.unlink()
    
    # Create symbolic link
    link_file.symlink_to(source_dir)
    
    # Update config/settings.json
    config_file = Path(base_dir).parent / "config" / "settings.json"
    if config_file.exists():
        with open(config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        config['current_version'] = version
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
    
    print(f"Current version set to {version}")
    return True


def fetch_all_versions(output_dir: str) -> None:
    """Fetch all supported Laravel versions."""
    base_output = output_dir
    
    for version in SUPPORTED_VERSIONS:
        fetch_and_save_docs(version, base_output, base_output)
    
    # Set default version as current
    set_current_version(DEFAULT_VERSION, base_output)
    
    # Generate version index
    generate_version_index(base_output)


def main():
    parser = argparse.ArgumentParser(
        description="Fetch Laravel documentation from GitHub for multiple versions."
    )
    
    # Version selection
    version_group = parser.add_mutually_exclusive_group()
    version_group.add_argument(
        '--version',
        help=f'Laravel version to fetch (default: {DEFAULT_VERSION})'
    )
    version_group.add_argument(
        '--versions',
        help='Comma-separated list of Laravel versions to fetch (e.g., 10.x,11.x,12.x)'
    )
    version_group.add_argument(
        '--all-versions',
        action='store_true',
        help='Fetch all supported versions'
    )
    
    # Output directory
    parser.add_argument(
        '--output',
        default='../references',
        help='Output directory for fetched docs (default: ../references)'
    )
    
    # Set current version
    parser.add_argument(
        '--set-current',
        help='Set the current version (creates symbolic link)'
    )
    
    args = parser.parse_args()
    
    # Handle set-current option
    if args.set_current:
        set_current_version(args.set_current, args.output)
        return
    
    # Handle version selection
    if args.all_versions:
        fetch_all_versions(args.output)
    elif args.versions:
        versions = [v.strip() for v in args.versions.split(',')]
        for version in versions:
            if version in SUPPORTED_VERSIONS:
                fetch_and_save_docs(version, args.output, args.output)
            else:
                print(f"Warning: Version {version} is not supported.")
        generate_version_index(args.output)
    else:
        version = args.version if args.version else DEFAULT_VERSION
        fetch_and_save_docs(version, args.output, args.output)
        generate_version_index(args.output)


if __name__ == '__main__':
    main()