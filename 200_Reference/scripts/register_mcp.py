#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# register_mcp.py - 自動定位 mcpvault 並將 Obsidian MCP 註冊到指定 AI Agent
#
# 三 Agent 契約:預設註冊到 Claude Code；可用 --agent 分流至 codex / antigravity。
#   用法:
#     python3 register_mcp.py <Obsidian_Vault_實體路徑>                 # 預設 claude
#     python3 register_mcp.py <Vault> --agent claude
#     python3 register_mcp.py <Vault> --agent antigravity
#     python3 register_mcp.py <Vault> --agent codex
#
# Claude 版採用官方 `claude mcp add` CLI(能安全保留既有 MCP server);
# 若 CLI 不可用則安全回退到編輯 ~/.claude.json 的 mcpServers(保留其他 key)。

import os
import sys
import json
import shutil
import subprocess


def locate_mcpvault():
    """使用 which 或常見路徑自動定位 mcpvault 絕對路徑。"""
    found = shutil.which("mcpvault")
    if found:
        return found
    fallback_paths = [
        "/opt/homebrew/bin/mcpvault",
        "/usr/local/bin/mcpvault",
        os.path.expanduser("~/.npm-global/bin/mcpvault"),
        "/usr/bin/mcpvault",
    ]
    for path in fallback_paths:
        if os.path.exists(path):
            return path
    return "mcpvault"


def normalize_vault(vault_path):
    vault_path = os.path.abspath(os.path.expanduser(vault_path))
    if not os.path.exists(vault_path):
        print("⚠️ 警告: 指定的 Obsidian Vault 路徑不存在。")
        print("將繼續寫入設定，但請確認該目錄稍後同步完成。")
    return vault_path


# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
def register_claude(vault_path, mcpvault_cmd):
    """優先使用 claude mcp add --scope user;失敗則安全編輯 ~/.claude.json。"""
    claude_cli = shutil.which("claude")
    if claude_cli:
        try:
            # 先移除舊的同名 server(忽略不存在的錯誤),再新增,確保冪等。
            subprocess.run([claude_cli, "mcp", "remove", "--scope", "user", "obsidian"],
                           capture_output=True, text=True)
            result = subprocess.run(
                [claude_cli, "mcp", "add", "--scope", "user", "obsidian", mcpvault_cmd, vault_path],
                capture_output=True, text=True,
            )
            if result.returncode == 0:
                print("✅ 成功透過 `claude mcp add` 註冊 Obsidian MCP(user scope)。")
                print("   - Agent：Claude Code")
                print("   - Vault 對接：{{OBSIDIAN_VAULT}}")
                return
            print(f"⚠️ claude mcp add 失敗，回退編輯 ~/.claude.json：{result.stderr.strip()}")
        except Exception as e:
            print(f"⚠️ 呼叫 claude CLI 失敗，回退編輯 ~/.claude.json：{e}")

    # 回退:安全編輯 ~/.claude.json(保留其他 key 與其他 MCP server)
    config_path = os.path.expanduser("~/.claude.json")
    config_data = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                config_data = json.load(f)
        except Exception as e:
            print(f"❌ 讀取 ~/.claude.json 失敗，為避免破壞既有設定而中止：{e}")
            sys.exit(1)
    config_data.setdefault("mcpServers", {})
    config_data["mcpServers"]["obsidian"] = {"command": mcpvault_cmd, "args": [vault_path]}
    _write_json(config_path, config_data)
    print("✅ 已將 Obsidian MCP 寫入 ~/.claude.json(保留其他 MCP server)。")


# ---------------------------------------------------------------------------
# AntiGravity / Gemini
# ---------------------------------------------------------------------------
def register_antigravity(vault_path, mcpvault_cmd):
    config_dir = os.environ.get("GEMINI_CONFIG") or os.path.expanduser("~/.gemini/config")
    config_dir = os.path.abspath(os.path.expanduser(config_dir))
    config_path = os.path.join(config_dir, "mcp_config.json")
    os.makedirs(config_dir, exist_ok=True)

    config_data = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                config_data = json.load(f)
        except Exception as e:
            print(f"⚠️ 讀取現有 mcp_config.json 失敗: {e}。將建立全新配置。")
    config_data.setdefault("mcpServers", {})
    config_data["mcpServers"]["obsidian"] = {"command": mcpvault_cmd, "args": [vault_path]}
    _write_json(config_path, config_data)
    print("✅ 成功註冊 Obsidian MCP。")
    print("   - MCP 設定檔：{{GEMINI_CONFIG}}/mcp_config.json")
    print("   - Vault 對接：{{OBSIDIAN_VAULT}}")


# ---------------------------------------------------------------------------
# Codex
# ---------------------------------------------------------------------------
def register_codex(vault_path, mcpvault_cmd):
    """Codex 使用 config.toml 的 [mcp_servers.obsidian]。以最小侵入方式提示。"""
    codex_home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
    config_path = os.path.join(codex_home, "config.toml")
    block = (
        "\n[mcp_servers.obsidian]\n"
        f'command = "{mcpvault_cmd}"\n'
        f'args = ["{vault_path}"]\n'
    )
    print("ℹ️ Codex 使用 config.toml 註冊 MCP。請將以下區塊加入(或確認已存在):")
    print(f"   檔案：{config_path}")
    print(block)
    print("   (為避免破壞既有 TOML 結構，本腳本不自動改寫 config.toml。)")


def _write_json(config_path, config_data):
    try:
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config_data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"❌ 寫入 {config_path} 失敗: {e}")
        sys.exit(1)


def main():
    args = [a for a in sys.argv[1:]]
    agent = "claude"
    if "--agent" in args:
        i = args.index("--agent")
        try:
            agent = args[i + 1].lower()
            del args[i:i + 2]
        except IndexError:
            print("❌ --agent 後需指定 claude / codex / antigravity。")
            sys.exit(1)
    if not args:
        print("用法: python3 register_mcp.py <Obsidian_Vault_實體路徑> [--agent claude|codex|antigravity]")
        sys.exit(1)

    vault_path = normalize_vault(args[0])
    mcpvault_cmd = locate_mcpvault()
    print(f"🔍 已定位 mcpvault：{mcpvault_cmd}")

    if agent == "claude":
        register_claude(vault_path, mcpvault_cmd)
    elif agent == "antigravity":
        register_antigravity(vault_path, mcpvault_cmd)
    elif agent == "codex":
        register_codex(vault_path, mcpvault_cmd)
    else:
        print(f"❌ 未知 agent：{agent}(可用:claude / codex / antigravity)")
        sys.exit(1)


if __name__ == "__main__":
    main()
