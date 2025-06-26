#!/bin/bash
# TDD-Driven MultiAgent Development System Setup
# Based on Claude Code Dev methodology

set -e

echo "🚀 TDD-Driven MultiAgent Development System Setup"
echo "================================================="
echo ""

# プロジェクト名の入力
read -p "📝 プロジェクト名を入力してください: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ プロジェクト名は必須です"
    exit 1
fi

# プロジェクトディレクトリ作成
PROJECT_DIR="./$PROJECT_NAME"
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  プロジェクトディレクトリが既に存在します: $PROJECT_DIR"
    read -p "上書きしますか？ (y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ]; then
        echo "❌ セットアップを中止しました"
        exit 1
    fi
    rm -rf "$PROJECT_DIR"
fi

echo ""
echo "📁 プロジェクト構造を作成中..."
mkdir -p "$PROJECT_DIR"/{shared,sync,output,.claude}
mkdir -p "$PROJECT_DIR"/shared/{specs,data,questions}
mkdir -p "$PROJECT_DIR"/sync/{daily,meeting}
mkdir -p "$PROJECT_DIR"/output/{backend,frontend,tests,docs}

# プロジェクト設定ファイル作成
cat > "$PROJECT_DIR/.claude/project-config.json" << EOF
{
    "project_name": "$PROJECT_NAME",
    "methodology": "TDD-Driven MultiAgent",
    "agents": [
        "test-lead",
        "backend-developer",
        "frontend-developer",
        "review-engineer",
        "integration-engineer"
    ],
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

# .gitignore作成
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
venv/
.env

# Build outputs
dist/
build/
*.pyc
__pycache__/

# IDE
.idea/
.vscode/
*.swp

# Test coverage
coverage/
.coverage
*.lcov

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
EOF

# Git初期化
cd "$PROJECT_DIR"
git init
git add .
git commit -m "🎉 Initial project setup for TDD-driven development"

# 技術スタック選択
echo ""
echo "🛠️  技術スタックを選択してください:"
echo ""
echo "フロントエンド:"
echo "  1) React + TypeScript"
echo "  2) Vue.js + TypeScript"
echo "  3) Next.js"
echo "  4) Angular"
echo "  5) Vanilla JavaScript"
read -p "選択 (1-5): " FRONTEND_CHOICE

case $FRONTEND_CHOICE in
    1) FRONTEND="React + TypeScript" ;;
    2) FRONTEND="Vue.js + TypeScript" ;;
    3) FRONTEND="Next.js" ;;
    4) FRONTEND="Angular" ;;
    5) FRONTEND="Vanilla JavaScript" ;;
    *) FRONTEND="React + TypeScript" ;;
esac

echo ""
echo "バックエンド:"
echo "  1) Node.js + Express"
echo "  2) Python + FastAPI"
echo "  3) Python + Django"
echo "  4) Go + Gin"
echo "  5) Java + Spring Boot"
read -p "選択 (1-5): " BACKEND_CHOICE

case $BACKEND_CHOICE in
    1) BACKEND="Node.js + Express" ;;
    2) BACKEND="Python + FastAPI" ;;
    3) BACKEND="Python + Django" ;;
    4) BACKEND="Go + Gin" ;;
    5) BACKEND="Java + Spring Boot" ;;
    *) BACKEND="Node.js + Express" ;;
esac

echo ""
echo "データベース:"
echo "  1) PostgreSQL"
echo "  2) MySQL"
echo "  3) MongoDB"
echo "  4) SQLite"
echo "  5) Redis"
read -p "選択 (1-5): " DATABASE_CHOICE

case $DATABASE_CHOICE in
    1) DATABASE="PostgreSQL" ;;
    2) DATABASE="MySQL" ;;
    3) DATABASE="MongoDB" ;;
    4) DATABASE="SQLite" ;;
    5) DATABASE="Redis" ;;
    *) DATABASE="PostgreSQL" ;;
esac

TECH_STACK="$FRONTEND,$BACKEND,$DATABASE"

# TDDエージェント設定作成
echo ""
echo "🤖 TDDエージェント設定を作成中..."

# 各エージェント用のブランチとワークツリー作成
AGENTS=("test-lead" "backend-developer" "frontend-developer" "review-engineer" "integration-engineer")

for AGENT in "${AGENTS[@]}"; do
    echo "  📍 $AGENT 用のブランチを作成..."
    git checkout -b "agent/$AGENT"
    
    # CLAUDE.md生成
    echo "  📝 $AGENT のCLAUDE.md生成..."
    python3 ../../scripts/generate-tdd-claude-config.py \
        --agent "$AGENT" \
        --project-name "$PROJECT_NAME" \
        --tech-stack "$TECH_STACK" \
        --output-dir "."
    
    git add CLAUDE.md
    git commit -m "feat: $AGENT エージェント設定を追加"
    git checkout main
done

# ワークツリー作成スクリプト
cat > setup-worktrees.sh << 'EOF'
#!/bin/bash
# エージェント用ワークツリーセットアップ

echo "🌳 エージェント用ワークツリーを作成中..."

AGENTS=("test-lead" "backend-developer" "frontend-developer" "review-engineer" "integration-engineer")

for AGENT in "${AGENTS[@]}"; do
    WORKTREE_PATH="../worktree-$AGENT"
    if [ -d "$WORKTREE_PATH" ]; then
        echo "  ⚠️  既存のワークツリーを削除: $WORKTREE_PATH"
        git worktree remove "$WORKTREE_PATH" --force
    fi
    
    echo "  🌿 $AGENT のワークツリーを作成..."
    git worktree add "$WORKTREE_PATH" "agent/$AGENT"
    
    # 作業ディレクトリ作成
    mkdir -p "$WORKTREE_PATH"/{work,sync}
    
    echo "  ✅ $AGENT のワークツリー準備完了: $WORKTREE_PATH"
done

echo ""
echo "✅ 全エージェントのワークツリー準備完了！"
echo ""
echo "📂 ワークツリー構造:"
echo "  ../worktree-test-lead/        - Test Lead Agent"
echo "  ../worktree-backend-developer/ - Backend Developer Agent"
echo "  ../worktree-frontend-developer/ - Frontend Developer Agent"
echo "  ../worktree-review-engineer/   - Review Engineer Agent"
echo "  ../worktree-integration-engineer/ - Integration Engineer Agent"
EOF

chmod +x setup-worktrees.sh

# TDDワークフロー管理スクリプト
cat > tdd-workflow.sh << 'EOF'
#!/bin/bash
# TDD Workflow Management Script

set -e

ACTION=$1

case $ACTION in
    "status")
        echo "📊 TDD Development Status"
        echo "========================"
        echo ""
        
        # 各エージェントの状態確認
        for AGENT in test-lead backend-developer frontend-developer review-engineer integration-engineer; do
            WORKTREE="../worktree-$AGENT"
            if [ -d "$WORKTREE/sync" ]; then
                echo "🤖 $AGENT:"
                if [ -f "$WORKTREE/sync/status.md" ]; then
                    tail -n 5 "$WORKTREE/sync/status.md" | sed 's/^/   /'
                else
                    echo "   No status reported"
                fi
                echo ""
            fi
        done
        ;;
        
    "sync")
        echo "🔄 Synchronizing agent data..."
        
        # 共有データの同期
        for AGENT in test-lead backend-developer frontend-developer review-engineer integration-engineer; do
            WORKTREE="../worktree-$AGENT"
            if [ -d "$WORKTREE" ]; then
                echo "  📋 Syncing $AGENT..."
                # テスト結果の共有
                if [ -d "$WORKTREE/output/tests" ]; then
                    cp -r "$WORKTREE/output/tests/"* shared/data/ 2>/dev/null || true
                fi
            fi
        done
        
        echo "✅ Synchronization complete"
        ;;
        
    "report")
        echo "📝 Generating TDD Progress Report"
        echo "================================="
        
        cat > sync/tdd-progress-report.md << REPORT_EOF
# TDD Progress Report
Generated: $(date +"%Y-%m-%d %H:%M:%S")

## Test Coverage
$(find output/tests -name "*.test.*" 2>/dev/null | wc -l) test files
$(find output/backend -name "*.py" -o -name "*.js" 2>/dev/null | wc -l) backend files
$(find output/frontend -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l) frontend files

## Agent Activity
$(for agent in test-lead backend-developer frontend-developer review-engineer integration-engineer; do
    worktree="../worktree-$agent"
    if [ -d "$worktree/.git" ]; then
        commits=$(cd "$worktree" && git log --oneline -n 5 2>/dev/null | wc -l)
        echo "- $agent: $commits recent commits"
    fi
done)

## Next Steps
- Review failing tests
- Implement missing features
- Run integration tests
REPORT_EOF

        echo "✅ Report generated: sync/tdd-progress-report.md"
        ;;
        
    *)
        echo "Usage: $0 {status|sync|report}"
        echo ""
        echo "Commands:"
        echo "  status  - Show current TDD development status"
        echo "  sync    - Synchronize data between agents"
        echo "  report  - Generate progress report"
        exit 1
        ;;
esac
EOF

chmod +x tdd-workflow.sh

# TDD開始スクリプト
cat > start-tdd-cycle.sh << 'EOF'
#!/bin/bash
# Start TDD Development Cycle

echo "🔴 Starting TDD RED Phase"
echo "========================"
echo ""
echo "Test Lead Agent will now create failing tests based on requirements."
echo ""
echo "📋 Instructions for Test Lead:"
echo "1. Navigate to: ../worktree-test-lead/"
echo "2. Review shared/specs/ for requirements"
echo "3. Create test specifications in work/"
echo "4. Generate failing tests in output/tests/"
echo "5. Update sync/status.md with test plan"
echo ""
echo "When tests are ready, other agents can begin GREEN phase."
echo ""
echo "💡 Use './tdd-workflow.sh status' to monitor progress"
EOF

chmod +x start-tdd-cycle.sh

# 初期コミット
git add .
git commit -m "feat: TDD workflow scripts and configuration"

# 完了メッセージ
echo ""
echo "✅ TDD-Driven MultiAgent Development System セットアップ完了！"
echo ""
echo "📋 プロジェクト情報:"
echo "  名前: $PROJECT_NAME"
echo "  フロントエンド: $FRONTEND"
echo "  バックエンド: $BACKEND"
echo "  データベース: $DATABASE"
echo ""
echo "🤖 設定されたエージェント:"
echo "  - Test Lead (TDDリーダー)"
echo "  - Backend Developer"
echo "  - Frontend Developer"
echo "  - Review Engineer"
echo "  - Integration Engineer"
echo ""
echo "🚀 次のステップ:"
echo "1. ワークツリーをセットアップ:"
echo "   ./setup-worktrees.sh"
echo ""
echo "2. TDD開発サイクルを開始:"
echo "   ./start-tdd-cycle.sh"
echo ""
echo "3. 進捗を確認:"
echo "   ./tdd-workflow.sh status"
echo ""
echo "💡 各エージェントは独立したワークツリーで並行作業します"
echo "📚 詳細は shared/specs/ の設計仕様書を参照してください"