#!/usr/bin/env python3
"""
Laravel Documentation Version Manager

Usage:
    # List available versions
    python version_manager.py --list
    
    # Show current version
    python version_manager.py --current
    
    # Set current version
    python version_manager.py --set-current 12.x
    
    # Compare versions
    python version_manager.py --compare 11.x 12.x
"""

import argparse
import json
import sys
from pathlib import Path


def load_config(config_path: str) -> dict:
    """Load skill configuration."""
    config_file = Path(config_path) / "config" / "settings.json"
    if config_file.exists():
        with open(config_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"current_version": "12.x", "supported_versions": ["10.x", "11.x", "12.x"]}


def save_config(config: dict, config_path: str) -> None:
    """Save skill configuration."""
    config_file = Path(config_path) / "config" / "settings.json"
    config_file.parent.mkdir(parents=True, exist_ok=True)
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)


def list_versions(base_dir: str, config: dict) -> None:
    """List all available versions."""
    print("Available Laravel Documentation Versions:")
    print("-" * 50)
    
    for version in config.get("supported_versions", []):
        v_num = version.replace('.x', '')
        v_dir = Path(base_dir) / "references" / f"v{v_num}"
        
        if v_dir.exists():
            files = list(v_dir.glob("*.md"))
            is_current = version == config.get("current_version", "")
            status = " [CURRENT]" if is_current else ""
            print(f"  {version}{status} - {len(files)} topic files")
        else:
            print(f"  {version} - Not downloaded")


def show_current(base_dir: str, config: dict) -> None:
    """Show current version."""
    current = config.get("current_version", "12.x")
    print(f"Current version: {current}")
    
    v_num = current.replace('.x', '')
    v_dir = Path(base_dir) / "references" / f"v{v_num}"
    
    if v_dir.exists():
        files = list(v_dir.glob("*.md"))
        print(f"Available topics: {len(files)}")
        print(f"Location: {v_dir}")
    else:
        print(f"Warning: Documentation for version {current} is not downloaded.")


def set_current_version(version: str, base_dir: str, config: dict) -> bool:
    """Set current version."""
    if version not in config.get("supported_versions", []):
        print(f"Error: Version {version} is not supported.")
        return False
    
    v_num = version.replace('.x', '')
    v_dir = Path(base_dir) / "references" / f"v{v_num}"
    
    if not v_dir.exists():
        print(f"Error: Documentation for version {version} is not downloaded.")
        print(f"Run: python scripts/fetch_laravel_docs.py --version {version}")
        return False
    
    # Update config
    config['current_version'] = version
    save_config(config, base_dir)
    
    # Update symbolic link
    link_file = Path(base_dir) / "references" / "current"
    if link_file.exists() or link_file.is_symlink():
        link_file.unlink()
    link_file.symlink_to(v_dir)
    
    print(f"Current version set to {version}")
    return True


def compare_versions(v1: str, v2: str, base_dir: str) -> None:
    """Compare two versions."""
    v1_num = v1.replace('.x', '')
    v2_num = v2.replace('.x', '')
    
    v1_dir = Path(base_dir) / "references" / f"v{v1_num}"
    v2_dir = Path(base_dir) / "references" / f"v{v2_num}"
    
    if not v1_dir.exists():
        print(f"Error: Documentation for version {v1} is not downloaded.")
        return
    
    if not v2_dir.exists():
        print(f"Error: Documentation for version {v2} is not downloaded.")
        return
    
    v1_files = set([f.stem for f in v1_dir.glob("*.md")])
    v2_files = set([f.stem for f in v2_dir.glob("*.md")])
    
    print(f"Comparing {v1} vs {v2}:")
    print("-" * 50)
    print(f"Topics in {v1}: {len(v1_files)}")
    print(f"Topics in {v2}: {len(v2_files)}")
    
    common = v1_files & v2_files
    only_v1 = v1_files - v2_files
    only_v2 = v2_files - v1_files
    
    print(f"\nCommon topics: {len(common)}")
    if only_v1:
        print(f"\nOnly in {v1}: {', '.join(sorted(only_v1))}")
    if only_v2:
        print(f"\nOnly in {v2}: {', '.join(sorted(only_v2))}")


def main():
    parser = argparse.ArgumentParser(
        description="Laravel Documentation Version Manager"
    )
    
    parser.add_argument(
        '--base-dir',
        default='..',
        help='Base directory of the skill (default: ..)'
    )
    
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available versions'
    )
    
    parser.add_argument(
        '--current',
        action='store_true',
        help='Show current version'
    )
    
    parser.add_argument(
        '--set-current',
        help='Set current version'
    )
    
    parser.add_argument(
        '--compare',
        nargs=2,
        metavar=('V1', 'V2'),
        help='Compare two versions'
    )
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.base_dir)
    
    # Execute command
    if args.list:
        list_versions(args.base_dir, config)
    elif args.current:
        show_current(args.base_dir, config)
    elif args.set_current:
        set_current_version(args.set_current, args.base_dir, config)
    elif args.compare:
        compare_versions(args.compare[0], args.compare[1], args.base_dir)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()