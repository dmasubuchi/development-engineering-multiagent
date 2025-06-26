# TDD Project Example - Todo API

このディレクトリは、TDD-Driven MultiAgent Systemを使用した実際のプロジェクト例です。

## プロジェクト概要

シンプルなTodo管理APIをTDD手法で開発する例を示します。

### 機能要件
1. Todoの作成（タイトル、説明、期限）
2. Todo一覧の取得（フィルタリング、ソート）
3. Todoの更新（ステータス変更含む）
4. Todoの削除
5. ユーザー認証

## TDD開発フロー

### 1. 🔴 RED Phase - Test Lead

```javascript
// tests/todo.test.js
describe('Todo API', () => {
  test('POST /api/todos creates a new todo', async () => {
    const newTodo = {
      title: '買い物に行く',
      description: '牛乳とパンを買う',
      dueDate: '2024-12-25'
    };
    
    const response = await request(app)
      .post('/api/todos')
      .set('Authorization', 'Bearer valid-token')
      .send(newTodo);
    
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      id: expect.any(String),
      title: newTodo.title,
      description: newTodo.description,
      dueDate: newTodo.dueDate,
      status: 'pending',
      createdAt: expect.any(String)
    });
  });
});
```

### 2. 🟢 GREEN Phase - Backend Developer

```javascript
// backend/routes/todos.js
router.post('/todos', authenticate, async (req, res) => {
  try {
    const { title, description, dueDate } = req.body;
    
    // 入力検証
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }
    
    const todo = await Todo.create({
      title,
      description,
      dueDate,
      status: 'pending',
      userId: req.user.id
    });
    
    res.status(201).json(todo);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### 3. 🎨 Frontend Implementation

```typescript
// frontend/components/TodoForm.tsx
const TodoForm: React.FC = () => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    dueDate: ''
  });
  
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    
    try {
      const response = await api.post('/todos', formData);
      if (response.status === 201) {
        showToast('Todo created successfully', 'success');
        onTodoCreated(response.data);
      }
    } catch (error) {
      showToast('Failed to create todo', 'error');
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
};
```

### 4. 🔧 REFACTOR Phase - Review Engineer

改善提案：
- エラーハンドリングの統一
- バリデーションロジックの抽出
- テストヘルパーの作成

### 5. 🔗 INTEGRATE Phase

```yaml
# .github/workflows/tdd-pipeline.yml
name: TDD Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: |
          npm test -- --coverage
          npm run test:e2e
      
      - name: Check Coverage
        run: |
          if [ $(jq '.total.lines.pct' coverage/coverage-summary.json) -lt 80 ]; then
            echo "Coverage below 80%"
            exit 1
          fi
```

## ディレクトリ構造

```
tdd-project-example/
├── shared/
│   ├── specs/
│   │   ├── requirements.md
│   │   └── api-spec.yaml
│   └── data/
│       └── test-fixtures.json
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── backend/
│   ├── models/
│   ├── routes/
│   └── services/
├── frontend/
│   ├── components/
│   ├── hooks/
│   └── services/
└── docs/
    └── tdd-journey.md
```

## エージェント別タスク

### Test Lead
1. 要件からテストケース抽出
2. テストファースト作成
3. カバレッジ目標設定

### Backend Developer
1. APIエンドポイント実装
2. データモデル作成
3. ビジネスロジック実装

### Frontend Developer
1. UIコンポーネント作成
2. API統合
3. ユーザビリティテスト

### Review Engineer
1. コード品質確認
2. ベストプラクティス適用
3. リファクタリング提案

### Integration Engineer
1. CI/CDパイプライン構築
2. 環境別デプロイ
3. モニタリング設定

## 学習ポイント

1. **テストが仕様書**：テストを読めば何を作るべきか分かる
2. **小さなステップ**：一度に多くを実装しない
3. **継続的な改善**：動くコードができたら改善
4. **チーム協調**：各エージェントが専門性を発揮

---

*このプロジェクトはTDD-Driven MultiAgent Systemのデモンストレーションです*