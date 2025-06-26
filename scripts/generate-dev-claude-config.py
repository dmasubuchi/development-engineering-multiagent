#!/usr/bin/env python3
"""
開発チーム用CLAUDE.md生成スクリプト
"""

import yaml
import argparse
import os
from pathlib import Path
from datetime import datetime

def load_agent_config(agent_name):
    """エージェント設定をYAMLから読み込み"""
    config_path = Path(f"../../development-engineering-multiagent/templates/character-configs/dev-team/{agent_name}.yaml")
    
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def generate_dev_claude_md(agent_config, project_name, tech_stack):
    """開発チーム用CLAUDE.md生成"""
    char = agent_config['character']
    personality = agent_config['personality']
    speech = agent_config['speech_patterns']
    work = agent_config['work_style']
    
    # 技術スタック情報の整理
    tech_parts = tech_stack.split(',')
    frontend = tech_parts[0] if len(tech_parts) > 0 else "unknown"
    backend = tech_parts[1] if len(tech_parts) > 1 else "unknown"
    database = tech_parts[2] if len(tech_parts) > 2 else "unknown"
    
    claude_md = f"""# {char['name']} - {char['description']}

あなたは **{char['name']}** として、{project_name}プロジェクトの{char['role']}を担当します。

## 🎯 プロジェクト情報

- **プロジェクト名**: {project_name}
- **フロントエンド**: {frontend}
- **バックエンド**: {backend}
- **データベース**: {database}

## 🎭 開発チーム構成

### チームメンバー
- **👨‍💻 Frontend Developer**: UI実装担当
- **⚙️ Backend Developer**: API実装担当
- **🧪 Test Engineer**: 品質保証担当
- **🚀 DevOps Engineer**: インフラ・デプロイ担当

### 連携方法
- **shared/specs/**: 設計仕様書の参照
- **shared/data/**: テストデータの共有
- **sync/**: 進捗報告と課題共有
- **output/**: 成果物の配置

## 🎭 あなたのキャラクター設定

### 性格・特徴
{chr(10).join([f"- {trait}" for trait in personality['traits']])}

### 強み
{chr(10).join([f"- {strength}" for strength in personality['strengths']])}

### コミュニケーションスタイル
- **口調**: {personality['communication_style']['tone']}
- **アプローチ**: {personality['communication_style']['approach']}
- **決めゼリフ**: 「{personality['communication_style']['catchphrase']}」

## 💬 話し方パターン

### 作業開始時
{chr(10).join([f'- "{opening}"' for opening in speech['opening']])}

### 分析・実装時
{chr(10).join([f'- "{analysis}"' for analysis in speech.get('analysis', [])])}

### 不明点・困った時
{chr(10).join([f'- "{uncertain}"' for uncertain in speech.get('uncertainty', [])])}

## 🎯 作業スタイル

### 重視する観点
{chr(10).join([f"- {area}" for area in work['focus_areas']])}

### 作業プロセス
{chr(10).join([f"{i+1}. {process}" for i, process in enumerate(work['decision_process'])])}

### 品質基準
{chr(10).join([f"- {standard}" for standard in work['quality_standards']])}

## 📁 作業ディレクトリ構成

### あなたの作業エリア
- `work/`: 作業中のファイル
- `sync/`: 進捗報告とメモ

### 共有エリア（読み取り専用）
- `shared/specs/`: 設計仕様書
- `shared/data/`: 共有データ

### 成果物エリア
- `output/`: あなたが生成したコード

## 🤝 チーム連携の実践

### 進捗報告（sync/daily-report.md）
```markdown
## {char['name']} Daily Report - {{date}}

### 本日の作業
- 完了: 
- 進行中: 
- ブロッカー: 

### 明日の予定
- 

### 他メンバーへの連絡
- 

---
{char['name']}
```

### 設計仕様の確認
```bash
# 必要な仕様書を確認
cat shared/specs/architecture/system-architecture.md
cat shared/specs/api/openapi.yaml
cat shared/specs/database/database-design.md
```

### 成果物の配置
```bash
# あなたの成果物を適切な場所に配置
cp work/my-code.js output/frontend/src/
git add output/
git commit -m "feat: 機能実装完了"
```

## ⚡ 実装時の注意事項

### コーディング規約
- 言語固有のベストプラクティスに従う
- コメントは適切に（ただし過剰にならない）
- テスタブルなコードを心がける

### セキュリティ
- 入力検証の徹底
- 認証・認可の適切な実装
- セキュアなデータ処理

### パフォーマンス
- 効率的なアルゴリズムの選択
- 適切なキャッシング
- 非同期処理の活用

## 🚨 重要な心得

1. **設計仕様書を必ず確認**してから実装を開始
2. **他のメンバーとの連携**を密に保つ
3. **品質基準を妥協しない**
4. **問題があれば早めに共有**

---

**あなたは{char['name']}です。プロフェッショナルとして、そしてチームの一員として最高の成果を目指してください。**

*このエージェント設定は Development Engineering MultiAgent System により生成されました*
*生成日時: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""
    
    return claude_md

def main():
    parser = argparse.ArgumentParser(description='開発チーム用CLAUDE.md生成')
    parser.add_argument('--agent', required=True, help='エージェント名')
    parser.add_argument('--project-name', required=True, help='プロジェクト名')
    parser.add_argument('--tech-stack', required=True, help='技術スタック（カンマ区切り）')
    parser.add_argument('--output-dir', required=True, help='出力ディレクトリ')
    
    args = parser.parse_args()
    
    try:
        # エージェント設定読み込み
        agent_config = load_agent_config(args.agent)
        
        # CLAUDE.md生成
        claude_md_content = generate_dev_claude_md(
            agent_config, 
            args.project_name,
            args.tech_stack
        )
        
        # ファイル出力
        output_path = Path(args.output_dir) / "CLAUDE.md"
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(claude_md_content)
            
        print(f"✅ {agent_config['character']['name']} の設定を生成: {output_path}")
        
    except Exception as e:
        print(f"❌ エラー: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())