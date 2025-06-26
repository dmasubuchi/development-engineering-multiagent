#!/usr/bin/env python3
"""
TDD進捗モニタリングスクリプト
Claude Code Dev方式のリアルタイム進捗追跡
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path
import time
import argparse

class TDDProgressMonitor:
    def __init__(self, project_path):
        self.project_path = Path(project_path)
        self.agents = [
            "test-lead",
            "backend-developer", 
            "frontend-developer",
            "review-engineer",
            "integration-engineer"
        ]
        
    def get_test_statistics(self):
        """テスト統計情報を取得"""
        stats = {
            "total_tests": 0,
            "passing_tests": 0,
            "failing_tests": 0,
            "coverage": 0.0
        }
        
        # テストファイルをカウント
        test_dir = self.project_path / "output" / "tests"
        if test_dir.exists():
            test_files = list(test_dir.glob("**/*.test.*")) + list(test_dir.glob("**/*_test.*"))
            stats["total_tests"] = len(test_files)
            
        # カバレッジレポートを読む
        coverage_file = self.project_path / "coverage" / "coverage-summary.json"
        if coverage_file.exists():
            try:
                with open(coverage_file) as f:
                    coverage_data = json.load(f)
                    stats["coverage"] = coverage_data.get("total", {}).get("lines", {}).get("pct", 0)
            except:
                pass
                
        return stats
        
    def get_agent_activity(self, agent):
        """エージェントの活動状況を取得"""
        worktree_path = self.project_path.parent / f"worktree-{agent}"
        activity = {
            "last_commit": None,
            "commit_count": 0,
            "current_status": "inactive",
            "files_changed": 0
        }
        
        if worktree_path.exists():
            try:
                # 最新コミット取得
                result = subprocess.run(
                    ["git", "log", "-1", "--format=%h|%s|%ar"],
                    cwd=worktree_path,
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0 and result.stdout.strip():
                    parts = result.stdout.strip().split("|")
                    activity["last_commit"] = {
                        "hash": parts[0],
                        "message": parts[1],
                        "time": parts[2]
                    }
                
                # コミット数
                result = subprocess.run(
                    ["git", "rev-list", "--count", "HEAD"],
                    cwd=worktree_path,
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    activity["commit_count"] = int(result.stdout.strip())
                
                # 変更ファイル数
                result = subprocess.run(
                    ["git", "diff", "--name-only"],
                    cwd=worktree_path,
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    files = result.stdout.strip().split("\n")
                    activity["files_changed"] = len([f for f in files if f])
                    
                # ステータスファイル確認
                status_file = worktree_path / "sync" / "status.md"
                if status_file.exists():
                    # ファイルの更新時刻で活動状況判断
                    mtime = datetime.fromtimestamp(status_file.stat().st_mtime)
                    if (datetime.now() - mtime).seconds < 300:  # 5分以内
                        activity["current_status"] = "active"
                    elif (datetime.now() - mtime).seconds < 3600:  # 1時間以内
                        activity["current_status"] = "idle"
                        
            except Exception as e:
                pass
                
        return activity
        
    def get_tdd_phase(self):
        """現在のTDDフェーズを判定"""
        test_stats = self.get_test_statistics()
        
        # 各エージェントの活動確認
        activities = {agent: self.get_agent_activity(agent) for agent in self.agents}
        
        # フェーズ判定ロジック
        if activities["test-lead"]["current_status"] == "active":
            if test_stats["total_tests"] == 0:
                return "🔴 RED (テスト作成開始)"
            elif test_stats["failing_tests"] > 0:
                return "🔴 RED (失敗テスト作成中)"
        
        if (activities["backend-developer"]["current_status"] == "active" or 
            activities["frontend-developer"]["current_status"] == "active"):
            if test_stats["failing_tests"] > 0:
                return "🟢 GREEN (実装中)"
            else:
                return "🟢 GREEN (テスト通過)"
                
        if activities["review-engineer"]["current_status"] == "active":
            return "🔧 REFACTOR (コード改善中)"
            
        if activities["integration-engineer"]["current_status"] == "active":
            return "🔗 INTEGRATE (統合・デプロイ中)"
            
        return "⏸️ IDLE (待機中)"
        
    def generate_dashboard(self):
        """ダッシュボード生成"""
        test_stats = self.get_test_statistics()
        current_phase = self.get_tdd_phase()
        
        dashboard = f"""# TDD Progress Dashboard
Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 📊 Current Phase
**{current_phase}**

## 🧪 Test Statistics
- Total Tests: {test_stats['total_tests']}
- Passing: {test_stats['passing_tests']}
- Failing: {test_stats['failing_tests']}
- Coverage: {test_stats['coverage']:.1f}%

## 🤖 Agent Activity
"""
        
        for agent in self.agents:
            activity = self.get_agent_activity(agent)
            status_icon = {
                "active": "🟢",
                "idle": "🟡",
                "inactive": "⚫"
            }.get(activity["current_status"], "⚫")
            
            dashboard += f"\n### {status_icon} {agent.replace('-', ' ').title()}\n"
            dashboard += f"- Status: {activity['current_status']}\n"
            dashboard += f"- Commits: {activity['commit_count']}\n"
            dashboard += f"- Files Changed: {activity['files_changed']}\n"
            
            if activity["last_commit"]:
                dashboard += f"- Last Commit: {activity['last_commit']['message']} ({activity['last_commit']['time']})\n"
            
        # タイムライン
        dashboard += "\n## 📅 Recent Timeline\n```\n"
        
        # 各エージェントの最新コミットを時系列で表示
        timeline_entries = []
        for agent in self.agents:
            activity = self.get_agent_activity(agent)
            if activity["last_commit"]:
                timeline_entries.append({
                    "agent": agent,
                    "message": activity["last_commit"]["message"],
                    "time": activity["last_commit"]["time"]
                })
        
        # 時系列でソート（簡易的）
        for entry in timeline_entries[:5]:  # 最新5件
            dashboard += f"{entry['time']:>12} | {entry['agent']:>20} | {entry['message']}\n"
            
        dashboard += "```\n"
        
        # 推奨アクション
        dashboard += "\n## 💡 Recommended Actions\n"
        
        if current_phase.startswith("🔴 RED"):
            dashboard += "- Backend/Frontend developers: Review failing tests\n"
            dashboard += "- Prepare implementation strategy\n"
        elif current_phase.startswith("🟢 GREEN"):
            if test_stats["failing_tests"] > 0:
                dashboard += "- Continue implementation to pass tests\n"
            else:
                dashboard += "- Review Engineer: Start code review\n"
                dashboard += "- Consider refactoring opportunities\n"
        elif current_phase.startswith("🔧 REFACTOR"):
            dashboard += "- Apply review feedback\n"
            dashboard += "- Ensure tests still pass\n"
        elif current_phase.startswith("🔗 INTEGRATE"):
            dashboard += "- Monitor deployment progress\n"
            dashboard += "- Prepare for next iteration\n"
        else:
            dashboard += "- Test Lead: Create new test cases\n"
            dashboard += "- Start next TDD cycle\n"
            
        return dashboard
        
    def watch(self, interval=30):
        """リアルタイムモニタリング"""
        print("🔍 TDD Progress Monitor Started")
        print(f"Monitoring: {self.project_path}")
        print(f"Update interval: {interval}s")
        print("Press Ctrl+C to stop\n")
        
        try:
            while True:
                # ダッシュボード生成
                dashboard = self.generate_dashboard()
                
                # 画面クリア（Unix/Linux/Mac）
                os.system('clear' if os.name != 'nt' else 'cls')
                
                # ダッシュボード表示
                print(dashboard)
                
                # ファイルにも保存
                dashboard_file = self.project_path / "sync" / "tdd-dashboard.md"
                dashboard_file.parent.mkdir(exist_ok=True)
                with open(dashboard_file, 'w') as f:
                    f.write(dashboard)
                
                # 待機
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\n\n✅ Monitoring stopped")
            
def main():
    parser = argparse.ArgumentParser(description='TDD進捗モニタリング')
    parser.add_argument('project_path', help='プロジェクトパス')
    parser.add_argument('--watch', action='store_true', help='リアルタイムモニタリング')
    parser.add_argument('--interval', type=int, default=30, help='更新間隔（秒）')
    
    args = parser.parse_args()
    
    monitor = TDDProgressMonitor(args.project_path)
    
    if args.watch:
        monitor.watch(args.interval)
    else:
        # 一度だけ実行
        dashboard = monitor.generate_dashboard()
        print(dashboard)
        
        # ファイルに保存
        dashboard_file = Path(args.project_path) / "sync" / "tdd-dashboard.md"
        dashboard_file.parent.mkdir(exist_ok=True)
        with open(dashboard_file, 'w') as f:
            f.write(dashboard)
        print(f"\n✅ Dashboard saved to: {dashboard_file}")

if __name__ == "__main__":
    main()