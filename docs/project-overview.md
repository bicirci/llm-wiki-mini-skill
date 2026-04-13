# llm-wiki-mini 项目文档

## 1. 项目定位

`llm-wiki-mini` 是一个面向 Claude Code 与 Codex 的仓库级 skill 项目。

它不是一个一次性摘要工具，也不是一个 query-time RAG 封装，而是 `llm-wiki` 思路的一个轻量化、离线优先实现：

- 用户提供原始素材
- agent 维护一个持续演化的 markdown wiki
- 知识被逐步编译进 wiki，而不是每次查询时从原始文档重新推导

项目的核心思想来源于 Andrej Karpathy 的 `llm-wiki` 说明文档：

- <https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>

## 2. 要实现的目标

本项目要实现的目标可以分为四类。

### 2.1 核心知识库目标

- 让 agent 维护一个持久化、可积累的 wiki，而不是只做临时回答
- 将原始来源、知识层、操作规范分离
- 让新增素材可以持续更新既有 wiki 页面，而不是只生成孤立摘要
- 让查询结果中有长期价值的内容可以回写到 wiki

### 2.2 产品边界目标

- 保持离线优先
- 不依赖第三方联网抓取插件
- 不引入复杂外部运行时依赖
- 对 URL 类来源统一走手动入口

### 2.3 安装与使用目标

- 支持 Claude Code 与 Codex
- 使用仓库级安装，而不是全局安装
- 安装后直接落到目标仓库下的平台标准目录
- 让目标仓库自动生成对应平台的根入口文件

### 2.4 工程化目标

- 安装产物精简、可解释、可测试
- skill 文件结构尽量贴近 Claude / Codex 的标准格式
- 安装过程可通过脚本进行可度量验证
- 安装日志与安装产物分离，避免污染目标仓库

## 3. 核心设计原则

### 3.1 三层模型

项目遵循 `llm-wiki` 的三层模型：

1. `raw/`
   - 原始素材层
   - 来源文件不可变
   - agent 读取，但不修改

2. `wiki/`
   - 知识维护层
   - 包含 source summary、entity、topic、comparison、synthesis 等页面
   - agent 负责维护一致性、交叉引用和演化

3. skill / schema
   - 操作规范层
   - 约束 agent 如何执行 `init`、`ingest`、`query`、`digest`、`lint`、`status`、`graph`

### 3.2 mini 的收缩原则

`mini` 只收缩“来源进入方式”，不收缩知识库哲学本身。

保留的核心能力：

- persistent wiki
- incremental ingest
- `index.md` / `log.md` 一等地位
- query 结果可回写
- lint 检查知识质量

移除的能力：

- 自动网页提取
- 第三方抓取插件
- 联网安装依赖

### 3.3 平台薄入口原则

平台入口文件只负责：

- 提供最小 frontmatter
- 描述 skill 的用途和触发边界
- 引导到共享规范文件

共享规范文件负责：

- 工作流定义
- 行为约束
- 输出要求
- finalization checks

## 4. 当前实现内容

截至目前，`llm-wiki-mini` 已完成以下实现。

### 4.1 文档与 skill 结构

- 提供仓库级说明文件：
  - `README.md`
  - `CLAUDE.md`
  - `AGENTS.md`
- 提供仓库根兼容入口：
  - `SKILL.md`
  - 该文件用于仓库内说明与兼容索引，不是最终安装到目标 repo 的平台主入口
- 提供平台专属薄入口：
  - `platforms/claude/SKILL.md`
  - `platforms/codex/SKILL.md`
- 提供共享规范源文件：
  - `shared/skill-core.md`
- 提供仓库内共享引用文件：
  - `references/skill-core.md`
- 安装时将共享规范整理为安装产物中的：
  - `references/skill-core.md`
- 提供 Codex 元数据：
  - `agents/openai.yaml`

### 4.2 安装器

当前 `install.sh` 已实现：

- 交互式询问 `platform`
- 交互式询问目标 repo 目录
- 也支持命令行参数：
  - `--platform`
  - `--target-dir`
  - `--dry-run`
- 自动安装到目标 repo 下的平台标准目录：
  - Claude: `.claude/skills/llm-wiki-mini`
  - Codex: `.codex/skills/llm-wiki-mini`
- 自动在目标 repo 根生成：
  - `CLAUDE.md`
  - `AGENTS.md`
- 安装日志保存到源仓库内的：
  - `.install-logs/`

### 4.3 安装产物裁剪

当前安装结果已经收敛为精简 skill 包。

安装产物会保留：

- `SKILL.md`
- `scripts/`
- `templates/`
- `references/skill-core.md`
- `agents/openai.yaml`（仅 Codex）

安装产物不会保留：

- `install.sh`
- `setup.sh`
- `README.md`
- 仓库级 `CLAUDE.md` / `AGENTS.md`
- `platforms/`
- `tests/`
- 安装日志文件

### 4.4 来源与工作流

当前来源边界已实现为：

- 主线来源：
  - 本地 PDF
  - 本地 Markdown / 文本 / HTML
  - 纯文本粘贴
- 手动入口：
  - 网页文章
  - X/Twitter
  - 微信公众号
  - YouTube
  - 知乎
  - 小红书

相关脚本包括：

- `scripts/source-registry.sh`
- `scripts/adapter-state.sh`
- `scripts/init-wiki.sh`
- `scripts/wiki-compat.sh`
- `setup.sh`

## 5. 当前安装行为说明

### 5.1 交互式行为

默认执行：

```bash
bash install.sh
```

脚本会提示：

1. 选择平台：`claude` 或 `codex`
2. 输入目标 repo 目录

### 5.2 非交互式行为

也可以显式执行：

```bash
bash install.sh --platform codex --target-dir <target-repo-dir>
```

这里的 `--target-dir` 当前语义是：

- 指向目标 repo 根目录
- 不是最终的 skill 目录

脚本会自行拼出平台规范路径。

## 6. 测试与验证

项目当前已具备两类验证方式。

### 6.1 安装产物验收测试

脚本：

- `tests/install-package.sh`

目的：

- 用真实目标目录验证安装结果
- 检查安装产物是否精简
- 检查平台裁剪是否正确
- 检查目标 repo 根入口文件是否生成
- 检查安装日志没有写入目标目录

### 6.2 回归测试

脚本：

- `tests/regression.sh`
- `tests/adapter-state.sh`

覆盖内容：

- `--platform` / `--target-dir` 安装路径
- 交互式提示文案与 `--dry-run` 输出
- 根目录 `setup.sh` 兼容入口
- Codex / Claude 安装结果
- source registry 行为
- adapter state 行为
- skill 结构与元数据约束

### 6.3 当前已验证结果

当前版本已验证通过：

```bash
bash tests/install-package.sh <test-target-dir>
bash tests/regression.sh
bash tests/adapter-state.sh
```

其中安装产物验收测试已经在真实目录下跑过一轮：

```bash
bash tests/install-package.sh ./test-wiki
```

## 7. 已完成的关键迭代

到目前为止，项目已经完成过多轮关键迭代，主要包括：

1. 从全局安装思路切换到仓库级安装
2. 从单一 `SKILL.md` 过渡到平台薄入口 + 共享规范
3. 清理安装产物，去除安装器和非运行时文件
4. 将日志写回源仓库，避免污染 target repo
5. 将 `shared/` 保留为仓库内规范源文件，并在安装时整理为标准引用位置
6. 将安装器输出收敛为英文为主的精简摘要
7. 用真实目标目录安装回归替代纯静态判断

### 7.1 提交记录对应的阶段

当前提交历史可以概括为三个阶段：

1. `8461d6d`
   - 初始化离线、仓库级的 mini skill
   - 建立 README、安装器、scripts、templates、基础测试

2. `67a8017`
   - 将结构重构为平台薄入口 + 共享规范
   - 引入 `shared/skill-core.md`、`references/skill-core.md`
   - 引入 `agents/openai.yaml`
   - 新增真实安装产物验收测试 `tests/install-package.sh`
   - 强化 repo-level 安装与产物裁剪

3. `c55a346`
   - 将 `install.sh` 的终端输出收敛为英文为主的精简摘要
   - 同步更新回归测试断言，使其匹配新的输出形式

## 8. 当前项目状态

当前项目已经具备以下能力：

- 可作为开源项目使用
- 可在目标仓库中生成 Claude / Codex 所需的 repo-level skill 结构
- 可通过自动化脚本验证安装结果
- 可在离线优先前提下运行 `llm-wiki` 的核心工作流

当前项目仍然是 `mini` 版本，意味着：

- 输入能力仍然有意受限
- 不包含自动抓取来源的复杂集成
- 重点在于提供一个简洁、稳定、规范、可测的 skill 载体

### 8.1 当前仓库状态

截至整理本文档时，仓库上下文为：

- 当前分支：`feat/repo-skill-installer-refine`
- `main` 与当前工作分支都已包含关键安装器重构提交
- 远程仓库：`origin git@github.com:bicirci/llm-wiki-mini-skill.git`
- 当前未提交内容主要是：
  - `docs/project-overview.md`

这意味着下次继续对话时，应默认以“安装器重构已经完成、文档仍在收尾中”的状态继续，而不是重新从初始版本开始判断。

### 8.2 已确认的关键决策

以下约束来自本次会话中的明确决策，后续修改时默认应继续保持：

- 只接受仓库级安装，不再回到全局 skill 安装模型
- `install.sh` 默认以交互式方式询问：
  - `platform`
  - `target-dir`
- `--target-dir` 的语义是“目标 repo 根目录”，不是最终 skill 目录
- 安装器自动在目标 repo 下创建平台标准目录：
  - Claude: `.claude/skills/llm-wiki-mini`
  - Codex: `.codex/skills/llm-wiki-mini`
- 安装器自动在目标 repo 根创建：
  - `CLAUDE.md`
  - `AGENTS.md`
- 不在 target repo 或 target skill 下写入 `install.log`
- 安装日志统一写回源仓库的 `.install-logs/`
- 源仓库保留 `shared/skill-core.md`
- 安装时将共享规范整理到安装产物中的 `references/skill-core.md`
- 安装产物按平台裁剪：
  - Claude 只装 Claude 需要的入口和共享内容
  - Codex 额外装 `agents/openai.yaml`
- 安装产物不得包含：
  - `install.sh`
  - `setup.sh`
  - `README.md`
  - 仓库级 `CLAUDE.md` / `AGENTS.md`
  - `platforms/`
  - `tests/`
  - 安装日志文件
- 公开文档和安装产物中避免出现本机绝对路径或用户 home 路径提示

### 8.3 用于恢复上下文时应优先查看的文件

如果下一次会话需要快速恢复上下文，建议按下面顺序读取：

1. `docs/project-overview.md`
   - 获取项目目标、已实现内容、安装器行为、测试范围、关键决策
2. `README.md`
   - 获取对外定位与当前开源文档口径
3. `install.sh`
   - 获取安装器真实行为与当前目录语义
4. `tests/install-package.sh`
   - 获取安装产物的验收标准
5. `tests/regression.sh`
   - 获取 repo-level 安装流程与文档约束
6. `platforms/claude/SKILL.md`
7. `platforms/codex/SKILL.md`
8. `shared/skill-core.md`
   - 获取平台薄入口和共享工作流契约
9. `agents/openai.yaml`
   - 获取 Codex 的补充元数据

只看 README 不足以恢复完整上下文，安装器语义、安装产物边界和测试约束应以 `install.sh` 与 `tests/` 为准。

## 9. 后续维护建议

后续维护时，建议遵循以下约束：

### 9.1 不要破坏安装产物精简性

新增文件时，优先区分：

- 仓库开发文件
- 安装运行时文件

不要让开发辅助文件泄漏到安装产物中。

### 9.2 保持共享规范单一来源

共享行为规范优先维护在：

- `shared/skill-core.md`

安装结果中的 `references/skill-core.md` 应始终视为构建产物，而不是新的权威来源。

### 9.3 保持测试先行

安装器和 skill 结构相关改动，优先先更新：

- `tests/install-package.sh`
- `tests/regression.sh`

避免只改实现、不更新验收标准。

### 9.4 保持 mini 边界清晰

若未来考虑扩展联网来源能力，应明确区分：

- 这是 `mini` 的增强
- 还是应该另做非 mini 版本

避免把当前项目再次膨胀成难以维护的多依赖安装器。
