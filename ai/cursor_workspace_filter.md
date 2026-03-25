# Cursor IDE：工作区与 `.cursor` 目录扫描（规则 / 技能 / 子代理）

本文整理自对 Cursor 官方文档与社区讨论的查阅，说明：**能否过滤或限定**工作区内多个 `.cursor` 目录对 Rules、Skills、Subagents 的加载，以及可行的缓解方式。

**文档日期**：2026-03-25（请以你本地 Cursor 版本为准，产品行为可能更新）。

---

## 1. 问题描述

在 **Cursor Settings → Rules, Skills, Subagents** 中，IDE 会汇总工作区中出现的配置。若工作区包含多个根目录或深层目录里也存在 `.cursor`，可能加载大量你认为无关的 Rules、Skills 与 Subagents。

用户期望的能力包括：

- 排除特定路径下的 `.cursor` 目录；或  
- 仅扫描白名单中的 `.cursor` 目录。

---

## 2. 官方文档中的约定路径（无「排除列表」）

根据 [Rules](https://cursor.com/docs/context/rules)、[Agent Skills](https://cursor.com/docs/context/skills)、[Subagents](https://cursor.com/docs/subagents) 等公开说明：

| 类型 | 常见位置（项目级） | 用户级 |
|------|-------------------|--------|
| Rules | `.cursor/rules/`、根目录 `AGENTS.md` 等 | Cursor 设置中的 User Rules |
| Skills | `.cursor/skills/`、`.agents/skills/` | `~/.cursor/skills/` 等 |
| Subagents | `.cursor/agents/`（及 `.claude/`、`.codex/` 兼容路径） | `~/.cursor/agents/` 等 |

文档描述的是「在这些位置发现配置」，**未提供**类似「忽略某路径下的 `.cursor`」或「仅扫描指定目录」的配置项。

---

## 3. `.cursorignore` 能否过滤 Rules / Skills / Subagents？

根据 [Ignore files](https://cursor.com/docs/context/ignore-files)：

- `.cursorignore` 主要作用于 **代码索引、语义搜索、Tab、Agent 对代码的访问、@ 引用** 等。
- 文档**未说明** `.cursorignore` 会改变 Rules、Skills、Subagents 的**发现与设置页列表**。

因此：**不应默认认为**在 `.cursorignore` 里忽略 `.cursor` 就能减少设置里列出的规则/技能/子代理；若个别版本实测有联动，应以实测为准，且非官方保证行为。

---

## 4. 实际可行的缓解方式

### 4.1 多根工作区（Multi-root Workspace）

每个加入工作区的**文件夹根**往往会被视为独立「项目」，各自下的 `.cursor` 可能一并进入汇总。

**做法**：

- 从工作区 **移除** 不需要其配置的文件夹；或  
- **单独窗口** 只打开当前要编辑的仓库。

### 4.2 子目录 / 依赖中带 `.cursor`

若某子树（如拷贝的工程、子模块）内含 `.cursor`，在**无官方排除项**的前提下，只能通过：

- 不把该子树加入当前工作区；或  
- 在仓库/磁盘层面 **改名、移动或删除** 不需要的 `.cursor` 目录（属于结构上的规避，而非 IDE 设置）。

### 4.3 技能：减少自动参与（仍在列表中）

在技能的 `SKILL.md` 前置元数据中设置 `disable-model-invocation: true`，可使该技能**不随模型判断自动挂载**，需通过 `/技能名` 等方式显式调用。详见 [Agent Skills](https://cursor.com/docs/context/skills)。

说明：这**不会**从设置 UI 中移除该技能，主要减轻自动上下文占用。

### 4.4 用户级目录整理

`~/.cursor/skills`、`~/.cursor/agents` 等对用户下**所有项目**生效。精简此处可减少「全局多出来」的条目。

---

## 5. 产品与社区动向

论坛存在「工作区或配置作用域」类需求（例如 [Workspace- or profile-scoped Cursor config](https://forum.cursor.com/t/workspace-or-profile-scoped-cursor-config-rules-skills-subagents-mcp/153068)），反映社区希望更细粒度地控制 Rules、Skills、Subagents、MCP 等作用域。若需要官方支持「按路径排除 `.cursor`」，可在 [Cursor Forum](https://forum.cursor.com/) 的 Ideas 中跟进或补充用例。

---

## 6. 结论（摘要）

| 问题 | 结论 |
|------|------|
| 是否有设置可「只扫描指定 `.cursor`」或「黑名单排除」？ | **公开文档未提供**此类开关。 |
| `.cursorignore` 是否可靠用于过滤上述三类配置的发现？ | **文档未支持**；不宜作为正式方案。 |
| 当前可操作建议 | 控制工作区根目录、单独窗口、整理 `~/.cursor`、技能用 `disable-model-invocation`；依赖内 `.cursor` 需从工作区或文件结构上规避。 |

---

## 7. 参考链接

- [Rules | Cursor Docs](https://cursor.com/docs/context/rules)  
- [Agent Skills | Cursor Docs](https://cursor.com/docs/context/skills)  
- [Subagents | Cursor Docs](https://cursor.com/docs/subagents)  
- [Ignore files | Cursor Docs](https://cursor.com/docs/context/ignore-files)  
- [Forum: Workspace- or profile-scoped Cursor config](https://forum.cursor.com/t/workspace-or-profile-scoped-cursor-config-rules-skills-subagents-mcp/153068)
