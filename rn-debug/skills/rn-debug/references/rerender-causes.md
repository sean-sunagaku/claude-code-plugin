# よくある再レンダリング原因と対策

## 1. インラインオブジェクト/配列の生成

**症状**: 毎回新しい参照が作られ、子コンポーネントが再レンダリング

```tsx
// NG: 毎レンダリングで新しいオブジェクト
<Child style={{ color: 'red' }} />
<Child items={[1, 2, 3]} />

// OK: 外に出すか useMemo
const style = useMemo(() => ({ color: 'red' }), []);
<Child style={style} />
```

**ログ挿入で確認**: `[PROPS CHANGED]` で style や items が毎回変化していればこれが原因。

## 2. インラインコールバック

**症状**: onPress 等に毎回新しい関数が渡される

```tsx
// NG
<Button onPress={() => doSomething(id)} />

// OK
const handlePress = useCallback(() => doSomething(id), [id]);
<Button onPress={handlePress} />
```

**ログ挿入で確認**: `[PROPS CHANGED]` で onPress が毎回変化。

## 3. Context Provider の value

**症状**: Provider の value が毎レンダリングで新しいオブジェクトになる

```tsx
// NG: 毎回 { isPremium, loading } が新しいオブジェクト
<Context.Provider value={{ isPremium, loading }}>

// OK: useMemo で安定化
const value = useMemo(() => ({ isPremium, loading }), [isPremium, loading]);
<Context.Provider value={value}>
```

**ログ挿入で確認**: `[CONTEXT]` で value identity が毎回 false。

## 4. useEffect の依存配列の問題

**症状**: useEffect が想定より多く実行される

```tsx
// NG: user オブジェクトが毎回新しい参照
useEffect(() => { ... }, [user]);

// OK: 安定した値を依存に
useEffect(() => { ... }, [user?.uid]);
```

**ログ挿入で確認**: `[EFFECT]` が想定外の頻度で出力される。

## 5. Firebase リスナーの再登録

**症状**: 依存値が不安定で onSnapshot が何度も登録される

```tsx
// NG: user が変わるたびにリスナー再登録
useEffect(() => {
  const unsub = onSnapshot(...);
  return unsub;
}, [user]); // user オブジェクト全体を依存にしている

// OK
useEffect(() => {
  if (!uid) return;
  const unsub = onSnapshot(...);
  return unsub;
}, [uid]); // UID のみ依存
```

**ログ挿入で確認**: `[LISTENER]` の registering/unsubscribing が頻発。

## 6. 親コンポーネントの再レンダリング伝播

**症状**: 親が再レンダリングすると子も全て再レンダリング

```tsx
// 対策: React.memo で子をメモ化
const Child = React.memo(function Child({ title }: Props) {
  return <Text>{title}</Text>;
});
```

**ログ挿入で確認**: `[RENDER]` で親子が同時に再レンダリングされ、子の props に変化がない。

## 7. FlatList の最適化不足

**症状**: リスト全体が再レンダリングされる

```tsx
// 対策
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={renderItem}  // useCallback でメモ化
  getItemLayout={...}       // レイアウト計算スキップ
/>
```

**ログ挿入で確認**: renderItem 内の `[RENDER]` が全アイテムで出力される。

## 8. setState に同じ値をセット

**症状**: 同じ値でも参照が異なると再レンダリング

```tsx
// NG: 新しい配列を毎回セット
setItems([...items]);

// OK: 変化がない場合はセットしない
const newItems = computeItems();
if (JSON.stringify(newItems) !== JSON.stringify(items)) {
  setItems(newItems);
}
```
