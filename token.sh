#!/bin/bash
# GitHub token 管理脚本 - 使用方式: source ./token.sh
# 设置后所有 git/curl 操作自动使用 token

TOKEN_FILE="/tmp/.github_token"
CREDS_FILE="/tmp/.github_creds"

store_token() {
    local token="$1"
    # 写 token 到文件（权限 600）
    echo -n "$token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    
    # 配置 git credential store
    cat > "$CREDS_FILE" << EOF
protocol=https
host=github.com
username=ZHworld
password=$token
EOF
    chmod 600 "$CREDS_FILE"
    
    # 设置 git credential helper
    git config --global credential.helper "store --file $CREDS_FILE" 2>/dev/null
    
    # 设置 token 供后续 curl 使用
    export GITHUB_TOKEN="$token"
    
    echo "✅ Token 已安全存储"
    echo "   - 文件: $TOKEN_FILE"
    echo "   - 状态: 仅本用户可读 (600)"
}

# 从文件读取 token
get_token() {
    if [ -f "$TOKEN_FILE" ]; then
        cat "$TOKEN_FILE"
    else
        echo ""
    fi
}

# 触发 GitHub Actions 编译
trigger_build() {
    local token
    token=$(get_token)
    if [ -z "$token" ]; then
        echo "❌ Token 未设置，先运行: source token.sh && store_token '你的token'"
        return 1
    fi
    
    echo "🚀 触发 GitHub Actions 编译..."
    curl -s -X POST \
        "https://api.github.com/repos/ZHworld/openwrt-r68s/actions/workflows/build-r68s.yml/dispatches" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        -d '{"ref":"main","inputs":{"kernel_version":"6.12.y","openwrt_ip":"192.168.20.1"}}'
    echo ""
    echo "✅ 编译已触发！查看进度: https://github.com/ZHworld/openwrt-r68s/actions"
}

# 检查编译状态
check_build() {
    local token
    token=$(get_token)
    curl -s "https://api.github.com/repos/ZHworld/openwrt-r68s/actions/runs?per_page=5" \
        -H "Authorization: Bearer $token" | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
for run in data.get('workflow_runs', []):
    status = run.get('status', '?')
    conc = run.get('conclusion', '?')
    created = run.get('created_at', '?')[:16]
    print(f'  #{run[\"run_number\"]} [{status:>10}/{conc:>10}] {created}')
"
}

case "${1:-}" in
    store)   store_token "$2" ;;
    trigger) trigger_build ;;
    status)  check_build ;;
    *)       echo "用法: source token.sh && store_token '你的token'" ;;
esac
