# モデル開発プレイブック (ML/DL 汎用)

> **使用タイミング**: 新規 ML/DL モデル開発（Kaggle コンペ / 業務 PoC / 研究プロジェクト等）のキックオフ時にのみ参照する。
> 既存 codebase の改修・バグ修正・リファクタリング・運用は参照不要。
>
> このファイルは**モデル開発の「構造とプロセス」**を提供する汎用リファレンス。
> 具体的な技術選定はプロジェクト固有の CLAUDE.md / SPEC.md に書く。

---

## 0. 全体フロー — キックオフ時の儀式 3 ステップ

着手前に**必ず**順番に実施する。1 つでも飛ばすと「最近覚えた手法を全プロジェクトで使う」病になる。

1. **問題タイプ診断** (30 分必須) — §1
2. **上位解法 / 標準パターンの体系調査** (半日必須) — §2
3. **タイプ別 pipeline template の選択** (1 時間) — §3

その後 §4 の 5 レイヤー構造に従って実装、§5 のプロセスメタを並行運用、§6 のアンチパターンを回避する。

---

## 1. 問題タイプ診断 (Phase 0 必須儀式)

着手前に**必ず** A-E のどれかに分類する。**「分からない問題」と「知らない手法」は別物** — 選択肢に無い手法は永遠に出てこない。

### 診断質問

| # | 質問 | 答え方 |
|---|---|---|
| Q1 | 入力モダリティは? | image / text / tabular / sequence / multimodal / graph |
| Q2 | 出力タスクは? | classification / regression / ranking / generation / segmentation / detection |
| Q3 | データサイズは? | small (<10K) / medium (10K-1M) / large (>1M) |
| Q4 | 評価指標は? | RMSE / AUC / NDCG / F1 / BLEU / custom |
| Q5 | 制約は? | time limit / kernel only / private test / API 推論時間 / プライバシー |
| Q6 | 信号構造は? | 単一強信号 / 多系統信号 combine / Foundation Model 適用可 |
| Q7 | ラベル品質は? | clean / noisy / weak / semi-supervised |

### タイプ分類 (典型)

- **A: 単一強信号タイプ** — 画像分類 / 標準的なテキスト分類 / 明確な leakage 構造あり
- **B: 多系統信号 combine タイプ** — 信号復元 / 不完全観測 sequence / multi-modal融合 / 医療診断 / petroleum / sensor fusion
- **C: Foundation Model 殴れるタイプ** — 最近の NLP / 一部画像 / 標準 task (BERT/Llama/CLIP/SAM の延長)
- **D: Tabular 系** — Kaggle Playground / 古典 tabular regression / 構造化データ予測
- **E: 時系列予測** — 需要予測 / sensor 時系列 / forecast 系 / event prediction
- **F: Generation / Search** — 生成系 / 推薦 / ranking (別 playbook 推奨、本書対象外)

→ プロジェクト docs/ に `problem_type_diagnosis.md` として 1 ページ保存する。

---

## 2. 上位解法 / 標準パターンの体系調査 (半日、必須)

着手前に**過去 1-2 年の類似タイプの上位解法 / 標準実装を 3〜5 件**読む。
**「分からない問題」は試行錯誤で解けるが、「知らない手法」は選択肢に無いと永遠に出ない**。

### 調査ソース

| ソース | 用途 |
|---|---|
| Kaggle 上位 Notebook / writeup | 同種コンペの 1st-3rd place writeup (WebSearch: `"<topic> kaggle 1st place solution"`) |
| Kaggle Discussion | `kaggle competitions topics --sort-by top` (CLI 2.1.x) |
| arXiv / 専門ジャーナル | ドメイン特化手法 (medical, petroleum, finance 等) |
| Papers with Code | SOTA leaderboard + 実装 |
| HuggingFace Models / Datasets | Foundation model の standard fine-tune コード |
| NVIDIA / Google Research blog | プロダクション実装ベストプラクティス |
| GitHub Awesome-* | 領域別の curated リスト |
| 公式 framework docs | PyTorch / Sklearn / Transformers の reference implementation |

### 必須アウトプット (プロジェクト docs/)

- `top_method_recon.md`: 当該タイプ問題で勝つ pipeline の典型 (1 ページ) + 上位陣の武器リスト (10 件) + 「未活用な武器」候補 (3 件)
- `community_latest_<YYYY-MM-DD>.md`: 競合スナップショット (Kaggle なら LB、業務なら SOTA benchmark)

### 注意点

- **タイトル/star/citation だけで判断しない、必ずコードを読む**
- **複数の上位解法に共通する骨格を見抜く** (派生フォークは同骨格 + 1〜2 signal の差)
- **Foundation model 系は「fine-tune の hyperparam」より「base model 選択」が支配的**な場合あり

---

## 3. タイプ別 pipeline template

問題タイプ診断 §1 の結果に応じて以下から選ぶ。**盲目的に全タイプに Type B を適用しない**。

### Type A: 単一強信号

```
data → augment (heavy: cutmix / mixup / RandAugment etc.)
     → strong single model (pretrained CNN / Transformer)
     → TTA → multi-seed ensemble
```

- 重要レイヤー: Layer 1 (GPU infra) / Layer 4 (multi-seed)
- 軽い/不要: Layer 2 (signal 生成) / Layer 3 (uncertainty)

### Type B: 多系統信号 combine

```
data → infra (高速化 / 中間保存)
     → multi-signal generators (5+ 系統の独立 estimator)
     → uncertainty features (mean + std + cv triple)
     → multi-model stack
     → grid post-proc (hyperparam tuning)
     → smoothing / calibration
```

- 全レイヤー必須、特に **Layer 2-3 が差別化の本丸**
- 例: sensor fusion, signal restoration, multimodal alignment

### Type C: Foundation Model

```
data → preprocessing (tokenize / patchify)
     → pretrained model fine-tune (LoRA / full / adapter)
     → multi-seed → pseudo-label retrain → simple ensemble
```

- Foundation Model が Layer 2-3 を自動化
- Layer 4 は multi-seed 中心、stacking は補助

### Type D: Tabular

```
data → feature eng (10K+ groupby with cuDF / pandas)
     → multi-seed GBDT (LGB / XGB / CatBoost)
     → hill climbing weight optim
     → multi-target stacking (target / residual / ratio / imputation の 4 表現)
     → pseudo-label retrain
```

- Layer 2 = feature engineering (大量 groupby)
- Layer 4 中心、cdeotte 系標準技

### Type E: 時系列予測

```
data → calendar features + lag/window
     → time-based CV (NOT GroupKFold)
     → LGBM / Prophet / N-BEATS / Temporal Fusion Transformer
     → simple ensemble → 後処理 calibration
```

- Layer 2 = lag/window features (軽め)
- Layer 3 不要、Layer 4 中心、**CV は時間軸方向で必ず切る**

---

## 4. 5 レイヤー構造と判断観点

すべてのタイプで「**この層は当該問題で必要か / どこまで作り込むか**」を判断する。盲目的に全層を作らない。

### Layer 1: 計算インフラ (最初に整備)

**目的**: 後段の自由度を確保。これを怠ると Layer 2 以降が物理的に乗らない。

**判断観点**:

- データサイズと memory ceiling (kernel/GPU 制限)
- GPU 必要性 (PyTorch / cuML / NN / cuDF)
- 計算時間制約 (kernel time / API 推論時間予算)
- JIT/AOT が必要か (Numba / Cython / TorchScript / TensorRT)
- dtype 戦略 (float32 vs float64 / int8 量子化)
- 中間ファイル保存戦略 (parquet / arrow / pickle / safetensors)
- 並列化方法 (multiprocessing / dask / DDP / 推論並列)
- 実験管理 (MLflow / W&B / git-tracked experiments)

**チェックリスト**:

- [ ] memory 上限を事前計算 (rows × cols × dtype bytes)
- [ ] 推論時間予算を制約から逆算
- [ ] CI/local 環境差分を確認 (encoding、path 等)
- [ ] 中間ファイル形式を決定
- [ ] 実験記録の lineage (どの run がどの commit から)

### Layer 2: Signal 生成 / Feature 抽出 (差別化の本丸)

**目的**: モデルの入力となる「予測手がかり」を生成。単一強信号か多系統 combine かは Type による。

**判断観点**:

- 単一強信号で十分か (Type A/C) vs 多系統 combine 必須か (Type B)
- ドメイン特有の estimator はあるか
- unsupervised features を作れるか
- 公開手法と差別化できる軸はあるか

**汎用 signal カタログ** (タイプ・ドメイン横断):

| カテゴリ | 例 | 適用領域 |
|---|---|---|
| Bayesian filter / state-space | Particle Filter, Kalman, HMM | sequence / sensor fusion |
| 離散探索 | Beam search, A*, Viterbi | alignment / decoding |
| 局所相関 | Cross-correlation, NCC, template matching | image patch / audio / signal |
| 空間補間 | kNN, IDW, Kriging, Voronoi | geospatial / map data |
| 周波数領域 | FFT, DWT, wavelet, Mel spectrogram | audio / signal / time series |
| Aggregation | groupby (mean/std/min/max), rolling stats | tabular / time series |
| Embedding | word2vec / fastText / pretrained encoder | NLP / categorical |
| Patch / Token | image patches, BPE tokens, audio frames | DL preprocessing |
| Graph-based | node embeddings, GNN message passing | relational data |
| Domain physics | 物理法則由来の derived quantities | 科学技術応用 |

**チェックリスト**:

- [ ] 3 系統以上の独立 signal を確保 (Type B)
- [ ] 各 signal が公開手法とどう異なるか明文化
- [ ] 計算コストが Layer 1 制約内に収まる確認
- [ ] feature と target の leak を全 signal で grep 確認

### Layer 3: 不確実性の learnable 化

**目的**: 各 signal の「信頼度」を feature として下流モデルに渡し、**動的 blending を学習させる**。

**コンセプト**: 通常の ML は点推定 ŷ のみを出すが、`(ŷ, σ)` のペアを feature として渡すと、下流モデルが「**この予測をいつ信用するか**」を学習できる。

**判断観点**:

- 各 estimator が `mean + std + cv` を出せるか
- inter-signal std が作れるか (全 estimator stack の std = master uncertainty)
- bootstrap / dropout / ensemble variance で uncertainty を作るか
- Type A/E では効果薄、Type B で最大化

**実装パターン**:

```python
# NG: 点推定だけ feature 化
features["est_x"] = est_mean

# OK: triple feature 化
features["est_x"]     = est_mean
features["est_x_std"] = est_std                            # 不確実性
features["est_x_d"]   = est_mean - anchor                  # 残差 (任意)
features["est_x_cv"]  = est_std / (abs(est_mean - anchor) + 1e-6)  # 変動係数

# Master uncertainty (estimator 群の合意度)
all_sigs = np.stack([est1_mean, est2_mean, ..., estN_mean])
features["signal_std"] = all_sigs.std(axis=0)
```

**uncertainty 源** (パターン):

- Bayesian: posterior std (PF / variational / MC dropout)
- Ensemble: prediction variance across seeds / engines
- Bootstrap: resample-based std
- Conformal: prediction interval width
- Model-internal: GBDT leaf disagreement, NN logit margin

**下流 GBDT が学習する分割木** (概念):

```
signal_std < threshold ?
  YES (信号一致) → estimator 全採用
  NO  (estimators がバラけ) → baseline/persistence に寄せる
```

**チェックリスト**:

- [ ] 全 estimator が std 列を出している
- [ ] inter-signal std が 1 列 master feature 化されている
- [ ] 下流モデルの feature_importance で std 系が top に来るか確認

### Layer 4: Stacking + Ensemble (残差を絞る)

**目的**: 多様な弱学習器を集約。**先に Layer 2 で signal 多様性を作る、ここから始めない**。

**判断観点**:

- model diversity の確保方法 (seed / hyperparam / engine / architecture)
- OOF stack の方法 (Ridge positive / Hill Climbing / LGBM meta-learner / NN meta)
- multi-seed × N / multi-target 表現 (4-target: raw / residual / ratio / imputation)
- 100% data retrain (val split を捨てて全データで最終訓練) を最終段で

**標準構成例**:

- GBDT 多様化: LGB seed = {42, 7, 123}, lr ∈ {0.025, 0.020, 0.030}, depth/num_leaves 2 種
- 異 engine 追加: CatBoost (categorical 強い), XGB (微妙に違う bias)
- NN 追加: TabNet / FT-Transformer / simple MLP (tabular)
- Stack: `Ridge(positive=True, fit_intercept=False)` で OOF 加重平均
- Refinement: Hill Climbing (greedy positive weight optim) で +0.1〜0.7 metric 期待

**チェックリスト**:

- [ ] OOF が 4 系列以上揃っている
- [ ] stack weight が CV 安定 (fold 間でブレ小)
- [ ] hill_climbing の改善幅 > 単一モデル最良の 0.5% (or 同等メトリック)
- [ ] 100% retrain の改善が CV 改善と一致 (大きく外れたら過学習)

### Layer 5: 後処理 + Final (学習対象として扱う)

**目的**: 学習の最後の絞り出し。**安全網ではなく学習対象**として扱う。

**判断観点**:

- shrinkage (α) — 基準値への収縮率
- fade-in / decay — 時間/距離に応じた予測弱化
- model blend (w) — 生 estimator を最終予測に混ぜる重み
- smoothing — Savitzky-Golay / rolling / Gaussian
- calibration — Platt scaling / isotonic / temperature
- Optuna TPE で多次元 grid 探索

**注意点**:

- **per-sample-key 最適化は禁忌** (test に存在しない key で fallback 必須 → 本質は global opt 同等、LB hack)
- hardcoded clip は安全網としてのみ、改善源にしない
- **Public LB hack 系を採用しない** (overlap dict 置換、key-specific tuning 等は Private 爆死)

**チェックリスト**:

- [ ] Optuna 探索範囲が CV で stable
- [ ] hidden test fallback 動作確認
- [ ] §6 アンチパターン (LB hack) を踏んでいないか確認

---

## 5. プロセスメタ (期間中ずっと運用)

### 5-1. 速度 vs 目標の整合性チェック (毎週末必須)

```
残り週数 × 必要週次改善 ≥ 目標まで残った差分 ?
```

- 達成可能 → 現方針継続
- 不可能 → **即座に方針再設計** (incremental tuning を続けない)

**実装**: `tools/velocity_check.py` を週末 cron 化、超過した時点でアラート。

最も再発防止効果が高いプロセス。「軌道速度を測らずに同じ方向に進む」のが最大の失敗パターン。

### 5-2. 公開動向スイープ (毎週月曜)

```bash
# Kaggle なら
kaggle kernels list --competition <slug> --sort-by voteCount --page-size 50
kaggle competitions topics --sort-by top --page-size 30
kaggle competitions leaderboard <slug> --show --csv

# 業務/研究なら
WebSearch: "<topic> SOTA 2026"
arXiv recent: <topic> filter 過去 30 日
HuggingFace trending models / datasets
```

- 新規上位手法を pull、**コードを読む** (タイトル/star/citation だけで判断しない)
- 上位の動きを把握、追走ペース確認

### 5-3. 失敗 (NoGO) の記録方法 — 真因を 1 段上で抽象化

「実験 X で metric 悪化」だけで終わらせない。

❌ NG: 「手法 A で精度悪化」
✅ OK: 「**点推定単一手法**は X 性質下で機能しない (ensemble + uncertainty 化なら可能性あり)」

memory への保存形式:

```markdown
- ルール: <抽象化された制約>
- Why: <具体的 incident と数値>
- 適用条件: <この制約が効く条件、効かない条件>
- 回避手段: <あれば、再武装の方向性>
```

抽象化レベル: 「**手法 X が失敗**」ではなく「**X のクラスに属する手法**が**Y の条件下**で失敗」。後者でないと再武装パスが見つからない。

### 5-4. 禁忌は条件付きで記録 (硬直化回避)

❌ NG: 「絶対 X 禁忌」
✅ OK: 「X を**目的変数の直接予測**に使うのは禁忌、**Y の前処理を挟めば**可」

無条件ルールに昇格させると、新発見手法を自力で見つけられなくなる。

### 5-5. メタ専門家ロール常設

「他の上位陣 / 競合 / 周辺領域は何をやっているか」を絶えず問い直す役を 1 人常設。
Agent Team を組む際は、ドメイン専門家に加えて**「メタ専門家」を必ず含める** (CLAUDE.md §計画・設計時の視点 と一致)。

### 5-6. 抽象化階層の見直し (月 1)

「我々は今、問題を正しい抽象化階層で考えているか?」を月 1 で問う。
低い階層 (L2 = 特定 feature の調整) に没入すると、高い階層 (L0 = pipeline 構造そのもの) の選択肢を見落とす。

---

## 6. アンチパターン (避ける)

| パターン | 症状 | 回避 |
|---|---|---|
| **Layer 5 から始める** | 後処理 calibration / Optuna を先に組み立てる | Layer 1-4 を整備してから |
| **Layer 4 から始める** | 単一 model のままで multi-seed stack | Layer 2 で signal 多様性を作ってから |
| **Public LB / metric hack 採用** | overlap dict 置換 / key-specific 最適化 | 本番/Private で爆死、絶対禁忌 |
| **単純チェックリスト盲従** | 全プロジェクトで同じ template 適用 | §1 タイプ診断を先にやる |
| **Incremental tuning loop** | 同じ feature group を 5 回拡張 | §5-1 速度チェックで察知 |
| **メタ専門家不在** | 上位/競合動向を sweep しない、tunnel vision | §5-2, §5-5 |
| **タイトル/star/citation で判断** | コードを読まずに手法推定 | 必ず pull + 内部実装確認 |
| **OOF / val metric 単独で abandon** | augmentation / 後処理を OOF 横ばいで諦める | LB / 本番 metric で判定 |
| **無条件禁忌の硬直化** | 「絶対 X 禁忌」を新発見でも適用 | §5-4 条件付きで記録 |
| **kernel/script 末尾の strict assertion** | `assert len(out) == N` が hidden で発火 | `print` 警告で代替 |
| **L0 抽象化の固定化** | 同じ問題定義で 3 ヶ月以上ループ | §5-6 月 1 で見直し |

---

## 7. 関連リソース

- `CLAUDE.md` (グローバル): スキル / 計画・設計時の視点 / Plan Mode ブレストフェーズ
- `tech-versions.md`: FW・ライブラリ最新版 (バージョン依存 API に注意)
- `skills-catalog.md`: スキル一覧 (test-strategy, brainstorming, deep-research, mcp-builder 等)

---

## 8. 改訂履歴

- **v1.0 (2026-05-16)**: 初版。ROGII Wellbore Geology Prediction (Kaggle Featured) の Phase 3 戦略再設計セッションで導出。
  - 4 専門家 brainstorm (ドメイン / 時系列ML / CV-Validation / Kaggle メタ) で 5 レイヤー構造を確立
  - 「予測の不確実性 learnable 化」概念を発見
  - 「問題タイプ診断 → タイプ別 template 選択」のメタプロセスを汎用化
  - 元セッションの具体的事例は `c:/work/Kaggle_ROGII_Wellbore_Geology_Prediction/docs/phase3_strategy_proposal.md` 参照
