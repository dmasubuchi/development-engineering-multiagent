#!/bin/bash
# Development Team Setup Script
# 開発チームのセットアップと初期化

set -e

echo "🚀 Development Engineering MultiAgent Setup"
echo "=========================================="
echo ""

# プロジェクト名の入力
read -p "プロジェクト名を入力してください: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-my-dev-project}

# 技術スタックの選択
echo ""
echo "📋 技術スタックを選択してください:"
echo ""
echo "フロントエンド:"
echo "1) React + TypeScript"
echo "2) Vue.js + TypeScript"
echo "3) Angular"
read -p "選択 (1-3): " frontend_choice

echo ""
echo "バックエンド:"
echo "1) Node.js + Express"
echo "2) Python + FastAPI"
echo "3) Java + Spring Boot"
echo "4) Go + Gin"
read -p "選択 (1-4): " backend_choice

echo ""
echo "データベース:"
echo "1) PostgreSQL"
echo "2) MySQL"
echo "3) MongoDB"
read -p "選択 (1-3): " db_choice

# 技術スタックの設定
case $frontend_choice in
  1) FRONTEND_STACK="react-typescript" ;;
  2) FRONTEND_STACK="vue-typescript" ;;
  3) FRONTEND_STACK="angular" ;;
  *) FRONTEND_STACK="react-typescript" ;;
esac

case $backend_choice in
  1) BACKEND_STACK="node-express" ;;
  2) BACKEND_STACK="python-fastapi" ;;
  3) BACKEND_STACK="java-spring" ;;
  4) BACKEND_STACK="go-gin" ;;
  *) BACKEND_STACK="node-express" ;;
esac

case $db_choice in
  1) DATABASE="postgresql" ;;
  2) DATABASE="mysql" ;;
  3) DATABASE="mongodb" ;;
  *) DATABASE="postgresql" ;;
esac

echo ""
echo "🎯 設定確認:"
echo "  プロジェクト名: $PROJECT_NAME"
echo "  フロントエンド: $FRONTEND_STACK"
echo "  バックエンド: $BACKEND_STACK"
echo "  データベース: $DATABASE"
echo ""
read -p "この設定で続行しますか？ (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "セットアップを中止しました"
    exit 0
fi

PROJECT_DIR="../${PROJECT_NAME}"

# プロジェクトディレクトリ作成
echo ""
echo "📁 プロジェクトディレクトリを作成中..."
if [ -d "$PROJECT_DIR" ]; then
    echo "❌ エラー: ${PROJECT_DIR} は既に存在します"
    exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Git初期化
echo "🔧 Git リポジトリを初期化中..."
git init -b main

# 基本ディレクトリ構造作成
echo "📂 ディレクトリ構造を作成中..."
mkdir -p {shared/{specs,data},output/{frontend,backend,tests,infrastructure},.claude}

# 設定ファイル作成
echo "⚙️ プロジェクト設定を作成中..."
cat > .claude/project-config.json << EOF
{
  "project_name": "${PROJECT_NAME}",
  "tech_stack": {
    "frontend": "${FRONTEND_STACK}",
    "backend": "${BACKEND_STACK}",
    "database": "${DATABASE}"
  },
  "team": {
    "frontend_developer": {
      "name": "Frontend Developer",
      "worktree": "../frontend-dev"
    },
    "backend_developer": {
      "name": "Backend Developer",
      "worktree": "../backend-dev"
    },
    "test_engineer": {
      "name": "Test Engineer",
      "worktree": "../test-eng"
    },
    "devops_engineer": {
      "name": "DevOps Engineer",
      "worktree": "../devops"
    }
  },
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

# README作成
cat > README.md << EOF
# ${PROJECT_NAME}

開発エンジニアリングマルチエージェントシステムによって管理されているプロジェクト

## 技術スタック
- **フロントエンド**: ${FRONTEND_STACK}
- **バックエンド**: ${BACKEND_STACK}
- **データベース**: ${DATABASE}

## チーム構成
- Frontend Developer - UI実装担当
- Backend Developer - API実装担当
- Test Engineer - 品質保証担当
- DevOps Engineer - インフラ・デプロイ担当

## ディレクトリ構造
\`\`\`
${PROJECT_NAME}/
├── shared/         # チーム共有リソース
│   ├── specs/      # 設計仕様書
│   └── data/       # テストデータ等
├── output/         # 生成されたコード
│   ├── frontend/   # フロントエンドコード
│   ├── backend/    # バックエンドコード
│   ├── tests/      # テストコード
│   └── infrastructure/ # インフラ設定
└── .claude/        # Claude設定
\`\`\`

## 開始方法
1. 各ワークツリーで \`claude\` を起動
2. 設計仕様書を shared/specs/ に配置
3. 各エージェントが並行して開発を実施

作成日: $(date +%Y-%m-%d)
EOF

# 初期コミット
echo "💾 初期コミットを作成中..."
git add .
git commit -m "feat: ${PROJECT_NAME} プロジェクト初期化

- 技術スタック: ${FRONTEND_STACK}, ${BACKEND_STACK}, ${DATABASE}
- 開発チーム設定完了
- 基本ディレクトリ構造作成"

# Git Worktreeで各開発者の環境を作成
echo ""
echo "🌿 開発チームのWorktree環境を作成中..."

# エージェント設定
declare -A agents=(
    ["frontend-dev"]="frontend-developer"
    ["backend-dev"]="backend-developer"
    ["test-eng"]="test-engineer"
    ["devops"]="devops-engineer"
)

declare -A agent_names=(
    ["frontend-developer"]="Frontend Developer"
    ["backend-developer"]="Backend Developer"
    ["test-engineer"]="Test Engineer"
    ["devops-engineer"]="DevOps Engineer"
)

for worktree in "${!agents[@]}"; do
    agent=${agents[$worktree]}
    agent_name=${agent_names[$agent]}
    
    echo "  🎭 ${agent_name} 環境を作成中..."
    
    # Worktree作成
    git worktree add -b "${worktree}" "../${worktree}"
    
    # エージェント専用ディレクトリ作成
    cd "../${worktree}"
    mkdir -p {work,sync}
    
    # CLAUDE.md生成
    python3 ../../development-engineering-multiagent/scripts/generate-dev-claude-config.py \
        --agent "$agent" \
        --project-name "$PROJECT_NAME" \
        --tech-stack "$FRONTEND_STACK,$BACKEND_STACK,$DATABASE" \
        --output-dir .
    
    # 共有ディレクトリへのシンボリックリンク
    ln -s "../${PROJECT_NAME}/shared" shared
    ln -s "../${PROJECT_NAME}/output" output
    
    # 初期コミット
    git add .
    git commit -m "feat: ${agent_name} ワークスペース初期化

役割: ${agent_name}
技術スタック: ${FRONTEND_STACK}, ${BACKEND_STACK}, ${DATABASE}"
    
    cd "$PROJECT_DIR"
    echo "  ✅ ${agent_name} 準備完了"
done

# 完了メッセージ
echo ""
echo "🎉 開発チームのセットアップが完了しました！"
echo ""
echo "📂 作成されたディレクトリ:"
echo "  🏠 メインプロジェクト: ${PROJECT_DIR}"
echo "  👨‍💻 Frontend Developer: ../frontend-dev/"
echo "  ⚙️ Backend Developer: ../backend-dev/"
echo "  🧪 Test Engineer: ../test-eng/"
echo "  🚀 DevOps Engineer: ../devops/"
echo ""
echo "🚀 次のステップ:"
echo "1. 設計仕様書を shared/specs/ に配置"
echo "2. 各ワークツリーで claude を起動:"
echo "   cd ../frontend-dev && claude"
echo "   cd ../backend-dev && claude"
echo "   cd ../test-eng && claude"
echo "   cd ../devops && claude"
echo ""
echo "💡 ヒント: tmux や複数ターミナルでの並行作業を推奨"
echo ""
echo "Happy Coding! 🚀"