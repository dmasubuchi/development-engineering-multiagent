#!/bin/bash
# Import Design Specifications Script
# 設計仕様書を開発プロジェクトにインポート

set -e

echo "📥 Design Specifications Import Tool"
echo "===================================="
echo ""

# 引数解析
ARCHITECTURE_DIR=""
API_DIR=""
DATABASE_DIR=""
UI_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --architecture)
            ARCHITECTURE_DIR="$2"
            shift 2
            ;;
        --api)
            API_DIR="$2"
            shift 2
            ;;
        --database)
            DATABASE_DIR="$2"
            shift 2
            ;;
        --ui)
            UI_DIR="$2"
            shift 2
            ;;
        --help)
            echo "使用方法:"
            echo "  $0 --architecture <dir> --api <dir> --database <dir> [--ui <dir>]"
            echo ""
            echo "オプション:"
            echo "  --architecture <dir>  アーキテクチャ設計ディレクトリ"
            echo "  --api <dir>          API設計ディレクトリ"
            echo "  --database <dir>     データベース設計ディレクトリ"
            echo "  --ui <dir>           UI設計ディレクトリ（オプション）"
            exit 0
            ;;
        *)
            echo "❌ 不明なオプション: $1"
            echo "ヘルプを表示: $0 --help"
            exit 1
            ;;
    esac
done

# 必須パラメータチェック
if [ -z "$ARCHITECTURE_DIR" ] || [ -z "$API_DIR" ] || [ -z "$DATABASE_DIR" ]; then
    echo "❌ エラー: 必須パラメータが不足しています"
    echo "使用方法: $0 --architecture <dir> --api <dir> --database <dir>"
    exit 1
fi

# ディレクトリ存在チェック
for dir in "$ARCHITECTURE_DIR" "$API_DIR" "$DATABASE_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "❌ エラー: ディレクトリが存在しません: $dir"
        exit 1
    fi
done

# プロジェクトディレクトリの確認
if [ ! -f ".claude/project-config.json" ]; then
    echo "❌ エラー: 開発プロジェクトのルートディレクトリで実行してください"
    exit 1
fi

PROJECT_NAME=$(cat .claude/project-config.json | grep -o '"project_name": "[^"]*' | cut -d'"' -f4)

echo "🎯 インポート対象:"
echo "  プロジェクト: $PROJECT_NAME"
echo "  アーキテクチャ設計: $ARCHITECTURE_DIR"
echo "  API設計: $API_DIR"
echo "  データベース設計: $DATABASE_DIR"
if [ -n "$UI_DIR" ]; then
    echo "  UI設計: $UI_DIR"
fi
echo ""

# インポート先ディレクトリ作成
echo "📁 インポート先ディレクトリを準備中..."
mkdir -p shared/specs/{architecture,api,database,ui}

# アーキテクチャ設計のインポート
echo "🏗️ アーキテクチャ設計をインポート中..."
if [ -f "$ARCHITECTURE_DIR/system-architecture-template.md" ]; then
    cp "$ARCHITECTURE_DIR/system-architecture-template.md" shared/specs/architecture/system-architecture.md
    echo "  ✅ システムアーキテクチャ設計書"
fi

# API設計のインポート
echo "🔌 API設計をインポート中..."
if [ -f "$API_DIR/api-design-template.yaml" ]; then
    cp "$API_DIR/api-design-template.yaml" shared/specs/api/openapi.yaml
    echo "  ✅ OpenAPI仕様書"
fi

# データベース設計のインポート
echo "🗄️ データベース設計をインポート中..."
if [ -f "$DATABASE_DIR/database-design-template.md" ]; then
    cp "$DATABASE_DIR/database-design-template.md" shared/specs/database/database-design.md
    echo "  ✅ データベース設計書"
fi

# UI設計のインポート（オプション）
if [ -n "$UI_DIR" ] && [ -d "$UI_DIR" ]; then
    echo "🎨 UI設計をインポート中..."
    find "$UI_DIR" -name "*.md" -o -name "*.html" -o -name "*.css" | while read file; do
        cp "$file" shared/specs/ui/
        echo "  ✅ $(basename "$file")"
    done
fi

# インポート概要ファイル作成
echo "📝 インポート概要を作成中..."
cat > shared/specs/README.md << EOF
# 設計仕様書

このディレクトリには、要件定義・設計フェーズで作成された仕様書が含まれています。

## インポート日時
$(date +"%Y-%m-%d %H:%M:%S")

## インポート元
- アーキテクチャ設計: ${ARCHITECTURE_DIR}
- API設計: ${API_DIR}
- データベース設計: ${DATABASE_DIR}
$([ -n "$UI_DIR" ] && echo "- UI設計: ${UI_DIR}")

## ファイル一覧
### アーキテクチャ
- system-architecture.md - システム全体のアーキテクチャ設計

### API
- openapi.yaml - OpenAPI 3.0形式のAPI仕様書

### データベース
- database-design.md - データベース設計書（ER図、テーブル定義）

$([ -n "$UI_DIR" ] && echo "### UI
- 各種UIデザインファイル")

## 開発チームへの指示
1. 各エージェントは自分の専門分野の仕様書を確認してください
2. 不明点があれば shared/questions/ に質問を記載してください
3. 実装開始前に全体ミーティング（sync/meeting.md）で認識を合わせます

---
*Development Engineering MultiAgent System*
EOF

# 質問用ディレクトリ作成
mkdir -p shared/questions

# Git に追加
echo ""
echo "💾 変更をGitに記録中..."
git add shared/specs/
git commit -m "feat: 設計仕様書をインポート

- アーキテクチャ設計
- API仕様書（OpenAPI）
- データベース設計
$([ -n "$UI_DIR" ] && echo "- UI設計")

インポート元:
- $ARCHITECTURE_DIR
- $API_DIR
- $DATABASE_DIR
$([ -n "$UI_DIR" ] && echo "- $UI_DIR")"

# 完了メッセージ
echo ""
echo "✅ 設計仕様書のインポートが完了しました！"
echo ""
echo "📋 インポートされたファイル:"
echo "  shared/specs/"
find shared/specs -type f -name "*.md" -o -name "*.yaml" | sed 's/^/  /'
echo ""
echo "🚀 次のステップ:"
echo "1. 各開発エージェントのワークツリーで仕様を確認"
echo "2. 開発タスクの分担と優先順位を決定"
echo "3. 実装開始"
echo ""
echo "💡 ヒント: 各エージェントは shared/specs/ の内容を参照できます"